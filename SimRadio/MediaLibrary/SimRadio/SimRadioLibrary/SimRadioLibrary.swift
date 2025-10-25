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
