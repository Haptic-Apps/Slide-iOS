//
//  Votable.swift
//  Slide for Apple Watch Extension
//
//  Created by Carlos Crane on 3/5/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import WatchConnectivity
import WatchKit

class Votable: WKInterfaceController {
    weak var sharedUp: WKInterfaceButton?
    weak var sharedDown: WKInterfaceButton?
    weak var sharedReadLater: WKInterfaceButton?
    
    func doVote(id: String, upvote: Bool, downvote: Bool) {
        print("Doing vote")
        WCSession.default.sendMessage(["vote": id, "upvote": upvote, "downvote": downvote], replyHandler: { (result) in
            if result["failed"] == nil {
                WKInterfaceDevice.current().play(.success)
                self.sharedUp?.setBackgroundColor((result["upvoted"] ?? false) as! Bool ? UIColor.init(hexString: "#FF5700") : UIColor.gray)
                self.sharedDown?.setBackgroundColor((result["downvoted"] ?? false) as! Bool ? UIColor.init(hexString: "#9494FF") : UIColor.gray)
            } else {
                WKInterfaceDevice.current().play(.failure)
            }
            self.sharedUp = nil
            self.sharedDown = nil
        }, errorHandler: { (error) in
            print(error)
        })
    }
    
    func doReadLater(id: String, sub: String) {
        WCSession.default.sendMessage(["readlater": id, "sub": sub], replyHandler: { (result) in
            if result["failed"] == nil {
                WKInterfaceDevice.current().play(.success)
                self.sharedReadLater?.setBackgroundColor((result["isReadLater"] ?? false) as! Bool ? UIColor.init(hexString: "#4CAF50") : UIColor.gray)
            } else {
                WKInterfaceDevice.current().play(.failure)
            }
            self.sharedReadLater = nil
        }, errorHandler: { (error) in
            print(error)
        })
    }
}
