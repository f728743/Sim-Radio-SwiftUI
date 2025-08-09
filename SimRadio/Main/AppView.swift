//
//  AppView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 14.01.2025.
//

import SwiftUI

struct AppView: View {
    @State private var playerController: PlayerController?
    init(dependencies: Dependencies?) {
        if let playerController = dependencies?.playerController {
            _playerController = State(wrappedValue: playerController)
        }
    }

    var body: some View {
        OverlayableRootView {
            OverlaidRootView()
                .environment(playerController)
        }
    }
}
