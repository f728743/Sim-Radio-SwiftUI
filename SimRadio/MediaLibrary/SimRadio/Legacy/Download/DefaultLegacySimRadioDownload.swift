//
//  DefaultLegacySimRadioDownload.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import Foundation

// swiftlint:disable file_length
private enum DownloadLog {
    case info(verbose: Bool), warning, error
}

private let logSettings: [DownloadLog] = [.warning, .error]

extension DefaultLegacySimRadioDownload: LegacySimRadioDownload {}

actor DefaultLegacySimRadioDownload {
    @MainActor weak var mediaState: SimRadioMediaState?
    private let downloadQueue: DownloadQueue
    private var stationDownloads: [LegacySimStation.ID: StationDownloadInfo] = [:]
    private var groupDownloads: [LegacySimFileGroup.ID: FileGroupDownloadInfo] = [:]

    let events: AsyncStream<LegacySimRadioDownloadEvent>
    private var eventContinuation: AsyncStream<LegacySimRadioDownloadEvent>.Continuation?

    struct StationDownloadInfo {
        var status: SimRadioDownloadStatus
        let fileGroupIDs: [LegacySimFileGroup.ID]
    }

    struct FileGroupDownloadInfo {
        let id: LegacySimFileGroup.ID
        var status: SimRadioDownloadStatus
        var files: [FileDownloadInfo]
    }

    struct FileDownloadInfo: Equatable {
        let url: URL
        var status: SimRadioDownloadStatus
    }

    init() {
        downloadQueue = DownloadQueue(
            destinationDirectory: .documentsDirectory,
            maxConcurrentDownloads: 8
        )

        (events, eventContinuation) = AsyncStream.makeStream(of: LegacySimRadioDownloadEvent.self)

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

    func downloadStation(withID id: LegacySimStation.ID, missing: [LegacySimFileGroup.ID: [URL]]?) {
        Task {
            await doDownloadStation(withID: id, missing: missing)
        }
    }

    func cancelDownloadStation(withID id: LegacySimStation.ID) async -> Bool {
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

private extension DefaultLegacySimRadioDownload {
    func finishEventStream() {
        eventContinuation?.finish()
        eventContinuation = nil
    }

    func doDownloadStation(withID id: LegacySimStation.ID, missing: [LegacySimFileGroup.ID: [URL]]?) async {
        guard let mediaState = await mediaState else { return }

        // Access mediaState on the MainActor
        let stations = await mediaState.legacySimRadio.stations
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

    func download(station: LegacySimStation, missing: [LegacySimFileGroup.ID: [URL]]?) async {
        guard let mediaState = await mediaState else { return }
        stationDownloads[station.id] = StationDownloadInfo(status: .initial, fileGroupIDs: station.fileGroupIDs)
        let isPartialDownload = missing != nil
        var groupURLs: [LegacySimFileGroup.ID: [URL]] = [:]
        let allFileGroups = await mediaState.legacySimRadio.fileGroups
        let groupsToSkip = await alreadyDownloaded(of: station.fileGroupIDs)
        for groupID in station.fileGroupIDs {
            guard !groupsToSkip.contains(groupID),
                  let urls = allFileGroups[groupID]?.files.compactMap(\.url) else { continue }

            let missingFilesInGroup = Set(missing?[groupID] ?? [])

            let files = urls.map {
                FileDownloadInfo(
                    url: $0,
                    status: isPartialDownload
                        ? missingFilesInGroup.contains($0) ? .initial : .init(state: .completed)
                        : .initial
                )
            }

            let groupInfo = FileGroupDownloadInfo(
                id: groupID,
                status: isPartialDownload ? .init(
                    state: missing?.keys.contains(groupID) == true ? .downloading : .completed
                ) : .initial,
                files: files
            )
            groupDownloads[groupID] = groupInfo
            groupURLs[groupID] = urls
        }

        for (groupID, urls) in groupURLs {
            log(info: "Queuing group \(groupID) with \(urls.count) files for station \(station.id.value)")
            Task {
                await updateFileSizes(for: urls, groupID: groupID) // Pass groupID here too
            }
        }

        let downloadRequest: [DownloadQueue.DownloadRequest] = groupURLs.flatMap { groupID, urls in
            let missingFilesInGroup = Set(missing?[groupID] ?? [])
            let groupRequests: [DownloadQueue.DownloadRequest] = urls.compactMap {
                let request = DownloadQueue.DownloadRequest(
                    sourceURL: $0,
                    destinationDirectoryPath: groupID.value
                )
                return isPartialDownload
                    ? missingFilesInGroup.contains($0) ? request : nil
                    : request
            }
            return groupRequests
        }
        eventContinuation?.yield(.init(id: station.id, status: .initial))
        await downloadQueue.append(downloadRequest)
    }

    func alreadyDownloaded(of groupIDs: [LegacySimFileGroup.ID]) async -> [LegacySimFileGroup.ID] {
        let allStations = await mediaState?.legacySimRadio.stations ?? [:]
        let downloadStatus = await mediaState?.legacySimDownloadStatus ?? [:]

        let downloadedGroups = Set(
            downloadStatus
                .filter { $0.value.state == .completed }
                .compactMap { allStations[$0.key]?.fileGroupIDs }
                .flatMap(\.self)
        )
        return groupIDs.filter { groupDownloads.keys.contains($0) || downloadedGroups.contains($0) }
    }

    func requestsOnlyForStation(withID id: LegacySimStation.ID) -> [DownloadQueue.DownloadRequest]? {
        var stationDownloads = stationDownloads
        guard let stationInfo = stationDownloads.removeValue(forKey: id) else {
            return nil
        }

        let otherGroupIDs = Set(stationDownloads.values.flatMap(\.fileGroupIDs))
        let stationOnlyGroupIDs = stationInfo.fileGroupIDs.filter { !otherGroupIDs.contains($0) }

        return stationOnlyGroupIDs.flatMap { groupID in
            downloadRequestInProgressForGroup(withID: groupID)
        }
    }

    func downloadRequestInProgressForGroup(withID groupID: LegacySimFileGroup.ID) -> [DownloadQueue.DownloadRequest] {
        (groupDownloads[groupID]?.files ?? []).compactMap {
            guard $0.status.state.isInProgress else { return nil }
            return .init(sourceURL: $0.url, destinationDirectoryPath: groupID.value)
        }
    }

    func groupID(of downloadRequest: DownloadQueue.DownloadRequest) -> LegacySimFileGroup.ID {
        .init(value: downloadRequest.destinationDirectoryPath)
    }

    func handleDownloaderEvent(_ event: DownloadQueue.Event) async {
        let groupID = groupID(of: event.downloadRequest)
        guard let groupDownload = groupDownloads[groupID] else {
            log(warning: "Missing groupID for event: \(event)")
            return
        }

        guard let fileIndex = groupDownload.files
            .firstIndex(where: { $0.url == event.downloadRequest.sourceURL })
        else {
            log(warning: "fileIndex for event: \(event)")
            return
        }

        guard var groupInfo = groupDownloads[groupID] else {
            log(warning: "Group \(groupID) not found for event: \(event)")
            return
        }

        let fileInfo = groupInfo.files[fileIndex]
        let newFileInfo = fileInfo.updated(queueState: event.state)
        groupInfo.files[fileIndex] = newFileInfo
        if let newGroupStatus = await groupInfo.files.overallStatus {
            groupInfo.status = newGroupStatus
        }
        groupDownloads[groupID] = groupInfo

        let groupStations = findStationIDs(for: groupID)
        for stationID in groupStations {
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
        if groupStations.isEmpty {
            log(warning: "Could not find station for groupID \(groupID)")
        }
    }

    func cleanupDownloadTracking(for stationID: LegacySimStation.ID) {
        guard let stationInfo = stationDownloads.removeValue(forKey: stationID) else {
            return
        }
        let groupIDsToKeep = Set(stationDownloads.values.flatMap(\.fileGroupIDs))
        stationInfo
            .fileGroupIDs
            .filter { !groupIDsToKeep.contains($0) }
            .forEach { groupDownloads[$0] = nil }
    }

    func findStationIDs(for groupID: LegacySimFileGroup.ID) -> [LegacySimStation.ID] {
        stationDownloads.compactMap { id, download in
            download.fileGroupIDs.contains(groupID) ? id : nil
        }
    }

    func calculateStationStatus(stationInfo: StationDownloadInfo) async -> SimRadioDownloadStatus? {
        var fileGroupStatuses: [SimRadioDownloadStatus] = []
        for fileGroupID in stationInfo.fileGroupIDs {
            if let status = await groupStatus(fileGroupID) {
                fileGroupStatuses.append(status)
            }
        }

        return await fileGroupStatuses.overallStatus
    }

    func groupStatus(_ groupID: LegacySimFileGroup.ID) async -> SimRadioDownloadStatus? {
        await groupDownloads[groupID]?.files.overallStatus
    }

    /// Fetches and updates the total size for each file URL using HEAD requests.
    func updateFileSizes(for urls: [URL], groupID: LegacySimFileGroup.ID) async {
        log(info: "Updating file sizes for group \(groupID)")
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
                    await update(fileURL: url, groupID: groupID, size: size)
                }
            }
        }
        log(info: "Finished updating file sizes for group \(groupID)")
    }

    /// Updates the total size for a specific file within a group.
    func update(fileURL: URL, groupID: LegacySimFileGroup.ID, size: Int64) async {
        guard var groupInfo = groupDownloads[groupID],
              let fileIndex = groupInfo.files.firstIndex(where: { $0.url == fileURL })
        else {
            log(error: "File \(fileURL.lastPathComponent) " +
                "or group \(groupID) not found for size update.")
            return
        }

        let downloadInfo = groupInfo.files[fileIndex]
        groupInfo.files[fileIndex] = .init(
            url: downloadInfo.url,
            status: .init(
                state: downloadInfo.status.state,
                downloadedBytes: downloadInfo.status.state == .completed ? size : downloadInfo.downloadedBytes,
                totalBytes: size
            )
        )
        if let newGroupStatus = await groupInfo.files.overallStatus {
            groupInfo.status = newGroupStatus
        }
        groupDownloads[groupID] = groupInfo
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
                for groupID in station.fileGroupIDs {
                    let group = await groupStatus(groupID)
                    if let group {
                        log(info: "    Group \(groupID.value): \(group.state) - \(group.progressString)")
                    }
                    // Optional: Print individual file status within group for detailed debug
                    if logSettings.logVerboseInfo, let group = groupDownloads[groupID] {
                        for file in group.files {
                            let fileName = file.url.lastPathComponent
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

extension Sequence {
    func asyncCompactMap<T>(
        _ transform: (Element) async -> T?
    ) async -> [T] {
        var values = [T]()

        for element in self {
            if let transformed = await transform(element) {
                values.append(transformed)
            }
        }
        return values
    }
}

extension DefaultLegacySimRadioDownload.FileDownloadInfo {
    func updated(queueState: DownloadQueue.DownloadState) -> DefaultLegacySimRadioDownload.FileDownloadInfo {
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
                state: .failed([url]),
                downloadedBytes: status.downloadedBytes,
                totalBytes: status.totalBytes
            )
        }
        return .init(url: url, status: newStatus)
    }
}

private protocol SimRadioDownloadStatusProtocol {
    var state: SimRadioDownloadState { get }
    var totalBytes: Int64 { get }
    var downloadedBytes: Int64 { get }
}

extension SimRadioDownloadStatus: SimRadioDownloadStatusProtocol {}

extension DefaultLegacySimRadioDownload.FileDownloadInfo: SimRadioDownloadStatusProtocol {
    var state: SimRadioDownloadState { status.state }
    var totalBytes: Int64 { status.totalBytes }
    var downloadedBytes: Int64 { status.downloadedBytes }
}

extension DefaultLegacySimRadioDownload.StationDownloadInfo: SimRadioDownloadStatusProtocol {
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

            if incomplete.contains(where: \.state.isFinished) {
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

// swiftlint:enable file_length
