//
//  Artwork.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 07.11.2025.
//

import Foundation

public enum Artwork: Hashable {
    case radio(name: String? = nil)
    case album
    case webImage(URL)
}

public extension Artwork {
    static func radio(
        _ url: URL?,
        name: String? = nil
    ) -> Artwork {
        url.map { .webImage($0) } ?? .radio(name: name)
    }

    static func album(_ url: URL?) -> Artwork {
        url.map { .webImage($0) } ?? .album
    }

    static func radioImage(
        _ urlString: String?,
        name: String? = nil
    ) -> Artwork {
        .radio(
            urlString.flatMap { URL(string: $0) },
            name: name
        )
    }
}
