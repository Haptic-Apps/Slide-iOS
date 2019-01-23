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

public class ColorUtil {
    static var theme = Theme.DARK
    static var setOnce = false
    static var defaultTheme = Theme.DARK

    static func shouldBeNight() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        return SettingValues.nightModeEnabled && /*todo pro*/ (hour >= SettingValues.nightStart + 12 || hour < SettingValues.nightEnd) &&  (hour == SettingValues.nightStart + 12 ? (minute >= SettingValues.nightStartMin) : true) && (hour == SettingValues.nightEnd  ? (minute < SettingValues.nightEndMin) : true)
    }

    static func doInit() -> Bool {
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
        navIconColor = theme.navIconColor
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
    static var navIconColor = UIColor.white {
        didSet {
            LinkCellImageCache.initialize()
        }
    }
    
    static var fontColor = UIColor.black

    private static func image(fromLayer layer: CALayer) -> UIImage {
        UIGraphicsBeginImageContext(layer.frame.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage!
    }

    static var baseColor = GMColor.blue500Color()
    static var baseAccent = GMColor.blueA400Color()
    public static var upvoteColor = UIColor.init(hexString: "#FF9800")
    public static var downvoteColor = UIColor.init(hexString: "#2196F3")

    public static func getColorForSub(sub: String, _ header: Bool = false) -> UIColor {
        if header && SettingValues.reduceColor {
            return ColorUtil.backgroundColor
        }
        if let color = UserDefaults.standard.colorForKey(key: "color+" + sub) {
            return color
        } else {
            return baseColor
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
        case MINT = "mint"
        case CREAM = "cream"
        case CONTRAST = "acontrast"
        case PINK = "pink"
        
        public var displayName: String {
            switch self {
            case .LIGHT:
                return "Light"
            case .DEEP:
                return "Deep purple"
            case .DARK:
                return "Dark gray"
            case .BLUE:
                return "Blue"
            case .SEPIA:
                return "Sepia"
            case .RED:
                return "Dark red"
            case .BLACK:
                return "AMOLED black"
            case .CONTRAST:
                return "AMOLED black with contrast"
            case .MINT:
                return "Mint green"
            case .CREAM:
                return "Crème"
            case .PINK:
                return "Pink"
            }
        }

        public static var cases: [Theme] {
            return [.LIGHT, .DARK, .BLACK, .CONTRAST, .BLUE, .SEPIA, .RED, .DEEP, .MINT, .PINK, .CREAM]
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
            case .CONTRAST:
                return UIColor.black
            case .MINT:
                return UIColor.white
            case .CREAM:
                return UIColor(hexString: "#DCD8C2")
            case .PINK:
                return UIColor(hexString: "#FFFFFC")
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
            case .CONTRAST:
                return UIColor(hexString: "#111010")
            case .MINT:
                return UIColor(hexString: "#eef6e8")
            case .CREAM:
                return UIColor(hexString: "#D1CDB9")
            case .PINK:
                return UIColor(hexString: "#fff5e8")
            }
        }
        
        public var navIconColor: UIColor {
            switch self {
            case .LIGHT:
                return ColorUtil.Theme.LIGHT.fontColor
            case .DEEP:
                return ColorUtil.Theme.DEEP.fontColor
            case .DARK:
                return ColorUtil.Theme.DARK.fontColor
            case .BLUE:
                return ColorUtil.Theme.BLUE.fontColor
            case .SEPIA:
                return ColorUtil.Theme.SEPIA.fontColor
            case .RED:
                return ColorUtil.Theme.RED.fontColor
            case .BLACK:
                return ColorUtil.Theme.BLACK.fontColor
            case .CONTRAST:
                return ColorUtil.Theme.CONTRAST.fontColor
            case .MINT:
                return UIColor(hexString: "#9fc675")
            case .CREAM:
                return ColorUtil.Theme.CREAM.fontColor
            case .PINK:
                return UIColor(hexString: "#ea8ab4")
            }
        }
        
        public func isLight() -> Bool {
            return self == .LIGHT || self == .MINT || self == .CREAM || self == .PINK
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
            case .CONTRAST:
                return UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87)
            case .MINT:
                return UIColor(hexString: "#09360f").withAlphaComponent(0.87)
            case .CREAM:
                return UIColor(hexString: "#444139").withAlphaComponent(0.87)
            case .PINK:
                return UIColor(hexString: "#262844").withAlphaComponent(0.87)
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
