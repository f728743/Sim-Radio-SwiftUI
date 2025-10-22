//
//  SeriesDetailsScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 19.10.2025.
//

import Kingfisher
import SwiftUI

struct SeriesDetailsScreen: View {
    @State private var viewModel: SeriesDetailsScreenViewModel

    init(series: APISimRadioSeriesDTO) {
        _viewModel = State(
            wrappedValue: SeriesDetailsScreenViewModel(series: series)
        )
    }

    var body: some View {
        ScrollView {
            scrollContent
        }
        .contentMargins(.bottom, 200, for: .scrollContent)
        .ignoresSafeArea()
        .task {
            try? await viewModel.load()
        }
    }
}

private extension SeriesDetailsScreen {
    var scrollContent: some View {
        VStack(spacing: 0) {
            SeriesDetailsCover(
                imageURL: viewModel.series.coverLogoURL,
                title: viewModel.series.title,
                onPlay: viewModel.play
            )
            VStack(spacing: 0) {
                SeriesDetailsSeries(
                    series: viewModel.series,
                    onAdd: viewModel.addSeries
                )
                .padding(.horizontal, ViewConst.screenPaddings)

                SeriesDetailsFoundStations(series: viewModel.series)
                    .padding(.top, 27)

                SeriesDetailsOtherStations(series: viewModel.series)
                    .padding(.top, 27)
            }
            .padding(.top, 30)
        }
    }
}

#Preview {
    SeriesDetailsScreen(series: .empty)
}
