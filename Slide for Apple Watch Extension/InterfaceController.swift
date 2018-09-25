//
//  InterfaceController.swift
//  Slide for Apple Watch Extension
//
//  Created by Carlos Crane on 9/23/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var table: WKInterfaceTable!
    @IBOutlet weak var loadingImage: WKInterfaceImage!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    @IBAction func onMenuItemPlayTap() {
        print("Play Tapped")
    }
    
    var links = [NSDictionary]()
    var subs = [String: String]()
    var subsOrdered = [String]()
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let watchSession = WCSession.default
        watchSession.delegate = self
        watchSession.activate()
        if subs.isEmpty {
            loadingImage.setImageNamed("Activity")
            loadingImage.startAnimatingWithImages(in: NSRange(location: 0, length: 15), duration: 1.0, repeatCount: 0)
            watchSession.sendMessage(["sublist": true], replyHandler: { (message) in
                self.subs = message["subs"] as? [String: String] ?? [String: String]()
                if self.subs.count > 0 {
                    self.subsOrdered = Array(self.subs.keys).sorted(by: { (a, b) -> Bool in
                        return a.lowercased() < b.lowercased()
                    })
                    self.subsOrdered = self.subsOrdered.filter({ (a) -> Bool in
                        !a.startsWith("/")
                    })
                    self.getSubmissions(self.subsOrdered[0])
                }
            }) { (error) in
                print(error)
            }
        }
    }
    
    @IBAction func gotosub() {
        presentTextInputController(withSuggestions: subsOrdered, allowedInputMode: .plain) { (subs) in
            self.getSubmissions((subs ?? ["all"])[0] as! String)
        }
    }
    
    func getSubmissions(_ subreddit: String) {
        self.loadingImage.setHidden(false)
        DispatchQueue.main.async {
            self.setTitle("r/\(subreddit)")
            self.table.setNumberOfRows(0, withRowType: "SubmissionRowController")
        }
        WCSession.default.sendMessage(["links": subreddit], replyHandler: { (message) in
            self.loadingImage.setHidden(true)
            if let links = message["links"] as? [NSDictionary] {
                self.links = links
            }
            self.beginLoadingTable()
        }) { (error) in
            print(error)
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func beginLoadingTable() {
        table.setNumberOfRows(links.count, withRowType: "SubmissionRowController")
        var index = 0
        for item in links {
            if let rowController = table.rowController(at: index) as? SubmissionRowController {
                rowController.parent = self
                rowController.setData(dictionary: item, color: UIColor(hexString: self.subs[item["subreddit"] as? String ?? ""] ?? "#ffffff"))
            }
            index += 1
        }
    }

}

extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("Doing links")
        DispatchQueue.main.async {
            self.setTitle(applicationContext["title"] as? String)
            self.beginLoadingTable()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
}


extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
