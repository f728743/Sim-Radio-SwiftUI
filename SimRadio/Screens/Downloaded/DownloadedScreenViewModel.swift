//
//  DownloadedScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 12.04.2025.
//

import Observation
import SwiftUI

@Observable @MainActor
class DownloadedScreenViewModel {
    var mediaState: MediaState?
    var items: [Media] {
        mediaState?.downloadedMedia ?? []
    }
}
