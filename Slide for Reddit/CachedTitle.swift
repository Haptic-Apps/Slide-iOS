//
//  CachedTitle.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/21/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import YYText

struct Title {
    var mainTitle: NSAttributedString?
    var infoLine: NSAttributedString?
    var extraLine: NSAttributedString?
    var color: UIColor
}

class CachedTitle {
    static var titles: [String: Title] = [:]
    static var removed: [String] = []
    static var approved: [String] = []
    static var spacer = NSMutableAttributedString.init(string: "  ")

    static let baseFontSize: CGFloat = 18

    static func addTitle(s: RSubmission) {
        titles[s.getId()] = titleForSubmission(submission: s, full: false, white: false, gallery: false)
    }

    static var titleFont = FontGenerator.fontOfSize(size: baseFontSize, submission: true)
    static var titleFontSmall = FontGenerator.fontOfSize(size: 14, submission: true)

    static func getTitle(submission: RSubmission, full: Bool, _ refresh: Bool, _ white: Bool = false, gallery: Bool) -> Title {
        let title = titles[submission.getId()]
        if title == nil || refresh || full || white || gallery {
            if white {
                return titleForSubmission(submission: submission, full: full, white: white, gallery: gallery)
            }
            if !full {
                titles[submission.getId()] = titleForSubmission(submission: submission, full: full, white: white, gallery: gallery)
                return titles[submission.getId()]!
            } else {
                return titleForSubmission(submission: submission, full: full, white: white, gallery: gallery)
            }
        } else {
            return title!
        }
    }
    
    static func getTitleForMedia(submission: RSubmission) -> Title {
        return titleForMedia(submission: submission)
    }

