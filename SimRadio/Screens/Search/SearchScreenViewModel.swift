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

    func add(_ dto: APIRealStationDTO) {
        Task {
            guard let realStation = RealStation(dto) else { return }
            try await mediaState?.addRealRadio([realStation], persisted: true)
        }
    }

    func play(_ dto: APIRealStationDTO) {
        Task {
            let allStations = items.compactMap {
                if case let .realStation(station) = $0 {
                    return RealStation(station)
                }
                return nil
            }

            guard let realStation = RealStation(dto) else { return }
            try await mediaState?.addRealRadio(allStations, persisted: false)
            mediaPlayer?.play(.realRadio(realStation.id), of: allStations.map { .realRadio($0.id) })
        }
    }

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
                items = result.items
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
}

func prettyPrintTags(_ tags: String) -> String {
    tags
        .split(separator: ",")
        .map(\.capitalized)
        .joined(separator: ", ")
}
