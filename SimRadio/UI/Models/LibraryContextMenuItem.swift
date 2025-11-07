//
//  LibraryContextMenuItem.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 07.11.2025.
//

import SwiftUI

enum LibraryContextMenuItem: Hashable {
    case play
    case delete
    case download
    case divider
}

extension LibraryContextMenuItem {
    var systemImage: String {
        switch self {
        case .play:
            "play"
        case .delete:
            "trash"
        case .download:
            "arrow.down"
        case .divider:
            ""
        }
    }

    var label: String {
        switch self {
        case .play: "Play"
        case .delete: "Delete"
        case .download: "Download"
        case .divider: ""
        }
    }

    var role: ButtonRole? {
        if case .delete = self {
            return .destructive
        }
        return nil
    }
}
