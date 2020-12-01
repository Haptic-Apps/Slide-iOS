//
//  CachedTitle.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/21/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import SDWebImage
import Proton
import YYText

struct Title {
    var mainTitle: NSAttributedString?
    var infoLine: NSAttributedString?
    var extraLine: NSAttributedString?
    var color: UIColor
}

class CachedTitle {
    static var AWARD_KEY = "https://ccrama.me/awards"
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

        var newlineDone = false
        if SettingValues.showFlairs {
            let flairsDict = submission.flairJSON.dictionaryValue()
            let flairTitle = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: brightF])
            if !flairsDict.keys.isEmpty {
                for key in flairsDict.keys {
                    let flair = flairsDict[key] as? NSDictionary
                    if let url = flair?["url"] as? String, SettingValues.imageFlairs {
                        if let urlAsURL = URL(string: url) {
                            let attachment = AsyncTextAttachment(imageURL: urlAsURL, delegate: nil, rounded: false, backgroundColor: ColorUtil.theme.foregroundColor)
                            attachment.bounds = CGRect(x: 0, y: -2 + (15 * -0.5) / 2, width: 15, height: 15)
                            flairTitle.append(NSAttributedString(attachment: attachment))
                        }
                    } else {
                        let flair = flairsDict[key] as? NSDictionary
                        if let color = flair?["color"] as? String, SettingValues.coloredFlairs {
                            let singleFlair = NSMutableAttributedString(string: "\u{00A0}\(key)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: UIColor(hexString: color), NSAttributedString.Key.foregroundColor: UIColor.white])
                            flairTitle.append(singleFlair)
                        } else {
                            let singleFlair = NSMutableAttributedString(string: "\u{00A0}\(key)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: ColorUtil.theme.backgroundColor, NSAttributedString.Key.foregroundColor: brightF])
                            flairTitle.append(singleFlair)
                        }
                    }
                }
                if !newlineDone {
                    newlineDone = true
                    attributedTitle.append(NSAttributedString(string: "\n"))
                }
                attributedTitle.append(flairTitle)
            }
        }
        
        if submission.nsfw {
            let nsfw = NSMutableAttributedString.init(string: "\u{00A0}NSFW\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: GMColor.red500Color(), NSAttributedString.Key.foregroundColor: UIColor.white])

            if !newlineDone {
                newlineDone = true
                attributedTitle.append(NSAttributedString(string: "\n"))
            } else {
                attributedTitle.append(spacer)
            }
            attributedTitle.append(nsfw)
        }

        if submission.spoiler {
            let spoiler = NSMutableAttributedString.init(string: "\u{00A0}SPOILER\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: GMColor.grey50Color(), NSAttributedString.Key.foregroundColor: UIColor.black])

            if !newlineDone {
                newlineDone = true
                attributedTitle.append(NSAttributedString(string: "\n"))
            } else {
                attributedTitle.append(spacer)
            }
            attributedTitle.append(spoiler)
        }

        if submission.oc {
            let oc = NSMutableAttributedString.init(string: "\u{00A0}OC\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: GMColor.blue50Color(), NSAttributedString.Key.foregroundColor: UIColor.black])

            if !newlineDone {
                newlineDone = true
                attributedTitle.append(NSAttributedString(string: "\n"))
            } else {
                attributedTitle.append(spacer)
            }
            attributedTitle.append(oc)
        }

        if submission.stickied {
            let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: GMColor.green500Color(), NSAttributedString.Key.foregroundColor: UIColor.white])

            if !newlineDone {
                newlineDone = true
                attributedTitle.append(NSAttributedString(string: "\n"))
            } else {
                attributedTitle.append(spacer)
            }
            attributedTitle.append(pinned)
        }

        if submission.locked {
            let locked = NSMutableAttributedString.init(string: "\u{00A0}LOCKED\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: GMColor.green500Color(), NSAttributedString.Key.foregroundColor: UIColor.white])

            if !newlineDone {
                newlineDone = true
                attributedTitle.append(NSAttributedString(string: "\n"))
            } else {
                attributedTitle.append(spacer)
            }
            attributedTitle.append(locked)
        }
        if submission.archived {
            let archived = NSMutableAttributedString.init(string: "\u{00A0}ARCHIVED\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: ColorUtil.theme.backgroundColor, NSAttributedString.Key.foregroundColor: brightF])
            if !newlineDone {
                newlineDone = true
                attributedTitle.append(NSAttributedString(string: "\n"))
            } else {
                attributedTitle.append(spacer)
            }

            attributedTitle.append(archived)
        }
        
        if SettingValues.typeInTitle {
            let info = NSMutableAttributedString.init(string: "\u{00A0}\(submission.type.rawValue)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: ColorUtil.theme.fontColor, NSAttributedString.Key.foregroundColor: ColorUtil.theme.foregroundColor])
            if !newlineDone {
                newlineDone = true
                attributedTitle.append(NSAttributedString(string: "\n"))
            } else {
                attributedTitle.append(spacer)
            }
            attributedTitle.append(info)
        }

        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: submission.created, numericDates: true))\((submission.isEdited ? ("(edit \(DateFormatter().timeSince(from: submission.edited, numericDates: true)))") : ""))  •  ", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: colorF])

        var authorAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: colorF]
        let userColor = ColorUtil.getColorForUser(name: submission.author)
        if submission.distinguished == "admin" {
            authorAttributes[.badgeColor] = UIColor.init(hexString: "#E57373")
            authorAttributes[.foregroundColor] = UIColor.white
        } else if submission.distinguished == "special" {
            authorAttributes[.badgeColor] = UIColor.init(hexString: "#F44336")
            authorAttributes[.foregroundColor] = UIColor.white
        } else if submission.distinguished == "moderator" {
            authorAttributes[.badgeColor] = UIColor.init(hexString: "#81C784")
            authorAttributes[.foregroundColor] = UIColor.white
        } else if AccountController.currentName == submission.author {
            authorAttributes[.badgeColor] = UIColor.init(hexString: "#FFB74D")
            authorAttributes[.foregroundColor] = UIColor.white
        } else if userColor != ColorUtil.baseColor {
            authorAttributes[.badgeColor] = userColor
            authorAttributes[.foregroundColor] = UIColor.white
        }
        
        if full {
            authorAttributes[.urlAction] = URL(string: "https://www.reddit.com/u/\(submission.author)")!
        }
        let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: submission.author, small: false) + (submission.cakeday ? " 🎂" : ""))\u{00A0}", attributes: authorAttributes)

        endString.append(authorString)
        
        if SettingValues.domainInInfo && !full {
            endString.append(NSAttributedString.init(string: "  •  \(submission.domain)", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: colorF]))
        }

        let tag = ColorUtil.getTagForUser(name: submission.author)
        if tag != nil {
            let tagString = NSMutableAttributedString.init(string: "\u{00A0}\(tag!)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: UIColor(rgb: 0x2196f3), NSAttributedString.Key.foregroundColor: UIColor.white])

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
        let fontSize = 12 + CGFloat(SettingValues.postFontOffset)

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
                
                let subScore = NSMutableAttributedString(string: (scoreInt >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(scoreInt) / Double(1000))) : "\(scoreInt)", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: sColor])
                let size = subScore.boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity), options: [], context: nil)

                let image = UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")!.getCopy(withSize: CGSize.square(size: size.height * 0.65), withColor: ColorUtil.theme.fontColor)
                let upvoteImage = NSTextAttachment()
                upvoteImage.image = image
                upvoteImage.bounds = CGRect(x: 0, y: (image.size.height * -0.35) / 2, width: image.size.width, height: image.size.height)
                
                extraLine.append(NSAttributedString(attachment: upvoteImage))
                extraLine.append(subScore)
            }
            
            if SettingValues.commentsInTitle {
                if SettingValues.scoreInTitle {
                    extraLine.append(spacer)
                }
                
                let commentString = NSMutableAttributedString(string: " \(submission.commentCount)", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: colorF])

                let size = commentString.boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity), options: [], context: nil)
                let commentImage = NSTextAttachment()
                let image = UIImage(sfString: SFSymbol.bubbleRightFill, overrideString: "comments")!.getCopy(withSize: CGSize.square(size: size.height * 0.75), withColor: ColorUtil.theme.fontColor)
                commentImage.image = image
                commentImage.bounds = CGRect(x: 0, y: (image.size.height * -0.25) / 2, width: image.size.width, height: image.size.height)

                extraLine.append(NSAttributedString(attachment: commentImage))
                extraLine.append(commentString)
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
        
        if submission.isCrosspost && !full {
            if extraLine.string.length > 0 {
                extraLine.append(NSAttributedString.init(string: "\n"))
            }
            
            let crosspost = NSMutableAttributedString()
            
            let finalText = NSMutableAttributedString.init(string: " Crossposted from ", attributes: [NSAttributedString.Key.foregroundColor: colorF, NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true)])
            let size = finalText.boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity), options: [], context: nil)
            
            let image = UIImage(named: "crosspost")!.getCopy(withColor: ColorUtil.theme.fontColor).getCopy(withSize: CGSize.square(size: size.height * 0.75), withColor: ColorUtil.theme.fontColor)

            let crosspostImage = NSTextAttachment()
            crosspostImage.image = image
            crosspostImage.bounds = CGRect(x: 0, y: (image.size.height * -0.25) / 2, width: image.size.width, height: image.size.height)

            crosspost.append(NSAttributedString(attachment: crosspostImage))

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

        if submission.pollOptions.count > 0 {
            if extraLine.string.length > 0 {
                extraLine.append(NSAttributedString.init(string: "\n"))
            }
            
            let poll = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: "poll")!.getCopy(withColor: ColorUtil.theme.fontColor), fontSize: titleFont.pointSize * 0.75)!

            let finalText = NSMutableAttributedString.init(string: " Poll", attributes: [NSAttributedString.Key.foregroundColor: colorF, NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true)])
                        
            poll.append(finalText)

            for option in submission.pollOptions {
                let split = option.split(";")
                poll.append(NSAttributedString.init(string: "\n"))
                let option = split[0]
                let count = Int(split[1]) ?? -1
                                
                if count != -1 {
                    poll.append(NSAttributedString(string: "\(count)", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.accentColorForSub(sub: submission.subreddit), NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true)]))
                    let value = (100.0 * CGFloat(count) / CGFloat(submission.pollTotal))
                    let percent = String(format: " (%.1f%%)", value)
                    poll.append(NSAttributedString(string: percent, attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.accentColorForSub(sub: submission.subreddit), NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 10, submission: true)]))
                }
                
                poll.append(NSAttributedString(string: "  \(option) ", attributes: [NSAttributedString.Key.foregroundColor: colorF, NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true)]))

            }
            
            poll.append(NSAttributedString.init(string: "\n"))
            poll.append(NSAttributedString(string: "\(submission.pollTotal) total votes", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.accentColorForSub(sub: submission.subreddit), NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true)]))

            poll.append(NSAttributedString.init(string: "\n"))
            extraLine.append(poll)
        }
        
        if SettingValues.showFirstParagraph && submission.isSelf && !submission.spoiler && !submission.nsfw && !full && !submission.body.trimmed().isEmpty {
            let length = submission.htmlBody.indexOf("\n") ?? submission.htmlBody.length
            let text = submission.htmlBody.substring(0, length: length).trimmed()

            if !text.isEmpty() {
                extraLine.append(NSAttributedString.init(string: "\n")) //Extra space for body
                extraLine.append(TextDisplayStackView.createAttributedChunk(baseHTML: text.replacingOccurrences(of: "<!-- SC_OFF -->", with: "").replacingOccurrences(of: "<p>", with: "").replacingOccurrences(of: "</p>", with: ""), fontSize: 14, submission: false, accentColor: ColorUtil.accentColorForSub(sub: submission.subreddit), fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil).trimWhiteSpace())
            }
        }
        
        return Title(mainTitle: finalTitle, infoLine: infoLine, extraLine: extraLine, color: colorF)
    }

    static func titleForMedia(submission: RSubmission) -> Title {

        let colorF = UIColor.white

        let attributedTitle = NSMutableAttributedString(string: submission.title.unescapeHTML, attributes: [NSAttributedString.Key.font: titleFontSmall, NSAttributedString.Key.foregroundColor: colorF])

        if submission.nsfw {
            let nsfw = NSMutableAttributedString.init(string: "\u{00A0}NSFW\u{00A0}", attributes: [NSAttributedString.Key.font: titleFontSmall, NSAttributedString.Key.badgeColor: GMColor.red500Color(), NSAttributedString.Key.foregroundColor: UIColor.white])

            attributedTitle.append(spacer)
            attributedTitle.append(nsfw)
        }

        if submission.oc {
            let oc = NSMutableAttributedString.init(string: "\u{00A0}OC\u{00A0}", attributes: [NSAttributedString.Key.font: titleFontSmall, NSAttributedString.Key.badgeColor: GMColor.blue50Color(), NSAttributedString.Key.foregroundColor: UIColor.black])

            attributedTitle.append(spacer)
            attributedTitle.append(oc)
        }

        let endString = NSMutableAttributedString(string: "r/\(submission.subreddit)  •  \(DateFormatter().timeSince(from: submission.created, numericDates: true))\((submission.isEdited ? ("(edit \(DateFormatter().timeSince(from: submission.edited, numericDates: true)))") : ""))  •  ", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: colorF])

        var authorAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: colorF]
        let userColor = ColorUtil.getColorForUser(name: submission.author)
        if submission.distinguished == "admin" {
            authorAttributes[.badgeColor] = UIColor.init(hexString: "#E57373")
            authorAttributes[.foregroundColor] = UIColor.white
        } else if submission.distinguished == "special" {
            authorAttributes[.badgeColor] = UIColor.init(hexString: "#F44336")
            authorAttributes[.foregroundColor] = UIColor.white
        } else if submission.distinguished == "moderator" {
            authorAttributes[.badgeColor] = UIColor.init(hexString: "#81C784")
            authorAttributes[.foregroundColor] = UIColor.white
        } else if AccountController.currentName == submission.author {
            authorAttributes[.badgeColor] = UIColor.init(hexString: "#FFB74D")
            authorAttributes[.foregroundColor] = UIColor.white
        } else if userColor != ColorUtil.baseColor {
            authorAttributes[.badgeColor] = userColor
            authorAttributes[.foregroundColor] = UIColor.white
        }

        let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: submission.author, small: false) + (submission.cakeday ? " 🎂" : ""))\u{00A0}", attributes: authorAttributes)

        endString.append(authorString)

        let tag = ColorUtil.getTagForUser(name: submission.author)
        if tag != nil {
            let tagString = NSMutableAttributedString.init(string: "\u{00A0}\(tag!)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: UIColor(rgb: 0x2196f3), NSAttributedString.Key.foregroundColor: UIColor.white])

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
        let fontSize = 12 + CGFloat(SettingValues.postFontOffset)
        let titleFont = FontGenerator.boldFontOfSize(size: 12, submission: true)
        var attrs = [NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: titleStrings.color] as [NSAttributedString.Key: Any]
        
        let color = ColorUtil.getColorForSub(sub: link.subreddit)

        var iconString = NSMutableAttributedString()
        if (link.subreddit_icon != "" || Subscriptions.icon(for: link.subreddit) != nil) && SettingValues.subredditIcons && !full {
            if Subscriptions.icon(for: link.subreddit) == nil {
                Subscriptions.subIcons[link.subreddit.lowercased()] = link.subreddit_icon.unescapeHTML
            }
            if let urlAsURL = URL(string: Subscriptions.icon(for: link.subreddit.lowercased())!.unescapeHTML) {
                if loadImages {
                    let attachment = AsyncTextAttachment(imageURL: urlAsURL, delegate: nil, rounded: true, backgroundColor: color)
                    attachment.bounds = CGRect(x: 0, y: 0, width: 24, height: 24)
                    iconString.append(NSAttributedString(attachment: attachment))
                    attrs[.baselineOffset] = (((24 - fontSize) / 2) - (titleFont.descender / 2))
                } else {
                    let attachment = NSTextAttachment()
                    attachment.bounds = CGRect(x: 0, y: 0, width: 24, height: 24)
                    iconString.append(NSAttributedString(attachment: attachment))
                    attrs[.baselineOffset] = (((24 - fontSize) / 2) - (titleFont.descender / 2))
                }
            }
            let tapString = NSMutableAttributedString(string: "  r/\(link.subreddit)", attributes: attrs)
            tapString.addAttributes([.urlAction: URL(string: "https://www.reddit.com/r/\(link.subreddit)")!], range: NSRange(location: 0, length: tapString.length))

            iconString.append(tapString)
        } else {
            if color != ColorUtil.baseColor {
                let preString = NSMutableAttributedString(string: "⬤  ", attributes: [NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: color])
                iconString = preString
                let tapString = NSMutableAttributedString(string: "r/\(link.subreddit)", attributes: attrs)
                tapString.addAttributes([.urlAction: URL(string: "https://www.reddit.com/r/\(link.subreddit)")!], range: NSRange(location: 0, length: tapString.length))
                iconString.append(tapString)
            } else {
                let tapString = NSMutableAttributedString(string: "r/\(link.subreddit)", attributes: attrs)
                tapString.addAttributes([.urlAction: URL(string: "https://www.reddit.com/r/\(link.subreddit)")!], range: NSRange(location: 0, length: tapString.length))
                iconString = tapString
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
                if let baseline = attrs[.baselineOffset] {
                    let mutableLine = NSMutableAttributedString(attributedString: infoLine)
                    mutableLine.addAttributes([.baselineOffset: baseline], range: NSRange(location: 0, length: infoLine.length))
                    finalTitle.append(mutableLine)
                } else {
                    finalTitle.append(infoLine)
                }
            }
            if let extraLine = titleStrings.extraLine, extraLine.length > 0 {
                finalTitle.append(NSAttributedString.init(string: "\n"))
                finalTitle.append(extraLine)
            }
        } else {
            finalTitle.append(iconString)
            if let infoLine = titleStrings.infoLine {
                if let baseline = attrs[.baselineOffset] {
                    let mutableLine = NSMutableAttributedString(attributedString: infoLine)
                    mutableLine.addAttributes([.baselineOffset: baseline], range: NSRange(location: 0, length: infoLine.length))
                    finalTitle.append(mutableLine)
                } else {
                    finalTitle.append(infoLine)
                }
            }
            finalTitle.append(NSAttributedString.init(string: "\n"))
            if let mainTitle = titleStrings.mainTitle {
                finalTitle.append(mainTitle)
            }
            if let extraLine = titleStrings.extraLine, extraLine.length > 0 {
                finalTitle.append(NSAttributedString.init(string: "\n"))
                finalTitle.append(extraLine)
            }
        }
        if !SettingValues.hideAwards {
            let to = 3
            if link.gilded {
                var awardCount = 0
                let awardDict = link.awardsJSON.dictionaryValue()

                let values = awardDict.values
                let sortedValues = values.sorted { (a, b) -> Bool in
                    let amountA = Int((a as? [String])?[4] ?? "0") ?? 0
                    let amountB = Int((b as? [String])?[4] ?? "0") ?? 0

                    return amountA > amountB
                }
                for raw in sortedValues {
                    if let award = raw as? [String] {
                        awardCount += Int(award[2]) ?? 0
                    }
                }
                
                var totalAwards = 0
                var attachments = [NSTextAttachment]()
                
                for raw in sortedValues {
                    if let award = raw as? [String] {
                        if totalAwards == to {
                            break
                        }
                        
                        totalAwards += 1

                        let url = award[1]
                        let testString = NSMutableAttributedString(string: "test", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
                        if let urlAsURL = URL(string: url) {
                            if loadImages {
                                let size = testString.boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity), options: [], context: nil)

                                let attachment = AsyncTextAttachment(imageURL: urlAsURL, delegate: nil, rounded: false, backgroundColor: ColorUtil.theme.foregroundColor)
                                attachment.bounds = CGRect(x: 0, y: -2 + (15 * -0.5) / 2, width: 15, height: 15)
                                attachments.append(attachment)
                            } else {
                                let attachment = NSTextAttachment()
                                attachment.bounds = CGRect(x: 0, y: -2 + (15 * -0.5) / 2, width: 15, height: 15)
                                attachments.append(attachment)
                            }
                        }
                    }
                }
                
                let awardLine = NSMutableAttributedString(string: "\n", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: ColorUtil.theme.foregroundColor])

                for award in attachments {
                    awardLine.append(NSAttributedString(attachment: award))
                    awardLine.appendString(" ")
                }
                
                if totalAwards == to {
                    awardLine.append(NSMutableAttributedString(string: "\(awardCount) Awards", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor, .baselineOffset: -2]))
                }
                
                awardLine.addAttributes([.urlAction: URL(string: CachedTitle.AWARD_KEY)!], range: NSRange(location: 2, length: awardLine.length - 2)) //We will catch this URL later on, start it after the newline

                finalTitle.append(awardLine)
                finalTitle.append(NSAttributedString(string: "\u{00A0}")) //Stop tap from going to the end of the view width
            }
        }
        return finalTitle
    }
}

extension NSAttributedString {

    /** Will Trim space and new line from start and end of the text */
    public func trimWhiteSpace() -> NSAttributedString {
        let invertedSet = CharacterSet.whitespacesAndNewlines.inverted
        let startRange = string.utf16.description.rangeOfCharacter(from: invertedSet)
        let endRange = string.utf16.description.rangeOfCharacter(from: invertedSet, options: .backwards)
        guard let startLocation = startRange?.upperBound, let endLocation = endRange?.lowerBound else {
            return NSAttributedString(string: string)
        }

        let location = string.utf16.distance(from: string.startIndex, to: startLocation) - 1
        let length = string.utf16.distance(from: startLocation, to: endLocation) + 2
        let range = NSRange(location: location, length: length)
        return attributedSubstring(from: range)
    }
}

extension UIImage {
    func centerImage(with finalSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(finalSize, false, self.scale)
        let _ = UIGraphicsGetCurrentContext()
        
        let selfSize = self.size
        let left = (finalSize.width - selfSize.width) / 2
        let top = (finalSize.height - selfSize.height) / 2
        
        let origin = CGPoint(x: left, y: top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }
}
