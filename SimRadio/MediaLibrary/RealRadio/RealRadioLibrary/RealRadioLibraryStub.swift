//
//  RealRadioLibraryStub.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

class RealRadioLibraryStub: RealRadioLibrary {
    func load() async {}
    func addStations(_: [RealStation], persisted _: Bool) async throws {}
    func removeStation(withID id: RealStation.ID) async {}
}
