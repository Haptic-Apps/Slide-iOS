//
//  LinkParser.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/28/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import DTCoreText
import UIKit
import YYText

class LinkParser {
    public static func parse(_ attributedString: NSAttributedString, _ color: UIColor, font: UIFont, fontColor: UIColor, linksCallback: ((URL) -> Void)?, indexCallback: (() -> Int)?) -> NSMutableAttributedString {
        let string = NSMutableAttributedString.init(attributedString: attributedString)
        string.removeAttribute(convertToNSAttributedStringKey(kCTForegroundColorFromContextAttributeName as String), range: NSRange.init(location: 0, length: string.length))
        if string.length > 0 {
            while string.string.contains("slide://") {
                do {
                    let match = try NSRegularExpression(pattern: "(slide:\\/\\/[a-zA-Z%?#0-9]+)", options: []).matches(in: string.string, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSRange(location: 0, length: string.length))[0]
                    let matchRange: NSRange = match.range(at: 1)
                    if matchRange.location != NSNotFound {
                        let attributedText = string.attributedSubstring(from: match.range).mutableCopy() as! NSMutableAttributedString
                        let oldAttrs = attributedText.attributes(at: 0, effectiveRange: nil)
                        print(attributedText.string)
                        let newAttrs = [ NSAttributedString.Key.link: URL(string: attributedText.string)!] as [NSAttributedString.Key: Any]
                        let allParams = newAttrs.reduce(into: oldAttrs) { (r, e) in r[e.0] = e.1 }
                        let newText = NSMutableAttributedString(string: "Slide Theme", attributes: allParams)
                        string.replaceCharacters(in: match.range, with: newText)
                    }
                } catch {
                    
                }
            }
            string.enumerateAttributes(in: NSRange.init(location: 0, length: string.length), options: .longestEffectiveRangeNotRequired, using: { (attrs, range, _) in
                for attr in attrs {
                    if let isColor = attr.value as? UIColor {
                        if isColor.hexString() == "#0000FF" {
                            string.setAttributes([NSAttributedString.Key.foregroundColor: color, NSAttributedString.Key.backgroundColor: ColorUtil.theme.backgroundColor.withAlphaComponent(0.5), NSAttributedString.Key.font: UIFont(name: "Courier", size: font.pointSize) ?? font], range: range)
                        } else if isColor.hexString() == "#008000" {
                            string.setAttributes([NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key(rawValue: YYTextStrikethroughAttributeName): YYTextDecoration(style: YYTextLineStyle.single, width: 1, color: fontColor), NSAttributedString.Key.font: font], range: range)
                        }
                    } else if let url = attr.value as? URL {
                        if SettingValues.enlargeLinks {
                            string.addAttribute(NSAttributedString.Key.font, value: FontGenerator.boldFontOfSize(size: 18, submission: false), range: range)
                        }
                        string.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
                        string.addAttribute(convertToNSAttributedStringKey(kCTUnderlineColorAttributeName as String), value: UIColor.clear, range: range)
                        let type = ContentType.getContentType(baseUrl: url)
                        if SettingValues.showLinkContentType {
                            let typeString = NSMutableAttributedString.init(string: "", attributes: convertToOptionalNSAttributedStringKeyDictionary([:]))
                            switch type {
                            case .ALBUM:
                                typeString.mutableString.setString("(Album)")
                            case .TABLE:
                                typeString.mutableString.setString("(Table)")
                            case .EXTERNAL:
                                typeString.mutableString.setString("(External link)")
                            case .LINK, .EMBEDDED, .NONE:
                                if url.absoluteString != string.mutableString.substring(with: range) {
                                    typeString.mutableString.setString("(\(url.host ?? url.absoluteString))")
                                }
                            case .DEVIANTART, .IMAGE, .TUMBLR, .XKCD:
                                typeString.mutableString.setString("(Image)")
                            case .GIF:
                                typeString.mutableString.setString("(GIF)")
                            case .IMGUR:
                                typeString.mutableString.setString("(Imgur)")
                            case .VIDEO, .STREAMABLE, .VID_ME:
                                typeString.mutableString.setString("(Video)")
                            case .REDDIT:
                                typeString.mutableString.setString("(Reddit link)")
                            case .SPOILER:
                                typeString.mutableString.setString("")
                            default:
                                if url.absoluteString != string.mutableString.substring(with: range) {
                                    typeString.mutableString.setString("(\(url.host!))")
                                }
                            }
                            string.insert(typeString, at: range.location + range.length)
                            string.addAttributes(convertToNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor]), range: NSRange.init(location: range.location + range.length, length: typeString.length))
                        }
                        
                        if type != .SPOILER {
                            linksCallback?(url)
                            if let value = indexCallback?(), !SettingValues.disablePreviews {
                                let positionString = NSMutableAttributedString.init(string: " †\(value)", attributes: [NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10)])
                                string.insert(positionString, at: range.location + range.length)
                            }
                        }

                        string.yy_setTextHighlight(range, color: color, backgroundColor: nil, userInfo: ["url": url])
                        break
                    }
                }
            })
            string.beginEditing()
            string.enumerateAttribute(
                .font,
                in: NSRange(location: 0, length: string.length)
            ) { (value, range, _) in
                if let f = value as? UIFont,
                    let newFontDescriptor = font.fontDescriptor.withSymbolicTraits(f.fontDescriptor.symbolicTraits) {

                    let newFont = UIFont(
                        descriptor: newFontDescriptor,
                        size: f.pointSize
                    )

                    string.removeAttribute(.font, range: range)
                    string.addAttribute(.font, value: newFont, range: range)
                }
            }
            string.endEditing()
            string.highlightTarget(color: color)
        }
        return string
    }

}

// Used from https://gist.github.com/aquajach/4d9398b95a748fd37e88
extension NSMutableAttributedString {

    func highlightTarget(color: UIColor) {
        let regPattern = "\\[\\[s\\[(.*?)\\]s\\]\\]"
        if let regex = try? NSRegularExpression(pattern: regPattern, options: []) {
            let matchesArray = regex.matches(in: self.string, options: [], range: NSRange(location: 0, length: self.string.length))
            for match in matchesArray.reversed() {
                let copy = self.attributedSubstring(from: match.range)
                let text = copy.string
                let attributedText = NSMutableAttributedString(string: text.replacingOccurrences(of: "[[s[", with: "").replacingOccurrences(of: "]s]]", with: ""), attributes: copy.attributes(at: 0, effectiveRange: nil))
                attributedText.yy_textBackgroundBorder = YYTextBorder(fill: color, cornerRadius: 3)
                attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location: 0, length: attributedText.length))
                let highlight = YYTextHighlight()
                highlight.userInfo = ["spoiler": true]
                attributedText.yy_setTextHighlight(highlight, range: NSRange(location: 0, length: attributedText.length))
                self.replaceCharacters(in: match.range, with: attributedText)
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringKey(_ input: String) -> NSAttributedString.Key {
	return NSAttributedString.Key(rawValue: input)
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
