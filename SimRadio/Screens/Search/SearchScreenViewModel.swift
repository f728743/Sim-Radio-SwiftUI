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
    var audioPlayer: AVPlayer?
    var isPlaying = false
    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                performSearch()
            }
        }
    }

    var items: [APISearchResultItem] = []
    var isLoading: Bool = false
    var errorMessage: String?

    var searchService: SearchService?
    private var searchTask: Task<Void, Never>?

    func add(_ station: APIRealStationDTO) {
        print("add ", station.name)
    }

    func play(_ station: APIRealStationDTO) {
        print("play ", station.name)
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
