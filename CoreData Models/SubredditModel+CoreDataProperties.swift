//
//  SubredditModel+CoreDataProperties.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/6/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//

import Foundation
import CoreData


extension SubredditModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SubredditModel> {
        return NSFetchRequest<SubredditModel>(entityName: "SubredditModel")
    }


}
