//
//  DownloadedScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 12.04.2025.
//

import MediaLibrary
import Observation
import SwiftUI

@Observable @MainActor
final class DownloadedScreenViewModel {
    var mediaState: MediaState?
    var items: [Media] {
        mediaState?.downloadedMedia ?? []
    }
}
