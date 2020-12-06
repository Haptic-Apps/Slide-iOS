//
//  MessageModel+CoreDataProperties.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/6/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//

import Foundation
import CoreData


extension MessageModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageModel> {
        return NSFetchRequest<MessageModel>(entityName: "MessageModel")
    }

    @NSManaged public var author: String
    @NSManaged public var created: Date
    @NSManaged public var htmlBody: String
    @NSManaged public var id: String
    @NSManaged public var markdownBody: String
    @NSManaged public var name: String
    @NSManaged public var permalink: String
    @NSManaged public var submissionTitle: String?
    @NSManaged public var subreddit: String
    @NSManaged public var subject: String
    @NSManaged public var context: String?
    @NSManaged public var isNew: Bool
    @NSManaged public var wasComment: Bool

}
