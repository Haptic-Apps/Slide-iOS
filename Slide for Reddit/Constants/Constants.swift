//
//  Constants.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 9/30/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation

class Constants {
    // Shared property
    public static let shared = Constants()
    // MARK: - Network
    // Returns network status for any iOS Version.
    public var isNetworkOnline: Bool {
        if #available(iOS 12.0, *) {
            print("12.0+")
            return NetworkMonitor.shared.online
        } else {
            return false
        }
    }
    
}
