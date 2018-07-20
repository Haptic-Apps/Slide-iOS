/* 
Copyright (c) 2016 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Foundation
 
/* For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar */

public class Images {
	public var hash: String?
	public var title: String?
	public var description: String?
	public var width: Int?
	public var height: Int?
	public var size: Int?
	public var ext: String?
	public var animated: String?
	public var prefer_video: String?
	public var looping: String?
	public var datetime: String?

/**
    Returns an array of models based on given dictionary.
    
    Sample usage:
    let images_list = Images.modelsFromDictionaryArray(someDictionaryArrayFromJSON)

    - parameter array:  NSArray from JSON dictionary.

    - returns: Array of Images Instances.
*/
    public class func modelsFromDictionaryArray(array: NSArray) -> [Images] {
        var models: [Images] = []
        for item in array {
            models.append(Images(dictionary: item as! NSDictionary)!)
        }
        return models
    }

/**
    Constructs the object based on the given dictionary.
    
    Sample usage:
    let images = Images(someDictionaryFromJSON)

    - parameter dictionary:  NSDictionary from JSON.

    - returns: Images Instance.
*/
	required public init?(dictionary: NSDictionary) {

		hash = dictionary["hash"] as? String
		title = dictionary["title"] as? String
		description = dictionary["description"] as? String
		width = dictionary["width"] as? Int
		height = dictionary["height"] as? Int
		size = dictionary["size"] as? Int
		ext = dictionary["ext"] as? String
		animated = dictionary["animated"] as? String
		prefer_video = dictionary["prefer_video"] as? String
		looping = dictionary["looping"] as? String
		datetime = dictionary["datetime"] as? String
	}
		
/**
    Returns the dictionary representation for the current instance.
    
    - returns: NSDictionary.
*/
	public func dictionaryRepresentation() -> NSDictionary {

		let dictionary = NSMutableDictionary()

		dictionary.setValue(self.hash, forKey: "hash")
		dictionary.setValue(self.title, forKey: "title")
		dictionary.setValue(self.description, forKey: "description")
		dictionary.setValue(self.width, forKey: "width")
		dictionary.setValue(self.height, forKey: "height")
		dictionary.setValue(self.size, forKey: "size")
		dictionary.setValue(self.ext, forKey: "ext")
		dictionary.setValue(self.animated, forKey: "animated")
		dictionary.setValue(self.prefer_video, forKey: "prefer_video")
		dictionary.setValue(self.looping, forKey: "looping")
		dictionary.setValue(self.datetime, forKey: "datetime")

		return dictionary
	}

}
