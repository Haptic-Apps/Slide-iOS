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
        titles[s.getId()] = titleForSubmission(submission: s, full: false, white: false)
    }

    static var titleFont = FontGenerator.fontOfSize(size: 18, submission: true)

    static func getTitle(submission: RSubmission, full: Bool, _ refresh: Bool, _ white: Bool = false) -> NSAttributedString {
        let title = titles[submission.getId()]
        if title == nil || refresh || full || white {
            if white {
                return titleForSubmission(submission: submission, full: full, white: white)
            }
            if !full {
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

        var colorF = ColorUtil.navIconColor
        if white {
            colorF = .white
        }
        
        var color2 = ColorUtil.fontColor
        if white {
            color2 = .white
        }

        let attributedTitle = NSMutableAttributedString(string: submission.title, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): titleFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): color2]))

        let spacer = NSMutableAttributedString.init(string: "  ")
        if !submission.flair.isEmpty {
            let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(submission.flair)\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]))

            attributedTitle.append(spacer)
            attributedTitle.append(flairTitle)
        }
        
        if submission.nsfw {
            let nsfw = NSMutableAttributedString.init(string: "\u{00A0}NSFW\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: GMColor.red500Color(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]))

            attributedTitle.append(spacer)
            attributedTitle.append(nsfw)
        }

        if submission.spoiler {
            let spoiler = NSMutableAttributedString.init(string: "\u{00A0}SPOILER\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: GMColor.grey50Color(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]))

            attributedTitle.append(spacer)
            attributedTitle.append(spoiler)
        }

        if submission.oc {
            let oc = NSMutableAttributedString.init(string: "\u{00A0}OC\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: GMColor.blue50Color(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]))
            attributedTitle.append(spacer)
            attributedTitle.append(oc)
        }

        if submission.gilded {
            attributedTitle.append(spacer)
            if submission.platinum > 0 {
                attributedTitle.append(spacer)
                let gild = NSMutableAttributedString.init(string: "P", attributes: convertToOptionalNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: GMColor.lightBlue500Color(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]))
                attributedTitle.append(gild)
                if submission.platinum > 1 {
                    let platinumed = NSMutableAttributedString.init(string: "\u{00A0}x\(submission.platinum) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))
                    attributedTitle.append(platinumed)
                }
            }
            if submission.gold > 0 {
                attributedTitle.append(spacer)
                let gild = NSMutableAttributedString.init(string: "G", attributes: convertToOptionalNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: GMColor.amber500Color(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]))
                attributedTitle.append(gild)
                if submission.gold > 1 {
                    let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(submission.gold) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))
                    attributedTitle.append(gilded)
                }
            }
            if submission.silver > 0 {
                attributedTitle.append(spacer)
                let gild = NSMutableAttributedString.init(string: "S", attributes: convertToOptionalNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: GMColor.grey500Color(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]))
                attributedTitle.append(gild)
                if submission.silver > 1 {
                    let silvered = NSMutableAttributedString.init(string: "\u{00A0}x\(submission.silver) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))
                    attributedTitle.append(silvered)
                }
            }
        }

        if submission.stickied {
            let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]))

            attributedTitle.append(spacer)
            attributedTitle.append(pinned)
        }

        if submission.locked {
            let locked = NSMutableAttributedString.init(string: "\u{00A0}LOCKED\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]))

            attributedTitle.append(spacer)
            attributedTitle.append(locked)
        }
        if submission.archived {
            let archived = NSMutableAttributedString.init(string: "\u{00A0}ARCHIVED\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]))

            attributedTitle.append(archived)
        }

        let attrs = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF] as [String: Any]

        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: submission.created, numericDates: true))\((submission.isEdited ? ("(edit \(DateFormatter().timeSince(from: submission.edited, numericDates: true)))") : ""))  •  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))

        let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: submission.author, small: false))\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))

        let userColor = ColorUtil.getColorForUser(name: submission.author)
        if submission.distinguished == "admin" {
            authorString.addAttributes(convertToNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#E57373"), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]), range: NSRange.init(location: 0, length: authorString.length))
        } else if submission.distinguished == "special" {
            authorString.addAttributes(convertToNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#F44336"), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]), range: NSRange.init(location: 0, length: authorString.length))
        } else if submission.distinguished == "moderator" {
            authorString.addAttributes(convertToNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#81C784"), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]), range: NSRange.init(location: 0, length: authorString.length))
        } else if AccountController.currentName == submission.author {
            authorString.addAttributes(convertToNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]), range: NSRange.init(location: 0, length: authorString.length))
        } else if userColor != ColorUtil.baseColor {
            authorString.addAttributes(convertToNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: userColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]), range: NSRange.init(location: 0, length: authorString.length))
        }

        endString.append(authorString)
        if SettingValues.domainInInfo && !full {
            endString.append(NSAttributedString.init(string: "  •  \(submission.domain)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF])))
        }

        let tag = ColorUtil.getTagForUser(name: submission.author)
        if !tag.isEmpty {
            let tagString = NSMutableAttributedString(string: "\u{00A0}\(tag)\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))
            tagString.addAttributes(convertToNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: UIColor(rgb: 0x2196f3), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]), range: NSRange.init(location: 0, length: tagString.length))
            endString.append(spacer)
            endString.append(tagString)
        }
        
        var boldString: NSMutableAttributedString
        let color = ColorUtil.getColorForSub(sub: submission.subreddit)
        var readString: NSAttributedString
        
        if SettingValues.newIndicator && !History.getSeen(s: submission) {
            readString = NSAttributedString(string: "•  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.accentColorForSub(sub: submission.subreddit)]))
        } else {
            readString = NSAttributedString()
        }
        
        if color != ColorUtil.baseColor {
            let preString = NSMutableAttributedString(string: "⬤  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): color]))
            boldString = preString
            boldString.append(NSMutableAttributedString(string: "r/\(submission.subreddit)", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs)))
        } else {
            boldString = NSMutableAttributedString(string: "r/\(submission.subreddit)", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs))
        }

        let infoString = NSMutableAttributedString()
        if SettingValues.infoBelowTitle {
            infoString.append(readString)
            infoString.append(attributedTitle)
            infoString.append(NSAttributedString.init(string: "\n\n"))
            infoString.append(boldString)
            infoString.append(endString)
        } else {
            infoString.append(readString)
            infoString.append(boldString)
            infoString.append(endString)
            infoString.append(NSAttributedString.init(string: "\n"))
            infoString.append(attributedTitle)
        }
        
        if !full {
            if SettingValues.scoreInTitle || SettingValues.commentsInTitle {
                infoString.append(NSAttributedString.init(string: "\n"))
            }
            if SettingValues.scoreInTitle {
                var sColor = colorF
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

                let subScore = NSMutableAttributedString(string: (scoreInt >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk points", (Double(scoreInt) / Double(1000))) : " \(scoreInt) points", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): sColor]))
                
                infoString.append(subScore)
            }
            
            if SettingValues.commentsInTitle {
                if SettingValues.scoreInTitle {
                    infoString.append(spacer)
                }
                let scoreString = NSMutableAttributedString(string: "\(submission.commentCount) comments", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))
                infoString.append(scoreString)
            }
        }
        
        if removed.contains(submission.id) || (!submission.removedBy.isEmpty() && !approved.contains(submission.id)) {
            let attrs = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): GMColor.red500Color()] as [String: Any]
            infoString.append(spacer)
            if submission.removedBy == "true" {
                infoString.append(NSMutableAttributedString.init(string: "Removed by Reddit\(!submission.removalReason.isEmpty() ? ":\(submission.removalReason)" : "")", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs)))
            } else {
                infoString.append(NSMutableAttributedString.init(string: "Removed\(!submission.removedBy.isEmpty() ? "by \(submission.removedBy)" : "")\(!submission.removalReason.isEmpty() ? " for \(submission.removalReason)" : "")\(!submission.removalNote.isEmpty() ? " \(submission.removalNote)" : "")", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs)))
            }
        } else if approved.contains(submission.id) || (!submission.approvedBy.isEmpty() && !removed.contains(submission.id)) {
            let attrs = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): GMColor.green500Color()] as [String: Any]
            infoString.append(spacer)
            infoString.append(NSMutableAttributedString.init(string: "Approved\(!submission.approvedBy.isEmpty() ? " by \(submission.approvedBy)":"")", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs)))
        }

        if submission.isCrosspost && !full {
            infoString.append(NSAttributedString.init(string: "\n\n"))

            let endString = NSMutableAttributedString(string: "Crossposted from ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))
            let by = NSMutableAttributedString(string: " by ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))

            let boldString = NSMutableAttributedString(string: "r/\(submission.crosspostSubreddit)", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs))

            let color = ColorUtil.getColorForSub(sub: submission.crosspostSubreddit)
            if color != ColorUtil.baseColor {
                boldString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange.init(location: 0, length: boldString.length))
            }

            endString.append(boldString)

            let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: submission.author, small: false))\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: true), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))

            let userColor = ColorUtil.getColorForUser(name: submission.crosspostAuthor)
            if AccountController.currentName == submission.author {
                authorString.addAttributes(convertToNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]), range: NSRange.init(location: 0, length: authorString.length))
            } else if userColor != ColorUtil.baseColor {
                authorString.addAttributes(convertToNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: userColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]), range: NSRange.init(location: 0, length: authorString.length))
            }

            endString.append(by)
            endString.append(authorString)
            let tag = ColorUtil.getTagForUser(name: submission.author)
            if !tag.isEmpty {
                let tagString = NSMutableAttributedString(string: "\u{00A0}\(tag)\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))
                tagString.addAttributes(convertToNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: UIColor(rgb: 0x2196f3), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]), range: NSRange.init(location: 0, length: tagString.length))
                endString.append(spacer)
                endString.append(tagString)
            }
            infoString.append(endString)
        }

        if SettingValues.showFirstParagraph && submission.isSelf && !submission.spoiler && !submission.nsfw && !full && !submission.body.trimmed().isEmpty {
            let length = submission.htmlBody.indexOf("\n") ?? submission.htmlBody.length
            var text = submission.htmlBody.substring(0, length: length).trimmed()

            text = text.replacingOccurrences(of: "<p>", with: "").replacingOccurrences(of: "</p>", with: "").trimmed()
            let attr = TextDisplayStackView.createAttributedChunk(baseHTML: text, fontSize: 14, submission: false, accentColor: ColorUtil.accentColorForSub(sub: submission.subreddit))
            if !text.isEmpty() {
                infoString.append(NSAttributedString.init(string: "\n\n"))
                infoString.append(attr)
            }
        }
        return infoString
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
