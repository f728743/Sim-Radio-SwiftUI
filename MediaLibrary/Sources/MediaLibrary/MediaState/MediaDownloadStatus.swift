//
//  MediaDownloadStatus.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 12.04.2025.
//

public struct MediaDownloadStatus: Sendable {
    public enum DownloadState: Sendable {
        case scheduled
        case downloading
        case completed
        case paused
        case busy
    }

    public let state: DownloadState
    public let downloadedBytes: Int64
    public let totalBytes: Int64

    public init(state: DownloadState, downloadedBytes: Int64 = 0, totalBytes: Int64 = 0) {
        self.state = state
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
    }
}

extension MediaDownloadStatus: DownloadProgressProtocol {}

public extension MediaDownloadStatus {
    static var initial: Self { .init(state: .scheduled) }
}

extension MediaDownloadStatus.DownloadState {
    var isPendingDownload: Bool {
        switch self {
        case .scheduled, .downloading, .paused: true
        default: false
        }
    }
}

public protocol DownloadProgressProtocol {
    var totalBytes: Int64 { get }
    var downloadedBytes: Int64 { get }
}

public extension DownloadProgressProtocol {
    var progress: Double {
        guard totalBytes != 0 else { return 0.0 }
        return (Double(downloadedBytes) / Double(totalBytes)).clamped(to: 0.0 ... 1.0)
    }

    var percent: Double { progress * 100 }
    var percentString: String { String(format: "%.1f%%", percent) }
    var progressString: String { "\(percentString) (\(downloadedBytes) / \(totalBytes))" }
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
