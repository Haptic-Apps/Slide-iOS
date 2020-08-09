//
//  ContentType.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/29/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

/**
 * Created by ccrama on 5/26/2015.
 */
class ContentType {
    /**
     * Checks if {@code host} is contains by any of the provided {@code bases}
     * <p/>
     * For example "www.youtube.com" contains "youtube.com" but not "notyoutube.com" or
     * "youtube.co.uk"
     *
     * @param host  A hostname from e.g. {@link URI#getHost()}
     * @param bases Any number of hostnames to compare against {@code host}
     * @return If {@code host} contains any of {@code bases}
     */
    public static func hostContains(host: String?, bases: [String]?) -> Bool {
        if host == nil || (host?.isEmpty)! {
            return false
        }
                
        for b in bases! {
            if b.isEmpty {
                continue
            }
            if (host?.hasSuffix("." + b))! || (host == b) { return true }
        }
        
        return false
    }

    public static func isExternal(_ uri: URL) -> Bool {
        return PostFilter.openExternally(uri)
    }
    
    public static func shouldOpenBrowser(_ url: URL) -> Bool {
        let browser = SettingValues.browser
        if browser == SettingValues.BROWSER_INTERNAL || browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY || browser == SettingValues.BROWSER_SAFARI_INTERNAL {
            return false
        } else {
            let type = getContentType(baseUrl: url)
            if type == .LINK || type == .UNKNOWN {
                return true
            }
        }
        return false
    }

    public static func isSpoiler(uri: URL) -> Bool {
        let urlString = uri.absoluteString
        if !urlString.hasPrefix("//") && ((urlString.hasPrefix("/") && urlString.length < 4)
            || urlString.hasPrefix("#spoil")
            || urlString.hasPrefix("/spoil")
            || urlString.hasPrefix("#s-")
            || urlString == ("#s")
            || urlString == ("#ln")
            || urlString == ("#b")
            || urlString == ("#sp")) {
            return true
        }
        return false
    }

    public static func isTable(uri: URL) -> Bool {
        let urlString = uri.absoluteString
        if urlString.contains("http://view.table/") {
            return true
        }
        return false
    }
    
    public static func isGifLoadInstantly(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        let path = uri.path.lowercased()
        
        return hostContains(host: host, bases: ["gfycat.com", "v.redd.it"]) || ((hostContains(host: host, bases: ["preview.redd.it", "external-preview.redd.it"]) && uri.absoluteString.contains("format=mp4"))) || (hostContains(host: host, bases: ["redditmedia.com", "imgur.com"]) && path.endsWith(".gif") || path.endsWith(".gifv") || path.endsWith(".webm")) || path.endsWith(".mp4")

    }
    
    public static func isGif(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        let path = uri.path.lowercased()

        return hostContains(host: host, bases: ["gfycat.com", "redgifs.com", "v.redd.it"]) || path.hasSuffix(".gif") || path.hasSuffix(
            ".gifv") || path.hasSuffix(".webm") || path.hasSuffix(".mp4") || ((hostContains(host: host, bases: ["preview.redd.it", "external-preview.redd.it"]) && uri.absoluteString.contains("format=mp4")))
    }
    
    public static func isGfycat(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        
        return hostContains(host: host, bases: ["gfycat.com"])
    }
    
    public static func isImage(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        let path = uri.path.lowercased()
        
        return host == ("i.reddituploads.com") || path.hasSuffix(".png") || path.hasSuffix(
            ".jpg") || path.hasSuffix(".jpeg")
        
    }
    public static func isImgurImage(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        let path = uri.path.lowercased()
        
        return (host!.contains("imgur.com") || host!.contains("bildgur.de")) && ((path.hasSuffix(
            ".png") || path.hasSuffix(".jpg") || path.hasSuffix(".jpeg")))
        
    }
    
    public static func isImgurHash(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        let path = uri.path.lowercased()
        return (host!.contains("imgur.com")) && !(path.hasSuffix(".png") && !path.hasSuffix(".jpg")  && !path.hasSuffix(".jpeg"))
    }
    
    public static func isAlbum(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        let path = uri.path.lowercased()
        
        return hostContains(host: host, bases: ["imgur.com", "bildgur.de"]) && (path.hasPrefix("/a/")
            || path.hasPrefix("/gallery/")
            || path.hasPrefix("/g/")
            || path.contains(","))
        
    }

    public static func isGallery(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        let path = uri.path.lowercased()
        
        return hostContains(host: host, bases: ["reddit.com", "redd.it"]) && (path.hasPrefix("/gallery/"))
    }

    public static func isVideo(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        let path = uri.path.lowercased()
        
        return hostContains(host: host, bases: ["youtu.be", "youtube.com", "youtube.co.uk"]) && !path.contains("/user/") && !path.contains("/channel/") || uri.absoluteString.contains("youtu")
    }
    
