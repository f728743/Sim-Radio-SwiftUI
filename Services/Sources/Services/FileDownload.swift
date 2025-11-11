//
//  FileDownload.swift
//  Services
//
//  Created by Alexey Vorobyov
//

import Foundation
import SharedUtilities

public final class FileDownload: NSObject {
    public let events: AsyncStream<Event>
    private let continuation: AsyncStream<Event>.Continuation
    private let urlSessionTask: URLSessionDownloadTask
    private let destinationDirectory: URL

    public enum Event: Sendable {
        case progress(downloadedBytes: Int64, totalBytes: Int64)
        case completed
        case canceled
        case failed(error: Error)
    }

    public convenience init(url: URL, destinationDirectory: URL, urlSession: URLSession) {
        self.init(
            destinationDirectory: destinationDirectory,
            urlSessionTask: urlSession.downloadTask(with: url)
        )
    }

    public convenience init(resumeData data: Data, destinationDirectory: URL, urlSession: URLSession) {
        self.init(
            destinationDirectory: destinationDirectory,
            urlSessionTask: urlSession.downloadTask(withResumeData: data)
        )
    }

    private init(destinationDirectory: URL, urlSessionTask: URLSessionDownloadTask) {
        self.urlSessionTask = urlSessionTask
        self.destinationDirectory = destinationDirectory
        (events, continuation) = AsyncStream.makeStream(of: Event.self)
        super.init()
        continuation.onTermination = { @Sendable [weak self] _ in
            self?.cancel()
        }
    }

    public func start() {
        urlSessionTask.delegate = self
        urlSessionTask.resume()
    }

    public func cancel() {
        urlSessionTask.cancel()
        continuation.yield(.canceled)
        continuation.finish()
    }
}

public extension FileDownload.Event {
    var isFinal: Bool {
        switch self {
        case .completed, .failed, .canceled:
            true
        case .progress:
            false
        }
    }
}

extension FileDownload: URLSessionDownloadDelegate {
    public func urlSession(
        _: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        if let networkError = downloadTask.response?.networkError {
            continuation.yield(.failed(error: networkError))
        } else {
            do {
                guard let fileName = downloadTask.originalRequest?.url?.lastPathComponent else {
                    throw (URLError(.badURL))
                }

                try destinationDirectory.ensureDirectoryExists()
                let fileURL = destinationDirectory.appending(path: fileName, directoryHint: .notDirectory)
                try fileURL.removeFileIfExists()
                try FileManager.default.moveItem(at: location, to: fileURL)
                continuation.yield(.completed)
            } catch {
                continuation.yield(.failed(error: error))
            }
        }
        continuation.finish()
    }

    public func urlSession(
        _: URLSession,
        downloadTask _: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        continuation.yield(
            .progress(
                downloadedBytes: totalBytesWritten,
                totalBytes: totalBytesExpectedToWrite
            )
        )
    }
}
