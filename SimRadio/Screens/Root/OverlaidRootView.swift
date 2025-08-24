//
//  OverlaidRootView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 17.11.2024.
//

import SwiftUI

struct OverlaidRootView: View {
    @State private var nowPlayingExpandProgress: CGFloat = .zero
    @State private var showOverlayingNowPlayng: Bool = false
    @State private var expandedNowPlaying: Bool = false
    @State private var showNowPlayingReplacement: Bool = false
    @Environment(PlayerController.self) var playerController
    @Environment(\.scenePhase) private var scenePhase
    @State private var expandWhenGoToBackground: Bool?

    var body: some View {
        ZStack(alignment: .bottom) {
            RootView()
            CompactNowPlayingReplacement(expanded: .constant(false))
                .opacity(showNowPlayingReplacement ? 1 : 0)
        }
        .universalOverlay(animation: .none, show: $showOverlayingNowPlayng) {
            ExpandableNowPlaying(
                show: $showOverlayingNowPlayng,
                expanded: $expandedNowPlaying
            )
            .environment(playerController)
            .onPreferenceChange(NowPlayingExpandProgressPreferenceKey.self) { [$nowPlayingExpandProgress] value in
                $nowPlayingExpandProgress.wrappedValue = value
            }
        }
        .onAppear {
            showOverlayingNowPlayng = true
        }
        .environment(\.nowPlayingExpandProgress, nowPlayingExpandProgress)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                expandWhenGoToBackground = expandedNowPlaying
                expandedNowPlaying = false
            case .inactive:
                if oldPhase == .background, expandWhenGoToBackground == true {
                    // Bugs occur with the safe area when restoring this parameter on return from background
                    // expandedNowPlaying = true
                }
            case .active:
                expandWhenGoToBackground = nil
            default:
                break
            }
        }
    }

    func showNowPlayng(replacement: Bool) {
        guard !expandedNowPlaying else { return }
        showOverlayingNowPlayng = !replacement
        showNowPlayingReplacement = replacement
    }
}

private struct CompactNowPlayingReplacement: View {
    @Namespace private var animationNamespaceStub
    @Binding var expanded: Bool
    var body: some View {
        ZStack(alignment: .top) {
            NowPlayingBackground(
                colors: [],
                expanded: false,
                isFullExpanded: false,
                canBeExpanded: false
            )
            CompactNowPlaying(
                expanded: $expanded,
                hideArtworkOnExpanded: false,
                animationNamespace: animationNamespaceStub
            )
        }
        .padding(.horizontal, 12)
        .padding(.bottom, ViewConst.compactNowPlayingHeight)
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub

    OverlayableRootView {
        OverlaidRootView()
            .environment(playerController)
            .environment(dependencies)
    }
}
