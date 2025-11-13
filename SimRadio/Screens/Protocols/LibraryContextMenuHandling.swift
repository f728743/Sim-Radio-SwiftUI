//
//  LibraryContextMenuHandling.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 08.11.2025.
//

import Foundation
import MediaLibrary
import Player

@MainActor
protocol LibraryContextMenuHandling: AnyObject {
    var mediaState: MediaState? { get }
    var player: MediaPlayer? { get }
}

extension LibraryContextMenuHandling {
    func contextMenu(for item: MediaItem) -> [LibraryContextMenuItem?] {
        switch item {
        case .mediaItem:
            return [.play, nil, .delete]
        case let .mediaList(mediaList):
            let needDowonload = !mediaList.meta.isOnlineOnly && needDowonload(mediaList.items.map(\.id))
            return [.play] + (needDowonload ? [.download] : []) + [nil, .delete]
        }
    }

    func onSelect(_ menuItem: LibraryContextMenuItem, of item: MediaItem) {
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

    func play(_ item: MediaItem) {
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

    func delete(_ item: MediaItem) {
        guard let mediaState else { return }
        Task {
            switch item {
            case let .mediaItem(media):
                if case let .realRadio(radioID) = media.id {
                    try await mediaState.removeRealRadio(radioID)
                }
            case let .mediaList(mediaList):
                if mediaList.items.first?.id.isSimRadio == true {
                    if case let .simRadioSeries(seriesID) = mediaList.id {
                        try await mediaState.removeSimRadio(seriesID)
                    }
                }
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
