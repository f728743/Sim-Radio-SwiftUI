//
//  SimRadioLibraryStub.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.04.2025.
//

import Foundation

class SimRadioLibraryStub: SimRadioLibrary {
    func downloadStation(_: SimStation.ID) async {}
    func removeDownload(_: SimStation.ID) async {}
    func pauseDownload(_: SimStation.ID) async {}
    func testPopulate() async {}
    func load() async {}
}
