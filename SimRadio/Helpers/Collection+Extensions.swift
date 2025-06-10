//
//  Collection+Extensions.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 27.11.2024.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
