//
//  AppDelegate.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 15.05.2025.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var dependencies: Dependencies?

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        dependencies = .make()
        Task {
            await dependencies?.mediaState.load()
        }
        return true
    }
}
