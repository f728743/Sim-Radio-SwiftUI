//
//  EmptyScreenView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.11.2025.
//

import SwiftUI

struct EmptyScreenView: View {
    let imageSystemName: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: imageSystemName)
                .font(.system(size: 48))
                .foregroundStyle(Color(.palette.stroke))
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .padding(.top, 16)
            Text(description)
                .font(.system(size: 17, weight: .regular))
                .padding(.top, 8)
                .foregroundStyle(Color(.palette.textTertiary))
        }
        .multilineTextAlignment(.center)
    }
}
