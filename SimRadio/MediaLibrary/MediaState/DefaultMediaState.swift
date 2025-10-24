//
//  DefaultMediaState.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import Foundation
import Observation

@MainActor
protocol SimRadioLibraryDelegate: AnyObject {
    func simRadioLibrary(
        _ library: SimRadioLibrary,
        didChangeDownloadStatus status: MediaDownloadStatus?,
        for stationID: SimStation.ID
    )

    func simRadioLibrary(
        _ library: SimRadioLibrary,
        didChange media: SimRadioMedia
    )
}

@Observable @MainActor
class DefaultMediaState: MediaState {
    var simRadio: SimRadioMedia = .empty

    private(set) var downloadStatus: [MediaID: MediaDownloadStatus] = [:]
    var simRadioLibrary: any SimRadioLibrary

    init(simRadioLibrary: any SimRadioLibrary) {
        self.simRadioLibrary = simRadioLibrary
    }

    var mediaList: [MediaList] {
        let simRadioMedia = simRadio.series.values.map { series in
            MediaList(
                id: .simRadioSeries(series.id),
                meta: series.meta,
                items: series.stationsIDs.compactMap {
                    guard let station: SimStation = simRadio.stations[$0] else { return nil }
                    return Media(
                        id: .simRadio(station.id),
                        meta: .init(station.meta)
                    )
                }
            )
        }

        return simRadioMedia
    }

    func load() async {
        await simRadioLibrary.load()
    }

    func addSimRadio(url: URL, persistent: Bool) async throws {
        try await simRadioLibrary.addSimRadio(url: url, persistent: persistent)
    }

    func download(_ mediaID: MediaID) async {
        let current = downloadStatus[mediaID]
        guard current == nil || current?.state == .paused else { return }

        switch mediaID {
        case let .simRadio(stationID):
            await simRadioLibrary.downloadStation(stationID)
        }
    }

    func removeDownload(_ mediaID: MediaID) async {
        guard downloadStatus.keys.contains(mediaID) else { return }

        switch mediaID {
        case let .simRadio(stationID):
            await simRadioLibrary.removeDownload(stationID)
        }
    }

    func pauseDownload(_ mediaID: MediaID) async {
        guard downloadStatus.keys.contains(mediaID) else { return }

        switch mediaID {
        case let .simRadio(stationID):
            await simRadioLibrary.pauseDownload(stationID)
        }
    }
}

extension DefaultMediaState: SimRadioLibraryDelegate {
    func simRadioLibrary(
        _: any SimRadioLibrary,
        didChangeDownloadStatus status: MediaDownloadStatus?,
        for stationID: SimStation.ID
    ) {
        downloadStatus[.simRadio(stationID)] = status
    }

    func simRadioLibrary(
        _: any SimRadioLibrary,
        didChange media: SimRadioMedia
    ) {
        simRadio = media
    }
}

extension DefaultMediaState {
    var downloadedMedia: [Media] {
        downloadStatus
            .map(\.self)
            .filter { $0.value.state == .completed }
            .compactMap {
                media(withId: $0.key)
            }
    }

    func media(withId id: Media.ID) -> Media? {
        switch id {
        case let .simRadio(stationId):
            guard let station = simRadio.stations[stationId] else { return nil }
            return Media(
                id: id,
                meta: .init(station.meta)
            )
        }
    }
}

extension MediaMeta {
    init(_ meta: SimStationMeta) {
        self.init(
            artwork: meta.logo,
            title: meta.title,
            subtitle: meta.genre,
            description: meta.host.map { "Hosted by \($0) – \(meta.genre)" } ?? meta.genre,
            artist: meta.host,
            genre: meta.genre,
            isLiveStream: true
        )
    }
}
