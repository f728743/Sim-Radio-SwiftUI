//
//  LegacySimRadioDownload.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 21.04.2025.
//

import Foundation

/// Represents an event related to a station's download progress.
struct LegacySimRadioDownloadEvent: Sendable {
    let id: LegacySimStation.ID
    let status: SimRadioDownloadStatus
}

protocol LegacySimRadioDownload: Actor {
    /// An asynchronous stream of download events for stations.
    var events: AsyncStream<LegacySimRadioDownloadEvent> { get }

    /// Initiates or resumes the download for a specific media item.
    /// - Parameters:
    ///   - id: The ID of the media to download.
    ///   - missing: Optionally, a dictionary specifying which files are known to be missing for partial downloads.
    func downloadStation(withID id: LegacySimStation.ID, missing: [LegacySimFileGroup.ID: [URL]]?) async

    /// Cancels the download for a specific station, potentially removing partially downloaded files.
    /// - Parameter id: The ID of the station download to cancel.
    func cancelDownloadStation(withID id: LegacySimStation.ID) async -> Bool
}

extension LegacySimRadioDownload {
    func downloadStation(withID id: LegacySimStation.ID) async {
        await downloadStation(withID: id, missing: nil)
    }
}
