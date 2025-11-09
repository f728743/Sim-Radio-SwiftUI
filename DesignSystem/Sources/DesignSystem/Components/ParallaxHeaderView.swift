//
//  ParallaxHeaderView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 24.10.2025.
//

import SwiftUI

public struct ParallaxHeaderView<T: View>: View {
    let content: () -> T
    let height: CGFloat

    public init(
        height: CGFloat,
        @ViewBuilder content: @escaping () -> T
    ) {
        self.height = height
        self.content = content
    }

    public var body: some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let contentHeight = height + (offset > 0 ? offset : 0)

            content()
                .frame(
                    width: geometry.size.width,
                    height: contentHeight
                )
                .offset(y: offset > 0 ? -offset : 0)
        }
        .frame(height: height)
    }
}
