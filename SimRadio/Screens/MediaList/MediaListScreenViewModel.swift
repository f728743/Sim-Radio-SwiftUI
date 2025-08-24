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

    var mediaState: DefaultMediaState?
    let items: [Media]
    let listMeta: MediaList.Meta?
    var state: MediaPlayerState = .paused(media: .none, mode: nil)
    var palyIndicatorSpectrum: [Float] = .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
    private var cancellables = Set<AnyCancellable>()

    weak var player: MediaPlayer? {
        didSet {
            observeMediaPlayerState()
        }
    }

    init(items: [Media], listMeta: MediaList.Meta?) {
        self.items = items
        self.listMeta = listMeta
    }

    func onSelect(media: Media.ID) {
        guard let player else { return }
        player.play(media, of: items.map(\.id), mode: nil)
    }

    func swipeButtons(media: Media.ID) -> [SwipeButton] {
        switch downloadStatus(for: media)?.state {
        case .completed: [.delete]
        case .none: [.download]
        case .downloading, .scheduled: [.pauseDownload, .delete]
        case .paused: [.download, .delete]
        case .busy: []
        }
    }

    func onSwipeActions(media: Media.ID, button: SwipeButton) {
        Task {
            switch button {
            case .download:
                await mediaState?.download(media)
            case .delete:
                await mediaState?.removeDownload(media)
            case .pauseDownload:
                await mediaState?.pauseDownload(media)
            }
        }
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

    var footer: LocalizedStringKey {
        "^[\(items.count) station](inflect: true)"
    }
}

private extension MediaListScreenViewModel {
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
