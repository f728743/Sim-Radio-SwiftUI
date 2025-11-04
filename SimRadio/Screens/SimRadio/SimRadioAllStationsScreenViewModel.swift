//
//  SimRadioAllStationsScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.11.2025.
//

import Observation
import SwiftUI

@Observable @MainActor
class SimRadioAllStationsScreenViewModel {
    var mediaState: MediaState?
    var items: [Media] {
        let res = (mediaState?.persistedMediaList ?? [])
            .flatMap(\.items)
            .filter(\.id.isSimRadio)
        return res
    }
}
