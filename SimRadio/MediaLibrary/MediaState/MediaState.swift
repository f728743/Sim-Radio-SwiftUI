//
//  MediaState.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 22.08.2025.
//

@MainActor
protocol MediaState: AnyObject {
    var mediaList: [MediaList] { get }
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
