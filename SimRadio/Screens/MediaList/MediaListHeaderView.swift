//
//  MediaListHeaderView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 03.11.2025.
//

import SwiftUI

struct MediaListHeaderView: View {
    let listMeta: MediaList.Meta

    var body: some View {
        VStack(spacing: 0) {
            ArtworkView(
                .radio(listMeta.artwork),
                cornerRadius: 10
            )
            .padding(.horizontal, 52)

            Text(listMeta.title)
                .font(.appFont.mediaListHeaderTitle)
                .padding(.top, 18)

            if let subtitle = listMeta.subtitle {
                Text(subtitle)
                    .font(.appFont.mediaListHeaderSubtitle)
                    .foregroundStyle(Color(.palette.textSecondary))
                    .padding(.top, 2)
            }

            buttons
                .padding(.top, 14)
        }
    }
}

private extension MediaListHeaderView {
    var buttons: some View {
        HStack(spacing: 16) {
            Button {
                print("Play")
            }
            label: {
                buttonLabel("Play", systemImage: "play.fill")
            }

            Button {
                print("Shuffle")
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
