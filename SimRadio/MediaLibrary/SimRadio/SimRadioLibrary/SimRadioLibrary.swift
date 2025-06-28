//
//  SimRadioLibrary.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

@MainActor
protocol LegacySimRadioLibrary {
    func downloadStation(_ stationID: LegacySimStation.ID) async
    func removeDownload(_ stationID: LegacySimStation.ID) async
    func pauseDownload(_ stationID: LegacySimStation.ID) async
}

@MainActor
protocol SimRadioLibrary: LegacySimRadioLibrary {
    func testPopulate() async
    func load() async

    func downloadStation(_ stationID: SimStation.ID) async
    func removeDownload(_ stationID: SimStation.ID) async
    func pauseDownload(_ stationID: SimStation.ID) async
}
