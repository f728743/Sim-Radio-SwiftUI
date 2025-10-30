//
//  PlayerButton.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 18.12.2024.
//

import Combine
import SwiftUI

struct PlayerButton<Content: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.playerButtonConfig) var config
    @State private var showCircle = false
    @State private var pressed = false
    private let onPressed: (() -> Void)?
    private let onPressing: ((TimeInterval) -> Void)?
    private let onEnded: (() -> Void)?
    private let label: Content?

    init(
        label: (() -> Content)? = nil,
        onPressed: (() -> Void)? = nil,
        onPressing: ((TimeInterval) -> Void)? = nil,
        onEnded: (() -> Void)? = nil
    ) {
        self.label = label?()
        self.onPressed = onPressed
        self.onPressing = onPressing
        self.onEnded = onEnded
    }

    var body: some View {
        label
            .scaleEffect(pressed ? 0.9 : 1)
            .frame(width: config.size, height: config.size)
            .foregroundStyle(color)
            .background(showCircle ? config.tint : .clear)
            .clipShape(Ellipse())
            .scaleEffect(pressed ? 0.85 : 1)
            .contentShape(.circle)
            .onPressGesture(
                interval: config.updateInterval,
                onPressed: {
                    guard isEnabled else { return }
                    withAnimation {
                        showCircle = true
                        pressed = true
                    }
                    onPressed?()
                },
                onPressing: { time in
                    guard isEnabled else { return }
                    onPressing?(time)
                },
                onEnded: {
                    guard isEnabled else { return }
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                        withAnimation {
                            showCircle = false
                        }
                    }
                    withAnimation {
                        pressed = false
                    }
                    onEnded?()
                }
            )
            .contentTransition(.symbolEffect(.replace))
    }
}

private extension PlayerButton {
    var color: Color {
        isEnabled ? showCircle ? config.pressedColor : config.labelColor : config.disabledColor
    }
}

extension View {
    func playerButtonStyle(_ config: PlayerButtonConfig) -> some View {
        environment(\.playerButtonConfig, config)
    }
}

extension EnvironmentValues {
    @Entry var playerButtonConfig = PlayerButtonConfig()
}

struct PlayerButtonConfig {
    let updateInterval: TimeInterval
    let size: CGFloat
    let labelColor: Color
    let tint: Color
    let pressedColor: Color
    let disabledColor: Color

    init(
        updateInterval: TimeInterval = 0.1,
        size: CGFloat = 68,
        labelColor: Color = .init(UIColor.label),
        tint: Color = .init(UIColor.tintColor),
        pressedColor: Color = .init(UIColor.secondaryLabel),
        disabledColor: Color = .iconSecondary
    ) {
        self.updateInterval = updateInterval
        self.size = size
        self.labelColor = labelColor
        self.tint = tint
        self.pressedColor = pressedColor
        self.disabledColor = disabledColor
    }
}

extension PlayerButton where Content == EmptyView {
    init(
        onPressed: (() -> Void)? = nil,
        onPressing: ((TimeInterval) -> Void)? = nil,
        onEnded: (() -> Void)? = nil
    ) {
        label = nil
        self.onPressed = onPressed
        self.onPressing = onPressing
        self.onEnded = onEnded
    }
}

#Preview {
    struct ButtonPreview: View {
        var body: some View {
            PlayerButton(
                label: {
                    Image(systemName: "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 34, height: 34)

                },
                onPressed: {
                    print("onPressed Button")
                },
                onPressing: { time in
                    print("onPressing \(time) Button")
                },
                onEnded: {
                    print("onEnded Button")
                }
            )
        }
    }

    return HStack(spacing: 60) {
        VStack {
            ButtonPreview()
                .disabled(true)
            Text("Disabled")
        }

        VStack {
            ButtonPreview()
            Text("Enabled")
        }
    }
}
