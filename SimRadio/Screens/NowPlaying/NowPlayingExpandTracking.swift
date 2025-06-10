//
//  NowPlayingExpandTracking.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.12.2024.
//

import SwiftUI

struct NowPlayingExpandProgressPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension EnvironmentValues {
    @Entry var nowPlayingExpandProgress = 0.0
}
