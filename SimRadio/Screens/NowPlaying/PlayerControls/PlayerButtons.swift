//
//  PlayerButtons.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 15.12.2024.
//

import SwiftUI

struct PlayerButtons: View {
    @Environment(PlayerController.self) var model
    let spacing: CGFloat
    let imageSize: CGFloat = 34
    @State var backwardAnimationTrigger: PlayerButtonTrigger = .one(bouncing: false)
    @State var forwardAnimationTrigger: PlayerButtonTrigger = .one(bouncing: false)

    var body: some View {
        HStack(spacing: spacing) {
            let isSwitchDisabled: Bool = !model.commandProfile.isSwitchTrackEnabled
            PlayerButton(
                label: {
                    PlayerButtonLabel(
                        type: model.backwardButton,
                        size: imageSize,
                        animationTrigger: backwardAnimationTrigger
                    )
                },
                onEnded: {
                    DispatchQueue.main.async {
                        backwardAnimationTrigger.toggle(bouncing: true)
                    }
                    model.onBackward()
                }
            )
            .disabled(isSwitchDisabled)
            .blendMode(isSwitchDisabled ? .overlay : .normal)

            PlayerButton(
                label: {
                    PlayerButtonLabel(type: model.playPauseButton, size: imageSize)
                },
                onEnded: {
                    model.onPlayPause()
                }
            )

            PlayerButton(
                label: {
                    PlayerButtonLabel(
                        type: model.forwardButton,
                        size: imageSize,
                        animationTrigger: forwardAnimationTrigger
                    )
                },
                onEnded: {
                    DispatchQueue.main.async {
                        forwardAnimationTrigger.toggle(bouncing: true)
                    }
                    model.onForward()
                }
            )
            .disabled(isSwitchDisabled)
            .blendMode(isSwitchDisabled ? .overlay : .normal)
        }
        .playerButtonStyle(.expandedPlayer)
    }
}

extension PlayerButtonConfig {
    static var expandedPlayer: Self {
        Self(
            labelColor: .init(Palette.PlayerCard.opaque),
            tint: .init(Palette.PlayerCard.translucent.withAlphaComponent(0.3)),
            pressedColor: .init(Palette.PlayerCard.opaque),
//            disabledColor: .init(Palette.PlayerCard.opaque)
        )
    }
}

#Preview {
    @Previewable @State var playerController = PlayerController()
    ZStack(alignment: .top) {
        PreviewBackground()
        VStack {
            Text("Header")
                .blendMode(.overlay)
            PlayerButtons(spacing: UIScreen.size.width * 0.14)
            Text("Footer")
                .blendMode(.overlay)
        }
        .foregroundStyle(Color(Palette.PlayerCard.opaque))
    }
    .environment(playerController)
}
