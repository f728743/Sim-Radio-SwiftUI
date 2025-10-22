//
//  SeriesDetailsFoundStations.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 22.10.2025.
//

import SwiftUI

struct SeriesDetailsFoundStations: View {
    let series: APISimRadioSeriesDTO

    var body: some View {
        VStack {
            SeriesDetailsSectionTitle("Found stations")
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
        .contentMargins(.bottom, 0, for: .scrollContent)
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
