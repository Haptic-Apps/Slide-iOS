//
//  Submission+CoreDataProperties.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/5/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//

import Foundation
import CoreData


extension Submission {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Submission> {
        return NSFetchRequest<Submission>(entityName: "Submission")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var author: String
    @NSManaged public var created: Date
    @NSManaged public var edited: Date?
    @NSManaged public var htmlBody: String?
    @NSManaged public var markdownBody: String?
    @NSManaged public var title: String
    @NSManaged public var subreddit: String
    @NSManaged public var archived: Bool
    @NSManaged public var locked: Bool
    @NSManaged public var hidden: Bool
    @NSManaged public var contentUrl: String?
    @NSManaged public var distinguished: String?
    @NSManaged public var videoPreview: String?
    @NSManaged public var videoMP4: String?
    @NSManaged public var isCrosspost: Bool
    @NSManaged public var isSpoiler: Bool
    @NSManaged public var isOC: Bool
    @NSManaged public var isMod: Bool
    @NSManaged public var crosspostAuthor: String?
    @NSManaged public var crosspostSubreddit: String?
    @NSManaged public var crosspostPermalink: String?
    @NSManaged public var isCakeday: Bool
    @NSManaged public var subredditIcon: String?
    @NSManaged public var reportsJSON: String?
    @NSManaged public var awardsJSON: String?
    @NSManaged public var flairJSON: String?
    @NSManaged public var galleryJSON: String
    @NSManaged public var pollJSON: String?
    @NSManaged public var removedBy: String?
    @NSManaged public var isRemoved: Bool
    @NSManaged public var approvedBy: String?
    @NSManaged public var isApproved: Bool
    @NSManaged public var removalReason: String?
    @NSManaged public var removalNote: String?
    @NSManaged public var isEdited: Bool
    @NSManaged public var commentCount: Double
    @NSManaged public var isSaved: Bool
    @NSManaged public var isStickied: Bool
    @NSManaged public var isVisited: Bool
    @NSManaged public var isSelf: Bool
    @NSManaged public var permalink: String
    @NSManaged public var bannerUrl: String?
    @NSManaged public var thumbnailUrl: String?
    @NSManaged public var lqURL: String?
    @NSManaged public var isLQ: Bool
    @NSManaged public var hasThumbnail: Bool
    @NSManaged public var hasBanner: Bool
    @NSManaged public var isNSFW: Bool
    @NSManaged public var score: Double
    @NSManaged public var upvoteRatio: Double
    @NSManaged public var domain: String
    @NSManaged public var hasVoted: Bool
    @NSManaged public var imageHeight: Int
    @NSManaged public var imageWidth: Int
    @NSManaged public var voteDirection: Bool
    @NSManaged public var isArchived: Bool
    @NSManaged public var isLocked: Bool

}
