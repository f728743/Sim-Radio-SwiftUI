//
//  SeriesDetailsOtherStations.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 22.10.2025.
//

import SwiftUI

struct SeriesDetailsOtherStations: View {
    let series: APISimRadioSeriesDTO

    var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(itemWidth)), count: 4)
    }
    
    var body: some View {
        VStack {
            SeriesDetailsSectionTitle("Other stations")
                .padding(.horizontal, ViewConst.screenPaddings)
            carusel
        }
    }
    
    var carusel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: Self.caruselSpacing) {
                ForEach(series.otherStationData) { station in
                    StationView(
                        artwork: station.artwork(seriesURL: series.url),
                        title: station.title
                    )
                }
            }
            .padding(.horizontal, ViewConst.screenPaddings)
        }
    }

    static let caruselSpacing = CGFloat(12)
    let itemWidth = ViewConst.itemWidth(
        forItemsPerScreen: 1,
        spacing: Self.caruselSpacing,
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
