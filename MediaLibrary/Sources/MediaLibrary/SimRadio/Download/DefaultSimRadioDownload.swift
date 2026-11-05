//
//  DefaultSimRadioDownload.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 25.06.2025.
//

import Foundation
import Services

extension DefaultSimRadioDownload: SimRadioDownload {}

public actor DefaultSimRadioDownload {
    @MainActor public weak var mediaState: SimRadioMediaState?
    private let downloadQueue: DownloadQueue
    private var stationDownloads: [SimStation.ID: StationDownloadInfo] = [:]
    private var trackListDownloads: [TrackList.ID: TrackListDownloadInfo] = [:]
    private var trackListIDByURL: [URL: TrackList.ID] = [:]

    public let events: AsyncStream<SimRadioDownloadEvent>
    private var eventContinuation: AsyncStream<SimRadioDownloadEvent>.Continuation?

    public init() {
        downloadQueue = DownloadQueue(
            destinationDirectory: .documentsDirectory,
            maxConcurrentDownloads: 8
        )

        (events, eventContinuation) = AsyncStream.makeStream(of: SimRadioDownloadEvent.self)

        Task { [weak self] in
            guard let self else { return }
            let stream = await downloadQueue.events
            for await event in stream {
                await handleDownloaderEvent(event)
            }
            await finishEventStream()
        }
    }

    deinit {
        eventContinuation?.finish()
    }

    public func downloadStation(withID id: SimStation.ID, missing: [TrackList.ID: [URL]]?) {
        Task {
            await doDownloadStation(withID: id, missing: missing)
        }
    }

    public func cancelDownloadStation(withID id: SimStation.ID) async -> Bool {
        SimRadioDownloadLogger.log(info: "Cancelling download for station \(id.value)")
        guard let requests = requestsOnlyForStation(withID: id) else {
            SimRadioDownloadLogger.log(warning: "Cannot cancel download for untracked station: \(id.value)")
            return false
        }
        SimRadioDownloadLogger.log(info: "Cancelling \(requests.count) download requests for station \(id.value)")
        for request in requests {
            await downloadQueue.cancel(request)
        }
        return true
    }
}

private extension DefaultSimRadioDownload {
    func finishEventStream() {
        eventContinuation?.finish()
        eventContinuation = nil
    }

    func doDownloadStation(withID id: SimStation.ID, missing: [TrackList.ID: [URL]]?) async {
        guard let mediaState = await mediaState else { return }

        // Access mediaState on the MainActor
        let stations = await mediaState.simRadio.stations
        guard let station = stations[id] else {
            SimRadioDownloadLogger.log(error: "Station \(id) not found in mediaState")
            return
        }

        guard !stationDownloads.keys.contains(id) else {
            SimRadioDownloadLogger.log(warning: "Station \(id) already tracked for download.")
            return
        }

        SimRadioDownloadLogger.log(info: "Starting download for station \(id)")
        await download(station: station, missing: missing)
    }

    func download(station: SimStation, missing: [TrackList.ID: [URL]]?) async {
        guard let mediaState = await mediaState else { return }
        let allTrackLists = await mediaState.simRadio.trackLists
        let usedTrackLists = allTrackLists.findAllUsedTrackLists(usedIDs: station.trackLists)
        let trackListsToSkip = await alreadyDownloaded(of: usedTrackLists.map(\.id))
        let trackListsToDownload = usedTrackLists.filter { !trackListsToSkip.contains($0.id) }
        let isPartialDownload = missing != nil
        stationDownloads[station.id] = StationDownloadInfo(
            status: .initial,
            trackListIDs: usedTrackLists.map(\.id)
        )
        var stationDownloadedFiles: [TrackList.ID: [FileDownloadInfo]] = [:]
        for trackList in trackListsToDownload {
            let files = makeFileDownloads(for: trackList, missing: missing)
            let trackListDownload = TrackListDownloadInfo(
                id: trackList.id,
                status: isPartialDownload ? .init(
                    state: missing?.keys.contains(trackList.id) == true ? .downloading : .completed
                ) : .initial,
                files: files
            )
            trackListDownloads[trackList.id] = trackListDownload
            stationDownloadedFiles[trackList.id] = files
        }

        for (trackListID, files) in stationDownloadedFiles {
            SimRadioDownloadLogger
                .log(info: "Queuing trackList \(trackListID) with \(files.count) files for station \(station.id.value)")
            Task {
                await updateFileSizes(for: files.map(\.request.sourceURL), trackListID: trackListID)
            }
        }

        let downloadRequest = stationDownloadedFiles.flatMap { trackListID, fileDownloads in
            let missingFilesInGroup = Set(missing?[trackListID] ?? [])
            let requests: [DownloadQueue.DownloadRequest] = fileDownloads.compactMap { fileDownload in
                let request = fileDownload.request
                return isPartialDownload
                    ? missingFilesInGroup.contains(fileDownload.request.localFileURL) ? request : nil
                    : request
            }
            requests.forEach { trackListIDByURL[$0.sourceURL] = trackListID }
            return requests
        }
        eventContinuation?.yield(.init(id: station.id, status: .initial))
        await downloadQueue.append(downloadRequest)
    }

