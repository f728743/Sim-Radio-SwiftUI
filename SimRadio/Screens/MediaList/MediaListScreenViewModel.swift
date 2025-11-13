//
//  MediaListScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 09.04.2025.
//

import Combine
import MediaLibrary
import Observation
import Player
import SwiftUI

@Observable @MainActor
class MediaListScreenViewModel {
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

    func swipeButtons(mediaID: MediaID) -> [MediaListSwipeButton] {
        switch mediaID {
        case let .simRadio(stationID): simRadioSwipeButtons(stationID: stationID)
        case .realRadio: [.delete]
        }
    }

    func simRadioSwipeButtons(stationID: SimStation.ID) -> [MediaListSwipeButton] {
        guard let mediaState else { return [] }
        let isOnlineOnly = mediaState
            .mediaList(persisted: true)
            .first { $0.id == .simRadioSeries(stationID.series)}?
            .meta
            .isOnlineOnly
        if isOnlineOnly ?? true { return [] }
        
        switch downloadStatus(for: .simRadio(stationID))?.state {
        case .completed: return [.delete]
        case .none: return [.download]
        case .downloading, .scheduled: return [.pauseDownload, .delete]
        case .paused: return [.download, .delete]
        case .busy: return []
        }
    }

    func onSwipeActions(mediaID: MediaID, button: MediaListSwipeButton) {
        switch mediaID {
        case .simRadio: onSimRadioSwipeActions(mediaID: mediaID, button: button)
        case .realRadio: onRealRadioSwipeActions(mediaID: mediaID, button: button)
        }
    }

    func onRealRadioSwipeActions(mediaID: MediaID, button: MediaListSwipeButton) {
        if case .delete = button {
            Task {
                if case let .realRadio(radioID) = mediaID {
                    try await mediaState?.removeRealRadio(radioID)
                }
            }
        }
    }

    func onSimRadioSwipeActions(mediaID: MediaID, button: MediaListSwipeButton) {
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
