//
//  SimRadioDownloadProgress.swift
//  MediaLibrary
//

import Foundation
import Services

extension DefaultSimRadioDownload {
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

protocol SimRadioDownloadStatusProtocol {
    var state: SimRadioDownloadState { get }
    var totalBytes: Int64 { get }
    var downloadedBytes: Int64 { get }
}

extension SimRadioDownloadStatus: SimRadioDownloadStatusProtocol {}

extension DefaultSimRadioDownload.FileDownloadInfo: SimRadioDownloadStatusProtocol {
    var state: SimRadioDownloadState {
        status.state
    }

    var totalBytes: Int64 {
        status.totalBytes
    }

    var downloadedBytes: Int64 {
        status.downloadedBytes
    }
}

extension DefaultSimRadioDownload.StationDownloadInfo: SimRadioDownloadStatusProtocol {
    var state: SimRadioDownloadState {
        status.state
    }

    var totalBytes: Int64 {
        status.totalBytes
    }

    var downloadedBytes: Int64 {
        status.downloadedBytes
    }
}

/// Aggregation logic for collections
extension Collection where Element: SimRadioDownloadStatusProtocol {
    var overallState: SimRadioDownloadState? {
        get async {
            if contains(where: { $0.state == .downloading }) {
                return .downloading
            }
            if contains(where: { $0.state == .scheduled }) {
                return .scheduled
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

    var overallTotalBytes: Int64 {
        reduce(0) { $0 + $1.totalBytes }
    }

    var overallDownloadedBytes: Int64 {
        reduce(0) { $0 + $1.downloadedBytes }
    }

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
