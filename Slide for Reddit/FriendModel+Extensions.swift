//
//  FriendModel+Extensions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/6/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation

public extension FriendModel {
    static func friendToRealm(user: User) -> FriendModel {
        let rFriend = RFriend()
        rFriend.name = user.name
        rFriend.friendSince = NSDate(timeIntervalSince1970: TimeInterval(user.date))
        return rFriend
    }
}
