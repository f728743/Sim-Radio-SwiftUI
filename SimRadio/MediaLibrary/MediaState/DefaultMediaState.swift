//
//  DefaultMediaState.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.03.2025.
//

import Foundation
import Observation

/// Observable wrapper around various libraries
@Observable @MainActor
class DefaultMediaState: MediaState {
    var simRadio: SimRadioMedia = .empty
    var nonPersistedSimSeries: [SimGameSeries.ID] = []

    var realRadio: RealRadioMedia = .empty
    var nonPersistedRealStations: [RealStation.ID] = []

    private(set) var downloadStatus: [MediaID: MediaDownloadStatus] = [:]
    var simRadioLibrary: any SimRadioLibrary
    var realRadioLibrary: any RealRadioLibrary

    init(
        simRadioLibrary: any SimRadioLibrary,
        realRadioLibrary: any RealRadioLibrary
    ) {
        self.simRadioLibrary = simRadioLibrary
        self.realRadioLibrary = realRadioLibrary
    }

    var mediaList: [MediaList] {
        let simRadioMedia = simRadio.series.values
            .map { series in
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
        let realRadioMedia = MediaList(
            id: .realRadioList,
            meta: .init(artwork: nil, title: "Radio", subtitle: nil),
            items: realRadio.stations.values.map { station in
                Media(
                    id: .realRadio(station.id),
                    meta: .init(station)
                )
            }
        )
        return simRadioMedia + [realRadioMedia]
    }

    var persistedMediaList: [MediaList] {
        let persistedMedia = simRadio.series.values
            .filter { !nonPersistedSimSeries.contains($0.id) }
            .map { series in
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
        return persistedMedia
    }

    func load() async {
        await simRadioLibrary.load()
        await realRadioLibrary.load()
    }

    func addSimRadio(url: URL, persisted: Bool) async throws {
        try await simRadioLibrary.addSimRadio(url: url, persisted: persisted)
    }

    func addRealRadio(_ stations: [RealStation], persisted: Bool) async throws {
        try await realRadioLibrary.addRealRadio(stations, persisted: persisted)
    }

    func download(_ mediaID: MediaID) async {
        let current = downloadStatus[mediaID]
        guard current == nil || current?.state == .paused else { return }

        switch mediaID {
        case let .simRadio(stationID):
            await simRadioLibrary.downloadStation(stationID)
        case .realRadio:
            break
        }
    }

    func removeDownload(_ mediaID: MediaID) async {
        guard downloadStatus.keys.contains(mediaID) else { return }

        switch mediaID {
        case let .simRadio(stationID):
            await simRadioLibrary.removeDownload(stationID)
        case .realRadio:
            break
        }
    }

    func pauseDownload(_ mediaID: MediaID) async {
        guard downloadStatus.keys.contains(mediaID) else { return }

        switch mediaID {
        case let .simRadio(stationID):
            await simRadioLibrary.pauseDownload(stationID)
        case .realRadio:
            break
        }
    }
}

extension DefaultMediaState {
    var downloadedMedia: [Media] {
        downloadStatus
            .map(\.self)
            .filter { $0.value.state == .completed }
            .compactMap {
                media(withID: $0.key)
            }
    }

    func media(withID id: Media.ID) -> Media? {
        switch id {
        case let .simRadio(stationID):
            guard let station = simRadio.stations[stationID] else { return nil }
            return Media(
                id: id,
                meta: .init(station.meta)
            )
        case let .realRadio(stationID):
            guard let station = realRadio.stations[stationID] else { return nil }
            return Media(
                id: id,
                meta: .init(station)
            )
        }
    }
}

extension DefaultMediaState: SimRadioMediaState {
    var simDownloadStatus: [SimStation.ID: MediaDownloadStatus] {
        Dictionary(uniqueKeysWithValues: downloadStatus.compactMap {
            if case let .simRadio(id) = $0.key {
                return (id, $0.value)
            }
            return nil
        })
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
        didChange media: SimRadioMedia,
        nonPersistedSeries: [SimGameSeries.ID]
    ) {
        simRadio = media
        nonPersistedSimSeries = nonPersistedSeries
    }
}

extension DefaultMediaState: RealRadioMediaState {}

extension DefaultMediaState: RealRadioLibraryDelegate {
    func realRadioLibrary(
        _: RealRadioLibrary,
        didChange media: RealRadioMedia,
        nonPersistedStations: [RealStation.ID]
    ) {
        realRadio = media
        nonPersistedRealStations = nonPersistedStations
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

extension MediaMeta {
    init(_ station: RealStation) {
        self.init(
            artwork: station.logo,
            title: station.title,
            subtitle: station.country,
            description: station.tags,
            artist: nil,
            genre: station.tags,
            isLiveStream: true
        )
    }
}
