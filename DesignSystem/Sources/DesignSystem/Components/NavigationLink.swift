//
//  NavigationLink.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.11.2025.
//

import SwiftUI

public struct NavigationLink: View {
    let title: String
    let systemImage: String

    public init(title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: 11) {
            Image(systemName: systemImage)
                .font(.system(size: 22))
                .frame(width: 36)
                .foregroundStyle(Color.brand)
            Text(title)
                .font(.system(size: 20))
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.palette.stroke))
        }
        .frame(height: 52)
        .contentShape(.rect)
    }
}

#Preview {
    NavigationLink(title: "Sim Radio", systemImage: "gamecontroller")
}
