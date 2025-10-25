//
//  LibraryScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 06.04.2025.
//

import Observation

@Observable @MainActor
class LibraryScreenViewModel {
    var mediaState: MediaState?

    var recentlyAdded: [MediaList] {
        guard let mediaState else { return [] }
        return mediaState.persistedMediaList
    }
}
