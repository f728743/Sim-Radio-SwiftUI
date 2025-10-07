//
//  SearchScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.10.2025.
//

import Foundation
import AVFoundation

@Observable @MainActor
class SearchScreenViewModel {
    var audioPlayer: AVPlayer?
    var isPlaying = false
    var searchText: String = "" {
        didSet {
            performSearch()
        }
    }
    var stations: [RealRadioStationDTO] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let searchService = SearchService(apiService: APIService(baseURL: "https://cx10577.tw1.ru"))
    private var searchTask: Task<Void, Never>?
    
    func performSearch() {
        searchTask?.cancel()
        
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            stations = []
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
                stations = result.data.stations
            } catch {
                if !Task.isCancelled {
                    print("API call Error: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    stations = []
                }
            }
            isLoading = false
        }
    }
    
    func playStation(_ station: RealRadioStationDTO) {
        // Останавливаем предыдущее воспроизведение
        audioPlayer?.pause()
        
        guard let url = URL(string: station.urlResolved) else { return }
        
        let playerItem = AVPlayerItem(url: url)
        audioPlayer = AVPlayer(playerItem: playerItem)
        audioPlayer?.play()
        isPlaying = true
        
        // Обработка окончания воспроизведения
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            self.isPlaying = false
        }
    }
    
    private func playStation() {

    }
}
