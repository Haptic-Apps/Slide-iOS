//
//  MoreObject.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/7/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation
import reddift

class MoreObject: RedditObject {
    public var id: String
    public var name: String
    public var parentID: String
    public var count: Int64
    public var childrenString: String
    
    static func moreToMoreObject(more: More) -> MoreObject {
        return MoreObject(more: more)
    }

    public init(more: More) {
        if more.id.endsWith("_") {
            self.id = "more_\(NSUUID().uuidString)"
        } else {
            self.id = more.name
        }
        self.name = more.name
        self.parentID = more.parentId
        self.count = Int64(more.count)
        self.childrenString = more.children.joined()
    }
}

extension MoreObject: Cacheable {
    func insertSelf(into context: NSManagedObjectContext, andSave: Bool) -> NSManagedObject? {
        context.performAndWaitReturnable {
            let moreModel = NSEntityDescription.insertNewObject(forEntityName: "MoreModel", into: context) as! MoreModel
            moreModel.id = self.id
            moreModel.name = self.name
            moreModel.parentID = self.parentID
            moreModel.childrenString = self.childrenString
            moreModel.count = self.count
            
            if andSave {
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Failed to save managed context \(error): \(error.userInfo)")
                    return nil
                }
            }
            
            return moreModel
        }
    }
}
