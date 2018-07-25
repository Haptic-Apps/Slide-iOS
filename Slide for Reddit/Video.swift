/*
Copyright (c) 2017 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Foundation
 
/* For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar */

public class Video {
	public var video_id: Int?
	public var url: String?
	public var full_url: String?
	public var embed_url: String?
	public var user_id: String?
	public var complete: String?
	public var complete_url: String?
	public var state: String?
	public var title: String?
	public var description: String?
	public var duration: Double?
	public var height: Int?
	public var width: Int?
	public var date_created: String?
	public var date_stored: String?
	public var date_completed: String?
	public var comment_count: Int?
	public var view_count: Int?
	public var share_count: Int?
	public var version: Int?
	public var nsfw: String?
	public var thumbnail: String?
	public var thumbnail_url: String?
	public var thumbnail_gif: String?
	public var thumbnail_gif_url: String?
	public var storyboard: String?
	public var score: Int?
	public var likes_count: Int?
	public var channel_id: Int?
	public var source: String?
	public var priv: String?
	public var latitude: Int?
	public var longitude: Int?
	public var place_id: String?
	public var place_name: String?
	public var colors: String?
	public var reddit_link: String?
	public var youtube_override_source: String?
	public var is_featured: String?
	public var date_featured: String?
	public var score_modifier: Int?
	public var channel: Channel?
	public var formats: Array<Formats>?

/**
    Returns an array of models based on given dictionary.
    
    Sample usage:
    let video_list = Video.modelsFromDictionaryArray(someDictionaryArrayFromJSON)

    - parameter array:  NSArray from JSON dictionary.

    - returns: Array of Video Instances.
*/
    public class func modelsFromDictionaryArray(array: NSArray) -> [Video] {
        var models: [Video] = []
        for item in array {
            models.append(Video(dictionary: item as! NSDictionary)!)
        }
        return models
    }

/**
    Constructs the object based on the given dictionary.
    
    Sample usage:
    let video = Video(someDictionaryFromJSON)

    - parameter dictionary:  NSDictionary from JSON.

    - returns: Video Instance.
*/
	required public init?(dictionary: NSDictionary) {

		video_id = dictionary["video_id"] as? Int
		url = dictionary["url"] as? String
		full_url = dictionary["full_url"] as? String
		embed_url = dictionary["embed_url"] as? String
		user_id = dictionary["user_id"] as? String
		complete = dictionary["complete"] as? String
		complete_url = dictionary["complete_url"] as? String
		state = dictionary["state"] as? String
		title = dictionary["title"] as? String
		description = dictionary["description"] as? String
		duration = dictionary["duration"] as? Double
		height = dictionary["height"] as? Int
		width = dictionary["width"] as? Int
		date_created = dictionary["date_created"] as? String
		date_stored = dictionary["date_stored"] as? String
		date_completed = dictionary["date_completed"] as? String
		comment_count = dictionary["comment_count"] as? Int
		view_count = dictionary["view_count"] as? Int
		share_count = dictionary["share_count"] as? Int
		version = dictionary["version"] as? Int
		nsfw = dictionary["nsfw"] as? String
		thumbnail = dictionary["thumbnail"] as? String
		thumbnail_url = dictionary["thumbnail_url"] as? String
		thumbnail_gif = dictionary["thumbnail_gif"] as? String
		thumbnail_gif_url = dictionary["thumbnail_gif_url"] as? String
		storyboard = dictionary["storyboard"] as? String
		score = dictionary["score"] as? Int
		likes_count = dictionary["likes_count"] as? Int
		channel_id = dictionary["channel_id"] as? Int
		source = dictionary["source"] as? String
		priv = dictionary["private"] as? String
		latitude = dictionary["latitude"] as? Int
		longitude = dictionary["longitude"] as? Int
		place_id = dictionary["place_id"] as? String
		place_name = dictionary["place_name"] as? String
		colors = dictionary["colors"] as? String
		reddit_link = dictionary["reddit_link"] as? String
		youtube_override_source = dictionary["youtube_override_source"] as? String
		is_featured = dictionary["is_featured"] as? String
		date_featured = dictionary["date_featured"] as? String
		score_modifier = dictionary["score_modifier"] as? Int
		if dictionary["channel"] != nil { channel = Channel(dictionary: dictionary["channel"] as! NSDictionary) }
		if dictionary["formats"] != nil { formats = Formats.modelsFromDictionaryArray(array: dictionary["formats"] as! NSArray) }
	}
		
/**
    Returns the dictionary representation for the current instance.
    
    - returns: NSDictionary.
*/
	public func dictionaryRepresentation() -> NSDictionary {

		let dictionary = NSMutableDictionary()

		dictionary.setValue(self.video_id, forKey: "video_id")
		dictionary.setValue(self.url, forKey: "url")
		dictionary.setValue(self.full_url, forKey: "full_url")
		dictionary.setValue(self.embed_url, forKey: "embed_url")
		dictionary.setValue(self.user_id, forKey: "user_id")
		dictionary.setValue(self.complete, forKey: "complete")
		dictionary.setValue(self.complete_url, forKey: "complete_url")
		dictionary.setValue(self.state, forKey: "state")
		dictionary.setValue(self.title, forKey: "title")
		dictionary.setValue(self.description, forKey: "description")
		dictionary.setValue(self.duration, forKey: "duration")
		dictionary.setValue(self.height, forKey: "height")
		dictionary.setValue(self.width, forKey: "width")
		dictionary.setValue(self.date_created, forKey: "date_created")
		dictionary.setValue(self.date_stored, forKey: "date_stored")
		dictionary.setValue(self.date_completed, forKey: "date_completed")
		dictionary.setValue(self.comment_count, forKey: "comment_count")
		dictionary.setValue(self.view_count, forKey: "view_count")
		dictionary.setValue(self.share_count, forKey: "share_count")
		dictionary.setValue(self.version, forKey: "version")
		dictionary.setValue(self.nsfw, forKey: "nsfw")
		dictionary.setValue(self.thumbnail, forKey: "thumbnail")
		dictionary.setValue(self.thumbnail_url, forKey: "thumbnail_url")
		dictionary.setValue(self.thumbnail_gif, forKey: "thumbnail_gif")
		dictionary.setValue(self.thumbnail_gif_url, forKey: "thumbnail_gif_url")
		dictionary.setValue(self.storyboard, forKey: "storyboard")
		dictionary.setValue(self.score, forKey: "score")
		dictionary.setValue(self.likes_count, forKey: "likes_count")
		dictionary.setValue(self.channel_id, forKey: "channel_id")
		dictionary.setValue(self.source, forKey: "source")
		dictionary.setValue(self.priv, forKey: "private")
		dictionary.setValue(self.latitude, forKey: "latitude")
		dictionary.setValue(self.longitude, forKey: "longitude")
		dictionary.setValue(self.place_id, forKey: "place_id")
		dictionary.setValue(self.place_name, forKey: "place_name")
		dictionary.setValue(self.colors, forKey: "colors")
		dictionary.setValue(self.reddit_link, forKey: "reddit_link")
		dictionary.setValue(self.youtube_override_source, forKey: "youtube_override_source")
		dictionary.setValue(self.is_featured, forKey: "is_featured")
		dictionary.setValue(self.date_featured, forKey: "date_featured")
		dictionary.setValue(self.score_modifier, forKey: "score_modifier")
		dictionary.setValue(self.channel?.dictionaryRepresentation(), forKey: "channel")

		return dictionary
	}

}
