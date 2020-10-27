//
//  FallbackNetworkMonitor.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 9/29/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import SystemConfiguration

// MARK: - Reachability Status
enum ReachabilityStatus {
    case transientConnection
    case connectionRequired
    case connectionOnTraffic
    case interventionRequired
    case connectionOnDemand
    case isLocalAddress
    case isDirect
    case isWWAN
    case connectionAutomatic
}

final class FallbackNetworkMonitor {
    // MARK: - References / Properties
    /// FallbackNetworkMonitor Singleton
    public static let shared = FallbackNetworkMonitor()
    /// Stops network monitoring
    deinit {
        stopFallbackNetworkMonitor()
    }
    /// Instantiating a SCNetworkReachability Object using hostname.
    private var reachability: SCNetworkReachability = SCNetworkReachabilityCreateWithName(nil, "www.reddit.com")!
    /// Creates the flags which get status of network.
    private var reachabilityFlags = SCNetworkReachabilityFlags()
    /// Queue for Reachability to run.
    private let reachabilityQueue = DispatchQueue.global(qos: .background)
    /// Fallback Online notification
    private var fallbackOnlineNotification = NotificationCenter.default
    /// Assigns the current flag options for network.
    public  private(set) var currentReachabilityFlags: SCNetworkReachabilityFlags = []
    /// Checks if reachability is actively listening.
    public var isListening: Bool = false {
        didSet {
            guard isListening != oldValue else { return }
            // If set to true it will start monitoring. Otherwise it can be switched.
            isListening ? startFallbackNetworkMonitoring() : stopFallbackNetworkMonitor()
        }
    }
    /// Returns current network status.
    public var isReachabilityOnline: Bool {
        get {
            // Used for testing on device if network changes.
            print("Fallback Online: \(currentReachabilityFlags.contains(.reachable))")
            // Returns if current network status.
            return currentReachabilityFlags.contains(.reachable)
        }
        set {
        }
    }
    /// Can check and return reachability status's.
    public var currentReachabilityStatus: ReachabilityStatus {
        if currentReachabilityFlags.contains(.transientConnection) == true {
            return .transientConnection
        } else if currentReachabilityFlags.contains(.connectionRequired) == true {
            return .connectionRequired
        } else if currentReachabilityFlags.contains(.connectionOnTraffic) == true {
            return .connectionOnTraffic
        } else if currentReachabilityFlags.contains(.interventionRequired) == true {
            return .interventionRequired
        } else if currentReachabilityFlags.contains(.connectionOnDemand) == true {
            return .connectionOnDemand
        } else if currentReachabilityFlags.contains(.isLocalAddress) == true {
            return .isLocalAddress
        } else if currentReachabilityFlags.contains(.isDirect) == true {
            return .isDirect
        } else if currentReachabilityFlags.contains(.isWWAN) == true {
            return .isWWAN
        } else {
            return .connectionAutomatic
        }
    }
    // MARK: - Methods
    /// Used to start monitoring Network changes.
    public func startFallbackNetworkMonitoring() {
        // Checks if SCNetworkReachability is already active.
        guard !isListening else { return }
        //
        let selfReference = UnsafeMutableRawPointer(Unmanaged<FallbackNetworkMonitor>.passUnretained(self).toOpaque())
        // Creates a context for SCNetworkReachability.
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        // Provides info to FallbackNetworkMonitor.
        context.info = selfReference
        // Closure used to get back info on Network.
        let callbackClosure: SCNetworkReachabilityCallBack? = { (_, flags, info) in
            guard let info = info else { return }
            print("Inside closure: \(flags.contains(.reachable))")
            Unmanaged<FallbackNetworkMonitor>.fromOpaque(info).takeUnretainedValue().reachabilityQueue.async {
                // Needed since this callback is a C pointer which cannot capture context.
                Unmanaged<FallbackNetworkMonitor>.fromOpaque(info).takeUnretainedValue().reachabilityDidChange(flags: flags)
            }
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
    private func reachabilityDidChange(flags: SCNetworkReachabilityFlags) {
        // Checks that current flag isn't the same as before, otherwise return.
        guard currentReachabilityFlags != flags else { return }
        // Assigns current flag info to current.
        currentReachabilityFlags = flags
        // Checks if current flag info is Online.
        let fallbackOnline = currentReachabilityFlags.contains(.reachable)
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
            // Calls did change to update flags
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
