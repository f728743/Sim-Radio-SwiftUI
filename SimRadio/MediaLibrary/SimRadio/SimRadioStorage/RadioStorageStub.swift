//
//  RadioStorageStub.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

@MainActor
class RadioStorageStub: SimRadioStorage {
    var addedSeriesIDs: [SimGameSeries.ID] {
        []
    }

    var allStoredStationStates: [SimStation.ID: StationStorageState] {
        [:]
    }

    func addSeries(id _: SimGameSeries.ID) {}

    func removeSeries(id _: SimGameSeries.ID) {}

    func containsSeries(id _: SimGameSeries.ID) -> Bool {
        false
    }

    func setStorageState(_: StationStorageState, for _: SimStation.ID) {}

    func getStorageState(for _: SimStation.ID) -> StationStorageState? {
        nil
    }

    func removeStorageState(for _: SimStation.ID) {}
}
