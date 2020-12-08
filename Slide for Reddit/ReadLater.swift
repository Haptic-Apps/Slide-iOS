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
    public static var readLaterIDs: NSMutableDictionary = NSMutableDictionary() {
        didSet {
            delegate?.didUpdate()
        }
    }
    
    public static weak var delegate: ReadLaterDelegate?
    
    public static func getReadLaterIDs(sub: String = "all") -> [Link] {
        var toReturn = [Link]()
        for value in readLaterIDs.allKeys {
            if value is String && ((readLaterIDs[value] as! String).lowercased() == sub.lowercased() || sub == "all") {
                var id = value as! String
                if id.contains("_") {
                    id = id.substring(3, length: id.length - 3)
                }
                toReturn.append(Link(id: id))
            }
        }
        return toReturn
    }

    public static func isReadLater(link: SubmissionObject) -> Bool {
        return isReadLater(id: link.id, subreddit: link.subreddit)
    }

    public static func isReadLater(id: String, subreddit: String) -> Bool {
        return ReadLater.getReadLaterIDs(sub: subreddit).contains(where: { (link) -> Bool in
            return link.id == id
        })
    }

    @discardableResult
    public static func toggleReadLater(link: SubmissionObject) -> Bool {
        let isMarkedReadLater = isReadLater(id: link.id)
        if isMarkedReadLater {
            ReadLater.removeReadLater(link: link)
            return false
        } else {
            ReadLater.addReadLater(link: link)
            return true
        }
    }

    public static func addReadLater(link: SubmissionObject) {
        addReadLater(id: link.id, subreddit: link.subreddit)
    }
    
    public static func isReadLater(id: String) -> Bool {
        return readLaterIDs[id] != nil
    }
    
    public static func addReadLater(id: String, subreddit: String) {
        readLaterIDs.setValue(subreddit, forKey: id)
        AppDelegate.removeDict.removeObject(forKey: id)
        delegate?.didUpdate()
    }

    public static func removeReadLater(link: SubmissionObject) {
        removeReadLater(id: link.id)
        delegate?.didUpdate()
    }
    
    public static func removeReadLater(id: String) {
        var shortId = id
        if shortId.contains("_") {
            shortId = shortId.substring(3, length: id.length - 3)
            readLaterIDs.removeObject(forKey: shortId)
        }
        readLaterIDs.removeObject(forKey: id)
        AppDelegate.removeDict[id] = 0
    }

    enum ReadWhere: String {
        case WATCH = "watch"
        case SUBLIST = "sublist"
        case OFFLINE = "offline"
        case OTHER = "other"
    }
}
