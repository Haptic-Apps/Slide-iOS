//
//  LinkParser.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/28/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import DTCoreText
import YYText
import UIKit

class LinkParser {
    public static func parse(_ attributedString: NSAttributedString, _ color: UIColor) -> NSMutableAttributedString {
        let string = NSMutableAttributedString.init(attributedString: attributedString)
        string.removeAttribute(convertToNSAttributedStringKey(kCTForegroundColorFromContextAttributeName as String), range: NSRange.init(location: 0, length: string.length))
        if string.length > 0 {
            while string.string.contains("slide://") {
                do {
                    let match = try NSRegularExpression(pattern: ".*?(slide:\\/\\/[a-zA-Z%?#0-9]+).*?", options: []).matches(in: string.string, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSRange(location: 0, length: string.length))[0]
                    let matchRange: NSRange = match.range(at: 1)
                    if matchRange.location != NSNotFound {
                        let attributedText = string.attributedSubstring(from: match.range).mutableCopy() as! NSMutableAttributedString
                        let newText = NSMutableAttributedString(string: "Slide Theme", attributes: attributedText.attributes(at: 0, effectiveRange: nil))
                        newText.addAttribute(NSAttributedString.Key.link, value: URL(string: attributedText.string), range: NSRange(location: 0, length: newText.length))
                        string.replaceCharacters(in: match.range, with: newText)
                    }
                } catch {
                    
                }
            }
            string.enumerateAttributes(in: NSRange.init(location: 0, length: string.length), options: .longestEffectiveRangeNotRequired, using: { (attrs, range, _) in
                for attr in attrs {
                    if let url = attr.value as? URL {
                        if SettingValues.enlargeLinks {
                            string.addAttribute(NSAttributedString.Key.font, value: FontGenerator.boldFontOfSize(size: 18, submission: false), range: range)
                        }
                        string.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
                        string.addAttribute(convertToNSAttributedStringKey(kCTUnderlineColorAttributeName as String), value: UIColor.clear, range: range)
                        let type = ContentType.getContentType(baseUrl: url)

                        if type == .SPOILER {
                            string.highlightTarget(color: color)
                        }

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
                                typeString.mutableString.setString("(Spoiler)")
                            default:
                                if url.absoluteString != string.mutableString.substring(with: range) {
                                    typeString.mutableString.setString("(\(url.host!))")
                                }
                            }
                            string.insert(typeString, at: range.location + range.length)
                            string.addAttributes(convertToNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor]), range: NSRange.init(location: range.location + range.length, length: typeString.length))
                        }
                        string.yy_setTextHighlight(range, color: color, backgroundColor: nil, userInfo: ["url": url])
                        break
                    }
                }
            })
        }
        return string
    }

}

// Used from https://gist.github.com/aquajach/4d9398b95a748fd37e88
extension NSMutableAttributedString {

    func highlightTarget(color: UIColor) {
        let regPattern = "\\[\\[s\\[(.*?)\\]s\\]\\]"
        if let regex = try? NSRegularExpression(pattern: regPattern, options: []) {
            let matchesArray = regex.matches(in: self.string, options: [], range: NSRange(location: 0, length: self.length))
            for match in matchesArray {
                let attributedText = self.attributedSubstring(from: match.range).mutableCopy() as! NSMutableAttributedString
                attributedText.addAttribute(NSAttributedString.Key.backgroundColor, value: color, range: NSRange(location: 0, length: attributedText.length))
                attributedText.addAttribute(convertToNSAttributedStringKey(kCTForegroundColorAttributeName as String), value: color, range: NSRange(location: 0, length: attributedText.length))
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
