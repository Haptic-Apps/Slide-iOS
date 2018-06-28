//
//  BannerLinkCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/25/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

final class BannerLinkCellView: LinkCellView {

    override func layoutForType() {
        super.layoutForType()
        let ceight = SettingValues.postViewMode == .COMPACT ? CGFloat(4) : CGFloat(8)
        let ctwelve = SettingValues.postViewMode == .COMPACT ? CGFloat(8) : CGFloat(12)
        let bannerPadding = (full || SettingValues.postViewMode != .CARD) ? CFloat(5) : CFloat(0)
        constraintsForType = batch {
            bannerImage.isHidden = false
            if SettingValues.postViewMode == .CENTER {
                // Image goes between title and buttons
                title.topAnchor == contentView.topAnchor + ceight
                title.horizontalAnchors == contentView.horizontalAnchors + ctwelve
                title.bottomAnchor <= bannerImage.topAnchor - ceight

                bannerImage.horizontalAnchors == contentView.horizontalAnchors + bannerPadding
                bannerImage.bottomAnchor == box.topAnchor - ctwelve
            }
            else {
                // Image goes above title
                bannerImage.topAnchor == contentView.topAnchor + bannerPadding
                bannerImage.horizontalAnchors == contentView.horizontalAnchors + bannerPadding

                title.topAnchor == bannerImage.bottomAnchor + ceight
                title.horizontalAnchors == contentView.horizontalAnchors + ctwelve
                title.bottomAnchor <= box.topAnchor - ctwelve
            }

            infoContainer.heightAnchor == CGFloat(45)
            if !SettingValues.smallerTag {
                infoContainer.leftAnchor == bannerImage.leftAnchor + bannerPadding
                infoContainer.bottomAnchor == bannerImage.bottomAnchor
                infoContainer.rightAnchor == bannerImage.rightAnchor - bannerPadding
            } else {
                infoContainer.bottomAnchor == bannerImage.bottomAnchor - 4
                infoContainer.rightAnchor == bannerImage.rightAnchor - bannerPadding - ctwelve
            }

            bannerImage.heightAnchor == bannerImage.widthAnchor / aspect
        }
    }
    
//    override func doConstraints() {
//        let target = CurrentType.banner
//        
//        if(currentType == target && target != .banner){
//            return //work is already done
//        }
//        
//        if(currentType == target && target == .banner && bigConstraint != nil){
//            self.contentView.addConstraint(bigConstraint!)
//            return
//        }
//        
//        let metrics=["horizontalMargin":75,"top":0,"bottom":0,"separationBetweenLabels":0,"size": full ? 16 : 8, "labelMinHeight":75, "ctwelve": SettingValues.postViewMode == .COMPACT ? 8 : 12,"ceight": SettingValues.postViewMode == .COMPACT ? 4 : 8, "bannerPadding": (full || SettingValues.postViewMode != .CARD) ? 5 : 0, "thumb": (SettingValues.largerThumbnail ? 75 : 50), "bannerHeight": submissionHeight] as [String: Int]
//        let views=["label":title, "body": textView, "image": thumbImage, "info": b, "tag" : tagbody, "upvote": upvote, "downvote" : downvote, "score": score, "comments": comments, "banner": bannerImage, "buttons":buttons, "box": box] as [String : Any]
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
//        thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-[image(0)]",
//                                                                          options: NSLayoutFormatOptions(rawValue: 0),
//                                                                          metrics: metrics,
//                                                                          views: views))
//        thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[label]-(ctwelve)-|",
//                                                                          options: NSLayoutFormatOptions(rawValue: 0),
//                                                                          metrics: metrics,
//                                                                          views: views))
//        if(SettingValues.postViewMode == .CENTER || full){
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[label]-(ceight)-[banner]-(ctwelve)-\(bx)|",
//                options: NSLayoutFormatOptions(rawValue: 0),
//                metrics: metrics,
//                views: views))
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[info]-[banner]",
//                                                                              options: NSLayoutFormatOptions.alignAllLastBaseline,
//                                                                              metrics: metrics,
//                                                                              views: views))
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[banner]-[tag]",
//                                                                              options: NSLayoutFormatOptions.alignAllLastBaseline,
//                                                                              metrics: metrics,
//                                                                              views: views))
//            
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[info(45)]-(ceight)-[buttons]",
//                                                                              options: NSLayoutFormatOptions(rawValue: 0),
//                                                                              metrics: metrics,
//                                                                              views: views))
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[tag]-(ctwelve)-[buttons]",
//                                                                              options: NSLayoutFormatOptions(rawValue: 0),
//                                                                              metrics: metrics,
//                                                                              views: views))
//            
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[info]-(ceight)-[box]",
//                                                                              options: NSLayoutFormatOptions(rawValue: 0),
//                                                                              metrics: metrics,
//                                                                              views: views))
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[tag]-(ctwelve)-[box]",
//                                                                              options: NSLayoutFormatOptions(rawValue: 0),
//                                                                              metrics: metrics,
//                                                                              views: views))
//            
//            
//        } else {
//            
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(bannerPadding)-[banner]-(ceight)-[label]-(ctwelve)-\(bx)|",
//                options: NSLayoutFormatOptions(rawValue: 0),
//                metrics: metrics,
//                views: views))
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[info(45)]-(ceight)-[label]",
//                                                                              options: NSLayoutFormatOptions(rawValue: 0),
//                                                                              metrics: metrics,
//                                                                              views: views))
//            
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[tag]-(ctwelve)-[label]",
//                                                                              options: NSLayoutFormatOptions(rawValue: 0),
//                                                                              metrics: metrics,
//                                                                              views: views))
//            
//        }
//        
//        thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:\(bt)|",
//            options: NSLayoutFormatOptions(rawValue: 0),
//            metrics: metrics,
//            views: views))
//        thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:\(bx)|",
//            options: NSLayoutFormatOptions(rawValue: 0),
//            metrics: metrics,
//            views: views))
//        
//        thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(bannerPadding)-[banner]-(bannerPadding)-|",
//                                                                          options: NSLayoutFormatOptions(rawValue: 0),
//                                                                          metrics: metrics,
//                                                                          views: views))
//        thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(bannerPadding)-[info]-(bannerPadding)-|",
//                                                                          options: NSLayoutFormatOptions(rawValue: 0),
//                                                                          metrics: metrics,
//                                                                          views: views))
//        thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[tag]-(ctwelve)-|",
//                                                                          options: NSLayoutFormatOptions(rawValue: 0),
//                                                                          metrics: metrics,
//                                                                          views: views))
//        
//        self.contentView.addConstraints(thumbConstraint)
//        currentType = target
//        if( target == .banner && bigConstraint != nil){
//            self.contentView.addConstraint(bigConstraint!)
//            return
//        }
//        
//    }
    
}
