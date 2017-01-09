/* 
Copyright (c) 2017 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Foundation
 
/* For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar */

public class Channel {
	public var channel_id : Int?
	public var url : String?
	public var title : String?
	public var description : String?
	public var date_created : String?
	public var is_default : String?
	public var hide_suggest : String?
	public var show_unmoderated : String?
	public var nsfw : String?
	public var follower_count : Int?
	public var video_count : Int?
	public var full_url : String?
	public var avatar_url : String?
	public var cover_url : String?

/**
    Returns an array of models based on given dictionary.
    
    Sample usage:
    let channel_list = Channel.modelsFromDictionaryArray(someDictionaryArrayFromJSON)

    - parameter array:  NSArray from JSON dictionary.

    - returns: Array of Channel Instances.
*/
    public class func modelsFromDictionaryArray(array:NSArray) -> [Channel]
    {
        var models:[Channel] = []
        for item in array
        {
            models.append(Channel(dictionary: item as! NSDictionary)!)
        }
        return models
    }

/**
    Constructs the object based on the given dictionary.
    
    Sample usage:
    let channel = Channel(someDictionaryFromJSON)

    - parameter dictionary:  NSDictionary from JSON.

    - returns: Channel Instance.
*/
	required public init?(dictionary: NSDictionary) {

		channel_id = dictionary["channel_id"] as? Int
		url = dictionary["url"] as? String
		title = dictionary["title"] as? String
		description = dictionary["description"] as? String
		date_created = dictionary["date_created"] as? String
		is_default = dictionary["is_default"] as? String
		hide_suggest = dictionary["hide_suggest"] as? String
		show_unmoderated = dictionary["show_unmoderated"] as? String
		nsfw = dictionary["nsfw"] as? String
		follower_count = dictionary["follower_count"] as? Int
		video_count = dictionary["video_count"] as? Int
		full_url = dictionary["full_url"] as? String
		avatar_url = dictionary["avatar_url"] as? String
		cover_url = dictionary["cover_url"] as? String
	}

		
/**
    Returns the dictionary representation for the current instance.
    
    - returns: NSDictionary.
*/
	public func dictionaryRepresentation() -> NSDictionary {

		let dictionary = NSMutableDictionary()

		dictionary.setValue(self.channel_id, forKey: "channel_id")
		dictionary.setValue(self.url, forKey: "url")
		dictionary.setValue(self.title, forKey: "title")
		dictionary.setValue(self.description, forKey: "description")
		dictionary.setValue(self.date_created, forKey: "date_created")
		dictionary.setValue(self.is_default, forKey: "is_default")
		dictionary.setValue(self.hide_suggest, forKey: "hide_suggest")
		dictionary.setValue(self.show_unmoderated, forKey: "show_unmoderated")
		dictionary.setValue(self.nsfw, forKey: "nsfw")
		dictionary.setValue(self.follower_count, forKey: "follower_count")
		dictionary.setValue(self.video_count, forKey: "video_count")
		dictionary.setValue(self.full_url, forKey: "full_url")
		dictionary.setValue(self.avatar_url, forKey: "avatar_url")
		dictionary.setValue(self.cover_url, forKey: "cover_url")

		return dictionary
	}

}