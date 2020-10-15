//
//  FallbackNetworkMonitor.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 9/29/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import SystemConfiguration

final class FallbackNetworkMonitor {
    // MARK: - References / Properties
    /// FallbackNetworkMonitor Singleton
    public static let shared = FallbackNetworkMonitor()
    /// Initializes the monitor with a host.
    /// - Parameter host: url as string used as a reference point.
    init(host: String = "www.reddit.com") {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else { fatalError("Failed to activate SCNetworkReachability.") }
        self.reachability = reachability
        self.callUpdate()
    }
    /// Stops network monitoring
    deinit {
        stopFallbackNetworkMonitor()
    }
    /// Instantiating a SCNetworkReachability Object using hostname.
    private var reachability: SCNetworkReachability
    /// Creates the flags which get status of network.
    private var reachabilityFlags = SCNetworkReachabilityFlags()
    /// Queue for Reachability to run.
    private let reachabilityQueue = DispatchQueue.global(qos: .background)
    /// Assigns the current flag options for network.
    private var currentReachabilityFlags: SCNetworkReachabilityFlags?
    /// Checks if reachability is actively listening.
    public var isListening: Bool = false {
        didSet {
            guard isListening != oldValue else { return }
            // If set to true it will start monitoring. Otherwise it can be switched.
            isListening ? startFallbackNetworkMonitoring() : stopFallbackNetworkMonitor()
        }
    }
    /// Fallback Online notification
    private var fallbackOnlineNotification = NotificationCenter.default
    /// Returns current network status.
    public var isReachabilityOnline: Bool {
        get {
            guard let currentReachabilityFlags = currentReachabilityFlags else { return false }
            // Used for testing on device if network changes.
            print("Fallback Online: \(currentReachabilityFlags.contains(.reachable))")
            return currentReachabilityFlags.contains(.reachable)
        }
        set {
        }
    }
    // MARK: - Methods
    /// Used to start monitoring Network changes.
    public func startFallbackNetworkMonitoring() {
        // Makes sure there are no nil objects and isListening is active.
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, "www.reddit.com"), !isListening else { print("SCNetworkReachabilityCreateWithName error!"); return }
        // Creates a context for SCNetworkReachability.
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        // Provides info to FallbackNetworkMonitor.
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        // Closure used to get back info on Network.
        let callbackClosure: SCNetworkReachabilityCallBack? = { (_, flags, info) in
            guard let info = info else { return }
            Unmanaged<FallbackNetworkMonitor>.fromOpaque(info).takeUnretainedValue().reachabilityDidChange(flags: flags)
        }
        // Checks if received data is not nil.
        if !SCNetworkReachabilitySetCallback(reachability, callbackClosure, &context) {
            fatalError("Cannot reach service because SCNetworkReachabilitySetCallback failed!")
        }
        // Checks if there is a Queue available.
        if !SCNetworkReachabilitySetDispatchQueue(reachability, reachabilityQueue) {
            fatalError("Cannot reach service because SCNetworkReachabilitySetDispatchQueue failed!")
        }
        // Calls updating.
        callUpdate()
        // Assigns isListening to true if everything is correct.
        isListening = true
    }
    /// Used to update flags that Network has experienced changes.
    /// - Parameter flags: SCNetworkReachabilityFlags
    public func reachabilityDidChange(flags: SCNetworkReachabilityFlags) {
        // Checks that current flag isn't the same as before, otherwise return.
        guard currentReachabilityFlags != flags else { return }
        // Assigns current flag info to current.
        currentReachabilityFlags = flags
        // Checks if current flag info is Online.
        guard let fallbackOnline = currentReachabilityFlags?.contains(.reachable) else { return }
        print("Raw fallback Online: \(fallbackOnline)")
        // Assigns info to a dictionary for Notification.
        let fallbackOnlineDictionary = ["fallbackOnline": fallbackOnline]
        //  Assigns Notification to current info.
        fallbackOnlineNotification.post(name: .fallbackOnline, object: nil, userInfo: fallbackOnlineDictionary)
    }
    
    /// Called when an update or change has occurred.
    private func callUpdate() {
        reachabilityQueue.async {
            // Creates new flag.
            var flags = SCNetworkReachabilityFlags()
            // Assigns new flag for reachability.
            SCNetworkReachabilityGetFlags(self.reachability, &flags)
            self.reachabilityDidChange(flags: flags)
        }
    }
    
    /// Stops the network monitoring.
    public func stopFallbackNetworkMonitor() {
        // Cancels Reachability data receiving.
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        // Cancels Reachability queue.
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        // Stops listening.
        isListening = false
    }
    
}
