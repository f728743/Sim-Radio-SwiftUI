//
//  SimRadioLibrary.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

@MainActor
protocol SimRadioLibrary {
    func testPopulate() async
    func load() async
    func downloadStation(_ stationID: SimStation.ID) async
    func removeDownload(_ stationID: SimStation.ID) async
    func pauseDownload(_ stationID: SimStation.ID) async
}
