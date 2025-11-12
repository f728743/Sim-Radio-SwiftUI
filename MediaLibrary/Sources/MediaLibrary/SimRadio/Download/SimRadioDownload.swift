//
//  SimRadioDownload.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 25.06.2025.
//

import Foundation

public struct SimRadioDownloadEvent: Sendable {
    let id: SimStation.ID
    let status: SimRadioDownloadStatus
}

public protocol SimRadioDownload: Actor {
    /// An asynchronous stream of download events for stations.
    var events: AsyncStream<SimRadioDownloadEvent> { get }

    /// Initiates or resumes the download for a specific media item.
    /// - Parameters:
    ///   - id: The ID of the media to download.
    ///   - missing: Optionally, a dictionary specifying which files are known to be missing for partial downloads.
    func downloadStation(withID id: SimStation.ID, missing: [TrackList.ID: [URL]]?) async

    /// Cancels the download for a specific station, potentially removing partially downloaded files.
    /// - Parameter id: The ID of the station download to cancel.
    func cancelDownloadStation(withID id: SimStation.ID) async -> Bool
}

extension SimRadioDownload {
    func downloadStation(withID id: SimStation.ID) async {
        await downloadStation(withID: id, missing: nil)
    }
}
