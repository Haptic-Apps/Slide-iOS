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
    static var titles: [String: NSAttributedString] = [:]
    static var removed: [String] = []
    static var approved: [String] = []

    static func addTitle(s: RSubmission) {

    }

    static var titleFont = FontGenerator.fontOfSize(size: 18, submission: true)

    static func getTitle(submission: RSubmission, full: Bool, _ refresh: Bool, _ white: Bool = false) -> NSAttributedString {
        let title = titles[submission.getId()]
        if (title == nil || refresh || full || white) {
            if (white) {
                return titleForSubmission(submission: submission, full: full, white: white)
            }
            if (!full) {
                titles[submission.getId()] = titleForSubmission(submission: submission, full: full, white: white)
                return titles[submission.getId()]!
            } else {
                return titleForSubmission(submission: submission, full: full, white: white)
            }
        } else {
            return title!
        }
    }

    static func titleForSubmission(submission: RSubmission, full: Bool, white: Bool) -> NSAttributedString {

        var colorF = ColorUtil.fontColor
        if (white) {
            colorF = .white
        }

        let attributedTitle = NSMutableAttributedString(string: submission.title, attributes: [NSFontAttributeName: titleFont, NSForegroundColorAttributeName: colorF])
        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(submission.flair)\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(submission.gilded) ", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])

        let locked = NSMutableAttributedString.init(string: "\u{00A0}LOCKED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])

        let archived = NSMutableAttributedString.init(string: "\u{00A0}ARCHIVED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])

        let nsfw = NSMutableAttributedString.init(string: "\u{00A0}NSFW\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.red500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])

        let spoiler = NSMutableAttributedString.init(string: "\u{00A0}SPOILER\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.grey50Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.black, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])

        let spacer = NSMutableAttributedString.init(string: "  ")
        if (!submission.flair.isEmpty) {
            attributedTitle.append(spacer)
            attributedTitle.append(flairTitle)
        }
        if (submission.nsfw) {
            attributedTitle.append(spacer)
            attributedTitle.append(nsfw)
        }

        if (submission.spoiler) {
            attributedTitle.append(spacer)
            attributedTitle.append(spoiler)
        }

        if (submission.gilded > 0) {
            attributedTitle.append(spacer)
            attributedTitle.append(spacer)
            let gild = NSMutableAttributedString.init(string: "G", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.amber500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
            attributedTitle.append(gild)
            if (submission.gilded > 1) {
                attributedTitle.append(gilded)
            }
        }

        if (submission.stickied) {
            attributedTitle.append(spacer)
            attributedTitle.append(pinned)
        }

        if (submission.locked) {
            attributedTitle.append(spacer)
            attributedTitle.append(locked)
        }
        if (submission.archived) {
            attributedTitle.append(archived)
        }

        let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF] as [String: Any]

        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: submission.created, numericDates: true))\((submission.isEdited ? ("(edit \(DateFormatter().timeSince(from: submission.edited, numericDates: true)))") : ""))  •  ", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])

        let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: submission.author, small: false))\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])


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
        if (SettingValues.domainInInfo && !full) {
            endString.append(NSAttributedString.init(string: "  •  \(submission.domain)", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF]))
        }

        let tag = ColorUtil.getTagForUser(name: submission.author)
        if (!tag.isEmpty) {
            let tagString = NSMutableAttributedString(string: "\u{00A0}\(tag)\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: colorF])
            tagString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor(rgb: 0x2196f3), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: tagString.length))
            endString.append(spacer)
            endString.append(tagString)
        }

        let boldString = NSMutableAttributedString(string: "r/\(submission.subreddit)", attributes: attrs)

        let color = ColorUtil.getColorForSub(sub: submission.subreddit)
        if (color != ColorUtil.baseColor) {
            boldString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: boldString.length))
        }

        let infoString = NSMutableAttributedString()
        infoString.append(boldString)
        infoString.append(endString)
        infoString.append(NSAttributedString.init(string: "\n"))
        infoString.append(attributedTitle)
        if (SettingValues.scoreInTitle) {
            infoString.append(NSAttributedString.init(string: "\n"))
            var scoreString: NSAttributedString = NSAttributedString()
            if (SettingValues.abbreviateScores) {
                let text = (submission.score >= 10000 && SettingValues.abbreviateScores) ? String(format: "%0.1fk ", (Double(submission.score) / Double(1000))) : " \(submission.score)"
                scoreString = NSMutableAttributedString(string: "\(text)pts \(submission.commentCount)cmts", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: colorF])
            } else {
                scoreString = NSMutableAttributedString(string: "\(submission.score)pts \(submission.commentCount)cmts", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: colorF])
            }
            infoString.append(scoreString)
        }
        
        if(removed.contains(submission.id) || (!submission.removedBy.isEmpty() && !approved.contains(submission.id))){
            let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: GMColor.red500Color()] as [String: Any]
            infoString.append(spacer)
            if(submission.removedBy == "true"){
                infoString.append(NSMutableAttributedString.init(string: "Removed by Reddit\(!submission.removalReason.isEmpty() ? ":\(submission.removalReason)" : "")", attributes: attrs))
            } else {
                infoString.append(NSMutableAttributedString.init(string: "Removed\(!submission.removedBy.isEmpty() ? "by \(submission.removedBy)" : "")\(!submission.removalReason.isEmpty() ? " for \(submission.removalReason)" : "")\(!submission.removalNote.isEmpty() ? " \(submission.removalNote)" : "")", attributes: attrs))
            }
        } else if(approved.contains(submission.id) || (!submission.approvedBy.isEmpty() && !removed.contains(submission.id))){
            let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: GMColor.green500Color()] as [String: Any]
            infoString.append(spacer)
            infoString.append(NSMutableAttributedString.init(string: "Approved\(!submission.approvedBy.isEmpty() ? " by \(submission.approvedBy)":"")", attributes: attrs))
        }

        if (submission.isCrosspost && !full) {
            infoString.append(NSAttributedString.init(string: "\n\n"))

            let endString = NSMutableAttributedString(string: "Crossposted to ", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])
            let by = NSMutableAttributedString(string: " by ", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])

            let boldString = NSMutableAttributedString(string: "r/\(submission.crosspostSubreddit)", attributes: attrs)

            let color = ColorUtil.getColorForSub(sub: submission.crosspostSubreddit)
            if (color != ColorUtil.baseColor) {
                boldString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: boldString.length))
            }

            endString.append(boldString)

            let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: submission.author, small: false))\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])


            let userColor = ColorUtil.getColorForUser(name: submission.crosspostAuthor)
            if (AccountController.currentName == submission.author) {
                authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
            } else if (userColor != ColorUtil.baseColor) {
                authorString.addAttributes([kTTTBackgroundFillColorAttributeName: userColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
            }

            endString.append(by)
            endString.append(authorString)
            let tag = ColorUtil.getTagForUser(name: submission.author)
            if (!tag.isEmpty) {
                let tagString = NSMutableAttributedString(string: "\u{00A0}\(tag)\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: colorF])
                tagString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor(rgb: 0x2196f3), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: tagString.length))
                endString.append(spacer)
                endString.append(tagString)
            }
            infoString.append(endString)
        }


        if (SettingValues.showFirstParagraph && submission.isSelf && !full && !submission.htmlBody.trimmed().isEmpty) {
            infoString.append(NSAttributedString.init(string: "\n\n"))
            var length = submission.htmlBody.indexOf("\n") ?? submission.htmlBody.length
            var text = submission.htmlBody.substring(0, length: length)
            do {
                let attr = try NSMutableAttributedString(data: (text.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                let font = FontGenerator.fontOfSize(size: 14, submission: false)
                let bodyString = attr.reconstruct(with: font, color: colorF, linkColor: ColorUtil.accentColorForSub(sub: submission.subreddit))
                infoString.append(bodyString)
            } catch {

            }
        }


        return infoString
    }
}
