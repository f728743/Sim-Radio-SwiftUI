//
//  AppFont.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.12.2024.
//

import SwiftUI

public enum AppFont {
    public static let timingIndicator: Font = .system(size: 12, weight: .semibold)
    static let miniPlayerTitle: Font = .system(size: 15, weight: .medium)
    public static let button: Font = .system(size: 17, weight: .semibold)
    public static let mediaListHeaderSubtitle: Font = .system(size: 20)
    public static let mediaListItemSubtitle: Font = .system(size: 13)
    public static let mediaListItemFooter: Font = .system(size: 15)
    static let tabbar: Font = .system(size: 10)
}

public extension Font {
    static var appFont: AppFont.Type {
        AppFont.self
    }
}
