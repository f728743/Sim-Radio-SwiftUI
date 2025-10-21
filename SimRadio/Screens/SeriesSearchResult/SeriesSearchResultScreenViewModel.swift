//
//  SeriesSearchResultScreenViewModel.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 19.10.2025.
//

import Observation
import SwiftUI

@Observable @MainActor
class SeriesSearchResultScreenViewModel {
    struct Display {
        let cover: Cover
        let series: Series
    }

    let seriesDTO: APISimRadioSeriesDTO
    private var series: SimRadioDTO.GameSeries?

    init(series: APISimRadioSeriesDTO) {
        seriesDTO = series
    }

    var display: Display {
        guard let series else { return .placeholder }
        let result = Display(
            origin: seriesDTO.url,
            dto: series,
            stations: seriesDTO.stations.map(\.id)
        )
        return result ?? .placeholder
    }

    func load() async throws {
        guard let url = URL(string: seriesDTO.url) else { return }
        let jsonData = try await URLSession.shared.data(from: url)
        let radio = try JSONDecoder().decode(SimRadioDTO.GameSeries.self, from: jsonData.0)
        series = radio
    }

    func play() {
        print("play ", display.series.title)
    }

    func addSeries() {
        print("add ", display.series.title)
    }
}

private extension SeriesSearchResultScreenViewModel {}

extension SeriesSearchResultScreenViewModel.Display {
    struct Cover {
        let image: URL?
        let title: String
    }

    struct Series {
        let artwork: URL?
        let title: String
        let stationCount: Int
        var description: LocalizedStringKey {
            "^[\(stationCount) station](inflect: true)"
        }
    }

    static var placeholder: Self {
        .init(
            cover: .init(image: nil, title: ""),
            series: .init(artwork: nil, title: "", stationCount: 0)
        )
    }
}

extension APISimRadioSeriesDTO {
    static var stub: APISimRadioSeriesDTO {
        .init(
            id: "",
            url: "",
            title: "",
            logo: "",
            stations: []
        )
    }
}

extension SeriesSearchResultScreenViewModel.Display {
    init?(origin: String, dto: SimRadioDTO.GameSeries, stations _: [String]) {
        guard let origin = URL(string: origin) else { return nil }
        let coverURL = origin
            .deletingLastPathComponent()
            .appendingPathComponent(dto.meta.cover.image)

        let seriesAwtworkURL = origin
            .deletingLastPathComponent()
            .appendingPathComponent(dto.meta.logo)

        self.init(
            cover: .init(
                image: coverURL,
                title: dto.meta.cover.title
            ),
            series: Series(
                artwork: seriesAwtworkURL,
                title: dto.meta.title,
                stationCount: dto.stations.count
            )
        )
    }
}
