//
//  InterfaceController.swift
//  Slide for Apple Watch Extension
//
//  Created by Carlos Crane on 9/23/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation
import WatchConnectivity
import WatchKit

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
    var isPro = false
    
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

        table.insertRows(at: IndexSet(integersIn: last ..< links.count), withRowType: "SubmissionRowController")
        
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
            rowController.completion = {[weak self] in
                rowController.progressImage.setImageNamed("Activity")
                rowController.progressImage.startAnimatingWithImages(in: NSRange(location: 0, length: 15), duration: 1.0, repeatCount: 0)
                rowController.loadButton.setTitle("Loading...")
                if let strongSelf = self {
                    strongSelf.getSubmissions(strongSelf.currentSub, reset: false)
                }
            }
        }
    }
    
    func loadData(_ session: WCSession) {
        if session.isReachable {
            checkTimer?.invalidate()
            checkTimer = nil
        } else {
            return
        }
        session.sendMessage(["sublist": true], replyHandler: { (message) in
            self.subs = message["subs"] as? [String: String] ?? [String: String]()
            self.subsOrdered = message["orderedsubs"] as? [String] ?? [String]()
            self.isPro = message["pro"] as? Bool ?? false
            if self.subsOrdered.count > 0 {
                self.getSubmissions(self.subsOrdered[0], reset: true)
            }
        }, errorHandler: { (error) in
            print(error)
        })
    }

    var checkTimer: Timer?
}

extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
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
            if activationState == .activated && session.isReachable {
                loadData(session)
            } else {
                checkTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
                    self.loadData(WCSession.default)
                })
            }
        }
    }
}