    public static func isImgurLink(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        return hostContains(host: host, bases: ["imgur.com", "bildgur.de"]) && !isAlbum(uri: uri) && !isGif(uri: uri) && !isImage(uri: uri)
    }
    
    public static func shouldOpenExternally(_ url: URL) -> Bool {
        let type = getContentType(baseUrl: url)
        if !SettingValues.internalGifView && (type == CType.GIF || type == CType.VID_ME || type == CType.STREAMABLE) {
            return true
        } else if !SettingValues.internalYouTube && type == CType.VIDEO {
            return true
        } else if !SettingValues.internalImageView && (type == CType.IMAGE || type == CType.IMGUR || type == CType.DEVIANTART || type == CType.XKCD || type == CType.TUMBLR) {
            return true
        } else if !SettingValues.internalAlbumView && type == CType.ALBUM {
            return true
        }
        return false
    }
    
    /**
     * Attempt to determine the content type of a link from the URL
     *
     * @param url URL to get ContentType from
     * @return ContentType of the URL
     */
    public static func getContentType(baseUrl: URL?) -> CType {
        if baseUrl == nil || baseUrl!.absoluteString.isEmpty() {
            return CType.NONE
        }
        var urlString = baseUrl!.absoluteString
        if urlString.hasPrefix("applewebdata:") {
            urlString = baseUrl!.path
        }
        if !urlString.hasPrefix("//") && ((urlString.hasPrefix("/") && urlString.length < 4)
            || urlString.hasPrefix("#spoil")
            || urlString.hasPrefix("/spoil")
            || urlString.hasPrefix("#s-")
            || urlString == ("#s")
            || urlString == ("#ln")
            || urlString == ("#b")
            || urlString == ("#sp")) {
            return CType.SPOILER
        }

        if urlString.contains("http://view.table/") {
            return CType.TABLE
        }
        
        if urlString.hasPrefix("//") { urlString = "https:" + urlString }
        if urlString.hasPrefix("/") { urlString = "reddit.com" + urlString }
        if !urlString.contains("://") { urlString = "http://" + urlString }
        
        let url = URL.init(string: urlString)
        let host = url?.host?.lowercased()
        let scheme = url?.scheme?.lowercased()

        if ContentType.isExternal(url!) {
            return .EXTERNAL
        }

        if host == nil || scheme == nil || !(scheme == ("http") || scheme == ("https")) {
            return CType.EXTERNAL
        }
        
        if isVideo(uri: url!) {
            return CType.VIDEO
        }
        if isGif(uri: url!) {
            return CType.GIF
        }
        if isImage(uri: url!) {
            return CType.IMAGE
        }
        if isAlbum(uri: url!) {
            return CType.ALBUM
        }
        if isGallery(uri: url!) {
            return CType.REDDIT_GALLERY
        }
        if hostContains(host: host, bases: ["imgur.com", "bildgur.de"]) {
            return CType.IMGUR
        }
        if hostContains(host: host, bases: ["xkcd.com"]) && !(host == ("imgs.xkcd.com")) && !(host == ("what-if.xkcd.com")) {
            return CType.XKCD
        }
        /* Currently doesn't work
        if hostContains(host: host, bases: ["tumblr.com"]) && (url?.path.contains("post"))! {
            return CType.TUMBLR
        }*/
        if hostContains(host: host, bases: ["reddit.com", "redd.it"]) {
            return CType.REDDIT
        }
        if hostContains(host: host, bases: ["vid.me"]) {
            return CType.VID_ME
        }
        if hostContains(host: host, bases: ["deviantart.com"]) {
            return CType.DEVIANTART
        }
        if hostContains(host: host, bases: ["streamable.com"]) {
            return CType.STREAMABLE
        }
        
        return CType.LINK
    }
    /**
     * Attempts to determine the content of a submission, mostly based on the URL
     *
     * @param submission Submission to get the content type from
     * @return Content type of the Submission
     * @see #getContentType(String)
     */
    public static func getContentType(submission: RSubmission?) -> CType {
        if submission == nil {
            return CType.SELF; //hopefully shouldn't be null, but catch it in case
        }
        
        let url = submission?.url
        if url == nil {
            return .NONE
        }

        let basicType = getContentType(baseUrl: url)
        
        if (submission?.isSelf)! {
            return CType.SELF
        }
        // TODO: - Decide whether internal youtube links should be EMBEDDED or LINK
        /* if (basicType == (CType.LINK) && submission?.mediaEmbed != nil && !submission?.mediaEmbed!.content.isEmpty{
         return CType.EMBEDDED;
         }*/
        
        return basicType
    }
    
