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
    
    public static func fontOfSize(size: CGFloat, submission: Bool) -> UIFont {
        let fontName = UserDefaults.standard.string(forKey: submission ? "postfont" : "commentfont") ?? ( submission ? "AvenirNext-DemiBold" : "AvenirNext-Medium")
        let adjustedSize = size + CGFloat(submission ? SettingValues.postFontOffset : SettingValues.commentFontOffset)

        return FontMapping.fromStoredName(name: fontName).font(ofSize: adjustedSize) ?? UIFont.systemFont(ofSize: adjustedSize)
    }
    
    public static func boldFontOfSize(size: CGFloat, submission: Bool) -> UIFont {
        let normalFont = fontOfSize(size: size, submission: submission)
        if normalFont.fontName == UIFont.systemFont(ofSize: 10).fontName {
            return UIFont.boldSystemFont(ofSize: size)
        }
        return normalFont.makeBold()
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
extension UIFont {
    
    func withTraits(traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor
            .withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits)) ?? self.fontDescriptor
        return UIFont(descriptor: descriptor, size: 0)
    }
    
    func makeBold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
    
}
