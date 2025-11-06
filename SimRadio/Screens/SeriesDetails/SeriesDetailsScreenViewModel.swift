//
//  SeriesDetailsScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 19.10.2025.
//

import Combine
import Observation
import SwiftUI

@Observable @MainActor
class SeriesDetailsScreenViewModel {
    let series: APISimRadioSeriesDTO

    weak var mediaState: MediaState?
    var state: MediaPlayerState = .paused(media: .none, mode: nil)
    var playIndicatorSpectrum: [Float] = .init(repeating: 0, count: MediaPlayer.Const.frequencyBands)
    var cancellables = Set<AnyCancellable>()
    private var isAddTapped: Bool = false
    weak var player: MediaPlayer? {
        didSet {
            observeMediaPlayerState()
        }
    }

    init(series: APISimRadioSeriesDTO) {
        self.series = series
    }

    func load() async throws {
        guard let url = URL(string: series.url) else { return }
        try await mediaState?.addSimRadio(url: url, persisted: false)
    }

    func play() {
        let stations = series.stations.map(\.id)
        guard let first = stations.first else { return }
        playStation(first, of: stations)
    }

    var isSeriesAdded: Bool? {
        guard let mediaState else { return nil }
        guard let id = series.mediaListID else {
            return false
        }
        if isAddTapped == true { return true }
        return mediaState.mediaList(persisted: true)
            .map(\.id)
            .contains(id)
    }

    func addSeries() {
        isAddTapped = true
        Task {
            guard let url = URL(string: series.url) else { return }
            try await mediaState?.addSimRadio(url: url, persisted: true)
        }
    }

    func playStation(_ station: APISimStationDTO) {
        let foundStations = series.foundStations
        let otherStations = series.otherStationData.map(\.id)

        if foundStations.contains(station.id) {
            playStation(station.id, of: foundStations)
        } else if otherStations.contains(station.id) {
            playStation(station.id, of: otherStations)
        }
    }

    func media(_ stationID: String) -> Media? {
        guard let url = URL(string: series.url) else { return nil }
        let result = mediaState?.media(withID: .media(stationID, url: url))
        return result
    }
}

extension SeriesDetailsScreenViewModel: PlayerStateObserving {}

extension APISimRadioSeriesDTO {
    var mediaListID: MediaListID? {
        guard let url = URL(string: url) else { return nil }
        return .simRadioSeries(.init(origin: url))
    }
}

private extension SeriesDetailsScreenViewModel {
    func playStation(_ stationID: String, of stationIDs: [String]) {
        guard let url = URL(string: series.url) else { return }
        player?.play(
            .media(stationID, url: url),
            of: stationIDs.map { .media($0, url: url) },
            mode: nil
        )
    }
}

extension MediaID {
    static func media(_ stationID: String, url: URL) -> Self {
        .simRadio(.init(series: .init(origin: url), value: stationID))
    }
}

extension APISimRadioSeriesDTO {
    var coverLogoURL: URL? {
        buildMediaURL(from: url, with: coverLogo)
    }

    var description: LocalizedStringKey {
        "^[\(stations.count) station](inflect: true)"
    }

    var foundStationData: [APISimStationDTO] {
        stations.filter { foundStations.contains($0.id) }
    }

    var otherStationData: [APISimStationDTO] {
        stations.filter { !foundStations.contains($0.id) }
    }
}

extension APISimStationDTO {
    func artwork(seriesURL: String) -> Artwork {
        .radio(buildMediaURL(from: seriesURL, with: logo))
    }
}
