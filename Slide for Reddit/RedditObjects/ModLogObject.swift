//
//  ModLogObject.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/7/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

class ModLogObject: RedditObject {
    public var id: String
    public var name: String {
        get {
            return id
        }
        set {
            self.id = newValue
        }
    }
    public var mod: String
    public var targetBody: String
    public var created: Date
    public var subreddit: String
    public var targetTitle: String
    public var permalink: String
    public var details: String
    public var action: String
    public var targetAuthor: String
    
    static func modActionToModLogObject(thing: ModAction) -> ModLogObject {
        return ModLogObject(thing: thing)
    }

    public init(thing: ModAction) {
        self.action = thing.action
        self.created = Date(timeIntervalSince1970: thing.createdUtc)
        self.details = thing.details
        self.id = thing.id
        self.mod = thing.mod
        self.permalink = thing.targetPermalink
        self.subreddit = thing.subreddit
        self.targetAuthor = thing.targetAuthor
        self.targetBody = thing.targetBody
        self.targetTitle = thing.targetTitle
    }
}
