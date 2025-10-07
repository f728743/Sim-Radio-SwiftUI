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
    
    nonisolated func search(query: String) async throws -> SearchResponseDTO {
        return try await apiService.get("/api/v1/stations/search", parameters: ["q": query])
    }
}

struct RealRadioStationDTO: Codable, Identifiable {
    let id: Int
    let stationuuid: String
    let name: String
    let urlResolved: String
    let homepage: String?
    let favicon: String?
    let tags: String?
    let country: String?
    let countrycode: String?
    let language: String?
    let votes: Int
    let codec: String?
    let bitrate: Int?
    let lastcheckok: Int
    let clickcount: Int
}

struct SearchResponseDTO: Codable {
    let status: String
    let data: SearchDataDTO
}

struct SearchDataDTO: Codable {
    let stations: [RealRadioStationDTO]
    let meta: SearchMetaDTO
}

struct SearchMetaDTO: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool
}
