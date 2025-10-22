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
    private var seriesMedia: SimRadioDTO.GameSeries?

    init(series: APISimRadioSeriesDTO) {
        self.series = series
    }

    func load() async throws {
        guard let url = URL(string: series.url) else { return }
        let jsonData = try await URLSession.shared.data(from: url)
        let radio = try JSONDecoder().decode(SimRadioDTO.GameSeries.self, from: jsonData.0)
        seriesMedia = radio
    }

    func play() {
        print("play ", series.title)
    }

    func addSeries() {
        print("add ", series.title)
    }
}

private extension SeriesDetailsScreenViewModel {}

extension APISimRadioSeriesDTO {
    static var empty: APISimRadioSeriesDTO {
        .init(
            id: "",
            url: "",
            title: "",
            logo: "",
            coverTitle: "",
            coverLogo: "",
            stations: [],
            foundStations: []
        )
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
