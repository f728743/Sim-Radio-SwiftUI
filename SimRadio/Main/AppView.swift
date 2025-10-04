//
//  AppView.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 14.01.2025.
//

import SwiftUI

struct AppView: View {
    @Environment(Dependencies.self) var dependencies
    var body: some View {
        OverlaidRootView()
            .environment(dependencies.playerController)
            .environment(\.managedObjectContext, dependencies.dataController.container.viewContext)
    }
}
