//
//  SearchScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.10.2025.
//

import AVFoundation
import Foundation

@Observable @MainActor
class SearchScreenViewModel {
    var items: [APISearchResultItem] = []
    var isLoading: Bool = false
    var errorMessage: String?

    weak var mediaState: MediaState?
    weak var mediaPlayer: MediaPlayer?
    var searchService: SearchService?

    private var searchTask: Task<Void, Never>?

    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                performSearch()
            }
        }
    }

    func add(_ station: APIRealStationDTO) {
        Task {
            try await mediaState?.addRealRadio(station, persisted: true)
        }
    }

    func play(_ station: APIRealStationDTO) {
        Task {
            try await mediaState?.addRealRadio(station, persisted: false)
            mediaPlayer?.play(
                .realRadio(.init(stationUUID: station.stationuuid)),
                of: items.compactMap {
                    switch $0 {
                    case let .realStation(dto): .realRadio(.init(stationUUID: dto.stationuuid))
                    default: nil
                    }
                },
                mode: nil
            )
        }
    }

    func performSearch() {
        guard let searchService else { return }
        searchTask?.cancel()

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            items = []
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil

        searchTask = Task { @MainActor in
            do {
                // Дебаунс 500ms
                try await Task.sleep(nanoseconds: 500_000_000)

                guard !Task.isCancelled else { return }

                let result = try await searchService.search(query: searchText)
                items = result.items
            } catch {
                if !Task.isCancelled {
                    print("API call Error: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    items = []
                }
            }
            isLoading = false
        }
    }
}
