//
//  PlayerController+Stub.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

import Foundation

extension PlayerController {
    static var stub: PlayerController {
        let result = PlayerController()
        result.display = .init(
            artwork: .radio(URL(string: "https://raw.githubusercontent.com/tmp-acc/GTA-IV-Radio-Stations/main/gta_iv.png")),
            title: "Los Santos Rock Radio",
            subtitle: "Classic rock, soft rock, pop rock"
        )
        return result
    }
}
