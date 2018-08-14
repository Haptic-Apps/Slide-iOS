//
//  FontGenerator.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/28/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class FontGenerator {
    //Fonts are: HelveticaNeue, RobotoCondensed-Regular, RobotoCondensed-Bold, Roboto-Light, Roboto-Bold, Roboto-Medium, or System Font (San Fransisco)
    public static func fontOfSize(size: CGFloat, submission: Bool) -> UIFont {
        return (submission ? postFont.font : commentFont.font).withSize( size + CGFloat(submission ? SettingValues.postFontOffset : SettingValues.commentFontOffset))
    }
    
    public static func boldFontOfSize(size: CGFloat, submission: Bool) -> UIFont {
        return (submission ? postFont.bold() : commentFont.bold()).withSize( size + CGFloat(submission ? SettingValues.postFontOffset : SettingValues.commentFontOffset))
    }
    
    public static var postFont = Font.SYSTEM
    public static var commentFont = Font.SYSTEM

    public static func initialize() {
        if let name = UserDefaults.standard.string(forKey: "postfont") {
            if let t = Font(rawValue: name) {
                postFont = t
            }
        }
        
        if let name = UserDefaults.standard.string(forKey: "commentfont") {
            if let t = Font(rawValue: name) {
                commentFont = t
            }
        }

    }
    
    enum Font: String {
        case HELVETICA = "helvetica"
        case ROBOTOCONDENSED_REGULAR = "rcreg"
        case ROBOTOCONDENSED_BOLD = "rcbold"
        case ROBOTO_LIGHT = "rlight"
        case ROBOTO_BOLD = "rbold"
        case ROBOTO_MEDIUM = "rmed"
        case SYSTEM = "system"
        case PAPYRUS = "papyrus"
        case CHALKBOARD = "chalkboard"

        public static var cases: [Font] {
            return [.HELVETICA, .ROBOTOCONDENSED_REGULAR, .ROBOTOCONDENSED_BOLD, .ROBOTO_LIGHT, .ROBOTO_BOLD, .ROBOTO_MEDIUM, .SYSTEM]
        }
        
        public func bold() -> UIFont {
            switch self {
            case .HELVETICA:
                return UIFont.init(name: "HelveticaNeue-Bold", size: 16)!
            case .ROBOTOCONDENSED_REGULAR:
                return UIFont.init(name: "RobotoCondensed-Bold", size: 16)!
            case .ROBOTOCONDENSED_BOLD:
                return UIFont.init(name: "RobotoCondensed-Bold", size: 16)!
            case .ROBOTO_LIGHT:
                return UIFont.init(name: "Roboto-Medium", size: 16)!
            case .ROBOTO_BOLD:
                return UIFont.init(name: "Roboto-Bold", size: 16)!
            case .ROBOTO_MEDIUM:
                return UIFont.init(name: "Roboto-Bold", size: 16)!
            case .PAPYRUS:
                return UIFont.init(name: "Papyrus", size: 16)!
            case .CHALKBOARD:
                return UIFont.init(name: "ChalkboardSE-Bold", size: 16)!
            case .SYSTEM:
                return UIFont.boldSystemFont(ofSize: 16)
            }
        }
 
        public var font: UIFont {
            switch self {
            case .HELVETICA:
                return UIFont.init(name: "HelveticaNeue", size: 16)!
            case .ROBOTOCONDENSED_REGULAR:
                return UIFont.init(name: "RobotoCondensed-Regular", size: 16)!
            case .ROBOTOCONDENSED_BOLD:
                return UIFont.init(name: "RobotoCondensed-Bold", size: 16)!
            case .ROBOTO_LIGHT:
                return UIFont.init(name: "Roboto-Light", size: 16)!
            case .ROBOTO_BOLD:
                return UIFont.init(name: "Roboto-Bold", size: 16)!
            case .ROBOTO_MEDIUM:
                return UIFont.init(name: "Roboto-Medium", size: 16)!
            case .PAPYRUS:
                return UIFont.init(name: "Papyrus", size: 16)!
            case .CHALKBOARD:
                return UIFont.init(name: "ChalkboardSE-Regular", size: 16)!
            case .SYSTEM:
                return UIFont.systemFont(ofSize: 16)
            }
        }
        
    }
}
