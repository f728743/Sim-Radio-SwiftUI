//
//  MediaList.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 03.11.2025.
//

import Foundation

public struct MediaList: Identifiable, Hashable, Equatable, Sendable {
    public let id: MediaListID
    public let meta: Meta
    public let items: [Media]

    public struct Meta: Hashable, Equatable, Sendable {
        public let artwork: URL?
        public let title: String
        public let subtitle: String?
        public let isOnlineOnly: Bool
        public let timestamp: Date?
    }
}

public extension MediaList {
    static let empty: MediaList = .init(
        id: .emptyMediaListID,
        meta: .init(
            artwork: nil,
            title: "",
            subtitle: nil,
            isOnlineOnly: true,
            timestamp: nil
        ),
        items: []
    )
}

public enum MediaListID: Hashable, Equatable, Sendable {
    case emptyMediaListID
    case simRadioSeries(SimGameSeries.ID)
    case realRadioList
}

public extension MediaListID {
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
