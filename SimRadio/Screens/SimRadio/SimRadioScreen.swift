//
//  SimRadioScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 24.09.2025.
//

import SwiftUI

struct SimRadioScreen: View {
    @Environment(Dependencies.self) var dependencies
    @State private var viewModel = SimRadioScreenViewModel()

    var body: some View {
        content
            .navigationTitle("Sim Radio")
            .task {
                viewModel.mediaState = dependencies.mediaState
            }
    }
}

private extension SimRadioScreen {
    @ViewBuilder
    var content: some View {
        if viewModel.items.isEmpty {
            empty
                .padding(.horizontal, 40)
                .offset(y: -ViewConst.compactNowPlayingHeight)
        } else {
            MediaListScreen(items: viewModel.items)
                .id(viewModel.items.count)
        }
    }

    var empty: some View {
        EmptyScreenView(
            imageSystemName: "gamecontroller",
            title: "No sim radio stations added",
            description: "Add sim radio stations to come back to them later and they'll show up here."
        )
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    RadioScreen()
        .environment(dependencies)
}
