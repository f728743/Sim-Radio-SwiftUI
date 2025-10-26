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
        guard let mediaState, let stationID = new.stations.keys.first else { return }
        let curren = mediaState.realRadio
        if !persisted {
            guard !curren.stations.keys.contains(stationID) else { return }
        }

        let nonPersistedStations = persisted
            ? mediaState.nonPersistedRealStations.filter { $0 != stationID }
            : mediaState.nonPersistedRealStations + [stationID]

        delegate?.realRadioLibrary(
            self,
            didChange: RealRadioMedia(
                stations: curren.stations.merging(new.stations) { _, new in new },
            ),
            nonPersistedStations: nonPersistedStations
        )
    }
}

extension DefaultRealRadioLibrary: RealRadioLibrary {
    func load() async {}

    func addRealRadio(_ station: RealStation, persisted: Bool) async throws {
        let new = RealRadioMedia(stations: [station.id: station])
        addToLibrary(new, persisted: persisted)
    }
}
