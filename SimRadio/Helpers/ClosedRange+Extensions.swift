//
//  ClosedRange+Extensions.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 22.12.2024.
//

import Foundation

extension ClosedRange where Bound: AdditiveArithmetic {
    var distance: Bound {
        upperBound - lowerBound
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
