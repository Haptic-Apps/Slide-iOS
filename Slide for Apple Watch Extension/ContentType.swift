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
        
        return hostContains(host: host, bases: ["gfycat.com", "v.redd.it"]) || (hostContains(host: host, bases: ["redditmedia.com", "imgur.com"]) && path.endsWith(".gif") || path.endsWith(".gifv") || path.endsWith(".webm")) || path.endsWith(".mp4")
        
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
        if hostContains(host: host, bases: ["tumblr.com"]) && (url?.path.contains("post"))! {
            return CType.TUMBLR
        }
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
        if dict == nil {
            return CType.SELF; //hopefully shouldn't be null, but catch it in case
        }
        
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

public extension String {
    
    ///  Finds the string between two bookend strings if it can be found.
    ///
    ///  - parameter left:  The left bookend
    ///  - parameter right: The right bookend
    ///
    ///  - returns: The string between the two bookends, or nil if the bookends cannot be found, the bookends are the same or appear contiguously.
    func between(_ left: String, _ right: String) -> String? {
        guard
            let leftRange = range(of: left), let rightRange = range(of: right, options: .backwards),
            left != right && leftRange.upperBound != rightRange.lowerBound
            else { return nil }
        
        return String(self[leftRange.upperBound...index(before: rightRange.lowerBound)])
        
    }
    
    // https://gist.github.com/stevenschobert/540dd33e828461916c11
    func camelize() -> String {
        let source = clean(with: " ", allOf: "-", "_")
        if source.contains(" ") {
            let first = self[self.startIndex...self.index(after: startIndex)] //source.substringToIndex(source.index(after: startIndex))
            let cammel = source.capitalized.replacingOccurrences(of: " ", with: "")
            //            let cammel = String(format: "%@", strip)
            let rest = String(cammel.dropFirst())
            return "\(first)\(rest)"
        } else {
            let first = source[self.startIndex...self.index(after: startIndex)].lowercased()
            let rest = String(source.dropFirst())
            return "\(first)\(rest)"
        }
    }
    
    func capitalize() -> String {
        return capitalized
    }
    
    //    func contains(_ substring: String) -> Bool {
    //        return range(of: substring) != nil
    //    }
    
    func chompLeft(_ prefix: String) -> String {
        if let prefixRange = range(of: prefix) {
            if prefixRange.upperBound >= endIndex {
                return String(self[startIndex..<prefixRange.lowerBound])
            } else {
                return String(self[prefixRange.upperBound..<endIndex])
            }
        }
        return self
    }
    
    func chompRight(_ suffix: String) -> String {
        if let suffixRange = range(of: suffix, options: .backwards) {
            if suffixRange.upperBound >= endIndex {
                return String(self[startIndex..<suffixRange.lowerBound])
            } else {
                return String(self[suffixRange.upperBound..<endIndex])
            }
        }
        return self
    }
    
    func collapseWhitespace() -> String {
        let thecomponents = components(separatedBy: NSCharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }
        return thecomponents.joined(separator: " ")
    }
    
    func clean(with: String, allOf: String...) -> String {
        var string = self
        for target in allOf {
            string = string.replacingOccurrences(of: target, with: with)
        }
        return string
    }
    
    func count(_ substring: String) -> Int {
        return components(separatedBy: substring).count - 1
    }
    
    func endsWith(_ suffix: String) -> Bool {
        return hasSuffix(suffix)
    }
    
    func ensureLeft(_ prefix: String) -> String {
        if startsWith(prefix) {
            return self
        } else {
            return "\(prefix)\(self)"
        }
    }
    
    func ensureRight(_ suffix: String) -> String {
        if endsWith(suffix) {
            return self
        } else {
            return "\(self)\(suffix)"
        }
    }
    
    func indexOf(_ substring: String) -> Int? {
        if let range = range(of: substring) {
            return self.distance(from: startIndex, to: range.lowerBound)
            //            return startIndex.distanceTo(range.lowerBound)
        }
        return nil
    }
    
