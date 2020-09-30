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
    // Returns current network status
    public var isReachable: Bool {
        return reachabilityFlags.contains(.reachable)
    }
    // MARK: Methods
    // Starts initial Monitoring
    public func startFallbackNetworkMonitoring() {
        SCNetworkReachabilityGetFlags(reachabilityHost, &reachabilityFlags)
    }
    
}
