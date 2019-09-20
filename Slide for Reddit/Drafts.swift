//
//  Drafts.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/22/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class Drafts {
    public static var drafts: [NSString] = []
    
    public static func addDraft(s: String) {
        for draft in drafts {
            if String(draft).trimmed() == s.trimmed() {
                return
            }
        }
        drafts.append(s as NSString)
        saveAndUpdate()
    }
    
    public static func initialize() {
        Drafts.drafts = UserDefaults.standard.array(forKey: "drafts") as! [NSString]? ?? []
    }
    
    public static func saveAndUpdate() {
        UserDefaults.standard.set(Drafts.drafts, forKey: "drafts")
        UserDefaults.standard.synchronize()
        initialize()
    }
    
    public static func deleteDraft(s: String) {
        drafts.remove(at: drafts.firstIndex(of: s as NSString)!)
        saveAndUpdate()
    }
    
}
