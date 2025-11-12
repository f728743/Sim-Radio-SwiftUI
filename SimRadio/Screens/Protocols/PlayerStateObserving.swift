//
//  PlayerStateObserving.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 06.11.2025.
//

import Combine
import MediaLibrary

@MainActor
protocol PlayerStateObserving: AnyObject {
    var cancellables: Set<AnyCancellable> { get set }
    var playIndicatorSpectrum: [Float] { get set }
    var playerState: MediaPlayerState { get set }
    var player: MediaPlayer? { get }
    func observeMediaPlayerState()
    func mediaActivity(_ mediaID: MediaID) -> MediaActivity?
}

extension PlayerStateObserving {
    func observeMediaPlayerState() {
        guard let player else { return }
        // Observe state changes
        cancellables.removeAll()
        player.$state
            .sink { [weak self] state in
                guard let self else { return }
                playerState = state
                playIndicatorSpectrum = .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
            }
            .store(in: &cancellables)

        player.$playIndicatorSpectrum
            .sink { [weak self] spectrum in
                self?.playIndicatorSpectrum = spectrum
            }
            .store(in: &cancellables)
    }

    func mediaActivity(_ mediaID: MediaID) -> MediaActivity? {
        switch playerState {
        case let .paused(pausedMediaID, _): pausedMediaID == mediaID ? .paused : nil
        case let .playing(playingMediaID, _): playingMediaID == mediaID ? .spectrum(playIndicatorSpectrum) : nil
        }
    }
}