    static func titleForSubmission(submission: RSubmission, full: Bool, white: Bool, gallery: Bool) -> Title {

        var colorF = ColorUtil.theme.fontColor
        if white {
            colorF = .white
        }
        let brightF = colorF
        colorF = colorF.add(overlay: ColorUtil.theme.foregroundColor.withAlphaComponent(0.20))

        if gallery {
            let attributedTitle = NSMutableAttributedString(string: submission.title.unescapeHTML, attributes: [NSAttributedString.Key.font: titleFontSmall, NSAttributedString.Key.foregroundColor: brightF])

            return Title(mainTitle: attributedTitle, color: colorF)
        }
        let attributedTitle = NSMutableAttributedString(string: submission.title.unescapeHTML, attributes: [NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: brightF])

        if !submission.flair.isEmpty {
            let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(submission.flair)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: ColorUtil.theme.backgroundColor, cornerRadius: 3), NSAttributedString.Key.foregroundColor: brightF])

            attributedTitle.append(spacer)
            attributedTitle.append(flairTitle)
        }
        
        if submission.nsfw {
            let nsfw = NSMutableAttributedString.init(string: "\u{00A0}NSFW\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: GMColor.red500Color(), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white])

            attributedTitle.append(spacer)
            attributedTitle.append(nsfw)
        }

        if submission.spoiler {
            let spoiler = NSMutableAttributedString.init(string: "\u{00A0}SPOILER\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: GMColor.grey50Color(), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.black])

            attributedTitle.append(spacer)
            attributedTitle.append(spoiler)
        }

        if submission.oc {
            let oc = NSMutableAttributedString.init(string: "\u{00A0}OC\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: GMColor.blue50Color(), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.black])

            attributedTitle.append(spacer)
            attributedTitle.append(oc)
        }

        
        /*if submission.cakeday {
            attributedTitle.append(spacer)
            let gild = NSMutableAttributedString(string: "🍰", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true)])
            attributedTitle.append(gild)
        }*/

        if submission.stickied {
            let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: GMColor.green500Color(), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white])

            attributedTitle.append(spacer)
            attributedTitle.append(pinned)
        }

        if submission.locked {
            let locked = NSMutableAttributedString.init(string: "\u{00A0}LOCKED\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: GMColor.green500Color(), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white])

            attributedTitle.append(spacer)
            attributedTitle.append(locked)
        }
        if submission.archived {
            let archived = NSMutableAttributedString.init(string: "\u{00A0}ARCHIVED\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: ColorUtil.theme.backgroundColor, cornerRadius: 3), NSAttributedString.Key.foregroundColor: brightF])

            attributedTitle.append(archived)
        }


        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: submission.created, numericDates: true))\((submission.isEdited ? ("(edit \(DateFormatter().timeSince(from: submission.edited, numericDates: true)))") : ""))  •  ", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: colorF])

        let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: submission.author + (submission.cakeday ? " 🎂" : ""), small: false))\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: colorF])
        authorString.yy_setTextHighlight(NSRange(location: 0, length: authorString.length), color: nil, backgroundColor: nil, userInfo: ["url": URL(string: "/u/\(submission.author)")!, "profile": submission.author])

        let userColor = ColorUtil.getColorForUser(name: submission.author)
        if submission.distinguished == "admin" {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: UIColor.init(hexString: "#E57373"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if submission.distinguished == "special" {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: UIColor.init(hexString: "#F44336"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if submission.distinguished == "moderator" {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: UIColor.init(hexString: "#81C784"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if AccountController.currentName == submission.author {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: UIColor.init(hexString: "#FFB74D"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if userColor != ColorUtil.baseColor {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: userColor, cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        }

        endString.append(authorString)
        if SettingValues.domainInInfo && !full {
            endString.append(NSAttributedString.init(string: "  •  \(submission.domain)", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: colorF]))
        }

        let tag = ColorUtil.getTagForUser(name: submission.author)
        if tag != nil {
            let tagString = NSMutableAttributedString.init(string: "\u{00A0}\(tag!)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: UIColor(rgb: 0x2196f3), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white])

            endString.append(spacer)
            endString.append(tagString)
        }
        
        let infoLine = NSMutableAttributedString()
        var finalTitle: NSMutableAttributedString
        
        if SettingValues.newIndicator && !History.getSeen(s: submission) {
            finalTitle = NSMutableAttributedString(string: "•  ", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: ColorUtil.accentColorForSub(sub: submission.subreddit)])
        } else {
            finalTitle = NSMutableAttributedString()
        }
        
        let extraLine = NSMutableAttributedString()
        finalTitle.append(attributedTitle)
        infoLine.append(endString)
                
        if !full {
            if SettingValues.scoreInTitle {
                var sColor = ColorUtil.theme.fontColor.add(overlay: ColorUtil.theme.foregroundColor.withAlphaComponent(0.15))
                switch ActionStates.getVoteDirection(s: submission) {
                case .down:
                    sColor = ColorUtil.downvoteColor
                case .up:
                    sColor = ColorUtil.upvoteColor
                case .none:
                    break
                }
                
                var scoreInt = submission.score
                switch ActionStates.getVoteDirection(s: submission) {
                case .up:
                    if submission.likes != .up {
                        if submission.likes == .down {
                            scoreInt += 1
                        }
                        scoreInt += 1
                    }
                case .down:
                    if submission.likes != .down {
                        if submission.likes == .up {
                            scoreInt -= 1
                        }
                        scoreInt -= 1
                    }
                case .none:
                    if submission.likes == .up && submission.author == AccountController.currentName {
                        scoreInt -= 1
                    }
                }
                let upvoteImage = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")!.getCopy(withColor: ColorUtil.theme.fontColor), fontSize: titleFont.pointSize * 0.45)!

                let subScore = NSMutableAttributedString(string: (scoreInt >= 10000 && SettingValues.abbreviateScores) ? String(format: "%0.1fk", (Double(scoreInt) / Double(1000))) : "\(scoreInt)", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: sColor])
                
                extraLine.append(upvoteImage)
                extraLine.append(subScore)
            }
            
            if SettingValues.commentsInTitle {
                if SettingValues.scoreInTitle {
                    extraLine.append(spacer)
                }
                let commentImage = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(sfString: SFSymbol.bubbleRightFill, overrideString: "comments")!.getCopy(withColor: ColorUtil.theme.fontColor), fontSize: titleFont.pointSize * 0.5)!

                let scoreString = NSMutableAttributedString(string: "\(submission.commentCount)", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: colorF])
                extraLine.append(commentImage)
                extraLine.append(scoreString)
            }
        }
        
        if removed.contains(submission.id) || (!submission.removedBy.isEmpty() && !approved.contains(submission.id)) {
            let attrs = [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: GMColor.red500Color()] as [NSAttributedString.Key: Any]
            extraLine.append(spacer)
            if submission.removedBy == "true" {
                extraLine.append(NSMutableAttributedString.init(string: "Removed by Reddit\(!submission.removalReason.isEmpty() ? ":\(submission.removalReason)" : "")", attributes: attrs))
            } else {
                extraLine.append(NSMutableAttributedString.init(string: "Removed\(!submission.removedBy.isEmpty() ? "by \(submission.removedBy)" : "")\(!submission.removalReason.isEmpty() ? " for \(submission.removalReason)" : "")\(!submission.removalNote.isEmpty() ? " \(submission.removalNote)" : "")", attributes: attrs))
            }
        } else if approved.contains(submission.id) || (!submission.approvedBy.isEmpty() && !removed.contains(submission.id)) {
            let attrs = [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: GMColor.green500Color()] as [NSAttributedString.Key: Any]
            extraLine.append(spacer)
            extraLine.append(NSMutableAttributedString.init(string: "Approved\(!submission.approvedBy.isEmpty() ? " by \(submission.approvedBy)":"")", attributes: attrs))
        }
        
        if SettingValues.typeInTitle {
            let info = NSMutableAttributedString.init(string: "\u{00A0}\u{00A0}\(submission.type.rawValue)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: ColorUtil.theme.fontColor, cornerRadius: 3), NSAttributedString.Key.foregroundColor: ColorUtil.theme.foregroundColor])
            finalTitle.append(spacer)
            finalTitle.append(info)
        }

        if submission.isCrosspost && !full {
            if extraLine.string.length > 0 {
                extraLine.append(NSAttributedString.init(string: "\n"))
            }
            
            let crosspost = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: "crosspost")!.getCopy(withColor: ColorUtil.theme.fontColor), fontSize: titleFont.pointSize * 0.75)!

            let finalText = NSMutableAttributedString.init(string: " Crossposted from ", attributes: [NSAttributedString.Key.foregroundColor: colorF, NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true)])
            
            let attrs = [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: colorF] as [NSAttributedString.Key: Any]
            
            let boldString = NSMutableAttributedString(string: "r/\(submission.crosspostSubreddit)", attributes: attrs)
            
            let color = ColorUtil.getColorForSub(sub: submission.crosspostSubreddit)
            if color != ColorUtil.baseColor {
                boldString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange.init(location: 0, length: boldString.length))
            }
            
            crosspost.append(finalText)
            crosspost.append(boldString)
            extraLine.append(crosspost)
        }

        if SettingValues.showFirstParagraph && submission.isSelf && !submission.spoiler && !submission.nsfw && !full && !submission.body.trimmed().isEmpty {
            let length = submission.htmlBody.indexOf("\n") ?? submission.htmlBody.length
            let text = submission.htmlBody.substring(0, length: length).trimmed()

            if !text.isEmpty() {
                extraLine.append(NSAttributedString.init(string: "\n")) //Extra space for body
                extraLine.append(TextDisplayStackView.createAttributedChunk(baseHTML: text, fontSize: 14, submission: false, accentColor: ColorUtil.accentColorForSub(sub: submission.subreddit), fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil))
            }
        }
        return Title(mainTitle: finalTitle, infoLine: infoLine, extraLine: extraLine, color: colorF)
    }

    static func titleForMedia(submission: RSubmission) -> Title {

        let colorF = UIColor.white

        let attributedTitle = NSMutableAttributedString(string: submission.title.unescapeHTML, attributes: [NSAttributedString.Key.font: titleFontSmall, NSAttributedString.Key.foregroundColor: colorF])

        if submission.nsfw {
            let nsfw = NSMutableAttributedString.init(string: "\u{00A0}NSFW\u{00A0}", attributes: [NSAttributedString.Key.font: titleFontSmall, NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: GMColor.red500Color(), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white])

            attributedTitle.append(spacer)
            attributedTitle.append(nsfw)
        }

        if submission.oc {
            let oc = NSMutableAttributedString.init(string: "\u{00A0}OC\u{00A0}", attributes: [NSAttributedString.Key.font: titleFontSmall, NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: GMColor.blue50Color(), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.black])

            attributedTitle.append(spacer)
            attributedTitle.append(oc)
        }

        let endString = NSMutableAttributedString(string: "r/\(submission.subreddit)  •  \(DateFormatter().timeSince(from: submission.created, numericDates: true))\((submission.isEdited ? ("(edit \(DateFormatter().timeSince(from: submission.edited, numericDates: true)))") : ""))  •  ", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: colorF])

        let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: submission.author + (submission.cakeday ? " 🎂" : ""), small: false))\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: colorF])
        authorString.yy_setTextHighlight(NSRange(location: 0, length: authorString.length), color: nil, backgroundColor: nil, userInfo: ["url": URL(string: "/u/\(submission.author)")!, "profile": submission.author])

        let userColor = ColorUtil.getColorForUser(name: submission.author)
        if submission.distinguished == "admin" {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: UIColor.init(hexString: "#E57373"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if submission.distinguished == "special" {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: UIColor.init(hexString: "#F44336"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if submission.distinguished == "moderator" {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: UIColor.init(hexString: "#81C784"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if AccountController.currentName == submission.author {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: UIColor.init(hexString: "#FFB74D"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if userColor != ColorUtil.baseColor {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: userColor, cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        }

        endString.append(authorString)

        let tag = ColorUtil.getTagForUser(name: submission.author)
        if tag != nil {
            let tagString = NSMutableAttributedString.init(string: "\u{00A0}\(tag!)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName): YYTextBorder(fill: UIColor(rgb: 0x2196f3), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white])

            endString.append(spacer)
            endString.append(tagString)
        }
        
                
        let extraLine = NSMutableAttributedString()
                        
        return Title(mainTitle: attributedTitle, infoLine: endString, extraLine: extraLine, color: UIColor.white)
    }

    static func getImageSize(fontSize: CGFloat) -> CGRect {
        var rect = CGRect.zero
        rect.origin.x = 0.75
        if fontSize < 16 {
            rect.size.width = 1.25 * fontSize
            rect.size.height = 1.25 * fontSize
        } else if 16 <= fontSize && fontSize <= 24 {
            rect.size.width = 0.5 * fontSize + 12
            rect.size.height = 0.5 * fontSize + 12
        } else {
            rect.size.width = fontSize
            rect.size.height = fontSize
        }
        
        if fontSize < 16 {
            rect.origin.y = -0.2525 * fontSize
        } else if 16 <= fontSize && fontSize <= 24 {
            rect.origin.y = 0.1225 * fontSize - 6
        } else {
            rect.origin.y = -0.1275 * fontSize
        }
        return rect
    }

    static func getTitleAttributedString(_ link: RSubmission, force: Bool, gallery: Bool, full: Bool, white: Bool = false, loadImages: Bool = true) -> NSAttributedString {
        let titleStrings = CachedTitle.getTitle(submission: link, full: full, force, white, gallery: gallery)
        
        let attrs = [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: titleStrings.color] as [NSAttributedString.Key: Any]
        
        let color = ColorUtil.getColorForSub(sub: link.subreddit)

        var iconString = NSMutableAttributedString()
        if link.subreddit_icon != "" && SettingValues.subredditIcons && !full {
            if Subscriptions.icon(for: link.subreddit) == nil {
                Subscriptions.subIcons[link.subreddit.lowercased()] = link.subreddit_icon
            }
            if let urlAsURL = URL(string: link.subreddit_icon) {
                if loadImages {
                    let flairView = UIImageView(frame: CGRect(x: 0, y: 3, width: 20 + SettingValues.postFontOffset, height: 20 + SettingValues.postFontOffset))
                    flairView.layer.cornerRadius = CGFloat(20 + SettingValues.postFontOffset) / 2
                    flairView.layer.borderColor = color.cgColor
                    flairView.backgroundColor = color
                    flairView.layer.borderWidth = 0.5
                    flairView.clipsToBounds = true
                    flairView.sd_setImage(with: urlAsURL, placeholderImage: nil, context: [.imageThumbnailPixelSize: CGSize(width: flairView.frame.size.width * UIScreen.main.scale, height: flairView.frame.size.height * UIScreen.main.scale)])
                    let flairImage = NSMutableAttributedString.yy_attachmentString(withContent: flairView, contentMode: UIView.ContentMode.center, attachmentSize: CGSize(width: 20 + SettingValues.postFontOffset, height: 20 + SettingValues.postFontOffset), alignTo: CachedTitle.titleFont, alignment: YYTextVerticalAlignment.center)
                    iconString.append(flairImage)
                } else {
                    let flairView = UIView(frame: CGRect(x: 0, y: 3, width: 20 + SettingValues.postFontOffset, height: 20 + SettingValues.postFontOffset))
                    let flairImage = NSMutableAttributedString.yy_attachmentString(withContent: flairView, contentMode: UIView.ContentMode.center, attachmentSize: CGSize(width: 20 + SettingValues.postFontOffset, height: 20 + SettingValues.postFontOffset), alignTo: CachedTitle.titleFont, alignment: YYTextVerticalAlignment.center)
                    iconString.append(flairImage)
                }
            }
            let tapString = NSMutableAttributedString(string: "  r/\(link.subreddit)", attributes: attrs)
            tapString.yy_setTextHighlight(NSRange(location: 0, length: tapString.length), color: nil, backgroundColor: nil, userInfo: ["url": URL(string: "/r/\(link.subreddit)")!])
            iconString.append(tapString)
        } else {
            if color != ColorUtil.baseColor {
                let adjustedSize = 12 + CGFloat(SettingValues.postFontOffset)

                let preString = NSMutableAttributedString(string: "⬤  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: adjustedSize), NSAttributedString.Key.foregroundColor: color])
                iconString = preString
                let tapString = NSMutableAttributedString(string: "r/\(link.subreddit)", attributes: attrs)
                tapString.yy_setTextHighlight(NSRange(location: 0, length: tapString.length), color: nil, backgroundColor: nil, userInfo: ["url": URL(string: "/r/\(link.subreddit)")!])
                iconString.append(tapString)
            } else {
                let tapString = NSMutableAttributedString(string: "r/\(link.subreddit)", attributes: attrs)
                tapString.yy_setTextHighlight(NSRange(location: 0, length: tapString.length), color: nil, backgroundColor: nil, userInfo: ["url": URL(string: "/r/\(link.subreddit)")!])
                iconString = tapString
            }
        }

        let awardString = NSMutableAttributedString()
        let awardPStyle = NSMutableParagraphStyle()
        awardPStyle.minimumLineHeight = 20
        if link.gilded {
            let boldFont = FontGenerator.boldFontOfSize(size: 12, submission: true)
            if SettingValues.hideAwards {
                var awardCount = link.platinum + link.silver + link.gold
                for award in link.awards {
                    awardCount += Int(award.split(":")[1]) ?? 0
                }
                let gild = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: "gold")!, fontSize: CachedTitle.titleFont.pointSize * 0.75)!
                awardString.append(gild)
                if awardCount > 1 {
                    let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(awardCount) ", attributes: [NSAttributedString.Key.paragraphStyle: awardPStyle, NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: titleStrings.color])
                    awardString.append(gilded)
                }
            } else {
                for award in link.awards {
                    let url = award.split("*")[0]
                    let count = Int(award.split(":")[1]) ?? 0
                    if let urlAsURL = URL(string: url) {
                        if loadImages {
                            let flairView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                            flairView.sd_setImage(with: urlAsURL, placeholderImage: nil, context: [.imageThumbnailPixelSize: CGSize(width: flairView.frame.size.width * UIScreen.main.scale, height: flairView.frame.size.height * UIScreen.main.scale)])
                            let flairImage = NSMutableAttributedString.yy_attachmentString(withContent: flairView, contentMode: UIView.ContentMode.center, attachmentSize: CachedTitle.getImageSize(fontSize: CachedTitle.titleFont.pointSize * 0.75).size, alignTo: CachedTitle.titleFont, alignment: YYTextVerticalAlignment.center)

                            awardString.append(flairImage)
                        } else {
                            let flairView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                            let flairImage = NSMutableAttributedString.yy_attachmentString(withContent: flairView, contentMode: UIView.ContentMode.center, attachmentSize: CachedTitle.getImageSize(fontSize: CachedTitle.titleFont.pointSize * 0.75).size, alignTo: CachedTitle.titleFont, alignment: YYTextVerticalAlignment.center)

                            awardString.append(flairImage)
                        }
                    }
                    if count > 1 {
                        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(link.gold) ", attributes: [NSAttributedString.Key.paragraphStyle: awardPStyle, NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: titleStrings.color])
                        awardString.append(gilded)
                    }
                    awardString.append(CachedTitle.spacer)
                }
                if link.platinum > 0 {
                    let gild = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: "platinum")!, fontSize: CachedTitle.titleFont.pointSize * 0.75)!
                    awardString.append(gild)
                    if link.platinum > 1 {
                        let platinumed = NSMutableAttributedString.init(string: "\u{00A0}x\(link.platinum) ", attributes: [NSAttributedString.Key.paragraphStyle: awardPStyle, NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: titleStrings.color])
                        awardString.append(platinumed)
                    }
                    awardString.append(CachedTitle.spacer)
                }
                
                if link.gold > 0 {
                    let gild = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: "gold")!, fontSize: CachedTitle.titleFont.pointSize * 0.75)!
                    awardString.append(gild)
                    if link.gold > 1 {
                        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(link.gold) ", attributes: [NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: titleStrings.color])
                        awardString.append(gilded)
                    }
                    awardString.append(CachedTitle.spacer)
                }
                if link.silver > 0 {
                    let gild = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: "silver")!, fontSize: CachedTitle.titleFont.pointSize * 0.75)!
                    awardString.append(gild)
                    if link.silver > 1 {
                        let silvered = NSMutableAttributedString.init(string: "\u{00A0}x\(link.silver) ", attributes: [NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: titleStrings.color])
                        awardString.append(silvered)
                    }
                    awardString.append(CachedTitle.spacer)
                }
            }
        }

        let finalTitle = NSMutableAttributedString()
        if SettingValues.infoBelowTitle {
            if let mainTitle = titleStrings.mainTitle {
                finalTitle.append(mainTitle)
            }
            finalTitle.append(NSAttributedString.init(string: "\n"))
            finalTitle.append(iconString)
            if let infoLine = titleStrings.infoLine {
                finalTitle.append(infoLine)
            }
            if awardString.length > 0 {
                finalTitle.append(NSAttributedString.init(string: "\n"))
                finalTitle.append(awardString)
            }
            if let extraLine = titleStrings.extraLine, extraLine.length > 0 {
                finalTitle.append(NSAttributedString.init(string: "\n"))
                finalTitle.append(extraLine)
            }
        } else {
            finalTitle.append(iconString)
            if let infoLine = titleStrings.infoLine {
                finalTitle.append(infoLine)
            }
            finalTitle.append(NSAttributedString.init(string: "\n"))
            if let mainTitle = titleStrings.mainTitle {
                finalTitle.append(mainTitle)
            }
            if awardString.length > 0 {
                finalTitle.append(NSAttributedString.init(string: "\n"))
                finalTitle.append(awardString)
            }
            if let extraLine = titleStrings.extraLine, extraLine.length > 0 {
                finalTitle.append(NSAttributedString.init(string: "\n"))
                finalTitle.append(extraLine)
            }
        }
        return finalTitle
    }

}
