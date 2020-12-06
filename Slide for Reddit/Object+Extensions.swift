//
//  Object+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

import reddift

extension Object {
    func getIdentifier() -> String {
        if self is CommentModel {
            return (self as! CommentModel).id
        } else if self is RMore {
            return (self as! RMore).id
        } else if self is Submission {
            return (self as! Submission).id
        } else {
            return (self as! RMessage).id
        }
    }
}
