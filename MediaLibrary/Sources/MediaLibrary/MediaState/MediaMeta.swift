//
//  MediaMeta.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 03.11.2025.
//

import Foundation

public struct MediaMeta: Equatable, Hashable, Sendable {
    public let artwork: URL?
    public let title: String
    public let subtitle: String?
    public let description: String?
    public let artist: String?
    public let genre: String?
    public let isLiveStream: Bool
    public let timestamp: Date?

    public init(
        artwork: URL?,
        title: String,
        subtitle: String?,
        description: String?,
        artist: String?,
        genre: String?,
        isLiveStream: Bool,
        timestamp: Date?
    ) {
        self.artwork = artwork
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.artist = artist
        self.genre = genre
        self.isLiveStream = isLiveStream
        self.timestamp = timestamp
    }
}
