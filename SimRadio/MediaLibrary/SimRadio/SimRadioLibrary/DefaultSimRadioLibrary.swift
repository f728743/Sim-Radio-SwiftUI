//
//  DefaultSimRadioLibrary.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

import Foundation

@MainActor
class DefaultSimRadioLibrary {
    let simRadioDownload: any SimRadioDownload

    let storage: any SimRadioStorage
    private var busy: [SimStation.ID: BusyReason] = [:]
    weak var mediaState: SimRadioMediaState?
    weak var delegate: SimRadioLibraryDelegate?

    init(
        storage: any SimRadioStorage,
        simRadioDownload: any SimRadioDownload
    ) {
        self.storage = storage
        self.simRadioDownload = simRadioDownload

        Task { [weak self] in
            guard let self else { return }
            let stream = await self.simRadioDownload.events
            for await event in stream {
                await handleDownloaderEvent(event)
            }
        }
    }
}

extension DefaultSimRadioLibrary: SimRadioLibrary {
    func downloadStation(_ stationID: SimStation.ID) async {
        if let state = mediaState?.simDownloadStatus[stationID]?.state, state == .paused {
            await resumeDownloading(stationID)
        } else {
            storage.setStorageState(.downloadStarted, for: stationID)
            await simRadioDownload.downloadStation(withID: stationID)
        }
    }

    func removeDownload(_ stationID: SimStation.ID) async {
        guard let mediaState,
              let state = mediaState.simDownloadStatus[stationID]?.state
        else { return }

        switch state {
        case .scheduled, .downloading:
            notifyChangeStatus(status: .init(state: .busy), for: stationID)
            busy[stationID] = .canceling
            let paused = await simRadioDownload.cancelDownloadStation(withID: stationID)
            if !paused {
                busy[stationID] = nil
                notifyChangeStatus(status: .init(state: .busy), for: stationID)
                await removeDownloadFiles(stationID)
                notifyChangeStatus(status: nil, for: stationID)
            }
        case .completed, .paused:
            notifyChangeStatus(status: .init(state: .busy), for: stationID)
            await removeDownloadFiles(stationID)
            notifyChangeStatus(status: nil, for: stationID)
        case .busy:
            break
        }
    }

    func pauseDownload(_ stationID: SimStation.ID) async {
        guard let mediaState,
              let state = mediaState.simDownloadStatus[stationID]?.state
        else { return }

        switch state {
        case .downloading, .scheduled:
            notifyChangeStatus(status: .init(state: .busy), for: stationID)
            busy[stationID] = .pausing
            let paused = await simRadioDownload.cancelDownloadStation(withID: stationID)
            if !paused {
                busy[stationID] = nil
            }
        default:
            break
        }
    }

    func load() {
        print("ℹ️ documents directory: \(URL.documentsDirectory.path)")

        Task {
            await loadSimRadio()
        }
    }

    func addSimRadio(url: URL, persisted: Bool) async throws {
        let seriesJSON = try await URLSession.shared.data(from: url)
        let series = try JSONDecoder().decode(SimRadioDTO.GameSeries.self, from: seriesJSON.0)

        let newSimRadio = SimRadioMedia(
            origin: url,
            dto: series,
            timestamp: persisted ? Date() : nil
        )
        guard newSimRadio.series.keys.count == 1,
              let seriesID = newSimRadio.series.keys.first
        else { return }

        let stations = Array(newSimRadio.stations.keys)
        if persisted {
            await removeDownload(stations)
            try saveJsonData(origin: url, dto: series)
            storage.addSeries(id: seriesID)
        }
        addToLibrary(newSimRadio, persisted: persisted)
    }
    
    func remove(_ series: SimGameSeries) async throws {
        guard let mediaState else { return }
        let curren = mediaState.simRadio

        let seriesID = series.id
        let directory = seriesID.directoryURL
        let seriesFileURL = directory.appending(path: SimGameSeries.defaultFileName, directoryHint: .notDirectory)
        storage.removeSeries(id: seriesID)
        try seriesFileURL.removeFileIfExists()
                
        let currentNonPersisted = mediaState.nonPersistedSimSeries
        let newNonPersisted = currentNonPersisted.contains(seriesID)
            ? currentNonPersisted : currentNonPersisted + [seriesID]

        delegate?.simRadioLibrary(
            self,
            didChange: curren,
            nonPersistedSeries: newNonPersisted
        )
    }
}

private extension DefaultSimRadioLibrary {
    enum BusyReason {
        case pausing
        case canceling
    }

    func removeDownload(_ stationIDs: [SimStation.ID]) async {
        for stationID in stationIDs {
            await removeDownload(stationID)
        }
    }

    func removeDownloadFiles(_ stationID: SimStation.ID) async {
        guard let mediaState else { return }
        storage.setStorageState(.removing, for: stationID)
        let otherDownloadedStationIDs = mediaState.simDownloadStatus.keys.filter { $0 != stationID }
        let trackListIDsToKeep = mediaState.simRadio.commonTrackLists(
            of: stationID,
            among: otherDownloadedStationIDs
        )
        let stationTrackLists = mediaState.simRadio.findAllUsedTrackLists(stationID: stationID)
        let stationTrackListIDs = stationTrackLists.map(\.id)
        let trackListIDsToDelete = Array(Set(stationTrackListIDs).subtracting(trackListIDsToKeep))
        removeFiles(of: stationTrackLists.filter { trackListIDsToDelete.contains($0.id) })
        storage.removeStorageState(for: stationID)
    }

