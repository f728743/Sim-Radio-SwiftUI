//
//  MediaActivityIndicator.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 02.06.2025.
//

import SwiftUI

enum MediaActivity {
    case paused
    case buffering
    case spectrum([Float])
}

struct MediaActivityIndicator: View {
    let state: MediaActivity

    var body: some View {
        AudioSpectrumView(
            size: .init(width: 16, height: 22),
            spectrum: spectrumValues,
        )
    }

    var spectrumValues: [Float] {
        switch state {
        case let .spectrum(values): values
        default: .init(repeating: 0, count: 5)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack {
        MediaActivityIndicator(state: .paused)
        MediaActivityIndicator(state: .buffering)
        MediaActivityIndicator(state: .spectrum([0.3, 0.8, 0.4, 0.6, 0.0]))
    }
    .padding(10)
    .background(Color.gray)
}
