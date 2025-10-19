//
//  ArtworkView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.08.2025.
//

import Kingfisher
import SwiftUI

enum Artwork: Hashable {
    case radio
    case album
    case webImage(URL)
}

extension Artwork {
    static func radio(_ url: URL?) -> Artwork {
        url.map { .webImage($0) } ?? .radio
    }

    static func album(_ url: URL?) -> Artwork {
        url.map { .webImage($0) } ?? .album
    }

    static func radioImage(_ urlString: String?) -> Artwork {
        .radio(urlString.flatMap { URL(string: $0) })
    }
}

struct ArtworkView: View {
    let artwork: Artwork
    let cornerRadius: CGFloat
    var background: Color

    init(_ artwork: Artwork, cornerRadius: CGFloat = 8, background: Color = Color(.palette.artworkBackground)) {
        self.artwork = artwork
        self.cornerRadius = cornerRadius
        self.background = background
    }

    var body: some View {
        let border = UIScreen.hairlineWidth
        ZStack {
            background
                .aspectRatio(contentMode: .fit)
            switch artwork {
            case .radio:
                Image(.radio)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

            case let .webImage(url):
                KFImage.url(url)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .aspectRatio(1.0, contentMode: .fit)

            case .album:
                Image(systemName: "rectangle.stack.badge.play")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .aspectRatio(1.0, contentMode: .fit)
                    .scaleEffect(0.9)
                    .foregroundStyle(Color.gray.secondary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .inset(by: border / 2)
                .stroke(Color(.palette.artworkBorder), lineWidth: border)
        )
    }
}

#Preview {
    VStack {
        ArtworkView(
            .radio(URL(string: "https://raw.githubusercontent.com/tmp-acc/GTA-IV-Radio-Stations/main/gta_iv.png"))
        )
        ArtworkView(.radio)
        ArtworkView(.album)
    }
}
