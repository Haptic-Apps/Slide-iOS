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

class PostActionMenuController: WKInterfaceController {
    @IBOutlet weak var bannerImage: WKInterfaceImage!
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var scoreLabel: WKInterfaceLabel!
    @IBOutlet weak var commentLabel: WKInterfaceLabel!
    @IBOutlet weak var imageGroup: WKInterfaceGroup!
    public var modelContext: SubmissionRowController?
    public var parent: InterfaceController?

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
    @IBAction func doUpvote() {
        WCSession.default.sendMessage(["upvote": modelContext!.id!], replyHandler: { (result) in
            if result["failed"] == nil {
                self.dismiss()
            }
        }, errorHandler: { (error) in
            print(error)
        })
    }
    
    override init() {
        super.init()
        self.setTitle("Back")
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        let myModel = context as! SubmissionRowController //make the model
        self.modelContext = myModel
        self.parent = (context as? SubmissionRowController)?.parent
        titleLabel.setAttributedText(myModel.titleText)
        bannerImage.setImage(myModel.thumbnail)
        imageGroup.setCornerRadius(5)
        
        scoreLabel.setText(myModel.scoreText)
        commentLabel.setText(myModel.commentText)

    }
}
