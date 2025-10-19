//
//  RootTabView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.09.2025.
//

import Foundation
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            ForEach(TabBarItem.allCases, id: \.self) { item in
                Tab(role: item.role) {
                    NavigationStack {
                        item.destinationView
                    }
                } label: {
                    Label {
                        Text(item.title)
                    } icon: {
                        item.image
                    }
                }
            }
        }
        .accentColor(Color(.palette.brand))
    }
}

private extension TabBarItem {
    @MainActor
    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .library:
            LibraryScreen()
                .withRouter()
        case .radio:
            RadioScreen()
                .withRouter()
        case .search:
            SearchScreen()
                .withRouter()
        }
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub

    RootTabView()
        .environment(playerController)
        .environment(dependencies)
}
