//
//  ColorUtil.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/29/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Foundation
import MaterialComponents
import MTColorDistance

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.length {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

class ColorUtil {
    static var theme = Theme.DARK
    static var setOnce = false

    static func shouldBeNight() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        return SettingValues.nightModeEnabled && /*todo pro*/ (hour >= SettingValues.nightStart + 12 || hour < SettingValues.nightEnd) &&  (hour == SettingValues.nightStart + 12 ? (minute >= SettingValues.nightStartMin) : true) && (hour == SettingValues.nightEnd  ? (minute < SettingValues.nightEndMin) : true)
    }

    static func doInit() -> Bool {
        var defaultTheme = Theme.DARK
        if let name = UserDefaults.standard.string(forKey: "theme") {
            if let t = Theme(rawValue: name) {
                defaultTheme = t
            }
        }
        var toReturn = false
        if theme != defaultTheme || (shouldBeNight() || (!shouldBeNight() && theme == SettingValues.nightTheme)) || (defaultTheme == SettingValues.nightTheme && theme != defaultTheme) {
            if shouldBeNight() && theme != SettingValues.nightTheme && SettingValues.nightTheme != defaultTheme {
                theme = SettingValues.nightTheme
                CachedTitle.titles.removeAll()
                LinkCellImageCache.initialize()
                SingleSubredditViewController.cellVersion += 1
                toReturn = true
            } else if !shouldBeNight() && theme != defaultTheme {
                theme = defaultTheme
                CachedTitle.titles.removeAll()
                LinkCellImageCache.initialize()
                SingleSubredditViewController.cellVersion += 1
                toReturn = true
            } else if defaultTheme == SettingValues.nightTheme && theme != defaultTheme {
                theme = defaultTheme
                CachedTitle.titles.removeAll()
                LinkCellImageCache.initialize()
                SingleSubredditViewController.cellVersion += 1
                toReturn = true
            }
        }
        
        if !setOnce {
            LinkCellImageCache.initialize()
            setOnce = true
        }
        foregroundColor = theme.foregroundColor
        backgroundColor = theme.backgroundColor
        fontColor = theme.fontColor
        let color = UserDefaults.standard.colorForKey(key: "basecolor")
        if color != nil {
            baseColor = color!
        }
        let accent = UserDefaults.standard.colorForKey(key: "accentcolor")
        if accent != nil {
            baseAccent = accent!
        }
        return toReturn
    }

    static var foregroundColor = UIColor.white
    static var backgroundColor = UIColor.white
    static var fontColor = UIColor.black {
        didSet {
            LinkCellImageCache.initialize()
        }
    }

    public static func setBackgroundToolbar(toolbar: UINavigationBar?) {
        if toolbar != nil {
            toolbar?.barTintColor = backgroundColor
        }
    }

    private static func image(fromLayer layer: CALayer) -> UIImage {
        UIGraphicsBeginImageContext(layer.frame.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage!
    }

    static var baseColor = GMColor.blue500Color()
    static var baseAccent = GMColor.cyanA200Color()
    public static var upvoteColor = UIColor.init(hexString: "#FF9800")
    public static var downvoteColor = UIColor.init(hexString: "#2196F3")

    public static func getColorForSub(sub: String) -> UIColor {
        let color = UserDefaults.standard.colorForKey(key: "color+" + sub)
        if color == nil || color!.hexString == UIColor.black.hexString {
            return baseColor
        } else {
            return color!
        }
    }

    public static func getColorForSubBackground(sub: String) -> UIColor {
        let color = UserDefaults.standard.colorForKey(key: "color+" + sub)
        if color == nil {
            return foregroundColor
        } else {
            return color!
        }
    }

    public static func getColorForUser(name: String) -> UIColor {
        let color = UserDefaults.standard.colorForKey(key: "user+" + name)
        if color == nil {
            return baseColor
        } else {
            return color!
        }
    }
    
    public static func getCommentDepthColors() -> [UIColor] {
        var colors = [UIColor]()
        for i in 0...4 {
            let color = UserDefaults.standard.colorForKey(key: "commentcolor\(i)")
            if color == nil {
                switch i {
                case 0:
                    colors.append(GMColor.blue500Color())
                case 1:
                    colors.append(GMColor.green500Color())
                case 2:
                    colors.append(GMColor.yellow500Color())
                case 3:
                    colors.append(GMColor.orange500Color())
                default:
                    colors.append(GMColor.red500Color())
                }
            } else {
                colors.append(color!)
            }
        }
        return colors
    }
    
    public static func setCommentDepthColors(_ colors: [UIColor]) {
        for i in 0...4 {
            UserDefaults.standard.setColor(color: colors.safeGet(i) ?? GMColor.red500Color(), forKey: "commentcolor\(i)")
        }
        UserDefaults.standard.synchronize()
    }
    
    public static func getCommentNameColor(_ subreddit: String) -> UIColor {
        if UserDefaults.standard.bool(forKey: "commentaccent") {
            return ColorUtil.accentColorForSub(sub: subreddit)
        }
        let color = UserDefaults.standard.colorForKey(key: "commentcolor")
        if color == nil {
            return ColorUtil.fontColor
        } else {
            return color!
        }
    }
    
    public static func setCommentNameColor(color: UIColor?, accent: Bool = false) {
        if color == nil {
            UserDefaults.standard.removeObject(forKey: "commentcolor")
        } else {
            UserDefaults.standard.setColor(color: color!, forKey: "commentcolor")
        }
        
        UserDefaults.standard.set(accent, forKey: "commentaccent")
        UserDefaults.standard.synchronize()
    }

    public static func setColorForSub(sub: String, color: UIColor) {
        UserDefaults.standard.setColor(color: color, forKey: "color+" + sub)
        UserDefaults.standard.synchronize()
    }

    public static func setTagForUser(name: String, tag: String) {
        UserDefaults.standard.set(tag, forKey: "tag+" + name)
        UserDefaults.standard.synchronize()
    }

    public static func getTagForUser(name: String) -> String {
        return UserDefaults.standard.string(forKey: "tag+" + name) ?? ""
    }

    public static func removeTagForUser(name: String) {
        UserDefaults.standard.removeObject(forKey: "tag+" + name)
        UserDefaults.standard.synchronize()
    }

    public static func setColorForUser(name: String, color: UIColor) {
        UserDefaults.standard.setColor(color: color, forKey: "user+" + name)
        UserDefaults.standard.synchronize()
    }

    public static func setAccentColorForSub(sub: String, color: UIColor) {
        UserDefaults.standard.setColor(color: color, forKey: "accent+" + sub)
        UserDefaults.standard.synchronize()
    }

    public static func accentColorForSub(sub: String) -> UIColor {
        let color = UserDefaults.standard.colorForKey(key: "accent+" + sub)
        if color == nil {
            return baseAccent
        } else {
            return color!
        }
    }

    enum Theme: String {
        case LIGHT = "light"
        case DARK = "dark"
        case BLACK = "black"
        case BLUE = "blue"
        case SEPIA = "sepia"
        case RED = "red"
        case DEEP = "deep"

        public static var cases: [Theme] {
            return [.LIGHT, .DARK, .BLACK, .BLUE, .SEPIA, .RED, .DEEP]
        }
        public var foregroundColor: UIColor {
            switch self {
            case .LIGHT:
                return UIColor.white
            case .DARK:
                return UIColor(hexString: "#303030")
            case .DEEP:
                return UIColor(hexString: "#1f1e26")
            case .BLUE:
                return UIColor(hexString: "#37474F")
            case .SEPIA:
                return UIColor(hexString: "#e2dfd7")
            case .RED:
                return UIColor(hexString: "#402c2c")
            case .BLACK:
                return UIColor.black
            }
        }

        public var backgroundColor: UIColor {
            switch self {
            case .LIGHT:
                return UIColor(hexString: "#e5e5e5")
            case .DEEP:
                return UIColor(hexString: "#16161C")
            case .DARK:
                return UIColor(hexString: "#212121")
            case .BLUE:
                return UIColor(hexString: "#2F3D44")
            case .SEPIA:
                return UIColor(hexString: "#cac5ad")
            case .RED:
                return UIColor(hexString: "#312322")
            case .BLACK:
                return UIColor.black
            }
        }

        public var fontColor: UIColor {
            switch self {
            case .LIGHT:
                return UIColor(hexString: "#000000").withAlphaComponent(0.87)
            case .DARK:
                return UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87)
            case .BLUE:
                return UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87)
            case .DEEP:
                return UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87)
            case .SEPIA:
                return UIColor(hexString: "#3e3d36").withAlphaComponent(0.87)
            case .RED:
                return UIColor(hexString: "#fff7ed").withAlphaComponent(0.87)
            case .BLACK:
                return UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87)
            }
        }
    }
    
    public static func distance(a: UIColor, b: UIColor) -> CGFloat {
        let redDist = pow(a.redValue - b.redValue, 2)
        let greenDist = pow(a.greenValue - b.greenValue, 2)
        let blueDist = pow(a.blueValue - b.blueValue, 2)
        return sqrt(redDist + greenDist + blueDist)
    }
    
    public static func getClosestColor(hex: String) -> UIColor {
        let allColors = GMPalette.allColorNoBlack()
        
        return UIColor.init(hexString: hex).closestColor(inPalette: allColors)
    }

}

extension UserDefaults {

    func colorForKey(key: String) -> UIColor? {
        var color: UIColor?
        if let colorData = data(forKey: key) {
            color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? UIColor
        }
        return color
    }

    func setColor(color: UIColor?, forKey key: String) {
        var colorData: NSData?
        if let color = color {
            colorData = NSKeyedArchiver.archivedData(withRootObject: color) as NSData?
        }
        set(colorData, forKey: key)
    }

}
