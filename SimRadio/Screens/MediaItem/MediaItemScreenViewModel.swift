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

    var state: MediaPlayerState = .paused(media: .none, mode: nil)
    var palyIndicatorSpectrum: [Float] = .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
    private var cancellables = Set<AnyCancellable>()

    init(item: Media) {
        self.item = item
    }

    func downloadStatus(for itemID: MediaID) -> MediaDownloadStatus? {
        mediaState?.downloadStatus[itemID]
    }

    func mediaActivity(_ mediaID: MediaID) -> MediaActivity? {
        switch state {
        case let .paused(pausedMediaID, _): pausedMediaID == mediaID ? .paused : nil
        case let .playing(playingMediaID, _): playingMediaID == mediaID ? .spectrum(palyIndicatorSpectrum) : nil
        }
    }

    func onSelect(media: Media.ID) {
        guard let player else { return }
        player.play(media, of: [item.id], mode: nil)
    }

    func onPlay() {
        guard let player else { return }
        player.play(item.id, of: [item.id], mode: nil)
    }
}

private extension MediaItemScreenViewModel {
    private func observeMediaPlayerState() {
        guard let player else { return }
        // Observe state changes
        cancellables.removeAll()
        player.$state
            .sink { [weak self] state in
                guard let self else { return }
                self.state = state
                palyIndicatorSpectrum = .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
            }
            .store(in: &cancellables)

        player.$palyIndicatorSpectrum
            .sink { [weak self] spectrum in
                self?.palyIndicatorSpectrum = spectrum
            }
            .store(in: &cancellables)
    }
}
