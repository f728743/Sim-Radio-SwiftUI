//
//  NewModelSimRadioDownload.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 25.06.2025.
//

import Foundation

struct NewModelSimRadioDownloadEvent: Sendable {
    let id: NewModelSimStation.ID
    let status: SimRadioDownloadStatus
}

protocol NewModelSimRadioDownload: Actor {
    /// An asynchronous stream of download events for stations.
    var events: AsyncStream<NewModelSimRadioDownloadEvent> { get }

    /// Initiates or resumes the download for a specific media item.
    /// - Parameters:
    ///   - id: The ID of the media to download.
    ///   - missing: Optionally, a dictionary specifying which files are known to be missing for partial downloads.
    func downloadStation(withID id: NewModelSimStation.ID, missing: [NewModelTrackList.ID: [URL]]?) async

    /// Cancels the download for a specific station, potentially removing partially downloaded files.
    /// - Parameter id: The ID of the station download to cancel.
    func cancelDownloadStation(withID id: NewModelSimStation.ID) async -> Bool
}

extension NewModelSimRadioDownload {
    func downloadStation(withID id: NewModelSimStation.ID) async {
        await downloadStation(withID: id, missing: nil)
    }
}
