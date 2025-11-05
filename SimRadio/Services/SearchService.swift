//
//  SearchService.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 06.10.2025.
//

import Foundation

final class SearchService: Sendable {
    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }

    nonisolated func search(query: String) async throws -> APISearchResponseDTO {
        try await apiService.get("/api/search", parameters: ["q": query])
    }
}

enum APISearchResultItem: Identifiable {
    var id: String {
        switch self {
        case let .realStation(item, _): item.stationuuid
        case let .simRadio(item): item.id
        }
    }

    case realStation(dto: APIRealStationDTO, isAdded: Bool)
    case simRadio(dto: APISimRadioSeriesDTO)
}

struct APISearchResponseDTO: Codable {
    let success: Bool
    let realRadio: [APIRealStationDTO]
    let simRadio: [APISimRadioSeriesDTO]
    let query: String
    let type: String
}

struct APIRealStationDTO: Codable {
    let stationuuid: String
    let name: String
    let url: String
    let urlResolved: String
    let favicon: String?
    let votes: Int?
    let clickcount: Int?
    let clicktrend: Int?
    let country: String?
    let language: String?
    let tags: String?
    let cachedFavicon: String?
}

struct APISimStationDTO: Codable, Hashable, Identifiable {
    let id: String
    let logo: String
    let tags: String
    let title: String
}

struct APISimRadioSeriesDTO: Codable, Hashable {
    let id: String
    let url: String
    let title: String
    let logo: String
    let coverTitle: String
    let coverLogo: String
    let stations: [APISimStationDTO]
    let foundStations: [String]
}

extension APISimRadioSeriesDTO {
    var artwork: Artwork {
        .album(buildMediaURL(from: url, with: logo))
    }
}

func buildMediaURL(from baseURL: String, with filename: String) -> URL? {
    guard let baseURL = URL(string: baseURL) else {
        return nil
    }
    let baseDirectory = baseURL.deletingLastPathComponent()
    return baseDirectory.appendingPathComponent(filename)
}

extension APIRealStationDTO {
    var artwork: Artwork {
        let url = cachedFavicon.flatMap { URL(string: $0) }
        return .radio(url, name: name)
    }
}
