//
//  MediaState.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 22.08.2025.
//

import Foundation

@MainActor
protocol MediaState: AnyObject {
    var mediaList: [MediaList] { get }
    var downloadedMedia: [Media] { get }
    var downloadStatus: [MediaID: MediaDownloadStatus] { get }

    func load() async
    func addSimRadio(url: URL, persistent: Bool) async throws

    func download(_ mediaID: MediaID) async
    func removeDownload(_ mediaID: MediaID) async
    func pauseDownload(_ mediaID: MediaID) async
}

extension MediaState {
    func metaOfMedia(withID id: MediaID) -> MediaMeta? {
        mediaList
            .flatMap(\.items)
            .first { $0.id == id }?
            .meta
    }
}

extension MediaState {
    var defaultPlayItems: (media: MediaID, items: [MediaID])? {
        guard
            let list = mediaList.filter({ !$0.items.isEmpty }).randomElement(),
            let item = list.items.randomElement()
        else { return nil }
        return (item.id, list.items.map(\.id))
    }
}
