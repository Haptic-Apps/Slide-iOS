//
//  SpoilerTTTAttributedLabel.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/15/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import TTTAttributedLabel

public class WrapSpoilers: NSObject {
    
    public static func addSpoilers(_ text: String) -> String{
        do {
            
            var base = text
            var spoil = false
            let attrString = NSMutableAttributedString.init(string: base)
            
            for match in base.capturedGroups(withRegex: "<a[^>]*title=\"([^\"]*)\"[^>]*>([^<]*)</a>") {
                spoil = true
                var tag = match[0]
                var spoilerText = match[1]
                var spoilerTeaser = match[2]
                // Remove the last </a> tag, but keep the < for parsing.
                if (!tag.contains("<a href=\"http")) {
                    base = base.replacingOccurrences(of: tag, with: tag.substring(0, length: tag.length - 4) + (spoilerTeaser.isEmpty() ? "spoiler" : "") + " [[s[ \(spoilerText)]s]]</a>");
                }
            }
            
            //match unconventional spoiler tags
            for match in base.capturedGroups(withRegex: "<a href=\"([#/](?:spoiler|sp|s))\">([^<]*)</a>") {
                var newPiece = match[0]
                let inner = "<a href=\"/spoiler\">spoiler [[s[ \(newPiece.substring(newPiece.indexOf(">")! + 1, length: newPiece.lastIndexOf(">")!))]s]]</a>";
                base = base.replacingOccurrences(of: match[0], with: inner);
            }
            
            if(spoil){
            print(base)
            }
            return base
        } catch {
            return text
        }
        
    }
    
}
extension String {
    func capturedGroups(withRegex pattern: String) -> [[String]] {
        var results = [[String]]()
        
        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return results
        }
        
        let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.characters.count))
        
        for match in matches.reversed() {
        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return results }
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
