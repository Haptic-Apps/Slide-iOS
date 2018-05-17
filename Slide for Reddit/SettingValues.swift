//
//  SettingValues.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/9/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import MaterialComponents.MaterialSnackbar

class SettingValues {

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
    public static let pref_upvotePercentage = "UPVOTE_PERCENTAGE"
    public static let pref_cropBigPic = "BIG_PIC_CROPPED"
    public static let pref_bannerHidden = "BANNER_HIDDEN"
    public static let pref_centerLead = "CENTER_LEAD_IMAGE"
    public static let pref_largerThumbnail = "LARGER_THUMBNAIL"
    public static let pref_scoreInTitle = "SCORE_IN_TITLE"
    public static let pref_dataSavingEnabled = "DATA_SAVING_ENABLED"
    public static let pref_dataSavingDisableWifi = "DATA_SAVING_D_WIFI"
    public static let pref_loadContentHQ = "LOAD_CONTENT_HQ"
    public static let pref_lqLow = "LQ_LOW"
    public static let pref_noImg = "NO_IMAGES"
    public static let pref_nsfwEnabled = "NSFW_ENABLED"
    public static let pref_nsfwPreviews = "NSFW_PREVIEWS"
    public static let pref_hideNSFWCollection = "NSFW_COLLECTION"
    public static let pref_domainInInfo = "DOMAIN_INFO"
    public static let pref_disableNavigationBar = "DISABLE_NAV"
    public static let pref_disableColor = "DISABLE_COLOR"
    public static let pref_collapseDefault = "COLLAPSE_DEFAULT"
    public static let pref_volumeButtonNavigation = "VOLUME_NAV"
    public static let pref_leftThumbnail = "LEFT_THUMB"
    public static let pref_hideButton = "HIDE_BUTTON"
    public static let pref_saveButton = "SAVE_BUTTON"
    public static let pref_internalGif = "INTERNAL_GIF"
    public static let pref_internalImage = "INTERNAL_IMAGE"
    public static let pref_internalAlbum = "INTERNAL_ALBUM"
    public static let pref_internalYouTube = "INTERNAL_YOUTUBE"
    public static let pref_multiColumn = "MULTI_COLUMN"
    public static let pref_showFirstParagraph = "FIRST_P"
    public static let pref_swapLongPress = "SWAP_LONG_PRESS"
    public static let pref_collapseFully = "COLLAPSE_FULLY"
    public static let pref_highlightOp = "HIGHLIGHT_OP"
    public static let pref_smallTag = "SMALLER_TAG"
    public static let pref_biometrics = "BIOMETRICS"
    public static let pref_safariVC = "SAFARIVC"
    public static let pref_fabType = "FABTYPE"


    public static var viewType = true
    public static var hiddenFAB = true
    public static var upvotePercentage = true
    public static var defaultSorting = LinkSortType.hot
    public static var defaultTimePeriod = TimeFilterWithin.day
    public static var defaultCommentSorting = CommentSort.confidence
    public static var tintingMode = "TINTING_MODE"
    public static var onlyTintOutside = false
    public static var bannerHidden = false
    public static var postViewMode = PostViewType.LIST
    public static var fabType = FabType.HIDE_READ
    public static var pictureMode = "PICTURE_MODE"
    public static var hideImageSelftext = false
    public static var abbreviateScores = true
    public static var commentCountLastVisit = true
    public static var rightThumbnail = true
    public static var centerLeadImage = true

    public static var hideButtonActionbar = false
    public static var saveButtonActionbar = true
    public static var bigPicCropped = false
    public static var enlargeLinks = true
    public static var noImages = false
    public static var showLinkContentType = true
    public static var internalGifView = true
    public static var scoreInTitle = false
    public static var internalAlbumView = true
    public static var internalImageView = true
    public static var forceExternalBrowserLinks: [String] = []
    public static var saveHistory = true
    public static var saveNSFWHistory = false
    public static var markReadOnScroll = false
    public static var dataSavingEnabled = true
    public static var loadContentHQ = false
    public static var dataSavingDisableWiFi = false
    public static var postFontOffset = -4
    public static var commentFontOffset = -4
    public static var largerThumbnail = true
    public static var lqLow = true
    public static var nsfwEnabled = false
    public static var nsfwPreviews = false
    public static var hideNSFWCollection = false
    public static var domainInInfo = false
    public static var disableNavigationBar = false
    public static var disableColor = false
    public static var collapseDefault = false
    public static var volumeButtonNavigation = false
    public static var leftThumbnail = false
    public static var hideButton = false
    public static var saveButton = false
    public static var internalImage = true
    public static var internalAlbum = true
    public static var internalGif = true
    public static var internalYouTube = true
    public static var multiColumn = false
    public static var showFirstParagraph = true
    public static var swapLongPress = false
    public static var collapseFully = true
    public static var highlightOp = true
    public static var smallerTag = true
    public static var biometrics = true
    public static var safariVC = true
    public static var nightStart = 1
    public static var nightEnd = 5
    public static var nightModeEnabled = false
    public static var nightTheme = ColorUtil.Theme.DARK

