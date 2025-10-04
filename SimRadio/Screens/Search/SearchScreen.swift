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
//                            station.cachedFavicon.flatMap { URL(string: $0) },
//                        title: station.name,
//                        subtitle: station.country,
                        onAdd: {
                            viewModel.add(item)
                        }
                    )
                    .onTapGesture {
                        viewModel.playStation(item)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct SearchItemLabel: View {
    let artwork: URL?
    let title: String
    let subtitle: String?
    
    var body: some View {
        HStack {
            artworkView
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    var artworkView: some View {
        ZStack {
            Artwork(
                url: artwork,
                cornerRadius: 5
            )
//            if let activity = model.activity {
//                Color.black.opacity(0.4)
//                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
//                MediaActivityIndicator(state: activity)
//            }
        }
        .frame(width: 48, height: 48)
    }
}

struct SearchItemView: View {
    let item: APISearchResultItem
//    let artwork: URL?
//    let title: String
//    let subtitle: String?
    let onAdd: () -> Void

    var body: some View {
        HStack {
            switch item {
            case let .simRadio(item):
                SearchItemLabel(
                    artwork: item.artwork,
                    title: item.title,
                    subtitle: nil
                )
            case let .realStation(item):
                SearchItemLabel(
                    artwork: item.artwork,
                    title: item.name,
                    subtitle: nil
                )
            }
        }
        .padding(.vertical, 4)
    }


}

#Preview {
    SearchScreen()
}
