//
//  Subreddit_Posts+CoreDataProperties.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/5/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//

import Foundation
import CoreData


extension Subreddit_Posts {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Subreddit_Posts> {
        return NSFetchRequest<Subreddit_Posts>(entityName: "Subreddit_Posts")
    }


}
