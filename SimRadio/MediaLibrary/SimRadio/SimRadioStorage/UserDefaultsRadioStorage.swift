//
//  UserDefaultsRadioStorage.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 18.04.2025.
//

import Foundation

@MainActor
class UserDefaultsRadioStorage: SimRadioStorage {
    private enum Key: String {
        case addedSeriesIDs = "UserData.addedSeriesIDs" // Use a prefix for uniqueness
        case stationStorageStates = "UserData.stationStorageStates"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: Managing Series

    var addedSeriesIDs: [SimGameSeries.ID] {
        (userDefaults.stringArray(forKey: Key.addedSeriesIDs.rawValue) ?? [])
            .compactMap { SimGameSeries.ID(value: $0) }
    }

    func addSeries(id: SimGameSeries.ID) {
        var currentIDs = addedSeriesIDs
        if !currentIDs.contains(id) {
            currentIDs.append(id)
            saveSeriesIDs(currentIDs)
        }
    }

    func removeSeries(id: SimGameSeries.ID) {
        var currentIDs = addedSeriesIDs
        currentIDs.removeAll { $0 == id }
        saveSeriesIDs(currentIDs)
    }

    func containsSeries(id: SimGameSeries.ID) -> Bool {
        addedSeriesIDs.contains(id)
    }

    private func saveSeriesIDs(_ ids: [SimGameSeries.ID]) {
        let stringIDs = ids.map(\.value)
        userDefaults.set(stringIDs, forKey: Key.addedSeriesIDs.rawValue)
    }

    // MARK: Managing the loading status of stations

    func setStorageState(_ state: StationStorageState, for stationID: SimStation.ID) {
        var currentStates = loadStoredStatesDictionary()
        currentStates[stationID.value] = state.rawValue
        saveStoredStatesDictionary(currentStates)
    }

    func getStorageState(for stationID: SimStation.ID) -> StationStorageState? {
        let currentStates = loadStoredStatesDictionary()
        guard let rawValue = currentStates[stationID.value] else {
            return nil
        }
        return StationStorageState(rawValue: rawValue)
    }

    func removeStorageState(for stationID: SimStation.ID) {
        var currentStates = loadStoredStatesDictionary()
        currentStates.removeValue(forKey: stationID.value)
        saveStoredStatesDictionary(currentStates)
    }

    var allStoredStationStates: [SimStation.ID: StationStorageState] {
        let rawStates = loadStoredStatesDictionary()
        var result: [SimStation.ID: StationStorageState] = [:]
        for (key, rawValue) in rawStates {
            if let state = StationStorageState(rawValue: rawValue) {
                result[SimStation.ID(value: key)] = state
            }
        }
        return result
    }

    private func loadStoredStatesDictionary() -> [String: String] {
        userDefaults.dictionary(forKey: Key.stationStorageStates.rawValue) as? [String: String] ?? [:]
    }

    private func saveStoredStatesDictionary(_ dictionary: [String: String]) {
        userDefaults.set(dictionary, forKey: Key.stationStorageStates.rawValue)
    }
}
