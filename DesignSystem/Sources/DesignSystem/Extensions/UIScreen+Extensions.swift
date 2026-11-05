//
//  UIScreen+Extensions.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 20.11.2024.
//

import SwiftUI
import UIKit

public extension UIScreen {
    var deviceCornerRadius: CGFloat {
        value(forKey: "_displayCornerRadius") as? CGFloat ?? 0
    }
}

public extension View {
    func onWindowScreenChange(_ action: @escaping @MainActor (UIScreen) -> Void) -> some View {
        background {
            WindowScreenReader(onChange: action)
                .frame(width: 0, height: 0)
        }
    }
}

private struct WindowScreenReader: UIViewRepresentable {
    var onChange: @MainActor (UIScreen) -> Void

    func makeUIView(context _: Context) -> ScreenView {
        let view = ScreenView()
        view.onChange = onChange
        return view
    }

    func updateUIView(_ uiView: ScreenView, context _: Context) {
        uiView.onChange = onChange
    }

    final class ScreenView: UIView {
        var onChange: (@MainActor (UIScreen) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let screen = window?.windowScene?.screen else { return }
            // Avoid changing SwiftUI state during a view update.
            DispatchQueue.main.async { [weak self] in
                guard let self, window?.windowScene?.screen === screen else { return }
                onChange?(screen)
            }
        }
    }
}
