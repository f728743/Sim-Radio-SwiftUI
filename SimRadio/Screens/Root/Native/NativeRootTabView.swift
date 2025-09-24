//
//  NativeRootTabView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 23.09.2025.
//

import Foundation
import SwiftUI

struct NativeRootTabView: View {
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
        case .home:
            LibraryScreen()
                .withRouter()
        case .radio:
            RadioScreen()
        case .search:
            SearchScreen()
        }
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub

    NativeRootTabView()
        .environment(playerController)
        .environment(dependencies)
}
