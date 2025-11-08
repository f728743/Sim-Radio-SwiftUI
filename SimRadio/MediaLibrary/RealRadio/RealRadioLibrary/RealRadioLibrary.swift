//
//  RealRadioLibrary.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.10.2025.
//

import Foundation

@MainActor
protocol RealRadioLibrary {
    func load() async
    func addStations(_: [RealStation], persisted: Bool) async throws
    func removeStation(withID id: RealStation.ID) async throws
}

@MainActor
protocol RealRadioLibraryDelegate: AnyObject {
    func realRadioLibrary(
        _ library: RealRadioLibrary,
        didChange media: RealRadioMedia,
        nonPersistedStations: [RealStation.ID]
    )
}
