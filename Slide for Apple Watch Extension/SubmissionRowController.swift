//
//  SubmissionRowController.swift
//  Slide for Apple Watch Extension
//
//  Created by Carlos Crane on 9/23/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import CoreGraphics
import Foundation
import UIKit
import WatchKit

public class SubmissionRowController: NSObject {
    
    var titleText: NSAttributedString?
    var thumbnail: UIImage?
    var largeimage: UIImage?
    var id: String?
    var sub: String?
    var scoreText: String!
    var commentText: String!
    var dictionary: NSDictionary!

    @IBOutlet weak var imageGroup: WKInterfaceGroup!
    @IBOutlet var bannerImage: WKInterfaceImage!
    @IBOutlet weak var scoreLabel: WKInterfaceLabel!
    @IBOutlet weak var commentsLabel: WKInterfaceLabel!
    @IBOutlet weak var infoLabel: WKInterfaceLabel!
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet var bigImage: WKInterfaceImage!
    @IBOutlet var thumbGroup: WKInterfaceGroup!
    
    @IBOutlet var upvote: WKInterfaceButton!
    @IBOutlet var downvote: WKInterfaceButton!
    @IBOutlet var readlater: WKInterfaceButton!
    
    @IBAction func didUpvote() {
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedUp = upvote
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedDown = downvote
        (WKExtension.shared().visibleInterfaceController as? Votable)?.doVote(id: id!, upvote: true, downvote: false)
    }
    @IBAction func didDownvote() {
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedUp = upvote
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedDown = downvote
        (WKExtension.shared().visibleInterfaceController as? Votable)?.doVote(id: id!, upvote: false, downvote: true)
    }
    
    @IBAction func didSaveLater() {
        (WKExtension.shared().visibleInterfaceController as? Votable)?.sharedReadLater = readlater
        (WKExtension.shared().visibleInterfaceController as? Votable)?.doReadLater(id: id!, sub: sub!)
    }

    func setData(dictionary: NSDictionary, color: UIColor) {
        largeimage = nil
        thumbnail = nil
        self.dictionary = dictionary
        
        let titleFont = UIFont.systemFont(ofSize: 14)
        let subtitleFont = UIFont.boldSystemFont(ofSize: 10)
        let attributedTitle = NSMutableAttributedString(string: dictionary["title"] as! String, attributes: [NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: UIColor.white])
        id = dictionary["id"] as? String ?? ""
        sub = dictionary["subreddit"] as? String ?? ""
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
        
        let endString = NSMutableAttributedString(string: "  •  \(dictionary["created"] as! String)", attributes: [NSAttributedString.Key.font: subtitleFont, NSAttributedString.Key.foregroundColor: UIColor.gray])
        
        let authorString = NSMutableAttributedString(string: "\nu/\(dictionary["author"] as? String ?? "")", attributes: [NSAttributedString.Key.font: subtitleFont, NSAttributedString.Key.foregroundColor: UIColor.gray])
        
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
        let boldString = NSMutableAttributedString(string: (dictionary["subreddit"] as? String ?? "").getSubredditFormatted(), attributes: attrs)
        
            boldString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange.init(location: 0, length: boldString.length))
        
        let infoString = NSMutableAttributedString()
            infoString.append(boldString)
            infoString.append(endString)
        infoString.append(NSAttributedString(string: "\n"))
        infoString.append(attributedTitle)
        titleLabel.setAttributedText(infoString)

        let type = ContentType.getContentType(dict: dictionary)
        var big = false
        var text = ""
        switch type {
        case .ALBUM:
            text = ("Album")
        case .REDDIT_GALLERY:
            text = ("Reddit Gallery")
        case .EXTERNAL:
            text = "External Link"
        case .LINK, .EMBEDDED, .NONE:
            text = "Link"
        case .DEVIANTART:
            text = "Deviantart"
        case .TUMBLR:
            text = "Tumblr"
        case .XKCD:
            text = ("XKCD")
        case .GIF:
            if (dictionary["domain"] as? String ?? "") == "v.redd.it" {
                text = "Reddit Video"
            } else {
                text = ("GIF")
            }
        case .IMGUR, .IMAGE:
            big = true && dictionary["bigimage"] != nil
            text = ("Image")
        case .YOUTUBE:
            text = "YouTube"
        case .STREAMABLE:
            text = "Streamable"
        case .VID_ME:
            text = ("Vid.me")
        case .REDDIT:
            text = ("Reddit content")
        default:
            text = "Link"
        }

