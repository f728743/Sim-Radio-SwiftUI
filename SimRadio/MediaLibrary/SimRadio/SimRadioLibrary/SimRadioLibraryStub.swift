//
//  SimRadioLibraryStub.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

import Foundation

class SimRadioLibraryStub: SimRadioLibrary {
    func load() async {}
    func addSimRadio(url _: URL, persisted _: Bool) async throws {}
    func remove(_ series: SimGameSeries) async throws {}

    func downloadStation(_: SimStation.ID) async {}
    func removeDownload(_: SimStation.ID) async {}
    func pauseDownload(_: SimStation.ID) async {}
}
