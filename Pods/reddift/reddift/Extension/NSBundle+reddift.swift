//
//  NSBundle+reddift.swift
//  reddift
//
//  Created by sonson on 2015/04/13.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

extension Bundle {
    /**
    Returns object from default info.plist.
    
    - parameter key: key for value
    - returns: Value
    */
    class func infoValueInMainBundle(for key: String) -> AnyObject? {
        if let obj = self.main.localizedInfoDictionary?[key] {
            return obj as AnyObject
        }
        if let obj = self.main.infoDictionary?[key] {
            return obj as AnyObject
        }
        return nil
    }
}
