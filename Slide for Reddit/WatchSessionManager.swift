//
//  WatchSessionManager.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/24/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//


// https://www.natashatherobot.com/watchconnectivity-say-hello-to-wcsession/
import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    
    static let sharedManager = WatchSessionManager()
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    private var validSession: WCSession? {
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            return session
        }
        return nil
    }
    
    var sub: String?
    
    func startSessionWithSubreddit(sub: String) {
        self.sub = sub
        session?.delegate = self
        session?.activate()
        
        if shelter.dogsLoaded == true {
            updateApplicationContext()
        }
    }
    
    func sessionWatchStateDidChange(session: WCSession) {
        if session.activationState == .activated {
            updateApplicationContext()
        }
    }
    
    // Construct and send the updated application context to the watch.
    func updateApplicationContext() {
        let context = [String: AnyObject]()
        
        // Now, compute the values from your model object to send to the watch.
        do {
            try WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: context)
        } catch {
            print("Error updating application context")
        }
    }
    
}

// MARK: Application Context
extension WatchSessionManager {
    
    // Sender
    func updateApplicationContext(applicationContext: [String : AnyObject]) throws {
        if let session = validSession {
            do {
                try session.updateApplicationContext(applicationContext)
            } catch let error {
                throw error
            }
        }
    }
    
}


// MARK: Interactive Messaging
extension WatchSessionManager {
    
    private var validReachableSession: WCSession? {
        if let session = validSession, session.reachable {
            return session
        }
        return nil
    }
    
    // Receiver
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject],
                 replyHandler: ([String : AnyObject]) -> Void) {
        if message[Key.Request.ApplicationContext] != nil {
            updateApplicationContext()
        }
    }
    
}
