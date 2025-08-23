//
//  Artwork.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.08.2025.
//

import Kingfisher
import SwiftUI

struct Artwork: View {
    let url: URL?
    var cornerRadius: CGFloat = 8
    var background = Color(.palette.artworkBackground)

    var body: some View {
        let border = UIScreen.hairlineWidth
        ZStack {
            background
                .aspectRatio(contentMode: .fit)
            KFImage.url(url)
                .resizable()
                .aspectRatio(contentMode: .fit)
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
    Artwork(
        url: URL(string: "https://raw.githubusercontent.com/tmp-acc/GTA-IV-Radio-Stations/main/gta_iv.png")!
    )
    .padding(32)
}
