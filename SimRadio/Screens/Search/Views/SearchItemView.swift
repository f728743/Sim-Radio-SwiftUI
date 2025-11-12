//
//  SearchItemView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 24.10.2025.
//

import DesignSystem
import Services
import SharedUtilities
import SwiftUI

struct SearchItemView: View {
    enum Event {
        case add(station: APIRealStationDTO)
        case play(station: APIRealStationDTO)
        case open(series: APISimRadioSeriesDTO)
    }

    let item: APISearchResultItem
    var activity: MediaActivity?
    let onEvent: (Event) -> Void

    var body: some View {
        Group {
            switch item {
            case let .simRadio(item):
                SearchItemLabel(
                    artwork: item.artwork,
                    title: item.title,
                    kindDescription: "Sim Radio series",
                    onTap: {
                        onEvent(.open(series: item))
                    },
                    trailingContent: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(.palette.textSecondary))
                    }
                )

            case let .realStation(item, isAdded):
                SearchItemLabel(
                    artwork: item.artwork,
                    title: item.name,
                    subtitle: item.tags.map { prettyPrintTags($0) },
                    kindDescription: "Radio",
                    activity: activity,
                    onTap: {
                        onEvent(.play(station: item))
                    },
                    trailingContent: {
                        addButton(isAdded: isAdded) {
                            if !isAdded {
                                onEvent(.add(station: item))
                            }
                        }
                    }
                )
            }
        }
        .listRowInsets(.rowInsets)
        .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
    }

    private func addButton(isAdded: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .foregroundStyle(Color(.palette.buttonBackground))
                Image(systemName: isAdded ? "checkmark" : "plus")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isAdded)
    }
}

private struct SearchItemLabel<TrailingContent: View>: View {
    let artwork: Artwork
    let title: String
    let subtitle: String?
    let kindDescription: String?
    let activity: MediaActivity?
    let onTap: () -> Void
    private let trailingContent: TrailingContent?

    init(
        artwork: Artwork,
        title: String,
        subtitle: String? = nil,
        kindDescription: String? = nil,
        activity: MediaActivity? = nil,
        onTap: @escaping () -> Void,
        trailingContent: (() -> TrailingContent)? = nil,
    ) {
        self.artwork = artwork
        self.title = title
        self.subtitle = subtitle
        self.kindDescription = kindDescription
        self.activity = activity
        self.onTap = onTap
        self.trailingContent = trailingContent?()
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                artworkView
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15))

                    if !subtitleText.isEmpty {
                        Text(subtitleText)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                onTap()
            }
            trailingContent
        }
        .frame(height: 76)

        var subtitleText: String {
            [kindDescription, subtitle]
                .compactMap(\.self)
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
        }
    }

    var artworkView: some View {
        ZStack {
            ArtworkView(artwork, cornerRadius: 4)
            if let activity {
                Color.black.opacity(0.4)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                MediaActivityIndicator(state: activity)
                    .foregroundStyle(Color.white)
            }
        }
        .frame(width: 56, height: 56)
    }
}
