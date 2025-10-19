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
    let series: APISimRadioSeriesDTO

    init(series: APISimRadioSeriesDTO) {
        self.series = series
    }
}

extension APISimRadioSeriesDTO {
    static var stub: APISimRadioSeriesDTO {
        .init(
            id: "String",
            url: "",
            title: "",
            logo: "",
            stations: []
        )
    }
}
