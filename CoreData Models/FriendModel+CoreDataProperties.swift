//
//  FriendModel+CoreDataProperties.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/6/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//

import Foundation
import CoreData


extension FriendModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FriendModel> {
        return NSFetchRequest<FriendModel>(entityName: "FriendModel")
    }

    @NSManaged public var name: String
    @NSManaged public var friendSince: Date

}
