//
//  MaterialDesignColorSwift.swift
//  baclavios
//
//  Created by Walter Da Col on 10/10/14.
//  Copyright (c) 2014 Walter Da Col. All rights reserved.
//
import Foundation

#if os(iOS)
    import UIKit
    typealias Color = UIColor
#else
    import Cocoa
    typealias Color = NSColor
#endif

extension Color {
    convenience init(rgba: UInt){
        let sRgba = min(rgba,0xFFFFFFFF)
        let red: CGFloat = CGFloat((sRgba & 0xFF000000) >> 24) / 255.0
        let green: CGFloat = CGFloat((sRgba & 0x00FF0000) >> 16) / 255.0
        let blue: CGFloat = CGFloat((sRgba & 0x0000FF00) >> 8) / 255.0
        let alpha: CGFloat = CGFloat(sRgba & 0x000000FF) / 255.0
        
        self.init(red: red, green: green, blue:blue, alpha:alpha)
    }
}

struct MaterialColors {
    static let Red = _MaterialColorRed.self
    static let Pink = _MaterialColorPink.self
    static let Purple = _MaterialColorPurple.self
    static let DeepPurple = _MaterialColorDeepPurple.self
    static let Indigo = _MaterialColorIndigo.self
    static let Blue = _MaterialColorBlue.self
    static let LightBlue = _MaterialColorLightBlue.self
    static let Cyan = _MaterialColorCyan.self
    static let Teal = _MaterialColorTeal.self
    static let Green = _MaterialColorGreen.self
    static let LightGreen = _MaterialColorLightGreen.self
    static let Lime = _MaterialColorLime.self
    static let Yellow = _MaterialColorYellow.self
    static let Amber = _MaterialColorAmber.self
    static let Orange = _MaterialColorOrange.self
    static let DeepOrange = _MaterialColorDeepOrange.self
    static let Brown = _MaterialColorBrown.self
    static let Grey = _MaterialColorGrey.self
    static let BlueGrey = _MaterialColorBlueGrey.self
}

struct _MaterialColorRed {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFDE0DCFF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF9BDBBFF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF69988FF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF36C60FF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE84E40FF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE51C23FF, TEXT: 0xFFFFFFFF)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xDD191DFF, TEXT: 0xFFFFFFFF)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xD01716FF, TEXT: 0xFFFFFFFF)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xC41411FF, TEXT: 0xFFFFFFDE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xB0120AFF, TEXT: 0xFFFFFFDE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF7997FF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF5177FF, TEXT: 0xFFFFFFFF)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF2D6FFF, TEXT: 0xFFFFFFFF)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE00032FF, TEXT: 0xFFFFFFFF)
}

struct _MaterialColorPink {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFCE4ECFF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF8BBD0FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF48FB1FF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF06292FF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xEC407AFF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE91E63FF, TEXT: 0xFFFFFFFF)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xD81B60FF, TEXT: 0xFFFFFFFF)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xC2185BFF, TEXT: 0xFFFFFFDE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xAD1457FF, TEXT: 0xFFFFFFDE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x880E4FFF, TEXT: 0xFFFFFFDE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF80ABFF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF4081FF, TEXT: 0xFFFFFFFF)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF50057FF, TEXT: 0xFFFFFFFF)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xC51162FF, TEXT: 0xFFFFFFFF)
}

struct _MaterialColorPurple {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF3E5F5FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE1BEE7FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xCE93D8FF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xBA68C8FF, TEXT: 0xFFFFFFFF)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xAB47BCFF, TEXT: 0xFFFFFFFF)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x9C27B0FF, TEXT: 0xFFFFFFDE)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x8E24AAFF, TEXT: 0xFFFFFFDE)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x7B1FA2FF, TEXT: 0xFFFFFFDE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x6A1B9AFF, TEXT: 0xFFFFFFDE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x4A148CFF, TEXT: 0xFFFFFFDE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xEA80FCFF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE040FBFF, TEXT: 0xFFFFFFFF)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xD500F9FF, TEXT: 0xFFFFFFFF)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xAA00FFFF, TEXT: 0xFFFFFFFF)
}

struct _MaterialColorDeepPurple {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xEDE7F6FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xD1C4E9FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xB39DDBFF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x9575CDFF, TEXT: 0xFFFFFFFF)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x7E57C2FF, TEXT: 0xFFFFFFFF)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x673AB7FF, TEXT: 0xFFFFFFDE)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x5E35B1FF, TEXT: 0xFFFFFFDE)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x512DA8FF, TEXT: 0xFFFFFFDE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x4527A0FF, TEXT: 0xFFFFFFDE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x311B92FF, TEXT: 0xFFFFFFDE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xB388FFFF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x7C4DFFFF, TEXT: 0xFFFFFFFF)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x651FFFFF, TEXT: 0xFFFFFFDE)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x6200EAFF, TEXT: 0xFFFFFFDE)
}

