//
//  TextLinkCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/25/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

final class TextLinkCellView: LinkCellView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */

    override func layoutForType() {
        super.layoutForType()
        let ceight = SettingValues.postViewMode == .COMPACT ? CGFloat(4) : CGFloat(8)
        let ctwelve = SettingValues.postViewMode == .COMPACT ? CGFloat(8) : CGFloat(12)
        constraintsForType = batch {
            title.topAnchor == contentView.topAnchor + ctwelve
            if SettingValues.actionBarMode == .SIDE_RIGHT {
                sideButtons.topAnchor == contentView.topAnchor + ctwelve
                title.rightAnchor == sideButtons.leftAnchor - ceight
                title.leftAnchor == contentView.leftAnchor + ctwelve
            } else if SettingValues.actionBarMode == .SIDE {
                sideButtons.topAnchor == contentView.topAnchor + ctwelve
                title.leftAnchor == sideButtons.rightAnchor + ceight
                title.rightAnchor == contentView.rightAnchor - ctwelve
            } else {
                title.horizontalAnchors == contentView.horizontalAnchors + ctwelve
            }
            if !SettingValues.actionBarMode.isFull() {
                title.bottomAnchor == contentView.bottomAnchor - ctwelve
            } else {
                title.bottomAnchor == box.topAnchor - ceight
            }
        }
    }

    override func layoutForContent() {
        
    }
    
//    override func doConstraints() {
//        let target = CurrentType.text
//        
//        if(currentType == target && target != .banner){
//            return //work is already done
//        } else if(currentType == target && target == .banner && bigConstraint != nil){
//            self.contentView.addConstraint(bigConstraint!)
//            return
//        }
//        
//        let metrics=["horizontalMargin":75,"top":0,"bottom":0,"separationBetweenLabels":0,"size": full ? 16 : 12, "labelMinHeight":75,  "thumb": (SettingValues.largerThumbnail ? 75 : 50), "ctwelve": SettingValues.postViewMode == .COMPACT ? 8 : 12,"ceight": SettingValues.postViewMode == .COMPACT ? 4 : 8,"bannerHeight": submissionHeight] as [String: Int]
//        let views=["label":title, "body": textView, "image": thumbImage, "info": b, "upvote": upvote, "downvote" : downvote, "score": score, "comments": comments, "banner": bannerImage, "buttons":buttons, "box": box] as [String : Any]
//        var bt = "[buttons]-(ceight)-"
//        var bx = "[box]-(ceight)-"
//        if(SettingValues.hideButtonActionbar && !full){
//            bt = "[buttons(0)]-4-"
//            bx = "[box(0)]-4-"
//        }
//        
//        self.contentView.removeConstraints(thumbConstraint)
//        thumbConstraint = []
//        
//        
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[image(0)]",
//                                                                              options: NSLayoutFormatOptions(rawValue: 0),
//                                                                              metrics: metrics,
//                                                                              views: views))
//            
//            
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[label]-(ctwelve)-|",
//                                                                              options: NSLayoutFormatOptions(rawValue: 0),
//                                                                              metrics: metrics,
//                                                                              views: views))
//            
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[body]-(ctwelve)-|",
//                                                                              options: NSLayoutFormatOptions(rawValue: 0),
//                                                                              metrics: metrics,
//                                                                              views: views))
//            
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ctwelve)-[label]-5@1000-[body]-(ctwelve)-\(bx)|",
//                options: NSLayoutFormatOptions(rawValue: 0),
//                metrics: metrics,
//                views: views))
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:\(bt)|",
//                options: NSLayoutFormatOptions(rawValue: 0),
//                metrics: metrics,
//                views: views))
//        self.contentView.addConstraints(thumbConstraint)
//        if(target == .banner && bigConstraint != nil){
//            self.contentView.addConstraint(bigConstraint!)
//            return
//        }
//        currentType = target
//    }
    
}
