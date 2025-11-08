//
//  LibraryScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 06.04.2025.
//

import Observation

@Observable @MainActor
class LibraryScreenViewModel {
    weak var mediaState: MediaState?
    weak var player: MediaPlayer?

    var recentlyAdded: [LibraryItem] {
        guard let mediaState else { return [] }
        let mediaList = mediaState.mediaList(persisted: true)

        let simSeriesItems = mediaList
            .filter(\.id.isSimRadioSeries)
            .map { LibraryItem.mediaList($0) }
        let realRadioItems = mediaList
            .filter(\.id.isRealRadioList)
            .flatMap { $0.items.map { LibraryItem.mediaItem($0) } }

        let result = (simSeriesItems + realRadioItems)
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(20)
        return Array(result)
    }
}

extension LibraryScreenViewModel: LibraryContextMenuHandling {}
