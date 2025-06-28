//
//  SimRadioStorage.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

enum StationStorageState: String {
    case downloadStarted
    case downloadPaused
    case downloaded
    case removing
}

@MainActor
protocol SimRadioStorage {
    var addedLegacySeriesIDs: [LegacySimGameSeries.ID] { get }
    func addSeries(id: LegacySimGameSeries.ID)
    func removeSeries(id: LegacySimGameSeries.ID)
    func containsSeries(id: LegacySimGameSeries.ID) -> Bool

    func setStorageState(_ state: StationStorageState, for stationID: LegacySimStation.ID)
    func getStorageState(for stationID: LegacySimStation.ID) -> StationStorageState?
    func removeStorageState(for stationID: LegacySimStation.ID)
    var allStoredLegacyStationStates: [LegacySimStation.ID: StationStorageState] { get }

    var addedSeriesIDs: [SimGameSeries.ID] { get }
    func addSeries(id: SimGameSeries.ID)
    func removeSeries(id: SimGameSeries.ID)
    func containsSeries(id: SimGameSeries.ID) -> Bool

    func setStorageState(_ state: StationStorageState, for stationID: SimStation.ID)
    func getStorageState(for stationID: SimStation.ID) -> StationStorageState?
    func removeStorageState(for stationID: SimStation.ID)
    var allStoredStationStates: [SimStation.ID: StationStorageState] { get }
}
