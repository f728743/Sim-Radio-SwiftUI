//
//  AppFont.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.12.2024.
//

import SwiftUI

enum AppFont {
    static let timingIndicator: Font = .system(size: 12, weight: .semibold)
    static let miniPlayerTitle: Font = .system(size: 15, weight: .medium)
    static let button: Font = .system(size: 17, weight: .semibold)
    static let mediaListHeaderTitle: Font = .system(size: 20, weight: .semibold)
    static let mediaListHeaderSubtitle: Font = .system(size: 20)
    static let mediaListItemTitle: Font = .system(size: 16)
    static let mediaListItemSubtitle: Font = .system(size: 13)
    static let mediaListItemFooter: Font = .system(size: 15)
    static let tabbar: Font = .system(size: 10)
}

extension Font {
    static var appFont: AppFont.Type {
        AppFont.self
    }
}
