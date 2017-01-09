/* 
Copyright (c) 2017 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Foundation
 
/* For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar */

public class GfycatCheck {
	public var urlKnown : String?
	public var gfyUrl : String?
	public var webmUrl : String?
	public var mp4Url : String?
	public var gifUrl : String?
	public var frameRate : Int?
	public var gfyName : String?

/**
    Returns an array of models based on given dictionary.
    
    Sample usage:
    let json4Swift_Base_list = Json4Swift_Base.modelsFromDictionaryArray(someDictionaryArrayFromJSON)

    - parameter array:  NSArray from JSON dictionary.

    - returns: Array of Json4Swift_Base Instances.
*/
    public class func modelsFromDictionaryArray(array:NSArray) -> [GfycatCheck]
    {
        var models:[GfycatCheck] = []
        for item in array
        {
            models.append(GfycatCheck(dictionary: item as! NSDictionary)!)
        }
        return models
    }

/**
    Constructs the object based on the given dictionary.
    
    Sample usage:
    let json4Swift_Base = Json4Swift_Base(someDictionaryFromJSON)

    - parameter dictionary:  NSDictionary from JSON.

    - returns: Json4Swift_Base Instance.
*/
	required public init?(dictionary: NSDictionary) {

		urlKnown = dictionary["urlKnown"] as? String
		gfyUrl = dictionary["gfyUrl"] as? String
		webmUrl = dictionary["webmUrl"] as? String
		mp4Url = dictionary["mp4Url"] as? String
		gifUrl = dictionary["gifUrl"] as? String
		frameRate = dictionary["frameRate"] as? Int
		gfyName = dictionary["gfyName"] as? String
	}

		
/**
    Returns the dictionary representation for the current instance.
    
    - returns: NSDictionary.
*/
	public func dictionaryRepresentation() -> NSDictionary {

		let dictionary = NSMutableDictionary()

		dictionary.setValue(self.urlKnown, forKey: "urlKnown")
		dictionary.setValue(self.gfyUrl, forKey: "gfyUrl")
		dictionary.setValue(self.webmUrl, forKey: "webmUrl")
		dictionary.setValue(self.mp4Url, forKey: "mp4Url")
		dictionary.setValue(self.gifUrl, forKey: "gifUrl")
		dictionary.setValue(self.frameRate, forKey: "frameRate")
		dictionary.setValue(self.gfyName, forKey: "gfyName")

		return dictionary
	}

}
