//
//  SeriesDetailsOtherStations.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 22.10.2025.
//

import SwiftUI

struct SeriesDetailsOtherStations: View {
    let series: APISimRadioSeriesDTO
    let onTap: (APISimStationDTO) -> Void

    var body: some View {
        VStack(spacing: 14) {
            SeriesDetailsSectionTitle("Other stations")
                .padding(.horizontal, ViewConst.screenPaddings)
            carousel
        }
    }

    let gridLayout = Array(
        repeating: GridItem(.fixed(Const.itemHeight), spacing: 0),
        count: Const.rowsCount
    )

    var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(
                rows: gridLayout,
                alignment: .top,
                spacing: Const.carouselSpacing
            ) {
                let stations = series.otherStationData
                ForEach(stations.enumerated(), id: \.element) { index, element in
                    StationView(
                        artwork: element.artwork(seriesURL: series.url),
                        title: element.title,
                        subtitle: element.tags.split(separator: ",").joined(separator: ", "),
                        withDivider: needDivider(index: index, itemCount: stations.count)
                    )
                    .frame(width: itemWidth)
                    .onTapGesture {
                        onTap(element)
                    }
                }
            }
            .scrollTargetLayout()
            .frame(height: Const.itemHeight * CGFloat(Const.rowsCount))
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, ViewConst.screenPaddings, for: .scrollContent)
    }

    func needDivider(index: Int, itemCount: Int) -> Bool {
        ((index + 1) % Const.rowsCount != 0) && (index != itemCount - 1)
    }

    let itemWidth = ViewConst.itemWidth(
        forItemsPerScreen: 1,
        spacing: Const.carouselSpacing,
        containerWidth: UIScreen.size.width
    )
}

private enum Const {
    static let itemHeight: CGFloat = 56
    static let rowsCount: Int = 4
    static let carouselSpacing: CGFloat = 12
}

private struct StationView: View {
    let artwork: Artwork
    let title: String
    var subtitle: String?
    let withDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ArtworkView(artwork, cornerRadius: 5)
                    .frame(width: 48)

                VStack(spacing: 0) {
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 16))

                    Text(subtitle ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.palette.textSecondary))
                }
            }
            .frame(height: Const.itemHeight - 1)
            Divider()
                .padding(.leading, 60)
                .opacity(withDivider ? 1 : 0)
        }
        .contentShape(.rect)
    }
}

#Preview {
    SeriesDetailsOtherStations(series: .mock, onTap: { _ in })
}
