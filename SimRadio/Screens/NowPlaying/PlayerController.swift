//
//  PlayerController.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 27.11.2024.
//

import Combine
import UIKit

@Observable @MainActor
class PlayerController {
    struct Display: Hashable {
        let artwork: URL?
        let title: String
        let subtitle: String
    }

    var display: Display = .placeholder

    var state: MediaPlayerState = .paused(.none)
    var commandProfile: CommandProfile = .init(isLiveStream: true, isSwitchTrackEnabled: false)
    var colors: [UIColor] = []

    weak var player: MediaPlayer? {
        didSet {
            observeMediaPlayerState()
        }
    }

    weak var mediaState: SimRadioMediaState?

    private var cancellables = Set<AnyCancellable>()

    var isLiveStream: Bool {
        commandProfile.isLiveStream
    }

    var playPauseButton: ButtonType {
        switch state {
        case .playing: commandProfile.isLiveStream ? .stop : .pause
        case .paused: .play
        }
    }

    var backwardButton: ButtonType { .backward }
    var forwardButton: ButtonType { .forward }

    func onPlayPause() {
        player?.togglePlayPause()
    }

    func onForward() {
        player?.forward()
    }

    func onBackward() {
        player?.backward()
    }
}

private extension PlayerController {
    private func observeMediaPlayerState() {
        guard let player else { return }
        // Observe state changes
        cancellables.removeAll()
        player.$state
            .sink { [weak self] state in
                if self?.state.currentMediaID != state.currentMediaID {
                    Task {
                        await self?.updateMeta(for: state.currentMediaID)
                    }
                }
                self?.state = state
            }
            .store(in: &cancellables)

        player.$commandProfile
            .sink { [weak self] commandProfile in
                if let commandProfile {
                    self?.commandProfile = commandProfile
                }
            }
            .store(in: &cancellables)
    }

    func updateMeta(for mediaID: MediaID?) async {
        guard let mediaID else {
            display = .placeholder
            return
        }
        guard let meta = mediaState?.metaOfMedia(withID: mediaID) else { return }
        display = .init(
            artwork: meta.logo,
            title: meta.title,
            subtitle: meta.detailsSubtitle
        )
        let colors = await meta.logo?
            .image?
            .dominantColorFrequencies(with: .high)?
            .map(\.color)

        if let colors {
            self.colors = colors
        }
    }
}

extension PlayerController.Display {
    static var placeholder: Self {
        .init(
            artwork: nil,
            title: "",
            subtitle: ""
        )
    }
}

extension SimRadioMediaState {
    func metaOfMedia(withID id: MediaID) -> SimStationMeta? {
        switch id {
        case let .legacySimRadio(id):
            legacySimRadio.stations[id]?.meta
        case let .simRadio(id):
            simRadio.stations[id]?.meta
        }
    }
}
