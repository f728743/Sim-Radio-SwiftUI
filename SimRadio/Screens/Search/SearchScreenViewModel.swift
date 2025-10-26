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
            try await mediaState?.addRealRadio(realStation, persisted: true)
        }
    }

    func play(_ dto: APIRealStationDTO) {
        Task {
            guard let realStation = RealStation(dto) else { return }
            try await mediaState?.addRealRadio(realStation, persisted: false)
            let media: MediaID = .realRadio(realStation.id)
            mediaPlayer?.play(media, of: [media])
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

extension RealStation {
    init?(_ dto: APIRealStationDTO) {
        guard let stream = URL(string: dto.url) else { return nil }
        self.init(
            id: .init(stationUUID: dto.stationuuid),
            title: dto.name,
            logo: dto.cachedFavicon.flatMap { URL(string: $0) },
            stream: stream,
            tags: dto.tags.map { prettyPrintTags($0) },
            language: dto.language,
            country: dto.country,
            votes: dto.votes,
            clickCount: dto.clickcount,
            clickTrend: dto.clicktrend
        )
    }
}

func prettyPrintTags(_ tags: String) -> String {
    tags
        .split(separator: ",")
        .map(\.capitalized)
        .joined(separator: ", ")
}
