//
//  Message.swift
//  reddift
//
//  Created by generator.rb via from https://github.com/reddit/reddit/wiki/JSON
//  Created at 2015-04-15 11:23:32 +0900
//

import Foundation

/**
Message object.
*/
public struct Message: Thing {
    /// identifier of Thing like 15bfi0.
    public let id: String
    /// name of Thing, that is fullname, like t3_15bfi0.
    public let name: String
    /// type of Thing, like t3.
    public static let kind = "t4"
    
    /**
    the message itself
    example: Hello! [Hola!](http....
    */
    public let  body: String
    /**
    
    example: false
    */
    public let wasComment: Bool
    /**
    
    example:
    */
    public let firstMessage: String
    /**
    either null or the first message's fullname
    example:
    */
    public let firstMessageName: String
    /**
    
    example: 1427126074
    */
    public let  created: Int
    /**
    
    example: sonson_twit
    */
    public let  dest: String
    /**
    
    example: reddit
    */
    public let  author: String
    /**
    
    example: 1427122474
    */
    public let createdUtc: Int
    /**
    the message itself with HTML formatting
    example: &lt;!-- SC_OFF --&gt;&l....
    */
    public let bodyHtml: String
    /**
    null if not a comment.
    example:
    */
    public let  subreddit: String
    /**
    null if no parent is attached
    example:
    */
    public let parentId: String
    /**
    if the message is a comment, then the permalink to the comment with ?context=3 appended to the end, otherwise an empty string
    example:
    */
    public let  context: String
    /**
    Again, an empty string if there are no replies.
    example:
    */
    public let  replies: String
    /**
    unread?  not sure
    example: false
    */
    public let  new: Bool
    /**
    
    example: admin
    */
    public let  distinguished: String
    /**
    subject of message
    example: Hello, /u/sonson_twit! Welcome to reddit!
    */
    public let  subject: String
    
    public init(id: String) {
        self.id = id
        self.name = "\(Message.kind)_\(self.id)"
        
        body = ""
        wasComment = false
        firstMessage = ""
        firstMessageName = ""
        created = 0
        dest = ""
        author = ""
        createdUtc = 0
        bodyHtml = ""
        subreddit = ""
        parentId = ""
        context = ""
        replies = ""
        new = false
        distinguished = ""
        subject = ""
    }
    
    /**
    Parse t4 object.
    
    - parameter data: Dictionary, must be generated parsing "t4".
    - returns: Message object as Thing.
    */
    public init(json data: JSONDictionary) {
        id = data["id"] as? String ?? ""
        body = data["body"] as? String ?? ""
        wasComment = data["was_comment"] as? Bool ?? false
        firstMessage = data["first_message"] as? String ?? ""
        name = data["name"] as? String ?? ""
        firstMessageName = data["first_message_name"] as? String ?? ""
        created = data["created"] as? Int ?? 0
        dest = data["dest"] as? String ?? ""
        author = data["author"] as? String ?? ""
        createdUtc = data["created_utc"] as? Int ?? 0
        let tempBodyHtml = data["body_html"] as? String ?? ""
        bodyHtml = tempBodyHtml.gtm_stringByUnescapingFromHTML()
        subreddit = data["subreddit"] as? String ?? ""
        parentId = data["parent_id"] as? String ?? ""
        context = data["context"] as? String ?? ""
        replies = data["replies"] as? String ?? ""
        new = data["new"] as? Bool ?? false
        distinguished = data["distinguished"] as? String ?? ""
        subject = data["subject"] as? String ?? ""
    }
}
