//
//  CustomTabRootView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 27.11.2024.
//

import SwiftUI

struct CustomTabRootView: View {
    @State private var tabSelection: TabBarItem = .home

    var body: some View {
        CustomTabView(selection: $tabSelection) {
            LibraryScreen()
                .withRouter()
                .accentColor(Color(.palette.brand))
                .tabBarItem(tab: .home, selection: $tabSelection)

            Text("Looking for something?")
                .tabBarItem(tab: .search, selection: $tabSelection)
        }
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub

    CustomTabRootView()
        .environment(dependencies)
        .environment(playerController)
}
