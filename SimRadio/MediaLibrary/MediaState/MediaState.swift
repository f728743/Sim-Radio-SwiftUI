//
//  MediaState.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 22.08.2025.
//

import Foundation

@MainActor
protocol MediaState: AnyObject {
    func mediaList(persisted: Bool) -> [MediaList]
    var downloadedMedia: [Media] { get }
    var downloadStatus: [MediaID: MediaDownloadStatus] { get }

    func load() async
    func addSimRadio(url: URL, persisted: Bool) async throws
    func addRealRadio(_ stations: [RealStation], persisted: Bool) async throws
    func removeRealRadio(_ stationID: RealStation.ID) async throws

    func download(_ mediaID: MediaID) async
    func removeDownload(_ mediaID: MediaID) async
    func pauseDownload(_ mediaID: MediaID) async
}

extension MediaState {
    func metaOfMedia(withID id: MediaID) -> MediaMeta? {
        media(withID: id)?.meta
    }

    func media(withID id: MediaID) -> Media? {
        mediaList(persisted: false)
            .flatMap(\.items)
            .first { $0.id == id }
    }
}

extension MediaState {
    var defaultPlayItems: (media: MediaID, items: [MediaID])? {
        guard
            let list = mediaList(persisted: false).filter({ !$0.items.isEmpty }).randomElement(),
            let item = list.items.randomElement()
        else { return nil }
        return (item.id, list.items.map(\.id))
    }
}
