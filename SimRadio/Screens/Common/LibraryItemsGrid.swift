//
//  LibraryItemsGrid.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.11.2025.
//

import DesignSystem
import SwiftUI

struct LibraryItemsGrid: View {
    enum Event {
        case tap(LibraryItem)
        case selected(LibraryContextMenuItem, LibraryItem)
    }

    static let itemPadding: CGFloat = 6
    let title: String
    let items: [LibraryItem]
    let onEvent: (Event) -> Void
    let contextMenu: (LibraryItem) -> [LibraryContextMenuItem?]

    var body: some View {
        VStack(spacing: 7) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Self.itemPadding)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 0), GridItem(.flexible(), spacing: 0)],
                spacing: 10
            ) {
                ForEach(items) { item in
                    LibraryItemView(label: item.label)
                        .onTapGesture {
                            onEvent(.tap(item))
                        }
                        .contextMenu {
                            ForEach(contextMenu(item), id: \.self) { menuItem in
                                if let menuItem {
                                    Button(role: menuItem.role) {
                                        onEvent(.selected(menuItem, item))
                                    } label: {
                                        Label(menuItem.label, systemImage: menuItem.systemImage)
                                    }

                                } else {
                                    Divider()
                                }
                            }
                        }
                }
            }
        }
    }
}

private struct LibraryItemView: View {
    let label: LibraryItem.Label

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ArtworkView(label.artwork)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text(label.subtitle ?? "")
                    .font(.appFont.mediaListItemSubtitle)
                    .foregroundStyle(Color(.palette.textSecondary))
                    .lineLimit(1)
            }
        }
        .padding(LibraryItemsGrid.itemPadding)
        .background(.background)
        .clipShape(.rect(cornerRadius: 14))
    }
}
