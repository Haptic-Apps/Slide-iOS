//
//  ReadLater.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/29/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class ReadLater {
    public static var readLaterIDs = NSMutableDictionary()
    
    public static func getReadLaterIDs(sub: String = "all") -> [Link] {
        var toReturn = [Link]()
        for value in readLaterIDs.allKeys {
            if value is String && ((readLaterIDs[value] as! String).lowercased() == sub || sub == "all") {
                var id = value as! String
                if id.contains("_") {
                    id = id.substring(3, length: id.length - 3)
                }
                toReturn.append(Link(id: id))
            }
        }
        return toReturn
    }
    
    public static func addReadLater(id: String, subreddit: String) {
        readLaterIDs.setValue(subreddit, forKey: id)
    }
    
    public static func removeReadLater(id: String) {
        print(readLaterIDs)
        print(id)
        var shortId = id
        if shortId.contains("_") {
            shortId = shortId.substring(3, length: id.length - 3)
            readLaterIDs.removeObject(forKey: shortId)
        }
        readLaterIDs.removeObject(forKey: id)
    }

    enum ReadWhere: String {
        case WATCH = "watch"
        case SUBLIST = "sublist"
        case OFFLINE = "offline"
        case OTHER = "other"
    }
}
