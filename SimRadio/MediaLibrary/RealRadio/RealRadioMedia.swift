//
//  RealRadioMedia.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

import Foundation

struct RealRadioMedia {
    let stations: [RealStation.ID: RealStation]
}

struct RealStation: Codable {
    let id: ID
    let title: String
    let logo: URL?
    let stream: URL
    let streamResolved: URL?
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

extension RealRadioMedia {
    static let empty: RealRadioMedia = .init(
        stations: [:]
    )
}
