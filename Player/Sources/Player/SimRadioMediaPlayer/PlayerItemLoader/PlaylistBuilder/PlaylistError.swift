//
//  PlaylistError.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 06.06.2025.
//

import Foundation
import MediaLibrary

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
    case wrongMode
    case firstFragmentNotFound
    case fragmentNotFound(id: SimRadioDTO.Fragment.ID)
    case invalidTimeInterval(from: String, to: String)
    case invalidFragment(id: SimRadioDTO.Fragment.ID)
    case invalidFragmentSource(id: SimRadioDTO.Fragment.ID)
    case trackListNotFound(id: TrackList.ID)
    case invalidPosition(id: SimRadioDTO.VoiceOverPosition.ID)
    case invalidSource(src: SimRadioDTO.FragmentSource)
    case trackIntroNotFound(trackIDs: [Track.ID], trackListsIDs: [TrackList.ID])
    case invalidDrawPool(trackListIDs: [SimRadioDTO.TrackList.ID])

    case notExhaustiveFragment(id: SimRadioDTO.Fragment.ID)
    case legacyFragmentNotFound(tag: String)
    case notExhaustiveLegacyFragment(tag: String)
    case wrongPositionTag(tag: String)
    case wrongSource
}
