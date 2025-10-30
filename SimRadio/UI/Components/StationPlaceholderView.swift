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

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        backgroundView
            .aspectRatio(1.0, contentMode: .fit)
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
        neewShadow ? Color(.sRGBLinear, white: 0, opacity: 0.33) : .clear
    }

    var neewShadow: Bool {
        name != nil
    }

    @ViewBuilder
    var backgroundView: some View {
        if let name {
            LinearGradient(
                colors: name.textColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.clear
        }
    }
}

extension String {
    var textColors: [Color] {
        let hash = SHA256.hash(data: Data(utf8))
        let bytes = Array(hash)
        let index = Int(bytes.first ?? 0) % Color.spectrum.count

        let offset = Int(bytes.dropFirst().first ?? 0) % 5 - 2
        var secondIndex = index + offset
        if secondIndex < 0 {
            secondIndex = Color.spectrum.count + secondIndex
        } else if secondIndex >= Color.spectrum.count {
            secondIndex = secondIndex % Color.spectrum.count
        }

        let first = Color.spectrum[index]
        let second = Color.spectrum[secondIndex]
        return [first, second]
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
        StationPlaceholderView(name: "Radio Rock")
            .frame(width: 40)
        StationPlaceholderView(name: "Radio Rock")
            .frame(width: 100)
        StationPlaceholderView(name: "Classical Music")
            .frame(height: 100)
    }
    .padding()
    .background(Color(.systemBackground))
}
