//
//  SeriesSearchResultScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 19.10.2025.
//

import SwiftUI

struct SeriesSearchResultScreen: View {
    @State private var viewModel: SeriesSearchResultScreenViewModel

    init(series: APISimRadioSeriesDTO) {
        _viewModel = State(
            wrappedValue: SeriesSearchResultScreenViewModel(series: series)
        )
    }

    var body: some View {
        Text("Series Search Result")
            .padding(25)
    }
}

#Preview {
    SeriesSearchResultScreen(series: .stub)
}
