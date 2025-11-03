//
//  LibraryItem.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 03.11.2025.
//

enum LibraryItem: Identifiable {
    var id: String {
        switch self {
        case let .mediaList(item): item.id.asString
        case let .mediaItem(item): item.id.asString
        }
    }

    case mediaList(MediaList)
    case mediaItem(Media)
}

extension LibraryItem {
    struct Label {
        let title: String
        let subtitle: String?
        let artwork: Artwork
    }

    var label: Label {
        switch self {
        case let .mediaList(mediaList):
            .init(
                title: mediaList.meta.title,
                subtitle: mediaList.meta.subtitle,
                artwork: .album(mediaList.meta.artwork)
            )
        case let .mediaItem(media):
            .init(
                title: media.meta.title,
                subtitle: media.meta.subtitle,
                artwork: .radio(media.meta.artwork)
            )
        }
    }
}
