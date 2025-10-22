//
//  RoutedView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.01.2025.
//

import SwiftUI

struct RoutedView: View {
    let route: Route

    var body: some View {
        switch route {
        case let .mediaList(items, listMeta):
            MediaListScreen(items: items, listMeta: listMeta)
        case .downloaded:
            DownloadedScreen()
        case let .seriesSearchResult(series):
            SeriesDetailsScreen(series: series)
        }
    }
}
