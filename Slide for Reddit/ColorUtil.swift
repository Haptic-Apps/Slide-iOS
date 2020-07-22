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
    static var theme: Theme = Theme(title: "dark", displayName: "Dark Gray", foregroundColor: UIColor(hexString: "#303030"), backgroundColor: UIColor(hexString: "#212121"), navIconColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), fontColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), isLight: false, isCustom: false) {
        didSet {
            LinkCellImageCache.initialize()
        }
    }
    
    static var defaultTheme = ""
    static var currentTheme = ""
    
    static var CUSTOM_FOREGROUND = "customForeground"
    static var CUSTOM_FONT = "customFont"
    static var CUSTOM_BACKGROUND = "customBackground"
    static var CUSTOM_NAVICON = "customNavicon"
    static var CUSTOM_STATUSBAR = "customStatus"

    static var CUSTOM_FOREGROUND_NIGHT = "customForegroundNight"
    static var CUSTOM_FONT_NIGHT = "customFontNight"
    static var CUSTOM_BACKGROUND_NIGHT = "customBackgroundNight"
    static var CUSTOM_NAVICON_NIGHT = "customNaviconNight"
    static var CUSTOM_STATUSBAR_NIGHT = "customStatusNight"

    static func shouldBeNight() -> Bool {
        if !SettingValues.nightModeEnabled {
            return false
        }
        if #available(iOS 13, *) {
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        return SettingValues.nightModeEnabled && (hour >= SettingValues.nightStart + 12 || hour < SettingValues.nightEnd) &&  (hour == SettingValues.nightStart + 12 ? (minute >= SettingValues.nightStartMin) : true) && (hour == SettingValues.nightEnd  ? (minute < SettingValues.nightEndMin) : true) // TODO: - Pro
    }

    static func doInit() -> Bool {
        initializeThemes()
        theme = themes[0]
        
        let name = shouldBeNight() ? SettingValues.nightTheme : UserDefaults.standard.string(forKey: "theme") ?? "light"
        defaultTheme = name
        for bTheme in themes {
            if bTheme.title == name {
                theme = bTheme
                break
            }
        }
        
        print("Switching theme to \(theme.title)")
        var toReturn = false
        if currentTheme != theme.title {
            CachedTitle.titles.removeAll()
            LinkCellImageCache.initialize()
            SingleSubredditViewController.cellVersion += 1
            toReturn = true
            currentTheme = theme.title
        }
        
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
            return ColorUtil.theme.foregroundColor
        }
        if let color = UserDefaults.standard.colorForKey(key: "color+" + sub) {
            return color
        } else {
            return baseColor
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
            return ColorUtil.theme.fontColor
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

    public static func getTagForUser(name: String) -> String? {
        return UserDefaults.standard.string(forKey: "tag+" + name)
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
    
    struct Theme: Equatable {
        var title: String
        var displayName: String
        var foregroundColor: UIColor
        var backgroundColor: UIColor
        var navIconColor: UIColor
        var fontColor: UIColor
        var isLight: Bool
        var isCustom: Bool
        
        static func == (lhs: Theme, rhs: Theme) -> Bool {
            return lhs.title == rhs.title
        }
    }
    
    static var themes = [Theme]()
    
    static func initializeThemes() {
        ColorUtil.themes.removeAll()
        ColorUtil.themes.append(Theme(title: "light", displayName: "Light", foregroundColor: UIColor.white, backgroundColor: UIColor(hexString: "#e5e5e5"), navIconColor: UIColor(hexString: "#000000").withAlphaComponent(0.87), fontColor: UIColor(hexString: "#000000").withAlphaComponent(0.87), isLight: true, isCustom: false))
        ColorUtil.themes.append(Theme(title: "dark", displayName: "Dark Gray", foregroundColor: UIColor(hexString: "#303030"), backgroundColor: UIColor(hexString: "#212121"), navIconColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), fontColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), isLight: false, isCustom: false))
        ColorUtil.themes.append(Theme(title: "black", displayName: "AMOLED Black", foregroundColor: UIColor.black, backgroundColor: UIColor.black, navIconColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), fontColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), isLight: false, isCustom: false))
        ColorUtil.themes.append(Theme(title: "blue", displayName: "Blue", foregroundColor: UIColor(hexString: "#37474F"), backgroundColor: UIColor(hexString: "#2F3D44"), navIconColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), fontColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), isLight: false, isCustom: false))
        ColorUtil.themes.append(Theme(title: "sepia", displayName: "Sepia", foregroundColor: UIColor(hexString: "#e2dfd7"), backgroundColor: UIColor(hexString: "#cac5ad"), navIconColor: UIColor(hexString: "#3e3d36").withAlphaComponent(0.87), fontColor: UIColor(hexString: "#3e3d36").withAlphaComponent(0.87), isLight: false, isCustom: false))
        ColorUtil.themes.append(Theme(title: "red", displayName: "Dark Red", foregroundColor: UIColor(hexString: "#402c2c"), backgroundColor: UIColor(hexString: "#312322"), navIconColor: UIColor(hexString: "#fff7ed").withAlphaComponent(0.87), fontColor: UIColor(hexString: "#fff7ed").withAlphaComponent(0.87), isLight: false, isCustom: false))
        ColorUtil.themes.append(Theme(title: "deep", displayName: "Deep Purple", foregroundColor: UIColor(hexString: "#1f1e26"), backgroundColor: UIColor(hexString: "#16161C"), navIconColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), fontColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), isLight: false, isCustom: false))
        ColorUtil.themes.append(Theme(title: "mint", displayName: "Mint Green", foregroundColor: UIColor(hexString: "#ffffff"), backgroundColor: UIColor(hexString: "#eef6e8"), navIconColor: UIColor(hexString: "#9fc675"), fontColor: UIColor(hexString: "#09360f").withAlphaComponent(0.87), isLight: true, isCustom: false))
        ColorUtil.themes.append(Theme(title: "cream", displayName: "Crème", foregroundColor: UIColor(hexString: "#DCD8C2"), backgroundColor: UIColor(hexString: "#D1CDB9"), navIconColor: UIColor(hexString: "#444139").withAlphaComponent(0.87), fontColor: UIColor(hexString: "#444139").withAlphaComponent(0.87), isLight: true, isCustom: false))
        ColorUtil.themes.append(Theme(title: "acontrast", displayName: "AMOLED Black with Contrast", foregroundColor: UIColor.black, backgroundColor: UIColor(hexString: "#111010"), navIconColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), fontColor: UIColor(hexString: "#FFFFFF").withAlphaComponent(0.87), isLight: false, isCustom: false))
        ColorUtil.themes.append(Theme(title: "pink", displayName: "Pink", foregroundColor: UIColor(hexString: "#FFFFFC"), backgroundColor: UIColor(hexString: "#fff5e8"), navIconColor: UIColor(hexString: "#ea8ab4"), fontColor: UIColor(hexString: "#262844").withAlphaComponent(0.87), isLight: true, isCustom: false))
        ColorUtil.themes.append(Theme(title: "solarize", displayName: "Solarized", foregroundColor: UIColor(hexString: "#0C3641"), backgroundColor: UIColor(hexString: "#032B35"), navIconColor: UIColor(hexString: "#6E73C1"), fontColor: UIColor(hexString: "#839496"), isLight: false, isCustom: false))
        
        for theme in UserDefaults.standard.dictionaryRepresentation().keys.filter({ $0.startsWith("Theme+") }) {
            let themeData = UserDefaults.standard.string(forKey: theme)!.removingPercentEncoding!
            let split = themeData.split("#")
            let title = split[1].removingPercentEncoding!.replacingOccurrences(of: "<H>", with: "#")
            themes.append(Theme(title: title, displayName: title, foregroundColor: UIColor(hex: split[2]), backgroundColor: UIColor(hex: split[3]), navIconColor: UIColor(hex: split[5]), fontColor: UIColor(hex: split[4]), isLight: Bool(split[8])!, isCustom: true))
        }
    }

    public static func getClosestColor(hex: String) -> UIColor {
        let color = UIColor(hexString: hex)
        return color.closestColor(inPalette: GMPalette.allColorNoBlack()) ?? color
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
