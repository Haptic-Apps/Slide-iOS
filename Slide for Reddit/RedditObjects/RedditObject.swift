//
//  RedditObject.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/7/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation

protocol RedditObject {
    var id: String { get set }
    var name: String { get set }
}

extension RedditObject {
    func getId() -> String {
        if let object = self as? SubmissionObject {
            return object.id
        } else if let object = self as? CommentObject {
            return object.id
        } else if let object = self as? MoreObject {
            return object.id
        } else if let object = self as? MessageObject {
            return object.id
        } else {
            return ""
        }
    }
}
