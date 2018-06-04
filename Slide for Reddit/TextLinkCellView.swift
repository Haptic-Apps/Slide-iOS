//
//  TextLinkCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/25/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class TextLinkCellView: LinkCellView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    override func doConstraints() {
        let target = CurrentType.text
        
        if(currentType == target && target != .banner){
            return //work is already done
        } else if(currentType == target && target == .banner && bigConstraint != nil){
            self.contentView.addConstraint(bigConstraint!)
            return
        }
        
        let metrics=["horizontalMargin":75,"top":0,"bottom":0,"separationBetweenLabels":0,"size": full ? 16 : 12, "labelMinHeight":75,  "thumb": (SettingValues.largerThumbnail ? 75 : 50), "ctwelve": SettingValues.postViewMode == .COMPACT ? 8 : 12,"ceight": SettingValues.postViewMode == .COMPACT ? 4 : 8,"bannerHeight": submissionHeight] as [String: Int]
        let views=["label":title, "body": textView, "image": thumbImage, "info": b, "upvote": upvote, "downvote" : downvote, "score": score, "comments": comments, "banner": bannerImage, "buttons":buttons, "box": box] as [String : Any]
        var bt = "[buttons]-(ceight)-"
        var bx = "[box]-(ceight)-"
        if(SettingValues.hideButtonActionbar && !full){
            bt = "[buttons(0)]-4-"
            bx = "[box(0)]-4-"
        }
        
        self.contentView.removeConstraints(thumbConstraint)
        thumbConstraint = []
        
        
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[image(0)]",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[label]-(ctwelve)-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[body]-(ctwelve)-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ctwelve)-[label]-5@1000-[body]-(ctwelve)-\(bx)|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:\(bt)|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        self.contentView.addConstraints(thumbConstraint)
        if(target == .banner && bigConstraint != nil){
            self.contentView.addConstraint(bigConstraint!)
            return
        }
        currentType = target
    }
    
}
