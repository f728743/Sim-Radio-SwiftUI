//
//  PlaylistRules.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 07.07.2025.
//

import Foundation

// TODO: get rid
class PlaylistRules {
    let fragments: [SimRadioDTO.Fragment.ID: SimRadioDTO.Fragment]
    let model: SimRadioDTO.Playlist
    let trackLists: [TrackList.ID: TrackList]

    init(
        model: SimRadioDTO.Playlist,
        trackLists: [TrackList]
    ) throws {
        self.model = model
        self.trackLists = Dictionary(uniqueKeysWithValues: trackLists.map { ($0.id, $0) })
        fragments = Dictionary(uniqueKeysWithValues: model.fragments.map { ($0.id, $0) })
    }

    func nextFragmentID(
        after fragmentID: SimRadioDTO.Fragment.ID,
        generator: inout RandomNumberGenerator
    ) async throws -> SimRadioDTO.Fragment.ID {
        guard let fragment = fragments[fragmentID] else {
            throw PlaylistGenerationError.fragmentNotFound(id: fragmentID)
        }
        let rnd = Double.random(in: 0 ... 1, using: &generator)
        var p = 0.0
        for next in fragment.next {
            p += next.probability ?? 1.0
            if rnd <= p {
                return next.fragment
            }
        }
        throw PlaylistGenerationError.notExhaustiveFragment(id: fragmentID)
    }
}
