//
//  MediaList.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 03.11.2025.
//

import Foundation

struct MediaList: Identifiable, Hashable, Equatable {
    let id: MediaListID
    let meta: Meta
    let items: [Media]

    struct Meta: Hashable, Equatable {
        let artwork: URL?
        let title: String
        let subtitle: String?
        let timestamp: Date?
    }
}

extension MediaList {
    static let empty: MediaList = .init(
        id: .emptyMediaListID,
        meta: .init(
            artwork: nil,
            title: "",
            subtitle: nil,
            timestamp: nil
        ),
        items: []
    )
}

enum MediaListID: Hashable, Equatable {
    case emptyMediaListID
    case simRadioSeries(SimGameSeries.ID)
    case realRadioList
}

extension MediaListID {
    var isSimRadioSeries: Bool {
        switch self {
        case .simRadioSeries: true
        default: false
        }
    }

    var isRealRadioList: Bool {
        switch self {
        case .realRadioList: true
        default: false
        }
    }

    var asString: String {
        switch self {
        case let .simRadioSeries(id):
            "simRadioSeries.\(id)"
        case .realRadioList:
            "realRadioList"
        case .emptyMediaListID:
            "emptyMediaListID"
        }
    }
}
