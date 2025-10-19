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
    }

    let seriesDTO: APISimRadioSeriesDTO
    private var series: SimRadioDTO.GameSeries?

    init(series: APISimRadioSeriesDTO) {
        seriesDTO = series
    }

    var display: Display? {
        guard let series else { return nil }
        let result = Display(
            origin: seriesDTO.url,
            dto: series,
            stations: seriesDTO.stations.map(\.id)
        )
        return result
    }

    func load() async throws {
        guard let url = URL(string: seriesDTO.url) else { return }
        let jsonData = try await URLSession.shared.data(from: url)
        let radio = try JSONDecoder().decode(SimRadioDTO.GameSeries.self, from: jsonData.0)
        series = radio
    }
}

private extension SeriesSearchResultScreenViewModel {}

extension SeriesSearchResultScreenViewModel.Display {
    struct Cover {
        let title: String
        let image: URL?
    }
}

extension APISimRadioSeriesDTO {
    static var stub: APISimRadioSeriesDTO {
        .init(
            id: "String",
            url: "",
            title: "String",
            logo: "String",
            stations: []
        )
    }
}

extension SeriesSearchResultScreenViewModel.Display {
    init?(origin: String, dto: SimRadioDTO.GameSeries, stations _: [String]) {
        guard let origin = URL(string: origin) else { return nil }
        self.init(
            cover: .init(
                title: dto.meta.cover.title,
                image: origin
                    .deletingLastPathComponent()
                    .appendingPathComponent(dto.meta.cover.image + SimRadioDTO.Const.largeImageExtension)
            )
        )
    }
}
