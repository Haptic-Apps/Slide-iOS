//
//  SettingValues.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/9/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import AVFoundation
import Foundation
import reddift

class SettingValues {

    public static let pref_viewType = "VIEW_TYPE"
    public static let pref_hiddenFAB = "HIDDEN_FAB"
    public static let pref_defaultSorting = "DEFAULT_SORT"
    public static let pref_defaultSearchSort = "DEFAULT_SORT_SEARCH"
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
    public static let pref_galleryCount = "GALLERY_COUNT"
    public static let pref_nameScrubbing = "NAME_SCRUBBING"
    public static let pref_autoCache = "AUTO_CACHE"
    public static let pref_pro = "RELEASE_PRO_ENABLED"
    public static let pref_pinToolbar = "PIN_TOOLBAR"
    public static let pref_commentActionRightLeft = "COMMENT_LEFT"
    public static let pref_commentActionRightRight = "COMMENT_RIGHT"
    public static let pref_commentActionLeftLeft = "COMMENT_LEFT_LEFT"
    public static let pref_commentActionLeftRight = "COMMENT_RIGHT_LEFT"
    public static let pref_commentActionDoubleTap = "COMMENT_DOUBLE_TAP"
    public static let pref_commentActionForceTouch = "COMMENT_FORCE_TOUCH"
    public static let pref_submissionActionDoubleTap = "SUBMISSION_DOUBLE_TAP"
    public static let pref_commentFullScreen = "COMMENT_FULLSCREEN"
    public static let pref_hapticFeedback = "HAPTIC_FEEDBACK"
    public static let pref_postImageMode = "POST_IMAGE_MODE"
    public static let pref_linkAlwaysThumbnail = "LINK_ALWAYS_THUMBNAIL"
    public static let pref_actionbarMode = "ACTIONBAR_MODE"
    public static let pref_flatMode = "FLAT_MODE"
    public static let pref_reduceElevation = "REDUCE_ELEVATION"
    public static let pref_bottomBarHidden = "BOTTOM_BAR_HIDDEN"
    public static let pref_widerIndicators = "WIDE_INDICATORS"
    public static let pref_blackShadowbox = "BLACK_SHADOWBOX"
    public static let pref_hideAutomod = "HIDE_AUTOMOD"
    public static let pref_commentGesturesEnabled = "COMMENT_GESTURES"
    public static let pref_submissionGesturesMode = "SUBMISSION_GESTURE_MODE_2"
    public static let pref_autoKeyboard = "AUTO_KEYBOARD"
    public static let pref_reduceColor = "REDUCE_COLORS"
    public static let pref_browser = "WEB_BROWSER"
    public static let pref_infoBelowTitle = "INFO_BELOW_TITLE"
    public static let pref_matchSilence = "MATCH_SILENCE"
    public static let pref_autoPlayMode = "AUTOPLAY_MODE"
    public static let pref_showPages = "SHOW_PAGES"
    public static let pref_submissionActionLeft = "SUBMISSION_LEFT"
    public static let pref_submissionActionRight = "SUBMISSION_RIGHT"
    public static let pref_submissionActionForceTouch = "SUBMISSION_FORCE_TOUCH"
    public static let pref_commentGesturesMode = "COMMENT_GESTURE_MODE_2"
    public static let pref_notifications = "NOTIFICATIONS"
    public static let pref_subBar = "SUB_BAR"
    public static let pref_appMode = "APP_MODE"
    public static let pref_moreButton = "MORE_BUTTON"
    public static let pref_disableBanner = "DISABLE_BANNER"
    public static let pref_newIndicator = "NEW_INDICATOR"
    public static let pref_totallyCollapse = "TOTALLY_COLLAPSE"
    public static let pref_fullyHideNavbar = "FULLY_HIDE_NAVBAR"
    public static let pref_typeInTitle = "TYPE_IN_TITLE"
    public static let pref_muteYouTube = "MUTE_YOU_TUBE"
    public static let pref_commentJumpMode = "COMMENT_JUMP_MODE"
    public static let pref_alwaysShowHeader = "ALWAYS_SHOW_HEADER"
    public static let pref_disablePreviews = "DISABLE_PREVIEWS"
    public static let pref_commentDepth = "MAX_COMMENT_DEPTH"
    public static let pref_postsToCache = "POST_CACHE_COUNT"
    public static let pref_shareButton = "SHARE_BUTTON_ENABLED"
    public static let pref_hideSeen = "HIDE_SEEN"
    public static let pref_sideGesture = "SIDE_GESTURE"
    public static let pref_disable13Popup = "DISABLE_13_POPUP"
    public static let pref_thumbTag = "THUMB_TAG"
    public static let pref_commentLimit = "COMMENT_LIMIT"
    public static let pref_submissionLimit = "SUBMISSION_LIMIT"
    public static let pref_hideAwards = "HIDE_AWARDS_v2"
    public static let pref_subredditIcons = "SUBREDDIT_ICONS"
    public static let pref_streamVideos = "STREAM_VIDEOS"
    public static let pref_fullWidthHeaderCells = "FULL_WIDTH_HEADER_CELLS"
    public static let pref_disablePopupIpad = "DISABLE_POPUP_IPAD"
    public static let pref_disableMulticolumnCollections = "DISABLE_MULTICOLUMN_COLLECTIONS"
    public static let pref_disableSubredditPopupIpad = "DISABLE_SUB_POPUP_IPAD"
    public static let pref_portraitMultiColumnCount = "MULTICOLUMN_COUNT_PORTRAIT"
    public static let pref_gfycatAPI = "USE_GFYCAT_API"
    public static let pref_scrollSidebar = "SCROLL_SIDEBAR"
    public static let pref_imageFlairs = "IMAGE_FLAIRS"
    public static let pref_coloredFlairs = "COLORED_FLAIRS"
    public static let pref_showFlairs = "SHOW_FLAIRS"
    public static let pref_desktopMode = "DESKTOP_MODE"

    public static let BROWSER_INTERNAL = "internal"
    public static let BROWSER_SAFARI_INTERNAL_READABILITY = "readability"
    public static let BROWSER_FIREFOX = "firefox"
    public static let BROWSER_SAFARI = "safari"
    public static let BROWSER_SAFARI_INTERNAL = "safariinternal"
    public static let BROWSER_CHROME = "chrome"
    public static let BROWSER_OPERA = "opera"
    public static let BROWSER_FOCUS = "focus"
    public static let BROWSER_FOCUS_KLAR = "focusklar"
    public static let BROWSER_DDG = "duckduckgo"
    public static let BROWSER_BRAVE = "brave"

