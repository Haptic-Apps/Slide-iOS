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

public class CommentsRowController: NSObject {
    
    var author: String!
    var time: String!
    var id: String!
    var fullname: String!
    var body: String!
    var submissionId: String!
    var dictionary: NSDictionary!
    
    var attributedTitle: NSAttributedString!
    var attributedBody: NSAttributedString!
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var bodyLabel: WKInterfaceLabel!
   
    func setData(dictionary: NSDictionary) {
        self.dictionary = dictionary
        let subtitleFont = UIFont.boldSystemFont(ofSize: 10)
        //let attributedTitle = NSMutableAttributedString(string: dictionary["title"] as! String, attributes: [NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: UIColor.white])
        id = dictionary["context"] as? String ?? ""
        fullname = dictionary["id"] as? String ?? ""
        submissionId = dictionary["submission"] as? String ?? ""

        let spacer = NSMutableAttributedString.init(string: "  ")
        
        let attrs = [NSAttributedString.Key.font: subtitleFont, NSAttributedString.Key.foregroundColor: UIColor.white]
        
        let endString = NSMutableAttributedString(string: "  •  \(dictionary["created"] as! String)", attributes: [NSAttributedString.Key.font: subtitleFont, NSAttributedString.Key.foregroundColor: UIColor.gray])
        
        let authorString = NSMutableAttributedString(string: "u/\(dictionary["author"] as? String ?? "")", attributes: [NSAttributedString.Key.font: subtitleFont, NSAttributedString.Key.foregroundColor: UIColor.gray])
        
        authorString.append(endString)
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
        
        let infoString = NSMutableAttributedString()
            infoString.append(authorString)
        let scoreNumber = dictionary["score"] as? Int ?? 0
        let scoreText = scoreNumber > 1000 ?
            String(format: "%0.1fk   ", (Double(scoreNumber) / Double(1000))) : "\(scoreNumber)   "
        infoString.append(spacer)
        let scoreString = NSMutableAttributedString(string: scoreText, attributes: attrs)
        scoreString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: NSRange.init(location: 0, length: scoreString.length))
        infoString.append(scoreString)
        self.attributedTitle = infoString
        titleLabel.setAttributedText(infoString)
        if let html = (dictionary["body"] as! String).replacingOccurrences(of: "<div class=\"md\">", with: "").replacingOccurrences(of: "</p>\n</div>", with: "</p>").replacingOccurrences(of: "<p>", with: "").replacingOccurrences(of: "</p>", with: "</br>").data(using: String.Encoding.unicode) {
            do {
                let attributedText = try NSMutableAttributedString(data: html, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                attributedText.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange(location: 0, length: attributedText.length))
                self.attributedBody = attributedText
                bodyLabel.setAttributedText(attributedText)
            } catch {
                //todo populate attributed string
                bodyLabel.setText(dictionary["body"] as? String)
            }
        } else {
            //todo populate attributed string
            bodyLabel.setText(dictionary["body"] as? String)
        }
    }
}
