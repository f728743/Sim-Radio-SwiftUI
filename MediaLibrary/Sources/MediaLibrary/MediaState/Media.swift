//
//  Media.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 29.03.2025.
//

import Foundation

public struct Media: Identifiable, Hashable, Equatable, Sendable {
    public let id: MediaID
    public let meta: MediaMeta
}

public enum MediaID: Hashable, Sendable {
    case simRadio(SimStation.ID)
    case realRadio(RealStation.ID)
}

public extension MediaID {
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
