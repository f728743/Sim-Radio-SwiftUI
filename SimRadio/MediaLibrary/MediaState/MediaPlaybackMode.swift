//
//  MediaPlaybackMode.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 03.11.2025.
//

struct MediaPlaybackMode: Identifiable {
    struct ID: Hashable {
        let value: String
    }

    let id: ID
    let title: String
}
