//
//  MoreModel+CoreDataProperties.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/6/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//

import Foundation
import CoreData


extension MoreModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MoreModel> {
        return NSFetchRequest<MoreModel>(entityName: "MoreModel")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var parentID: String
    @NSManaged public var count: Int64
    @NSManaged public var childrenString: String

}
