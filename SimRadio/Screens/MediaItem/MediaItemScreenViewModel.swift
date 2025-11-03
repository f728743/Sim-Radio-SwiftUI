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
