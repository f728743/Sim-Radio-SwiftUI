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
        case .realStation(let item): item.stationuuid
        case .simRadio(let item): item.id
        }
    }
    
    case realStation(APIRealStationDTO)
    case simRadio(APISimRadioSeriesDTO)
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
    let favicon: String?
    let votes: Int?
    let clickcount: Int?
    let clicktrend: Int?
    let country: String?
    let language: String?
    let tags: String?
    let cachedFavicon: String?
}

struct APISimStationDTO: Codable {
    let id: String
    let logo: String
    let tags: String
    let title: String
}

struct APISimRadioSeriesDTO: Codable {
    let id: String
    let url: String
    let title: String
    let logo: String
    let stations: [APISimStationDTO]
}

extension APISearchResponseDTO {
    var items: [APISearchResultItem] {
        simRadio.map { .simRadio($0)} + realRadio.map { .realStation($0)}
    }
}

extension APISimRadioSeriesDTO {
    var artwork: URL? {
        guard let url = URL(string: logo) else { return nil }
        return url
    }
}

extension APIRealStationDTO {
    var artwork: URL? {
        cachedFavicon.flatMap { URL(string: $0) }
    }
}
