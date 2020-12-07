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
    
    //mark SubmissionsÏ
    public static func getSeen(s: Submission) -> Bool {
        if !SettingValues.saveHistory {
            return false
        } else if s.isNSFW && !SettingValues.saveNSFWHistory {
            return false
        }
        let fullname = s.id
        if seenTimes.object(forKey: fullname) != nil {
            return true
        }
        return (s.isVisited || s.likes != .none)
    }
    
    public static func getSeenTime(s: Submission) -> Double {
        let fullname = s.id
        if let time = seenTimes.object(forKey: fullname) {
            if time is NSNumber {
                return Double(truncating: time as! NSNumber)
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
    public static func addSeen(s: Submission, skipDuplicates: Bool = true) {
        if !SettingValues.saveNSFWHistory && s.isNSFW {
            
        } else if SettingValues.saveHistory {
            let fullname = s.id
            currentSeen.append(fullname)
            if !skipDuplicates || seenTimes.object(forKey: fullname) == nil {
                seenTimes.setValue(NSNumber(value: NSDate().timeIntervalSince1970), forKey: fullname)
            }
            currentVisits.append(s.id)
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
                return Double(truncating: time as! NSNumber)
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    //mark Comments
    public static func commentsSince(s: Submission) -> Int {
        if let comments = commentCounts.object(forKey: s.id) {
            return s.commentCount - (comments as! Int)
        } else {
            return 0
        }
    }
    
    public static func setComments(s: Submission) {
        commentCounts.setValue(NSNumber(value: s.commentCount), forKey: s.id)
    }
}
