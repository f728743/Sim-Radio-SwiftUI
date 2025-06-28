//
//  SimRadioDownloadStatus.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 28.06.2025.
//

import Foundation

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