    enum PostViewType: String {
        case LIST = "list"
        case DESKTOP = "desktop"
        case CARD = "card"
    }

    public static func getLinkSorting(forSubreddit: String) -> LinkSortType {
        if let sorting = UserDefaults.standard.string(forKey: forSubreddit + "Sorting") {
            for s in LinkSortType.cases {
                if (s.path == sorting) {
                    return s
                }
            }
        }
        return defaultSorting
    }

    public static func getTimePeriod(forSubreddit: String) -> TimeFilterWithin {
        if let time = UserDefaults.standard.string(forKey: forSubreddit + "Time") {
            for t in TimeFilterWithin.cases {
                if (t.param == time) {
                    return t
                }
            }
        }
        return defaultTimePeriod
    }

    public static func setSubSorting(forSubreddit: String, linkSorting: LinkSortType, timePeriod: TimeFilterWithin) {
        UserDefaults.standard.set(linkSorting.path, forKey: forSubreddit + "Sorting")
        UserDefaults.standard.set(timePeriod.param, forKey: forSubreddit + "Time")
        UserDefaults.standard.synchronize()
    }

    public static func initialize() {
        let settings = UserDefaults.standard
        SettingValues.bigPicCropped = settings.bool(forKey: SettingValues.pref_cropBigPic)
        SettingValues.saveNSFWHistory = settings.bool(forKey: SettingValues.pref_saveNSFWHistory)
        SettingValues.saveHistory = settings.object(forKey: SettingValues.pref_saveHistory) == nil ? true : settings.bool(forKey: SettingValues.pref_saveHistory)
        SettingValues.multiColumn = settings.object(forKey: SettingValues.pref_multiColumn) == nil ? true : settings.bool(forKey: SettingValues.pref_multiColumn)
        SettingValues.highlightOp = settings.object(forKey: SettingValues.pref_highlightOp) == nil ? true : settings.bool(forKey: SettingValues.pref_highlightOp)

        SettingValues.postFontOffset = settings.object(forKey: SettingValues.pref_postFontSize) == nil ? 0 : settings.integer(forKey: SettingValues.pref_postFontSize)
        SettingValues.commentFontOffset = settings.object(forKey: SettingValues.pref_commentFontSize) == nil ? 0 : settings.integer(forKey: SettingValues.pref_commentFontSize)

        if let time = UserDefaults.standard.string(forKey: pref_defaultTimePeriod) {
            for t in TimeFilterWithin.cases {
                if (t.param == time) {
                    defaultTimePeriod = t
                    break
                }
            }
        }

        if let sort = UserDefaults.standard.string(forKey: pref_defaultTimePeriod) {
            for t in LinkSortType.cases {
                if (t.path == sort) {
                    defaultSorting = t
                    break
                }
            }
        }

        if let sort = UserDefaults.standard.string(forKey: pref_defaultCommentSorting) {
            for t in CommentSort.cases {
                if (t.path == sort) {
                    defaultCommentSorting = t
                    break
                }
            }
        }

        SettingValues.smallerTag = settings.bool(forKey: SettingValues.pref_smallTag)
        SettingValues.markReadOnScroll = settings.bool(forKey: SettingValues.pref_markReadOnScroll)
        SettingValues.nsfwEnabled = settings.bool(forKey: SettingValues.pref_nsfwEnabled)
        SettingValues.nsfwPreviews = settings.bool(forKey: SettingValues.pref_nsfwPreviews)
        SettingValues.swapLongPress = settings.bool(forKey: SettingValues.pref_swapLongPress)
        SettingValues.hideNSFWCollection = settings.bool(forKey: SettingValues.pref_hideNSFWCollection)
        SettingValues.domainInInfo = settings.bool(forKey: SettingValues.pref_domainInInfo)
        SettingValues.showFirstParagraph = settings.object(forKey: SettingValues.pref_showFirstParagraph) == nil ? true : settings.bool(forKey: SettingValues.pref_showFirstParagraph)
        SettingValues.disableNavigationBar = settings.bool(forKey: SettingValues.pref_disableNavigationBar)
        SettingValues.disableColor = settings.bool(forKey: SettingValues.pref_disableColor)
        SettingValues.collapseDefault = settings.bool(forKey: SettingValues.pref_collapseDefault)
        SettingValues.volumeButtonNavigation = settings.bool(forKey: SettingValues.pref_volumeButtonNavigation)
        SettingValues.collapseFully = settings.bool(forKey: SettingValues.pref_collapseFully)
        SettingValues.leftThumbnail = settings.bool(forKey: SettingValues.pref_leftThumbnail)
        SettingValues.biometrics = settings.bool(forKey: SettingValues.pref_biometrics)

        SettingValues.dataSavingEnabled = settings.bool(forKey: SettingValues.pref_dataSavingEnabled)
        SettingValues.dataSavingDisableWiFi = settings.bool(forKey: SettingValues.pref_dataSavingDisableWifi)
        SettingValues.loadContentHQ = settings.bool(forKey: SettingValues.pref_loadContentHQ)
        SettingValues.noImages = settings.bool(forKey: SettingValues.pref_noImg)
        SettingValues.lqLow = settings.bool(forKey: SettingValues.pref_lqLow)
        SettingValues.saveButton = settings.object(forKey: SettingValues.pref_saveButton) == nil ? true : settings.bool(forKey: SettingValues.pref_saveButton)
        SettingValues.hideButton = settings.bool(forKey: SettingValues.pref_hideButton)

        SettingValues.largerThumbnail = settings.object(forKey: SettingValues.pref_largerThumbnail) == nil ? true : settings.bool(forKey: SettingValues.pref_largerThumbnail)
        SettingValues.bannerHidden = settings.bool(forKey: SettingValues.pref_bannerHidden)
        SettingValues.viewType = settings.bool(forKey: SettingValues.pref_viewType)
        SettingValues.centerLeadImage = settings.bool(forKey: SettingValues.pref_centerLead)
        SettingValues.abbreviateScores = settings.bool(forKey: SettingValues.pref_abbreviateScores)
        SettingValues.scoreInTitle = settings.bool(forKey: SettingValues.pref_scoreInTitle)
        SettingValues.hideButtonActionbar = settings.bool(forKey: SettingValues.pref_hideButtonActionbar)
        SettingValues.postViewMode = PostViewType.init(rawValue: settings.string(forKey: SettingValues.pref_postViewMode) ?? "card")!
        SettingValues.fabType = FabType.init(rawValue: settings.string(forKey: SettingValues.pref_fabType) ?? "hide")!

        SettingValues.internalImage = settings.object(forKey: SettingValues.pref_internalImage) == nil ? true : settings.bool(forKey: SettingValues.pref_internalImage)
        SettingValues.internalGif = settings.object(forKey: SettingValues.pref_internalGif) == nil ? true : settings.bool(forKey: SettingValues.pref_internalGif)
        SettingValues.internalAlbum = settings.object(forKey: SettingValues.pref_internalAlbum) == nil ? true : settings.bool(forKey: SettingValues.pref_internalAlbum)
        SettingValues.internalYouTube = settings.object(forKey: SettingValues.pref_internalYouTube) == nil ? true : settings.bool(forKey: SettingValues.pref_internalYouTube)

    }

