//
//  DownloadedScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.01.2025.
//

import SwiftUI

struct DownloadedScreen: View {
    @Environment(Dependencies.self) var dependencies
    @State private var viewModel = DownloadedScreenViewModel()

    var body: some View {
        content
            .navigationTitle("Downloaded")
            .task {
                viewModel.mediaState = dependencies.mediaState
            }
    }
}

private extension DownloadedScreen {
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
            imageSystemName: "icloud.and.arrow.down",
            title: "Download Sim Stations to Listen to Offline",
            description: "Downloaded Stations will appear here."
        )
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    DownloadedScreen()
        .environment(dependencies)
}
