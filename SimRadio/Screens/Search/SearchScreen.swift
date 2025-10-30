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
    @State private var isSearchPresented = false
    @State var firstTime = true

    var body: some View {
        content
            .navigationTitle("Search")
            .toolbarTitleDisplayMode(.inlineLarge)
            .searchable(
                text: $viewModel.searchText,
                isPresented: $isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: Text(promptText)
            )
            .task {
                viewModel.searchService = SearchService(apiService: dependencies.apiService)
                viewModel.mediaState = dependencies.mediaState
                viewModel.mediaPlayer = dependencies.mediaPlayer

                if firstTime { // TODO: remove
                    firstTime = false
                    viewModel.searchText = "soma"
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
        .background(Color(.systemBackground))
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                isSearchPresented = false
            }
        )
    }

    var promptText: String {
        viewModel.searchText.isEmpty ? "Search for radio stations..." : viewModel.searchText
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub

    SearchScreen()
        .withRouter()
        .environment(dependencies)
}