    public static var commentActionRightRight = CommentAction.UPVOTE
    public static var commentActionRightLeft = CommentAction.DOWNVOTE
    public static var commentActionLeftRight = CommentAction.MENU
    public static var commentActionLeftLeft = CommentAction.COLLAPSE
    public static var commentActionDoubleTap = CommentAction.NONE
    public static var commentActionForceTouch = CommentAction.MENU
    public static var submissionActionDoubleTap = SubmissionAction.NONE
    public static var submissionActionLeft = SubmissionAction.UPVOTE
    public static var submissionActionRight = SubmissionAction.SAVE
    public static var commentGesturesMode = CellGestureMode.NONE
    public static var submissionActionForceTouch = SubmissionAction.NONE

    public static var sideGesture = SideGesturesMode.NONE

    public static var browser = "firefox"
    public static var subredditBar = true
    public static var hideBottomBar = true
    public static var hideStatusBar = true
    public static var hiddenFAB = true
    public static var upvotePercentage = true
    public static var defaultSorting = LinkSortType.hot
    public static var defaultSearchSorting = SearchSortBy.top
    public static var defaultTimePeriod = TimeFilterWithin.day
    public static var defaultCommentSorting = CommentSort.suggested
    public static var tintingMode = "TINTING_MODE"
    public static var onlyTintOutside = false
    public static var postViewMode = PostViewType.LIST
    public static var postImageMode = PostImageMode.CROPPED_IMAGE
    public static var actionBarMode = ActionBarMode.FULL
    public static var autoPlayMode = AutoPlay.ALWAYS
    public static var flatMode = false
    public static var reduceElevation = false
    public static var fabType = FabType.HIDE_READ
    public static var pictureMode = "PICTURE_MODE"
    public static var hideImageSelftext = false
    public static var abbreviateScores = true
    public static var commentCountLastVisit = true
    public static var rightThumbnail = true
    public static var multiColumnCount = 2
    public static var portraitMultiColumnCount = 1
    public static var galleryCount = 2
    public static var nameScrubbing = true
    public static var muteYouTube = true
    public static var autoCache = false
    public static var dontHideTopBar = false
    public static var hapticFeedback = true
    public static var wideIndicators = false
    public static var blackShadowbox = false
    public static var hideAutomod = false
    public static var submissionGestureMode = CellGestureMode.NONE
    public static var infoBelowTitle = false
    public static var subredditIcons = false
   // public static var matchSilence = true
    public static var showPages = true
    public static var menuButton = true
    public static var shareButton = true
    public static var disableBanner = false
    public static var newIndicator = false
    public static var typeInTitle = true
    public static var scrollSidebar = false

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
    public static var cachedPostsCount = 25
    public static var commentDepth = 10
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
    public static var nightTheme = ""
    public static var commentFullScreen = true
    public static var linkAlwaysThumbnail = false
    public static var autoKeyboard = true
    public static var appMode = AppMode.SPLIT
    public static var commentJumpButton = CommentJumpMode.RIGHT
    public static var alwaysShowHeader = false
    public static var disablePreviews = false
    public static var hideSeen = true
    public static var disable13Popup = true
    public static var thumbTag = true
    public static var hideAwards = false
    public static var streamVideos = true
    public static var fullWidthHeaderCells = false
    public static var disablePopupIpad = false
    public static var disableMulticolumnCollections = false
    public static var disableSubredditPopupIpad = false
    public static var gfycatAPI = true
    public static var imageFlairs = false
    public static var coloredFlairs = false
    public static var showFlairs = true
    public static var desktopMode = false

    public static var commentLimit = 95
    public static var submissionLimit = 13

    enum PostViewType: String {
        case LIST = "list"
        case COMPACT = "compact"
        case CARD = "card"
        case CENTER = "center"
    }
    
    enum PostImageMode: String {
        case FULL_IMAGE = "full"
        case CROPPED_IMAGE = "cropped"
        case SHORT_IMAGE = "short"
        case THUMBNAIL = "thumbnail"
        case NONE = "none"
    }

    enum ActionBarMode: String {
        case NONE = "none"
        case FULL = "full"
        case FULL_LEFT = "left"
        case SIDE = "side"
        case SIDE_RIGHT = "right"
        
        func isSide() -> Bool {
            return self == .SIDE || self == .SIDE_RIGHT
        }
        
