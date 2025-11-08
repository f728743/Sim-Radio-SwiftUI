//
//  SimRadioScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 24.09.2025.
//

import SwiftUI

struct SimRadioScreen: View {
    @Environment(Router.self) var router
    @Environment(Dependencies.self) var dependencies
    @State private var viewModel = SimRadioScreenViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                let rowSeparatorLeading: CGFloat = 60
                NavigationLink(title: "All Sim Stations", systemImage: "play.square.stack")
                    .onTapGesture {
                        router.navigateToSimRadioAllStations()
                    }
                    .padding(.horizontal, ViewConst.screenPaddings)
                Divider()
                    .padding(.leading, rowSeparatorLeading)

                simSeries
                    .padding(.horizontal, ViewConst.screenPaddings - LibraryItemsGrid.itemPadding)
                    .padding(.top, 26)
            }
        }
        .listStyle(.plain)
        .contentMargins(.bottom, ViewConst.screenPaddings, for: .scrollContent)
        .navigationTitle("Sim Radio")
        .toolbarTitleDisplayMode(.inlineLarge)
        .task {
            viewModel.mediaState = dependencies.mediaState
        }
    }
}

private extension SimRadioScreen {
    var simSeries: some View {
        LibraryItemsGrid(
            title: "Sim Series",
            items: viewModel.simSeries,
            onTap: { item in
                switch item {
                case let .mediaList(list):
                    router.navigateToMedia(items: list.items, listMeta: list.meta)
                case let .mediaItem(item):
                    router.navigateToMedia(item: item)
                }
            },
            contextMenu: viewModel.contextMenu
        )
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub
    SimRadioScreen()
        .withRouter()
        .environment(dependencies)
        .environment(playerController)
}
