//
//  RegularNowPlaying.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 20.11.2024.
//

import DesignSystem
import Kingfisher
import SwiftUI

struct RegularNowPlaying: View {
    @Environment(PlayerController.self) var model
    var expanded: Bool
    var size: CGSize
    var animationNamespace: Namespace.ID
    @State private var controlsVisible = false

    var body: some View {
        VStack(spacing: 12) {
            grip
                .blendMode(.overlay)
                .opacity(expanded ? 1 : 0)

            if expanded {
                artwork
                    .matchedGeometryEffect(
                        id: PlayerMatchedGeometry.artwork,
                        in: animationNamespace
                    )
                    .frame(height: size.width - Const.horizontalPadding * 2)
                    .padding(.vertical, size.height < 700 ? 10 : 30)
                    .padding(.horizontal, 25)

                GeometryReader { geometry in
                    PlayerControls()
                        .offset(y: controlsVisible ? 0 : geometry.size.height)
                        .allowsHitTesting(controlsVisible)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .padding(.top, ViewConst.safeAreaInsets.top)
        .padding(.bottom, ViewConst.safeAreaInsets.bottom)
        .task(id: expanded) {
            guard expanded else {
                controlsVisible = false
                return
            }
            // Establish the offscreen starting position after this view is recreated.
            await Task.yield()
            guard !Task.isCancelled else { return }
            withAnimation(.playerExpandAnimation) {
                controlsVisible = true
            }
        }
    }
}

private extension RegularNowPlaying {
    enum Const {
        static let horizontalPadding: CGFloat = 25
    }

    var grip: some View {
        Capsule()
            .fill(.white.secondary)
            .frame(width: 40, height: 5)
    }

    @ViewBuilder
    var artwork: some View {
        let small = !model.state.isPlaying
        ArtworkView(
            model.display.artwork,
            cornerRadius: expanded ? 10 : 7,
            background: Color(.palette.playerCard.artworkBackground)
        )
        .shadow(
            color: Color(.sRGBLinear, white: 0, opacity: small ? 0.13 : 0.33),
            radius: small ? 3 : 8,
            y: small ? 3 : 10
        )
        .padding(small ? 48 : 0)
        .animation(.smooth, value: model.state)
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub

    RegularNowPlaying(
        expanded: true,
        size: UIScreen.size,
        animationNamespace: Namespace().wrappedValue
    )
    .onAppear {
        playerController.mediaState = dependencies.mediaState
        playerController.player = dependencies.mediaPlayer
    }
    .background {
        ColorfulBackground(
            colors: playerController.colors.map { Color($0) }
        )
        .overlay(Color(UIColor(white: 0.4, alpha: 0.5)))
    }
    .ignoresSafeArea()
    .environment(playerController)
}
