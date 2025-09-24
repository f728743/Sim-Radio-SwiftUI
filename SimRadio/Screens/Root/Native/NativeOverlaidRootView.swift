//
//  NativeOverlaidRootView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 24.09.2025.
//

import Foundation

import SwiftUI

@available(iOS 26, *)
struct NativeOverlaidRootView: View {
    @State private var expandSheet: Bool = false
    
    @State private var nowPlayingFrame: CGRect = .zero
    @Namespace private var animationNamespace

    var body: some View {
        NativeRootTabView()
            .tabBarMinimizeBehavior(.onScrollDown)
            .tabViewBottomAccessory {
                MiniPlayerView()
                    .onGeometryChange(
                        for: CGRect.self,
                        of: { $0.frame(in: .global)},
                        action: { nowPlayingFrame = $0 }
                    )
                    .onTapGesture {
                        withAnimation {
                            expandSheet.toggle()
                        }
                    }
            }
            .safeAreaInset(edge: .bottom) {
                customBottomSheet()
                    .opacity(0.4)
                    .onTapGesture {
                        expandSheet.toggle()
                    }
            }
            .overlay {
                if expandSheet {
                    ExpandedBottomSheet(expandSheet: $expandSheet, animation: animationNamespace)
                        /// Transition for more fluent Animation
                        .transition(.asymmetric(insertion: .identity, removal: .offset(y: -5)))
                }
            }
    }
    
    @ViewBuilder
    func customBottomSheet() -> some View {
        /// Animating Sheet Background (To Look Like It's Expanding From the Bottom)
        ZStack {
            if expandSheet {
                Rectangle()
                    .fill(.green)
            } else {
                Color.red
                    .overlay {
                        MusicInfo(expandSheet: $expandSheet, animation: animationNamespace)
                    }
                    .matchedGeometryEffect(id: PlayerMatchedGeometry.backgroundView, in: animationNamespace)
            }
        }
        .frame(height: nowPlayingFrame.height)
        .ignoresSafeArea()
        .padding(.leading, nowPlayingFrame.minX)
        .padding(.trailing, UIScreen.size.width - nowPlayingFrame.maxX)
        .padding(.bottom, UIScreen.size.height - nowPlayingFrame.maxY - ViewConst.safeAreaInsets.bottom)
    }
}

struct PlayerInfo: View {
    let size: CGSize

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: size.height / 4)
                .fill(.blue.gradient)
                .frame(width: size.width, height: size.height)

            VStack(alignment: .leading, spacing: 6) {
                Text("Some Apple Music Title")
                    .font(.callout)

                Text("Some Artist Name")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .lineLimit(1)
        }
    }
}

struct MiniPlayerView: View {
    var body: some View {
        HStack(spacing: 15) {
            PlayerInfo(size: .init(width: 30, height: 30))

            Spacer(minLength: 0)

            /// Action Buttons
            Button {} label: {
                Image(systemName: "play.fill")
                    .contentShape(.rect)
            }
            .padding(.trailing, 10)

            Button {} label: { Image(systemName: "forward.fill")
                .contentShape(.rect)
            }
        }
        .padding(.horizontal, 15)
    }
}

@available(iOS 26, *)
#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub

    NativeOverlaidRootView()
        .environment(playerController)
        .environment(dependencies)
}
