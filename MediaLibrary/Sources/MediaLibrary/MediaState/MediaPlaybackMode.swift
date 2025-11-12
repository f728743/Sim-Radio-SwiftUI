//
//  MediaPlaybackMode.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 03.11.2025.
//

public struct MediaPlaybackMode: Identifiable {
    public struct ID: Hashable {
        public let value: String

        public init(value: String) {
            self.value = value
        }
    }

    public let id: ID
    public let title: String

    public init(id: ID, title: String) {
        self.id = id
        self.title = title
    }
}