struct _MaterialColorIndigo {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE8EAF6FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xC5CAE9FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x9FA8DAFF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x7986CBFF, TEXT: 0xFFFFFFFF)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x5C6BC0FF, TEXT: 0xFFFFFFFF)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x3F51B5FF, TEXT: 0xFFFFFFDE)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x3949ABFF, TEXT: 0xFFFFFFDE)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x303F9FFF, TEXT: 0xFFFFFFDE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x283593FF, TEXT: 0xFFFFFFDE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x1A237EFF, TEXT: 0xFFFFFFDE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x8C9EFFFF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x536DFEFF, TEXT: 0xFFFFFFFF)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x3D5AFEFF, TEXT: 0xFFFFFFFF)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x304FFEFF, TEXT: 0xFFFFFFDE)
}

struct _MaterialColorBlue {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE7E9FDFF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xD0D9FFFF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xAFBFFFFF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x91A7FFFF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x738FFEFF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x5677FCFF, TEXT: 0xFFFFFFFF)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x4E6CEFFF, TEXT: 0xFFFFFFFF)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x455EDEFF, TEXT: 0xFFFFFFFF)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x3B50CEFF, TEXT: 0xFFFFFFDE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x2A36B1FF, TEXT: 0xFFFFFFDE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xA6BAFFFF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x6889FFFF, TEXT: 0xFFFFFFFF)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x4D73FFFF, TEXT: 0xFFFFFFFF)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x4D69FFFF, TEXT: 0xFFFFFFFF)
}

struct _MaterialColorLightBlue {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE1F5FEFF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xB3E5FCFF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x81D4FAFF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x4FC3F7FF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x29B6F6FF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x03A9F4FF, TEXT: 0xFFFFFFFF)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x039BE5FF, TEXT: 0xFFFFFFFF)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x0288D1FF, TEXT: 0xFFFFFFFF)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x0277BDFF, TEXT: 0xFFFFFFFF)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x01579BFF, TEXT: 0xFFFFFFDE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x80D8FFFF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x40C4FFFF, TEXT: 0x000000DE)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x00B0FFFF, TEXT: 0x000000DE)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x0091EAFF, TEXT: 0xFFFFFFFF)
}

struct _MaterialColorCyan {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE0F7FAFF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xB2EBF2FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x80DEEAFF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x4DD0E1FF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x26C6DAFF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x00BCD4FF, TEXT: 0xFFFFFFFF)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x00ACC1FF, TEXT: 0xFFFFFFFF)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x0097A7FF, TEXT: 0xFFFFFFFF)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x00838FFF, TEXT: 0xFFFFFFFF)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x006064FF, TEXT: 0xFFFFFFDE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x84FFFFFF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x18FFFFFF, TEXT: 0x000000DE)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x00E5FFFF, TEXT: 0x000000DE)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x00B8D4FF, TEXT: 0x000000DE)
}

struct _MaterialColorTeal {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE0F2F1FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xB2DFDBFF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x80CBC4FF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x4DB6ACFF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x26A69AFF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x009688FF, TEXT: 0xFFFFFFFF)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x00897BFF, TEXT: 0xFFFFFFFF)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x00796BFF, TEXT: 0xFFFFFFFF)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x00695CFF, TEXT: 0xFFFFFFDE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x004D40FF, TEXT: 0xFFFFFFDE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xA7FFEBFF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x64FFDAFF, TEXT: 0x000000DE)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x1DE9B6FF, TEXT: 0x000000DE)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x00BFA5FF, TEXT: 0x000000DE)
}

struct _MaterialColorGreen {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xD0F8CEFF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xA3E9A4FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x72D572FF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x42BD41FF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x2BAF2BFF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x259B24FF, TEXT: 0xFFFFFFFF)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x0A8F08FF, TEXT: 0xFFFFFFFF)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x0A7E07FF, TEXT: 0xFFFFFFFF)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x056F00FF, TEXT: 0xFFFFFFDE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x0D5302FF, TEXT: 0xFFFFFFDE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xA2F78DFF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x5AF158FF, TEXT: 0x000000DE)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x14E715FF, TEXT: 0x000000DE)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x12C700FF, TEXT: 0x000000DE)
}

struct _MaterialColorLightGreen {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF1F8E9FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xDCEDC8FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xC5E1A5FF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xAED581FF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x9CCC65FF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x8BC34AFF, TEXT: 0x000000DE)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x7CB342FF, TEXT: 0x000000DE)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x689F38FF, TEXT: 0x000000DE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x558B2FFF, TEXT: 0xFFFFFFFF)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x33691EFF, TEXT: 0xFFFFFFFF)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xCCFF90FF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xB2FF59FF, TEXT: 0x000000DE)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x76FF03FF, TEXT: 0x000000DE)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x64DD17FF, TEXT: 0x000000DE)
}

