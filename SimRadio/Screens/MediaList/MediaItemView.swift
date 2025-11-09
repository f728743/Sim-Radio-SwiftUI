//
//  MediaItemView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 09.04.2025.
//

import DesignSystem
import Kingfisher
import SwiftUI

struct MediaItemView: View {
    struct Model {
        let artwork: URL?
        let title: String
        let subtitle: String?
        var downloadStatus: MediaDownloadStatus?
        var activity: MediaActivity?
    }

    let model: Model

    var body: some View {
        HStack(spacing: 12) {
            artwork
            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(.system(size: 16))
                Text(model.subtitle ?? "")
                    .font(.appFont.mediaListItemSubtitle)
                    .foregroundStyle(Color(.palette.textTertiary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
            if let downloadStatus = model.downloadStatus {
                MediaDownloadProgressView(status: downloadStatus)
            }
        }
        .padding(.top, 4)
        .frame(height: 56, alignment: .top)
    }

    var artwork: some View {
        ZStack {
            ArtworkView(
                model.artwork.map { .webImage($0) } ?? .radio(name: model.title),
                cornerRadius: 5
            )
            if let activity = model.activity {
                Color.black.opacity(0.4)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                MediaActivityIndicator(state: activity)
                    .foregroundStyle(Color.white)
            }
        }
        .frame(width: 48, height: 48)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    MediaItemView(
        model: .init(
            artwork: URL(string: "https://raw.githubusercontent.com/tmp-acc/GTA-V-Radio-Stations-TestDownload" +
                "/master/radio_01_class_rock/radio_01_class_rock.png"),
            title: "Los Santos Rock Radio",
            subtitle: "Classic rock, soft rock, pop rock",
            activity: .paused
        )
    )
}
