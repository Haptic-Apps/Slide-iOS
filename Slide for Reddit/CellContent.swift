//
//  CellContent.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/31/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//
import UIKit
import TTTAttributedLabel

struct CellContent {
    var attributedString: NSAttributedString
    let textHeight: CGFloat
    let id: String
    let width: CGFloat
    
    init(string: NSAttributedString, width: CGFloat, id: String) {
        attributedString = string
        self.width = width
        self.id = id
        let horizontalMargin = CommentDepthCell.margin().left + CommentDepthCell.margin().right
        let verticalMargin = CommentDepthCell.margin().top + CommentDepthCell.margin().bottom
        let size = (string).boundingRect(with: CGSize.init(width: width-horizontalMargin, height:10000), options: [.usesLineFragmentOrigin , .usesFontLeading], context: nil).height

        textHeight = size + verticalMargin
    }
    
    init(string: String, width: CGFloat, fontSize: CGFloat = 14, id: String) {
        self.id = id
        self.width =  width
        let font = FontGenerator.fontOfSize(size: fontSize, submission: id.hasPrefix("t3"))
        attributedString = NSAttributedString(string: string, attributes: [NSFontAttributeName : font])
        let horizontalMargin = CommentDepthCell.margin().left + CommentDepthCell.margin().right
        let verticalMargin = CommentDepthCell.margin().top + CommentDepthCell.margin().bottom
        let size = (string).boundingRect(with: CGSize.init(width: width-horizontalMargin, height:10000), options: [.usesLineFragmentOrigin , .usesFontLeading], context: nil).height
        textHeight = size + verticalMargin
    }
    
    //Used in comments
    init(string: NSAttributedString, width: CGFloat, hasRelies: Bool, id: String) {
        attributedString = string
        self.id = id
        self.width = width
        let horizontalMargin = CommentDepthCell.margin().left + CommentDepthCell.margin().right
        let verticalMargin = CommentDepthCell.margin().top + CommentDepthCell.margin().bottom
        let size = (string).boundingRect(with: CGSize.init(width: width-horizontalMargin, height:10000), options: [.usesLineFragmentOrigin , .usesFontLeading], context: nil).height
        if hasRelies {
            textHeight = size + verticalMargin
        } else {
            textHeight = size + verticalMargin
        }
    }
    
    init(string: NSAttributedString, width: CGFloat) {
        attributedString = string
        self.id = ""
        self.width = width
        let size = (string).boundingRect(with: CGSize.init(width: width, height:10000), options: [.usesLineFragmentOrigin , .usesFontLeading], context: nil).height
        textHeight = size
    }

    
    init(string: String, width: CGFloat, hasRelies: Bool, fontSize: CGFloat = 14, id: String) {
        self.id = id
        self.width = width
        let font = FontGenerator.fontOfSize(size: fontSize, submission: id.hasPrefix("t3"))
        attributedString = NSAttributedString(string: string, attributes: [NSFontAttributeName : font])
        let horizontalMargin = CommentDepthCell.margin().left + CommentDepthCell.margin().right
        let verticalMargin = CommentDepthCell.margin().top + CommentDepthCell.margin().bottom
        let size = (string).boundingRect(with: CGSize.init(width: width-horizontalMargin, height:10000), options: [.usesLineFragmentOrigin , .usesFontLeading], context: nil).height
        if hasRelies {
            textHeight = size + verticalMargin
        } else {
            textHeight = size + verticalMargin
        }
    }
}
