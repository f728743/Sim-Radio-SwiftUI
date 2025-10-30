//
//  NowPlayingBackground.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.01.2025.
//

import SwiftUI

struct NowPlayingBackground: View {
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
        ViewConst.compactNowPlayingHeight / 2
    }
}

#Preview {
    NowPlayingBackground(
        colors: [],
        expanded: false,
        isFullExpanded: false
    )
}
