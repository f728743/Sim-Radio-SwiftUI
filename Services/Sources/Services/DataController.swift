//
//  DataController.swift
//  SimRadio
//
//  Created by Alexey Vorobyov on 07.10.2025.
//

import CoreData

public final class DataController {
    public let container: NSPersistentContainer

    public init() {
        let modelURL = Bundle.module.url(forResource: "SimRadio", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        container = NSPersistentContainer(name: "SimRadio", managedObjectModel: model)

        container.loadPersistentStores { _, error in
            if let error {
                print("Core Data error: \(error)")
            }
        }
    }
}
