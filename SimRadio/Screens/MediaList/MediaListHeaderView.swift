//
//  MediaListHeaderView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 03.11.2025.
//

import DesignSystem
import MediaLibrary
import SwiftUI

struct MediaListHeaderView: View {
    enum Event {
        case play
        case shuffle
    }

    let item: MediaItem.Label
    let onEvent: (Event) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ArtworkView(
                item.artwork,
                cornerRadius: 10
            )
            .padding(.horizontal, 48)

            Text(item.title)
                .font(.system(size: 22, weight: .bold))
                .padding(.top, 23)

            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.appFont.mediaListHeaderSubtitle)
                    .foregroundStyle(Color.textAccent)
                    .padding(.top, 4)
            }
            buttons
                .padding(.top, 14)
        }
        .multilineTextAlignment(.center)
    }
}

private extension MediaListHeaderView {
    var buttons: some View {
        HStack(spacing: 16) {
            Button {
                onEvent(.play)
            }
            label: {
                buttonLabel("Play", systemImage: "play.fill")
            }

            Button {
                onEvent(.shuffle)
            }
            label: {
                buttonLabel("Shuffle", systemImage: "shuffle")
            }
        }
        .buttonStyle(AppleMusicButtonStyle())
    }

    func buttonLabel(_ title: String, systemImage icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
            Text(title)
                .font(.appFont.button)
        }
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    let item: Media = dependencies.mediaState.mediaList(persisted: false).first!.items.first!
    MediaListHeaderView(
        item: .init(
            title: item.meta.title,
            subtitle: item.meta.subtitle,
            artwork: .radio(item.meta.artwork)
        ),
        onEvent: { _ in }
    )
    .environment(dependencies)
}
