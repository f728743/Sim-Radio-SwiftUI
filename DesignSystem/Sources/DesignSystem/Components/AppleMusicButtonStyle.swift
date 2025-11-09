//
//  AppleMusicButtonStyle.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 12.01.2025.
//

import SwiftUI

public struct AppleMusicButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(Color(.palette.buttonBackground))
            .foregroundStyle(Color.brand)
            .clipShape(.capsule)
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

#Preview {
    Button {
        print("Play")
    }
    label: {
        Label("Play", systemImage: "play.fill")
    }
    .padding(.horizontal, 80)
    .buttonStyle(AppleMusicButtonStyle())
}
