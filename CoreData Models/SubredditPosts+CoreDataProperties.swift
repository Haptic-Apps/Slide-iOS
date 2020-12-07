//
//  SubredditPosts+CoreDataProperties.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/6/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//

import Foundation
import CoreData


extension SubredditPosts {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SubredditPosts> {
        return NSFetchRequest<SubredditPosts>(entityName: "SubredditPosts")
    }

    @NSManaged public var subreddit: String?
    @NSManaged public var time: Date?
    @NSManaged public var posts: String?

}
