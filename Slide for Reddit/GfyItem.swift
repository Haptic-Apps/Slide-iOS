/*
Copyright (c) 2017 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Foundation
 
/* For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar */

public class GfyItem {
	public var gfyId: String?
	public var gfyName: String?
	public var gfyNumber: Int?
	public var userName: String?
	public var width: Int?
	public var height: Int?
	public var frameRate: Int?
	public var numFrames: Int?
	public var mp4Url: String?
	public var webmUrl: String?
	public var webpUrl: String?
	public var mobileUrl: String?
	public var mobilePosterUrl: String?
	public var posterUrl: String?
	public var thumb360Url: String?
	public var thumb360PosterUrl: String?
	public var thumb100PosterUrl: String?
	public var max5mbGif: String?
	public var max2mbGif: String?
	public var mjpgUrl: String?
	public var gifUrl: String?
	public var gifSize: Int?
	public var mp4Size: Int?
	public var webmSize: Int?
	public var createDate: Int?
	public var views: Int?
	public var viewsNewEpoch: String?
	public var title: String?
	public var extraLemmas: String?
	public var md5: String?
	public var tags: [String]?
	public var userTags: [String]?
	public var nsfw: Int?
	public var sar: String?
	public var url: String?
	public var source: Int?
	public var dynamo: String?
	public var subreddit: String?
	public var redditId: String?
	public var redditIdText: String?
	public var likes: String?
	public var dislikes: String?
	public var published: String?
	public var description: String?
	public var copyrightClaimaint: String?
	public var languageText: String?
	public var fullDomainWhitelist: [String]?
	public var fullGeoWhitelist: [String]?
	public var iframeProfileImageVisible: String?

/**
    Returns an array of models based on given dictionary.
    
    Sample usage:
    let gfyItem_list = GfyItem.modelsFromDictionaryArray(someDictionaryArrayFromJSON)

    - parameter array:  NSArray from JSON dictionary.

    - returns: Array of GfyItem Instances.
*/
    public class func modelsFromDictionaryArray(array: NSArray) -> [GfyItem] {
        var models: [GfyItem] = []
        for item in array {
            models.append(GfyItem(dictionary: item as! NSDictionary)!)
        }
        return models
    }

/**
    Constructs the object based on the given dictionary.
    
    Sample usage:
    let gfyItem = GfyItem(someDictionaryFromJSON)

    - parameter dictionary:  NSDictionary from JSON.

    - returns: GfyItem Instance.
*/
	required public init?(dictionary: NSDictionary) {

		gfyId = dictionary["gfyId"] as? String
		gfyName = dictionary["gfyName"] as? String
		gfyNumber = dictionary["gfyNumber"] as? Int
		userName = dictionary["userName"] as? String
		width = dictionary["width"] as? Int
		height = dictionary["height"] as? Int
		frameRate = dictionary["frameRate"] as? Int
		numFrames = dictionary["numFrames"] as? Int
		mp4Url = dictionary["mp4Url"] as? String
		webmUrl = dictionary["webmUrl"] as? String
		webpUrl = dictionary["webpUrl"] as? String
		mobileUrl = dictionary["mobileUrl"] as? String
		mobilePosterUrl = dictionary["mobilePosterUrl"] as? String
		posterUrl = dictionary["posterUrl"] as? String
		thumb360Url = dictionary["thumb360Url"] as? String
		thumb360PosterUrl = dictionary["thumb360PosterUrl"] as? String
		thumb100PosterUrl = dictionary["thumb100PosterUrl"] as? String
		max5mbGif = dictionary["max5mbGif"] as? String
		max2mbGif = dictionary["max2mbGif"] as? String
		mjpgUrl = dictionary["mjpgUrl"] as? String
		gifUrl = dictionary["gifUrl"] as? String
		gifSize = dictionary["gifSize"] as? Int
		mp4Size = dictionary["mp4Size"] as? Int
		webmSize = dictionary["webmSize"] as? Int
		createDate = dictionary["createDate"] as? Int
		views = dictionary["views"] as? Int
		viewsNewEpoch = dictionary["viewsNewEpoch"] as? String
		title = dictionary["title"] as? String
		extraLemmas = dictionary["extraLemmas"] as? String
		md5 = dictionary["md5"] as? String
		nsfw = dictionary["nsfw"] as? Int
		sar = dictionary["sar"] as? String
		url = dictionary["url"] as? String
		source = dictionary["source"] as? Int
		dynamo = dictionary["dynamo"] as? String
		subreddit = dictionary["subreddit"] as? String
		redditId = dictionary["redditId"] as? String
		redditIdText = dictionary["redditIdText"] as? String
		likes = dictionary["likes"] as? String
		dislikes = dictionary["dislikes"] as? String
		published = dictionary["published"] as? String
		description = dictionary["description"] as? String
		copyrightClaimaint = dictionary["copyrightClaimaint"] as? String
		languageText = dictionary["languageText"] as? String
		iframeProfileImageVisible = dictionary["iframeProfileImageVisible"] as? String
	}
		
/**
    Returns the dictionary representation for the current instance.
    
    - returns: NSDictionary.
*/
	public func dictionaryRepresentation() -> NSDictionary {

		let dictionary = NSMutableDictionary()

		dictionary.setValue(self.gfyId, forKey: "gfyId")
		dictionary.setValue(self.gfyName, forKey: "gfyName")
		dictionary.setValue(self.gfyNumber, forKey: "gfyNumber")
		dictionary.setValue(self.userName, forKey: "userName")
		dictionary.setValue(self.width, forKey: "width")
		dictionary.setValue(self.height, forKey: "height")
		dictionary.setValue(self.frameRate, forKey: "frameRate")
		dictionary.setValue(self.numFrames, forKey: "numFrames")
		dictionary.setValue(self.mp4Url, forKey: "mp4Url")
		dictionary.setValue(self.webmUrl, forKey: "webmUrl")
		dictionary.setValue(self.webpUrl, forKey: "webpUrl")
		dictionary.setValue(self.mobileUrl, forKey: "mobileUrl")
		dictionary.setValue(self.mobilePosterUrl, forKey: "mobilePosterUrl")
		dictionary.setValue(self.posterUrl, forKey: "posterUrl")
		dictionary.setValue(self.thumb360Url, forKey: "thumb360Url")
		dictionary.setValue(self.thumb360PosterUrl, forKey: "thumb360PosterUrl")
		dictionary.setValue(self.thumb100PosterUrl, forKey: "thumb100PosterUrl")
		dictionary.setValue(self.max5mbGif, forKey: "max5mbGif")
		dictionary.setValue(self.max2mbGif, forKey: "max2mbGif")
		dictionary.setValue(self.mjpgUrl, forKey: "mjpgUrl")
		dictionary.setValue(self.gifUrl, forKey: "gifUrl")
		dictionary.setValue(self.gifSize, forKey: "gifSize")
		dictionary.setValue(self.mp4Size, forKey: "mp4Size")
		dictionary.setValue(self.webmSize, forKey: "webmSize")
		dictionary.setValue(self.createDate, forKey: "createDate")
		dictionary.setValue(self.views, forKey: "views")
		dictionary.setValue(self.viewsNewEpoch, forKey: "viewsNewEpoch")
		dictionary.setValue(self.title, forKey: "title")
		dictionary.setValue(self.extraLemmas, forKey: "extraLemmas")
		dictionary.setValue(self.md5, forKey: "md5")
		dictionary.setValue(self.nsfw, forKey: "nsfw")
		dictionary.setValue(self.sar, forKey: "sar")
		dictionary.setValue(self.url, forKey: "url")
		dictionary.setValue(self.source, forKey: "source")
		dictionary.setValue(self.dynamo, forKey: "dynamo")
		dictionary.setValue(self.subreddit, forKey: "subreddit")
		dictionary.setValue(self.redditId, forKey: "redditId")
		dictionary.setValue(self.redditIdText, forKey: "redditIdText")
		dictionary.setValue(self.likes, forKey: "likes")
		dictionary.setValue(self.dislikes, forKey: "dislikes")
		dictionary.setValue(self.published, forKey: "published")
		dictionary.setValue(self.description, forKey: "description")
		dictionary.setValue(self.copyrightClaimaint, forKey: "copyrightClaimaint")
		dictionary.setValue(self.languageText, forKey: "languageText")
		dictionary.setValue(self.iframeProfileImageVisible, forKey: "iframeProfileImageVisible")

		return dictionary
	}

}
