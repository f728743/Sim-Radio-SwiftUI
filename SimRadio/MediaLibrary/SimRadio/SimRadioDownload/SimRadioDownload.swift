//
//  SimRadioDownload.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 21.04.2025.
//

import Foundation

/// Represents an event related to a station's download progress.
struct SimRadioDownloadEvent: Sendable {
    let id: SimStation.ID
    let status: SimRadioDownloadStatus
}

/// Represents the download status, including state and progress.
struct SimRadioDownloadStatus: Equatable, Sendable {
    let state: SimRadioDownloadState
    let downloadedBytes: Int64
    let totalBytes: Int64

    // Convenience initializer
    init(state: SimRadioDownloadState, downloadedBytes: Int64 = 0, totalBytes: Int64 = 0) {
        self.state = state
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
    }
}

extension SimRadioDownloadStatus {
    static var initial: Self { .init(state: .scheduled) }
}

/// Represents the possible states of a station's download.
enum SimRadioDownloadState: Equatable, Sendable {
    case scheduled
    case downloading
    case completed
    case canceled
    case failed([URL]) // Keep track of failed URLs if needed
}

extension SimRadioDownloadState {
    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    var failedURLs: [URL] {
        if case let .failed(urls) = self {
            urls
        } else {
            []
        }
    }

    var isDone: Bool {
        switch self {
        case .completed, .canceled:
            true
        default:
            false
        }
    }

    var isInProgress: Bool {
        switch self {
        case .scheduled, .downloading:
            true
        default:
            false
        }
    }
}

extension SimRadioDownloadStatus: DownloadProgressProtocol {}

protocol SimRadioDownload: Actor {
    /// An asynchronous stream of download events for stations.
    var events: AsyncStream<SimRadioDownloadEvent> { get }

    /// Initiates or resumes the download for a specific media item.
    /// - Parameters:
    ///   - id: The ID of the media to download.
    ///   - missing: Optionally, a dictionary specifying which files are known to be missing for partial downloads.
    func downloadStation(withID id: SimStation.ID, missing: [SimFileGroup.ID: [URL]]?) async

    /// Cancels the download for a specific station, potentially removing partially downloaded files.
    /// - Parameter id: The ID of the station download to cancel.
    func cancelDownloadStation(withID id: SimStation.ID) async -> Bool
}

extension SimRadioDownload {
    func downloadStation(withID id: SimStation.ID) async {
        await downloadStation(withID: id, missing: nil)
    }
}
