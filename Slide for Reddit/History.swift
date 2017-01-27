//
//  History.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/8/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class History {
    public static var seenTimes = NSMutableDictionary()
    public static var commentCounts = NSMutableDictionary()

    //mark Submissions
    public static func getSeen(s: RSubmission)-> Bool {
        let fullname = s.getId()
        if seenTimes.object(forKey: fullname) != nil{
            return true
        }
        return (s.visited || s.likes != .none)
    }

    public static func getSeenTime(s: RSubmission)-> Double{
    let fullname = s.getId()
       if let time = seenTimes.object(forKey: fullname) {
        if(time is NSNumber){
            return Double(time as! NSNumber)
        } else {
            return 0
        }
       } else {
        return 0
        }
    }

    public static func addSeen(s: RSubmission){
        let fullname = s.getId()
        seenTimes.setValue(NSNumber(value: NSDate().timeIntervalSince1970), forKey: fullname)
    }
    
    //mark Comments
    public static func commentsSince(s: RSubmission) -> Int{
        if let comments = commentCounts.object(forKey: s.getId()){
            return s.commentCount - (comments as! Int)
        } else {
            return 0
        }
    }
    
    public static func setComments(s: RSubmission){
        commentCounts.setValue(NSNumber(value: s.commentCount), forKey: s.getId())
    }
}
