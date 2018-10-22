//
//  ReadLater.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/29/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

protocol ReadLaterDelegate: class {
    func didUpdate()
}

class ReadLater {
    public static var readLaterIDs: NSMutableDictionary  = NSMutableDictionary() {
        didSet {
            delegate?.didUpdate()
        }
    }
    
    public static weak var delegate: ReadLaterDelegate?
    
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

    public static func isReadLater(link: RSubmission) -> Bool {
        return isReadLater(id: link.getId(), subreddit: link.subreddit)
    }

    public static func isReadLater(id: String, subreddit: String) -> Bool {
        return ReadLater.getReadLaterIDs(sub: subreddit).contains(where: { (link) -> Bool in
            return link.getId() == id
        })
    }

    @discardableResult
    public static func toggleReadLater(link: RSubmission) -> Bool {
        let isMarkedReadLater = isReadLater(link: link)
        if isMarkedReadLater {
            ReadLater.removeReadLater(link: link)
            return false
        } else {
            ReadLater.addReadLater(link: link)
            return true
        }
    }

    public static func addReadLater(link: RSubmission) {
        addReadLater(id: link.getId(), subreddit: link.subreddit)
    }
    
    public static func isReadLater(id: String) -> Bool {
        return readLaterIDs[id] != nil
    }
    
    public static func addReadLater(id: String, subreddit: String) {
        readLaterIDs.setValue(subreddit, forKey: id)
    }

    public static func removeReadLater(link: RSubmission) {
        removeReadLater(id: link.getId())
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
