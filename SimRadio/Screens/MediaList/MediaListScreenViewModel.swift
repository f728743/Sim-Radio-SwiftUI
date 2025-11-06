//
//  MediaListScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 09.04.2025.
//

import Combine
import Observation
import SwiftUI

@Observable @MainActor
class MediaListScreenViewModel {
    enum SwipeButton: Hashable {
        case download
        case pauseDownload
        case delete
    }

    weak var mediaState: MediaState?
    let items: [Media]
    let listMeta: MediaList.Meta?
    var playerState: MediaPlayerState = .paused(media: .none, mode: nil)
    var playIndicatorSpectrum: [Float] = .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
    var cancellables = Set<AnyCancellable>()

    weak var player: MediaPlayer? {
        didSet {
            observeMediaPlayerState()
        }
    }

    init(items: [Media], listMeta: MediaList.Meta?) {
        self.items = items
        self.listMeta = listMeta
    }

    func onSelect(media: MediaID) {
        guard let player else { return }
        player.play(media, of: items.map(\.id), mode: nil)
    }

    func onPlay() {
        guard let player, let item = items.first else { return }
        player.play(item.id, of: items.map(\.id), mode: nil)
    }

    func onShuffle() {
        guard let player, !items.isEmpty else { return }
        let shuffledItems = items.map(\.id).shuffled()
        guard let itemID = shuffledItems.first else { return }

        player.play(itemID, of: shuffledItems, mode: nil)
    }

    func swipeButtons(mediaID: MediaID) -> [SwipeButton] {
        switch mediaID {
        case .simRadio: simRadioSwipeButtons(mediaID: mediaID)
        case .realRadio: [.delete]
        }
    }

    func simRadioSwipeButtons(mediaID: MediaID) -> [SwipeButton] {
        switch downloadStatus(for: mediaID)?.state {
        case .completed: [.delete]
        case .none: [.download]
        case .downloading, .scheduled: [.pauseDownload, .delete]
        case .paused: [.download, .delete]
        case .busy: []
        }
    }

    func onSwipeActions(mediaID: MediaID, button: SwipeButton) {
        switch mediaID {
        case .simRadio: onSimRadioSwipeActions(mediaID: mediaID, button: button)
        case .realRadio: onRealRadioSwipeActions(mediaID: mediaID, button: button)
        }
    }

    func onRealRadioSwipeActions(mediaID: MediaID, button: SwipeButton) {
        if case .delete = button {
            Task {
                if case let .playing(currentlyPlayingMediaID, _) = playerState {
                    if currentlyPlayingMediaID == mediaID {
                        player?.pause()
                    }
                }
                try await mediaState?.removeRealRadio(mediaID)
            }
        }
    }

    func onSimRadioSwipeActions(mediaID: MediaID, button: SwipeButton) {
        Task {
            switch button {
            case .download:
                await mediaState?.download(mediaID)
            case .delete:
                await mediaState?.removeDownload(mediaID)
            case .pauseDownload:
                await mediaState?.pauseDownload(mediaID)
            }
        }
    }

    func downloadStatus(for itemID: MediaID) -> MediaDownloadStatus? {
        mediaState?.downloadStatus[itemID]
    }

    var footer: LocalizedStringKey {
        "^[\(items.count) station](inflect: true)"
    }
}

extension MediaListScreenViewModel: PlayerStateObserving {}

extension MediaListScreenViewModel.SwipeButton {
    var systemImage: String {
        switch self {
        case .download:
            "arrow.down"
        case .pauseDownload:
            "pause.fill"
        case .delete:
            "minus.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .download: "Download"
        case .pauseDownload: "Pause"
        case .delete: "Delete"
        }
    }

    var color: Color {
        switch self {
        case .download: Color(.systemBlue)
        case .pauseDownload: Color(.systemGray)
        case .delete: Color(.systemRed)
        }
    }
}
