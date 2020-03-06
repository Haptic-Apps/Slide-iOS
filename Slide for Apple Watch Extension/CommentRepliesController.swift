//
//  CommentRepliesController.swift
//  Slide for Apple Watch Extension
//
//  Created by Carlos Crane on 3/1/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import WatchConnectivity
import WatchKit

class CommentRepliesController: Votable {
    public var modelContext: CommentsRowController?
    
    @IBOutlet var originalBody: WKInterfaceLabel!
    @IBOutlet var commentsTable: WKInterfaceTable!
    @IBOutlet var originalTitle: WKInterfaceLabel!
    @IBOutlet var upvoteButton: WKInterfaceButton!
    @IBOutlet var downvoteButton: WKInterfaceButton!
    
    override init() {
      super.init()
      self.setTitle("Back")
    }
    @IBAction func didUpvote() {
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedUp = upvoteButton
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedDown = downvoteButton
        (WKExtension.shared().visibleInterfaceController as? Votable)?.doVote(id: modelContext!.fullname!, upvote: true, downvote: false)
    }
    @IBAction func didDownvote() {
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedUp = upvoteButton
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedDown = downvoteButton
        (WKExtension.shared().visibleInterfaceController as? Votable)?.doVote(id: modelContext!.fullname!, upvote: false, downvote: true)
    }

    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        return table.rowController(at: rowIndex)
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        let myModel = context as! CommentsRowController //make the model
        self.modelContext = myModel
        self.originalTitle.setAttributedText(myModel.attributedTitle)
        self.originalBody.setAttributedText(myModel.attributedBody)
        
        upvoteButton.setBackgroundColor((myModel.dictionary["upvoted"] ?? false) as! Bool ? UIColor.init(hexString: "#FF5700") : UIColor.gray)
        downvoteButton.setBackgroundColor((myModel.dictionary["downvoted"] ?? false) as! Bool ? UIColor.init(hexString: "#9494FF") : UIColor.gray)

        WCSession.default.sendMessage(["comments": myModel.submissionId!, "context": myModel.id!], replyHandler: { (message) in
            self.comments = message["comments"] as? [NSDictionary] ?? []
            self.beginLoadingTable()
        }, errorHandler: { (error) in
            print(error)
        })
    }
        
    var comments = [NSDictionary]()
    func beginLoadingTable() {
        WKInterfaceDevice.current().play(.success)
        
        commentsTable.insertRows(at: IndexSet(integersIn: 0 ..< comments.count), withRowType: "CommentsRowController")
        if comments.count > 0 {
            for index in 0...(comments.count - 1) {
                let item = comments[index]
                if let rowController = commentsTable.rowController(at: index) as? CommentsRowController {
                    rowController.setData(dictionary: item)
                }
            }
        }
    }
}
