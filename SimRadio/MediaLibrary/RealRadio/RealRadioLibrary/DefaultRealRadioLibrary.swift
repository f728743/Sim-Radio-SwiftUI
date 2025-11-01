//
//  DefaultRealRadioLibrary.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

import CoreData

@MainActor
class DefaultRealRadioLibrary {
    weak var mediaState: RealRadioMediaState?
    weak var dataController: DataController?
    weak var delegate: RealRadioLibraryDelegate?
}

private extension DefaultRealRadioLibrary {
    func addToLibrary(_ new: RealRadioMedia, persisted: Bool) {
        guard let mediaState else { return }
        let curren = mediaState.realRadio
        let newStationIDs = Set(new.stations.keys)
        let idsToAdd = newStationIDs.subtracting(curren.stations.keys)

        let nonPersistedStations = persisted
            ? mediaState.nonPersistedRealStations.filter { !newStationIDs.contains($0) }
            : mediaState.nonPersistedRealStations + idsToAdd

        if persisted {
            let savedStationIDs = Set(curren.stations.keys)
                .subtracting(mediaState.nonPersistedRealStations)
            let stationIDsToSave = newStationIDs.subtracting(savedStationIDs)
            let stationsToSave = new.stations.filter { stationIDsToSave.contains($0.key) }
            Task {
                do {
                    for station in stationsToSave.values {
                        try await save(station)
                    }
                } catch {
                    print("Failed to save stations: \(error)")
                }
            }
        }

        let stationsToAdd = new.stations.filter { idsToAdd.contains($0.key) }
        delegate?.realRadioLibrary(
            self,
            didChange: RealRadioMedia(
                stations: curren.stations.merging(stationsToAdd) { _, new in new },
            ),
            nonPersistedStations: nonPersistedStations
        )
    }

    func save(_ station: RealStation) async throws {
        guard let context = dataController?.container.viewContext else { return }
        let data = try JSONEncoder().encode(station)
        let json = String(data: data, encoding: .utf8)

        let managedObject = Station(context: context)
        managedObject.id = station.id.stationUUID
        managedObject.name = station.title
        managedObject.tags = station.tags
        managedObject.data = json
        try context.save()
    }
}

extension DefaultRealRadioLibrary: RealRadioLibrary {
    func load() async {
        guard let context = dataController?.container.viewContext,
              let mediaState else { return }
        let curren = mediaState.realRadio
        let fetchRequest: NSFetchRequest<Station> = Station.fetchRequest()
        do {
            let managedObjects = try context.fetch(fetchRequest)
            let stations = managedObjects.compactMap { RealStation(from: $0) }
            let stationDictionary = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
            let stationIDs = Set(stations.map(\.id))

            let newMediaState = RealRadioMedia(
                stations: curren.stations.merging(stationDictionary) { _, new in new },
            )

            let newNonPersistedRealStations = mediaState.nonPersistedRealStations.filter { !stationIDs.contains($0) }
            delegate?.realRadioLibrary(
                self,
                didChange: newMediaState,
                nonPersistedStations: newNonPersistedRealStations
            )
        } catch {
            print("Failed to fetch stations: \(error)")
        }
    }

    func addRealRadio(_ stations: [RealStation], persisted: Bool) async throws {
        let new = RealRadioMedia(stations: Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) }))
        addToLibrary(new, persisted: persisted)
    }
}

extension RealStation {
    init?(from managedObject: Station) {
        guard
            let json = managedObject.data.map({ Data($0.utf8) }),
            let series = try? JSONDecoder().decode(RealStation.self, from: json)
        else { return nil }
        self = series
    }
}
