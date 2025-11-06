//
//  MediaItemScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.11.2025.
//

import Combine
import Observation
import SwiftUI

@Observable @MainActor
class MediaItemScreenViewModel {
    let item: Media

    weak var mediaState: MediaState?
    weak var player: MediaPlayer? {
        didSet {
            observeMediaPlayerState()
        }
    }

    var playerState: MediaPlayerState = .paused(media: .none, mode: nil)
    var playIndicatorSpectrum: [Float] = .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
    var cancellables = Set<AnyCancellable>()

    init(item: Media) {
        self.item = item
    }

    func downloadStatus(for itemID: MediaID) -> MediaDownloadStatus? {
        mediaState?.downloadStatus[itemID]
    }

    func onSelect(media: MediaID) {
        guard let player else { return }
        player.play(media, of: [item.id], mode: nil)
    }

    func onPlay() {
        guard let player else { return }
        player.play(item.id, of: [item.id], mode: nil)
    }
}

extension MediaItemScreenViewModel: PlayerStateObserving {}
