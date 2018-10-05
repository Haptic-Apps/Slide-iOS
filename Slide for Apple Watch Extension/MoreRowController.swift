//
//  MoreRowController.swift
//  Slide for Apple Watch Extension
//
//  Created by Carlos Crane on 9/29/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

import CoreGraphics
import Foundation
import UIKit
import WatchKit

public class MoreRowController: NSObject {
    
    var page = 0
    
    @IBOutlet weak var progressImage: WKInterfaceImage!
    @IBOutlet weak var loadButton: WKInterfaceButton!
    @IBAction func doLoadMore() {
        completion()
    }
    
    var completion: () -> Void = {}
}
