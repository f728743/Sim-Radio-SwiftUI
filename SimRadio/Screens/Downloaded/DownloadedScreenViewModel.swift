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

private extension MediaState {
    var downloadedMedia: [Media] {
        downloadStatus
            .map(\.self)
            .filter { $0.value.state == .completed }
            .compactMap {
                guard case let .simRadio(id) = $0.key,
                      let station = simRadio.stations[id] else { return nil }
                return Media(
                    id: .simRadio(station.id),
                    meta: .init(station.meta)
                )
            }
    }
}
