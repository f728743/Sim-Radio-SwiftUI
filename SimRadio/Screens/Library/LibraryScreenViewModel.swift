//
//  LibraryScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 06.04.2025.
//

import Observation

@Observable @MainActor
class LibraryScreenViewModel {
    var mediaState: DefaultMediaState?

    func testPopulate() {
        Task {
            await mediaState?.testPopulate()
        }
    }

    var recentlyAdded: [MediaList] {
        guard let mediaState else { return [] }
        return mediaState.mediaList
    }
}
