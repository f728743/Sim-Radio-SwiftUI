//
//  MediaState.swift
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
        for stationID: LegacySimStation.ID
    )

    func simRadioLibrary(
        _ library: SimRadioLibrary,
        didChange media: LegacySimRadioMedia
    )

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
class MediaState {
    var legacySimRadio: LegacySimRadioMedia = .empty
    var simRadio: SimRadioMedia = .empty

    private(set) var downloadStatus: [MediaID: MediaDownloadStatus] = [:]
    var simRadioLibrary: any SimRadioLibrary

    init(simRadioLibrary: any SimRadioLibrary) {
        self.simRadioLibrary = simRadioLibrary
    }

    var mediaList: [MediaList] {
        let legacySimRadioMedia = legacySimRadio.series.values.map { series in
            MediaList(
                id: .legacySimRadioSeries(series.id),
                meta: series.meta,
                items: series.stationsIDs.compactMap {
                    guard let station = legacySimRadio.stations[$0] else { return nil }
                    return Media(
                        id: .legacySimRadio(station.id),
                        meta: .init(
                            artwork: station.meta.artwork,
                            title: station.meta.title,
                            listSubtitle: station.meta.genre,
                            detailsSubtitle: station.meta.detailsSubtitle,
                            isLiveStream: true
                        )
                    )
                }
            )
        }

        let simRadioMedia = simRadio.series.values.map { series in
            MediaList(
                id: .simRadioSeries(series.id),
                meta: .init(artwork: nil, title: "new", subtitle: nil),
                items: series.stationsIDs.compactMap {
                    guard let station: SimStation = simRadio.stations[$0] else { return nil }
                    return Media(
                        id: .simRadio(station.id),
                        meta: .init(
                            artwork: nil,
                            title: station.id.value,
                            listSubtitle: "station.meta.genre",
                            detailsSubtitle: "station.meta.detailsSubtitle",
                            isLiveStream: true
                        )
                    )
                }
            )
        }

        return legacySimRadioMedia + simRadioMedia
    }

    func load() async {
        await simRadioLibrary.load()
    }

    func testPopulate() async {
        await simRadioLibrary.testPopulate()
    }

    func download(_ mediaID: MediaID) async {
        let current = downloadStatus[mediaID]
        guard current == nil || current?.state == .paused else { return }

        switch mediaID {
        case let .legacySimRadio(stationID):
            await simRadioLibrary.downloadStation(stationID)
        case let .simRadio(stationID):
            await simRadioLibrary.downloadStation(stationID)
        }
    }

    func removeDownload(_ mediaID: MediaID) async {
        guard downloadStatus.keys.contains(mediaID) else { return }

        switch mediaID {
        case let .legacySimRadio(stationID):
            await simRadioLibrary.removeDownload(stationID)
        case let .simRadio(stationID):
            await simRadioLibrary.removeDownload(stationID)
        }
    }

    func pauseDownload(_ mediaID: MediaID) async {
        guard downloadStatus.keys.contains(mediaID) else { return }

        switch mediaID {
        case let .legacySimRadio(stationID):
            await simRadioLibrary.pauseDownload(stationID)
        case let .simRadio(stationID):
            await simRadioLibrary.pauseDownload(stationID)
        }
    }
}

extension MediaState: SimRadioLibraryDelegate {
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

    func simRadioLibrary(
        _: any SimRadioLibrary,
        didChange media: LegacySimRadioMedia
    ) {
        legacySimRadio = media
    }

    func simRadioLibrary(
        _: any SimRadioLibrary,
        didChangeDownloadStatus status: MediaDownloadStatus?,
        for stationID: LegacySimStation.ID
    ) {
        downloadStatus[.legacySimRadio(stationID)] = status
    }
}
