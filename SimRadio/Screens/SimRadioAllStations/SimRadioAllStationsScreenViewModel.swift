//
//  SimRadioAllStationsScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.11.2025.
//

import MediaLibrary
import Observation
import SwiftUI

@Observable @MainActor
final class SimRadioAllStationsScreenViewModel {
    var mediaState: MediaState?
    var items: [Media] {
        let res = (mediaState?.mediaList(persisted: true) ?? [])
            .flatMap(\.items)
            .filter(\.id.isSimRadio)
        return res
    }
}
