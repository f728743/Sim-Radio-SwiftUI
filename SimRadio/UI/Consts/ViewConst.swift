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
    static let tabbarHeight: CGFloat = safeAreaInsets.bottom + 92
    static var compactNowPlayingHeight: CGFloat {
        if #available(iOS 26.0, *) {
            48
        } else {
            56
        }
    }

    static var safeAreaInsets: EdgeInsets {
        MainActor.assumeIsolated {
            EdgeInsets(UIApplication.keyWindow?.safeAreaInsets ?? .zero)
        }
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
