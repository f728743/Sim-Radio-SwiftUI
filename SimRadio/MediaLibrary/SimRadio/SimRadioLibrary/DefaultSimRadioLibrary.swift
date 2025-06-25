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
    let newModelSimRadioDownload: any NewModelSimRadioDownload

    let storage: any SimRadioStorage
    private var busy: [SimStation.ID: BusyReason] = [:]
    private var newModelBusy: [NewModelSimStation.ID: BusyReason] = [:]
    weak var mediaState: SimRadioMediaState?
    weak var delegate: SimRadioLibraryDelegate?

    init(
        storage: any SimRadioStorage,
        simRadioDownload: any SimRadioDownload,
        newModelSimRadioDownload: any NewModelSimRadioDownload
    ) {
        self.storage = storage
        self.simRadioDownload = simRadioDownload
        self.newModelSimRadioDownload = newModelSimRadioDownload

        Task { [weak self] in
            guard let self else { return }
            let stream = await self.simRadioDownload.events
            for await event in stream {
                await handleDownloaderEvent(event)
            }
        }

        Task { [weak self] in
            guard let self else { return }
            let stream = await self.newModelSimRadioDownload.events
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

    func testPopulateOld() async {
        let baseUrl = "https://raw.githubusercontent.com/tmp-acc/"
        let simRadioURLs = [
            //            "GTA-V-Radio-Stations-TestDownload/short/sim_radio_stations.json",
//            "GTA-V-Radio-Stations-TestDownload/long/sim_radio_stations.json",
//            "GTA-IV-Radio-Stations/master/sim_radio_stations.json",
            "GTA-V-Radio-Stations/master/sim_radio_stations.json"
        ].compactMap { URL(string: "\(baseUrl)\($0)") }
        await addSimRadio(urls: simRadioURLs)
    }

    func testPopulateNew() async {
        let newModelBaseURL = "https://media.githubusercontent.com/media/maxerohingta/"
        let newModelSimRadioURLs = [
            "convert_gta5_audio/refs/heads/main/converted_m4a/new_sim_radio_stations.json"
        ].compactMap { URL(string: "\(newModelBaseURL)\($0)") }
        await addNewModelSimRadio(urls: newModelSimRadioURLs)
    }

    func downloadStation(_ stationID: SimStation.ID) async {
        if let state = mediaState?.simDownloadStatus[stationID]?.state, state == .paused {
            await resumeDownloading(stationID)
        } else {
            storage.setStorageState(.downloadStarted, for: stationID)
            await simRadioDownload.downloadStation(withID: stationID)
        }
    }

    func downloadStation(_ stationID: NewModelSimStation.ID) async {
        if let state = mediaState?.newModelSimDownloadStatus[stationID]?.state, state == .paused {
            await resumeDownloading(stationID)
        } else {
            storage.setStorageState(.downloadStarted, for: stationID)
            await newModelSimRadioDownload.downloadStation(withID: stationID)
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

    func removeDownload(_ stationID: NewModelSimStation.ID) async {
        guard let mediaState,
              let state = mediaState.newModelSimDownloadStatus[stationID]?.state
        else { return }

        switch state {
        case .scheduled, .downloading:
            notifyChangeStatus(status: .init(state: .busy), for: stationID)
            newModelBusy[stationID] = .canceling
            let paused = await newModelSimRadioDownload.cancelDownloadStation(withID: stationID)
            if !paused {
                newModelBusy[stationID] = nil
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

    func pauseDownload(_: SimStation.ID) async {}

    func pauseDownload(_ stationID: NewModelSimStation.ID) async {
        guard let mediaState,
              let state = mediaState.newModelSimDownloadStatus[stationID]?.state
        else { return }

        switch state {
        case .downloading, .scheduled:
            notifyChangeStatus(status: .init(state: .busy), for: stationID)
            newModelBusy[stationID] = .pausing
            let paused = await newModelSimRadioDownload.cancelDownloadStation(withID: stationID)
            if !paused {
                newModelBusy[stationID] = nil
            }
        default:
            break
        }
    }

    func load() {
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

    func removeDownload(_ stationIDs: [NewModelSimStation.ID]) async {
        for stationID in stationIDs {
            await removeDownload(stationID)
        }
    }

    func removeDownloadFiles(_ stationID: SimStation.ID) async {
        guard let mediaState else { return }
        storage.setStorageState(.removing, for: stationID)
        let otherDownloadedStationIDs = mediaState.simDownloadStatus.keys.filter { $0 != stationID }
        let fileGroupIDsToKeep = mediaState.simRadio.sharedFileGroups(of: stationID, among: otherDownloadedStationIDs)
        let stationFileGroupIDs = mediaState.simRadio.stations[stationID]?.fileGroupIDs ?? []
        let fileGroupIDsToDelete = Array(Set(stationFileGroupIDs).subtracting(fileGroupIDsToKeep))
        do {
            try await removeFiles(of: fileGroupIDsToDelete)
            stationID.directoryURL.removeDirectoryIfEmpty()

        } catch {
            print(error)
        }
        storage.removeStorageState(for: stationID)
    }

    func removeDownloadFiles(_ stationID: NewModelSimStation.ID) async {
        guard let mediaState else { return }
        storage.setStorageState(.removing, for: stationID)
        let otherDownloadedStationIDs = mediaState.newModelSimDownloadStatus.keys.filter { $0 != stationID }
        let fileGroupIDsToKeep = mediaState.newModelSimRadio.sharedTrackLists(
            of: stationID,
            among: otherDownloadedStationIDs
        )
        let stationTrackListIDs = mediaState.newModelSimRadio.stations[stationID]?.trackLists ?? []
        let trackListIDsToDelete = Array(Set(stationTrackListIDs).subtracting(fileGroupIDsToKeep))
        do {
            try await removeFiles(of: trackListIDsToDelete)
//            stationID.directoryURL.removeDirectoryIfEmpty() TODO:  remove tracklist directories

        } catch {
            print(error)
        }
        storage.removeStorageState(for: stationID)
    }

    func handleDownloaderEvent(_: NewModelSimRadioDownloadEvent) async {
        // TODO:
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
        let jsonData = try await URLSession.shared.data(from: fileURL)
        let radio = try JSONDecoder().decode(SimRadioDTO.GameSeries.self, from: jsonData.0)
        guard let url = radio.origin.map({ URL(string: $0) }) ?? nil else { return }
        notifyAdded(SimRadioMedia(dto: radio, origin: url))
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
        let newSimRadio = SimRadioMedia(dto: radio, origin: url)

        guard newSimRadio.series.keys.count == 1,
              let seriesID = newSimRadio.series.keys.first
        else { return }

        let stations = Array(newSimRadio.stations.keys)
        await removeDownload(stations)
        try saveJsonData(series: radio, origin: url)
        storage.addSeries(id: seriesID)
        notifyAdded(newSimRadio)
    }

    func addNewModelSimRadio(urls: [URL]) async {
        for url in urls {
            do {
                try await addNewModelSimRadio(url: url)
            } catch {
                print(error)
            }
        }
    }

    func addNewModelSimRadio(url: URL) async throws {
        let jsonData = try await URLSession.shared.data(from: url)
        let radio = try JSONDecoder().decode(NewModelSimRadioDTO.GameSeries.self, from: jsonData.0)

        let newSimRadio = NewModelSimRadioMedia(origin: url, dto: radio)

        print("ℹ️ documents directory: \(URL.documentsDirectory.path)")

        guard newSimRadio.series.keys.count == 1,
              let seriesID = newSimRadio.series.keys.first
        else { return }

        let stations = Array(newSimRadio.stations.keys)
        await removeDownload(stations)
        try saveJsonData(series: radio, origin: url)
        storage.addSeries(id: seriesID)
        notifyAdded(newSimRadio)
    }

    func notifyAdded(_ new: SimRadioMedia) {
        guard let mediaState else { return }
        let curren = mediaState.simRadio
        delegate?.simRadioLibrary(
            self,
            didChange: SimRadioMedia(
                series: curren.series.merging(new.series) { _, new in new },
                fileGroups: curren.fileGroups.merging(new.fileGroups) { _, new in new },
                stations: curren.stations.merging(new.stations) { _, new in new }
            )
        )
    }

    func notifyAdded(_ new: NewModelSimRadioMedia) {
        guard let mediaState else { return }
        let curren = mediaState.newModelSimRadio
        delegate?.simRadioLibrary(
            self,
            didChange: NewModelSimRadioMedia(
                series: curren.series.merging(new.series) { _, new in new },
                trackLists: curren.trackLists.merging(new.trackLists) { _, new in new },
                stations: curren.stations.merging(new.stations) { _, new in new }
            )
        )
    }

    func saveJsonData(series: SimRadioDTO.GameSeries, origin: URL) throws {
        let directory = SimGameSeries.ID(origin: origin).directoryURL
        try directory.ensureDirectoryExists()
        let fileURL = directory.appending(path: SimGameSeries.defaultFileName, directoryHint: .notDirectory)
        try fileURL.removeFileIfExists()
        let gameSeries = SimRadioDTO.GameSeries(
            origin: origin.absoluteString,
            info: series.info,
            gameSeriesShared: series.gameSeriesShared,
            stations: series.stations
        )
        let jsonData = try JSONEncoder().encode(gameSeries)
        try jsonData.write(to: fileURL)
    }

    func saveJsonData(series: NewModelSimRadioDTO.GameSeries, origin: URL) throws {
        let directory = NewModelSimGameSeries.ID(origin: origin).directoryURL
        try directory.ensureDirectoryExists()
        let fileURL = directory.appending(path: NewModelSimGameSeries.defaultFileName, directoryHint: .notDirectory)
        try fileURL.removeFileIfExists()
        let gameSeries = NewModelSimRadioDTO.GameSeries(
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

    func resumeDownloading(_ stationID: NewModelSimStation.ID) async {
        do {
            guard let mediaState else { return }
            let current = mediaState.newModelSimRadio
            let currentStatus = try await current.calculateStationLocalStatus(stationID)
            switch currentStatus {
            case .completed:
                storage.setStorageState(.downloaded, for: stationID)
                notifyChangeStatus(status: .init(state: .completed), for: stationID)
                return
            case let .partial(missing: missing):
                await newModelSimRadioDownload.downloadStation(withID: stationID, missing: missing)
            case .missing:
                break
            }
        } catch {
            print(error)
        }
        notifyChangeStatus(status: .initial, for: stationID)
        await newModelSimRadioDownload.downloadStation(withID: stationID)
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

    func removeFiles(of fileGroupIDs: [SimFileGroup.ID]) async throws {
        guard let allFileGroups = mediaState?.simRadio.fileGroups else { return }
        let fileGroups = fileGroupIDs.compactMap { allFileGroups[$0] }
        for fileGroup in fileGroups {
            let fileURLs = fileGroup.files.map { fileGroup.id.localFileURL(for: $0.url) }
            fileURLs.forEach { $0.remove() }
            fileGroup.id.directoryURL.removeDirectoryIfEmpty()
        }
    }

    func removeFiles(of _: [NewModelTrackList.ID]) async throws {
        // TODO:
//        guard let allFileGroups = mediaState?.simRadio.fileGroups else { return }
//        let fileGroups = fileGroupIDs.compactMap { allFileGroups[$0] }
//        for fileGroup in fileGroups {
//            let fileURLs = fileGroup.files.map { fileGroup.id.localFileURL(for: $0.url) }
//            fileURLs.forEach { $0.remove() }
//            fileGroup.id.directoryURL.removeDirectoryIfEmpty()
//        }
    }

    func notifyChangeStatus(status: MediaDownloadStatus?, for stationID: SimStation.ID) {
        delegate?.simRadioLibrary(
            self,
            didChangeDownloadStatus: status,
            for: stationID
        )
    }

    func notifyChangeStatus(status: MediaDownloadStatus?, for stationID: NewModelSimStation.ID) {
        delegate?.simRadioLibrary(
            self,
            didChangeDownloadStatus: status,
            for: stationID
        )
    }
}

extension MediaDownloadStatus.DownloadState {
    init?(_ state: SimRadioDownloadState) {
        switch state {
        case .completed: self = .completed
        case .scheduled: self = .scheduled
        case .downloading: self = .downloading
        case .failed: self = .paused
        case .canceled:
            return nil
        }
    }
}
