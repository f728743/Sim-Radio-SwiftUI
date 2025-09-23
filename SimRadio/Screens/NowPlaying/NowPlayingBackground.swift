//
//  NowPlayingBackground.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.01.2025.
//

import SwiftUI

struct NowPlayingBackground: View {
    enum Mode {
        case standard
        case small
    }

    var mode: Mode = .standard
    let colors: [Color]
    let expanded: Bool
    let isFullExpanded: Bool
    var canBeExpanded: Bool = true

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.thickMaterial)
            if canBeExpanded {
                ColorfulBackground(colors: colors)
                    .overlay(Color(UIColor(white: 0.4, alpha: 0.4)))
                    .opacity(expanded ? 1 : 0)
            }
        }
        .clipShape(.rect(cornerRadius: playerCornerRadius))
        .frame(height: expanded ? nil : ViewConst.compactNowPlayingHeight)
        .shadow(
            color: .primary.opacity(needShadow ? 0.2 : 0),
            radius: 8,
            x: 0,
            y: 2
        )
    }
}

private extension NowPlayingBackground {
    var playerCornerRadius: CGFloat {
        expanded ? expandPlayerCornerRadius : collapsedPlayerCornerRadius
    }

    var expandPlayerCornerRadius: CGFloat {
        isFullExpanded ? 0 : UIScreen.deviceCornerRadius
    }

    var collapsedPlayerCornerRadius: CGFloat {
        mode == .standard ? 14 : ViewConst.compactNowPlayingHeight / 2
    }

    var needShadow: Bool {
        colorScheme == .light && mode == .standard
    }
}

#Preview {
    NowPlayingBackground(
        mode: .small,
        colors: [],
        expanded: false,
        isFullExpanded: false
    )
}
