//
//  FullLinkCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/28/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

final class FullLinkCellView: LinkCellView {
    
    override func configureView() {
        full = true
        self.textView = TextDisplayStackView.init(fontSize: 16, submission: false, color: ColorUtil.baseAccent, width: 100, delegate: self).then {
            $0.accessibilityIdentifier = "Self Text View"
            $0.backgroundColor = ColorUtil.foregroundColor
            $0.isHidden = true
        }
        super.configureView()
    }
    
    override func layoutForType() {
        super.layoutForType()
        
        let ceight = CFloat(8)
        let ctwelve = CFloat(12)
        let bannerPadding = CFloat(5)
        
        constraintsForType = batch {
            textView.bottomAnchor == infoBox.topAnchor - (ctwelve / 2)
            infoBox.bottomAnchor >= box.topAnchor - (ctwelve / 2)
            infoBox.horizontalAnchors == contentView.horizontalAnchors + ctwelve
            textView.topAnchor == title.bottomAnchor + ceight
            textView.horizontalAnchors == contentView.horizontalAnchors + ctwelve
            title.topAnchor == contentView.topAnchor + ctwelve - 5
            title.horizontalAnchors == contentView.horizontalAnchors + ctwelve

            if big {
                bannerImage.isHidden = false
                // Image goes between title and buttons
                title.bottomAnchor <= bannerImage.topAnchor - ceight
                
                bannerImage.horizontalAnchors == contentView.horizontalAnchors + bannerPadding
                bannerImage.bottomAnchor == infoBox.topAnchor - ctwelve
                if type != ContentType.CType.IMAGE {
                    infoContainer.isHidden = false
                }
                infoContainer.heightAnchor == CGFloat(45)
                infoContainer.leftAnchor == bannerImage.leftAnchor
                infoContainer.bottomAnchor == bannerImage.bottomAnchor
                infoContainer.rightAnchor == bannerImage.rightAnchor
                
                if videoView != nil {
                    videoView.edgeAnchors == bannerImage.edgeAnchors
                    topVideoView.edgeAnchors == videoView.edgeAnchors
                }
            } else if thumb {
                thumbImageContainer.isHidden = false
                infoContainer.backgroundColor = .clear
                info.textColor = ColorUtil.fontColor
                let ceight = CGFloat(8)
                let ctwelve = CGFloat(12)
                thumbImageContainer.bottomAnchor <= infoBox.topAnchor - ceight
                
                // Thumbnail sizing
                thumbImageContainer.topAnchor == title.bottomAnchor + ctwelve
                thumbImageContainer.leftAnchor == contentView.leftAnchor + ctwelve
                infoContainer.heightAnchor == CGFloat(75)
                infoContainer.isHidden = false

                let thumbSize: CGFloat = 75
                thumbImageContainer.widthAnchor == thumbSize
                thumbImageContainer.heightAnchor == thumbSize
                
                infoContainer.leftAnchor == thumbImageContainer.rightAnchor + bannerPadding
                infoContainer.verticalAnchors == thumbImageContainer.verticalAnchors
                infoContainer.rightAnchor == contentView.rightAnchor - bannerPadding
            }
        }
        layoutForContent()
    }
    
    override func layoutForContent() {
        super.layoutForContent()
        
        constraintsForContent = batch {
            bannerImage.heightAnchor == CGFloat(submissionHeight)
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
