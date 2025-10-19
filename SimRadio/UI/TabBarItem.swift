//
//  TabBarItem.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.01.2025.
//

import SwiftUI

enum TabBarItem: Hashable, CaseIterable {
    case library
    case radio
    case search
}

extension TabBarItem {
    var title: String {
        switch self {
        case .library: "Library"
        case .radio: "Radio"
        case .search: "Search"
        }
    }

    var image: Image {
        switch self {
//        case .home: Image(_internalSystemName: "home.fill")
        case .library: Image(systemName: "rectangle.stack.badge.play")
        case .radio: Image(systemName: "dot.radiowaves.left.and.right")
        case .search: Image(systemName: "magnifyingglass")
        }
    }

    var role: TabRole? {
        switch self {
        case .search: .search
        default: nil
        }
    }
}
