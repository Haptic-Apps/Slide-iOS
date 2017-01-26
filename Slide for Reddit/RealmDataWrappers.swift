//
//  RealmDataWrappers.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/26/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import RealmSwift

class RSubmission: Object {
    override static func primaryKey() -> String? {
        return "id"
    }
    dynamic var id = ""
    dynamic var author = ""
    dynamic var created = NSDate(timeIntervalSince1970: 1)
    dynamic var edited = NSDate(timeIntervalSince1970: 1)
    dynamic var depth = 0
    dynamic var htmlBody = ""
    dynamic var subreddit = ""
    dynamic var archived = false
    dynamic var locked = false
    dynamic var url = ""
    dynamic var thumbnailUrl = ""
    dynamic var imageUrl = ""
    dynamic var commentCount = 0
    dynamic var saved = false
    dynamic var stickied = false
    dynamic var controlvertial = false
    dynamic var scoreHidden = false
    dynamic var score = 0
    dynamic var flair = ""
    dynamic var voted = false
    dynamic var vote = false
    dynamic var comments = List<RComment>()
}

class RComment: Object {
    override static func primaryKey() -> String? {
        return "id"
    }
    dynamic var id = ""
    dynamic var author = ""
    dynamic var created = NSDate(timeIntervalSince1970: 1)
    dynamic var edited = NSDate(timeIntervalSince1970: 1)
    dynamic var depth = 0
    dynamic var htmlText = ""
    dynamic var pinned = false
    dynamic var controlvertial = false
    dynamic var scoreHidden = false
    dynamic var score = 0
    dynamic var flair = ""
    dynamic var voted = false
    dynamic var vote = false
}

class RSubmissionListing: Object {
    dynamic var name = ""
    dynamic var accessed = NSDate(timeIntervalSince1970: 1)
    dynamic var comments = false
    let submissions = List<RSubmission>()
}
