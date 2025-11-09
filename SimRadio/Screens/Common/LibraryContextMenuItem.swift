//
//  LibraryContextMenuItem.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 07.11.2025.
//

import SwiftUI

public enum LibraryContextMenuItem: Hashable {
    case play
    case delete
    case download
}

public extension LibraryContextMenuItem {
    var systemImage: String {
        switch self {
        case .play:
            "play"
        case .delete:
            "trash"
        case .download:
            "arrow.down"
        }
    }

    var label: String {
        switch self {
        case .play: "Play"
        case .delete: "Delete"
        case .download: "Download"
        }
    }

    var role: ButtonRole? {
        if case .delete = self {
            return .destructive
        }
        return nil
    }
}
