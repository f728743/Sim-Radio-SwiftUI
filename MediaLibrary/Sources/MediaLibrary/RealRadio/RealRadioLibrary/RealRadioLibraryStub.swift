//
//  RealRadioLibraryStub.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

final class RealRadioLibraryStub: RealRadioLibrary {
    func load() async {}
    func addStations(_: [RealStation], persisted _: Bool) async throws {}
    func removeStation(withID _: RealStation.ID) async {}
}
