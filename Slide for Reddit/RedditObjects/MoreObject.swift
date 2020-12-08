//
//  MoreObject.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/7/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

class MoreObject: RedditObject {
    public var id: String
    public var name: String
    public var parentID: String
    public var count: Int32
    public var childrenString: String
    
    static func moreToMoreObject(more: More) -> MoreObject {
        return MoreObject(more: more)
    }

    public init(more: More) {
        if more.id.endsWith("_") {
            self.id = "more_\(NSUUID().uuidString)"
        } else {
            self.id = more.name
        }
        self.name = more.name
        self.parentID = more.parentId
        self.count = Int32(more.count)
        self.childrenString = more.children.joined()
    }
}
