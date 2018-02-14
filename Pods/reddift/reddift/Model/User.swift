//
//  User.swift
//  reddift
//
//  Created by sonson on 2015/11/12.
//  Copyright © 2015年 sonson. All rights reserved.
//

import Foundation

/**
 */
public enum UserModPermission: String {
    case all
    case wiki
    case posts
    case mail
    case flair
    case unknown
    
    public init(_ value: String) {
        switch value {
        case "all":
            self = .all
        case "wiki":
            self = .wiki
        case "posts":
            self = .posts
        case "mail":
            self = .mail
        case "flair":
            self = .flair
        default:
            self = .unknown
        }
    }
}

/**
 User object
 */
public struct User {
    public let date: TimeInterval
    public let modPermissions: [UserModPermission]
    public let name: String
    public let id: String
    
    public init(date: Double, permissions: [String]?, name: String, id: String) {
        self.date = date
        if let permissions = permissions {
            self.modPermissions = permissions.map({UserModPermission($0)})
        } else {
            self.modPermissions = []
        }
        self.name = name
        self.id = id
    }
}
