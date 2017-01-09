//
//  Oembed.swift
//  reddift
//
//  Created by sonson on 2015/04/20.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
Media represents the content which is embeded a link.
*/
public struct Oembed {
    /**
    example, "http://i.imgur.com",
    */
    public let providerUrl: String
    /**
    example, "The Internet's visual storytelling community. Explore, share, and discuss the best visual stories the Internet has to offer.",
    */
    public let description: String
    /**
    example, "Imgur GIF",
    */
    public let title: String
    /**
    example, 245,
    */
    public let thumbnailWidth: Int
    /**
    example, 333,
    */
    public let height: Int
    /**
    example, 245,
    */
    public let width: Int
    /**
    example, "&lt;iframe class=\"embedly-embed\" src=\"//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fi.imgur.com%2FkhgfcrQ.mp4&amp;src_secure=1&amp;url=http%3A%2F%2Fi.imgur.com%2FkhgfcrQ.gifv&amp;image=http%3A%2F%2Fi.imgur.com%2FkhgfcrQ.gif&amp;key=2aa3c4d5f3de4f5b9120b660ad850dc9&amp;type=video%2Fmp4&amp;schema=imgur\" width=\"245\" height=\"333\" scrolling=\"no\" frameborder=\"0\" allowfullscreen&gt;&lt;/iframe&gt;",
    */
    public let html: String
    /**
    example, "1.0",
    */
    public let version: String
    /**
    example, "Imgur",
    */
    public let providerName: String
    /**
    example, "http://i.imgur.com/khgfcrQ.gif",
    */
    public let thumbnailUrl: String
    /**
    example, "video",
    */
    public let type: String
    /**
    example, 333
    */
    public let thumbnailHeight: Int
    /**
    Update each property with JSON object.
    
    - parameter json: JSON object which is included "t2" JSON.
    */
    public init (json: JSONDictionary) {
		self.providerUrl = json["provider_url"] as? String ?? ""
		self.description = json["description"] as? String ?? ""
		self.title = json["title"] as? String ?? ""
		self.thumbnailWidth = json["thumbnail_width"] as? Int ?? 0
		self.height = json["height"] as? Int ?? 0
		self.width = json["width"] as? Int ?? 0
        let tempHtml = json["html"] as? String ?? ""
        self.html = tempHtml.gtm_stringByUnescapingFromHTML()
		self.version = json["version"] as? String ?? ""
		self.providerName = json["provider_name"] as? String ?? ""
		self.thumbnailUrl = json["thumbnail_url"] as? String ?? ""
		self.type = json["type"] as? String ?? ""
		self.thumbnailHeight = json["thumbnail_height"] as? Int ?? 0
    }
}
