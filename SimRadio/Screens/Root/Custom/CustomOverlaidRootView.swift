//
//  CustomOverlaidRootView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 17.11.2024.
//

import SwiftUI

struct CustomOverlaidRootView: View {
    @State private var nowPlayingExpandProgress: CGFloat = .zero
    @State private var showOverlayingNowPlayng: Bool = false
    @State private var expandedNowPlaying: Bool = false
    @State private var showNowPlayingReplacement: Bool = false
    @Environment(PlayerController.self) var playerController
    @Environment(\.scenePhase) private var scenePhase
    @State private var expandWhenGoToBackground: Bool?

    var body: some View {
        ZStack(alignment: .bottom) {
            CustomRootTabView()
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

/// Resuable File
struct MusicInfo: View {
    @Binding var expandSheet: Bool
    var animation: Namespace.ID
    var body: some View {
        HStack(spacing: 0) {
            /// Adding Matched Geometry Effect (Hero Animation)
            ZStack {
                if !expandSheet {
                    GeometryReader {
                        let size = $0.size

                        Image("Artwork")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: expandSheet ? 15 : 5, style: .continuous))
                    }
                    .matchedGeometryEffect(id: PlayerMatchedGeometry.artwork, in: animation)
                }
            }
            .frame(width: 45, height: 45)

            Text("Look What You Made Me do")
                .fontWeight(.semibold)
                .lineLimit(1)
                .padding(.horizontal, 15)

            Spacer(minLength: 0)

            Button {} label: {
                Image(systemName: "pause.fill")
                    .font(.title2)
            }

            Button {} label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
            .padding(.leading, 25)
        }
        .foregroundColor(.primary)
        .padding(.horizontal)
        .padding(.bottom, 5)
        .frame(height: 70)
        .contentShape(Rectangle())
        .onTapGesture {
            /// Expanding Bottom Sheet
            withAnimation(.easeInOut(duration: 0.3)) {
                expandSheet = true
            }
        }
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub

    OverlayableRootView {
        CustomOverlaidRootView()
            .environment(playerController)
            .environment(dependencies)
    }
}
