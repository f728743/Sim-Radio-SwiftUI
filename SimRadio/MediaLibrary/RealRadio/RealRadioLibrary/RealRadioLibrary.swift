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
    func addRealRadio(_: [RealStation], persisted: Bool) async throws
    func removeRealRadio(_ radio: RealStation.ID) async throws
}

@MainActor
protocol RealRadioLibraryDelegate: AnyObject {
    func realRadioLibrary(
        _ library: RealRadioLibrary,
        didChange media: RealRadioMedia,
        nonPersistedStations: [RealStation.ID]
    )
}
