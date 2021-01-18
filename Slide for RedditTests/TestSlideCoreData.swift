//
//  TestSlideCoreData.swift
//  Slide for RedditTests
//
//  Created by Carlos Crane on 12/10/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation

class TestSlideCoreData: NSObject {
    var storeContainer: NSPersistentContainer
    override init() {

        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType

        let container = NSPersistentContainer(name: "Reddit")
        container.persistentStoreDescriptions = [persistentStoreDescription]

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        storeContainer = container
        super.init()
    }
}
