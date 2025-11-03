//
//  Media.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 29.03.2025.
//

import Foundation

struct Media: Identifiable, Hashable, Equatable {
    let id: MediaID
    let meta: MediaMeta
}

enum MediaID: Hashable {
    case simRadio(SimStation.ID)
    case realRadio(RealStation.ID)
}

extension MediaID {
    var isSimRadio: Bool {
        switch self {
        case .simRadio: true
        default: false
        }
    }

    var isRealRadio: Bool {
        switch self {
        case .realRadio: true
        default: false
        }
    }

    var asString: String {
        switch self {
        case let .simRadio(id):
            "simRadio.\(id)"
        case let .realRadio(id):
            "realRadio.\(id)"
        }
    }
}
