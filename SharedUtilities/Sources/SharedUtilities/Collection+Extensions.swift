//
//  Collection+Extensions.swift
//  SharedUtilities
//
//  Created by Alexey Vorobyov on 27.11.2024.
//

import Foundation

public extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
