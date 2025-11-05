//
//  SearchScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.10.2025.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI

@Observable @MainActor
class SearchScreenViewModel {
    var items: [APISearchResultItem] = []
    var state: MediaPlayerState = .paused(media: .none, mode: nil)
    var palyIndicatorSpectrum: [Float] = .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
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
    private var cancellables = Set<AnyCancellable>()

    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                performSearch()
            }
        }
    }

    func add(_ dto: APIRealStationDTO) {
        guard let stationIndex = items.firstIndex(where: { $0.id == dto.stationuuid }) else {
            return
        }
        items[stationIndex] = .realStation(dto: dto, isAdded: true)
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

    func mediaActivity(_ mediaID: MediaID) -> MediaActivity? {
        switch state {
        case let .paused(pausedMediaID, _): pausedMediaID == mediaID ? .paused : nil
        case let .playing(playingMediaID, _): playingMediaID == mediaID ? .spectrum(palyIndicatorSpectrum) : nil
        }
    }
}

private extension SearchScreenViewModel {
    func performSearch() {
        guard let searchService else { return }
        searchTask?.cancel()

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            items = []
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
                items = items(dto: result)
                isLoading = false
            } catch {
                if !Task.isCancelled {
                    print("API call Error: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    items = []
                    isLoading = false
                }
            }
        }
    }

    func items(dto: APISearchResponseDTO) -> [APISearchResultItem] {
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

    var addedStations: Set<MediaID> {
        Set(
            (mediaState?.mediaList(persisted: true) ?? [])
                .flatMap(\.items)
                .filter(\.id.isRealRadio)
                .map(\.id)
        )
    }

    func observeMediaPlayerState() {
        guard let player else { return }
        // Observe state changes
        cancellables.removeAll()
        player.$state
            .sink { [weak self] state in
                guard let self else { return }
                self.state = state
                palyIndicatorSpectrum = .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
            }
            .store(in: &cancellables)

        player.$palyIndicatorSpectrum
            .sink { [weak self] spectrum in
                self?.palyIndicatorSpectrum = spectrum
            }
            .store(in: &cancellables)
    }
}

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

func prettyPrintTags(_ tags: String) -> String {
    tags
        .split(separator: ",")
        .map(\.capitalized)
        .joined(separator: ", ")
}
