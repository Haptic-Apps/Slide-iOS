//
//  RemovalReasons.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/10/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

class RemovalReasons {
    public static var reasons: [NSString] = []
    
    public static func addReason(s: String) {
        reasons.append(s as NSString)
        saveAndUpdate()
    }
    
    public static func initialize() {
        if let reasons = UserDefaults.standard.array(forKey: "reasons") as! [NSString]? {
            RemovalReasons.reasons = reasons
        }
        else {
            addReason(s: "Spam")
            addReason(s: "Test")
            addReason(s: "Custom reason")
        }
    }
    
    public static func saveAndUpdate() {
        UserDefaults.standard.set(RemovalReasons.reasons, forKey: "reasons")
        UserDefaults.standard.synchronize()
        initialize()
    }
    
    public static func deleteReason(s: String) {
        reasons.remove(at: reasons.index(of: s as NSString)!)
        saveAndUpdate()
    }
    
}
