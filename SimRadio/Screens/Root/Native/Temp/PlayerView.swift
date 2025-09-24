//
//  PlayerView.swift
//  AppleMusicSheet
//
//  Created by Alexey Vorobyov on 25.09.2025.
//

import SwiftUI

struct PlayerView: View {
    var body: some View {
        GeometryReader {
            let size = $0.size
            /// Dynamic Spacing Using Available Height
            let spacing = size.height * 0.04

            /// Sizing it for more compact look
            VStack(spacing: spacing) {
                VStack(spacing: spacing) {
                    HStack(alignment: .center, spacing: 15) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Look What You Made Me do")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            Text("Taylor Swift")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button {} label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                                .padding(12)
                                .background {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .environment(\.colorScheme, .light)
                                }
                        }
                    }

                    /// Timing Indicator
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .light)
                        .frame(height: 5)
                        .padding(.top, spacing)

                    /// Timing Label View
                    HStack {
                        Text("0:00")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Spacer(minLength: 0)

                        Text("3:33")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                /// Moving it to Top
                .frame(height: size.height / 2.5, alignment: .top)

                /// Playback Controls
                HStack(spacing: size.width * 0.18) {
                    Button {} label: {
                        Image(systemName: "backward.fill")
                            /// Dynamic Sizing for Smaller to Larger iPhones
                            .font(size.height < 300 ? .title3 : .title)
                    }

                    /// Making Play/Pause Little Bigger
                    Button {} label: {
                        Image(systemName: "pause.fill")
                            /// Dynamic Sizing for Smaller to Larger iPhones
                            .font(size.height < 300 ? .largeTitle : .system(size: 50))
                    }

                    Button {} label: {
                        Image(systemName: "forward.fill")
                            /// Dynamic Sizing for Smaller to Larger iPhones
                            .font(size.height < 300 ? .title3 : .title)
                    }
                }
                .foregroundColor(.white)
                .frame(maxHeight: .infinity)

                /// Volume & Other Controls
                VStack(spacing: spacing) {
                    HStack(spacing: 15) {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.gray)

                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .light)
                            .frame(height: 5)

                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.gray)
                    }

                    HStack(alignment: .top, spacing: size.width * 0.18) {
                        Button {} label: {
                            Image(systemName: "quote.bubble")
                                .font(.title2)
                        }

                        VStack(spacing: 6) {
                            Button {} label: {
                                Image(systemName: "airpods.gen3")
                                    .font(.title2)
                            }

                            Text("iJustine's Airpods")
                                .font(.caption)
                        }

                        Button {} label: {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                        }
                    }
                    .foregroundColor(.white)
                    .blendMode(.overlay)
                    .padding(.top, spacing)
                }
                /// Moving it to bottom
                .frame(height: size.height / 2.5, alignment: .bottom)
            }
        }
    }
}
