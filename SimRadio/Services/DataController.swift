//
//  DataController.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 07.10.2025.
//

import CoreData
import Foundation

class DataController {
    let container = NSPersistentContainer(name: "SimRadio")

    init() {
        container.loadPersistentStores { _, error in
            if let error {
                print("Core Data error: \(error)")
            }
        }
    }
}