        readlater.setBackgroundColor((dictionary["readLater"] ?? false) as! Bool ? UIColor.init(hexString: "#4CAF50") : UIColor.gray)
        upvote.setBackgroundColor((dictionary["upvoted"] ?? false) as! Bool ? UIColor.init(hexString: "#FF5700") : UIColor.gray)
        downvote.setBackgroundColor((dictionary["downvoted"] ?? false) as! Bool ? UIColor.init(hexString: "#9494FF") : UIColor.gray)
        readlater.setBackgroundColor(UIColor.gray)
        
        if big {
            bigImage.setHidden(false)
            thumbGroup.setHidden(true)
        } else {
            bigImage.setHidden(true)
            thumbGroup.setHidden(false)
        }
        
        let domain = dictionary["domain"] as? String ?? ""
        let aboutString = NSMutableAttributedString(string: "\(text)", attributes: [NSAttributedString.Key.font: subtitleFont.withSize(13)])
        aboutString.append(NSMutableAttributedString(string: "\n\(domain)", attributes: [NSAttributedString.Key.font: subtitleFont]))
        infoLabel.setAttributedText(aboutString)

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
        titleText = infoString
        
        let scoreNumber = dictionary["score"] as? Int ?? 0
        scoreText = scoreNumber > 1000 ?
            String(format: "%0.1fk   ", (Double(scoreNumber) / Double(1000))) : "\(scoreNumber)   "
        scoreLabel.setText(scoreText)
        commentText = "\(dictionary["num_comments"] as? Int ?? 0)"
        commentsLabel.setText(commentText)
        
        if big, let imageurl = (dictionary["bigimage"] as? String), !imageurl.isEmpty(), imageurl.startsWith("http") {
            DispatchQueue.global().async {
                let imageUrl = URL(string: imageurl)!
                URLSession.shared.dataTask(with: imageUrl, completionHandler: { (data, _, _) in
                    if let image = UIImage(data: data!) {
                        self.largeimage = image
                        DispatchQueue.main.async {
                            self.bigImage.setImage(self.largeimage!)
                        }
                    } else {
                        NSLog("could not load data from image URL: \(imageUrl)")
                    }
                }).resume()
            }
        } else if let thumburl = (dictionary["thumbnail"] as? String), !thumburl.isEmpty(), thumburl.startsWith("http") {
            DispatchQueue.global().async {
                let imageUrl = URL(string: thumburl)!
                URLSession.shared.dataTask(with: imageUrl, completionHandler: { (data, _, _) in
                    if let image = UIImage(data: data!) {
                        self.thumbnail = image
                        DispatchQueue.main.async {
                            self.bannerImage.setImage(self.thumbnail!)
                        }
                    } else {
                        NSLog("could not load data from image URL: \(imageUrl)")
                    }
                }).resume()
            }
        } else if type == .SELF || type == .NONE {
            thumbGroup.setHidden(true)
            bigImage.setHidden(true)
        } else {
            if dictionary["spoiler"] as? Bool ?? false {
                self.bannerImage.setImage(UIImage(named: "reports")?.getCopy(withSize: CGSize(width: 25, height: 25)))
            } else if type == .REDDIT || (dictionary["is_self"] as? Bool ?? false) {
                self.bannerImage.setImage(UIImage(named: "reddit")?.getCopy(withSize: CGSize(width: 25, height: 25)))
            } else {
                self.bannerImage.setImage(UIImage(named: "nav")?.getCopy(withSize: CGSize(width: 25, height: 25)))
            }
        }
        self.imageGroup.setCornerRadius(10)
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
}
