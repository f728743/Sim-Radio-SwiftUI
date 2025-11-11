//
//  Palette.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 04.12.2024.
//

import SwiftUI
import UIKit

public extension Color {
    static let spectrum: [Color] = [
        Color("AppCoral", bundle: .module),
        Color("AppOrange", bundle: .module),
        Color("AppYellow", bundle: .module),
        Color("AppLime", bundle: .module),
        Color("AppMint", bundle: .module),
        Color("AppSky", bundle: .module),
        Color("AppIndigo", bundle: .module),
        Color("AppPurple", bundle: .module),
        Color("AppPink", bundle: .module)
    ]

    static let iconPrimary: Color = .primary
    static let iconSecondary: Color = .graySecondary

    static let textPrimary: Color = .primary
    static let textAccent: Color = .brand
    static let brand: Color = .init("Brand", bundle: .module)
    static let graySecondary: Color = .init("GraySecondary", bundle: .module)
}

extension Color {
    func adjust(
        hue: CGFloat = 0,
        saturation: CGFloat = 0,
        brightness: CGFloat = 0,
        opacity: CGFloat = 0
    ) -> Color {
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return self
        }
        return Color(
            hue: (h + hue).clamped(to: 0 ... 1),
            saturation: (s + saturation).clamped(to: 0 ... 1),
            brightness: (b + brightness).clamped(to: 0 ... 1),
            opacity: (a + opacity).clamped(to: 0 ... 1)
        )
    }
}

public enum Palette {
    public enum PlayerCard {}
}

public extension Palette {
    static var playerCard: Palette.PlayerCard.Type {
        Palette.PlayerCard.self
    }

    static let artworkBorder: UIColor = .dynamic(
        light: .black.withAlphaComponent(0.2),
        dark: .white.withAlphaComponent(0.2)
    )

    static let artworkBackground: UIColor = .dynamic(
        light: UIColor(r: 233, g: 233, b: 234, a: 255),
        dark: UIColor(r: 39, g: 39, b: 41, a: 255)
    )

    static let buttonBackground: UIColor = .dynamic(
        light: UIColor(r: 238, g: 238, b: 239, a: 255),
        dark: UIColor(r: 28, g: 28, b: 31, a: 255)
    )

    static let textSecondary: UIColor = .dynamic(
        light: UIColor(r: 138, g: 138, b: 142, a: 255),
        dark: UIColor(r: 141, g: 141, b: 147, a: 255)
    )

    static let textTertiary: UIColor = .dynamic(
        light: UIColor(r: 127, g: 127, b: 127, a: 255),
        dark: UIColor(r: 128, g: 128, b: 128, a: 255)
    )

    static let stroke: UIColor = .dynamic(
        light: UIColor(r: 197, g: 197, b: 199, a: 255),
        dark: UIColor(r: 70, g: 69, b: 73, a: 255)
    )
}

public extension Palette.PlayerCard {
    static let opaque: UIColor = .white
    static let translucent: UIColor = .init(white: 0.784, alpha: 0.816)
    static let artworkBackground: UIColor = .dynamic(
        light: Palette.platinum,
        dark: Palette.taupeGray
    )
}

private extension Palette {
    static let taupeGray = UIColor(red: 0.525, green: 0.525, blue: 0.545, alpha: 1)
    static let platinum = UIColor(red: 0.898, green: 0.898, blue: 0.913, alpha: 1)
    static let stackedDarkBackground = UIColor(red: 0.0784, green: 0.0784, blue: 0.086, alpha: 1)
}

public extension UIColor {
    static var palette: Palette.Type {
        Palette.self
    }
}
