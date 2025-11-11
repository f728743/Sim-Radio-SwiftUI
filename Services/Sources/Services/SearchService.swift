//
//  SearchService.swift
//  Services
//
//  Created by Alexey Vorobyov on 06.10.2025.
//

import Foundation

public final class SearchService: Sendable {
    private let apiService: APIServiceProtocol

    public init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }

    public nonisolated func search(query: String) async throws -> APISearchResponseDTO {
        try await apiService.get("/api/search", parameters: ["q": query])
    }
}

public enum APISearchResultItem: Identifiable {
    public var id: String {
        switch self {
        case let .realStation(item, _): item.stationuuid
        case let .simRadio(item): item.id
        }
    }

    case realStation(dto: APIRealStationDTO, isAdded: Bool)
    case simRadio(dto: APISimRadioSeriesDTO)
}

public struct APISearchResponseDTO: Codable {
    public let success: Bool
    public let realRadio: [APIRealStationDTO]
    public let simRadio: [APISimRadioSeriesDTO]
    public let query: String
    public let type: String

    public init(
        success: Bool,
        realRadio: [APIRealStationDTO],
        simRadio: [APISimRadioSeriesDTO],
        query: String,
        type: String
    ) {
        self.success = success
        self.realRadio = realRadio
        self.simRadio = simRadio
        self.query = query
        self.type = type
    }
}

public struct APIRealStationDTO: Codable {
    public let stationuuid: String
    public let name: String
    public let url: String
    public let urlResolved: String
    public let favicon: String?
    public let votes: Int?
    public let clickcount: Int?
    public let clicktrend: Int?
    public let country: String?
    public let language: String?
    public let tags: String?
    public let cachedFavicon: String?

    init(
        stationuuid: String,
        name: String,
        url: String,
        urlResolved: String,
        favicon: String?,
        votes: Int?,
        clickcount: Int?,
        clicktrend: Int?,
        country: String?,
        language: String?,
        tags: String?,
        cachedFavicon: String?
    ) {
        self.stationuuid = stationuuid
        self.name = name
        self.url = url
        self.urlResolved = urlResolved
        self.favicon = favicon
        self.votes = votes
        self.clickcount = clickcount
        self.clicktrend = clicktrend
        self.country = country
        self.language = language
        self.tags = tags
        self.cachedFavicon = cachedFavicon
    }
}

public struct APISimStationDTO: Codable, Hashable, Identifiable {
    public let id: String
    public let logo: String
    public let tags: String
    public let title: String

    public init(
        id: String,
        logo: String,
        tags: String,
        title: String
    ) {
        self.id = id
        self.logo = logo
        self.tags = tags
        self.title = title
    }
}

public struct APISimRadioSeriesDTO: Codable, Hashable {
    public let id: String
    public let url: String
    public let title: String
    public let logo: String
    public let coverTitle: String
    public let coverLogo: String
    public let stations: [APISimStationDTO]
    public let foundStations: [String]

    public init(
        id: String,
        url: String,
        title: String,
        logo: String,
        coverTitle: String,
        coverLogo: String,
        stations: [APISimStationDTO],
        foundStations: [String]
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.logo = logo
        self.coverTitle = coverTitle
        self.coverLogo = coverLogo
        self.stations = stations
        self.foundStations = foundStations
    }
}
