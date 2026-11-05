//
//  NonRepeatingRandomizer.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 08.07.2025.
//

struct NonRepeatingRandomizer<T> {
    private var discardPile: [T] = []
    private var drawPool: [T] = []
    private let maxDiscardSize: Int

    init?(elements: [T], avoidRepeatsRatio ratio: Double) {
        guard !elements.isEmpty, ratio.isFinite else { return nil }
        maxDiscardSize = min(elements.count - 1, max(1, Int(min(1, max(0, ratio)) * Double(elements.count))))
        drawPool = elements
    }

    mutating func next(generator: inout RandomNumberGenerator) -> T {
        let index = Int.random(in: 0 ..< drawPool.count, using: &generator)
        let item = drawPool[index]

        discardPile.append(item)
        drawPool.remove(at: index)

        if discardPile.count > maxDiscardSize {
            drawPool.append(discardPile.removeFirst())
        }

        return item
    }
}
