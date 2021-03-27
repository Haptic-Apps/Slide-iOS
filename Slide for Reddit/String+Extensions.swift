//
//  String+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

extension String {
    
    func indexInt(of char: Character) -> Int? {
        return firstIndex(of: char)?.utf16Offset(in: self)
    }

    func toAttributedString() -> NSAttributedString? {
        guard let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false) else {
            return nil
        }

        let htmlString = try? NSMutableAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue, NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)

        return htmlString
    }

    func size(with: UIFont) -> CGSize {
        let fontAttribute = [NSAttributedString.Key.font: with]
        let size = self.size(withAttributes: fontAttribute)  // for Single Line
        return size
    }
    
    func toBase64() -> String? {
        guard let data = self.data(using: String.Encoding.utf8) else {
            return nil
        }
        
        return data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
}

// Mapping from XML/HTML character entity reference to character
// From http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
// From https://stackoverflow.com/a/30141700/7138792
private let characterEntities: [String: Character] = [
    // XML predefined entities:
    "&quot;": "\"",
    "&amp;": "&",
    "&apos;": "'",
    "&lt;": "<",
    "&gt;": ">",

    // HTML character entity references:
    "&nbsp;": "\u{00a0}",
]

extension String {
    func insertingZeroWidthSpacesBeforeCaptials() -> String {
        var str = ""
        for (i, char) in self.enumerated() {
            let charStr = String(char)
            if i != 0 && charStr.lowercased() != charStr {
                str += "\u{200B}"
            }
            str += charStr
        }
        return str
    }
}

extension String {
    func getSubredditFormatted() -> String {
        if self.hasPrefix("/m/") {
            return self.replacingOccurrences(of: "/m/", with: "m/")
        }
        
        if self.hasPrefix("u_") {
            return self.replacingOccurrences(of: "u_", with: "u/")
        }
        
        if self.hasPrefix("/r/") {
            return self.replacingOccurrences(of: "/r/", with: "r/")
        }

        if self.hasPrefix("r/") {
            return self
        } else {
            return "r/\(self)"
        }
    }
    
    func getSubredditFormattedShort() -> String {
        if self.hasPrefix("/m/") {
            return self.replacingOccurrences(of: "/m/", with: "m/")
        }
        
        if self.hasPrefix("u_") {
            return self.replacingOccurrences(of: "u_", with: "u/")
        }
        
        if self.hasPrefix("/r/") {
            return self.replacingOccurrences(of: "/r/", with: "")
        }

        return self
    }
}
