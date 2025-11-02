//
//  RadioScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.11.2025.
//

import Observation
import SwiftUI

@Observable @MainActor
class RadioScreenViewModel {
    var mediaState: MediaState?
    var items: [Media] {
        mediaState?.downloadedMedia ?? []
    }
}
