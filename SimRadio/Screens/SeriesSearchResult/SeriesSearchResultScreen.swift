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
            content
        }
        .ignoresSafeArea()
        .task {
            try? await viewModel.load()
        }
    }
}

private extension SeriesSearchResultScreen {
    var content: some View {
        VStack(spacing: 0) {
            KFImage.url(viewModel.display?.cover.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .aspectRatio(1.0, contentMode: .fit)
        }
    }
}

#Preview {
    SeriesSearchResultScreen(series: .stub)
}
