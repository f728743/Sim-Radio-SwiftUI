//
//  SearchScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.09.2025.
//

import SwiftUI

struct SearchScreen: View {
    @State private var viewModel = SearchScreenViewModel()
    @Environment(Dependencies.self) var dependencies
    @Environment(Router.self) var router

    @State var firstTime = true

    var body: some View {
        content
            .navigationTitle("Search")
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("Search for radio stations...")
            )
            .task {
                viewModel.searchService = SearchService(apiService: dependencies.apiService)

                if firstTime { // TODO: remove
                    firstTime = false
                    viewModel.searchText = "fm"
                }
            }
    }
}

private extension SearchScreen {
    var content: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Searching...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }

            if viewModel.items.isEmpty, !viewModel.isLoading, viewModel.errorMessage == nil {
                ContentUnavailableView.search
            } else {
                List(viewModel.items) { item in
                    SearchItemView(
                        item: item,
                        onEvent: { event in
                            switch event {
                            case let .add(station):
                                viewModel.add(station)
                            case let .play(station):
                                viewModel.play(station)
                            case let .open(series):
                                router.navigateToSeriesSearchResult(series: series)
                            }
                        }
                    )
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct SearchItemLabel<TrailingContent: View>: View {
    let artwork: Artwork
    let title: String
    var subtitle: String?
    var kindDescription: String?
    let onTap: () -> Void
    private let trailingContent: TrailingContent?

    init(
        artwork: Artwork,
        title: String,
        subtitle: String? = nil,
        kindDescription: String? = nil,
        onTap: @escaping () -> Void,
        trailingContent: (() -> TrailingContent)? = nil,
    ) {
        self.artwork = artwork
        self.title = title
        self.subtitle = subtitle
        self.kindDescription = kindDescription
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
        ArtworkView(artwork, cornerRadius: 4)
            .frame(width: 56, height: 56)
    }
}

private struct SearchItemView: View {
    enum Event {
        case add(station: APIRealStationDTO)
        case play(station: APIRealStationDTO)
        case open(series: APISimRadioSeriesDTO)
    }

    let item: APISearchResultItem
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
            case let .realStation(item):
                SearchItemLabel(
                    artwork: item.artwork,
                    title: item.name,
                    subtitle: item.tags?.split(separator: ",").joined(separator: ", "),
                    kindDescription: "Radio",
                    onTap: {
                        onEvent(.play(station: item))
                    },
                    trailingContent: {
                        Button(
                            action: {
                                onEvent(.add(station: item))
                            },
                            label: {
                                ZStack {
                                    Circle()
                                        .foregroundStyle(Color(.palette.buttonBackground))
                                    Image(systemName: "plus")
                                        .font(.system(size: 19, weight: .semibold))
                                        .foregroundStyle(Color(.palette.brand))
                                }
                                .frame(width: 32, height: 32)
                            }
                        )
                        .buttonStyle(.plain)
                    }
                )
            }
        }
        .listRowInsets(.rowInsets)
        .alignmentGuide(.listRowSeparatorLeading) {
            $0[.leading]
        }
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub

    SearchScreen()
        .withRouter()
        .environment(dependencies)
}
