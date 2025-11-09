//
//  LiveIndicator.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 16.05.2025.
//

import DesignSystem
import SwiftUI

struct LiveIndicator: View {
    var palette: Palette.PlayerCard.Type {
        UIColor.palette.playerCard.self
    }

    var body: some View {
        ZStack {
            Capsule()
                .frame(height: 7)
                .mask(fadeMask)
                .foregroundStyle(Color(palette.translucent))
            Text("LIVE")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(palette.opaque))
        }
    }

    var fadeMask: some View {
        HStack(spacing: 0) {
            Color.black
            LinearGradient(
                gradient: Gradient(colors: [.black, .black.opacity(0), .black.opacity(0), .black]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 100)
            Color.black
        }
    }
}

#Preview {
    ZStack {
        PreviewBackground()
        LiveIndicator()
            .padding(.horizontal)
            .blendMode(.overlay)
    }
}
