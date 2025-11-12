//
//  RealStation.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.11.2025.
//

import Foundation
import Services
import SharedUtilities

public struct RealStation: Codable, Sendable {
    public let id: ID
    public let title: String
    public let logo: URL?
    public let stream: URL
    public let streamResolved: URL
    public let tags: String?
    public let language: String?
    public let country: String?
    public let votes: Int?
    public let clickCount: Int?
    public let clickTrend: Int?
    public let timestamp: Date?

    public struct ID: Codable, Hashable, Sendable {
        public let stationUUID: String

        public init(stationUUID: String) {
            self.stationUUID = stationUUID
        }
    }
}

public extension RealStation {
    init?(_ dto: APIRealStationDTO, timestamp: Date?) {
        guard let stream = URL(string: dto.url),
              let streamResolved = URL(string: dto.urlResolved)
        else { return nil }
        self.init(
            id: .init(stationUUID: dto.stationuuid),
            title: dto.name,
            logo: dto.cachedFavicon.flatMap { URL(string: $0) },
            stream: stream,
            streamResolved: streamResolved,
            tags: dto.tags.map { prettyPrintTags($0) },
            language: dto.language,
            country: dto.country,
            votes: dto.votes,
            clickCount: dto.clickcount,
            clickTrend: dto.clicktrend,
            timestamp: timestamp
        )
    }
}
