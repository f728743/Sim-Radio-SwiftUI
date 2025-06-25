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
        case addedNewModelSeriesIDs = "UserData.addedNewModelSeriesIDs" // Use a prefix for uniqueness
        case newModelStationStorageStates = "UserData.newModelStationStorageStates"
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

    // ----

    func addSeries(id: NewModelSimGameSeries.ID) {
        var currentIDs = addedNewModelSeriesIDs
        if !currentIDs.contains(id) {
            currentIDs.append(id)
            saveNewModelSeriesIDs(currentIDs)
        }
    }

    func removeSeries(id: NewModelSimGameSeries.ID) {
        var currentIDs = addedNewModelSeriesIDs
        currentIDs.removeAll { $0 == id }
        saveNewModelSeriesIDs(currentIDs)
    }

    func containsSeries(id: NewModelSimGameSeries.ID) -> Bool {
        addedNewModelSeriesIDs.contains(id)
    }

    func setStorageState(_ state: StationStorageState, for stationID: NewModelSimStation.ID) {
        var currentStates = loadStoredNewModelStatesDictionary()
        currentStates[stationID.userDefaultsKey] = state.rawValue
        saveStoredNewModelStatesDictionary(currentStates)
    }

    func getStorageState(for stationID: NewModelSimStation.ID) -> StationStorageState? {
        let currentStates = loadStoredNewModelStatesDictionary()
        guard let rawValue = currentStates[stationID.value] else {
            return nil
        }
        return StationStorageState(rawValue: rawValue)
    }

    func removeStorageState(for stationID: NewModelSimStation.ID) {
        var currentStates = loadStoredNewModelStatesDictionary()
        currentStates.removeValue(forKey: stationID.userDefaultsKey)
        saveStoredNewModelStatesDictionary(currentStates)
    }

    var addedNewModelSeriesIDs: [NewModelSimGameSeries.ID] {
        (userDefaults.stringArray(forKey: Key.addedNewModelSeriesIDs.rawValue) ?? [])
            .compactMap { value in
                URL(string: value).map { NewModelSimGameSeries.ID(origin: $0) }
            }
    }

    private func saveNewModelSeriesIDs(_ ids: [NewModelSimGameSeries.ID]) {
        let stringIDs = ids.map(\.origin.absoluteString)
        userDefaults.set(stringIDs, forKey: Key.addedNewModelSeriesIDs.rawValue)
    }

    var allStoredNewModelStationStates: [NewModelSimStation.ID: StationStorageState] {
        let rawStates = loadStoredNewModelStatesDictionary()
        var result: [NewModelSimStation.ID: StationStorageState] = [:]
        for (key, rawValue) in rawStates {
            if let state = StationStorageState(rawValue: rawValue) {
                result[NewModelSimStation.ID(userDefaultsKey: key)] = state
            }
        }
        return result
    }

    private func loadStoredNewModelStatesDictionary() -> [String: String] {
        userDefaults.dictionary(forKey: Key.newModelStationStorageStates.rawValue) as? [String: String] ?? [:]
    }

    private func saveStoredNewModelStatesDictionary(_ dictionary: [String: String]) {
        userDefaults.set(dictionary, forKey: Key.newModelStationStorageStates.rawValue)
    }
}

private extension NewModelSimStation.ID {
    var userDefaultsKey: String {
        [value, series.origin.absoluteString].joined(separator: ";")
    }

    init(userDefaultsKey: String) {
        let components = userDefaultsKey.split(separator: ";")
        guard components.count == 2, let url = URL(string: String(components[1])) else {
            fatalError("Invalid ID format: \(userDefaultsKey)")
        }
        value = String(components[0])
        series = .init(origin: url)
    }
}
