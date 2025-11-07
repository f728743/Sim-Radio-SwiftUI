//
//  SimRadioScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.11.2025.
//

import Observation
import SwiftUI

@Observable @MainActor
class SimRadioScreenViewModel {
    var mediaState: MediaState?
    var simSeries: [LibraryItem] {
        guard let mediaState else { return [] }
        let mediaList = mediaState.mediaList(persisted: true)
        let items = mediaList
            .filter(\.id.isSimRadioSeries)
            .map { LibraryItem.mediaList($0) }
        return items
    }

    func contextMenu(for _: LibraryItem) -> [LibraryContextMenuItem] {
        [.play, .download, .delete]
    }
}
