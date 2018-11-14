//
//  NSDate+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 11/14/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

extension Date {
    var timeAgoString: String? {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]

        guard let timeString = formatter.string(from: self, to: Date()) else {
            return nil
        }

        let formatString = NSLocalizedString("%@ ago", comment: "")
        return String(format: formatString, timeString)
    }
}
