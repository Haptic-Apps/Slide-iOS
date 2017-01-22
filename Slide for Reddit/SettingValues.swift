//
//  SettingValues.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/9/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

class SettingValues{
    
    public static let pref_viewType = "VIEW_TYPE"
    public static let pref_hiddenFAB = "HIDDEN_FAB"
    public static let pref_defaultSorting = "DEFAULT_SORT"
    public static let pref_defaultTimePeriod = "DEFAULT_TIME"
    public static let pref_defaultCommentSorting = "DEFAULT_SORT_COMMENT"
    public static let pref_tintingMode = "TINTING_MODE"
    public static let pref_onlyTintOutside = "TINT_OUTSIDE"
    public static let pref_postViewMode = "POST_VIEW_MODE"
    public static let pref_pictureMode = "PICTURE_MODE"
    public static let pref_hideImageSelftext = "HIDE_IMAGE_SELFTEXT"
    public static let pref_abbreviateScores = "ABBREVIATE_SCORES"
    public static let pref_commentCountLastVisit = "COMMENT_COUNT_LAST_VISIT"
    public static let pref_rightThumbnail = "RIGHT_ALIGNED_THUMBNAIL"
    public static let pref_hideButtonActionbar = "HIDE_BUTTON_ACTIONBAR"
    public static let pref_saveButtonActionbar = "SHOW_BUTTON_ACTIONBAR"
    public static let pref_enlargeLinks = "ENLARGE_LINKS"
    public static let pref_showLinkContentType = "SHOW_LINK_CONTENT_TYPE"
    public static let pref_commentFontSize = "COMMENT_FONT_SIZE"
    public static let pref_postFontSize = "POST_FONT_SIZE"
    public static let pref_internalGifView = "INTERNAL_GIF_VIEW"
    public static let pref_internalAlbumView = "INTERNAL_ALBUM_VIEW"
    public static let pref_internalImageView = "INTERNAL_IMAGE_VIEW"
    public static let pref_forceExternalBrowserLinks = "TO_OPEN_EXTERNALLY"
    public static let pref_saveHistory = "SAVE_HISTORY"
    public static let pref_saveNSFWHistory = "SAVE_HISTORY_NSFW"
    public static let pref_markReadOnScroll = "MARK_READ_ON_SCROLL"
    public static let pref_dataSavingEnableMobile = "DATASAVING_ENABLE_MOBILE"
    public static let pref_dataSavingEnableWiFi = "DATASAVING_ENABLE_WIFI"
    public static let pref_dataSavingImageQuality = "DATASAVING_IMAGE_QUALITY"
    public static let pref_upvotePercentage = "UPVOTE_PERCENTAGE"

    public static var viewType = true
    public static var hiddenFAB = true
    public static var upvotePercentage = true
    public static var defaultSorting = LinkSortType.hot
    public static var defaultTimePeriod = TimeFilterWithin.day
    public static var defaultCommentSorting = CommentSort.confidence
    public static var tintingMode = "TINTING_MODE"
    public static var onlyTintOutside = false
    public static var postViewMode = "POST_VIEW_MODE"
    public static var pictureMode = "PICTURE_MODE"
    public static var hideImageSelftext = false
    public static var abbreviateScores = true
    public static var commentCountLastVisit = true
    public static var rightThumbnail = true
    public static var hideButtonActionbar = false
    public static var saveButtonActionbar = true
    public static var enlargeLinks = true
    public static var showLinkContentType = true
    public static var commentFontSize = 16
    public static var postFontSize = 18
    public static var internalGifView = true
    public static var internalAlbumView = true
    public static var internalImageView = true
    public static var forceExternalBrowserLinks : [String] = []
    public static var saveHistory = true
    public static var saveNSFWHistory = true
    public static var markReadOnScroll = false
    public static var dataSavingEnableMobile = false
    public static var dataSavingEnableWiFi = false
    public static var dataSavingImageQuality = "DATASAVING_IMAGE_QUALITY"
    
    public static func initialize(){
        let settings = UserDefaults.standard
        SettingValues.viewType = settings.bool(forKey: SettingValues.pref_viewType)
    }
}
