//
//  PlaylistError.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 06.06.2025.
//

import Foundation

enum PlayerItemLoadingError: Error {
    case playlistError
    case fileNotFound(url: URL)
    case playerItemCreatingError
    case failedToCreateTap
}

enum PlaylistGenerationError: Error {
    case makeDailyPlaylistError(date: Date)
    case makePlaylistError
    case wrongCondition
    case fragmentNotFound(tag: String)
    case notExhaustiveFragment(tag: String)
    case wrongPositionTag(tag: String)
    case wrongSource
}
