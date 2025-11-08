//
//  MediaListSwipeButton.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 07.11.2025.
//

import SwiftUI

enum MediaListSwipeButton: Hashable {
    case download
    case pauseDownload
    case delete
}

extension MediaListSwipeButton {
    var systemImage: String {
        switch self {
        case .download:
            "arrow.down"
        case .pauseDownload:
            "pause.fill"
        case .delete:
            "minus.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .download: "Download"
        case .pauseDownload: "Pause"
        case .delete: "Delete"
        }
    }

    var color: Color {
        switch self {
        case .download: Color(.systemBlue)
        case .pauseDownload: Color(.systemGray)
        case .delete: Color(.systemRed)
        }
    }
}
