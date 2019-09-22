//
//  ConversationViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/21/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import UIKit
import MessengerKit

class ConversationViewController: MSGMessengerViewController {
    var thread: RThread
    let user: RedditMessageUser
    let recipient: RedditMessageUser
    var messages: [[RMessage]]

    init(message: RThread) {
        self.thread = message
        self.messages = [[]]
        self.user = RedditMessageUser(displayName: AccountController.currentName, avatar: nil, isSender: true)
        self.recipient = RedditMessageUser(displayName: thread.author, avatar: nil, isSender: false)
        super.init(nibName: nil, bundle: nil)
        self.title = thread.subject
        let sorted = self.thread.messages.sorted { (first, second) -> Bool in
            return first.created.timeIntervalSince1970 > second.created.timeIntervalSince1970
        }
        self.messages = sorted.reduce(into: []) {
            if $0.last?.last?.author == $1.author {
                $0[$0.index(before: $0.endIndex)].append($1)
            } else {
                $0.append([$1])
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension ConversationViewController: MSGDataSource {
    
    func numberOfSections() -> Int {
        return messages.count
    }
    
    func numberOfMessages(in section: Int) -> Int {
        return messages[section].count
    }
    
    func message(for indexPath: IndexPath) -> MSGMessage {
        let rMessage = messages[indexPath.section][indexPath.item]
        return MSGMessage(id: (indexPath.section * 100) + indexPath.row, body: MSGMessageBody.custom(rMessage.htmlBody), user: rMessage.author == user.displayName ? user : recipient, sentAt: rMessage.created as Date)
    }
    
    func footerTitle(for section: Int) -> String? {
        return ""
    }
    
    func headerTitle(for section: Int) -> String? {
        return messages[section].first?.author
    }

}

public class RedditMessageUser: MSGUser {
    public var displayName: String
    
    public var avatar: UIImage?
    
    public var isSender: Bool
    
    init(displayName: String, avatar: UIImage?, isSender: Bool) {
        self.displayName = displayName
        self.avatar = avatar
        self.isSender = isSender
    }
    
}

class TextDisplayMessageCollectionView: MSGImessageCollectionView {

    override func registerCells() {
        super.registerCells()
        
        register(UINib(nibName: "CustomOutgoingTextCell", bundle: nil), forCellWithReuseIdentifier: "outgoingText")
        register(UINib(nibName: "CustomIncomingTextCell", bundle: nil), forCellWithReuseIdentifier: "incomingText")
    }

}

struct SlideStyle: MSGMessengerStyle {
    var collectionView: MSGCollectionView.Type = TextDisplayMessageCollectionView.self
    
    var inputView: MSGInputView.Type = MSGImessageInputView.self
    
    var headerHeight: CGFloat = 0
    
    var footerHeight: CGFloat = 0
    
    var backgroundColor: UIColor = ColorUtil.theme.backgroundColor
    
    var inputViewBackgroundColor: UIColor = ColorUtil.theme.foregroundColor
    
    var font: UIFont = .preferredFont(forTextStyle: .body)
    
    var inputFont: UIFont = .systemFont(ofSize: 14)
    
    var inputPlaceholder: String = "Reply..."
    
    var inputTextColor: UIColor = ColorUtil.theme.fontColor
    
    var inputPlaceholderTextColor: UIColor = ColorUtil.theme.fontColor.withAlphaComponent(0.8)
    
    var outgoingTextColor: UIColor = .white
    
    var outgoingLinkColor: UIColor = ColorUtil.baseAccent
    
    var incomingTextColor: UIColor = ColorUtil.theme.fontColor
    
    var incomingLinkColor: UIColor = ColorUtil.baseAccent
    
    func size(for message: MSGMessage, in collectionView: UICollectionView) -> CGSize {
        var size: CGSize!
        
        switch message.body {
        case .text(let body):
            
            let bubble = CustomBubble()
            bubble.text = body
            bubble.font = font
            let bubbleSize = bubble.calculatedSize(in: CGSize(width: collectionView.bounds.width, height: .infinity))
            size = CGSize(width: collectionView.bounds.width, height: bubbleSize.height)
            
            break
            
            
        case .emoji:
            
            size = CGSize(width: collectionView.bounds.width, height: 60)
            
            break
            
        default:
            
            size = CGSize(width: collectionView.bounds.width, height: 175)
            
            break
        }
        
        return size
    }
    
    // MARK - Custom Properties
    
    var incomingBorderColor: UIColor = .white
    
    var outgoingBorderColor: UIColor = UIColor(hue:0.91, saturation:0.70, brightness:0.85, alpha:1.00)
    
}
