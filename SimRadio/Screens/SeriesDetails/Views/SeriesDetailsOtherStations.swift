//
//  SeriesDetailsOtherStations.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 22.10.2025.
//

import SwiftUI

struct SeriesDetailsOtherStations: View {
    let series: APISimRadioSeriesDTO

    let gridLayout = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        VStack {
            SeriesDetailsSectionTitle("Other stations")
                .padding(.horizontal, ViewConst.screenPaddings)
            carousel
        }
    }

    var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: gridLayout, alignment: .top, spacing: Self.carouselSpacing) {
                ForEach(series.otherStationData) { station in
                    StationView(
                        artwork: station.artwork(seriesURL: series.url),
                        title: station.title
                    )
                    .frame(width: itemWidth)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(ViewConst.screenPaddings, for: .scrollContent)
    }

    static let carouselSpacing = CGFloat(12)
    let itemWidth = ViewConst.itemWidth(
        forItemsPerScreen: 1,
        spacing: Self.carouselSpacing,
        containerWidth: UIScreen.size.width
    )
}

private struct StationView: View {
    let artwork: Artwork
    let title: String
    var body: some View {
        HStack {
            ArtworkView(artwork)
                .frame(width: 48, height: 48)

            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
