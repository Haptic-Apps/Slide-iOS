//
//  SettingValues.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/9/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

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
    public static let pref_largerThumbnail = "LARGER_THUMBNAIL"
    public static let pref_scoreInTitle = "SCORE_IN_TITLE"
    public static let pref_commentsInTitle = "COMMENTS_IN_TITLE"
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
    public static let pref_readLaterButton = "READ_LATER_BUTTON"
    public static let pref_internalYouTube = "INTERNAL_YOUTUBE"
    public static let pref_showFirstParagraph = "FIRST_P"
    public static let pref_swapLongPress = "SWAP_LONG_PRESS"
    public static let pref_collapseFully = "COLLAPSE_FULLY"
    public static let pref_highlightOp = "HIGHLIGHT_OP"
    public static let pref_smallTag = "SMALLER_TAG"
    public static let pref_biometrics = "BIOMETRICS"
    public static let pref_safariVC = "SAFARIVC"
    public static let pref_fabType = "FABTYPE"
    public static let pref_nightStartH = "NIGHTSH"
    public static let pref_nightStartM = "NIGHTSM"
    public static let pref_nightEndH = "NIGHTEH"
    public static let pref_nightEndM = "NIGHTEM"
    public static let pref_nightTheme = "NIGHTTHEME"
    public static let pref_nightMode = "NIGHT_ENABLED"
    public static let pref_nightModeFilter = "NIGHT_FILTER"
    public static let pref_multiColumnCount = "MULTICOLUMN_COUNT"
    public static let pref_nameScrubbing = "NAME_SCRUBBING"
    public static let pref_autoCache = "AUTO_CACHE"
    public static let pref_pro = "RELEASE_PRO_ENABLED"
    public static let pref_pinToolbar = "PIN_TOOLBAR"
    public static let pref_commentActionRightLeft = "COMMENT_LEFT"
    public static let pref_commentActionRightRight = "COMMENT_RIGHT"
    public static let pref_commentActionLeftLeft = "COMMENT_LEFT_LEFT"
    public static let pref_commentActionLeftRight = "COMMENT_RIGHT_LEFT"
    public static let pref_commentActionDoubleTap = "COMMENT_DOUBLE_TAP"
    public static let pref_submissionActionDoubleTap = "SUBMISSION_DOUBLE_TAP"
    public static let pref_commentFullScreen = "COMMENT_FULLSCREEN"
    public static let pref_hapticFeedback = "HAPTIC_FEEDBACK"
    public static let pref_postImageMode = "POST_IMAGE_MODE"
    public static let pref_linkAlwaysThumbnail = "LINK_ALWAYS_THUMBNAIL"
    public static let pref_actionbarMode = "ACTIONBAR_MODE"
    public static let pref_flatMode = "FLAT_MODE"
    public static let pref_bottomBarHidden = "BOTTOM_BAR_HIDDEN"
    public static let pref_widerIndicators = "WIDE_INDICATORS"
    public static let pref_blackShadowbox = "BLACK_SHADOWBOX"
    public static let pref_hideAutomod = "HIDE_AUTOMOD"
    public static let pref_commentGesturesEnabled = "COMMENT_GESTURES"
    public static let pref_submissionGesturesEnabled = "SUBMISSIONS_GESTURES"
    public static let pref_autoKeyboard = "AUTO_KEYBOARD"
    public static let pref_reduceColor = "REDUCE_COLORS"
    public static let pref_browser = "WEB_BROWSER"
    public static let pref_infoBelowTitle = "INFO_BELOW_TITLE"
    public static let pref_matchSilence = "MATCH_SILENCE"
    public static let pref_autoPlayMode = "AUTOPLAY_MODE"
    public static let pref_showPages = "SHOW_PAGES"
    public static let pref_submissionActionLeft = "SUBMISSION_LEFT"
    public static let pref_submissionActionRight = "SUBMISSION_RIGHT"
    public static let pref_commentGesturesMode = "COMMENT_GESTURE_MODE"
    public static let pref_notifications = "NOTIFICATIONS"
    public static let pref_subBar = "SUB_BAR"
    public static let pref_appMode = "APP_MODE"

    public static let BROWSER_INTERNAL = "internal"
    public static let BROWSER_SAFARI_INTERNAL_READABILITY = "readability"
    public static let BROWSER_FIREFOX = "firefox"
    public static let BROWSER_SAFARI = "safari"
    public static let BROWSER_SAFARI_INTERNAL = "safariinternal"
    public static let BROWSER_CHROME = "chrome"
    public static let BROWSER_OPERA = "opera"
    public static let BROWSER_FOCUS = "focus"

    public static var commentActionRightRight = CommentAction.UPVOTE
    public static var commentActionRightLeft = CommentAction.DOWNVOTE
    public static var commentActionLeftRight = CommentAction.MENU
    public static var commentActionLeftLeft = CommentAction.COLLAPSE
    public static var commentActionDoubleTap = CommentAction.NONE
    public static var submissionActionDoubleTap = SubmissionAction.NONE
    public static var submissionActionLeft = SubmissionAction.UPVOTE
    public static var submissionActionRight = SubmissionAction.SAVE
    public static var commentGesturesMode = CommentGesturesMode.NONE

    public static var browser = "firefox"
    public static var subredditBar = true
    public static var hiddenFAB = true
    public static var upvotePercentage = true
    public static var defaultSorting = LinkSortType.hot
    public static var defaultTimePeriod = TimeFilterWithin.day
    public static var defaultCommentSorting = CommentSort.confidence
    public static var tintingMode = "TINTING_MODE"
    public static var onlyTintOutside = false
    public static var postViewMode = PostViewType.LIST
    public static var postImageMode = PostImageMode.CROPPED_IMAGE
    public static var actionBarMode = ActionBarMode.FULL
    public static var autoPlayMode = AutoPlay.ALWAYS
    public static var flatMode = false
    public static var fabType = FabType.HIDE_READ
    public static var pictureMode = "PICTURE_MODE"
    public static var hideImageSelftext = false
    public static var abbreviateScores = true
    public static var commentCountLastVisit = true
    public static var rightThumbnail = true
    public static var multiColumnCount = 2
    public static var nameScrubbing = true
    public static var autoCache = false
    public static var pinToolbar = false
    public static var hapticFeedback = true
    public static var wideIndicators = false
    public static var blackShadowbox = false
    public static var hideAutomod = false
    public static var submissionGesturesEnabled = false
    public static var infoBelowTitle = false
    public static var matchSilence = true
    public static var showPages = true

    public static var enlargeLinks = true
    public static var noImages = false
    public static var showLinkContentType = true
    public static var internalGifView = true
    public static var scoreInTitle = false
    public static var commentsInTitle = false
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
    public static var isPro = true
    public static var lqLow = true
    public static var nsfwEnabled = false
    public static var reduceColor = true
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
    public static var readLaterButton = true
    public static var internalYouTube = true
    public static var showFirstParagraph = true
    public static var swapLongPress = false
    public static var collapseFully = true
    public static var highlightOp = true
    public static var notifications = true
    public static var smallerTag = true
    public static var biometrics = true
    public static var nightStart = 1
    public static var nightStartMin = 0
    public static var nightEnd = 5
    public static var nightEndMin = 0
    public static var nightModeEnabled = false
    public static var nightModeFilter = false
    public static var nightTheme = ColorUtil.Theme.DARK
    public static var commentFullScreen = true
    public static var linkAlwaysThumbnail = false
    public static var autoKeyboard = true
    public static var appMode = AppMode.SINGLE

    enum PostViewType: String {
        case LIST = "list"
        case COMPACT = "compact"
        case CARD = "card"
        case CENTER = "center"
    }
    
    enum PostImageMode: String {
        case FULL_IMAGE = "full"
        case CROPPED_IMAGE = "cropped"
        case THUMBNAIL = "thumbnail"
        //for future implementation case NONE = "none"
    }

    enum ActionBarMode: String {
        case NONE = "none"
        case FULL = "full"
        case SIDE = "side"
        case SIDE_RIGHT = "right"
        
        func isSide() -> Bool {
            return self == .SIDE || self == .SIDE_RIGHT
        }
    }

    enum AutoPlay: String {
        static let cases: [AutoPlay] = [.ALWAYS, .WIFI, .TAP, .NEVER]

        case NEVER = "never"
        case WIFI = "wifi_only"
        case ALWAYS = "always"
        case TAP = "tap"
        
        func description() -> String {
            switch self {
            case .NEVER:
                return "Never autoplay videos"
            case .ALWAYS:
                return "Always autoplay videos"
            case .WIFI:
                return "Autoplay only on WiFi"
            case .TAP:
                return "Play videos on tap"
            }
        }
    }
    
    enum CommentGesturesMode: String {
        static let cases: [CommentGesturesMode] = [.GESTURES, .NONE, .SWIPE_ANYWHERE]
        
        case GESTURES = "gestures"
        case NONE = "none"
        case SWIPE_ANYWHERE = "swipe_anywhere"

        func description() -> String {
            switch self {
            case .GESTURES:
                return "Swipe gestures"
            case .NONE:
                return "Slide between posts"
            case .SWIPE_ANYWHERE:
                return "Swipe anywhere to exit"
            }
        }
    }
    
    public static func shouldAutoPlay() -> Bool {
        switch SettingValues.autoPlayMode {
        case .ALWAYS:
            return true
        case .WIFI:
            return LinkCellView.checkWiFi()
        case .NEVER:
            return false
        case .TAP:
            return true
        }
    }

    public static func getLinkSorting(forSubreddit: String) -> LinkSortType {
        if let sorting = UserDefaults.standard.string(forKey: forSubreddit.lowercased() + "Sorting") {
            for s in LinkSortType.cases {
                if s.path == sorting {
                    return s
                }
            }
        }
        return defaultSorting
    }

    public static func getTimePeriod(forSubreddit: String) -> TimeFilterWithin {
        if let time = UserDefaults.standard.string(forKey: forSubreddit.lowercased() + "Time") {
            for t in TimeFilterWithin.cases {
                if t.param == time {
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
        let pad = UIDevice.current.userInterfaceIdiom == .pad
        let settings = UserDefaults.standard
        SettingValues.saveNSFWHistory = settings.bool(forKey: SettingValues.pref_saveNSFWHistory)
        SettingValues.reduceColor = settings.bool(forKey: SettingValues.pref_reduceColor)
        SettingValues.saveHistory = settings.object(forKey: SettingValues.pref_saveHistory) == nil ? true : settings.bool(forKey: SettingValues.pref_saveHistory)
        
        var columns = Int(round(UIApplication.shared.statusBarView!.frame.size.width / CGFloat(320)))
        if columns == 0 {
            columns = 1
        }
        SettingValues.multiColumnCount = settings.object(forKey: SettingValues.pref_multiColumnCount) == nil ? columns : settings.integer(forKey: SettingValues.pref_multiColumnCount)
        SettingValues.highlightOp = settings.object(forKey: SettingValues.pref_highlightOp) == nil ? true : settings.bool(forKey: SettingValues.pref_highlightOp)

        var basePath = settings.string(forKey: SettingValues.pref_defaultSorting)
        for sort in LinkSortType.cases {
            if sort.path == basePath {
                SettingValues.defaultSorting = sort
                break
            }
        }

        SettingValues.hapticFeedback = settings.object(forKey: SettingValues.pref_hapticFeedback) == nil ? true : settings.bool(forKey: SettingValues.pref_hapticFeedback)
        SettingValues.submissionGesturesEnabled = settings.object(forKey: SettingValues.pref_submissionGesturesEnabled) == nil ? false : settings.bool(forKey: SettingValues.pref_submissionGesturesEnabled)

        basePath = settings.string(forKey: SettingValues.pref_defaultTimePeriod)
        for time in TimeFilterWithin.cases {
            if time.param == basePath {
                SettingValues.defaultTimePeriod = time
                break
            }
        }

        SettingValues.postFontOffset = settings.object(forKey: SettingValues.pref_postFontSize) == nil ? -2 : settings.integer(forKey: SettingValues.pref_postFontSize)
        SettingValues.commentFontOffset = settings.object(forKey: SettingValues.pref_commentFontSize) == nil ? -2 : settings.integer(forKey: SettingValues.pref_commentFontSize)

        if let time = UserDefaults.standard.string(forKey: pref_defaultTimePeriod) {
            for t in TimeFilterWithin.cases {
                if t.param == time {
                    defaultTimePeriod = t
                    break
                }
            }
        }

        if let sort = UserDefaults.standard.string(forKey: pref_defaultTimePeriod) {
            for t in LinkSortType.cases {
                if t.path == sort {
                    defaultSorting = t
                    break
                }
            }
        }

        if let sort = UserDefaults.standard.string(forKey: pref_defaultCommentSorting) {
            for t in CommentSort.cases {
                if t.path == sort {
                    defaultCommentSorting = t
                    break
                }
            }
        }

        SettingValues.smallerTag = settings.object(forKey: SettingValues.pref_smallTag) == nil ? true : settings.bool(forKey: SettingValues.pref_smallTag)
        SettingValues.blackShadowbox = settings.bool(forKey: SettingValues.pref_blackShadowbox)
        SettingValues.markReadOnScroll = settings.bool(forKey: SettingValues.pref_markReadOnScroll)
        SettingValues.swapLongPress = settings.bool(forKey: SettingValues.pref_swapLongPress)
        SettingValues.domainInInfo = settings.bool(forKey: SettingValues.pref_domainInInfo)
        SettingValues.notifications = settings.bool(forKey: SettingValues.pref_notifications)
        SettingValues.showFirstParagraph = settings.object(forKey: SettingValues.pref_showFirstParagraph) == nil ? true : settings.bool(forKey: SettingValues.pref_showFirstParagraph)
        SettingValues.disableNavigationBar = settings.bool(forKey: SettingValues.pref_disableNavigationBar)
        SettingValues.disableColor = settings.bool(forKey: SettingValues.pref_disableColor)
        SettingValues.collapseDefault = settings.bool(forKey: SettingValues.pref_collapseDefault)
        SettingValues.volumeButtonNavigation = settings.bool(forKey: SettingValues.pref_volumeButtonNavigation)
        SettingValues.collapseFully = settings.bool(forKey: SettingValues.pref_collapseFully)
        SettingValues.autoCache = settings.bool(forKey: SettingValues.pref_autoCache)
        SettingValues.wideIndicators = settings.bool(forKey: SettingValues.pref_widerIndicators)
        SettingValues.leftThumbnail = settings.bool(forKey: SettingValues.pref_leftThumbnail)
        SettingValues.hideAutomod = settings.bool(forKey: SettingValues.pref_hideAutomod)
        SettingValues.biometrics = settings.bool(forKey: SettingValues.pref_biometrics)
        SettingValues.enlargeLinks = settings.object(forKey: SettingValues.pref_enlargeLinks) == nil ? true : settings.bool(forKey: SettingValues.pref_enlargeLinks)
        SettingValues.commentFullScreen = settings.object(forKey: SettingValues.pref_commentFullScreen) == nil ? true : settings.bool(forKey: SettingValues.pref_commentFullScreen)
        SettingValues.showLinkContentType = settings.object(forKey: SettingValues.pref_showLinkContentType) == nil ? true : settings.bool(forKey: SettingValues.pref_showLinkContentType)
        SettingValues.nameScrubbing = settings.bool(forKey: SettingValues.pref_nameScrubbing)
        SettingValues.hiddenFAB = settings.bool(forKey: SettingValues.pref_hiddenFAB)
        SettingValues.isPro = settings.bool(forKey: SettingValues.pref_pro)
        SettingValues.pinToolbar = settings.bool(forKey: SettingValues.pref_pinToolbar)
        SettingValues.autoKeyboard = settings.object(forKey: SettingValues.pref_autoKeyboard) == nil ? true : settings.bool(forKey: SettingValues.pref_autoKeyboard)
        SettingValues.linkAlwaysThumbnail = settings.object(forKey: SettingValues.pref_linkAlwaysThumbnail) == nil ? true : settings.bool(forKey: SettingValues.pref_linkAlwaysThumbnail)
        SettingValues.showPages = settings.bool(forKey: SettingValues.pref_showPages)

        SettingValues.dataSavingEnabled = settings.bool(forKey: SettingValues.pref_dataSavingEnabled)
        SettingValues.dataSavingDisableWiFi = settings.bool(forKey: SettingValues.pref_dataSavingDisableWifi)
        SettingValues.loadContentHQ = settings.bool(forKey: SettingValues.pref_loadContentHQ)
        SettingValues.noImages = settings.bool(forKey: SettingValues.pref_noImg)
        SettingValues.lqLow = false //deprecate this settings.bool(forKey: SettingValues.pref_lqLow)
        SettingValues.saveButton = settings.object(forKey: SettingValues.pref_saveButton) == nil ? true : settings.bool(forKey: SettingValues.pref_saveButton)
        SettingValues.readLaterButton = settings.object(forKey: SettingValues.pref_readLaterButton) == nil ? true : settings.bool(forKey: SettingValues.pref_readLaterButton)
        SettingValues.hideButton = settings.bool(forKey: SettingValues.pref_hideButton)
        SettingValues.nightModeEnabled = settings.bool(forKey: SettingValues.pref_nightMode)
        SettingValues.nightStart = settings.object(forKey: SettingValues.pref_nightStartH) == nil ? 9 : settings.integer(forKey: SettingValues.pref_nightStartH)
        SettingValues.nightStartMin = settings.object(forKey: SettingValues.pref_nightStartH) == nil ? 0 : settings.integer(forKey: SettingValues.pref_nightStartM)
        SettingValues.nightEnd = settings.object(forKey: SettingValues.pref_nightStartH) == nil ? 5 : settings.integer(forKey: SettingValues.pref_nightEndH)
        SettingValues.nightEndMin = settings.object(forKey: SettingValues.pref_nightStartH) == nil ? 0 : settings.integer(forKey: SettingValues.pref_nightEndM)
        if let name = UserDefaults.standard.string(forKey: SettingValues.pref_nightTheme) {
            if let t = ColorUtil.Theme(rawValue: name) {
                SettingValues.nightTheme = t
            }
        }

        SettingValues.largerThumbnail = settings.object(forKey: SettingValues.pref_largerThumbnail) == nil ? true : settings.bool(forKey: SettingValues.pref_largerThumbnail)
        SettingValues.subredditBar = settings.bool(forKey: SettingValues.pref_subBar)
        SettingValues.matchSilence = settings.object(forKey: SettingValues.pref_matchSilence) == nil ? true : settings.bool(forKey: SettingValues.pref_matchSilence)
        SettingValues.infoBelowTitle = settings.bool(forKey: SettingValues.pref_infoBelowTitle)
        SettingValues.abbreviateScores = settings.object(forKey: SettingValues.pref_abbreviateScores) == nil ? true : settings.bool(forKey: SettingValues.pref_abbreviateScores)
        SettingValues.scoreInTitle = settings.bool(forKey: SettingValues.pref_scoreInTitle)
        SettingValues.commentsInTitle = settings.bool(forKey: SettingValues.pref_commentsInTitle)
        SettingValues.appMode = AppMode.init(rawValue: settings.string(forKey: SettingValues.pref_appMode) ?? (pad ? "split" : "single")) ?? (pad ? .SPLIT : .SINGLE)

        SettingValues.postViewMode = PostViewType.init(rawValue: settings.string(forKey: SettingValues.pref_postViewMode) ?? "card") ?? .CARD
        SettingValues.actionBarMode = ActionBarMode.init(rawValue: settings.string(forKey: SettingValues.pref_actionbarMode) ?? "full") ?? .FULL
        SettingValues.autoPlayMode = AutoPlay.init(rawValue: settings.string(forKey: SettingValues.pref_autoPlayMode) ?? "always") ?? .ALWAYS
        SettingValues.browser = settings.string(forKey: SettingValues.pref_browser) ?? SettingValues.BROWSER_INTERNAL
        SettingValues.flatMode = settings.bool(forKey: SettingValues.pref_flatMode)
        SettingValues.postImageMode = PostImageMode.init(rawValue: settings.string(forKey: SettingValues.pref_postImageMode) ?? "full") ?? .CROPPED_IMAGE
        SettingValues.fabType = FabType.init(rawValue: settings.string(forKey: SettingValues.pref_fabType) ?? "hide") ?? .HIDE_READ
        SettingValues.commentGesturesMode = CommentGesturesMode.init(rawValue: settings.string(forKey: SettingValues.pref_commentGesturesMode) ?? "swipe_anywhere") ?? .SWIPE_ANYWHERE
        SettingValues.commentActionRightLeft = CommentAction.init(rawValue: settings.string(forKey: SettingValues.pref_commentActionRightLeft) ?? "downvote") ?? .DOWNVOTE
        SettingValues.commentActionRightRight = CommentAction.init(rawValue: settings.string(forKey: SettingValues.pref_commentActionRightRight) ?? "upvote") ?? .UPVOTE
        SettingValues.commentActionLeftLeft = CommentAction.init(rawValue: settings.string(forKey: SettingValues.pref_commentActionLeftLeft) ?? "collapse") ?? .COLLAPSE
        SettingValues.commentActionLeftRight = CommentAction.init(rawValue: settings.string(forKey: SettingValues.pref_commentActionLeftRight) ?? "menu") ?? .MENU

        SettingValues.commentActionDoubleTap = CommentAction.init(rawValue: settings.string(forKey: SettingValues.pref_commentActionDoubleTap) ?? "none") ?? .NONE
        SettingValues.submissionActionDoubleTap = SubmissionAction.init(rawValue: settings.string(forKey: SettingValues.pref_submissionActionDoubleTap) ?? "none") ?? .NONE
        SettingValues.submissionActionRight = SubmissionAction.init(rawValue: settings.string(forKey: SettingValues.pref_submissionActionRight) ?? "upvote") ?? .UPVOTE
        SettingValues.submissionActionLeft = SubmissionAction.init(rawValue: settings.string(forKey: SettingValues.pref_submissionActionLeft) ?? "downvote") ?? .DOWNVOTE

        SettingValues.internalImageView = settings.object(forKey: SettingValues.pref_internalImageView) == nil ? true : settings.bool(forKey: SettingValues.pref_internalImageView)
        SettingValues.internalGifView = settings.object(forKey: SettingValues.pref_internalGifView) == nil ? true : settings.bool(forKey: SettingValues.pref_internalGifView)
        SettingValues.internalAlbumView = settings.object(forKey: SettingValues.pref_internalAlbumView) == nil ? true : settings.bool(forKey: SettingValues.pref_internalAlbumView)
        SettingValues.internalYouTube = settings.object(forKey: SettingValues.pref_internalYouTube) == nil ? true : settings.bool(forKey: SettingValues.pref_internalYouTube)

    }

    public static func doneVersion() -> Bool {
        let settings = UserDefaults.standard
        return settings.object(forKey: Bundle.main.releaseVersionNumber!) != nil
    }

    public static func firstEnter() -> Bool {
        let settings = UserDefaults.standard
        return settings.object(forKey: "USEDONCE") != nil
    }

    public static func showVersionDialog(_ title: String, _ permalink: String, parentVC: UIViewController) {
        let settings = UserDefaults.standard
        settings.set(true, forKey: Bundle.main.releaseVersionNumber!)
        settings.set(title, forKey: "vtitle")
        settings.set(permalink, forKey: "vlink")
        settings.synchronize()
        let finalTitle = title + "\nTap to view Changelog"
        
        BannerUtil.makeBanner(text: finalTitle, color: GMColor.green500Color(), seconds: 7, context: parentVC, top: true, callback: {
            VCPresenter.openRedditLink(permalink, parentVC.navigationController, parentVC)
        })
    }
    
    public enum CommentAction: String {
        public static let cases: [CommentAction] = [.UPVOTE, .DOWNVOTE, .MENU, .COLLAPSE, .SAVE, .REPLY, .EXIT, .NEXT, .NONE]
        
        case UPVOTE = "upvote"
        case DOWNVOTE = "downvote"
        case MENU = "menu"
        case COLLAPSE = "collapse"
        case SAVE = "save"
        case NONE = "none"
        case REPLY = "reply"
        case NEXT = "next"
        case EXIT = "exit"
        
        func getTitle() -> String {
            switch self {
            case .COLLAPSE :
                return "Collapse parent"
            case .UPVOTE:
                return "Upvote"
            case .DOWNVOTE:
                return "Downvote"
            case .SAVE:
                return "Save"
            case .MENU:
                return "Comment menu"
            case .NONE:
                return "Disabled"
            case .REPLY:
                return "Reply"
            case .EXIT:
                return "Close comments"
            case .NEXT:
                return "Next comment page"
            }
        }
        
        func getPhoto() -> String {
            switch self {
            case .COLLAPSE :
                return "down"
            case .UPVOTE:
                return "upvote"
            case .DOWNVOTE:
                return "downvote"
            case .SAVE:
                return "save"
            case .MENU:
                return "moreh"
            case .NONE:
                return "close"
            case .REPLY:
                return "reply"
            case .EXIT:
                return "back"
            case .NEXT:
                return "next"
            }
        }
        
        func getColor() -> UIColor {
            switch self {
            case .COLLAPSE :
                return ColorUtil.baseAccent
            case .UPVOTE:
                return ColorUtil.upvoteColor
            case .DOWNVOTE:
                return ColorUtil.downvoteColor
            case .SAVE:
                return GMColor.yellow500Color()
            case .MENU:
                return ColorUtil.baseAccent
            case .NONE:
                return GMColor.red500Color()
            case .REPLY:
                return GMColor.green500Color()
            case .EXIT:
                return ColorUtil.baseAccent
            case .NEXT:
                return ColorUtil.baseAccent
            }
        }
    }

    public enum SubmissionAction: String {
        public static let cases: [SubmissionAction] = [.UPVOTE, .DOWNVOTE, .MENU, .HIDE, .SAVE, .READ_LATER, .SUBREDDIT, .SHARE, .AUTHOR, .EXTERNAL, .NONE]
        
        case UPVOTE = "upvote"
        case DOWNVOTE = "downvote"
        case MENU = "menu"
        case HIDE = "hide"
        case SAVE = "save"
        case NONE = "none"
        case SUBREDDIT = "sub"
        case SHARE = "share"
        case AUTHOR = "author"
        case EXTERNAL = "external"
        case READ_LATER = "readlater"
        
        func getTitle() -> String {
            switch self {
            case .HIDE :
                return "Hide post"
            case .UPVOTE:
                return "Upvote"
            case .DOWNVOTE:
                return "Downvote"
            case .SAVE:
                return "Save"
            case .MENU:
                return "Submission menu"
            case .NONE:
                return "Disabled"
            case .SUBREDDIT:
                return "Visit subreddit"
            case .AUTHOR:
                return "Visit author profile"
            case .EXTERNAL:
                return "Open submission link externally"
            case .SHARE:
                return "Share submission link"
            case .READ_LATER:
                return "Add to Read Later list"
            }
        }
        
        func getPhoto() -> String {
            switch self {
            case .HIDE :
                return "hide"
            case .UPVOTE:
                return "upvote"
            case .DOWNVOTE:
                return "downvote"
            case .SAVE:
                return "save"
            case .MENU:
                return "moreh"
            case .NONE:
                return "close"
            case .SUBREDDIT:
                return "subs"
            case .AUTHOR:
                return "profile"
            case .EXTERNAL:
                return "world"
            case .SHARE:
                return "share"
            case .READ_LATER:
                return "history"
            }
        }
        
        func getColor() -> UIColor {
            switch self {
            case .HIDE :
                return .black
            case .UPVOTE:
                return ColorUtil.upvoteColor
            case .DOWNVOTE:
                return ColorUtil.downvoteColor
            case .SAVE:
                return GMColor.yellow500Color()
            case .MENU:
                return ColorUtil.baseAccent
            case .NONE:
                return GMColor.red500Color()
            case .SUBREDDIT:
                return GMColor.green500Color()
            case .EXTERNAL:
                return GMColor.green500Color()
            case .AUTHOR:
                return GMColor.blue500Color()
            case .SHARE:
                return GMColor.lightGreen500Color()
            case .READ_LATER:
                return GMColor.green500Color()
            }
        }
    }

    public enum FabType: String {

        public static let cases: [FabType] = [.HIDE_READ, .SHADOWBOX, .NEW_POST, .SIDEBAR, .RELOAD, .SEARCH]

        case HIDE_READ = "hide"
        case SHADOWBOX = "shadowbox"
        case NEW_POST = "newpost"
        case SIDEBAR = "sidebar"
        case GALLERY = "gallery"
        case SEARCH = "search"
        case RELOAD = "reload"

        func getPhoto() -> String {
            switch self {
            case .HIDE_READ:
                return "hide"
            case .NEW_POST:
                return "edit"
            case .SHADOWBOX:
                return "shadowbox"
            case .SIDEBAR:
                return "info"
            case .RELOAD:
                return "sync"
            case .GALLERY:
                return "image"
            case .SEARCH:
                return "search"
            }
        }

        func getTitle() -> String {
            switch self {
            case .HIDE_READ:
                return "Hide read"
            case .NEW_POST:
                return "New submission"
            case .SHADOWBOX:
                return "Shadowbox"
            case .SIDEBAR:
                return "Sidebar"
            case .RELOAD:
                return "Reload"
            case .GALLERY:
                 return "Gallery"
            case .SEARCH:
                return "Search"
            }
        }

    }

    public enum AppMode: String {
        
        public static let cases: [AppMode] = [.SPLIT, .SINGLE, .MULTI_COLUMN]
        
        case SPLIT = "split"
        case SINGLE = "single"
        case MULTI_COLUMN = "multi"
        
        func getTitle() -> String {
            switch self {
            case .SPLIT:
                return "Split view mode"
            case .SINGLE:
                return "Single list"
            case .MULTI_COLUMN:
                return "Multi-column mode"
            }
        }
        
        func getDescription() -> String {
            switch self {
            case .SPLIT:
                return "Displays submissions on the left and comments on the right (requires an iPad)"
            case .SINGLE:
                return "Single column display of submissions"
            case .MULTI_COLUMN:
                return "Multiple column display of submissions (requires Pro)"
            }
        }

    }

}
