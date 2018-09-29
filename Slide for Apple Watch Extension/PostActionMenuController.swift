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

    @IBAction func openComments() {
    }
    @IBAction func readLater() {
        WCSession.default.sendMessage(["readlater": modelContext!.id!, "sub" : modelContext!.sub!], replyHandler: { (message) in
            self.dismiss()
        }, errorHandler: { (error) in
            print(error)
        })
    }
    @IBAction func doUpvote() {
    }
    
    override init () {
        super.init ()
        self.setTitle("Back")
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        let myModel = context as! SubmissionRowController //make the model
        self.modelContext = myModel
        titleLabel.setAttributedText(myModel.titleText)
        bannerImage.setImage(myModel.thumbnail)
        imageGroup.setCornerRadius(5)
    }
}
