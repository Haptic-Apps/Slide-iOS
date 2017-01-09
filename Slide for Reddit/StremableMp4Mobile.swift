/* 
Copyright (c) 2017 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Foundation
 
/* For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar */

public class StremableMp4Mobile {
	public var status : Int?
	public var width : Int?
	public var url : String?
	public var bitrate : Int?
	public var duration : Int?
	public var size : Int?
	public var framerate : Int?
	public var height : Int?

/**
    Returns an array of models based on given dictionary.
    
    Sample usage:
    let mp4-mobile_list = Mp4-mobile.modelsFromDictionaryArray(someDictionaryArrayFromJSON)

    - parameter array:  NSArray from JSON dictionary.

    - returns: Array of Mp4-mobile Instances.
*/
    public class func modelsFromDictionaryArray(array:NSArray) -> [StremableMp4Mobile]
    {
        var models:[StremableMp4Mobile] = []
        for item in array
        {
            models.append(StremableMp4Mobile(dictionary: item as! NSDictionary)!)
        }
        return models
    }

/**
    Constructs the object based on the given dictionary.
    
    Sample usage:
    let mp4-mobile = Mp4-mobile(someDictionaryFromJSON)

    - parameter dictionary:  NSDictionary from JSON.

    - returns: Mp4-mobile Instance.
*/
	required public init?(dictionary: NSDictionary) {

		status = dictionary["status"] as? Int
		width = dictionary["width"] as? Int
		url = dictionary["url"] as? String
		bitrate = dictionary["bitrate"] as? Int
		duration = dictionary["duration"] as? Int
		size = dictionary["size"] as? Int
		framerate = dictionary["framerate"] as? Int
		height = dictionary["height"] as? Int
	}

		
/**
    Returns the dictionary representation for the current instance.
    
    - returns: NSDictionary.
*/
	public func dictionaryRepresentation() -> NSDictionary {

		let dictionary = NSMutableDictionary()

		dictionary.setValue(self.status, forKey: "status")
		dictionary.setValue(self.width, forKey: "width")
		dictionary.setValue(self.url, forKey: "url")
		dictionary.setValue(self.bitrate, forKey: "bitrate")
		dictionary.setValue(self.duration, forKey: "duration")
		dictionary.setValue(self.size, forKey: "size")
		dictionary.setValue(self.framerate, forKey: "framerate")
		dictionary.setValue(self.height, forKey: "height")

		return dictionary
	}

}
