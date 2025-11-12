//
//  SimRadioStorage.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

public enum StationStorageState: String {
    case downloadStarted
    case downloadPaused
    case downloaded
    case removing
}

@MainActor
public protocol SimRadioStorage {
    var addedSeriesIDs: [SimGameSeries.ID] { get }
    func addSeries(id: SimGameSeries.ID)
    func removeSeries(id: SimGameSeries.ID)
    func containsSeries(id: SimGameSeries.ID) -> Bool

    func setStorageState(_ state: StationStorageState, for stationID: SimStation.ID)
    func getStorageState(for stationID: SimStation.ID) -> StationStorageState?
    func removeStorageState(for stationID: SimStation.ID)
    var allStoredStationStates: [SimStation.ID: StationStorageState] { get }
}
