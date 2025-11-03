//
//  LibraryScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 06.04.2025.
//

import Kingfisher
import SwiftUI

struct LibraryScreen: View {
    @Environment(Router.self) var router
    @Environment(Dependencies.self) var dependencies
    @State private var viewModel = LibraryScreenViewModel()

    var body: some View {
        List {
            navigationLink(title: "Sim Radio", icon: "gamecontroller")
                .listRowInsets(.init(top: 0, leading: 23, bottom: 0, trailing: 22))
                .listSectionSeparator(.hidden, edges: .top)
                .onTapGesture {
                    router.navigateToSimRadio()
                }

            navigationLink(title: "Radio", icon: "dot.radiowaves.left.and.right")
                .listRowInsets(.init(top: 0, leading: 23, bottom: 0, trailing: 22))
                .onTapGesture {
                    router.navigateToRadio()
                }

            navigationLink(title: "Downloaded", icon: "arrow.down.circle")
                .listRowInsets(.init(top: 0, leading: 23, bottom: 0, trailing: 22))
                .onTapGesture {
                    router.navigateToDownloaded()
                }

            recentlyAdded
                .listRowInsets(.init(top: 25, leading: 20, bottom: 0, trailing: 20))
                .listSectionSeparator(.hidden, edges: .bottom)
        }
        .listStyle(.plain)
        .navigationTitle("Library")
        .toolbarTitleDisplayMode(.inlineLarge)
        .task {
            viewModel.mediaState = dependencies.mediaState
        }
    }
}

private extension LibraryScreen {
    var recentlyAdded: some View {
        VStack(spacing: 13) {
            Text("Recently Added")
                .font(.system(size: 22, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(viewModel.recentlyAdded) { item in
                    RecentlyAddedItem(label: item.label)
                        .onTapGesture {
                            switch item {
                            case let .mediaList(list):
                                router.navigateToMedia(items: list.items, listMeta: list.meta)
                            case let .mediaItem(item):
                                router.navigateToMedia(item: item)
                            }
//                            router.navigateToMedia(items: item.items, listMeta: item.meta)
                        }
                }
            }
        }
    }

    func navigationLink(title: String, icon: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .frame(width: 36)
                .foregroundStyle(Color(.palette.brand))
            Text(title)
                .font(.system(size: 20))
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.palette.stroke))
        }
        .frame(height: 48)
        .contentShape(.rect)
    }
}

private struct RecentlyAddedItem: View {
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

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub
    LibraryScreen()
        .withRouter()
        .environment(dependencies)
        .environment(playerController)
}
