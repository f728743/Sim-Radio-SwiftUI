//
//  TabBarItem.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.01.2025.
//

import SwiftUI

enum TabBarItem: Hashable, CaseIterable {
    case home, search
}

extension TabBarItem {
    var title: String {
        switch self {
        case .home: "Home"
        case .search: "Search"
        }
    }

    var image: Image {
        switch self {
        case .home: Image("img_home")
        case .search: Image(systemName: "magnifyingglass")
        }
    }
}
