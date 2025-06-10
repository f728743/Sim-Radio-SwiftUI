//
//  PlayerControls.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.12.2024.
//

import SwiftUI

struct PlayerControls: View {
    @Environment(PlayerController.self) var model
    @State private var volume: Double = 0.5

    var body: some View {
        GeometryReader {
            let size = $0.size
            let spacing = size.verticalSpacing
            VStack(spacing: 0) {
                VStack(spacing: spacing) {
                    trackInfo

                    timingIndicator(spacing: spacing)
                        .padding(.top, spacing)
                        .padding(.horizontal, ViewConst.playerCardPaddings)
                        .animation(.default, value: model.commandProfile)
                }
                .frame(height: size.height / 2.5, alignment: .top)
                PlayerButtons(spacing: size.width * 0.14)
                    .padding(.horizontal, ViewConst.playerCardPaddings)
                volume(playerSize: size)
                    .frame(height: size.height / 2.5, alignment: .bottom)
            }
        }
    }
}

private extension CGSize {
    var verticalSpacing: CGFloat { height * 0.04 }
}

private extension PlayerControls {
    var palette: Palette.PlayerCard.Type {
        UIColor.palette.playerCard.self
    }

    @ViewBuilder
    func timingIndicator(spacing: CGFloat) -> some View {
        if model.isLiveStream {
            LiveIndicator()
                .blendMode(.overlay)
                .padding(.bottom, 30)
                .frame(height: 60)
        } else {
            TimingIndicator(spacing: spacing)
                .padding(.horizontal, -ElasticSliderConfig.playbackProgress.growth)
        }
    }

    var trackInfo: some View {
        HStack(alignment: .center, spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                let fade = ViewConst.playerCardPaddings
                let cfg = MarqueeText.Config(leftFade: fade, rightFade: fade)
                MarqueeText(model.display.title, config: cfg)
                    .transformEffect(.identity)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(palette.opaque))
                    .id(model.display)
                MarqueeText(model.display.subtitle, config: cfg)
                    .transformEffect(.identity)
                    .foregroundStyle(Color(palette.opaque))
                    .blendMode(.overlay)
                    .id(model.display)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func volume(playerSize: CGSize) -> some View {
        VStack(spacing: playerSize.verticalSpacing) {
            VolumeSlider()
                .padding(.horizontal, 8)

            footer(width: playerSize.width)
                .padding(.top, playerSize.verticalSpacing)
                .padding(.horizontal, ViewConst.playerCardPaddings)
        }
    }

    func footer(width _: CGFloat) -> some View {
        AirPlayButton()
            .foregroundStyle(Color(palette.opaque))
            .blendMode(.overlay)
    }
}

#Preview {
    @Previewable @State var playerController = PlayerController()
    ZStack(alignment: .bottom) {
        PreviewBackground()
        PlayerControls()
            .frame(height: 400)
    }
    .onAppear {
//        playerController.mediaList = .mockGta5
    }
    .environment(playerController)
}