        func isFull() -> Bool {
            return self == .FULL || self == .FULL_LEFT
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

    enum CellGestureMode: String {
        static let cases: [CellGestureMode] = [.HALF, .HALF_FULL, .FULL, .NONE]
        
        case HALF = "half"
        case HALF_FULL = "half_full"
        case NONE = "none"
        case FULL = "full"

        func description() -> String {
            switch self {
            case .HALF:
                return "Right-side Gestures with paging"
            case .HALF_FULL:
                return "Right-side Gestures without paging (full width)"
            case .NONE:
                return "No Gestures"
            case .FULL:
                return "Full gestures without paging (full width)"
            }
        }
        
        func shouldPage() -> Bool {
            if self == .HALF_FULL || self == .FULL {
                return false
            }
            return true
        }
    }

    enum SideGesturesMode: String {
        static let cases: [SideGesturesMode] = [.SUBS, .POST, .SIDEBAR, .INBOX, .NONE]
        
        case SUBS = "subs"
        case POST = "post"
        case SIDEBAR = "sidebar"
        case NONE = "none"
        case INBOX = "inbox"

        func description() -> String {
            switch self {
            case .SUBS:
                return "Open subreddit drawer"
            case .POST:
                return "Submit a post to the current subreddit"
            case .INBOX:
                return "Opens your Inbox"
            case .SIDEBAR:
                return "Open the current subreddit sidebar"
            case .NONE:
                return "No side swipe gesture"
            }
        }
        
        func getPhoto() -> String {
            switch self {
            case .SUBS :
                return "subs"
            case .POST:
                return "edit"
            case .INBOX:
                return "inbox"
            case .SIDEBAR:
                return "info"
            case .NONE:
                return "close"
            }
        }
        
        func getColor() -> UIColor {
            switch self {
            case .SUBS :
                return GMColor.blue500Color()
            case .POST:
                return GMColor.green500Color()
            case .INBOX:
                return GMColor.lightBlue500Color()
            case .SIDEBAR:
                return GMColor.orange500Color()
            case .NONE:
                return GMColor.red500Color()
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
    
    public static func getCommentSorting(forSubreddit: String) -> CommentSort {
        if let sorting = UserDefaults.standard.string(forKey: forSubreddit.lowercased() + "CommentSorting") {
            for s in CommentSort.cases {
                if s.path == sorting {
                    return s
                }
            }
        }
        return defaultCommentSorting
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
        UserDefaults.standard.set(linkSorting.path, forKey: forSubreddit.lowercased() + "Sorting")
        UserDefaults.standard.set(timePeriod.param, forKey: forSubreddit.lowercased() + "Time")
        UserDefaults.standard.synchronize()
    }

    public static func setCommentSorting(forSubreddit: String, commentSorting: CommentSort) {
        UserDefaults.standard.set(commentSorting.path, forKey: forSubreddit.lowercased() + "CommentSorting")
        UserDefaults.standard.synchronize()
    }

    public static func initialize() {
        let pad = UIDevice.current.respectIpadLayout()
        let settings = UserDefaults.standard
        SettingValues.saveNSFWHistory = settings.bool(forKey: SettingValues.pref_saveNSFWHistory)
        SettingValues.reduceColor = settings.object(forKey: SettingValues.pref_reduceColor) == nil ? true : settings.bool(forKey: SettingValues.pref_reduceColor)
        SettingValues.saveHistory = settings.object(forKey: SettingValues.pref_saveHistory) == nil ? true : settings.bool(forKey: SettingValues.pref_saveHistory)
        
        var columns = 2 // TODO - Maybe calculate per device?
        if UIDevice.current.isMac() {
            columns = 1
        }
        SettingValues.multiColumnCount = settings.object(forKey: SettingValues.pref_multiColumnCount) == nil ? columns : settings.integer(forKey: SettingValues.pref_multiColumnCount)
        SettingValues.portraitMultiColumnCount = settings.object(forKey: SettingValues.pref_portraitMultiColumnCount) == nil ? (UIDevice.current.respectIpadLayout() ? 2 : 1) : settings.integer(forKey: SettingValues.pref_portraitMultiColumnCount)
        SettingValues.galleryCount = settings.object(forKey: SettingValues.pref_galleryCount) == nil ? columns : settings.integer(forKey: SettingValues.pref_galleryCount)
        SettingValues.highlightOp = settings.object(forKey: SettingValues.pref_highlightOp) == nil ? true : settings.bool(forKey: SettingValues.pref_highlightOp)

        var basePath = settings.string(forKey: SettingValues.pref_defaultSorting)
        for sort in LinkSortType.cases {
            if sort.path == basePath {
                SettingValues.defaultSorting = sort
                break
            }
        }
        
        basePath = settings.string(forKey: SettingValues.pref_defaultSearchSort)
        for sort in SearchSortBy.cases {
            if sort.path == basePath {
                SettingValues.defaultSearchSorting = sort
                break
            }
        }
        
        SettingValues.hapticFeedback = settings.object(forKey: SettingValues.pref_hapticFeedback) == nil ? true : settings.bool(forKey: SettingValues.pref_hapticFeedback)
        SettingValues.menuButton = settings.object(forKey: SettingValues.pref_moreButton) == nil ? true : settings.bool(forKey: SettingValues.pref_moreButton)
        SettingValues.shareButton = settings.object(forKey: SettingValues.pref_shareButton) == nil ? false : settings.bool(forKey: SettingValues.pref_shareButton)

        basePath = settings.string(forKey: SettingValues.pref_defaultTimePeriod)
        for time in TimeFilterWithin.cases {
            if time.param == basePath {
                SettingValues.defaultTimePeriod = time
                break
            }
        }

        SettingValues.desktopMode = settings.object(forKey: SettingValues.pref_desktopMode) == nil ? UIDevice.current.isMac() : settings.bool(forKey: SettingValues.pref_desktopMode)
        SettingValues.desktopMode = SettingValues.desktopMode && (UIDevice.current.respectIpadLayout() || UIDevice.current.isMac()) // Only enable this on Mac or iPad
        
        SettingValues.scrollSidebar = settings.object(forKey: SettingValues.pref_scrollSidebar) == nil ? true : settings.bool(forKey: SettingValues.pref_scrollSidebar)

        SettingValues.postFontOffset = settings.object(forKey: SettingValues.pref_postFontSize) == nil ? 0 : settings.integer(forKey: SettingValues.pref_postFontSize)
        SettingValues.commentFontOffset = settings.object(forKey: SettingValues.pref_commentFontSize) == nil ? -2 : settings.integer(forKey: SettingValues.pref_commentFontSize)

        SettingValues.commentLimit = settings.object(forKey: SettingValues.pref_commentLimit) == nil ? 100 : settings.integer(forKey: SettingValues.pref_commentLimit)
        SettingValues.submissionLimit = settings.object(forKey: SettingValues.pref_submissionLimit) == nil ? 13 : settings.integer(forKey: SettingValues.pref_submissionLimit)

        SettingValues.commentDepth = settings.object(forKey: SettingValues.pref_commentDepth) == nil ? 10 : settings.integer(forKey: SettingValues.pref_commentDepth)
        SettingValues.cachedPostsCount = settings.object(forKey: SettingValues.pref_postsToCache) == nil ? 25 : settings.integer(forKey: SettingValues.pref_postsToCache)

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
        
        if let sort = UserDefaults.standard.string(forKey: pref_commentJumpMode) {
            for t in CommentJumpMode.cases {
                if t.rawValue == sort {
                    commentJumpButton = t
                    break
                }
            }
        }
        
        SettingValues.hideImageSelftext = settings.object(forKey: SettingValues.pref_hideImageSelftext) == nil ? true : settings.bool(forKey: SettingValues.pref_hideImageSelftext)
        SettingValues.disable13Popup = false // REMOVE this setting settings.bool(forKey: SettingValues.pref_disable13Popup)
        SettingValues.streamVideos = settings.object(forKey: SettingValues.pref_streamVideos) == nil ? true : settings.bool(forKey: SettingValues.pref_streamVideos)
        SettingValues.fullWidthHeaderCells = settings.bool(forKey: SettingValues.pref_fullWidthHeaderCells)
        if UIDevice.current.isMac() {
            SettingValues.fullWidthHeaderCells = true
        }
        SettingValues.gfycatAPI = settings.object(forKey: SettingValues.pref_gfycatAPI) == nil ? true : settings.bool(forKey: SettingValues.pref_gfycatAPI)
        SettingValues.imageFlairs = settings.object(forKey: SettingValues.pref_imageFlairs) == nil ? true : settings.bool(forKey: SettingValues.pref_imageFlairs)
        SettingValues.coloredFlairs = settings.object(forKey: SettingValues.pref_coloredFlairs) == nil ? true : settings.bool(forKey: SettingValues.pref_coloredFlairs)
        SettingValues.showFlairs = settings.object(forKey: SettingValues.pref_showFlairs) == nil ? true : settings.bool(forKey: SettingValues.pref_showFlairs)

        SettingValues.subredditIcons = settings.object(forKey: SettingValues.pref_subredditIcons) == nil ? true : settings.bool(forKey: SettingValues.pref_subredditIcons)
        SettingValues.disablePopupIpad = settings.bool(forKey: SettingValues.pref_disablePopupIpad)
        SettingValues.disableSubredditPopupIpad = settings.bool(forKey: SettingValues.pref_disableSubredditPopupIpad)
        SettingValues.disableMulticolumnCollections = settings.bool(forKey: SettingValues.pref_disableMulticolumnCollections)

        SettingValues.muteYouTube = settings.object(forKey: SettingValues.pref_muteYouTube) == nil ? true : settings.bool(forKey: SettingValues.pref_muteYouTube)
        SettingValues.smallerTag = settings.object(forKey: SettingValues.pref_smallTag) == nil ? true : settings.bool(forKey: SettingValues.pref_smallTag)
        SettingValues.blackShadowbox = settings.bool(forKey: SettingValues.pref_blackShadowbox)
        SettingValues.alwaysShowHeader = settings.bool(forKey: SettingValues.pref_alwaysShowHeader)
        SettingValues.markReadOnScroll = settings.bool(forKey: SettingValues.pref_markReadOnScroll)
        SettingValues.swapLongPress = settings.bool(forKey: SettingValues.pref_swapLongPress)
        SettingValues.domainInInfo = settings.bool(forKey: SettingValues.pref_domainInInfo)
        SettingValues.notifications = settings.bool(forKey: SettingValues.pref_notifications)
        SettingValues.hideBottomBar = settings.object(forKey: SettingValues.pref_totallyCollapse) == nil ? true : settings.bool(forKey: SettingValues.pref_totallyCollapse)
        SettingValues.hideStatusBar = settings.bool(forKey: SettingValues.pref_fullyHideNavbar)
        SettingValues.showFirstParagraph = settings.object(forKey: SettingValues.pref_showFirstParagraph) == nil ? true : settings.bool(forKey: SettingValues.pref_showFirstParagraph)
        SettingValues.disableNavigationBar = settings.bool(forKey: SettingValues.pref_disableNavigationBar)
        SettingValues.disableColor = settings.bool(forKey: SettingValues.pref_disableColor)
        SettingValues.typeInTitle = settings.bool(forKey: SettingValues.pref_typeInTitle)
        SettingValues.collapseDefault = settings.bool(forKey: SettingValues.pref_collapseDefault)
        SettingValues.disablePreviews = settings.bool(forKey: SettingValues.pref_disablePreviews)
        SettingValues.volumeButtonNavigation = settings.bool(forKey: SettingValues.pref_volumeButtonNavigation)
        SettingValues.collapseFully = settings.bool(forKey: SettingValues.pref_collapseFully)
        SettingValues.autoCache = settings.bool(forKey: SettingValues.pref_autoCache)
        SettingValues.wideIndicators = settings.bool(forKey: SettingValues.pref_widerIndicators)
        SettingValues.leftThumbnail = settings.bool(forKey: SettingValues.pref_leftThumbnail)
        SettingValues.hideAutomod = settings.bool(forKey: SettingValues.pref_hideAutomod)
        SettingValues.biometrics = settings.bool(forKey: SettingValues.pref_biometrics)
        SettingValues.thumbTag = settings.object(forKey: SettingValues.pref_thumbTag) == nil ? true : settings.bool(forKey: SettingValues.pref_thumbTag)
        SettingValues.enlargeLinks = settings.object(forKey: SettingValues.pref_enlargeLinks) == nil ? true : settings.bool(forKey: SettingValues.pref_enlargeLinks)
        SettingValues.commentFullScreen = settings.object(forKey: SettingValues.pref_commentFullScreen) == nil ? !pad : settings.bool(forKey: SettingValues.pref_commentFullScreen)
        SettingValues.showLinkContentType = settings.object(forKey: SettingValues.pref_showLinkContentType) == nil ? true : settings.bool(forKey: SettingValues.pref_showLinkContentType)
        SettingValues.nameScrubbing = settings.bool(forKey: SettingValues.pref_nameScrubbing)
        SettingValues.hiddenFAB = settings.bool(forKey: SettingValues.pref_hiddenFAB)
        SettingValues.isPro = settings.bool(forKey: SettingValues.pref_pro)
        SettingValues.dontHideTopBar = settings.bool(forKey: SettingValues.pref_pinToolbar)
        SettingValues.autoKeyboard = settings.object(forKey: SettingValues.pref_autoKeyboard) == nil ? true : settings.bool(forKey: SettingValues.pref_autoKeyboard)
        SettingValues.linkAlwaysThumbnail = settings.object(forKey: SettingValues.pref_linkAlwaysThumbnail) == nil ? true : settings.bool(forKey: SettingValues.pref_linkAlwaysThumbnail)
        SettingValues.showPages = settings.bool(forKey: SettingValues.pref_showPages)
        SettingValues.disableBanner = settings.bool(forKey: SettingValues.pref_disableBanner)
        SettingValues.newIndicator = settings.bool(forKey: SettingValues.pref_newIndicator)
        SettingValues.hideAwards = settings.bool(forKey: SettingValues.pref_hideAwards)

        SettingValues.dataSavingEnabled = settings.bool(forKey: SettingValues.pref_dataSavingEnabled)
        SettingValues.dataSavingDisableWiFi = settings.bool(forKey: SettingValues.pref_dataSavingDisableWifi)
        SettingValues.loadContentHQ = settings.bool(forKey: SettingValues.pref_loadContentHQ)
        SettingValues.noImages = settings.bool(forKey: SettingValues.pref_noImg)
        SettingValues.lqLow = false // deprecate this settings.bool(forKey: SettingValues.pref_lqLow)
        SettingValues.saveButton = settings.object(forKey: SettingValues.pref_saveButton) == nil ? true : settings.bool(forKey: SettingValues.pref_saveButton)
        SettingValues.readLaterButton = settings.object(forKey: SettingValues.pref_readLaterButton) == nil ? true : settings.bool(forKey: SettingValues.pref_readLaterButton)
        SettingValues.hideButton = settings.bool(forKey: SettingValues.pref_hideButton)
        SettingValues.nightModeEnabled = settings.bool(forKey: SettingValues.pref_nightMode)
        SettingValues.nightStart = settings.object(forKey: SettingValues.pref_nightStartH) == nil ? 9 : settings.integer(forKey: SettingValues.pref_nightStartH)
        SettingValues.nightStartMin = settings.object(forKey: SettingValues.pref_nightStartH) == nil ? 0 : settings.integer(forKey: SettingValues.pref_nightStartM)
        SettingValues.nightEnd = settings.object(forKey: SettingValues.pref_nightStartH) == nil ? 5 : settings.integer(forKey: SettingValues.pref_nightEndH)
        SettingValues.nightEndMin = settings.object(forKey: SettingValues.pref_nightStartH) == nil ? 0 : settings.integer(forKey: SettingValues.pref_nightEndM)
        if let name = UserDefaults.standard.string(forKey: SettingValues.pref_nightTheme) {
            SettingValues.nightTheme = name
        }

        SettingValues.largerThumbnail = settings.object(forKey: SettingValues.pref_largerThumbnail) == nil ? true : settings.bool(forKey: SettingValues.pref_largerThumbnail)
        SettingValues.subredditBar = true // Enable this forever now settings.object(forKey: SettingValues.pref_subBar) == nil ? true : settings.bool(forKey: SettingValues.pref_subBar)
        // SettingValues.matchSilence = settings.bool(forKey: SettingValues.pref_matchSilence)
        SettingValues.infoBelowTitle = settings.bool(forKey: SettingValues.pref_infoBelowTitle)
        SettingValues.abbreviateScores = settings.object(forKey: SettingValues.pref_abbreviateScores) == nil ? true : settings.bool(forKey: SettingValues.pref_abbreviateScores)
        SettingValues.scoreInTitle = settings.bool(forKey: SettingValues.pref_scoreInTitle)
        SettingValues.commentsInTitle = settings.bool(forKey: SettingValues.pref_commentsInTitle)
        SettingValues.appMode = AppMode.init(rawValue: settings.string(forKey: SettingValues.pref_appMode) ?? (UIDevice.current.isMac() ? "triple" : (pad ? "multi" : "single"))) ?? (UIDevice.current.isMac() ? .TRIPLE_MULTI_COLUMN : (pad ? .SPLIT : .SINGLE))
        SettingValues.hideSeen = settings.bool(forKey: SettingValues.pref_hideSeen)

        SettingValues.postViewMode = PostViewType.init(rawValue: settings.string(forKey: SettingValues.pref_postViewMode) ?? "card") ?? .CARD
        SettingValues.actionBarMode = ActionBarMode.init(rawValue: settings.string(forKey: SettingValues.pref_actionbarMode) ?? "full") ?? .FULL
        SettingValues.autoPlayMode = AutoPlay.init(rawValue: settings.string(forKey: SettingValues.pref_autoPlayMode) ?? "always") ?? .ALWAYS
        SettingValues.browser = settings.string(forKey: SettingValues.pref_browser) ?? SettingValues.BROWSER_INTERNAL
        SettingValues.flatMode = settings.bool(forKey: SettingValues.pref_flatMode)
        SettingValues.reduceElevation = settings.bool(forKey: SettingValues.pref_reduceElevation)
        SettingValues.postImageMode = PostImageMode.init(rawValue: settings.string(forKey: SettingValues.pref_postImageMode) ?? "full") ?? .CROPPED_IMAGE
        SettingValues.fabType = FabType.init(rawValue: settings.string(forKey: SettingValues.pref_fabType) ?? "hide") ?? .HIDE_READ
        SettingValues.commentGesturesMode = CellGestureMode.init(rawValue: settings.string(forKey: SettingValues.pref_commentGesturesMode) ?? "half") ?? .HALF
        SettingValues.submissionGestureMode = CellGestureMode.init(rawValue: settings.string(forKey: SettingValues.pref_submissionGesturesMode) ?? "none") ?? .NONE
        SettingValues.commentActionRightLeft = CommentAction.init(rawValue: settings.string(forKey: SettingValues.pref_commentActionRightLeft) ?? "downvote") ?? .DOWNVOTE
        SettingValues.commentActionRightRight = CommentAction.init(rawValue: settings.string(forKey: SettingValues.pref_commentActionRightRight) ?? "upvote") ?? .UPVOTE
        SettingValues.commentActionLeftLeft = CommentAction.init(rawValue: settings.string(forKey: SettingValues.pref_commentActionLeftLeft) ?? "collapse") ?? .COLLAPSE
        SettingValues.commentActionLeftRight = CommentAction.init(rawValue: settings.string(forKey: SettingValues.pref_commentActionLeftRight) ?? "menu") ?? .MENU

        SettingValues.commentActionDoubleTap = CommentAction.init(rawValue: settings.string(forKey: SettingValues.pref_commentActionDoubleTap) ?? "none") ?? .NONE
        SettingValues.commentActionForceTouch = CommentAction.init(rawValue: settings.string(forKey: SettingValues.pref_commentActionForceTouch) ?? "menu") ?? .MENU

        SettingValues.submissionActionDoubleTap = SubmissionAction.init(rawValue: settings.string(forKey: SettingValues.pref_submissionActionDoubleTap) ?? "none") ?? .NONE
        SettingValues.submissionActionRight = SubmissionAction.init(rawValue: settings.string(forKey: SettingValues.pref_submissionActionRight) ?? "upvote") ?? .UPVOTE
        SettingValues.submissionActionLeft = SubmissionAction.init(rawValue: settings.string(forKey: SettingValues.pref_submissionActionLeft) ?? "downvote") ?? .DOWNVOTE

        SettingValues.sideGesture = SideGesturesMode.init(rawValue: settings.string(forKey: SettingValues.pref_sideGesture) ?? "none") ?? .NONE

        SettingValues.submissionActionForceTouch = SubmissionAction.init(rawValue: settings.string(forKey: SettingValues.pref_submissionActionForceTouch) ?? "none") ?? .NONE

        SettingValues.internalImageView = settings.object(forKey: SettingValues.pref_internalImageView) == nil ? true : settings.bool(forKey: SettingValues.pref_internalImageView)
        SettingValues.internalGifView = settings.object(forKey: SettingValues.pref_internalGifView) == nil ? true : settings.bool(forKey: SettingValues.pref_internalGifView)
        SettingValues.internalAlbumView = settings.object(forKey: SettingValues.pref_internalAlbumView) == nil ? true : settings.bool(forKey: SettingValues.pref_internalAlbumView)
        SettingValues.internalYouTube = settings.object(forKey: SettingValues.pref_internalYouTube) == nil ? true : settings.bool(forKey: SettingValues.pref_internalYouTube)
    }

    public static func done7() -> Bool {
        let settings = UserDefaults.standard
        return settings.object(forKey: "7.0.0") != nil
    }
    
    public static func doneVersion() -> Bool {
        let settings = UserDefaults.standard
        return settings.object(forKey: Bundle.main.releaseVersionNumber ?? "") != nil
    }

    public static func firstEnter() -> Bool {
        let settings = UserDefaults.standard
        return settings.object(forKey: "USEDONCE") != nil
    }

    public static func showVersionDialog(_ title: String, _ submission: Link, parentVC: UIViewController) {
        let settings = UserDefaults.standard
        settings.set(true, forKey: Bundle.main.releaseVersionNumber!)
        settings.set(title, forKey: "vtitle")
        settings.set(submission.permalink, forKey: "vlink")
        settings.synchronize()
        
        let chunk = TextDisplayStackView.createAttributedChunk(baseHTML: submission.selftextHtml, fontSize: 12, submission: true, accentColor: ColorUtil.baseAccent, fontColor: UIColor.fontColor, linksCallback: nil, indexCallback: nil)
        
        let layout = BadgeLayoutManager()
        let storage = NSTextStorage()
        storage.addLayoutManager(layout)
        let initialSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        let container = NSTextContainer(size: initialSize)
        container.widthTracksTextView = true
        layout.addTextContainer(container)

        let body = TitleUITextView(delegate: nil, textContainer: container).then {
            $0.doSetup()
        }

        body.attributedText = chunk
        body.layoutTitleImageViews()
        
        let textHeight = body.attributedText!.height(containerWidth: UIScreen.main.bounds.size.width * 0.85 - 30)
        var size = CGSize(width: UIScreen.main.bounds.size.width * 0.85 - 30, height: textHeight)

        let detailViewController = UpdateViewController(view: body, size: size)
        detailViewController.titleView.font = UIFont.boldSystemFont(ofSize: 20)
        detailViewController.titleView.textColor = UIColor.fontColor
        detailViewController.titleView.text = submission.title
        detailViewController.preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: min(size.height, 300))
        detailViewController.comments.backgroundColor = ColorUtil.baseAccent
        detailViewController.comments.setTitle("Join the discussion!", for: UIControl.State.normal)
        detailViewController.comments.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        detailViewController.comments.contentHorizontalAlignment = .left
        detailViewController.comments.addTapGestureRecognizer { (_) in
            detailViewController.dismiss(animated: true) {
                VCPresenter.openRedditLink(submission.permalink, parentVC.navigationController, parentVC)
            }
        }
        detailViewController.comments.addRightImage(image: UIImage(sfString: SFSymbol.bubbleLeftAndBubbleRightFill, overrideString: "comments")!.navIcon(true), offset: 10)
        detailViewController.dismissHandler = {() in
        }
        VCPresenter.presentModally(viewController: detailViewController, parentVC, CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: min(size.height + 15 + 15 + 20, UIScreen.main.bounds.size.height * 0.6)))
    }
    
    public enum PostOverflowAction: String {
        public static let cases: [PostOverflowAction] = [.PROFILE, .SUBREDDIT, .SUBSCRIBE, .REPORT, .BLOCK, .SAVE, .CROSSPOST, .READ_LATER, .SHARE_CONTENT, .SHARE_REDDIT, .CHROME, .SAFARI, .FILTER, .COPY, .HIDE, .UPVOTE, .DOWNVOTE, .MODERATE]

        case PROFILE = "profile"
        case SUBREDDIT = "sub"
        case REPORT = "report"
        case BLOCK = "block"
        case SAVE = "save"
        case CROSSPOST = "crosspost"
        case READ_LATER = "readlater"
        case SHARE_CONTENT = "sharecontent"
        case SHARE_REDDIT = "sharereddit"
        case CHROME = "openchrome"
        case SAFARI = "opensafari"
        case FILTER = "filter"
        case COPY = "copy"
        case HIDE = "hide"
        case UPVOTE = "upvote"
        case DOWNVOTE = "downvote"
        case MODERATE = "moderate"
        case SUBSCRIBE = "subscribe"
        
        public static func getMenu(_ link: SubmissionObject, mutableList: Bool) -> [PostOverflowAction] {
            var toReturn = [PostOverflowAction]()
            for item in getMenuNone() {
                if item == .CHROME {
                    let open = OpenInChromeController.init()
                    if !open.isChromeInstalled() {
                        continue
                    }
                }
                if !AccountController.isLoggedIn && (item == .UPVOTE || item == .DOWNVOTE || item == .SAVE || item == .CROSSPOST) {
                    continue
                }
                if !AccountController.modSubs.contains(link.subreddit) && item == .MODERATE {
                    continue
                }
                if !mutableList && (item == .FILTER || item == .HIDE) {
                    continue
                }
                if Subscriptions.isSubscriber(link.subreddit) && item == .SUBSCRIBE {
                    continue
                }
                toReturn.append(item)
            }
            return toReturn
        }
        
        public static func getMenuNone() -> [PostOverflowAction] {
            let menu = UserDefaults.standard.stringArray(forKey: "postMenu") ?? ["profile", "sub", "moderate", "report", "block", "save", "crosspost", "readlater", "sharecontent", "sharereddit", "openchrome", "opensafari", "filter", "copy", "hide"]
            var toReturn = [PostOverflowAction]()
            for item in menu {
                toReturn.append(PostOverflowAction(rawValue: item)!)
            }
            return toReturn
        }

        public func getTitle(_ link: SubmissionObject? = nil) -> String {
            switch self {
            case .PROFILE:
                if link == nil {
                    return "Author profile"
                }
                return "\(AccountController.formatUsernamePosessive(input: link!.author, small: false)) profile"
            case .SUBREDDIT:
                if link == nil {
                    return "Subreddit"
                }
                return "r/\(link!.subreddit)"
            case .SUBSCRIBE:
                if link == nil {
                    return "Subscribe"
                }
                return "Subscribe to r/\(link!.subreddit)"
            case .REPORT:
                return "Report content"
            case .BLOCK:
                return "Block user"
            case .SAVE:
                return "Save"
            case .CROSSPOST:
                return "Crosspost submission"
            case .READ_LATER:
                if link == nil {
                    return "Read Later"
                }
                return ReadLater.isReadLater(id: link!.id) ? "Remove from Read Later" : "Add to Read Later"
            case .SHARE_CONTENT:
                return "Share content link"
            case .SHARE_REDDIT:
                return "Share reddit link"
            case .CHROME:
                return "Open in Chrome"
            case .SAFARI:
                return "Open in Safari"
            case .FILTER:
                return "Filter this content"
            case .COPY:
                return "Copy self text"
            case .HIDE:
                return "Hide"
            case .UPVOTE:
                return "Upvote"
            case .DOWNVOTE:
                return "Downvote"
            case .MODERATE:
                return "Mod Actions"
            }
        }
        
        public func getImage(_ link: SubmissionObject? = nil) -> UIImage {
            switch self {
            case .PROFILE:
                return UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon()
            case .SUBREDDIT:
                return UIImage(sfString: .rCircleFill, overrideString: "subs")!.menuIcon()
            case .REPORT:
                return UIImage(sfString: SFSymbol.exclamationmarkBubbleFill, overrideString: "flag")!.menuIcon()
            case .BLOCK:
                return UIImage(sfString: SFSymbol.handRaisedFill, overrideString: "block")!.menuIcon()
            case .SAVE:
                return UIImage(sfString: SFSymbol.starFill, overrideString: "save")!.menuIcon()
            case .SUBSCRIBE:
                return UIImage(sfString: SFSymbol.plusCircleFill, overrideString: "add")!.menuIcon()
            case .CROSSPOST:
                return UIImage(named: "crosspost")!.menuIcon()
            case .READ_LATER:
                if link == nil {
                    return UIImage(sfString: SFSymbol.trayAndArrowDownFill, overrideString: "readLater")!.menuIcon()
                }
                return ReadLater.isReadLater(id: link!.id) ? UIImage(sfString: SFSymbol.trayAndArrowUpFill, overrideString: "restore")!.menuIcon() : UIImage(sfString: SFSymbol.trayAndArrowDownFill, overrideString: "readLater")!.menuIcon()
            case .SHARE_CONTENT:
                return UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")!.menuIcon()
            case .SHARE_REDDIT:
                return UIImage(sfString: SFSymbol.bubbleLeftAndBubbleRightFill, overrideString: "comments")!.menuIcon()
            case .CHROME:
                return UIImage(sfString: SFSymbol.link, overrideString: "link")!.menuIcon()
            case .SAFARI:
                return UIImage(named: "world")!.menuIcon()
            case .FILTER:
                return UIImage(named: "filter")!.menuIcon()
            case .COPY:
                return UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()
            case .HIDE:
                return UIImage(sfString: SFSymbol.xmark, overrideString: "hide")!.menuIcon()
            case .UPVOTE:
                return UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")!.menuIcon().getCopy(withColor: ColorUtil.upvoteColor)
            case .DOWNVOTE:
                return UIImage(sfString: SFSymbol.arrowDown, overrideString: "downvote")!.menuIcon().getCopy(withColor: ColorUtil.downvoteColor)
            case .MODERATE:
                return UIImage(sfString: SFSymbol.shieldLefthalfFill, overrideString: "mod")!.menuIcon().getCopy(withColor: GMColor.lightGreen500Color())
            }
        }
    }
    
    public enum CommentAction: String {
        public static let cases: [CommentAction] = [.UPVOTE, .DOWNVOTE, .MENU, .COLLAPSE, .SAVE, .REPLY, .EXIT, .NEXT, .NONE]
        public static let cases3D: [CommentAction] = [.PARENT_PREVIEW, .UPVOTE, .DOWNVOTE, .MENU, .COLLAPSE, .SAVE, .REPLY, .EXIT, .NEXT, .NONE]

        case UPVOTE = "upvote"
        case DOWNVOTE = "downvote"
        case MENU = "menu"
        case COLLAPSE = "collapse"
        case SAVE = "save"
        case NONE = "none"
        case REPLY = "reply"
        case NEXT = "next"
        case EXIT = "exit"
        case PARENT_PREVIEW = "parent"
        
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
            case .PARENT_PREVIEW:
                return "Parent comment preview"
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
            case .PARENT_PREVIEW:
                return "comments"
            }
        }
        
        func getColor() -> UIColor {
            switch self {
            case .COLLAPSE :
                return GMColor.grey500Color()
            case .UPVOTE:
                return ColorUtil.upvoteColor
            case .DOWNVOTE:
                return ColorUtil.downvoteColor
            case .SAVE:
                return GMColor.yellow500Color()
            case .MENU:
                return GMColor.green500Color()
            case .NONE:
                return GMColor.red500Color()
            case .REPLY:
                return GMColor.green500Color()
            case .EXIT:
                return GMColor.red500Color()
            case .NEXT:
                return GMColor.lightGreen500Color()
            case .PARENT_PREVIEW:
                return GMColor.purple500Color()
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

    public enum NavigationHeaderActions: String {
        public static let cases: [NavigationHeaderActions] = [.HOME, .POPULAR, .RANDOM, .READ_LATER, .SAVED, .UPVOTED, .HISTORY, .AUTO_CACHE, .YOUR_PROFILE, .COLLECTIONS, .CREATE_MULTI, .TRENDING]

        case HOME = "home"
        case POPULAR = "popular"
        case RANDOM = "random"
        case SAVED = "saved"
        case UPVOTED = "upvoted"
        case HISTORY = "history"
        case AUTO_CACHE = "auto_cache"
        case YOUR_PROFILE = "profile"
        case COLLECTIONS = "collections"
        case CREATE_MULTI = "create_multi"
        case TRENDING = "trending"
        case READ_LATER = "readlater"

        public static func getMenuNone() -> [NavigationHeaderActions] {
            let menu = UserDefaults.standard.stringArray(forKey: "headerMenu") ?? ["home", "random", "readlater", "saved", "collections"]
            var toReturn = [NavigationHeaderActions]()
            for item in menu {
                let action = NavigationHeaderActions(rawValue: item) ?? .HOME
                if !action.needsAccount() || AccountController.isLoggedIn {
                    toReturn.append(action)
                }
            }
            return toReturn
        }
        
        public func needsAccount() -> Bool {
            switch self {
            case .HOME, .POPULAR, .READ_LATER, .RANDOM, .AUTO_CACHE, .COLLECTIONS, .TRENDING:
                return false
            default:
                return true
            }
        }

        public func getTitle() -> String {
            switch self {
            case .HOME:
                return "Home"
            case .POPULAR:
                return "Popular"
            case .READ_LATER:
                return "Read later"
            case .RANDOM:
                return "Random"
            case .SAVED:
                return "Saved posts"
            case .UPVOTED:
                return "Upvoted posts"
            case .HISTORY:
                return "Post history"
            case .AUTO_CACHE:
                return "Start AutoCache now"
            case .YOUR_PROFILE:
                return "Your profile"
            case .COLLECTIONS:
                return "Your Collections"
            case .CREATE_MULTI:
                return "Create a Multireddit"
            case .TRENDING:
                return "Trending on Reddit"
            }
        }
        
        // TODO pre ios 13 icons
        public func getImage(_ link: SubmissionObject? = nil) -> UIImage {
            switch self {
            case .HOME:
                return UIImage(sfString: SFSymbol.houseFill, overrideString: "world")!.menuIcon()
            case .POPULAR:
                return UIImage(sfString: SFSymbol.flameFill, overrideString: "upvote")!.menuIcon()
            case .RANDOM:
                return UIImage(sfString: SFSymbol.shuffle, overrideString: "sync")!.menuIcon()
            case .READ_LATER:
                return UIImage(sfString: SFSymbol.bookFill, overrideString: "bookmark")!.menuIcon()
            case .SAVED:
                return UIImage(sfString: SFSymbol.starFill, overrideString: "save")!.menuIcon()
            case .UPVOTED:
                return UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")!.menuIcon()
            case .HISTORY:
                return UIImage(sfString: SFSymbol.clockFill, overrideString: "history")!.menuIcon()
            case .AUTO_CACHE:
                return UIImage(sfString: SFSymbol.squareAndArrowDownFill, overrideString: "download")!.menuIcon()
            case .YOUR_PROFILE:
                return UIImage(sfString: SFSymbol.personFill, overrideString: "user")!.menuIcon()
            case .COLLECTIONS:
                return UIImage(sfString: SFSymbol.squareStackFill, overrideString: "multis")!.menuIcon()
            case .CREATE_MULTI:
                return UIImage(sfString: SFSymbol.folderFillBadgePlus, overrideString: "multis")!.menuIcon()
            case .TRENDING:
                return UIImage(named: "trending")!.menuIcon()
            }
        }
    }
    
    public enum FabType: String {

        public static let cases: [FabType] = [.HIDE_READ, .HIDE_PERMANENTLY, .SHADOWBOX, .GALLERY, .NEW_POST, .SIDEBAR, .RELOAD, .SEARCH]

        case HIDE_READ = "hide"
        case SHADOWBOX = "shadowbox"
        case NEW_POST = "newpost"
        case SIDEBAR = "sidebar"
        case GALLERY = "gallery"
        case SEARCH = "search"
        case RELOAD = "reload"
        case HIDE_PERMANENTLY = "perm"

        func getPhoto() -> UIImage? {
            switch self {
            case .HIDE_READ:
                return UIImage(sfString: SFSymbol.eyeSlashFill, overrideString: "hide")
            case .HIDE_PERMANENTLY:
                return UIImage(sfString: SFSymbol.eyeSlashFill, overrideString: "hide")
            case .NEW_POST:
                return UIImage(sfString: SFSymbol.squareAndPencil, overrideString: "edit")
            case .SHADOWBOX:
                return UIImage(named: "shadowbox")
            case .SIDEBAR:
                return UIImage(sfString: SFSymbol.infoCircleFill, overrideString: "info")
            case .RELOAD:
                return UIImage(sfString: SFSymbol.arrowClockwise, overrideString: "sync")
            case .GALLERY:
                return UIImage(sfString: SFSymbol.photoFill, overrideString: "image")
            case .SEARCH:
                return UIImage(sfString: SFSymbol.magnifyingglass, overrideString: "search")
            }
        }

        func getTitle() -> String {
            switch self {
            case .HIDE_READ:
                return "Hide read"
            case .HIDE_PERMANENTLY:
                return "Hide read permanently"
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

        func getTitleShort() -> String {
            switch self {
            case .HIDE_READ:
                return "Hide read"
            case .HIDE_PERMANENTLY:
                return "Hide read"
            case .NEW_POST:
                return "Submit"
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
        public static let cases: [AppMode] = UIDevice.current.isMac() ? [.SPLIT, .SINGLE, .MULTI_COLUMN, .TRIPLE_MULTI_COLUMN] : [.SPLIT, .SINGLE, .MULTI_COLUMN]
        
        case SPLIT = "split"
        case SINGLE = "single"
        case MULTI_COLUMN = "multi"
        case TRIPLE_MULTI_COLUMN = "triple"

        func getTitle() -> String {
            switch self {
            case .SPLIT:
                return "Split view mode"
            case .SINGLE:
                return "Single list"
            case .MULTI_COLUMN:
                return "Multi-column mode"
            case .TRIPLE_MULTI_COLUMN:
                return "Multi-column with comments"
            }
        }
        
        func getDescription() -> String {
            switch self {
            case .SPLIT:
                return "Displays submissions on the left and comments on the right"
            case .SINGLE:
                return "Single column display of submissions"
            case .MULTI_COLUMN:
                return "Multiple column display of submissions"
            case .TRIPLE_MULTI_COLUMN:
                return "Multiple column display of submissions with comments on the right"
            }
        }
    }

    public enum CommentJumpMode: String {
        
        public static let cases: [CommentJumpMode] = [.DISABLED, .LEFT, .RIGHT]
        
        case DISABLED = "disabled"
        case LEFT = "left"
        case RIGHT = "right"
        
        func getTitle() -> String {
            switch self {
            case .DISABLED:
                return "Disabled"
            case .LEFT:
                return "Left side"
            case .RIGHT:
                return "Right side"
            }
        }
    }

}

// MARK: - Font Settings
extension SettingValues {
    static var commentFontWeight: String? {
        get {
            return UserDefaults.standard.string(forKey: "COMMENT_FONT_WEIGHT") ?? "Regular"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "COMMENT_FONT_WEIGHT")
        }
    }

    static var submissionFontWeight: String? {
        get {
            return UserDefaults.standard.string(forKey: "SUBMISSION_FONT_WEIGHT") ?? "Regular"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "SUBMISSION_FONT_WEIGHT")
        }
    }
}

// MARK: - Audio Settings
extension SettingValues {
    static var muteInlineVideos: Bool {
        get {
            return UserDefaults.standard.object(forKey: "MUTE_INLINE_VIDEOS") as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "MUTE_INLINE_VIDEOS")
        }
    }

    static var muteVideosInModal: Bool {
        get {
            return UserDefaults.standard.object(forKey: "MUTE_VIDEOS_IN_MODAL") as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "MUTE_VIDEOS_IN_MODAL")
        }
    }

    static var modalVideosRespectHardwareMuteSwitch: Bool {
        get {
            return UserDefaults.standard.object(forKey: "MODAL_VIDEOS_RESPECT_HARDWARE_MUTE_SWITCH") as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "MODAL_VIDEOS_RESPECT_HARDWARE_MUTE_SWITCH")
        }
    }
}

class UpdateViewController: UIViewController {
    var childView = UIView()
    var titleView = UILabel()
    var exit = UIImageView()
    var scrollView = UIScrollView()
    var estimatedSize: CGSize
    var comments = UIButton()
    var dismissHandler: (() -> Void)?
    init(view: UIView, size: CGSize) {
        self.estimatedSize = size
        super.init(nibName: nil, bundle: nil)
        self.childView = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView = UIScrollView().then {
            $0.backgroundColor = UIColor.foregroundColor
            $0.isUserInteractionEnabled = true
        }
        self.view.addSubviews(scrollView, titleView, comments)
        titleView.horizontalAnchors /==/ self.view.horizontalAnchors
        titleView.textAlignment = .center
        titleView.topAnchor /==/ self.view.topAnchor + 15
        scrollView.topAnchor /==/ self.titleView.bottomAnchor + 15
        scrollView.horizontalAnchors /==/ self.view.horizontalAnchors + 10
        comments.topAnchor /==/ self.scrollView.bottomAnchor + 15
        comments.bottomAnchor /==/ self.view.bottomAnchor - 15
        comments.heightAnchor /==/ 40
        comments.layer.cornerRadius = 10
        comments.layer.masksToBounds = true
        comments.horizontalAnchors /==/ self.view.horizontalAnchors + 15
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.addSubview(childView)
        childView.widthAnchor /==/ estimatedSize.width
        childView.heightAnchor /==/ estimatedSize.height
        childView.topAnchor /==/ scrollView.topAnchor
        scrollView.contentSize = estimatedSize
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissHandler?()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIButton {
    func addRightImage(image: UIImage, offset: CGFloat) {
        self.setImage(image, for: .normal)
        self.imageView?.translatesAutoresizingMaskIntoConstraints = false
        self.imageView?.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0.0).isActive = true
        self.imageView?.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offset).isActive = true
    }
}
