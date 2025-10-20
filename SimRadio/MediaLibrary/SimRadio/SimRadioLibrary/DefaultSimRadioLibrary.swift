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
    func testPopulate() async {
        await testPopulateNew()
    }

    func testPopulateNew() async {
        let baseURL = "https://media.githubusercontent.com/media/maxerohingta/"
        let simRadioURLs = [
            "convert_gta5_audio/refs/heads/main/converted_m4a/sim_radio.json",
            "convert_gta4_audio/refs/heads/main/result/sim_radio.json"
        ].compactMap { URL(string: "\(baseURL)\($0)") }
        await addSimRadio(urls: simRadioURLs)
    }

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
        let mediaFileURL = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent(series.media)
        let mediaJSON = try await URLSession.shared.data(from: mediaFileURL)
        let media = try JSONDecoder().decode(SimRadioDTO.GameSeriesMedia.self, from: mediaJSON.0)
        guard let url = series.origin.map({ URL(string: $0) }) ?? nil else { return }
        let seriesData = SimRadioDTO.GameSeriesData(gameSeries: series, media: media)
        notifyAdded(SimRadioMedia(origin: url, dto: seriesData))
    }

    func addSimRadio(urls: [URL]) async {
        for url in urls {
            do {
                try await addSimRadio(url: url)
            } catch {
                print(error)
            }
        }
    }

    func addSimRadio(url: URL) async throws {
        let seriesJSON = try await URLSession.shared.data(from: url)
        let series = try JSONDecoder().decode(SimRadioDTO.GameSeries.self, from: seriesJSON.0)
        let mediaURL = url
            .deletingLastPathComponent()
            .appendingPathComponent(series.media)
        let mediaJSON = try await URLSession.shared.data(from: mediaURL)
        let media = try JSONDecoder().decode(SimRadioDTO.GameSeriesMedia.self, from: mediaJSON.0)

        let seriesData = SimRadioDTO.GameSeriesData(gameSeries: series, media: media)
        let newSimRadio = SimRadioMedia(origin: url, dto: seriesData)
        guard newSimRadio.series.keys.count == 1,
              let seriesID = newSimRadio.series.keys.first
        else { return }

        let stations = Array(newSimRadio.stations.keys)
        await removeDownload(stations)
        try saveJsonData(origin: url, dto: seriesData)
        storage.addSeries(id: seriesID)
        notifyAdded(newSimRadio)
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

    func notifyAdded(_ new: SimRadioMedia) {
        guard let mediaState else { return }
        let curren = mediaState.simRadio
        delegate?.simRadioLibrary(
            self,
            didChange: SimRadioMedia(
                series: curren.series.merging(new.series) { _, new in new },
                trackLists: curren.trackLists.merging(new.trackLists) { _, new in new },
                stations: curren.stations.merging(new.stations) { _, new in new }
            )
        )
    }

    func saveJsonData(origin: URL, dto: SimRadioDTO.GameSeriesData) throws {
        let directory = SimGameSeries.ID(origin: origin).directoryURL
        try directory.ensureDirectoryExists()
        let seriesFileURL = directory.appending(path: SimGameSeries.defaultFileName, directoryHint: .notDirectory)
        let mediaFileURL = seriesFileURL
            .deletingLastPathComponent()
            .appendingPathComponent(dto.gameSeries.media)

        let series = SimRadioDTO.GameSeries(
            meta: dto.gameSeries.meta,
            origin: origin.absoluteString,
            media: dto.gameSeries.media,
            stations: dto.gameSeries.stations
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let jsonSeries = try encoder.encode(series)
        let jsonMedia = try encoder.encode(dto.media)

        try seriesFileURL.removeFileIfExists()
        try jsonSeries.write(to: seriesFileURL)

        try mediaFileURL.removeFileIfExists()
        try jsonMedia.write(to: mediaFileURL)
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
