//
//  LinkParser.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/28/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import DTCoreText
import UIKit

class LinkParser {
    public static func parse(_ attributedString: NSAttributedString, _ color: UIColor, font: UIFont, bold: UIFont? = nil, fontColor: UIColor, linksCallback: ((URL) -> Void)?, indexCallback: (() -> Int)?) -> NSMutableAttributedString {
        var finalBold: UIFont
        if bold == nil {
            finalBold = font.makeBold()
        } else {
            finalBold = bold!
        }
        
        let string = NSMutableAttributedString.init(attributedString: attributedString)
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
                            //Is a code block (for some reason)
                            string.setAttributes([NSAttributedString.Key.foregroundColor: color, NSAttributedString.Key.backgroundColor: ColorUtil.theme.backgroundColor.withAlphaComponent(0.5), NSAttributedString.Key.font: UIFont(name: "Courier", size: font.pointSize) ?? font], range: range)
                        } else if isColor.hexString() == "#008000" {
                            //Is strikethrough (for some reason)
                            string.setAttributes([NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.strikethroughStyle: 2, NSAttributedString.Key.strikethroughColor: fontColor, NSAttributedString.Key.font: font], range: range)
                        }
                    } else if let url = attr.value as? URL {
                        if SettingValues.enlargeLinks {
                            string.addAttribute(NSAttributedString.Key.font, value: FontGenerator.boldFontOfSize(size: 18, submission: false), range: range)
                        }
                        string.removeAttribute(.foregroundColor, range: range)
                        string.removeAttribute(.link, range: range)
                        string.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
                        string.addAttribute(.underlineStyle, value: 0, range: range)
                        let type = ContentType.getContentType(baseUrl: url)
                        if SettingValues.showLinkContentType {
                            let typeString = NSMutableAttributedString.init(string: "", attributes: [:])
                            switch type {
                            case .ALBUM:
                                typeString.mutableString.setString("(Album)")
                            case .REDDIT_GALLERY:
                                typeString.mutableString.setString("(Gallery)")
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
                            string.addAttributes([NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: fontColor], range: NSRange.init(location: range.location + range.length, length: typeString.length))
                        }
                        
                        if type != .SPOILER {
                            linksCallback?(url)
                            if let value = indexCallback?(), !SettingValues.disablePreviews {
                                let positionString = NSMutableAttributedString.init(string: " †\(value)", attributes: [NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10)])
                                string.insert(positionString, at: range.location + range.length)
                            }
                        }

                        string.addAttribute(.textHighlight, value: TextHighlight(["url": url]), range: NSRange(location: range.location, length: range.length))
                        break
                    }
                }
            })
            string.beginEditing()
            string.enumerateAttribute(
                .font,
                in: NSRange(location: 0, length: string.length)
            ) { (value, range, _) in
                
                if let f = value as? UIFont {
                    let isItalic = f.fontDescriptor.symbolicTraits.contains(UIFontDescriptor.SymbolicTraits.traitItalic)
                    let isBold = f.fontDescriptor.symbolicTraits.contains(UIFontDescriptor.SymbolicTraits.traitBold)
                    
                    var newFont = font.withSize(f.pointSize)
                    if isBold {
                        newFont = finalBold.withSize(f.pointSize)
                    }

                    if isItalic {
                        newFont = newFont.withTraits(traits: .traitItalic)
                    }
                    
                    string.removeAttribute(.font, range: range)
                    if isItalic {
                        string.addAttributes([.font: newFont, .foregroundColor: fontColor], range: range)
                    } else {
                        string.addAttribute(.font, value: newFont, range: range)
                    }
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
                attributedText.addAttributes([NSAttributedString.Key.foregroundColor: color, .badgeColor: color, .textHighlight: TextHighlight(["spoiler": true, "attributedText": attributedText.string])], range: NSRange(location: 0, length: attributedText.length))
                self.replaceCharacters(in: match.range, with: attributedText)
            }
        }
    }
}
