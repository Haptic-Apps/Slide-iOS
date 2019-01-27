//
//  FontGenerator.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/28/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import DTCoreText
import UIKit

class FontGenerator {

    enum FontWeight: String, CaseIterable {
        case ultraLight = "UltraLight"
        case light = "Light"
        case thin = "Thin"
        case regular = "Regular"
        case semibold = "SemiBold"
        case medium = "Medium"
        case heavy = "Heavy"
        case bold = "Bold"
        case black = "Black"

        var attribute: UIFont.Weight {
            switch self {
            case .ultraLight:
                return UIFont.Weight.ultraLight
            case .light:
                return UIFont.Weight.light
            case .thin:
                return UIFont.Weight.thin
            case .regular:
                return UIFont.Weight.regular
            case .semibold:
                return UIFont.Weight.semibold
            case .medium:
                return UIFont.Weight.medium
            case .heavy:
                return UIFont.Weight.heavy
            case .bold:
                return UIFont.Weight.bold
            case .black:
                return UIFont.Weight.black
            }
        }
    }

    public static func fontOfSize(size: CGFloat, submission: Bool) -> UIFont {
        let fontName = UserDefaults.standard.string(forKey: submission ? "postfont" : "commentfont") ?? "system"
        let adjustedSize = size + CGFloat(submission ? SettingValues.postFontOffset : SettingValues.commentFontOffset)
        let font = UIFont(name: fontName, size: adjustedSize) ?? UIFont.systemFont(ofSize: adjustedSize)
        let weight = (submission ? SettingValues.submissionFontWeight : SettingValues.commentFontWeight) ?? "Regular"
        let fontWeight = FontWeight(rawValue: weight) ?? .regular
        return font.withWeight(fontWeight.attribute)
    }
    
    public static func boldFontOfSize(size: CGFloat, submission: Bool) -> UIFont {
        let normalFont = fontOfSize(size: size, submission: submission)
        guard let descriptor = normalFont.fontDescriptor.withSymbolicTraits(.traitBold) else {
            return normalFont
        }
        let adjustedSize = size + CGFloat(submission ? SettingValues.postFontOffset : SettingValues.commentFontOffset)
        return UIFont(descriptor: descriptor, size: adjustedSize)
    }
    
    public static var postFont = Font.SYSTEM
    public static var commentFont = Font.SYSTEM
    public static var fontDict = [String: UIFont]()

    public static func initialize() {
        fontDict.removeAll()
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
        case AVENIR = "avenirnext-regular"
        case AVENIR_MEDIUM = "avenirnext-medium"
        case ROBOTOCONDENSED_REGULAR = "rcreg"
        case ROBOTOCONDENSED_BOLD = "rcbold"
        case ROBOTO_LIGHT = "rlight"
        case ROBOTO_BOLD = "rbold"
        case ROBOTO_MEDIUM = "rmed"
        case SYSTEM = "system"
        case PAPYRUS = "papyrus"
        case CHALKBOARD = "chalkboard"

        public static var cases: [Font] {
            return [.HELVETICA, .AVENIR, .AVENIR_MEDIUM, .ROBOTOCONDENSED_REGULAR, .ROBOTOCONDENSED_BOLD, .ROBOTO_LIGHT, .ROBOTO_BOLD, .ROBOTO_MEDIUM, .SYSTEM]
        }
        
        public func bold() -> UIFont {
            switch self {
            case .HELVETICA:
                return UIFont.init(name: "HelveticaNeue-Bold", size: 16)!
            case .AVENIR:
                return UIFont.init(name: "AvenirNext-DemiBold", size: 16)!
            case .AVENIR_MEDIUM:
                return UIFont.init(name: "AvenirNext-Bold", size: 16)!
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
            case .AVENIR:
                return UIFont.init(name: "AvenirNext-Regular", size: 16)!
            case .AVENIR_MEDIUM:
                return UIFont.init(name: "AvenirNext-DemiBold", size: 16)!
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
