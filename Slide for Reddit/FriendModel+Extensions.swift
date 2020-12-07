//
//  FriendModel+Extensions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/6/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation
import reddift

public extension FriendModel {
    static func friendToRealm(user: User) -> FriendModel {
        let friendModel = FriendModel()
        friendModel.name = user.name
        friendModel.friendSince = Date(timeIntervalSince1970: TimeInterval(user.date))
        return friendModel
    }
}
