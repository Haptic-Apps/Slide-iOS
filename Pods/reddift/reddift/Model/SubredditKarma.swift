//
//  SubredditKarma.swift
//  reddift
//
//  Created by sonson on 2015/11/16.
//  Copyright © 2015年 sonson. All rights reserved.
//

import Foundation

/**
 Subreddit karma object
 */
public struct SubredditKarma {
    let commentKarma: Int
    let linkKarma: Int
    let subreddit: String
    
    init(subreddit: String, commentKarma: Int, linkKarma: Int) {
        self.subreddit = subreddit
        self.commentKarma = commentKarma
        self.linkKarma = linkKarma
    }
}
