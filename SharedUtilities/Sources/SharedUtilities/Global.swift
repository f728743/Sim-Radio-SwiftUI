//
//  Global.swift
//  SharedUtilities
//
//  Created by Alexey Vorobyov on 09.11.2025.
//

import UIKit

@inline(__always)
public func lerp<V: BinaryFloatingPoint>(_ v0: V, _ v1: V, _ t: some BinaryFloatingPoint) -> V {
    v0 + V(t) * (v1 - v0)
}

public func lerp(_ v0: UIColor, _ v1: UIColor, _ t: some BinaryFloatingPoint) -> UIColor? {
    var red0: CGFloat = 0
    var green0: CGFloat = 0
    var blue0: CGFloat = 0
    var alpha0: CGFloat = 0
    var red1: CGFloat = 0
    var green1: CGFloat = 0
    var blue1: CGFloat = 0
    var alpha1: CGFloat = 0

    v0.getRed(&red0, green: &green0, blue: &blue0, alpha: &alpha0)
    v1.getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
    return UIColor(
        red: lerp(red0, red1, t),
        green: lerp(green0, green1, t),
        blue: lerp(blue0, blue1, t),
        alpha: lerp(alpha0, alpha1, t)
    )
}

public func prettyPrintTags(_ tags: String) -> String {
    tags
        .split(separator: ",")
        .map(\.capitalized)
        .joined(separator: ", ")
}
