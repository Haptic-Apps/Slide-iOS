//
//  RSubmission+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/6/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation
import Realm
import reddift

extension RSubmission {
    
    func getLinkView() -> LinkCellView {
        var target = CurrentType.none
        let submission = self

        var thumb = submission.thumbnail
        var big = submission.banner
        let height = submission.height

        var type = ContentType.getContentType(baseUrl: submission.url)
        if submission.isSelf {
            type = .SELF
        }

        //        if (SettingValues.bannerHidden) {
        //            big = false
        //            thumb = true
        //        }

        let fullImage = ContentType.fullImage(t: type)

        if !fullImage && height < 75 {
            big = false
            thumb = true
        }

        if type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big {
            big = false
            thumb = false
        }

        if height < 75 {
            thumb = true
            big = false
        }

        if type == ContentType.CType.SELF && SettingValues.hideImageSelftext
            || SettingValues.noImages && submission.isSelf {
            big = false
            thumb = false
        }

        if big || !submission.thumbnail {
            thumb = false
        }

        if !big && !thumb && submission.type != .SELF && submission.type != .NONE { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
        }

        let sub = submission.subreddit
        if submission.nsfw && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection && Subscriptions.isCollection(sub)) {
            big = false
            thumb = true
        }

        if SettingValues.noImages {
            big = false
            thumb = false
        }
        if thumb && type == .SELF {
            thumb = false
        }

        if thumb && !big {
            target = .thumb
        } else if big {
            target = .banner
        } else {
            target = .text
        }

        if type == .LINK && SettingValues.linkAlwaysThumbnail {
            target = .thumb
        }

        var cell: LinkCellView!
        if target == .thumb {
            cell = ThumbnailLinkCellView()
        } else if target == .banner {
            if SettingValues.shouldAutoPlay() && (ContentType.displayVideo(t: type) && type != .VIDEO) {
                cell = AutoplayBannerLinkCellView()
            } else {
                cell = BannerLinkCellView()
            }
        } else {
            cell = TextLinkCellView()
        }

        return cell

    }
}
