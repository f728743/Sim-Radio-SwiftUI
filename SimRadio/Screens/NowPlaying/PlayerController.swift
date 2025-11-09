//
//  PlayerController.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 27.11.2024.
//

import Combine
import DesignSystem
import SwiftUI
import UIKit

@Observable @MainActor
class PlayerController {
    struct Display: Hashable {
        let artwork: Artwork
        let title: String
        let subtitle: String
    }

    var display: Display = .placeholder
    var modes: [MediaPlaybackMode] = []
    var selectedMode: MediaPlaybackMode.ID?

    var state: MediaPlayerState = .paused(media: .none, mode: nil)
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

    func onSelectMode(_ mode: MediaPlaybackMode.ID?) {
        player?.play(mode: mode)
    }
}

private extension PlayerController {
    private func observeMediaPlayerState() {
        guard let player else { return }
        // Observe state changes
        cancellables.removeAll()
        player.$state
            .sink { [weak self] state in
                guard let self else { return }
                if self.state.currentMediaID != state.currentMediaID {
                    selectedMode = nil
                }
                self.state = state
            }
            .store(in: &cancellables)

        player.$commandProfile
            .sink { [weak self] commandProfile in
                if let commandProfile {
                    self?.commandProfile = commandProfile
                }
            }
            .store(in: &cancellables)

        player.$playbackModes
            .sink { [weak self] modes in
                guard let self else { return }
                if selectedMode == nil {
                    selectedMode = modes.first?.id
                }
                self.modes = modes
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
                artwork: .radio(meta.artwork, name: meta.title),
                title: meta.title,
                subtitle: meta.description ?? ""
            )
            colors = await meta.colors.map { UIColor($0) }
        } else {
            display = .placeholder
            colors = [UIColor(.graySecondary)]
        }
    }
}

extension MediaMeta {
    var colors: [Color] {
        get async {
            guard let artwork else { return title.textColors }
            return await artwork
                .image?
                .dominantColorFrequencies(with: .high)?
                .map { Color(uiColor: $0.color) } ?? [.graySecondary]
        }
    }
}

extension PlayerController.Display {
    static var placeholder: Self {
        .init(
            artwork: .radio(),
            title: "",
            subtitle: ""
        )
    }
}
