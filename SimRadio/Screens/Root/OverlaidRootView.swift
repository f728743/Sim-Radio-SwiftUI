//
//  OverlaidRootView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 24.09.2025.
//

import Foundation
import Observation
import SwiftUI

@available(iOS 26, *)
struct OverlaidRootView: View {
    @State private var containerWidth: CGFloat = 0
    @State private var expandSheet: Bool = false

    @State private var placement = PlayerPlacement()
    @Namespace private var animationNamespace
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RootTabView()
            .onGeometryChange(
                for: CGFloat.self,
                of: { $0.size.width },
                action: { containerWidth = $0 }
            )
            .tabViewBottomAccessory {
                CompactNowPlaying(
                    expanded: $expandSheet,
                    animationNamespace: animationNamespace,
                    containerWidth: containerWidth
                )
                .onGeometryChange(
                    for: CGRect.self,
                    of: { $0.frame(in: .global) },
                    action: {
                        placement.frame = $0
                    }
                )
            }
            .overlay {
                PlayerOverlay(
                    expanded: $expandSheet,
                    placement: placement
                )
                // Hack to fix the status bar color not updating correctly in iOS 26
                .toolbarColorScheme(colorScheme, for: .navigationBar)
            }
    }
}

@Observable
private final class PlayerPlacement {
    var frame: CGRect = .zero
}

private struct PlayerOverlay: View {
    @Binding var expanded: Bool
    let placement: PlayerPlacement

    var body: some View {
        ExpandableNowPlaying(
            show: .constant(true),
            expanded: $expanded,
            collapsedFrame: placement.frame
        )
    }
}

@available(iOS 26, *)
#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub

    OverlaidRootView()
        .environment(playerController)
        .environment(dependencies)
}
