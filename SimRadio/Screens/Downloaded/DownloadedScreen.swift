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
        VStack(spacing: 0) {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 48))
                .foregroundStyle(Color(.palette.stroke))
            Text("Download Stations to Listen to Offline")
                .font(.system(size: 22, weight: .semibold))
                .padding(.top, 16)
            Text("Downloaded Stations will appear here.")
                .font(.system(size: 17, weight: .regular))
                .padding(.top, 8)
                .foregroundStyle(Color(.palette.textTertiary))
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    DownloadedScreen()
        .environment(dependencies)
}
