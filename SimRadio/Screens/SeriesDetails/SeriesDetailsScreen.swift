//
//  SeriesDetailsScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 19.10.2025.
//

import Kingfisher
import SwiftUI

struct SeriesDetailsScreen: View {
    @Environment(Router.self) var router
    @Environment(Dependencies.self) var dependencies
    @State private var viewModel: SeriesDetailsScreenViewModel
    @State var scrollOffset: CGFloat = 0

    init(series: APISimRadioSeriesDTO) {
        _viewModel = State(
            wrappedValue: SeriesDetailsScreenViewModel(series: series)
        )
    }

    var body: some View {
        ScrollView {
            scrollContent
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newValue in
            scrollOffset = newValue
        }
        .contentMargins(.bottom, 200, for: .scrollContent)
        .ignoresSafeArea()
        .task {
            viewModel.mediaState = dependencies.mediaState
            viewModel.mediaPlayer = dependencies.mediaPlayer
            try? await viewModel.load()
        }
    }

    var detailsBarOpacity: Double {
        let imageHeight = UIScreen.size.width
        let topOffset = imageHeight - scrollOffset - SeriesDetailsBar.Const.height
        let high: CGFloat = 140
        let low: CGFloat = 25

        if topOffset >= high {
            return 1
        } else if topOffset <= low {
            return 0
        }
        return (topOffset - low) / (high - low)
    }
}

private extension SeriesDetailsScreen {
    var scrollContent: some View {
        VStack(spacing: -SeriesDetailsBar.Const.height) {
            ParallaxHeaderView(height: UIScreen.size.width) {
                KFImage.url(viewModel.series.coverLogoURL)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .aspectRatio(1.0, contentMode: .fill)
                    .offset(y: max(scrollOffset, 0) / 4)
            }
            VStack(spacing: 0) {
                SeriesDetailsBar(
                    title: viewModel.series.title,
                    controsOpacity: detailsBarOpacity,
                    onPlay: viewModel.play
                )
                VStack(spacing: 0) {
                    SeriesDetailsSeries(
                        series: viewModel.series,
                        onAdd: viewModel.addSeries
                    )
                    .padding(.horizontal, ViewConst.screenPaddings)
                    .padding(.top, 30)

                    SeriesDetailsFoundStations(
                        series: viewModel.series,
                        onTap: { station in
                            guard let item = viewModel.media(station.id) else { return }
                            router.navigateToMedia(item: item)
                        }
                    )
                    .padding(.top, 47)

                    SeriesDetailsOtherStations(
                        series: viewModel.series,
                        onTap: viewModel.playStation
                    )
                    .padding(.top, 27)
                }
                .background(Color(.systemBackground))
            }
        }
    }
}

#Preview {
    SeriesDetailsScreen(series: .mock)
}
