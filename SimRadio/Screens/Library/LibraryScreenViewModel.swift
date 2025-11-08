//
//  LibraryScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 06.04.2025.
//

import Observation

@Observable @MainActor
class LibraryScreenViewModel {
    weak var mediaState: MediaState?
    weak var player: MediaPlayer?

    var recentlyAdded: [LibraryItem] {
        guard let mediaState else { return [] }
        let mediaList = mediaState.mediaList(persisted: true)

        let simSeriesItems = mediaList
            .filter(\.id.isSimRadioSeries)
            .map { LibraryItem.mediaList($0) }
        let realRadioItems = mediaList
            .filter(\.id.isRealRadioList)
            .flatMap { $0.items.map { LibraryItem.mediaItem($0) } }

        let result = (simSeriesItems + realRadioItems)
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(20)
        return Array(result)
    }

    func contextMenu(for item: LibraryItem) -> [LibraryContextMenuItem?] {
        switch item {
        case .mediaItem:
            [.play, nil, .delete]
        case let .mediaList(mediaList):
            [.play] + (needDowonload(mediaList.items.map(\.id)) ? [.download] : []) + [nil, .delete]
        }
    }

    func onSelect(_ menuItem: LibraryContextMenuItem, of item: LibraryItem) {
        switch menuItem {
        case .play:
            play(item)
        case .download:
            if case let .mediaList(mediaList) = item {
                download(mediaList.items.map(\.id))
            }
        case .delete:
            delete(item)
        }
    }

    func play(_ item: LibraryItem) {
        switch item {
        case let .mediaItem(media):
            player?.play(media.id, of: [media.id])
        case let .mediaList(mediaList):
            if let media = mediaList.items.first {
                player?.play(media.id, of: mediaList.items.map(\.id))
            }
        }
    }

    func download(_ mediaIDs: [MediaID]) {
        guard let mediaState else { return }
        Task {
            let notDownloading = findNotDownloadingMediaIDs(from: mediaIDs)
            for mediaID in notDownloading {
                await mediaState.download(mediaID)
            }
        }
    }

    func delete(_ item: LibraryItem) {
        guard let mediaState else { return }
        Task {
            switch item {
            case let .mediaItem(media):
                if case let .realRadio(radioID) = media.id {
                    try await mediaState.removeRealRadio(radioID)
                }
            case let .mediaList(mediaList):
                break
            }
        }
    }

    func findNotDownloadingMediaIDs(from mediaIDs: [MediaID]) -> [MediaID] {
        guard let downloadStatus = mediaState?.downloadStatus else { return [] }
        return mediaIDs.filter { downloadStatus[$0] == nil }
    }

    func needDowonload(_ mediaIDs: [MediaID]) -> Bool {
        guard let downloadStatus = mediaState?.downloadStatus, !mediaIDs.isEmpty else { return false }

        return mediaIDs.contains { mediaID in
            downloadStatus[mediaID]?.state == nil
        }
    }
}
