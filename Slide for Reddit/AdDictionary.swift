//
//  AdDictionary.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/1/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
class AdDictionary {
    static var hosts: [String] = []
    
    static func doInit() {
        let path = Bundle.main.path(forResource: "adsources", ofType: "txt")
        do {
            let text = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            hosts = text.components(separatedBy: ",")
            print(hosts.count)
        }
        catch {
            print(error)
        }
    }
}
