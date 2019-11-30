//
//  GalleryLinkCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 11/30/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit
import YYText

final class GalleryLinkCellView: LinkCellView {
    
    override func layoutForType() {
        super.layoutForType()
        
        let ceight = CGFloat(4)
        let ctwelve = CGFloat(8)
        let bannerPadding = CFloat(3)
        
        constraintsForType = batch {
            bannerImage.isHidden = false
            if SettingValues.postViewMode == .CENTER {
                // Image goes between title and buttons
                title.topAnchor == contentView.topAnchor + ctwelve
                if SettingValues.actionBarMode == .SIDE_RIGHT {
                    sideButtons.topAnchor == contentView.topAnchor + ctwelve
                    sideButtons.bottomAnchor <= bannerImage.topAnchor - ceight
                    title.rightAnchor == sideButtons.leftAnchor - ceight
                    title.leftAnchor == contentView.leftAnchor + ctwelve
                } else if SettingValues.actionBarMode == .SIDE {
                    sideButtons.topAnchor == contentView.topAnchor + ctwelve
                    sideButtons.bottomAnchor <= bannerImage.topAnchor - ceight
                    title.leftAnchor == sideButtons.rightAnchor + ceight
                    title.rightAnchor == contentView.rightAnchor - ctwelve
                } else {
                    title.horizontalAnchors == contentView.horizontalAnchors + ctwelve
                }
                title.bottomAnchor <= bannerImage.topAnchor - ceight

                bannerImage.horizontalAnchors == contentView.horizontalAnchors + bannerPadding
                
                if SettingValues.actionBarMode.isFull() {
                    bannerImage.bottomAnchor == box.topAnchor - ctwelve
                } else {
                    bannerImage.bottomAnchor == contentView.bottomAnchor - ctwelve
                }
                
                videoView.edgeAnchors == bannerImage.edgeAnchors
                topVideoView.edgeAnchors == videoView.edgeAnchors
            } else {
                // Image goes above title
                if SettingValues.actionBarMode == .SIDE_RIGHT {
                    title.rightAnchor == sideButtons.leftAnchor - ceight
                    title.leftAnchor == contentView.leftAnchor + ctwelve
                } else if SettingValues.actionBarMode == .SIDE {
                    title.leftAnchor == sideButtons.rightAnchor + ceight
                    title.rightAnchor == contentView.rightAnchor - ctwelve
                } else {
                    title.horizontalAnchors == contentView.horizontalAnchors + ctwelve
                }
                
                if !SettingValues.actionBarMode.isFull() {
                    title.bottomAnchor <= contentView.bottomAnchor - ceight
                } else {
                    title.bottomAnchor == box.topAnchor - ceight
                }
                
                bannerImage.topAnchor == contentView.topAnchor + bannerPadding
                bannerImage.bottomAnchor == title.topAnchor - ceight
                bannerImage.horizontalAnchors == contentView.horizontalAnchors + bannerPadding
                if SettingValues.actionBarMode.isSide() {
                    sideButtons.topAnchor == bannerImage.bottomAnchor + ceight
                    sideButtons.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
                    sideButtons.bottomAnchor <= contentView.bottomAnchor - ceight
                }
                
                videoView.edgeAnchors == bannerImage.edgeAnchors
                topVideoView.edgeAnchors == videoView.edgeAnchors
            }
            
            infoContainer.heightAnchor == CGFloat(45)
            tagbody.bottomAnchor == bannerImage.bottomAnchor - 8
            tagbody.rightAnchor == bannerImage.rightAnchor - 8
        }
    }
    
    override func layoutForContent() {
        super.layoutForContent()
        
        self.downvote.isHidden = true
        self.share.isHidden = true
        self.hide.isHidden = true
        self.readLater.isHidden = true
        self.save.isHidden = true
        
        self.bannerImage.layer.cornerRadius = 5
        self.videoView.layer.cornerRadius = 5
                
        constraintsForContent = batch {
            // bannerImage.heightAnchor >= CGFloat(submissionHeight)
        }
    }
    
    override func refreshTitle(np: Bool = false, force: Bool = false) {
            guard let link = self.link else {
                return
            }

        let attText = CachedTitle.getTitle(submission: link, full: full, force, false, gallery: true)
            let bounds = self.estimateHeightSingle(full, np: np, attText: attText)
            if oldBounds.width != bounds.textBoundingSize.width || oldBounds.height != bounds.textBoundingSize.height {
                oldBounds = bounds.textBoundingSize
                title.textLayout = bounds
                title.textContainerInset = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
                title.preferredMaxLayoutWidth = bounds.textBoundingSize.width
            }
            title.attributedText = attText
            title.textVerticalAlignment = .top
    }
    
    override func refresh(np: Bool = false) {
        super.refresh(np: np)
        title.alpha = 0.8
    }
}
