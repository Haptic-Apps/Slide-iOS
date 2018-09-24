//
//  SubmissionRowController.swift
//  Slide for Apple Watch Extension
//
//  Created by Carlos Crane on 9/23/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation
import WatchKit

public class SubmissionRowController: NSObject {
    
    @IBOutlet weak var bannerImage: WKInterfaceImage!
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    
    func getTitle(dictionary: NSDictionary) -> NSAttributedString {
        let titleFont = UIFont.systemFont(ofSize: 12)
        let subtitleFont = UIFont.boldSystemFont(ofSize: 10)
        let attributedTitle = NSMutableAttributedString(string: dictionary["title"] as! String, attributes: [NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: UIColor.white])
        
        let nsfw = NSMutableAttributedString.init(string: "\u{00A0}NSFW\u{00A0}", attributes: [NSAttributedString.Key.foregroundColor: UIColor.red, NSAttributedString.Key.font: subtitleFont])
        
        let spoiler = NSMutableAttributedString.init(string: "\u{00A0}SPOILER\u{00A0}", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: subtitleFont])

        let spacer = NSMutableAttributedString.init(string: "  ")
        if let flair = dictionary["link_flair_text"] as? String {
            attributedTitle.append(spacer)
            attributedTitle.append(NSMutableAttributedString.init(string: "\u{00A0}\(flair)\u{00A0}", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: subtitleFont]))
        }
        
        if let isNsfw = dictionary["nsfw"] as? Bool, isNsfw == true {
            attributedTitle.append(spacer)
            attributedTitle.append(nsfw)
        }
        
        if let nsfw = dictionary["spoiler"] as? Bool, nsfw == true {
            attributedTitle.append(spacer)
            attributedTitle.append(spoiler)
        }
        
        let attrs = [NSAttributedString.Key.font: subtitleFont, NSAttributedString.Key.foregroundColor: UIColor.white]
        
        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: NSDate.init(timeIntervalSince1970: TimeInterval(dictionary["created"] as? Int ?? 0)), numericDates: true))  •  ", attributes: [NSAttributedString.Key.font: subtitleFont])
        
        let authorString = NSMutableAttributedString(string: "\u{00A0}u/\(dictionary["author"] as? String ?? "")\u{00A0}", attributes: [NSAttributedString.Key.font: subtitleFont, NSAttributedString.Key.foregroundColor: UIColor.gray])
        
        endString.append(authorString)
//        if SettingValues.domainInInfo && !full {
//            endString.append(NSAttributedString.init(string: "  •  \(submission.domain)", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF]))
//        }
//
//        let tag = ColorUtil.getTagForUser(name: submission.author)
//        if !tag.isEmpty {
//            let tagString = NSMutableAttributedString(string: "\u{00A0}\(tag)\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: colorF])
//            tagString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor(rgb: 0x2196f3), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: tagString.length))
//            endString.append(spacer)
//            endString.append(tagString)
//        }
//
        let boldString = NSMutableAttributedString(string: "r/\(dictionary["subreddit"] ?? "")", attributes: attrs)
        
            boldString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSRange.init(location: 0, length: boldString.length))
        
        let infoString = NSMutableAttributedString()
            infoString.append(boldString)
            infoString.append(endString)
            infoString.append(NSAttributedString.init(string: "\n"))
            infoString.append(attributedTitle)
        
//            infoString.append(NSAttributedString.init(string: "\n"))
//            var sColor = UIColor.white
//            switch ActionStates.getVoteDirection(s: submission) {
//            case .down:
//                sColor = ColorUtil.downvoteColor
//            case .up:
//                sColor = ColorUtil.upvoteColor
//            case .none:
//                break
//            }
//
//            let subScore = NSMutableAttributedString(string: (submission.score >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk points", (Double(submission.score) / Double(1000))) : " \(submission.score) points", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: sColor])
//
//            infoString.append(subScore)
//
//            if SettingValues.scoreInTitle {
//                infoString.append(spacer)
//            }
//            let scoreString = NSMutableAttributedString(string: "\(submission.commentCount) comments", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: colorF])
//            infoString.append(scoreString)
        return infoString
    }
}
extension DateFormatter {
    /**
     Formats a date as the time since that date (e.g., “Last week, yesterday, etc.”).
     
     - Parameter from: The date to process.
     - Parameter numericDates: Determines if we should return a numeric variant, e.g. "1 month ago" vs. "Last month".
     
     - Returns: A string with formatted `date`.
     */
    func timeSince(from: NSDate, numericDates: Bool = false) -> String {
        let calendar = Calendar.current
        let now = NSDate()
        let earliest = now.earlierDate(from as Date)
        let latest = earliest == now as Date ? from : now
        let components = calendar.dateComponents([.year, .day, .hour, .minute, .second], from: earliest, to: latest as Date)
        
        var result = ""
        
        if components.year! >= 2 {
            result = "\(components.year!)y"
        } else if components.year! >= 1 {
            if numericDates {
                result = "1y"
            } else {
                result = "Last year"
            }
        } else if components.day! >= 2 {
            result = "\(components.day!)d"
        } else if components.day! >= 1 {
            if numericDates {
                result = "1d"
            } else {
                result = "Yesterday"
            }
        } else if components.hour! >= 2 {
            result = "\(components.hour!)h"
        } else if components.hour! >= 1 {
            if numericDates {
                result = "1h"
            } else {
                result = "An hour ago"
            }
        } else if components.minute! >= 2 {
            result = "\(components.minute!)m"
        } else if components.minute! >= 1 {
            if numericDates {
                result = "1m"
            } else {
                result = "A minute ago"
            }
        } else if components.second! >= 3 {
            result = "\(components.second!)s"
        } else {
            result = "Just now"
        }
        
        return result
    }
}
