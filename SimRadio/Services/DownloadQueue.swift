//
//  DownloadQueue.swift
//  SimRadio
//
//  Created by Alexey Vorobyov
//

import Foundation

actor DownloadQueue {
    struct DownloadRequest: Equatable, Hashable {
        let sourceURL: URL
        let destinationDirectoryPath: String
    }

    enum DownloadState {
        case queued
        case progress(downloadedBytes: Int64, totalBytes: Int64)
        case completed
        case canceled
        case failed(error: Error)
    }

    struct Event {
        let state: DownloadState
        let downloadRequest: DownloadRequest
    }

    let events: AsyncStream<Event>
    private let continuation: AsyncStream<Event>.Continuation
    private let destinationDirectory: URL
    private let urlSession: URLSession
    private let maxConcurrentDownloads: Int
    private var downloadQueue: [QueueElement] = []
    private var activeDownloads: [DownloadRequest: FileDownload] = [:]

    init(destinationDirectory: URL, maxConcurrentDownloads: Int = 6) {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        urlSession = URLSession(configuration: config)
        self.destinationDirectory = destinationDirectory
        self.maxConcurrentDownloads = maxConcurrentDownloads
        (events, continuation) = AsyncStream.makeStream(of: Event.self)

        continuation.onTermination = { [weak self] _ in
            Task { [weak self] in
                await self?.cancelAllDownloads()
            }
        }
    }

    func append(_ downloadRequests: [DownloadRequest]) async {
        await withTaskGroup(of: Void.self) { group in
            for downloadRequest in downloadRequests {
                group.addTask { await self.append(downloadRequest) }
            }
        }
    }

    func append(_ downloadRequest: DownloadRequest) async {
        guard !downloadQueue.contains(where: { $0.downloadRequest == downloadRequest }) else {
            return
        }

        downloadQueue.append(
            QueueElement(
                downloadRequest: downloadRequest,
                state: .queued
            )
        )

        continuation.yield(Event(state: .queued, downloadRequest: downloadRequest))

        if activeDownloads.count < maxConcurrentDownloads {
            await start(downloadRequest)
        }
    }

    func cancel(_ downloadRequest: DownloadRequest) async {
        if let download = activeDownloads[downloadRequest] {
            download.cancel()
        } else if let index = downloadQueue.firstIndex(where: { $0.downloadRequest == downloadRequest }) {
            let element = downloadQueue.remove(at: index)
            continuation.yield(Event(state: .canceled, downloadRequest: element.downloadRequest))
        }
    }

    func cancelAllDownloads() async {
        for downloadRequest in activeDownloads.keys {
            await cancel(downloadRequest)
        }
    }
}

// MARK: - Private Helpers

private extension DownloadQueue {
    enum ElementState {
        case queued
        case downloading
    }

    struct QueueElement {
        let downloadRequest: DownloadRequest
        var state: ElementState
    }

    var activeDownloadsCount: Int {
        downloadQueue.count { $0.isDownloading }
    }

    func destinationDirectory(destinationPath: String) -> URL {
        destinationDirectory
            .appending(path: destinationPath, directoryHint: .notDirectory)
    }

    func processDownloadQueue() async {
        while activeDownloads.count < maxConcurrentDownloads {
            if let element = downloadQueue.first(where: { $0.isQueued }) {
                await start(element.downloadRequest)
            } else {
                break
            }
        }
    }

    func start(_ downloadRequest: DownloadRequest) async {
        guard let index = downloadQueue.firstIndex(where: { $0.downloadRequest == downloadRequest }) else { return }
        downloadQueue[index].state = .downloading
        let download = FileDownload(
            url: downloadRequest.sourceURL,
            destinationDirectory: destinationDirectory(destinationPath: downloadRequest.destinationDirectoryPath),
            urlSession: urlSession
        )

        activeDownloads[downloadRequest] = download
        download.start()

        continuation.yield(
            Event(
                state: .progress(downloadedBytes: 0, totalBytes: 0),
                downloadRequest: downloadRequest
            )
        )
        Task {
            for await event in download.events {
                await process(event, for: downloadRequest)
            }
            await processDownloadQueue()
        }
    }

    func process(_ event: FileDownload.Event, for downloadRequest: DownloadRequest) async {
        switch event {
        case .completed, .failed:
            downloadQueue.removeAll { $0.downloadRequest == downloadRequest }
        case .canceled:
            if let index = downloadQueue.firstIndex(where: { $0.downloadRequest == downloadRequest }) {
                downloadQueue.remove(at: index)
            }
        default: break
        }

        if event.isFinal {
            activeDownloads.removeValue(forKey: downloadRequest)
        }
        continuation.yield(Event(state: event.downloadState, downloadRequest: downloadRequest))
    }
}

extension FileDownload.Event {
    var downloadState: DownloadQueue.DownloadState {
        switch self {
        case let .progress(downloadedBytes, totalBytes):
            .progress(downloadedBytes: downloadedBytes, totalBytes: totalBytes)
        case .completed:
            .completed
        case let .failed(error):
            .failed(error: error)
        case .canceled:
            .canceled
        }
    }
}

extension DownloadQueue.QueueElement {
    var isDownloading: Bool {
        if case .downloading = state { return true }
        return false
    }

    var isQueued: Bool {
        if case .queued = state { return true }
        return false
    }
}

extension DownloadQueue.DownloadState {
    var isFinished: Bool {
        switch self {
        case .completed, .canceled:
            true
        default:
            false
        }
    }

    var isFailed: Bool {
        switch self {
        case .failed:
            true
        default:
            false
        }
    }
}

extension DownloadQueue.DownloadRequest {
    var localDirectoryURL: URL {
        .documentsDirectory.appending(
            path: destinationDirectoryPath,
            directoryHint: .isDirectory
        )
    }

    var localFileURL: URL {
        localDirectoryURL.appending(
            path: sourceURL.lastPathComponent,
            directoryHint: .notDirectory
        )
    }
}