    func makeFileDownloads(
        for trackList: TrackList,
        missing: [TrackList.ID: [URL]]?
    ) -> [FileDownloadInfo] {
        let isPartialDownload = missing != nil
        let tracks = trackList.tracks.filter { $0.path != nil }
        let missingFiles = Set(missing?[trackList.id] ?? [])
        return tracks.map {
            guard let url = $0.url, let destinationDirectoryPath = $0.destinationDirectoryPath else { fatalError() }
            let request = DownloadQueue.DownloadRequest(
                sourceURL: url,
                destinationDirectoryPath: destinationDirectoryPath
            )
            return FileDownloadInfo(
                request: request,
                status: isPartialDownload
                    ? missingFiles.contains(request.localFileURL) ? .initial : .init(state: .completed)
                    : .initial
            )
        }
    }

    func alreadyDownloaded(of groupIDs: [TrackList.ID]) async -> [TrackList.ID] {
        let allStations = await mediaState?.simRadio.stations ?? [:]
        let allTrackLists = await mediaState?.simRadio.trackLists ?? [:]
        let downloadStatus = await mediaState?.simDownloadStatus ?? [:]
        let downloadedTrackLists = Set(
            downloadStatus
                .filter { $0.value.state == .completed }
                .map {
                    let stationTrackLists = allStations[$0.key]?.trackLists ?? []
                    return allTrackLists.findAllUsedTrackLists(usedIDs: stationTrackLists).map(\.id)
                }
                .flatMap(\.self)
        )
        return groupIDs.filter { trackListDownloads.keys.contains($0) || downloadedTrackLists.contains($0) }
    }

    func requestsOnlyForStation(withID id: SimStation.ID) -> [DownloadQueue.DownloadRequest]? {
        var stationDownloads = stationDownloads
        guard let stationInfo = stationDownloads.removeValue(forKey: id) else {
            return nil
        }

        let otherGroupIDs = Set(stationDownloads.values.flatMap(\.trackListIDs))
        let stationOnlyTrackListIDs = stationInfo.trackListIDs.filter { !otherGroupIDs.contains($0) }

        return stationOnlyTrackListIDs.flatMap { trackListID in
            downloadRequestInProgressForTrackList(withID: trackListID)
        }
    }

    func downloadRequestInProgressForTrackList(withID trackListID: TrackList.ID) -> [DownloadQueue.DownloadRequest] {
        (trackListDownloads[trackListID]?.files ?? []).compactMap {
            guard $0.status.state.isInProgress else { return nil }
            return $0.request
        }
    }

    func handleDownloaderEvent(_ event: DownloadQueue.Event) async {
        guard let trackListID = trackListIDByURL[event.downloadRequest.sourceURL] else {
            SimRadioDownloadLogger.log(warning: "Missing trackListID for event: \(event)")
            return
        }

        guard var trackListDownload = trackListDownloads[trackListID] else {
            SimRadioDownloadLogger.log(warning: "Group \(trackListID) not found for event: \(event)")
            return
        }

        guard let fileIndex = trackListDownload.files
            .firstIndex(where: { $0.request == event.downloadRequest })
        else {
            SimRadioDownloadLogger.log(warning: "fileIndex for event: \(event)")
            return
        }

        let fileInfo = trackListDownload.files[fileIndex]
        let newFileInfo = fileInfo.updated(queueState: event.state)
        trackListDownload.files[fileIndex] = newFileInfo
        if let newGroupStatus = await trackListDownload.files.overallStatus {
            trackListDownload.status = newGroupStatus
        }
        trackListDownloads[trackListID] = trackListDownload

        let trackListStations = findStationIDs(for: trackListID)
        if trackListStations.isEmpty {
            SimRadioDownloadLogger.log(warning: "Could not find station for trackListID \(trackListID)")
        }

        if event.state.isFinished || event.state.isFailed {
            trackListIDByURL[event.downloadRequest.sourceURL] = nil
        }

        for stationID in trackListStations {
            await updateStationDownloadStatus(for: stationID)
        }
    }

    func updateStationDownloadStatus(for stationID: SimStation.ID) async {
        guard let stationInfo = stationDownloads[stationID] else {
            SimRadioDownloadLogger.log(error: "Station \(stationID) not found during status calculation.")
            return
        }

        guard let newStationStatus = await calculateStationStatus(stationInfo: stationInfo) else {
            SimRadioDownloadLogger.log(warning: "nil ftatus for station with id \(stationID)")
            return
        }
        if newStationStatus.state.isFinished {
            cleanupDownloadTracking(for: stationID)
            stationDownloads[stationID] = nil
        } else {
            stationDownloads[stationID]?.status = newStationStatus
        }

        if stationInfo.status != newStationStatus {
            eventContinuation?.yield(.init(id: stationID, status: newStationStatus))
            logProgress()
        }
    }

