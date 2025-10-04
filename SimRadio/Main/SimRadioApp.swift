//
//  SimRadioApp.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 09.01.2025.
//

import SwiftUI

@main
struct SimRadioApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appDelegate.dependencies)
        }
    }
}
