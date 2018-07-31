//
//  SpoilerTTTAttributedLabel.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/15/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import TTTAttributedLabel
import UIKit

public class WrapSpoilers: NSObject {
    
    public static func addSpoilers(_ text: String) -> String {
        var base = text
        
        for match in base.capturedGroups(withRegex: "<a[^>]*title=\"([^\"]*)\"[^>]*>([^<]*)</a>") {
            let tag = match[0]
            let spoilerText = match[1]
            let spoilerTeaser = match[2]
            // Remove the last </a> tag, but keep the < for parsing.
            if !tag.contains("<a href=\"http") {
                base = base.replacingOccurrences(of: tag, with: tag.substring(0, length: tag.length - 4) + (spoilerTeaser.isEmpty() ? "spoiler" : "") + " [[s[ \(spoilerText)]s]]</a> ")
            }
        }
        
        //match unconventional spoiler tags
        for match in base.capturedGroups(withRegex: "<a href=\"([#/](?:spoiler|sp|s))\">([^<]*)</a>") {
            let newPiece = match[0]
            let inner = "<a href=\"/spoiler\">spoiler [[s[ \(newPiece.subsequence(newPiece.indexOf(">")! + 1, endIndex: newPiece.lastIndexOf("<")!))]s]]</a> "
            base = base.replacingOccurrences(of: match[0], with: inner)
        }
        
        //match native Reddit spoilers
        for match in base.capturedGroups(withRegex: "<span class=\"[^\"]*md-spoiler-text+[^\"]*\">([^<]*)</span>") {
            let tag = match[0]
            let spoilerText = match[1]
            base = base.replacingOccurrences(of: tag, with: "<a href=\"/spoiler\">spoiler  [[s[ \(spoilerText)]s]]</a> ")
        }
        
        return base
    }
    
    public static func addTables(_ text: String) -> String {
        var base = text
        for match in base.capturedGroups(withRegex: "<table>(.*?)</table>") {
            let newPiece = match[0]
            let tableEscaped = newPiece.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            let inner = "\n<h1><a href=\"http://view.table/\(tableEscaped)\">View table</a></h1>\n"
            base = base.replacingOccurrences(of: match[0], with: inner)
        }
        
        return base
    }
    
}

extension String {
    func capturedGroups(withRegex pattern: String) -> [[String]] {
        var results = [[String]]()
        
        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [NSRegularExpression.Options.dotMatchesLineSeparators])
        } catch {
            return results
        }
        
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.length))
        
        for match in matches.reversed() {
            let lastRangeIndex = match.numberOfRanges - 1
            guard lastRangeIndex >= 1 else {
                return results
            }
            var res = [String]()
            res.append((self as NSString).substring(with: match.rangeAt(0)))
            for i in 1...lastRangeIndex {
                let capturedGroupIndex = match.rangeAt(i)
                let matchedString = (self as NSString).substring(with: capturedGroupIndex)
                res.append(matchedString)
            }
            results.append(res)
        }
        
        return results
    }
}
