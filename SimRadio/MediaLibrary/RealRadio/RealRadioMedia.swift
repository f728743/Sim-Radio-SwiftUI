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

extension RealRadioMedia {
    static let empty: RealRadioMedia = .init(
        stations: [:]
    )
}
