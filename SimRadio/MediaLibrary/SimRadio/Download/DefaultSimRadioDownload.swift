//
//  DefaultSimRadioDownload.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 25.06.2025.
//

// swiftlint:disable file_length function_body_length cyclomatic_complexity

import Foundation

private enum DownloadLog {
    case info(verbose: Bool), warning, error
}

private let logSettings: [DownloadLog] = [.warning, .error]

extension DefaultSimRadioDownload: SimRadioDownload {}

actor DefaultSimRadioDownload {
    @MainActor weak var mediaState: SimRadioMediaState?
    private let downloadQueue: DownloadQueue
    private var stationDownloads: [SimStation.ID: StationDownloadInfo] = [:]
    private var trackListDownloads: [TrackList.ID: TrackListDownloadInfo] = [:]
    private var trackListIDByURL: [URL: TrackList.ID] = [:]

    let events: AsyncStream<SimRadioDownloadEvent>
    private var eventContinuation: AsyncStream<SimRadioDownloadEvent>.Continuation?

    struct StationDownloadInfo {
        var status: SimRadioDownloadStatus
        let trackListIDs: [TrackList.ID]
    }

    struct TrackListDownloadInfo {
        let id: TrackList.ID
        var status: SimRadioDownloadStatus
        var files: [FileDownloadInfo]
    }

    struct FileDownloadInfo: Equatable {
        let request: DownloadQueue.DownloadRequest
        var status: SimRadioDownloadStatus
    }

    init() {
        downloadQueue = DownloadQueue(
            destinationDirectory: .documentsDirectory,
            maxConcurrentDownloads: 8
        )

        (events, eventContinuation) = AsyncStream.makeStream(of: SimRadioDownloadEvent.self)

        Task { [weak self] in
            guard let self else { return }
            let stream = downloadQueue.events
            for await event in stream {
                await handleDownloaderEvent(event)
            }
            await finishEventStream()
        }
    }

    deinit {
        eventContinuation?.finish()
    }

    func downloadStation(withID id: SimStation.ID, missing: [TrackList.ID: [URL]]?) {
        Task {
            await doDownloadStation(withID: id, missing: missing)
        }
    }

    func cancelDownloadStation(withID id: SimStation.ID) async -> Bool {
        log(info: "Cancelling download for station \(id.value)")
        guard let requests = requestsOnlyForStation(withID: id) else {
            log(warning: "Cannot cancel download for untracked station: \(id.value)")
            return false
        }
        log(info: "Cancelling \(requests.count) download requests for station \(id.value)")
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
            log(error: "Station \(id) not found in mediaState")
            return
        }

        guard !stationDownloads.keys.contains(id) else {
            log(warning: "Station \(id) already tracked for download.")
            return
        }

        log(info: "Starting download for station \(id)")
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
            let tracks = trackList.tracks.filter { $0.path != nil }
            let missingFiles = Set(missing?[trackList.id] ?? [])
            let files = tracks.map {
                guard let url = $0.url, let destinationDirectoryPath = $0.destinationDirectoryPath else { fatalError() }
                return FileDownloadInfo(
                    request: .init(sourceURL: url, destinationDirectoryPath: destinationDirectoryPath),
                    status: isPartialDownload
                        ? missingFiles.contains(url) ? .initial : .init(state: .completed)
                        : .initial
                )
            }
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
            log(info: "Queuing trackList \(trackListID) with \(files.count) files for station \(station.id.value)")
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
            log(warning: "Missing trackListID for event: \(event)")
            return
        }

        guard var trackListDownload = trackListDownloads[trackListID] else {
            log(warning: "Group \(trackListID) not found for event: \(event)")
            return
        }

        guard let fileIndex = trackListDownload.files
            .firstIndex(where: { $0.request == event.downloadRequest })
        else {
            log(warning: "fileIndex for event: \(event)")
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
            log(warning: "Could not find station for trackListID \(trackListID)")
        }

        if event.state.isFinished || event.state.isFailed {
            trackListIDByURL[event.downloadRequest.sourceURL] = nil
        }

        for stationID in trackListStations {
            guard let stationInfo = stationDownloads[stationID] else {
                log(error: "Station \(stationID) not found during status calculation.")
                continue
            }

            guard let newStationStatus = await calculateStationStatus(stationInfo: stationInfo) else {
                log(warning: "nil ftatus for station with id \(stationID)")
                continue
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
            print("")
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
        log(info: "Updating file sizes for trackList \(trackListID)")
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
                        log(error: "Failed to fetch size for \(url.lastPathComponent): \(error)")
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
        log(info: "Finished updating file sizes for trackList \(trackListID)")
    }

    /// Updates the total size for a specific file within a group.
    func update(fileURL: URL, trackListID: TrackList.ID, size: Int64) async {
        guard var trackList = trackListDownloads[trackListID],
              let fileIndex = trackList.files.firstIndex(where: { $0.request.sourceURL == fileURL })
        else {
            log(error: "File \(fileURL.lastPathComponent) " +
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
            guard logSettings.logInfo else { return }
            let overall = await Array(stationDownloads.values).overallStatus
            log(info: "--- Download Progress (\(Date().ISO8601Format())) ---")
            if let overall {
                log(info: "Overall: \(overall.state) - \(overall.progressString)")
            }

            for (stationID, station) in stationDownloads {
                log(info: "  Station \(stationID.value): \(station.status.state) - \(station.status.progressString)")
                for groupID in station.trackListIDs {
                    let group = await groupStatus(groupID)
                    if let group {
                        log(info: "    Group \(groupID.value): \(group.state) - \(group.progressString)")
                    }
                    // Optional: Print individual file status within group for detailed debug
                    if logSettings.logVerboseInfo, let group = trackListDownloads[groupID] {
                        for file in group.files {
                            let fileName = file.request.sourceURL.lastPathComponent
                            log(verboseInfo: "      File \(fileName): \(file.status.state) " +
                                "- \(file.status.progressString)")
                        }
                    }
                }
            }
            log(info: "---------------------------------------")
        }
    }
}

extension DefaultSimRadioDownload.FileDownloadInfo {
    func updated(queueState: DownloadQueue.DownloadState) -> DefaultSimRadioDownload.FileDownloadInfo {
        let newStatus: SimRadioDownloadStatus = switch queueState {
        case .queued:
            .init(
                state: .scheduled,
                downloadedBytes: status.downloadedBytes,
                totalBytes: status.totalBytes
            )
        case let .progress(downloadedBytes, totalBytes):
            .init(
                state: .downloading,
                downloadedBytes: downloadedBytes,
                totalBytes: totalBytes == 0 ? status.totalBytes : totalBytes
            )
        case .completed:
            .init(
                state: .completed,
                downloadedBytes: status.totalBytes,
                totalBytes: status.totalBytes
            )
        case .canceled:
            .init(
                state: .canceled,
                downloadedBytes: status.downloadedBytes,
                totalBytes: status.totalBytes
            )
        case .failed:
            .init(
                state: .failed([request.sourceURL]),
                downloadedBytes: status.downloadedBytes,
                totalBytes: status.totalBytes
            )
        }
        return .init(
            request: request,
            status: newStatus
        )
    }
}

private protocol SimRadioDownloadStatusProtocol {
    var state: SimRadioDownloadState { get }
    var totalBytes: Int64 { get }
    var downloadedBytes: Int64 { get }
}

extension SimRadioDownloadStatus: SimRadioDownloadStatusProtocol {}

extension DefaultSimRadioDownload.FileDownloadInfo: SimRadioDownloadStatusProtocol {
    var state: SimRadioDownloadState { status.state }
    var totalBytes: Int64 { status.totalBytes }
    var downloadedBytes: Int64 { status.downloadedBytes }
}

extension DefaultSimRadioDownload.StationDownloadInfo: SimRadioDownloadStatusProtocol {
    var state: SimRadioDownloadState { status.state }
    var totalBytes: Int64 { status.totalBytes }
    var downloadedBytes: Int64 { status.downloadedBytes }
}

// Aggregation logic for collections
extension Collection where Element: SimRadioDownloadStatusProtocol {
    var overallState: SimRadioDownloadState? {
        get async {
            if contains(where: { $0.state == .downloading }) {
                return .downloading
            }

            let incomplete = filter { $0.state != .completed }
            if incomplete.isEmpty {
                return .completed
            }

            if incomplete.contains(where: { $0.state == .canceled }) {
                return .canceled
            }

            if incomplete.contains(where: \.state.isFailed) {
                return .failed(flatMap(\.state.failedURLs))
            }
            return isEmpty ? nil : .scheduled
        }
    }

    var overallTotalBytes: Int64 { reduce(0) { $0 + $1.totalBytes } }
    var overallDownloadedBytes: Int64 { reduce(0) { $0 + $1.downloadedBytes } }

    var overallStatus: SimRadioDownloadStatus? {
        get async {
            await overallState.map {
                .init(
                    state: $0,
                    downloadedBytes: overallDownloadedBytes,
                    totalBytes: overallTotalBytes
                )
            }
        }
    }
}

extension Int64 {
    private nonisolated(unsafe) static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter
    }()

    var bytesToMB: String {
        Self.formatter.string(fromByteCount: Swift.max(0, self))
    }
}

private func log(verboseInfo: String) {
    guard logSettings.logVerboseInfo else { return }
    print(verboseInfo)
}

private func log(info: String) {
    guard logSettings.logInfo else { return }
    print(info)
}

private func log(warning: String) {
    guard logSettings.contains(
        where: {
            if case .warning = $0 { return true }
            return false
        }
    ) else { return }
    print(warning)
}

private func log(error: String) {
    guard logSettings.contains(
        where: {
            if case .error = $0 { return true }
            return false
        }
    ) else { return }
    print(error)
}

extension Collection<DownloadLog> {
    var logVerboseInfo: Bool {
        contains(
            where: {
                if case let .info(verbose) = $0 {
                    if verbose { return true }
                }
                return false
            }
        )
    }

    var logInfo: Bool {
        contains(
            where: {
                if case .info = $0 { return true }
                return false
            }
        )
    }
}

// swiftlint:enable file_length function_body_length cyclomatic_complexity
