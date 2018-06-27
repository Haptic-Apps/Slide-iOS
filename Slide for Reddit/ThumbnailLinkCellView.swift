//
//  ThumbnailLinkCellView
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/25/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

final class ThumbnailLinkCellView: LinkCellView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */

    override func layoutForType() {
        super.layoutForType()
        constraintsForType = batch {
            thumbImageContainer.isHidden = false
            thumbImageContainer.bottomAnchor <= box.topAnchor - 8

            // Thumbnail sizing
            thumbImageContainer.topAnchor == contentView.topAnchor + 8
            if SettingValues.leftThumbnail {
                thumbImageContainer.leftAnchor == contentView.leftAnchor + 8
            }
            else {
                thumbImageContainer.rightAnchor == contentView.rightAnchor - 8
            }

            let thumbSize: CGFloat = (SettingValues.largerThumbnail ? 75 : 50) - (SettingValues.postViewMode == .COMPACT ? 15 : 0)
            thumbImageContainer.widthAnchor == thumbSize
            thumbImageContainer.heightAnchor == thumbSize

            title.topAnchor == contentView.topAnchor + 8
            title.leftAnchor == (SettingValues.leftThumbnail ? thumbImageContainer.rightAnchor + 8 : contentView.leftAnchor + 8)
            title.rightAnchor == (SettingValues.leftThumbnail ? contentView.rightAnchor - 8 : thumbImageContainer.leftAnchor - 8)
            title.bottomAnchor <= box.topAnchor - 8
        }
    }
    
//    override func doConstraints() {
//        let target = CurrentType.thumb
//                
//        if(currentType == target && target != .banner){
//            return //work is already done
//        } else if(currentType == target && target == .banner && bigConstraint != nil){
//            self.contentView.addConstraint(bigConstraint!)
//            return
//        }
//        
//        let metrics=["horizontalMargin":75,"top":0,"bottom":0,"separationBetweenLabels":0,"size": full ? 16 : 8, "labelMinHeight":75,  "ctwelve": SettingValues.postViewMode == .COMPACT ? 8 : 12,"ceight": SettingValues.postViewMode == .COMPACT ? 4 : 8,"thumb": (SettingValues.largerThumbnail ? 75 : 50), "bannerHeight": submissionHeight] as [String: Int]
//        let views=["label":title, "body": textView, "image": thumbImage, "info": b, "upvote": upvote, "downvote" : downvote, "score": score, "comments": comments, "banner": bannerImage, "buttons":buttons, "box": box] as [String : Any]
//        var bt = "(ceight)-[buttons]-(ceight)-"
//        var bx = "(ceight)-[box]-(ceight)-"
//        if(SettingValues.hideButtonActionbar && !full){
//            bt = "(ceight)-[buttons(0)]-"
//            bx = "(ceight)-[box(0)]-"
//        }
//        
//        self.contentView.removeConstraints(thumbConstraint)
//        thumbConstraint = []
//        
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[image(thumb)]",
//                                                                              options: NSLayoutFormatOptions(rawValue: 0),
//                                                                              metrics: metrics,
//                                                                              views: views))
//            if(SettingValues.leftThumbnail){
//                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ceight)-[image(thumb)]-(ceight)-[label]-(ctwelve)-|",
//                                                                                  options: NSLayoutFormatOptions(rawValue: 0),
//                                                                                  metrics: metrics,
//                                                                                  views: views))
//            } else {
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[label]-(ceight)-[image(thumb)]-(ceight)-|",
//                                                                              options: NSLayoutFormatOptions(rawValue: 0),
//                                                                              metrics: metrics,
//                                                                              views: views))
//            }
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[label]-\(bx)|",
//                options: NSLayoutFormatOptions(rawValue: 0),
//                metrics: metrics,
//                views: views))
//            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[label]-\(bt)|",
//            options: NSLayoutFormatOptions(rawValue: 0),
//            metrics: metrics,
//            views: views))
//
//        self.contentView.addConstraints(thumbConstraint)
//        if(target == .banner && bigConstraint != nil){
//            self.contentView.addConstraint(bigConstraint!)
//            return
//        }
//        currentType = target
//    }
    
}
