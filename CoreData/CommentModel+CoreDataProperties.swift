//
//  CommentModel+CoreDataProperties.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/6/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//

import Foundation
import CoreData


extension CommentModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CommentModel> {
        return NSFetchRequest<CommentModel>(entityName: "CommentModel")
    }

    @NSManaged public var approvedBy: String?
    @NSManaged public var author: String
    @NSManaged public var awardsJSON: String
    @NSManaged public var controversality: Int16
    @NSManaged public var created: Date
    @NSManaged public var depth: Int16
    @NSManaged public var distinguished: String?
    @NSManaged public var flairJSON: String?
    @NSManaged public var hasVoted: Bool
    @NSManaged public var hidden: Bool
    @NSManaged public var htmlBody: String
    @NSManaged public var id: String
    @NSManaged public var isApproved: Bool
    @NSManaged public var isArchived: Bool
    @NSManaged public var isCakeday: Bool
    @NSManaged public var isEdited: Bool
    @NSManaged public var isMod: Bool
    @NSManaged public var isRemoved: Bool
    @NSManaged public var isSaved: Bool
    @NSManaged public var isStickied: Bool
    @NSManaged public var locked: Bool
    @NSManaged public var markdownBody: String
    @NSManaged public var name: String
    @NSManaged public var parentId: String?
    @NSManaged public var permalink: String
    @NSManaged public var removalNote: String?
    @NSManaged public var removalReason: String?
    @NSManaged public var removedBy: String?
    @NSManaged public var reportsJSON: String?
    @NSManaged public var score: Double
    @NSManaged public var scoreHidden: Bool
    @NSManaged public var submissionTitle: String
    @NSManaged public var subreddit: String
    @NSManaged public var voteDirection: Bool

}
