//
//  AudioSpectrumView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.06.2025.
//

import SwiftUI

struct AudioSpectrumView: View {
    let size: CGSize
    let spectrum: [Float]
    let color: Color

    var body: some View {
        let barWidth: CGFloat = spectrum.count > 0
            ? size.width / CGFloat(spectrum.count) : 0
        HStack(alignment: .center, spacing: barWidth - barWidth * 3 / 4) {
            ForEach(Array(spectrum.enumerated()), id: \.offset) { _, value in
                BarView(value: value)
                    .fill(color)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct BarView: Shape {
    let value: Float

    func path(in rect: CGRect) -> Path {
        let cornerRadius = rect.width / 2
        let height = max(rect.width, CGFloat(value.clamped(to: 0 ... 1)) * rect.height)
        let lineRect = CGRect(
            x: 0,
            y: 0 + (rect.height - height) / 2,
            width: rect.width,
            height: height
        )
        return Path(roundedRect: lineRect, cornerRadius: cornerRadius)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    AudioSpectrumView(
        size: .init(width: 160, height: 160),
        spectrum: [0.3, 0.8, 0.4, 0.6, 0.0],
        color: .red
    )
    .background(Color.gray.tertiary)
}
