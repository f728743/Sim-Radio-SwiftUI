//
//  DownloadedScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.01.2025.
//

import SwiftUI

struct DownloadedScreen: View {
//    @Environment(MediaState.self) var mediaState
    @Environment(Dependencies.self) var dependencies
    @State private var viewModel: DownloadedScreenViewModel

    init() {
        _viewModel = State(
            wrappedValue: DownloadedScreenViewModel()
        )
    }

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                empty
                    .padding(.horizontal, 40)
                    .offset(y: -ViewConst.compactNowPlayingHeight)
            } else {
                MediaListScreen(items: viewModel.items)
                    .id(viewModel.items.count)
            }
        }
        .task {
            viewModel.mediaState = dependencies.mediaState
        }
    }
}

extension DownloadedScreen {
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
