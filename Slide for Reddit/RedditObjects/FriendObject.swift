//
//  FriendObject.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/7/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

class FriendObject: RedditObject {
    public var name: String
    public var id: String {
        get {
            return name
        }
        set {
            self.name = newValue
        }
    }

    public var friendSince: Date
    
    static func userToFriendObject(user: User) -> FriendObject {
        return FriendObject(user: user)
    }

    public init(user: User) {
        self.name = user.name
        self.friendSince = Date(timeIntervalSince1970: TimeInterval(user.date))
    }
}
