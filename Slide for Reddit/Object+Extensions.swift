//
//  Object+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation
import RealmSwift
import reddift

extension Object {
    func getIdentifier() -> String {
        if self is RComment {
            return (self as! RComment).getId()
        } else if self is RMore {
            return (self as! RMore).getId()
        } else if self is RSubmission {
            return (self as! RSubmission).getId()
        } else {
            return (self as! RMessage).getId()
        }
    }
}
