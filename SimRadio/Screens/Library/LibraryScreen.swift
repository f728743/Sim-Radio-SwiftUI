//
//  LibraryScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 06.04.2025.
//

import DesignSystem
import Kingfisher
import SwiftUI

struct LibraryScreen: View {
    @Environment(Router.self) var router
    @Environment(Dependencies.self) var dependencies
    @State private var viewModel = LibraryScreenViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                let rowSeparatorLeading: CGFloat = 60
                NavigationLink(title: "Sim Radio", systemImage: "gamecontroller")
                    .onTapGesture {
                        router.navigateToSimRadio()
                    }
                    .padding(.horizontal, ViewConst.screenPaddings)
                Divider()
                    .padding(.leading, rowSeparatorLeading)

                NavigationLink(title: "Radio", systemImage: "dot.radiowaves.left.and.right")
                    .onTapGesture {
                        router.navigateToRadio()
                    }
                    .padding(.horizontal, ViewConst.screenPaddings)
                Divider()
                    .padding(.leading, rowSeparatorLeading)

                NavigationLink(title: "Downloaded", systemImage: "arrow.down.circle")
                    .onTapGesture {
                        router.navigateToDownloaded()
                    }
                    .padding(.horizontal, ViewConst.screenPaddings)
                Divider()
                    .padding(.leading, rowSeparatorLeading)

                recentlyAdded
                    .padding(.horizontal, ViewConst.screenPaddings - LibraryItemsGrid.itemPadding)
                    .padding(.top, 26)
            }
        }
        .contentMargins(.bottom, ViewConst.screenPaddings, for: .scrollContent)
        .navigationTitle("Library")
        .toolbarTitleDisplayMode(.inlineLarge)
        .task {
            viewModel.mediaState = dependencies.mediaState
            viewModel.player = dependencies.mediaPlayer
        }
    }
}

private extension LibraryScreen {
    var recentlyAdded: some View {
        LibraryItemsGrid(
            title: "Recently Added",
            items: viewModel.recentlyAdded,
            onEvent: { event in
                switch event {
                case let .tap(item):
                    switch item {
                    case let .mediaList(list):
                        router.navigateToMedia(items: list.items, listMeta: list.meta)
                    case let .mediaItem(item):
                        router.navigateToMedia(item: item)
                    }
                case let .selected(menuItem, item):
                    viewModel.onSelect(menuItem, of: item)
                }

            },
            contextMenu: viewModel.contextMenu
        )
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub
    LibraryScreen()
        .withRouter()
        .environment(dependencies)
        .environment(playerController)
}
