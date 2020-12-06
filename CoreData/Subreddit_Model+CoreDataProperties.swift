//
//  Subreddit_Model+CoreDataProperties.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/5/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//

import Foundation
import CoreData


extension Subreddit_Model {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Subreddit_Model> {
        return NSFetchRequest<Subreddit_Model>(entityName: "Subreddit_Model")
    }


}
