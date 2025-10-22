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
        .contentMargins(.bottom, 200, for: .scrollContent)
    }
}

struct SeriesDetailsOtherStations: View {
    let series: APISimRadioSeriesDTO

    var body: some View {
        VStack {
            SeriesDetailsSectionTitle("Other Stations")
                .padding(.horizontal, ViewConst.screenPaddings)
            carusel
        }
    }

    var carusel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Self.caruselSpacing) {
                ForEach(series.foundStationData) { item in
                    itemView(item)
                }
            }
            .padding(.horizontal, ViewConst.screenPaddings)
        }
    }

    func itemView(_ station: APISimStationDTO) -> some View {
        VStack(spacing: 7) {
            ArtworkView(station.artwork(seriesURL: series.url), cornerRadius: 7)

            Text(station.title)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: itemWidth)
        .lineLimit(1)
    }

    static let caruselSpacing = CGFloat(12)
    let itemWidth = ViewConst.itemWidth(
        forItemsPerScreen: 2,
        spacing: Self.caruselSpacing,
        containerWidth: UIScreen.size.width
    )
}

#Preview {
    SeriesDetailsScreen(series: .empty)
}
