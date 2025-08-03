//
//  DefaultSimRadioLibrary.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

// swiftlint:disable file_length

import Foundation

@MainActor
class DefaultSimRadioLibrary {
    let legacySimRadioDownload: any LegacySimRadioDownload
    let simRadioDownload: any SimRadioDownload

    let storage: any SimRadioStorage
    private var legacyBusy: [LegacySimStation.ID: BusyReason] = [:]
    private var busy: [SimStation.ID: BusyReason] = [:]
    weak var mediaState: SimRadioMediaState?
    weak var delegate: SimRadioLibraryDelegate?

    init(
        storage: any SimRadioStorage,
        legacySimRadioDownload: any LegacySimRadioDownload,
        simRadioDownload: any SimRadioDownload
    ) {
        self.storage = storage
        self.legacySimRadioDownload = legacySimRadioDownload
        self.simRadioDownload = simRadioDownload

        Task { [weak self] in
            guard let self else { return }
            let stream = await self.legacySimRadioDownload.events
            for await event in stream {
                await handleDownloaderEvent(event)
            }
        }

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

    func testPopulateLegacy() async {
        let baseUrl = "https://raw.githubusercontent.com/tmp-acc/"
        let simRadioURLs = [
            //            "GTA-V-Radio-Stations-TestDownload/short/sim_radio_stations.json",
//            "GTA-V-Radio-Stations-TestDownload/long/sim_radio_stations.json",
//            "GTA-IV-Radio-Stations/master/sim_radio_stations.json",
            "GTA-V-Radio-Stations/master/sim_radio_stations.json"
        ].compactMap { URL(string: "\(baseUrl)\($0)") }
        await addLegacySimRadio(urls: simRadioURLs)
    }

    func testPopulateNew() async {
        let baseURL = "https://media.githubusercontent.com/media/maxerohingta/"
        let simRadioURLs = [
            "convert_gta5_audio/refs/heads/main/converted_m4a/new_sim_radio_stations.json"
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

    func pauseDownload(_: LegacySimStation.ID) async {}

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

    func removeDownload(_ stationIDs: [LegacySimStation.ID]) async {
        for stationID in stationIDs {
            await removeDownload(stationID)
        }
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

        await loadLegacySimRadio()
    }

    func loadSimRadio(series id: SimGameSeries.ID) async throws {
        let fileURL = id.jsonFileURL
        let jsonData = try await URLSession.shared.data(from: fileURL)
        let radio = try JSONDecoder().decode(SimRadioDTO.GameSeries.self, from: jsonData.0)
        guard let url = radio.origin.map({ URL(string: $0) }) ?? nil else { return }
        notifyAdded(SimRadioMedia(origin: url, dto: radio))
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
        let jsonData = try await URLSession.shared.data(from: url)
        let radio = try JSONDecoder().decode(SimRadioDTO.GameSeries.self, from: jsonData.0)

        let newSimRadio = SimRadioMedia(origin: url, dto: radio)
        guard newSimRadio.series.keys.count == 1,
              let seriesID = newSimRadio.series.keys.first
        else { return }

        let stations = Array(newSimRadio.stations.keys)
        await removeDownload(stations)
        try saveJsonData(series: radio, origin: url)
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

    func saveJsonData(series: LegacySimRadioDTO.GameSeries, origin: URL) throws {
        let directory = LegacySimGameSeries.ID(origin: origin).directoryURL
        try directory.ensureDirectoryExists()
        let fileURL = directory.appending(path: LegacySimGameSeries.defaultFileName, directoryHint: .notDirectory)
        try fileURL.removeFileIfExists()
        let gameSeries = LegacySimRadioDTO.GameSeries(
            origin: origin.absoluteString,
            info: series.info,
            common: series.common,
            stations: series.stations
        )
        let jsonData = try JSONEncoder().encode(gameSeries)
        try jsonData.write(to: fileURL)
    }

    func saveJsonData(series: SimRadioDTO.GameSeries, origin: URL) throws {
        let directory = SimGameSeries.ID(origin: origin).directoryURL
        try directory.ensureDirectoryExists()
        let fileURL = directory.appending(path: SimGameSeries.defaultFileName, directoryHint: .notDirectory)
        try fileURL.removeFileIfExists()
        let gameSeries = SimRadioDTO.GameSeries(
            meta: series.meta,
            origin: origin.absoluteString,
            trackLists: series.trackLists,
            stations: series.stations
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let jsonData = try encoder.encode(gameSeries)
        try jsonData.write(to: fileURL)
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

// MARK: Legacy

extension DefaultSimRadioLibrary {
    func loadLegacySimRadio() async {
        let series = storage.addedLegacySeriesIDs
        for id in series {
            do {
                try await loadLegacySimRadio(series: id)
            } catch {
                print(error)
            }
        }
        await updateLegacyStationsDownloadState()
    }

    func loadLegacySimRadio(series id: LegacySimGameSeries.ID) async throws {
        let fileURL = id.jsonFileURL
        let jsonData = try await URLSession.shared.data(from: fileURL)
        let radio = try JSONDecoder().decode(LegacySimRadioDTO.GameSeries.self, from: jsonData.0)
        guard let url = radio.origin.map({ URL(string: $0) }) ?? nil else { return }
        notifyAdded(LegacySimRadioMedia(origin: url, dto: radio))
    }

    func addLegacySimRadio(urls: [URL]) async {
        for url in urls {
            do {
                try await addLegacySimRadio(url: url)
            } catch {
                print(error)
            }
        }
    }

    func notifyAdded(_ new: LegacySimRadioMedia) {
        guard let mediaState else { return }
        let curren = mediaState.legacySimRadio
        delegate?.simRadioLibrary(
            self,
            didChange: LegacySimRadioMedia(
                series: curren.series.merging(new.series) { _, new in new },
                fileGroups: curren.fileGroups.merging(new.fileGroups) { _, new in new },
                stations: curren.stations.merging(new.stations) { _, new in new }
            )
        )
    }

    func addLegacySimRadio(url: URL) async throws {
        let jsonData = try await URLSession.shared.data(from: url)
        let radio = try JSONDecoder().decode(LegacySimRadioDTO.GameSeries.self, from: jsonData.0)
        let newSimRadio = LegacySimRadioMedia(origin: url, dto: radio)

        guard newSimRadio.series.keys.count == 1,
              let seriesID = newSimRadio.series.keys.first
        else { return }

        let stations = Array(newSimRadio.stations.keys)
        await removeDownload(stations)
        try saveJsonData(series: radio, origin: url)
        storage.addSeries(id: seriesID)
        notifyAdded(newSimRadio)
    }
}

// MARK: LegacySimRadioLibrary

extension DefaultSimRadioLibrary: LegacySimRadioLibrary {
    func downloadStation(_ stationID: LegacySimStation.ID) async {
        if let state = mediaState?.legacySimDownloadStatus[stationID]?.state, state == .paused {
            await resumeDownloading(stationID)
        } else {
            storage.setStorageState(.downloadStarted, for: stationID)
            await legacySimRadioDownload.downloadStation(withID: stationID)
        }
    }

    func removeDownload(_ stationID: LegacySimStation.ID) async {
        guard let mediaState,
              let state = mediaState.legacySimDownloadStatus[stationID]?.state
        else { return }

        switch state {
        case .scheduled, .downloading:
            notifyChangeStatus(status: .init(state: .busy), for: stationID)
            legacyBusy[stationID] = .canceling
            let paused = await legacySimRadioDownload.cancelDownloadStation(withID: stationID)
            if !paused {
                legacyBusy[stationID] = nil
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

    func pauseDownload(stationID: LegacySimStation.ID) async {
        guard let mediaState,
              let state = mediaState.legacySimDownloadStatus[stationID]?.state
        else { return }

        switch state {
        case .downloading, .scheduled:
            notifyChangeStatus(status: .init(state: .busy), for: stationID)
            legacyBusy[stationID] = .pausing
            let paused = await legacySimRadioDownload.cancelDownloadStation(withID: stationID)
            if !paused {
                legacyBusy[stationID] = nil
            }
        default:
            break
        }
    }
}

private extension DefaultSimRadioLibrary {
    func handleDownloaderEvent(_ event: LegacySimRadioDownloadEvent) async {
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
            let reason = legacyBusy.removeValue(forKey: event.id)
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

    func updateLegacyStationsDownloadState() async {
        for (stationID, storageState) in storage.allStoredLegacyStationStates {
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

    func resumeDownloading(_ stationID: LegacySimStation.ID) async {
        do {
            guard let mediaState else { return }
            let current = mediaState.legacySimRadio
            let currentStatus = try await current.calculateStationLocalStatus(stationID)
            switch currentStatus {
            case .completed:
                storage.setStorageState(.downloaded, for: stationID)
                notifyChangeStatus(status: .init(state: .completed), for: stationID)
                return
            case let .partial(missing: missing):
                await legacySimRadioDownload.downloadStation(withID: stationID, missing: missing)
            case .missing:
                break
            }
        } catch {
            print(error)
        }
        notifyChangeStatus(status: .initial, for: stationID)
        await legacySimRadioDownload.downloadStation(withID: stationID)
    }

    func removeDownloadFiles(_ stationID: LegacySimStation.ID) async {
        guard let mediaState else { return }
        storage.setStorageState(.removing, for: stationID)
        let otherDownloadedStationIDs = mediaState.legacySimDownloadStatus.keys.filter { $0 != stationID }
        let fileGroupIDsToKeep = mediaState.legacySimRadio.sharedFileGroups(
            of: stationID,
            among: otherDownloadedStationIDs
        )
        let stationFileGroupIDs = mediaState.legacySimRadio.stations[stationID]?.fileGroupIDs ?? []
        let fileGroupIDsToDelete = Array(Set(stationFileGroupIDs).subtracting(fileGroupIDsToKeep))
        do {
            try await removeFiles(of: fileGroupIDsToDelete)
            stationID.directoryURL.removeDirectoryIfEmpty()

        } catch {
            print(error)
        }
        storage.removeStorageState(for: stationID)
    }

    func notifyChangeStatus(status: MediaDownloadStatus?, for stationID: LegacySimStation.ID) {
        delegate?.simRadioLibrary(
            self,
            didChangeDownloadStatus: status,
            for: stationID
        )
    }

    func removeFiles(of fileGroupIDs: [LegacySimFileGroup.ID]) async throws {
        guard let allFileGroups = mediaState?.legacySimRadio.fileGroups else { return }
        let fileGroups = fileGroupIDs.compactMap { allFileGroups[$0] }
        for fileGroup in fileGroups {
            let fileURLs = fileGroup.files.map { fileGroup.id.localFileURL(for: $0.url) }
            fileURLs.forEach { $0.remove() }
            fileGroup.id.directoryURL.removeDirectoryIfEmpty()
        }
    }
}

// swiftlint:enable file_length