struct _MaterialColorLime {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF9FBE7FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF0F4C3FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE6EE9CFF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xDCE775FF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xD4E157FF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xCDDC39FF, TEXT: 0x000000DE)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xC0CA33FF, TEXT: 0x000000DE)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xAFB42BFF, TEXT: 0x000000DE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x9E9D24FF, TEXT: 0x000000DE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x827717FF, TEXT: 0xFFFFFFFF)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF4FF81FF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xEEFF41FF, TEXT: 0x000000DE)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xC6FF00FF, TEXT: 0x000000DE)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xAEEA00FF, TEXT: 0x000000DE)
}

struct _MaterialColorYellow {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFFDE7FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFF9C4FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFF59DFF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFF176FF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFEE58FF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFEB3BFF, TEXT: 0x000000DE)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFDD835FF, TEXT: 0x000000DE)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFBC02DFF, TEXT: 0x000000DE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF9A825FF, TEXT: 0x000000DE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF57F17FF, TEXT: 0x000000DE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFFF8DFF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFFF00FF, TEXT: 0x000000DE)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFEA00FF, TEXT: 0x000000DE)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFD600FF, TEXT: 0x000000DE)
}

struct _MaterialColorAmber {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFF8E1FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFECB3FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFE082FF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFD54FFF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFCA28FF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFC107FF, TEXT: 0x000000DE)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFB300FF, TEXT: 0x000000DE)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFA000FF, TEXT: 0x000000DE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF8F00FF, TEXT: 0x000000DE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF6F00FF, TEXT: 0x000000DE)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFE57FFF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFD740FF, TEXT: 0x000000DE)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFC400FF, TEXT: 0x000000DE)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFAB00FF, TEXT: 0x000000DE)
}

struct _MaterialColorOrange {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFF3E0FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFE0B2FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFCC80FF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFB74DFF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFA726FF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF9800FF, TEXT: 0x000000DE)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFB8C00FF, TEXT: 0x000000DE)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF57C00FF, TEXT: 0x000000DE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xEF6C00FF, TEXT: 0xFFFFFFFF)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE65100FF, TEXT: 0xFFFFFFFF)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFD180FF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFAB40FF, TEXT: 0x000000DE)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF9100FF, TEXT: 0x000000DE)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF6D00FF, TEXT: 0x00000000)
}

struct _MaterialColorDeepOrange {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFBE9E7FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFCCBCFF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFAB91FF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF8A65FF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF7043FF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF5722FF, TEXT: 0xFFFFFFFF)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF4511EFF, TEXT: 0xFFFFFFFF)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE64A19FF, TEXT: 0xFFFFFFFF)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xD84315FF, TEXT: 0xFFFFFFFF)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xBF360CFF, TEXT: 0xFFFFFFFF)
    static let A100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF9E80FF, TEXT: 0x000000DE)
    static let A200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF6E40FF, TEXT: 0x000000DE)
    static let A400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFF3D00FF, TEXT: 0xFFFFFFFF)
    static let A700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xDD2C00FF, TEXT: 0xFFFFFFFF)
}

struct _MaterialColorBrown {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xEFEBE9FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xD7CCC8FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xBCAAA4FF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xA1887FFF, TEXT: 0xFFFFFFFF)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x8D6E63FF, TEXT: 0xFFFFFFFF)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x795548FF, TEXT: 0xFFFFFFDE)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x6D4C41FF, TEXT: 0xFFFFFFDE)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x5D4037FF, TEXT: 0xFFFFFFDE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x4E342EFF, TEXT: 0xFFFFFFDE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x3E2723FF, TEXT: 0xFFFFFFDE)
}

struct _MaterialColorGrey {
    static let P0	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFFFFFFFF, TEXT: 0x000000DE)
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xFAFAFAFF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xF5F5F5FF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xEEEEEEFF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xE0E0E0FF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xBDBDBDFF, TEXT: 0x000000DE)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x9E9E9EFF, TEXT: 0x000000DE)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x757575FF, TEXT: 0xFFFFFFDE)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x616161FF, TEXT: 0xFFFFFFDE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x424242FF, TEXT: 0xFFFFFFDE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x212121FF, TEXT: 0xFFFFFFDE)
    static let P1000	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x000000FF, TEXT: 0xFFFFFFDE)
}

struct _MaterialColorBlueGrey {
    static let P50	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xECEFF1FF, TEXT: 0x000000DE)
    static let P100	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xCFD8DCFF, TEXT: 0x000000DE)
    static let P200	: (HUE: UInt, TEXT: UInt)	= (HUE: 0xB0BEC5FF, TEXT: 0x000000DE)
    static let P300	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x90A4AEFF, TEXT: 0x000000DE)
    static let P400	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x78909CFF, TEXT: 0xFFFFFFFF)
    static let P500	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x607D8BFF, TEXT: 0xFFFFFFFF)
    static let P600	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x546E7AFF, TEXT: 0xFFFFFFDE)
    static let P700	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x455A64FF, TEXT: 0xFFFFFFDE)
    static let P800	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x37474FFF, TEXT: 0xFFFFFFDE)
    static let P900	: (HUE: UInt, TEXT: UInt)	= (HUE: 0x263238FF, TEXT: 0xFFFFFFDE)
}