    func lastIndexOf(_ substring: String) -> Int? {
        if let range = range(of: substring, options: .backwards) {
            return self.distance(from: startIndex, to: range.lowerBound)
            //            return startIndex.distanceTo(range.lowerBound)
        }
        return nil
    }
    
    func initials() -> String {
        let words = self.components(separatedBy: " ")
        return words.reduce("") { $0 + $1[startIndex...startIndex] }
        //        return words.reduce(""){$0 + $1[0...0]}
    }
    
    func initialsFirstAndLast() -> String {
        let words = self.components(separatedBy: " ")
        return words.reduce("") { ($0 == "" ? "" : String($0[startIndex...startIndex])) + $1[startIndex...startIndex] }
    }
    
    func isAlpha() -> Bool {
        for chr in self {
            if !(chr >= "a" && chr <= "z") && !(chr >= "A" && chr <= "Z") {
                return false
            }
        }
        return true
    }
    
    func isAlphaNumeric() -> Bool {
        let alphaNumeric = NSCharacterSet.alphanumerics
        let output = self.unicodeScalars.split { !alphaNumeric.contains($0) }.map(String.init)
        if output.count == 1 {
            if output[0] != self {
                return false
            }
        }
        return output.count == 1
        //        return componentsSeparatedByCharactersInSet(alphaNumeric).joinWithSeparator("").length == 0
    }
    
    func isEmpty() -> Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).length == 0
    }
    
    func isNumeric() -> Bool {
        if defaultNumberFormatter().number(from: self) != nil {
            return true
        }
        return false
    }
    
    private func join<S: Sequence>(_ elements: S) -> String {
        return elements.map { String(describing: $0) }.joined(separator: self)
    }
    
    func latinize() -> String {
        return self.folding(options: .diacriticInsensitive, locale: .current)
        //        stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale.currentLocale())
    }
    
    func lines() -> [String] {
        return self.components(separatedBy: NSCharacterSet.newlines)
    }
    
    var length: Int {
        return self.count
    }
    
    func pad(_ n: Int, _ string: String = " ") -> String {
        return "".join([string.times(n), self, string.times(n)])
    }
    
    func padLeft(_ n: Int, _ string: String = " ") -> String {
        return "".join([string.times(n), self])
    }
    
    func padRight(_ n: Int, _ string: String = " ") -> String {
        return "".join([self, string.times(n)])
    }
    
    func slugify(withSeparator separator: Character = "-") -> String {
        let slugCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\(separator)")
        return latinize()
            .lowercased()
            .components(separatedBy: slugCharacterSet.inverted)
            .filter { $0 != "" }
            .joined(separator: String(separator))
    }
    
    /// split the string into a string array by white spaces
    func tokenize() -> [String] {
        return self.components(separatedBy: .whitespaces)
    }
    
    func split(_ separator: Character = " ") -> [String] {
        return self.split { $0 == separator }.map(String.init)
    }
    
    func startsWith(_ prefix: String) -> Bool {
        return hasPrefix(prefix)
    }
    
    func stripPunctuation() -> String {
        return components(separatedBy: .punctuationCharacters)
            .joined(separator: "")
            .components(separatedBy: " ")
            .filter { $0 != "" }
            .joined(separator: " ")
    }
    
    func times(_ n: Int) -> String {
        return (0..<n).reduce("") { (str1, str2) in str1 + self }
    }
    
    func toFloat() -> Float? {
        if let number = defaultNumberFormatter().number(from: self) {
            return number.floatValue
        }
        return nil
    }
    
    func toInt() -> Int? {
        if let number = defaultNumberFormatter().number(from: self) {
            return number.intValue
        }
        return nil
    }
    
    func toBool() -> Bool? {
        let trimmed = self.trimmed().lowercased()
        if Int(trimmed) != 0 {
            return true
        }
        switch trimmed {
        case "true", "yes", "1":
            return true
        case "false", "no", "0":
            return false
        default:
            return false
        }
    }
    
    func toDate(_ format: String = "yyyy-MM-dd") -> Date? {
        return dateFormatter(format).date(from: self) as Date?
    }
    
    func toDateTime(_ format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        return toDate(format)
    }
    
    func trimmedLeft() -> String {
        if let range = rangeOfCharacter(from: NSCharacterSet.whitespacesAndNewlines.inverted) {
            return String(self[range.lowerBound..<endIndex])
        }
        return self
    }
    
    func trimmedRight() -> String {
        if let range = rangeOfCharacter(from: NSCharacterSet.whitespacesAndNewlines.inverted, options: NSString.CompareOptions.backwards) {
            return String(self[startIndex..<range.upperBound])
        }
        return self
    }
    
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    subscript(r: Range<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: r.upperBound - r.lowerBound)
        return String(self[startIndex..<endIndex])
    }
    
    func substring(_ startIndex: Int, length: Int) -> String {
        
        let start = self.index(self.startIndex, offsetBy: startIndex)
        let end = self.index(self.startIndex, offsetBy: startIndex + length)
        return substring(with: start..<end)
    }
    
    func subsequence(_ startIndex: Int, endIndex: Int) -> String {
        let start = self.index(self.startIndex, offsetBy: startIndex)
        let end = self.index(self.startIndex, offsetBy: endIndex)
        
        return substring(with: start..<end)
    }
    
    subscript(i: Int) -> Character {
        let index = self.index(self.startIndex, offsetBy: i)
        return self[index]
    }
    
    //    /// get the left part of the string before the index
    //    func left(_ range:Range<String.Index>?) -> String {
    //        return self.substring(to: (range?.lowerBound)!)
    //    }
    //    /// get the right part of the string after the index
    //    func right(_ range:Range<String.Index>?) -> String {
    //        return self.substring(from: self.index((range?.lowerBound)!, offsetBy:1))
    //    }
    
}

