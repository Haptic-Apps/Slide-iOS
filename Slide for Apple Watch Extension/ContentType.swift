//
//  ContentType.swift
//  Slide for Apple Watch Extension
//
//  Created by Carlos Crane on 9/25/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

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
        
        return hostContains(host: host, bases: ["gfycat.com", "v.redd.it"]) || ((hostContains(host: host, bases: ["preview.redd.it", "external-preview.redd.it"]) && path.contains("format=mp4"))) || (hostContains(host: host, bases: ["redditmedia.com", "imgur.com"]) && path.endsWith(".gif") || path.endsWith(".gifv") || path.endsWith(".webm")) || path.endsWith(".mp4")
        
    }
    
    public static func isGif(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        let path = uri.path.lowercased()
        
        return hostContains(host: host, bases: ["gfycat.com", "v.redd.it"]) || path.hasSuffix(".gif") || path.hasSuffix(
            ".gifv") || path.hasSuffix(".webm") || path.hasSuffix(".mp4")
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
    
    public static func isVideo(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        let path = uri.path.lowercased()
        
        return hostContains(host: host, bases: ["youtu.be", "youtube.com", "youtube.co.uk"]) && !path.contains("/user/") && !path.contains("/channel/")
    }
    
    public static func isImgurLink(uri: URL) -> Bool {
        let host = uri.host?.lowercased()
        return hostContains(host: host, bases: ["imgur.com", "bildgur.de"]) && !isAlbum(uri: uri) && !isGif(uri: uri) && !isImage(uri: uri)
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
    public static func getContentType(dict: NSDictionary) -> CType {
        let url = URL(string: dict["url"] as? String ?? "")
        if url == nil {
            return .NONE
        }
        
        let basicType = getContentType(baseUrl: url)
        
        if (dict["is_self"] as? Bool ?? false)! {
            return CType.SELF
        }
        // TODO: Decide whether internal youtube links should be EMBEDDED or LINK
        /* todo this if (basicType == (CType.LINK) && submission?.mediaEmbed != nil && !submission?.mediaEmbed!.content.isEmpty{
         return CType.EMBEDDED;
         }*/
        
        return basicType
    }
    
    public static func displayImage(t: CType) -> Bool {
        switch t {
            
        case CType.ALBUM, CType.DEVIANTART, CType.IMAGE, CType.XKCD, CType.TUMBLR, CType.IMGUR, CType.SELF:
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
            
        case CType.ALBUM, CType.DEVIANTART, CType.GIF, CType.IMAGE, CType.IMGUR, CType.STREAMABLE, CType.TUMBLR, CType.XKCD, CType.VIDEO, CType.SELF, CType.VID_ME:
            return true
            
        case CType.EMBEDDED, CType.EXTERNAL, CType.LINK, CType.NONE, CType.REDDIT, CType.SPOILER, CType.TABLE, CType.UNKNOWN:
            return false
        }
    }
    
    public static func mediaType(t: CType) -> Bool {
        switch t {
            
        case CType.ALBUM, CType.DEVIANTART, CType.GIF, CType.IMAGE, CType.TUMBLR, CType.XKCD, CType.IMGUR, CType.STREAMABLE, CType.VID_ME:
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
    enum CType {
        case UNKNOWN
        case ALBUM
        case DEVIANTART
        case EMBEDDED
        case EXTERNAL
        case GIF
        case IMAGE
        case IMGUR
        case LINK
        case NONE
        case SPOILER
        case REDDIT
        case SELF
        case STREAMABLE
        case VIDEO
        case XKCD
        case TUMBLR
        case VID_ME
        case TABLE
    }
}
