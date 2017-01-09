//
//  Trophy.swift
//  reddift
//
//  Created by sonson on 2015/11/13.
//  Copyright © 2015年 sonson. All rights reserved.
//

import Foundation

/**
 Trophy object
 */
public struct Trophy: Thing {
    /// identifier of Thing like 15bfi0.
    public let id: String
    /// name of Thing, that is fullname, like t3_15bfi0.
    public let name: String
    /// type of Thing, like t3.
    static public let kind = "t6"
    
    /// Trophy data
    public let title: String
    public let description: String
    public let awardID: String
    public let icon40: URL?
    public let icon70: URL?
    public let url: URL?
    
    public init(id: String) {
        self.id = id
        self.name = "\(Comment.kind)_\(self.id)"
        self.title = ""
        self.description = ""
        self.awardID = ""
        self.icon40 = nil
        self.icon70 = nil
        self.url = nil
    }
    
    public init(json: JSONDictionary) {
        id = json["id"] as? String ?? ""
        name = "\(Trophy.kind)_\(id)"
        awardID = json["award_id"] as? String ?? ""
        description = json["description"] as? String ?? ""
        icon40 = URL(string: (json["icon_40"] as? String ?? ""))
        icon70 = URL(string: (json["icon_70"] as? String ?? ""))
        url = URL(string: (json["url"] as? String ?? ""))
        title = json["name"] as? String ?? ""
    }
}
