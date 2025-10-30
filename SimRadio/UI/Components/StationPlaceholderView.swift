//
//  StationPlaceholderView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 29.10.2025.
//

import CryptoKit
import SwiftUI

struct StationPlaceholderView: View {
    let name: String?
    @State var size: CGFloat = .zero

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        backgroundView
            .aspectRatio(1.0, contentMode: .fit)
            .onGeometryChange(
                for: CGFloat.self,
                of: { $0.size.width },
                action: { size = $0 }
            )
            .overlay {
                Image(.radio)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(0.7)
                    .foregroundStyle(foregroundColor)
                    .shadow(color: shadowColor, radius: 2, y: 1)
            }
    }
}

private extension StationPlaceholderView {
    var foregroundColor: Color {
        name == nil ? .iconSecondary : .white
    }

    var shadowColor: Color {
        useGradient ? Color(.sRGBLinear, white: 0, opacity: 0.33) : .clear
    }

    var useGradient: Bool {
        size > 50 && name != nil
    }

    var color: Color {
        guard let name else { return .clear }
        let hash = SHA256.hash(data: Data(name.utf8))
        let bytes = Array(hash)
        let index = Int(bytes.first ?? 0) % Color.spectrum.count
        return Color.spectrum[index]
    }

    @ViewBuilder
    var backgroundView: some View {
        if useGradient {
            LinearGradient(
                colors: [
                    color.adjust(brightness: 0.15),
                    color.adjust(brightness: -0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            color
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            ForEach(0 ... Color.spectrum.count - 1, id: \.self) { i in
                Color.spectrum[i]
            }
        }
        .frame(height: 90)
        StationPlaceholderView(name: "Classic FM")
            .frame(width: 40)
            .background(Color.red)
        StationPlaceholderView(name: "Classic FM")
            .frame(width: 100)
        StationPlaceholderView(name: "Rock Nation")
            .frame(height: 100)
    }
    .padding()
    .background(Color(.systemBackground))
}
