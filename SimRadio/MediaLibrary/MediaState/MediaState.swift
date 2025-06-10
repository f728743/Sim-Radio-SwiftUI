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
        for stationID: SimStation.ID
    )

    func simRadioLibrary(
        _ library: SimRadioLibrary,
        didChange media: SimRadioMedia
    )
}

@Observable @MainActor
class MediaState {
    var simRadio: SimRadioMedia = .empty
    private(set) var downloadStatus: [MediaID: MediaDownloadStatus] = [:]
    var simRadioLibrary: any SimRadioLibrary

    init(simRadioLibrary: any SimRadioLibrary) {
        self.simRadioLibrary = simRadioLibrary
    }

    var mediaList: [MediaList] {
        simRadio.series.values.map { series in
            MediaList(
                id: .simRadioSeries(series.id),
                meta: series.meta,
                items: series.stationsIDs.compactMap {
                    guard let station = simRadio.stations[$0] else { return nil }
                    return Media(
                        id: .simRadio(station.id),
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

extension MediaState: SimRadioLibraryDelegate {
    func simRadioLibrary(
        _: SimRadioLibrary,
        didChange media: SimRadioMedia
    ) {
        simRadio = media
    }

    func simRadioLibrary(
        _: SimRadioLibrary,
        didChangeDownloadStatus status: MediaDownloadStatus?,
        for stationID: SimStation.ID
    ) {
        downloadStatus[.simRadio(stationID)] = status
    }
}
