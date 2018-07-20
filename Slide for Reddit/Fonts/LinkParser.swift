//
//  LinkParser.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/28/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import DTCoreText
import TTTAttributedLabel
import UIKit

class LinkParser {
    public static func parse(_ attributedString: NSAttributedString, _ color: UIColor) -> NSMutableAttributedString {
        let string = NSMutableAttributedString.init(attributedString: attributedString)
        string.removeAttribute(kCTForegroundColorFromContextAttributeName as String, range: NSRange.init(location: 0, length: string.length))
        if (string.length > 0) {
            string.enumerateAttributes(in: NSRange.init(location: 0, length: string.length), options: .longestEffectiveRangeNotRequired, using: { (attrs, range, _) in
                for attr in attrs {
                    if let url = attr.value as? URL {
                        if (SettingValues.enlargeLinks) {
                            string.addAttribute(NSFontAttributeName, value: FontGenerator.boldFontOfSize(size: 18, submission: false), range: range)
                        }
                        string.addAttribute(NSForegroundColorAttributeName, value: color, range: range)
                        string.addAttribute(kCTUnderlineColorAttributeName as String, value: UIColor.clear, range: range)
                        let type = ContentType.getContentType(baseUrl: url)

                        if (type == .SPOILER) {
                            string.highlightTarget(color: color)
                        }

                        if (SettingValues.showLinkContentType) {

                            let typeString = NSMutableAttributedString.init(string: "", attributes: [:])
                            switch (type) {
                            case .ALBUM:
                                typeString.mutableString.setString("(Album)")
                            case .TABLE:
                                typeString.mutableString.setString("(Table)")
                            case .EXTERNAL:
                                typeString.mutableString.setString("(External link)")
                            case .LINK, .EMBEDDED, .NONE:
                                if (url.absoluteString != string.mutableString.substring(with: range)) {
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
                                if (url.absoluteString != string.mutableString.substring(with: range)) {
                                    typeString.mutableString.setString("(\(url.host!))")
                                }
                            }
                            string.insert(typeString, at: range.location + range.length)
                            string.addAttributes([NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor], range: NSRange.init(location: range.location + range.length, length: typeString.length))
                        }
                        string.addAttribute(kCTForegroundColorAttributeName as String, value: color, range: range)
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
                attributedText.addAttribute(NSBackgroundColorAttributeName, value: color, range: NSRange(location: 0, length: attributedText.length))
                attributedText.addAttribute(kCTForegroundColorAttributeName as String, value: color, range: NSRange(location: 0, length: attributedText.length))
                self.replaceCharacters(in: match.range, with: attributedText)
            }
        }
    }
}