    func cleanupDownloadTracking(for stationID: SimStation.ID) {
        guard let stationInfo = stationDownloads.removeValue(forKey: stationID) else {
            return
        }
        let groupIDsToKeep = Set(stationDownloads.values.flatMap(\.trackListIDs))
        stationInfo
            .trackListIDs
            .filter { !groupIDsToKeep.contains($0) }
            .forEach { trackListDownloads[$0] = nil }
    }

    func findStationIDs(for trackListID: TrackList.ID) -> [SimStation.ID] {
        let result = stationDownloads.compactMap { id, download in
            download.trackListIDs.contains(trackListID) ? id : nil
        }
        if result.isEmpty {
            print("--- WARNING: No station found for trackList \(trackListID)")
        }
        return result
    }

    func calculateStationStatus(stationInfo: StationDownloadInfo) async -> SimRadioDownloadStatus? {
        var fileGroupStatuses: [SimRadioDownloadStatus] = []
        for fileGroupID in stationInfo.trackListIDs {
            if let status = await groupStatus(fileGroupID) {
                fileGroupStatuses.append(status)
            }
        }

        return await fileGroupStatuses.overallStatus
    }

    func groupStatus(_ trackListD: TrackList.ID) async -> SimRadioDownloadStatus? {
        await trackListDownloads[trackListD]?.files.overallStatus
    }

    /// Fetches and updates the total size for each file URL using HEAD requests.
    func updateFileSizes(for urls: [URL], trackListID: TrackList.ID) async {
        SimRadioDownloadLogger.log(info: "Updating file sizes for trackList \(trackListID)")
        await withTaskGroup(of: (URL, Int64?).self) { group in
            for url in urls {
                group.addTask {
                    var request = URLRequest(url: url)
                    request.httpMethod = "HEAD"
                    do {
                        let (_, response) = try await URLSession.shared.data(for: request)
                        // Check for Content-Length header
                        let contentLength = response.expectedContentLength // This is Int64
                        return (url, contentLength > 0 ? contentLength : nil) // Return nil if size is unknown/invalid
                    } catch {
                        SimRadioDownloadLogger.log(error: "Failed to fetch size for \(url.lastPathComponent): \(error)")
                        return (url, nil)
                    }
                }
            }

            // Collect results as they complete
            for await (url, size) in group {
                if let size {
                    await update(fileURL: url, trackListID: trackListID, size: size)
                }
            }
        }
        SimRadioDownloadLogger.log(info: "Finished updating file sizes for trackList \(trackListID)")
    }

    /// Updates the total size for a specific file within a group.
    func update(fileURL: URL, trackListID: TrackList.ID, size: Int64) async {
        guard var trackList = trackListDownloads[trackListID],
              let fileIndex = trackList.files.firstIndex(where: { $0.request.sourceURL == fileURL })
        else {
            SimRadioDownloadLogger.log(error: "File \(fileURL.lastPathComponent) " +
                "or trackList \(trackListID) not found for size update.")
            return
        }

        let downloadInfo = trackList.files[fileIndex]
        trackList.files[fileIndex] = .init(
            request: downloadInfo.request,
            status: .init(
                state: downloadInfo.status.state,
                downloadedBytes: downloadInfo.status.state == .completed ? size : downloadInfo.downloadedBytes,
                totalBytes: size
            )
        )
        if let newGroupStatus = await trackList.files.overallStatus {
            trackList.status = newGroupStatus
        }
        trackListDownloads[trackListID] = trackList
    }

    func logProgress() {
        Task {
            guard SimRadioDownloadLogger.isInfoEnabled else { return }
            let overall = await Array(stationDownloads.values).overallStatus
            SimRadioDownloadLogger.log(info: "--- Download Progress (\(Date().ISO8601Format())) ---")
            if let overall {
                SimRadioDownloadLogger.log(info: "Overall: \(overall.state) - \(overall.progressString)")
            }

            for (stationID, station) in stationDownloads {
                SimRadioDownloadLogger
                    .log(
                        info: "  Station \(stationID.value): \(station.status.state) - \(station.status.progressString)"
                    )
                for groupID in station.trackListIDs {
                    let group = await groupStatus(groupID)
                    if let group {
                        SimRadioDownloadLogger
                            .log(info: "    Group \(groupID.value): \(group.state) - \(group.progressString)")
                    }
                    // Optional: Print individual file status within group for detailed debug
                    if SimRadioDownloadLogger.isVerboseInfoEnabled, let group = trackListDownloads[groupID] {
                        for file in group.files {
                            let fileName = file.request.sourceURL.lastPathComponent
                            SimRadioDownloadLogger.log(verboseInfo: "      File \(fileName): \(file.status.state) " +
                                "- \(file.status.progressString)")
                        }
                    }
                }
            }
            SimRadioDownloadLogger.log(info: "---------------------------------------")
        }
    }
}
