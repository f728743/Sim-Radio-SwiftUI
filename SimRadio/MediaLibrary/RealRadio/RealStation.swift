//
//  RealStation.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.11.2025.
//

import Foundation

struct RealStation: Codable {
    let id: ID
    let title: String
    let logo: URL?
    let stream: URL
    let streamResolved: URL
    let tags: String?
    let language: String?
    let country: String?
    let votes: Int?
    let clickCount: Int?
    let clickTrend: Int?

    struct ID: Codable, Hashable {
        let stationUUID: String
    }
}

extension RealStation {
    init?(_ dto: APIRealStationDTO) {
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
            clickTrend: dto.clicktrend
        )
    }
}
