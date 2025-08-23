//
//  LibraryScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 06.04.2025.
//

import Kingfisher
import SwiftUI

struct LibraryScreen: View {
    @Environment(\.nowPlayingExpandProgress) var expandProgress
    @Environment(Router.self) var router
    @Environment(Dependencies.self) var dependencies
    @State private var viewModel = LibraryScreenViewModel()

    var body: some View {
        List {
            navigationLink(title: "Downloaded", icon: "arrow.down.circle")
                .listRowInsets(.init(top: 0, leading: 23, bottom: 0, trailing: 22))
                .listSectionSeparator(.hidden, edges: .top)
                .listRowBackground(Color(.palette.appBackground(expandProgress: expandProgress)))
                .onTapGesture {
                    router.navigateToDownloaded()
                }
            recentlyAdded
                .listRowInsets(.init(top: 25, leading: 20, bottom: 0, trailing: 20))
                .listSectionSeparator(.hidden, edges: .bottom)
                .listRowBackground(Color(.palette.appBackground(expandProgress: expandProgress)))
        }
        .background(Color(.palette.appBackground(expandProgress: expandProgress)))
        .listStyle(.plain)
        .navigationTitle("Library")
        .toolbar {
            Button { viewModel.testPopulate() }
                label: { ProfileToolbarButton() }
        }
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
                    RecentlyAddedItem(item: item)
                        .onTapGesture {
                            router.navigateToMedia(items: item.items, listMeta: item.meta)
                        }
                }
            }
        }
    }

    func navigationLink(title: String, icon: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 22))
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
    let item: MediaList

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Artwork(url: item.meta.artwork)
            VStack(alignment: .leading, spacing: 0) {
                Text(item.meta.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text(item.meta.subtitle ?? "")
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