    public static func displayImage(t: CType) -> Bool {
        switch t {
            
        case CType.ALBUM, CType.REDDIT_GALLERY, CType.DEVIANTART, CType.IMAGE, CType.XKCD, CType.TUMBLR, CType.IMGUR, CType.SELF:
            return true
        default:
            return false
        }
    }
    
    public static func displayVideo(t: CType) -> Bool {
        switch t {
        case CType.STREAMABLE, CType.VID_ME, CType.VIDEO, CType.GIF:
            return true
        default:
            return false
        }
    }
    
    public static func imageType(t: CType) -> Bool {
        return (t == .IMAGE || t == .IMGUR)
    }
    
    public static func fullImage(t: CType) -> Bool {
        switch t {
            
        case CType.ALBUM, CType.REDDIT_GALLERY, CType.DEVIANTART, CType.GIF, CType.IMAGE, CType.IMGUR, CType.STREAMABLE, CType.TUMBLR, CType.XKCD, CType.VIDEO, CType.SELF, CType.VID_ME:
            return true
            
        case CType.EMBEDDED, CType.EXTERNAL, CType.LINK, CType.NONE, CType.REDDIT, CType.SPOILER, CType.TABLE, CType.UNKNOWN:
            return false
        }
    }
    
    public static func mediaType(t: CType) -> Bool {
        switch t {
            
        case CType.ALBUM, CType.REDDIT_GALLERY, CType.DEVIANTART, CType.GIF, CType.IMAGE, CType.TUMBLR, CType.XKCD, CType.IMGUR, CType.STREAMABLE, CType.VID_ME:
            return true
        default:
            return false
        }
    }
    
    /**
     * Returns a string identifier for a submission e.g. Link, GIF, NSFW Image
     *
     * @param submission Submission to get the description for
     * @return the String identifier
     */
    enum CType: String {
        case UNKNOWN = "Unknown"
        case ALBUM = "Album"
        case REDDIT_GALLERY = "Gallery"
        case DEVIANTART = "DeviantArt"
        case EMBEDDED = "Embedded"
        case EXTERNAL = "External"
        case GIF = "Gif"
        case IMAGE = "Image"
        case IMGUR = "Imgur"
        case LINK = "Link"
        case NONE = "None"
        case SPOILER = "Spoiler"
        case REDDIT = "Reddit"
        case SELF = "Selftext"
        case STREAMABLE = "Streamable"
        case VIDEO = "Video"
        case XKCD = "XKCD"
        case TUMBLR = "Tumblr"
        case VID_ME = "Vid.me"
        case TABLE = "Table"
        
        func getTitle(_ url: URL?) -> String {
            switch self {
            case .UNKNOWN, .LINK, .NONE, .SPOILER, .TABLE, .EMBEDDED:
                return "Link"
            case .ALBUM:
                return "Imgur Album"
            case .REDDIT_GALLERY:
                return "Gallery"
            case .DEVIANTART:
                return "Deviantart"
            case .IMAGE:
                return "Direct Image"
            case .IMGUR:
                return "Imgur Image"
            case .TUMBLR:
                return "Tumblr"
            case .XKCD:
                return "XKCD"
            case .EXTERNAL:
                return "External Link"
            case .GIF:
                if url != nil && url!.absoluteString.contains("v.redd.it") {
                    return "Reddit Video"
                }
                return "Gif"
            case .STREAMABLE:
                return "Streamable.com Video"
            case .VIDEO:
                return "YouTube Video"
            case .VID_ME:
                return "Vid.me Video"
            case .REDDIT:
                return "Reddit Link"
            case .SELF:
                return "Selftext Post"
            }
        }
        
        func getImage() -> String {
            switch self {
            case .UNKNOWN, .LINK, .NONE, .SPOILER, .TABLE, .EMBEDDED:
                return "world"
            case .ALBUM, .REDDIT_GALLERY, .DEVIANTART, .IMAGE, .IMGUR, .TUMBLR, .XKCD:
                return "image"
            case .EXTERNAL:
                return "crosspost"
            case .GIF, .STREAMABLE, .VIDEO, .VID_ME:
                return "play"
            case .REDDIT:
                return "reddit"
            case .SELF:
                return "size"
            }
        }
    }
    
    static func getThumbnailType(submission: Link) -> ThumbnailType {
        let thumbnail = submission.thumbnail
        
        if thumbnail.isEmpty() {
            return ThumbnailType.NONE
        }
        
        if let type = ThumbnailType(rawValue: thumbnail) {
            return type
        } else {
            return ThumbnailType.URL
        }
        
    }
    
    enum ThumbnailType: String {
        case NSFW = "nsfw"
        case DEFAULT = "default"
        case SELF = "self"
        case NONE = ""
        case URL = "url"
    }
}
