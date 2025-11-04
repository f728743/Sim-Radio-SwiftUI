//
//  LibraryItemsGrid.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.11.2025.
//

import SwiftUI

struct LibraryItemsGrid: View {
    let title: String
    let items: [LibraryItem]
    let onTap: (LibraryItem) -> Void

    var body: some View {
        VStack(spacing: 13) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(items) { item in
                    LibraryItemView(label: item.label)
                        .onTapGesture {
                            onTap(item)
                        }
                }
            }
        }
    }
}

private struct LibraryItemView: View {
    let label: LibraryItem.Label

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ArtworkView(label.artwork)
            VStack(alignment: .leading, spacing: 0) {
                Text(label.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text(label.subtitle ?? "")
                    .font(.appFont.mediaListItemSubtitle)
                    .foregroundStyle(Color(.palette.textSecondary))
                    .lineLimit(1)
            }
        }
    }
}
