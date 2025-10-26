//
//  SimRadioLibrary.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

import Foundation

@MainActor
protocol SimRadioLibrary {
    func load() async

    func addSimRadio(url: URL, persisted: Bool) async throws

    func downloadStation(_ stationID: SimStation.ID) async
    func removeDownload(_ stationID: SimStation.ID) async
    func pauseDownload(_ stationID: SimStation.ID) async
}

@MainActor
protocol SimRadioLibraryDelegate: AnyObject {
    func simRadioLibrary(
        _ library: SimRadioLibrary,
        didChangeDownloadStatus status: MediaDownloadStatus?,
        for stationID: SimStation.ID
    )

    func simRadioLibrary(
        _ library: SimRadioLibrary,
        didChange media: SimRadioMedia,
        nonPersistedSeries: [SimGameSeries.ID]
    )
}
