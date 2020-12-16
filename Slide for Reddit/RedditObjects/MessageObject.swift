//
//  MessageObject.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/7/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

class MessageObject: RedditObject {
    public var author: String
    public var created: Date
    public var htmlBody: String
    public var id: String
    public var markdownBody: String
    public var name: String
    public var submissionTitle: String?
    public var subreddit: String
    public var subject: String
    public var context: String?
    public var isNew: Bool
    public var wasComment: Bool

    static func messageToMessageObject(message: Message) -> MessageObject {
        return MessageObject(message: message)
    }

    public init(message: Message) {
        let title = message.baseJson["link_title"] as? String ?? ""
        var bodyHtml = message.bodyHtml.replacingOccurrences(of: "<blockquote>", with: "<cite>").replacingOccurrences(of: "</blockquote>", with: "</cite>")

        self.htmlBody = bodyHtml
        self.name = message.name
        self.id = message.getId()
        self.markdownBody = message.body
        self.author = message.author
        self.subreddit = message.subreddit
        self.created = Date(timeIntervalSince1970: TimeInterval(message.createdUtc))
        self.isNew = message.new
        self.submissionTitle = title
        self.context = message.context
        self.wasComment = message.wasComment
        self.subject = message.subject
    }
}