public extension NSString {
    func substring(_ startIndex: Int, length: Int) -> NSString {
        return self.subsequence(startIndex, endIndex: startIndex + length)
    }
    
    func subsequence(_ startIndex: Int, endIndex: Int) -> NSString {
        return self.subsequence(startIndex, endIndex: endIndex)
    }
    
}

private enum ThreadLocalIdentifier {
    case dateFormatter(String)
    
    case defaultNumberFormatter
    case localeNumberFormatter(Locale)
    
    var objcDictKey: String {
        switch self {
        case .dateFormatter(let format):
            return "SS\(self)\(format)"
        case .localeNumberFormatter(let l):
            return "SS\(self)\(l.identifier)"
        default:
            return "SS\(self)"
        }
    }
}

private func threadLocalInstance<T: AnyObject>(_ identifier: ThreadLocalIdentifier, initialValue: @autoclosure () -> T) -> T {
    #if os(Linux)
    var storage = Thread.current.threadDictionary
    #else
    let storage = Thread.current.threadDictionary
    #endif
    let k = identifier.objcDictKey
    
    let instance: T = storage[k] as? T ?? initialValue()
    if storage[k] == nil {
        storage[k] = instance
    }
    
    return instance
}

private func dateFormatter(_ format: String) -> DateFormatter {
    return threadLocalInstance(.dateFormatter(format), initialValue: {
        let df = DateFormatter()
        df.dateFormat = format
        return df
    }())
}

private func defaultNumberFormatter() -> NumberFormatter {
    return threadLocalInstance(.defaultNumberFormatter, initialValue: NumberFormatter())
}

private func localeNumberFormatter(_ locale: Locale) -> NumberFormatter {
    return threadLocalInstance(.localeNumberFormatter(locale), initialValue: {
        let nf = NumberFormatter()
        nf.locale = locale
        return nf
    }())
}

public extension String {
    func isValidEmail() -> Bool {
        #if os(Linux)
        let regex = try? RegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        #else
        let regex = try? NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        #endif
        return regex?.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.length)) != nil
    }
    
}
