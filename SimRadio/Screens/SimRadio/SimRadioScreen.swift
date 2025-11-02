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
        VStack(spacing: 0) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 48))
                .foregroundStyle(Color(.palette.stroke))
            Text("No sim radio stations added")
                .font(.system(size: 22, weight: .semibold))
                .padding(.top, 16)
            Text("Add sim radio stations to come back to them later and they'll show up here.")
                .font(.system(size: 17, weight: .regular))
                .padding(.top, 8)
                .foregroundStyle(Color(.palette.textTertiary))
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    RadioScreen()
        .environment(dependencies)
}
