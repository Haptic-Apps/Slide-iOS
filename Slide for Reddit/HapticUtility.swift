//
//  HapticUtility.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/25/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import AudioToolbox.AudioServices
import UIKit

//https://medium.com/@sdrzn/make-your-ios-app-feel-better-a-comprehensive-guide-over-taptic-engine-and-haptic-feedback-724dec425f10
public class HapticUtility {
    
    static let peek = SystemSoundID(1519)
    static let pop = SystemSoundID(1520)
    static let cancelled = SystemSoundID(1521)
    static let tryAgain = SystemSoundID(1102)
    static let failed = SystemSoundID(1107)
    
    @available(iOS 10.0, *)
    static let impactFeedbackGenerator: (
        light: UIImpactFeedbackGenerator,
        medium: UIImpactFeedbackGenerator,
        heavy: UIImpactFeedbackGenerator) = (
            UIImpactFeedbackGenerator(style: .light),
            UIImpactFeedbackGenerator(style: .medium),
            UIImpactFeedbackGenerator(style: .heavy)
    )

    @available(iOS 10.0, *)
    public static func hapticActionComplete() {
        
        // Play haptic signal
        if let feedbackSupportLevel = UIDevice.current.value(forKey: "_feedbackSupportLevel") as? Int {
            switch feedbackSupportLevel {
            case 2:
                HapticUtility.impactFeedbackGenerator.medium.prepare()
                // 2nd Generation Taptic Engine w/ Haptic Feedback (iPhone 7/7+)
                HapticUtility.impactFeedbackGenerator.medium.impactOccurred()
            case 1:
                // 1st Generation Taptic Engine (iPhone 6S/6S+)
                AudioServicesPlaySystemSound(HapticUtility.peek)
            case 0:
                // No Taptic Engine
                break
            default: break
            }
        }
    }
    
    @available(iOS 10.0, *)
    public static func hapticActionStrong() {
        if SettingValues.hapticFeedback {
            // Play haptic signal
            if let feedbackSupportLevel = UIDevice.current.value(forKey: "_feedbackSupportLevel") as? Int {
                switch feedbackSupportLevel {
                case 2:
                    HapticUtility.impactFeedbackGenerator.heavy.prepare()
                    // 2nd Generation Taptic Engine w/ Haptic Feedback (iPhone 7/7+)
                    HapticUtility.impactFeedbackGenerator.heavy.impactOccurred()
                case 1:
                    // 1st Generation Taptic Engine (iPhone 6S/6S+)
                    AudioServicesPlaySystemSound(HapticUtility.pop)
                case 0:
                    // No Taptic Engine
                    break
                default:
                    break
                }
            }
        }
    }
    
    @available(iOS 10.0, *)
    public static func hapticActionWeak() {
        if SettingValues.hapticFeedback {
            // Play haptic signal
            if let feedbackSupportLevel = UIDevice.current.value(forKey: "_feedbackSupportLevel") as? Int {
                switch feedbackSupportLevel {
                case 2:
                    HapticUtility.impactFeedbackGenerator.light.prepare()
                    // 2nd Generation Taptic Engine w/ Haptic Feedback (iPhone 7/7+)
                    HapticUtility.impactFeedbackGenerator.light.impactOccurred()
                case 1:
                    // 1st Generation Taptic Engine (iPhone 6S/6S+)
                    AudioServicesPlaySystemSound(HapticUtility.peek)
                case 0:
                    // No Taptic Engine
                    break
                default:
                    break
                }
            }
        }
    }
    
    public static func hapticError() {
        let vibrate = SystemSoundID(kSystemSoundID_Vibrate)
        AudioServicesPlaySystemSound(vibrate)
    }
}
