//
//  ModlogModel+CoreDataProperties.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/6/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//

import Foundation
import CoreData


extension ModlogModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ModlogModel> {
        return NSFetchRequest<ModlogModel>(entityName: "ModlogModel")
    }

    @NSManaged public var id: String
    @NSManaged public var mod: String
    @NSManaged public var targetBody: String
    @NSManaged public var created: Date
    @NSManaged public var subreddit: String
    @NSManaged public var targetTitle: String
    @NSManaged public var permalink: String
    @NSManaged public var details: String
    @NSManaged public var action: String
    @NSManaged public var targetAuthor: String
    @NSManaged public var subject: String
}