    public static func doneVersion() -> Bool {
        let settings = UserDefaults.standard
        return settings.object(forKey: Bundle.main.releaseVersionNumber!) != nil
    }

    public static func showVersionDialog(_ title: String, _ permalink: String, parentVC: UIViewController){
        let settings = UserDefaults.standard
        settings.set(true, forKey: Bundle.main.releaseVersionNumber!)
        settings.set(title, forKey: "vtitle")
        settings.set(permalink, forKey: "vlink")
        settings.synchronize()
        let message = MDCSnackbarMessage.init(text: title)
        let action = MDCSnackbarMessageAction()
        let actionHandler = { () in
            VCPresenter.openRedditLink(permalink, parentVC.navigationController, parentVC)
        }
        action.handler = actionHandler
        action.title = "CHANGELOG"

        message.action = action
        MDCSnackbarManager.show(message)

    }

    public enum FabType: String {

        public static let cases: [FabType] = [.HIDE_READ, .SHADOWBOX, .NEW_POST, .SIDEBAR, .GALLERY]

        case HIDE_READ = "hide"
        case SHADOWBOX = "shadowbox"
        case NEW_POST = "newpost"
        case SIDEBAR = "sidebar"
        case GALLERY = "gallery"

        func getPhoto() -> String {
            switch (self) {
            case .HIDE_READ:
                return "hide"
            case .NEW_POST:
                return "edit"
            case .SHADOWBOX:
                return "shadowbox"
            case .SIDEBAR:
                return "info"
            case .GALLERY:
                return "image"
            }
        }

        func getTitle() -> String {
            switch (self){
            case .HIDE_READ:
                return "Hide read"
            case .NEW_POST:
                return "New submission"
            case .SHADOWBOX:
                return "Shadowbox"
            case .SIDEBAR:
                return "Sidebar"
            case .GALLERY:
                 return "Gallery"
            }
        }

    }

}
