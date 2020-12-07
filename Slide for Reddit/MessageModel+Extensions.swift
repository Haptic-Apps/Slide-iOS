//
//  MessageModel+Extensions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/6/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation
import reddift

public extension MessageModel {
    static func messageToMessageModel(message: Message) -> MessageModel {
        let managedContext = SlideCoreData.sharedInstance.backgroundContext
        let messageEntity = NSEntityDescription.entity(forEntityName: "MessageModel", in: managedContext)!
        let messageModel = NSManagedObject(entity: messageEntity, insertInto: managedContext) as! MessageModel

        let title = message.baseJson["link_title"] as? String ?? ""
        var bodyHtml = message.bodyHtml.replacingOccurrences(of: "<blockquote>", with: "<cite>").replacingOccurrences(of: "</blockquote>", with: "</cite>")
        bodyHtml = bodyHtml.replacingOccurrences(of: "<div class=\"md\">", with: "")
        messageModel.htmlBody = bodyHtml
        messageModel.name = message.name
        messageModel.id = message.getId()
        
        messageModel.author = message.author
        messageModel.subreddit = message.subreddit
        messageModel.created = Date(timeIntervalSince1970: TimeInterval(message.createdUtc))
        messageModel.isNew = message.new
        messageModel.submissionTitle = title
        messageModel.context = message.context
        messageModel.wasComment = message.wasComment
        messageModel.subject = message.subject
        
        //TODO do we want to save messages in CoreData?
        return messageModel
    }
}
