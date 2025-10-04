//
//  CompactNowPlaying.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 20.11.2024.
//

import Kingfisher
import SwiftUI

struct CompactNowPlaying: View {
    enum Mode {
        case standard
        case small
    }

    @Environment(PlayerController.self) var model
    var mode: Mode = .standard
    @Binding var expanded: Bool
    var hideArtworkOnExpanded: Bool = true
    var animationNamespace: Namespace.ID
    @State var forwardAnimationTrigger: PlayerButtonTrigger = .one(bouncing: false)
    @State var viewWidth: CGFloat = .zero

    var body: some View {
        nowPlaying
            .frame(height: ViewConst.compactNowPlayingHeight)
            .contentShape(.rect)
            .transformEffect(.identity)
            .onTapGesture {
                withAnimation(.playerExpandAnimation) {
                    expanded = true
                }
            }
            .onGeometryChange(
                for: CGFloat.self,
                of: { $0.size.width },
                action: { viewWidth = $0 }
            )
    }
}

private extension CompactNowPlaying {
    @ViewBuilder
    func artwork(cornerRadius: CGFloat) -> some View {
        if !hideArtworkOnExpanded || !expanded {
            Artwork(
                url: model.display.artwork,
                cornerRadius: cornerRadius,
                background: Color(.systemGray4)
            )
            .matchedGeometryEffect(
                id: PlayerMatchedGeometry.artwork,
                in: animationNamespace
            )
        }
    }
    
    @ViewBuilder
    var nowPlaying: some View {
        if mode == .standard {
            standardNowPlaying
        } else {
            smallNowPlaying
        }
    }
    
    var standardNowPlaying: some View {
        HStack(spacing: 8) {
            artwork(cornerRadius: 7)
                .frame(width: 40, height: 40)

            Text(model.display.title)
                .lineLimit(1)
                .font(.appFont.miniPlayerTitle)
                .padding(.trailing, -18)

            Spacer(minLength: 0)

            PlayerButton(
                label: {
                    PlayerButtonLabel(type: model.playPauseButton, size: 20)
                },
                onEnded: {
                    model.onPlayPause()
                }
            )
            .playerButtonStyle(.miniPlayer)

            PlayerButton(
                label: {
                    PlayerButtonLabel(
                        type: model.forwardButton,
                        size: 30,
                        animationTrigger: forwardAnimationTrigger
                    )
                },
                onEnded: {
                    model.onForward()
                    DispatchQueue.main.async {
                        forwardAnimationTrigger.toggle(bouncing: true)
                    }
                }
            )
            .playerButtonStyle(.miniPlayer)
        }
        .padding(.horizontal, 8)
    }
    
    var inlinedBottomAccessory: Bool {
        let padding = UIScreen.size.width - viewWidth        
        return padding > 60
    }
    
    var smallNowPlaying: some View {
        HStack(spacing: 0) {
            artwork(cornerRadius: 5)
                .frame(width: 30, height: 30)
                VStack(spacing: 0) {
                
                let title = model.display.title
                // TODO: MarqueeText
//                    let fade = ViewConst.playerCardPaddings
//                    let cfg = MarqueeText.Config(leftFade: fade, rightFade: fade)
//                    let title = "#STUPiDFACEDD"
//                    MarqueeText(title, config: cfg)
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 13, weight: .semibold))
                    .id(model.display)
                let subtitle = model.display.subtitle
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(model.display)
            }
            .padding(.leading, 8)
            .geometryGroup()
            .lineLimit(1)
            
            Spacer(minLength: 0)

            HStack(spacing: 0) {
                PlayerButton(
                    label: {
                        PlayerButtonLabel(type: model.playPauseButton, size: 16)
                    },
                    onEnded: {
                        model.onPlayPause()
                    }
                )
                if !inlinedBottomAccessory {
                    PlayerButton(
                        label: {
                            PlayerButtonLabel(
                                type: model.forwardButton,
                                size: 26,
                                animationTrigger: forwardAnimationTrigger
                            )
                        },
                        onEnded: {
                            model.onForward()
                            DispatchQueue.main.async {
                                forwardAnimationTrigger.toggle(bouncing: true)
                            }
                        }
                    )
                    
                }
            }
            .playerButtonStyle(.miniPlayer)
        }
        .padding(.leading, 16)
        .padding(.trailing, 13)
    }
}

extension PlayerButtonConfig {
    static var miniPlayer: Self {
        Self(
            size: 44,
            tint: .init(Palette.PlayerCard.translucent.withAlphaComponent(0.3))
        )
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub

    CompactNowPlaying(
        expanded: .constant(false),
        animationNamespace: Namespace().wrappedValue
    )
    .background(.gray)
    .environment(playerController)
    .onAppear {
        playerController.mediaState = dependencies.mediaState
        playerController.player = dependencies.mediaPlayer
    }
}
