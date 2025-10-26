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
    func addRealRadio(_: APIRealStationDTO, persisted: Bool) async throws
}

@MainActor
protocol RealLibraryDelegate: AnyObject {
    func realRadioLibrary(
        _ library: RealRadioLibrary,
        didChange media: RealRadioMedia,
        nonPersistedSeries: [RealStation.ID]
    )
}
