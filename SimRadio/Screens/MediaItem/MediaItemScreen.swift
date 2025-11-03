//
//  MediaItemScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 24.09.2025.
//

import SwiftUI

struct MediaItemScreen: View {
    @Environment(Dependencies.self) var dependencies
    @State private var viewModel: MediaItemScreenViewModel

    init(item: Media) {
        _viewModel = State(
            wrappedValue: MediaItemScreenViewModel(item: item)
        )
    }

    var body: some View {
        content
            .task {
                viewModel.mediaState = dependencies.mediaState
                viewModel.player = dependencies.mediaPlayer
            }
    }
}

private extension MediaItemScreen {
    @ViewBuilder
    var content: some View {
        Text("MediaItemScreen")
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub
    let item: Media = dependencies.mediaState.mediaList.first!.items.first!
    MediaItemScreen(item: item)
        .environment(dependencies)
        .environment(playerController)
}
