//
//  CustomRootTabView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 27.11.2024.
//

import SwiftUI

struct CustomRootTabView: View {
    @State private var tabSelection: TabBarItem = .home

    var body: some View {
        CustomTabView(selection: $tabSelection) {
            LibraryScreen()
                .withRouter()
                .accentColor(Color(.palette.brand))
                .tabBarItem(tab: .home, selection: $tabSelection)

            RadioScreen()
                .tabBarItem(tab: .radio, selection: $tabSelection)

            SearchScreen()
                .tabBarItem(tab: .search, selection: $tabSelection)
        }
    }
}

#Preview {
    @Previewable @State var dependencies = Dependencies.stub
    @Previewable @State var playerController = PlayerController.stub

    CustomRootTabView()
        .environment(dependencies)
        .environment(playerController)
}
