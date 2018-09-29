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

    var links = [NSDictionary]()
    var subs = [String: String]()
    var subsOrdered = [String]()
    var page = 1
    var last = 0
    var currentSub = ""
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let watchSession = WCSession.default
        watchSession.delegate = self
        watchSession.activate()
    }
    
    @IBAction func gotosub() {
        presentTextInputController(withSuggestions: subsOrdered, allowedInputMode: .plain) { (subs) in
            self.getSubmissions((subs ?? ["all"])[0] as! String, reset: true)
        }
    }
    
    func getSubmissions(_ subreddit: String, reset: Bool) {
        currentSub = subreddit
        if reset {
            self.page = 1
            self.last = 0
            self.loadingImage.setHidden(false)
            self.links.removeAll()
            DispatchQueue.main.async {
                self.setTitle("r/\(subreddit)")
                self.table.setNumberOfRows(0, withRowType: "SubmissionRowController")
            }
        }
        WCSession.default.sendMessage(["links": subreddit, "reset": reset], replyHandler: { (message) in
            self.loadingImage.setHidden(true)
            if let newLinks = message["links"] as? [NSDictionary] {
                self.links.append(contentsOf: newLinks)
            }
            self.beginLoadingTable()
        }, errorHandler: { (error) in
            print(error)
        })
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func beginLoadingTable() {
        page += 1
        if page > 1 {
            table.removeRows(at: IndexSet(integer: last))
        }

        table.insertRows(at: IndexSet(integersIn: last...(links.count - 1)), withRowType: "SubmissionRowController")
        
        for index in last...(links.count - 1) {
            let item = links[index]
            if let rowController = table.rowController(at: index) as? SubmissionRowController {
                rowController.parent = self
                rowController.setData(dictionary: item, color: UIColor(hexString: self.subs[item["subreddit"] as? String ?? ""] ?? "#ffffff"))
            }
        }
        
        last = links.count
        table.insertRows(at: IndexSet(integer: links.count), withRowType: "MoreRowController")
        if let rowController = table.rowController(at: links.count) as? MoreRowController {
            rowController.loadButton.setTitle("Load page \(page)")
            rowController.completion = {
                rowController.progressImage.setImageNamed("Activity")
                rowController.progressImage.startAnimatingWithImages(in: NSRange(location: 0, length: 15), duration: 1.0, repeatCount: 0)
                rowController.loadButton.setTitle("Loading...")

                self.getSubmissions(self.currentSub, reset: false)
            }
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
        if subs.isEmpty {
            loadingImage.setHidden(false)
            loadingImage.setImageNamed("Activity")
            loadingImage.startAnimatingWithImages(in: NSRange(location: 0, length: 15), duration: 1.0, repeatCount: 0)
            session.sendMessage(["sublist": true], replyHandler: { (message) in
                self.subs = message["subs"] as? [String: String] ?? [String: String]()
                self.subsOrdered = message["orderedsubs"] as? [String] ?? [String]()
                if self.subsOrdered.count > 0 {
                    self.getSubmissions(self.subsOrdered[0], reset: true)
                }
            }, errorHandler: { (error) in
                print(error)
            })
        }
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
