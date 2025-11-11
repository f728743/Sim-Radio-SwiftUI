//
//  SeriesDetailsSeries.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 22.10.2025.
//

import DesignSystem
import Services
import SwiftUI

struct SeriesDetailsSeries: View {
    let series: APISimRadioSeriesDTO
    let isAdded: Bool?
    let onAdd: () -> Void
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ArtworkView(series.artwork, cornerRadius: 9)
                .frame(width: 98)
            VStack(alignment: .leading, spacing: 0) {
                Text(series.title)
                    .font(.system(size: 16))
                Text(series.description)
                    .font(.system(size: 13))
                    .padding(.top, 3)

                Button(
                    action: {
                        if isAdded == false {
                            onAdd()
                        }
                    },
                    label: {
                        ZStack {
                            Circle()
                                .foregroundStyle(Color(.palette.buttonBackground))
                            if let isAdded {
                                Image(systemName: isAdded ? "checkmark" : "plus")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color.brand)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                        .frame(width: 32, height: 32)
                    }
                )
                .padding(.top, 6)
                .padding(.bottom, 2)
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SeriesDetailsSeries(
        series: .mock,
        isAdded: false,
        onAdd: {}
    )
}
