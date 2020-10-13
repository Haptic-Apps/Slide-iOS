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
    // MARK: References / Properties
    // Shared constant
    public static let shared = FallbackNetworkMonitor()
    // Instantiating a SCNetworkReachability Object using hostname.
    private let reachabilityHost = SCNetworkReachabilityCreateWithName(nil, "www.reddit.com")
    // Creates the flags which get status of network
    private var reachabilityFlags = SCNetworkReachabilityFlags()
    // Queue for Reachability to run.
    private let reachabilityQueue = DispatchQueue.global(qos: .background)
    //
    private var currentReachabilityFlags: SCNetworkReachabilityFlags?
    //
    private var callbackClosure: SCNetworkReachabilityCallBack?
    // Checks if reachability is listening.
    private var isListening: Bool = false
    /// Online notification
    private var fallbackOnlineNotification = NotificationCenter.default
    // Returns current network status
    public var isReachable: Bool {
        print("Fallback Online: \(reachabilityFlags.contains(.reachable))")
        return reachabilityFlags.contains(.reachable)
    }
    // MARK: Methods
    // Starts initial Monitoring
    public func startFallbackNetworkMonitoring() {
        //
        guard !isListening, let reachability = reachabilityHost else { print("SCNetworkReachabilityCreateWithName error!"); return }
        //
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        //
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        //
        SCNetworkReachabilitySetCallback(reachability, { (_, flags, info) in
            if let info = info {
                // No internet
                if flags.rawValue == 0 {
                    
                } else { // Internet has changed.
                    let fallbackMonitor = Unmanaged<FallbackNetworkMonitor>.fromOpaque(info).takeUnretainedValue()
                    fallbackMonitor.reachabilityQueue.async {
                        fallbackMonitor.checkReachability(flags: flags)
                    }
                }
            }
        }, &context)
        //
        callUpdate(with: reachability)
        //
        isListening = true
    }
    
    //
    public func checkReachability(flags: SCNetworkReachabilityFlags) {
        //
        guard currentReachabilityFlags != flags, isListening == true else { return }
        //
        currentReachabilityFlags = flags
        //
        let fallbackOnline = currentReachabilityFlags?.rawValue != 1
        //
        let fallbackOnlineDictionary = ["fallbackOnline": fallbackOnline]
        //
        fallbackOnlineNotification.post(name: .fallbackOnline, object: nil, userInfo: fallbackOnlineDictionary)
    }
    
    //
    private func callUpdate(with reachability: SCNetworkReachability) {
        reachabilityQueue.async {
            //
            self.currentReachabilityFlags = nil
            //
            var flags = SCNetworkReachabilityFlags()
            //
            SCNetworkReachabilityGetFlags(reachability, &flags)
            self.checkReachability(flags: flags)
        }
    }
    
    //
    public func stopFallbackNetworkMonitor() {
        guard isListening, let reachability = reachabilityHost else { return }
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        isListening = false
    }
    
}
