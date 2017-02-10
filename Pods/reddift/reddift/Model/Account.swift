//
//  Account.swift
//  reddift
//
//  Created by generator.rb via from https://github.com/reddit/reddit/wiki/JSON
//  Created at 2015-04-15 11:23:32 +0900
//

import Foundation

/**
Account object.
*/
public struct Account: Thing {
    /// identifier of Thing like 15bfi0.
    public let id: String
    /// name of Thing, that is fullname, like t3_15bfi0.
    public let name: String
    /// type of Thing, like t3.
    public static let kind = "t2"
    
    /**
    user has unread mail? null if not your account
    example: false
    */
    public let hasMail: Bool
    /**
    
    example: 1427126074
    */
    public let  created: Int
    /**
    
    example: false
    */
    public let hideFromRobots: Bool
    
    public let isFriend: Bool
    /**
    
    example: 0
    */
    public let goldCreddits: Int
    /**
    
    example: 1427122474
    */
    public let createdUtc: Int
    /**
    user has unread mod mail? null if not your account
    example: false
    */
    public let hasModMail: Bool
    /**
    user's link karma
    example: 1
    */
    public let linkKarma: Int
    /**
    user's comment karma
    example: 1
    */
    public let commentKarma: Int
    /**
    whether this account is set to be over 18
    example: true
    */
    public let over18: Bool
    /**
    reddit gold status
    example: false
    */
    public let isGold: Bool
    /**
    whether this account moderates any subreddits
    example: false
    */
    public let isMod: Bool
    /**
    
    example:
    */
    public let goldExpiration: Bool
    /**
    user has provided an email address and got it verified?
    example: false
    */
    public let hasVerifiedEmail: Bool
    /**
    Number of unread messages in the inbox. Not present if not your account
    example: 0
    */
    public let inboxCount: Int
    
    public init(id: String) {
        self.id = id
        self.name = "\(Account.kind)_\(self.id)"
        
        hasMail = false
        created = 0
        hideFromRobots = false
        goldCreddits = 0
        createdUtc = 0
        hasModMail = false
        linkKarma = 0
        commentKarma = 0
        over18 = false
        isGold = false
        isMod = false
        goldExpiration = false
        hasVerifiedEmail = false
        isFriend = false
        inboxCount = 0
    }
    
    /**
    Parse t2 object.
    
    - parameter data: Dictionary, must be generated parsing "t2".
    - returns: Account object as Thing.
    */
    public init(json data: JSONDictionary) {
        id = data["id"] as? String ?? ""
        hasMail = data["has_mail"] as? Bool ?? false
        isFriend = data["is_friend"] as? Bool ?? false
        name = data["name"] as? String ?? ""
        created = data["created"] as? Int ?? 0
        hideFromRobots = data["hide_from_robots"] as? Bool ?? false
        goldCreddits = data["gold_creddits"] as? Int ?? 0
        createdUtc = data["created_utc"] as? Int ?? 0
        hasModMail = data["has_mod_mail"] as? Bool ?? false
        linkKarma = data["link_karma"] as? Int ?? 0
        commentKarma = data["comment_karma"] as? Int ?? 0
        over18 = data["over_18"] as? Bool ?? false
        isGold = data["is_gold"] as? Bool ?? false
        isMod = data["is_mod"] as? Bool ?? false
        goldExpiration = data["gold_expiration"] as? Bool ?? false
        hasVerifiedEmail = data["has_verified_email"] as? Bool ?? false
        inboxCount = data["inbox_count"] as? Int ?? 0
    }
}

func parseDataInJSON_t2(_ json: JSONAny) -> Result<Thing> {
    if let object = json as? JSONDictionary {
        return Result(fromOptional: Account(json: object), error: ReddiftError.accountJsonObjectIsMalformed as NSError)
    }
    return Result(fromOptional: nil, error: ReddiftError.accountJsonObjectIsNotDictionary as NSError)
}
