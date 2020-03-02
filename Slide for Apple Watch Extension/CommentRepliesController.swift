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

class CommentRepliesController: WKInterfaceController {
    public var modelContext: CommentsRowController?
    @IBOutlet var commentTable: WKInterfaceTable!
    @IBOutlet var originalTitle: WKInterfaceLabel!
    @IBOutlet var originalBody: WKInterfaceLabel!
    
    override init() {
      super.init()
      self.setTitle("Back")
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

        WCSession.default.sendMessage(["comments": myModel.submissionId!, "context": myModel.id], replyHandler: { (message) in
            self.comments = message["comments"] as? [NSDictionary] ?? []
            self.beginLoadingTable()
        }, errorHandler: { (error) in
            print(error)
        })
    }
        
    var comments = [NSDictionary]()
    func beginLoadingTable() {
        commentTable.insertRows(at: IndexSet(integersIn: 0 ..< comments.count), withRowType: "CommentsRowController")
        
        for index in 0...(comments.count - 1) {
            let item = comments[index]
            if let rowController = commentTable.rowController(at: index) as? CommentsRowController {
                rowController.setData(dictionary: item)
            }
        }
    }
}