    func handleDownloaderEvent(_ event: SimRadioDownloadEvent) async {
        let state = MediaDownloadStatus.DownloadState(event.status.state)
        let status = state.map { MediaDownloadStatus(
            state: $0,
            downloadedBytes: event.status.downloadedBytes,
            totalBytes: event.status.totalBytes
        ) }
        notifyChangeStatus(status: status, for: event.id)

        switch event.status.state {
        case .failed:
            storage.setStorageState(.downloadPaused, for: event.id)
        case .completed:
            storage.setStorageState(.downloaded, for: event.id)
        case .canceled:
            let reason = busy.removeValue(forKey: event.id)
            switch reason {
            case .canceling:
                notifyChangeStatus(status: nil, for: event.id)
                await removeDownloadFiles(event.id)
            case .pausing:
                storage.setStorageState(.downloadPaused, for: event.id)
                notifyChangeStatus(
                    status: .init(
                        state: .paused,
                        downloadedBytes: event.status.downloadedBytes,
                        totalBytes: event.status.totalBytes
                    ),
                    for: event.id
                )
            case .none:
                print("Error: unknown reason for busy state of download")
            }
        default: break
        }
    }

    func loadSimRadio() async {
        let series = storage.addedSeriesIDs
        for id in series {
            do {
                try await loadSimRadio(series: id)
            } catch {
                print(error)
            }
        }
        await updateStationsDownloadState()
    }

    func loadSimRadio(series id: SimGameSeries.ID) async throws {
        let fileURL = id.jsonFileURL
        let seriesJSON = try await URLSession.shared.data(from: fileURL)
        let series = try JSONDecoder().decode(SimRadioDTO.GameSeries.self, from: seriesJSON.0)
        guard let url = series.origin.map({ URL(string: $0) }) ?? nil else { return }
        let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
        addToLibrary(
            SimRadioMedia(
                origin: url,
                dto: series,
                timestamp: resourceValues.creationDate
            ),
            persisted: true
        )
    }

    func updateStationsDownloadState() async {
        for (stationID, storageState) in storage.allStoredStationStates {
            switch storageState {
            case .downloadPaused:
                notifyChangeStatus(status: .init(state: .paused), for: stationID)
            case .downloadStarted:
                await resumeDownloading(stationID)
            case .downloaded:
                notifyChangeStatus(status: .init(state: .completed), for: stationID)
            case .removing:
                await removeDownloadFiles(stationID)
            }
        }
    }

    func addToLibrary(_ new: SimRadioMedia, persisted: Bool) {
        guard let mediaState, let seriesID = new.series.keys.first else { return }
        let curren = mediaState.simRadio
        if !persisted {
            guard !curren.series.keys.contains(seriesID) else { return }
        }

        let nonPersistedSeries = persisted
            ? mediaState.nonPersistedSimSeries.filter { $0 != seriesID }
            : mediaState.nonPersistedSimSeries + [seriesID]

        delegate?.simRadioLibrary(
            self,
            didChange: SimRadioMedia(
                series: curren.series.merging(new.series) { _, new in new },
                trackLists: curren.trackLists.merging(new.trackLists) { _, new in new },
                stations: curren.stations.merging(new.stations) { _, new in new }
            ),
            nonPersistedSeries: nonPersistedSeries
        )
    }

    func saveJsonData(origin: URL, dto: SimRadioDTO.GameSeries) throws {
        let directory = SimGameSeries.ID(origin: origin).directoryURL
        try directory.ensureDirectoryExists()
        let seriesFileURL = directory.appending(path: SimGameSeries.defaultFileName, directoryHint: .notDirectory)

        let series = SimRadioDTO.GameSeries(
            meta: dto.meta,
            origin: origin.absoluteString,
            stations: dto.stations,
            trackLists: dto.trackLists
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let jsonSeries = try encoder.encode(series)

        try seriesFileURL.removeFileIfExists()
        try jsonSeries.write(to: seriesFileURL)
    }

    func resumeDownloading(_ stationID: SimStation.ID) async {
        do {
            guard let mediaState else { return }
            let current = mediaState.simRadio
            let currentStatus = try await current.calculateStationLocalStatus(stationID)
            switch currentStatus {
            case .completed:
                storage.setStorageState(.downloaded, for: stationID)
                notifyChangeStatus(status: .init(state: .completed), for: stationID)
                return
            case let .partial(missing: missing):
                await simRadioDownload.downloadStation(withID: stationID, missing: missing)
            case .missing:
                break
            }
        } catch {
            print(error)
        }
        notifyChangeStatus(status: .initial, for: stationID)
        await simRadioDownload.downloadStation(withID: stationID)
    }

    func removeFiles(of trackLists: [TrackList]) {
        let files = trackLists.flatMap { $0.tracks.compactMap(\.localFileURL) }
        files.removeAll()
        let directories = files.map { $0.deletingLastPathComponent() }.unique()
        directories.removeEmptyDirectories()
    }

    func notifyChangeStatus(status: MediaDownloadStatus?, for stationID: SimStation.ID) {
        delegate?.simRadioLibrary(
            self,
            didChangeDownloadStatus: status,
            for: stationID
        )
    }
}
