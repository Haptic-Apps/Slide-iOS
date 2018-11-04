//
//  ProInterfaceController.swift
//  Slide for Apple Watch Extension
//
//  Created by Carlos Crane on 11/4/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import WatchConnectivity
import WatchKit

class ProInterfaceController: WKInterfaceController {
    
    @IBAction func openPro() {
        WCSession.default.sendMessage(["pro": true], replyHandler: { (_) in
        }, errorHandler: { (error) in
            print(error)
        })
    }
}
