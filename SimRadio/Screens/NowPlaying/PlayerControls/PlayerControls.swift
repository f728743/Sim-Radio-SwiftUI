//
//  PlayerControls.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 01.12.2024.
//

import DesignSystem
import MediaLibrary
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
                    HStack(spacing: 4) {
                        trackInfo
                        options
                    }

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
                let title = model.display.title.isEmpty ? " " : model.display.title
                let subtitle = model.display.subtitle.isEmpty ? " " : model.display.subtitle
                MarqueeText(title, config: cfg)
                    .transformEffect(.identity)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(palette.opaque))
                    .id(model.display)
                MarqueeText(subtitle, config: cfg)
                    .transformEffect(.identity)
                    .foregroundStyle(Color(palette.opaque))
                    .blendMode(.overlay)
                    .id(model.display)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    var options: some View {
        if !model.modes.isEmpty {
            Menu {
                Picker(
                    selection: Binding(
                        get: { model.selectedMode },
                        set: { newValue in
                            model.selectedMode = newValue
                            model.onSelectMode(newValue)
                        }
                    ),
                    label: EmptyView()
                ) {
                    ForEach(model.modes) {
                        if let systemImage = $0.id.systemImage {
                            Label($0.title, systemImage: systemImage)
                                .tag($0.id as MediaPlaybackMode.ID?)
                        } else {
                            Text($0.title)
                                .tag($0.id as MediaPlaybackMode.ID?)
                        }
                    }
                }
            } label: {
                optionsMenuLabel
            }
            // TODO: set dark theme menu without  .preferredColorScheme(.dark)
            .padding(.trailing, ViewConst.playerCardPaddings)
        }
    }

    var optionsMenuLabel: some View {
        ZStack {
            Image(systemName: "ellipsis.circle.fill")
                .foregroundStyle(.clear, Color(palette.translucent))
                .blendMode(.overlay)
            Image(systemName: "ellipsis.circle.fill")
                .foregroundStyle(Color(palette.opaque), .clear)
        }
        .font(.system(size: 28))
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

extension MediaPlaybackMode.ID {
    var systemImage: String? {
        switch value {
        case "alternate_playback": "clock.arrow.trianglehead.2.counterclockwise.rotate.90"
        case "option_all": "checklist.checked"
        default: nil
        }
    }
}

#Preview {
    @Previewable @State var playerController = PlayerController()
    ZStack(alignment: .bottom) {
        PreviewBackground()
        PlayerControls()
            .frame(height: 400)
    }
    .environment(playerController)
}
