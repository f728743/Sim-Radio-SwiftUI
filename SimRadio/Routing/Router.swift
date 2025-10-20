//
//  Router.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.01.2025.
//

import SwiftUI

enum Route: Hashable, Equatable {
    case mediaList(items: [Media], listMeta: MediaList.Meta?)
    case downloaded
    case seriesSearchResult(series: APISimRadioSeriesDTO)
}

@Observable
class Router {
    var path = NavigationPath()

    func navigateToMedia(items: [Media], listMeta: MediaList.Meta?) {
        path.append(Route.mediaList(items: items, listMeta: listMeta))
    }

    func navigateToDownloaded() {
        path.append(Route.downloaded)
    }

    func navigateToSeriesSearchResult(series: APISimRadioSeriesDTO) {
        path.append(Route.seriesSearchResult(series: series))
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}

private struct RouterViewModifier: ViewModifier {
    @State private var router = Router()
    func body(content: Content) -> some View {
        NavigationStack(path: $router.path) {
            content
                .environment(router)
                .navigationDestination(for: Route.self) { route in
                    RoutedView(route: route)
                }
        }
    }
}

extension View {
    func withRouter() -> some View {
        modifier(RouterViewModifier())
    }
}
