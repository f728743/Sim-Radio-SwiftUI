//
//  ArtworkView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.08.2025.
//

import Kingfisher
import SwiftUI

public struct ArtworkView: View {
    let artwork: Artwork
    let cornerRadius: CGFloat
    var background: Color

    public init(_ artwork: Artwork, cornerRadius: CGFloat = 8, background: Color = Color(.palette.artworkBackground)) {
        self.artwork = artwork
        self.cornerRadius = cornerRadius
        self.background = background
    }

    public var body: some View {
        let border = UIScreen.hairlineWidth
        ZStack {
            background
                .aspectRatio(contentMode: .fit)
            switch artwork {
            case let .radio(name):
                StationPlaceholderView(name: name)

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
                    .foregroundStyle(Color.iconSecondary)
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
        ArtworkView(.radio(name: "Rock"))
        ArtworkView(.radio())
        ArtworkView(.album)
    }
}
