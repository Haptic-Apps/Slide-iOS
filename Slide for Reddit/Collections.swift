//
//  Collections.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/15/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

protocol CollectionsDelegate: class {
    func didUpdate()
}

class Collections {
    public static var collectionIDs: NSMutableDictionary = NSMutableDictionary() {
        didSet {
            delegate?.didUpdate()
        }
    }
    
    public static weak var delegate: CollectionsDelegate?
    
    public static func getAllCollectionIDs() -> [Link] {
        var toReturn = [Link]()
        for value in collectionIDs.allKeys {
            if value is String {
                var id = value as! String
                if id.contains("_") {
                    id = id.substring(3, length: id.length - 3)
                }
                toReturn.append(Link(id: id))
            }
        }
        return toReturn
    }
    
    public static func getAllCollections() -> [String] {
        var collections = [String]()
        for item in collectionIDs.allValues {
            if item is String && !collections.contains(item as! String) {
                collections.append(item as! String)
            }
        }
        return collections
    }
    
    public static func getCollectionIDs(title: String = "NONE") -> [Link] {
        var toReturn = [Link]()
        for value in collectionIDs.allKeys {
            if value is String && ((collectionIDs[value] as! String).lowercased() == title.lowercased()) {
                var id = value as! String
                if id.contains("_") {
                    id = id.substring(3, length: id.length - 3)
                }
                toReturn.append(Link(id: id))
            }
        }
        return toReturn
    }

    public static func isSavedCollectionAny(link: Submission) -> Bool {
        return isSavedCollectionAny(id: link.getId())
    }

    public static func isSavedCollectionAny(link: Submission, title: String) -> Bool {
        return isSavedCollection(id: link.getId(), title: title)
    }

    public static func isSavedCollectionAny(id: String) -> Bool {
        return collectionIDs.object(forKey: id) != nil
    }

    public static func isSavedCollection(id: String, title: String) -> Bool {
        return Collections.getCollectionIDs(title: title).contains(where: { (link) -> Bool in
            return link.getId() == id
        })
    }

    @discardableResult
    public static func toggleSavedCollection(link: Submission, title: String) -> Bool {
        let isMarkedReadLater = isSavedCollection(id: link.getId(), title: title)
        if isMarkedReadLater {
            Collections.removeFromCollection(link: link, title: title)
            return false
        } else {
            Collections.addToCollection(link: link, title: title)
            return true
        }
    }

    public static func addToCollection(link: Submission, title: String) {
        addToCollection(id: link.getId(), title: title)
    }
    
    public static func addToCollection(id: String, title: String) {
        collectionIDs.setValue(title, forKey: id)
        AppDelegate.removeDict.removeObject(forKey: id)
        delegate?.didUpdate()
    }

    public static func addToCollectionCreate(id: String, title: String) {
        collectionIDs.setValue(title, forKey: id)
        AppDelegate.removeDict.removeObject(forKey: id)
        delegate?.didUpdate()
    }

    public static func removeFromCollection(link: Submission, title: String) {
        removeFromCollection(id: link.getId(), title: title)
        delegate?.didUpdate()
    }
    
    public static func removeFromCollection(id: String, title: String) {
        var shortId = id
        if shortId.contains("_") {
            shortId = shortId.substring(3, length: id.length - 3)
            collectionIDs.removeObject(forKey: shortId)
        }
        collectionIDs.removeObject(forKey: id)
        AppDelegate.removeDict[id] = 0
    }
}
