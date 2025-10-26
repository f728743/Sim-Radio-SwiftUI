//
//  Media.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 29.03.2025.
//

import Foundation

struct Media: Identifiable, Hashable, Equatable {
    let id: MediaID
    let meta: MediaMeta
}

struct MediaPlaybackMode: Identifiable {
    struct ID: Hashable {
        let value: String
    }

    let id: ID
    let title: String
}

struct MediaMeta: Equatable, Hashable {
    let artwork: URL?
    let title: String
    let subtitle: String?
    let description: String?
    let artist: String?
    let genre: String?
    let isLiveStream: Bool
}

enum MediaListID: Hashable, Equatable {
    case emptyMediaListID
    case simRadioSeries(SimGameSeries.ID)
}

enum MediaID: Hashable {
    case simRadio(SimStation.ID)
    case realRadio(RealStation.ID)
}

struct MediaList: Identifiable, Hashable, Equatable {
    let id: MediaListID
    let meta: Meta
    let items: [Media]

    struct Meta: Hashable, Equatable {
        let artwork: URL?
        let title: String
        let subtitle: String?
    }
}

extension MediaList {
    static let empty: MediaList = .init(
        id: .emptyMediaListID,
        meta: .init(
            artwork: nil,
            title: "",
            subtitle: nil
        ),
        items: []
    )
}
