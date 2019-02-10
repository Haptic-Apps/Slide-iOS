//
//  History.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/8/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class History {
    public static var seenTimes = NSMutableDictionary()
    public static var commentCounts = NSMutableDictionary()
    
    public static var currentVisits = [String]()
    
    //mark Submissions
    public static func getSeen(s: RSubmission) -> Bool {
        if !SettingValues.saveHistory {
            return false
        } else if s.nsfw && !SettingValues.saveNSFWHistory {
            return false
        }
        let fullname = s.getId()
        if seenTimes.object(forKey: fullname) != nil {
            return true
        }
        return (s.visited || s.likes != .none)
    }
    
    public static func getSeenTime(s: RSubmission) -> Double {
        let fullname = s.getId()
        if let time = seenTimes.object(forKey: fullname) {
            if time is NSNumber {
                return Double(time as! NSNumber)
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    public static func publishSeen() {
        if SettingValues.saveHistory && false {
            //Possibly do this, although it's only available as an API endpoint if the user has Reddit gold
        }
    }
    
    public static var currentSeen: [String] = [String]()
    public static func addSeen(s: RSubmission, skipDuplicates: Bool = true) {
        if !SettingValues.saveNSFWHistory && s.nsfw {
            
        } else if SettingValues.saveHistory {
            let fullname = s.getId()
            currentSeen.append(fullname)
            if !skipDuplicates || seenTimes.object(forKey: fullname) == nil {
                seenTimes.setValue(NSNumber(value: NSDate().timeIntervalSince1970), forKey: fullname)
            }
            currentVisits.append(s.getId())
        }
    }
    
    public static func clearHistory() {
        seenTimes.removeAllObjects()
    }
    
    public static func inboxSeen() {
        seenTimes.setValue(NSNumber(value: NSDate().timeIntervalSince1970), forKey: "inbox")
    }
    
    public static func getInboxSeen() -> Double {
        if let time = seenTimes.object(forKey: "inbox") {
            if time is NSNumber {
                return Double(time as! NSNumber)
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    //mark Comments
    public static func commentsSince(s: RSubmission) -> Int {
        if let comments = commentCounts.object(forKey: s.getId()) {
            return s.commentCount - (comments as! Int)
        } else {
            return 0
        }
    }
    
    public static func setComments(s: RSubmission) {
        commentCounts.setValue(NSNumber(value: s.commentCount), forKey: s.getId())
    }
}
