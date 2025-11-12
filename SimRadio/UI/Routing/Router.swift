//
//  Router.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 26.01.2025.
//

import MediaLibrary
import Services
import SwiftUI

enum Route: Hashable, Equatable {
    case mediaList(_ items: [Media], listMeta: MediaList.Meta?)
    case mediaItem(_ item: Media)
    case downloaded
    case simRadio
    case simRadioAllStations
    case radio
    case seriesSearchResult(series: APISimRadioSeriesDTO)
}

@Observable
class Router {
    var path = NavigationPath()

    func navigateToMedia(items: [Media], listMeta: MediaList.Meta?) {
        path.append(Route.mediaList(items, listMeta: listMeta))
    }

    func navigateToMedia(item: Media) {
        path.append(Route.mediaItem(item))
    }

    func navigateToRadio() {
        path.append(Route.radio)
    }

    func navigateToSimRadio() {
        path.append(Route.simRadio)
    }

    func navigateToSimRadioAllStations() {
        path.append(Route.simRadioAllStations)
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
                        .environment(router)
                }
        }
    }
}

extension View {
    func withRouter() -> some View {
        modifier(RouterViewModifier())
    }
}
