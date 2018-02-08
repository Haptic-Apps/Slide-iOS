//
//  CachedTitle.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/21/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import TTTAttributedLabel

class CachedTitle {
    static var titles: [String:NSAttributedString] = [:]
    static func addTitle(s: RSubmission){
        
    }
    
    static var titleFont = FontGenerator.fontOfSize(size: 18, submission: true)
    
    static func getTitle(submission: RSubmission, full: Bool,  _ refresh: Bool, _ white: Bool = false) -> NSAttributedString {
        let title = titles[submission.getId()]
        if(title == nil || refresh || full || white){
            if(white){
                return titleForSubmission(submission: submission, full: full, white: white)
            }
            if(!full) {
                titles[submission.getId()] = titleForSubmission(submission: submission, full: full, white: white)
                return titles[submission.getId()]!
            } else {
                return titleForSubmission(submission: submission, full: full, white: white)
            }
        } else {
            return title!
        }
    }
    
    static func titleForSubmission(submission: RSubmission, full: Bool, white: Bool) -> NSAttributedString{
        
        var colorF = ColorUtil.fontColor
        if(white){
            colorF = .white
        }
        
        let attributedTitle = NSMutableAttributedString(string: submission.title, attributes: [NSFontAttributeName: titleFont, NSForegroundColorAttributeName: colorF])
        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(submission.flair)\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(submission.gilded) ", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])
        
        let locked = NSMutableAttributedString.init(string: "\u{00A0}LOCKED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        
        let archived = NSMutableAttributedString.init(string: "\u{00A0}ARCHIVED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        
        let nsfw = NSMutableAttributedString.init(string: "\u{00A0}NSFW\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.red500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])

        let spacer = NSMutableAttributedString.init(string: "  ")
        if(!submission.flair.isEmpty){
            attributedTitle.append(spacer)
            attributedTitle.append(flairTitle)
        }
        if(submission.nsfw){
            attributedTitle.append(spacer)
            attributedTitle.append(nsfw)
        }

        if(submission.gilded > 0){
            attributedTitle.append(spacer)
            attributedTitle.append(spacer)
            let gild = NSMutableAttributedString.init(string: "G", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.amber500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
            attributedTitle.append(gild)
            if(submission.gilded > 1){
                attributedTitle.append(gilded)
            }
        }
        
        if(submission.stickied){
            attributedTitle.append(spacer)
            attributedTitle.append(pinned)
        }
        
        if(submission.locked){
            attributedTitle.append(spacer)
            attributedTitle.append(locked)
        }
        if(submission.archived){
            attributedTitle.append(archived)
        }
        
        let attrs = [NSFontAttributeName : FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF] as [String: Any]
        
        let endString = NSMutableAttributedString(string:"  •  \(DateFormatter().timeSince(from: submission.created, numericDates: true))\((submission.isEdited ? ("(edit \(DateFormatter().timeSince(from: submission.edited, numericDates: true)))") : ""))  •  ", attributes: [NSFontAttributeName : FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])
        
        let authorString = NSMutableAttributedString(string: "\u{00A0}\(submission.author)\u{00A0}", attributes: [NSFontAttributeName : FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])
        
        
        let userColor = ColorUtil.getColorForUser(name: submission.author)
        if (submission.distinguished == "admin") {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#E57373"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (submission.distinguished == "special") {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#F44336"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (submission.distinguished == "moderator") {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#81C784"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (AccountController.currentName == submission.author) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (userColor != ColorUtil.baseColor) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: userColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        }
        
        endString.append(authorString)
        if(SettingValues.domainInInfo && !full){
            endString.append(NSAttributedString.init(string: "  •  \(submission.domain)"))
        }
        
        let tag = ColorUtil.getTagForUser(name: submission.author)
        if(!tag.isEmpty){
            let tagString = NSMutableAttributedString(string: "\u{00A0}\(tag)\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: colorF])
            tagString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor(rgb: 0x2196f3), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
            endString.append(spacer)
            endString.append(tagString)
        }
        
        let boldString = NSMutableAttributedString(string:"/r/\(submission.subreddit)", attributes:attrs)
        
        let color = ColorUtil.getColorForSub(sub: submission.subreddit)
        if(color != ColorUtil.baseColor){
            boldString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: boldString.length))
        }
        
        let infoString = NSMutableAttributedString()
        infoString.append(boldString)
        infoString.append(endString)
        infoString.append(NSAttributedString.init(string: "\n"))
        infoString.append(attributedTitle)
        
        if(SettingValues.showFirstParagraph && submission.isSelf && !full && !submission.htmlBody.trimmed().isEmpty){
            infoString.append(NSAttributedString.init(string: "\n\n"))
            var length = submission.htmlBody.indexOf("\n")  ?? submission.htmlBody.length
            var text = submission.htmlBody.substring(0, length: length)
            do {
            let attr = try NSMutableAttributedString(data: (text.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
            let font = FontGenerator.fontOfSize(size: 14, submission: false)
            let bodyString = attr.reconstruct(with: font, color: colorF, linkColor: ColorUtil.accentColorForSub(sub: submission.subreddit))
                infoString.append(bodyString)
            } catch {
                
            }
        }
        
        if(SettingValues.scoreInTitle){
            infoString.append(NSAttributedString.init(string: "\n"))
            var scoreString: NSAttributedString = NSAttributedString()
            if(SettingValues.abbreviateScores){
                let text = (submission.score>=10000 && SettingValues.abbreviateScores) ? String(format: "%0.1fk ", (Double(submission.score)/Double(1000))) : " \(submission.score)"
                scoreString = NSMutableAttributedString(string: "\(text)pts \(submission.commentCount)cmts", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: colorF])
            }  else {
                scoreString = NSMutableAttributedString(string: "\(submission.score)pts \(submission.commentCount)cmts", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: colorF])
            }
            infoString.append(scoreString)
        }

        return  infoString
    }
}
