//
//  SeriesSearchResultScreen.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 19.10.2025.
//

import Kingfisher
import SwiftUI

struct SeriesSearchResultScreen: View {
    @State private var viewModel: SeriesSearchResultScreenViewModel

    init(series: APISimRadioSeriesDTO) {
        _viewModel = State(
            wrappedValue: SeriesSearchResultScreenViewModel(series: series)
        )
    }

    var body: some View {
        ScrollView {
            scrollContent
        }
        .ignoresSafeArea()
        .task {
            try? await viewModel.load()
        }
    }
}

private extension SeriesSearchResultScreen {
    var scrollContent: some View {
        VStack(spacing: 0) {
            cover
            VStack(spacing: 0) {
                SeriesView(
                    series: viewModel.display.series,
                    onAdd: viewModel.addSeries
                )
                stationList
            }
            .padding(.horizontal, ViewConst.screenPaddings)
            .padding(.top, 30)
        }
    }

    var stationList: some View {
        Text("Stations")
    }

    var cover: some View {
        ZStack(alignment: .bottom) {
            KFImage.url(viewModel.display.cover.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .aspectRatio(1.0, contentMode: .fit)
            coverBottomBar
        }
    }

    var coverBottomBar: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.0), .black.opacity(0.5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)

            HStack(spacing: 0) {
                Text(viewModel.display.cover.title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()
                ZStack {
                    Circle()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(Color(.palette.brand))

                    Button(
                        action: {
                            viewModel.play()
                        },
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
        }
    }
}

private struct SeriesView: View {
    let series: SeriesSearchResultScreenViewModel.Display.Series
    let onAdd: () -> Void
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ArtworkView(.album(series.artwork), cornerRadius: 9)
                .frame(width: 98, height: 98)
            VStack(alignment: .leading, spacing: 0) {
                Text(series.title)
                    .font(.system(size: 16))
                Text(series.description)
                    .font(.system(size: 13))
                    .padding(.top, 3)

                Button(
                    action: onAdd,
                    label: {
                        ZStack {
                            Circle()
                                .foregroundStyle(Color(.palette.buttonBackground))
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(.palette.brand))
                        }
                        .frame(width: 32, height: 32)
                    }
                )
                .padding(.top, 6)
                .padding(.bottom, 2)
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SeriesSearchResultScreen(series: .stub)
}
