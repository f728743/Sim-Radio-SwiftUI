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
        List {
            NavigationLink(title: "All Sim Stations", systemImage: "play.square.stack")
                .listRowInsets(.init(top: 0, leading: 23, bottom: 0, trailing: 22))
                .listSectionSeparator(.hidden, edges: .top)
                .onTapGesture {
                    router.navigateToSimRadioAllStations()
                }

            simSeries
                .listRowInsets(.init(top: 25, leading: 20, bottom: 0, trailing: 20))
                .listSectionSeparator(.hidden, edges: .bottom)
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
            }
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
