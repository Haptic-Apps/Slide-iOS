//
//  AVAudioSession+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 2/14/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import AVFoundation
import Foundation

extension AVAudioSession {
    /**
     Special version of setCategory that also supports iOS 9.
     */
    func setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) throws {
        if #available(iOS 10.0, *) {
            try AVAudioSession.sharedInstance().setCategory(category, mode: .default, options: options)
        } else {
            // Set category with options (iOS 9+) setCategory(_:options:)
            AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:withOptions:error:"), with: category, with: options)
        }
        print("Set audio mode to \(category.rawValue)")
        try AVAudioSession.sharedInstance().setActive(true)
    }
}
