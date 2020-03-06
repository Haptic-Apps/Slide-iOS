//
//  PostActionMenuController.swift
//  Slide for Apple Watch Extension
//
//  Created by Carlos Crane on 9/24/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation
import WatchConnectivity
import WatchKit

class PostActionMenuController: Votable {
    @IBOutlet weak var bannerImage: WKInterfaceImage!
    @IBOutlet var commentTable: WKInterfaceTable!
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var scoreLabel: WKInterfaceLabel!
    @IBOutlet weak var commentLabel: WKInterfaceLabel!
    @IBOutlet weak var imageGroup: WKInterfaceGroup!
    public var modelContext: SubmissionRowController?
    public var parent: InterfaceController?
    @IBOutlet var thumbImage: WKInterfaceImage!
    @IBOutlet var thumbGroup: WKInterfaceGroup!
    @IBOutlet var upvoteButton: WKInterfaceButton!
    @IBOutlet var downvoteButton: WKInterfaceButton!
    @IBOutlet var linkInfo: WKInterfaceLabel!
    var id: String?
    @IBAction func didUpvote() {
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedUp = upvoteButton
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedDown = downvoteButton
        (WKExtension.shared().visibleInterfaceController as? Votable)?.doVote(id: id!, upvote: true, downvote: false)
    }
    @IBAction func didDownvote() {
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedUp = upvoteButton
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedDown = downvoteButton
        (WKExtension.shared().visibleInterfaceController as? Votable)?.doVote(id: id!, upvote: false, downvote: true)
    }

    @IBAction func openComments() {
//        if !(self.parent?.isPro ?? true) {
//            self.parent?.presentController(withName: "Pro", context: parent!)
//        } else {
            WCSession.default.sendMessage(["comments": modelContext!.id!], replyHandler: { (_) in
            }, errorHandler: { (error) in
                print(error)
            })
//        }
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        return table.rowController(at: rowIndex)
    }

    @IBAction func readLater() {
//        if !(self.parent?.isPro ?? true) {
//            self.parent?.presentController(withName: "Pro", context: parent!)
//        } else {
            WCSession.default.sendMessage(["readlater": modelContext!.id!, "sub": modelContext!.sub!], replyHandler: { (_) in
                self.dismiss()
            }, errorHandler: { (error) in
                print(error)
            })
//        }
    }

    override init() {
        super.init()
        self.setTitle("Back")
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        let myModel = context as! SubmissionRowController //make the model
        self.modelContext = myModel
        titleLabel.setAttributedText(myModel.titleText)
        if myModel.thumbnail == nil && myModel.largeimage != nil {
            bannerImage.setImage(myModel.largeimage)
            bannerImage.setHidden(false)
            thumbGroup.setHidden(true)
        } else if myModel.thumbnail != nil {
            thumbImage.setImage(myModel.thumbnail)
            bannerImage.setHidden(true)
            thumbGroup.setHidden(false)
        } else {
            bannerImage.setHidden(true)
            thumbGroup.setHidden(true)
        }
        imageGroup.setCornerRadius(5)
        
        upvoteButton.setBackgroundColor((myModel.dictionary["upvoted"] ?? false) as! Bool ? UIColor.init(hexString: "#FF5700") : UIColor.gray)
        downvoteButton.setBackgroundColor((myModel.dictionary["downvoted"] ?? false) as! Bool ? UIColor.init(hexString: "#9494FF") : UIColor.gray)

        scoreLabel.setText(myModel.scoreText)
        id = myModel.id
        commentLabel.setText(myModel.commentText)
        WCSession.default.sendMessage(["comments": myModel.id!], replyHandler: { (message) in
            self.comments = message["comments"] as? [NSDictionary] ?? []
            self.beginLoadingTable()
        }, errorHandler: { (error) in
            print(error)
        })
    }
        
    var comments = [NSDictionary]()
    func beginLoadingTable() {
        WKInterfaceDevice.current().play(.success)

        commentTable.insertRows(at: IndexSet(integersIn: 0 ..< comments.count), withRowType: "CommentsRowController")
        
        if comments.count > 0 {
            for index in 0...(comments.count - 1) {
                let item = comments[index]
                if let rowController = commentTable.rowController(at: index) as? CommentsRowController {
                    rowController.setData(dictionary: item)
                }
            }
        }
    }
}
