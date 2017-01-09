//
//  More.swift
//  reddift
//
//  Created by sonson on 2015/04/21.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
More object.
"more" is included in Listing object(Maybe).
If Listing object has "more" object, it has mure more children to be downloaded.
*/
public struct More: Thing {
    /// identifier of Thing like 15bfi0.
    public let id: String
    /// name of Thing, that is fullname, like t3_15bfi0.
    public let name: String
    /// type of Thing, like t3.
    public static let kind = "more"
    
    public let parentId: String
    public let count: Int
	public let children: [String]
	
    public init(id: String) {
        self.id = id
        self.name = "\(More.kind)_\(self.id)"
        parentId = ""
        count = 0
        children = []
    }
    
    /**
    Parse more object.
    
    - parameter data: Dictionary, must be generated parsing "more".
    - returns: More object as Thing.
    */
    public init(json data: JSONDictionary) {
        id = data["id"] as? String ?? ""
        name = data["name"] as? String ?? ""
        parentId = data["parent_id"] as? String ?? ""
        count = data["count"] as? Int ?? 0
        children = data["children"] as? [String] ?? []
    }
    
    public init(id: String, name: String, parentId: String, count: Int = 0, child: String) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.count = count
        self.children = [child]
    }
    
    public var isEmpty: Bool {
        get {
            return id == "_"
        }
    }
}
