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

    weak var mediaState: MediaState?

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

        player.$nowPlayingMeta
            .sink { [weak self] meta in
                guard let self else { return }
                Task {
                    await updateDisplay(withMeta: meta)
                }
            }.store(in: &cancellables)
    }
    
    func updateDisplay(withMeta meta: MediaMeta?) async {
        if let meta {
            display = .init(
                artwork: meta.artwork,
                title: meta.title,
                subtitle: meta.description ?? ""
            )
            let colors = await meta.artwork?
                .image?
                .dominantColorFrequencies(with: .high)?
                .map(\.color)            
            if let colors {
                self.colors = colors
            }
        } else {
            display = .placeholder
            colors = []
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
