//
//  DefaultRealRadioLibrary.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

@MainActor
class DefaultRealRadioLibrary {
    weak var mediaState: RealRadioMediaState?
    weak var delegate: RealRadioLibraryDelegate?
}

private extension DefaultRealRadioLibrary {
    func addToLibrary(_ new: RealRadioMedia, persisted: Bool) {
        guard let mediaState else { return }
        let stationIDs = Set(new.stations.keys)
        let idsToAdd = stationIDs.subtracting(mediaState.realRadio.stations.keys)

        let curren = mediaState.realRadio

        let nonPersistedStations = persisted
            ? mediaState.nonPersistedRealStations.filter { idsToAdd.contains($0) }
            : mediaState.nonPersistedRealStations + idsToAdd

        let stationsToAdd = new.stations.filter { idsToAdd.contains($0.key) }
        delegate?.realRadioLibrary(
            self,
            didChange: RealRadioMedia(
                stations: curren.stations.merging(stationsToAdd) { _, new in new },
            ),
            nonPersistedStations: nonPersistedStations
        )
    }
}

extension DefaultRealRadioLibrary: RealRadioLibrary {
    func load() async {}

    func addRealRadio(_ stations: [RealStation], persisted: Bool) async throws {
        let new = RealRadioMedia(stations: Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) }))
        addToLibrary(new, persisted: persisted)
    }
}
