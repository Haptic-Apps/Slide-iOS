//
//  Constants.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 9/30/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation

enum NetworkInterfaceTypes {
    case cellular
    case wifi
    case other
    case notAvailable
}

class Constants {
    // Shared property
    public static let shared = Constants()
    // MARK: - Network
    
    /// Returns network status for any iOS Version.
    public var isNetworkOnline: Bool {
        if #available(iOS 12.0, *) {
            return NetworkMonitor.shared.online
        } else {
            return FallbackNetworkMonitor.shared.isReachabilityOnline
        }
    }
    
    /// Get interface type of connection.
    public var networkInterfaceType: NetworkInterfaceTypes {
        if #available(iOS 12.0, *) {
            guard let networkManagerInterfaceType = NetworkMonitor.shared.interfaceType else { return .notAvailable }
            if networkManagerInterfaceType == .wifi {
                return .wifi
            } else if networkManagerInterfaceType == .cellular {
                return .cellular
            } else if networkManagerInterfaceType == .other {
                return .other
            } else if networkManagerInterfaceType == .loopback {
                return .other
            }
        } else {
            let fallbackNetworkManagerInterfaceType = FallbackNetworkMonitor.shared.currentReachabilityStatus
            if fallbackNetworkManagerInterfaceType == .isWWAN {
                return .cellular
            } else if fallbackNetworkManagerInterfaceType == .isLocalAddress {
                return .wifi
            } else if fallbackNetworkManagerInterfaceType == .isDirect {
                return .other
            }
        }
        return .notAvailable
    }
    
}
