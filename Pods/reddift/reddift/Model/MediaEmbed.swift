//
//  MediaEmbed.swift
//  reddift
//
//  Created by sonson on 2015/04/21.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
Media represents the content which is embeded a link.
*/
public struct MediaEmbed {
	/// Height of content.
	let height: Int
	/// Width of content.
    let width: Int
	/// Information of content.
    let content: String
	/// Is content scrolled?
    let scrolling: Bool
	
    /**
    Update each property with JSON object.
    
    - parameter json: JSON object which is included "t2" JSON.
    */
    public init (json: JSONDictionary) {
		height = json["height"] as? Int ?? 0
        width = json["width"] as? Int ?? 0
		let tempContent = json["content"] as? String ?? ""
        content = tempContent.gtm_stringByUnescapingFromHTML()
		scrolling = json["scrolling"] as? Bool ?? false
    }
    
    var string: String {
        get {
            return "{content=\(content)\nsize=\(width)x\(height)}\n"
        }
    }
}
