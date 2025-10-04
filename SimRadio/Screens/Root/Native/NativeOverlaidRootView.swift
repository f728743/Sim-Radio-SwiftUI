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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NativeRootTabView()
            .tabBarMinimizeBehavior(.onScrollDown)
            .tabViewBottomAccessory {
                CompactNowPlaying(
                    mode: .small,
                    expanded: $expandSheet,
                    animationNamespace: animationNamespace
                )
                .onGeometryChange(
                    for: CGRect.self,
                    of: { $0.frame(in: .global) },
                    action: {
                        nowPlayingFrame = $0
                    }
                )
            }
            .overlay {
                ExpandableNowPlaying(
                    show: .constant(true),
                    expanded: $expandSheet,
                    mode: .overlay(collapsedFrame: nowPlayingFrame)
                )
                // Hack to fix the status bar color not updating correctly in iOS 26
                .toolbarColorScheme(colorScheme, for: .navigationBar)
            }
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
