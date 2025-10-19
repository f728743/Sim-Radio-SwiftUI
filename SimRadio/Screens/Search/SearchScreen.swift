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
                viewModel.searchText = "gta"
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
                            case let .add(station): viewModel.add(station)
                            case let .play(station): viewModel.play(station)
                            case let .open(series): viewModel.open(series)
                            }
                        }
                    )
                }
                .listStyle(.plain)
            }
        }
    }
}

struct SearchItemLabel: View {
    let artwork: Artwork
    let title: String
    var subtitle: String?
    var kindDescription: String?

    var body: some View {
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
        
        var subtitleText: String {
            [kindDescription, subtitle]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
        }
    }

    var artworkView: some View {
        ArtworkView(artwork, cornerRadius: 4)
            .frame(width: 56, height: 56)
    }
}

struct SearchItemView: View {
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
                HStack(spacing: 0) {
                    SearchItemLabel(
                        artwork: item.artwork,
                        title: item.title,
                        kindDescription: "Sim Radio series"
                    )
                    Spacer()
                    Button(
                        action: {},
                        label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color(.palette.textSecondary))
                        }
                    )
                }
            case let .realStation(item):
                HStack(spacing: 0) {
                    SearchItemLabel(
                        artwork: item.artwork,
                        title: item.name,
                        subtitle: item.tags?.split(separator: ",").joined(separator: ", "),
                        kindDescription: "Radio"
                    )
                    Spacer()
                    Button(
                        action: {},
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
                }
            }
        }
        .frame(height: 76)
        .contentShape(.rect)
        .listRowInsets(.rowInsets)
        .alignmentGuide(.listRowSeparatorLeading) {
            $0[.leading]
        }
    }
}

#Preview {
    SearchScreen()
}
