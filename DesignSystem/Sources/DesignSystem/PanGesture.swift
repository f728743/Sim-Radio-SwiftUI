//
//  PanGesture.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 17.11.2024.
//

import SwiftUI

public struct PanGesture: UIGestureRecognizerRepresentable {
    var onChange: (Value) -> Void
    var onEnd: (Value) -> Void

    public init(
        onChange: @escaping (Value) -> Void,
        onEnd: @escaping (Value) -> Void
    ) {
        self.onChange = onChange
        self.onEnd = onEnd
    }

    public func makeUIGestureRecognizer(context _: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        return gesture
    }

    public func updateUIGestureRecognizer(_: UIPanGestureRecognizer, context _: Context) {}

    public func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context _: Context) {
        let state = recognizer.state
        let translation = recognizer.translation(in: recognizer.view).toSize()
        let velocity = recognizer.velocity(in: recognizer.view).toSize()
        let value = Value(translation: translation, velocity: velocity)

        if state == .began || state == .changed {
            onChange(value)
        } else {
            onEnd(value)
        }
    }

    public struct Value {
        public var translation: CGSize
        public var velocity: CGSize
    }
}

extension CGPoint {
    func toSize() -> CGSize {
        CGSize(width: x, height: y)
    }
}
