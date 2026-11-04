//
//  SimRadioScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.11.2025.
//

import MediaLibrary
import Observation
import Player
import SwiftUI

@Observable @MainActor
final class SimRadioScreenViewModel {
    weak var mediaState: MediaState?
    weak var player: MediaPlayer?

    var simSeries: [MediaItem] {
        guard let mediaState else { return [] }
        let mediaList = mediaState.mediaList(persisted: true)
        return mediaList
            .filter(\.id.isSimRadioSeries)
            .map { MediaItem.mediaList($0) }
    }
}

extension SimRadioScreenViewModel: LibraryContextMenuHandling {}
