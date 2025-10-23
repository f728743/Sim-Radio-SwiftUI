//
//  SeriesDetailsBar.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 22.10.2025.
//

import Kingfisher
import SwiftUI

struct SeriesDetailsBar: View {
    let title: String
    let controsOpacity: CGFloat
    let onPlay: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0), .black.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Const.height)

            HStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()
                ZStack {
                    Circle()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(Color(.palette.brand))

                    Button(
                        action: onPlay,
                        label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 21))
                                .foregroundStyle(.white)
                                .padding(10)
                                .contentShape(.rect)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
            .opacity(controsOpacity)
        }
    }

    enum Const {
        static var height: CGFloat { 88 }
    }
}
