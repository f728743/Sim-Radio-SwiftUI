//
//  ViewConst.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.12.2024.
//

import Foundation
import SwiftUI

enum ViewConst {}

extension ViewConst {
    static let playerCardPaddings: CGFloat = 32
    static let screenPaddings: CGFloat = 20
    static let itemPeekAmount: CGFloat = 36
    static let compactNowPlayingHeight: CGFloat = 48

    static var safeAreaInsets: EdgeInsets {
        MainActor.assumeIsolated {
            EdgeInsets(UIApplication.keyWindow?.safeAreaInsets ?? .zero)
        }
    }

    static func itemWidth(
        forItemsPerScreen count: Int,
        spacing: CGFloat = 0,
        containerWidth: CGFloat
    ) -> CGFloat {
        let totalSpacing = spacing * CGFloat(count)
        let availableWidth = containerWidth - screenPaddings - itemPeekAmount - totalSpacing
        return availableWidth / CGFloat(count)
    }
}

extension EdgeInsets {
    init(_ insets: UIEdgeInsets) {
        self.init(
            top: insets.top,
            leading: insets.left,
            bottom: insets.bottom,
            trailing: insets.right
        )
    }
}

extension EdgeInsets {
    static let rowInsets: EdgeInsets = .init(
        top: 0,
        leading: ViewConst.screenPaddings,
        bottom: 0,
        trailing: ViewConst.screenPaddings
    )
}
