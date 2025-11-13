//
//  SearchScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.10.2025.
//

import AVFoundation
import Combine
import DesignSystem
import Foundation
import MediaLibrary
import Player
import Services
import SwiftUI

@Observable @MainActor
final class SearchScreenViewModel {
    var dto: APISearchResponseDTO?
    var playerState: MediaPlayerState = .paused(media: .none, mode: nil)
    var playIndicatorSpectrum: [Float] = .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
    var isLoading: Bool = false
    var errorMessage: String?

    weak var mediaState: MediaState?
    weak var player: MediaPlayer? {
        didSet {
            observeMediaPlayerState()
        }
    }

    var searchService: SearchService?

    private var searchTask: Task<Void, Never>?
    var cancellables = Set<AnyCancellable>()

    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                performSearch()
            }
        }
    }

    func add(_ dto: APIRealStationDTO) {
        Task {
            guard let realStation = RealStation(dto, timestamp: Date()) else { return }
            try await mediaState?.addRealRadio([realStation], persisted: true)
        }
    }

    func play(_ dto: APIRealStationDTO) {
        Task {
            let allStations = items.compactMap {
                if case let .realStation(station, _) = $0 {
                    return RealStation(station, timestamp: nil)
                }
                return nil
            }

            guard let realStation = RealStation(dto, timestamp: nil) else { return }
            try await mediaState?.addRealRadio(allStations, persisted: false)
            player?.play(.realRadio(realStation.id), of: allStations.map { .realRadio($0.id) })
        }
    }

    var items: [APISearchResultItem] {
        guard let dto else { return [] }
        let persisted = addedStations
        let result: [APISearchResultItem] = dto.simRadio.map { .simRadio(dto: $0) } +
            dto.realRadio.map { sationDTO in
                .realStation(
                    dto: sationDTO,
                    isAdded: persisted.contains(sationDTO.mediaID)
                )
            }
        return result
    }
}

private extension SearchScreenViewModel {
    func performSearch() {
        guard let searchService else { return }

        if urlInputHandled() {
            return
        }

        searchTask?.cancel()

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            dto = nil
            errorMessage = nil
            isLoading = false
            return
        }

        errorMessage = nil
        searchTask = Task { @MainActor in
            do {
                isLoading = true
                try await Task.sleep(for: .milliseconds(500))

                guard !Task.isCancelled else {
                    return
                }

                let result = try await searchService.search(query: searchText)
                guard !Task.isCancelled else {
                    return
                }
                dto = result
                isLoading = false
            } catch {
                if !Task.isCancelled {
                    print("API call Error: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    dto = nil
                    isLoading = false
                }
            }
        }
    }

    func urlInputHandled() -> Bool {
        guard searchText.hasPrefix("https://"),
              searchText.hasSuffix(".json"),
              let url = URL(string: searchText) else {
            return false
        }
        Task {
            try await mediaState?.addSimRadio(url: url, persisted: true)
        }
        return true
    }

    var addedStations: Set<MediaID> {
        Set(
            (mediaState?.mediaList(persisted: true) ?? [])
                .flatMap(\.items)
                .filter(\.id.isRealRadio)
                .map(\.id)
        )
    }
}

extension SearchScreenViewModel: PlayerStateObserving {}

extension APIRealStationDTO {
    var mediaID: MediaID {
        .realRadio(.init(stationUUID: stationuuid))
    }
}

extension APISearchResultItem {
    var mediaID: MediaID? {
        if case let .realStation(dto, _) = self {
            return dto.mediaID
        }
        return nil
    }
}

extension APISimRadioSeriesDTO {
    var artwork: Artwork {
        .album(buildMediaURL(from: url, with: logo))
    }
}

extension APIRealStationDTO {
    var artwork: Artwork {
        let url = cachedFavicon.flatMap { URL(string: $0) }
        return .radio(url, name: name)
    }
}

func buildMediaURL(from baseURL: String, with filename: String) -> URL? {
    guard let baseURL = URL(string: baseURL) else {
        return nil
    }
    let baseDirectory = baseURL.deletingLastPathComponent()
    return baseDirectory.appendingPathComponent(filename)
}
