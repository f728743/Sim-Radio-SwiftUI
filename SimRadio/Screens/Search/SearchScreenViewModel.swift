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
            performSearch()
        }
    }

    var items: [APISearchResultItem] = []
    var isLoading: Bool = false
    var errorMessage: String?

    var searchService: SearchService?
    private var searchTask: Task<Void, Never>?

    func add(_: APISearchResultItem) {}

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

    func playStation(_ station: APISearchResultItem) {
        // Останавливаем предыдущее воспроизведение
//        audioPlayer?.pause()
//        let urlStr = station.url.replacingOccurrences(of: "http://", with: "https://")
//        print("url: ", urlStr, station.id)
//        guard let url = URL(string: urlStr) else { return }
//
//        let playerItem = AVPlayerItem(url: url)
//        audioPlayer = AVPlayer(playerItem: playerItem)
//        audioPlayer?.play()
//        isPlaying = true
//
//        // Обработка окончания воспроизведения
//        NotificationCenter.default.addObserver(
//            forName: .AVPlayerItemDidPlayToEndTime,
//            object: playerItem,
//            queue: .main
//        ) { _ in
//            self.isPlaying = false
//        }
    }

    private func playStation() {}
}
