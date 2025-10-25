//
//  SeriesDetailsScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 19.10.2025.
//

import Observation
import SwiftUI

@Observable @MainActor
class SeriesDetailsScreenViewModel {
    let series: APISimRadioSeriesDTO

    weak var mediaState: MediaState?
    weak var mediaPlayer: MediaPlayer?

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

    func addSeries() {
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
}

private extension SeriesDetailsScreenViewModel {
    func playStation(_ stationID: String, of stationIDs: [String]) {
        guard let url = URL(string: series.url) else { return }
        mediaPlayer?.play(
            .media(stationID, url: url),
            of: stationIDs.map { .media($0, url: url) },
            mode: nil
        )
    }
}

private extension MediaID {
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
