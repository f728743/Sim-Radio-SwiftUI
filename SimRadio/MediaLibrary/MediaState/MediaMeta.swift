//
//  MediaMeta.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 03.11.2025.
//

import Foundation

struct MediaMeta: Equatable, Hashable {
    let artwork: URL?
    let title: String
    let subtitle: String?
    let description: String?
    let artist: String?
    let genre: String?
    let isLiveStream: Bool
}
