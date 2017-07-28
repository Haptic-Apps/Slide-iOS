//
//  Link.swift
//  reddift
//
//  Created by generator.rb via from https://github.com/reddit/reddit/wiki/JSON
//  Created at 2015-04-15 11:23:32 +0900
//

import Foundation

/**
 Returns string by replacing NOT ASCII characters with a percent escaped string using UTF8.
 If an argument is nil, returns vacant string.
 */
private func convertObjectToEscapedURLString(_ object: AnyObject?) -> String {
    if let urlstring = object as? String {
        return urlstring.addPercentEncoding
    } else {
        return ""
    }
}

/**
 Link content.
 */
public struct Link: Thing {
    /// identifier of Thing like 15bfi0.
    public let id: String
    /// name of Thing, that is fullname, like t3_15bfi0.
    public let name: String
    /// type of Thing, like t3.
    public static let kind = "t3"
    
    /**
     example: self.redditdev
     */
    public let domain: String
    /**
     example:
     */
    public let bannedBy: String
    /**
     Used for streaming video. Technical embed specific information is found here.
     example: {}
     */
    public let mediaEmbed: MediaEmbed?
    /**
     subreddit of thing excluding the /r/ prefix. "pics"
     example: redditdev
     */
    public let subreddit: String
    /**
     the formatted escaped HTML text.  this is the HTML formatted version of the marked up text.  Items that are boldened by ** or *** will now have &lt;em&gt; or *** tags on them. Additionally, bullets and numbered lists will now be in HTML list format. NOTE: The HTML string will be escaped.  You must unescape to get the raw HTML. Null if not present.
     example: &lt;!-- SC_OFF --&gt;&lt;div class="md"&gt;&lt;p&gt;So this is the code I ran:&lt;/p&gt;
     &lt;pre&gt;&lt;code&gt;r = praw.Reddit(&amp;quot;/u/habnpam sflkajsfowifjsdlkfj test test test&amp;quot;)
     for c in praw.helpers.comment_stream(reddit_session=r, subreddit=&amp;quot;helpmefind&amp;quot;, limit=500, verbosity=1):
     print(c.author)
     &lt;/code&gt;&lt;/pre&gt;
     &lt;hr/&gt;
     &lt;p&gt;From what I understand, comment_stream() gets the most recent comments. So if we specify the limit to be 100, it will initially get the 100 newest comment, and then constantly update to get new comments.  It seems to works appropriately for every subreddit except &lt;a href="/r/helpmefind"&gt;/r/helpmefind&lt;/a&gt;. For &lt;a href="/r/helpmefind"&gt;/r/helpmefind&lt;/a&gt;, it fetches around 30 comments, regardless of the limit.&lt;/p&gt;
     &lt;/div&gt;&lt;!-- SC_ON --&gt;
     */
    public let selftextHtml: String
    /**
     the raw text.  this is the unformatted text which includes the raw markup characters such as ** for bold. &lt;, &gt;, and &amp; are escaped. Empty if not present.
     example: So this is the code I ran:
     r = praw.Reddit("/u/habnpam sflkajsfowifjsdlkfj test test test")
     for c in praw.helpers.comment_stream(reddit_session=r, subreddit="helpmefind", limit=500, verbosity=1):
     print(c.author)
     ---
     From what I understand, comment_stream() gets the most recent comments. So if we specify the limit to be 100, it will initially get the 100 newest comment, and then constantly update to get new comments.  It seems to works appropriately for every subreddit except /r/helpmefind. For /r/helpmefind, it fetches around 30 comments, regardless of the limit.
     */
    public let selftext: String
    /**
     how the logged-in user has voted on the link - True = upvoted, False = downvoted, null = no vote
     example:
     */
    public let likes: VoteDirection
    /**
     example: []
     */
    public let userReports: [AnyObject]
    /**
     example:
     */
    public let secureMedia: AnyObject?
    /**
     the text of the link's flair.
     example:
     */
    public let linkFlairText: String
    /**
     example: 0
     */
    public let gilded: Int
    /**
     example: false
     */
    public let archived: Bool
    public let locked: Bool
    /**
     probably always returns false
     example: false
     */
    public let clicked: Bool
    /**
     example:
     */
    public let reportReasons: [AnyObject]
    /**
     the account name of the poster. null if this is a promotional link
     example: habnpam
     */
    public let author: String
    /**
     the number of comments that belong to this link. includes removed comments.
     example: 10
     */
    public let numComments: Int
    /**
     the net-score of the link.  note: A submission's score is simply the number of upvotes minus the number of downvotes. If five users like the submission and three users don't it will have a score of 2. Please note that the vote numbers are not "real" numbers, they have been "fuzzed" to prevent spam bots etc. So taking the above example, if five users upvoted the submission, and three users downvote it, the upvote/downvote numbers may say 23 upvotes and 21 downvotes, or 12 upvotes, and 10 downvotes. The points score is correct, but the vote totals are "fuzzed".
     example: 2
     */
    public let score: Int
    /**
     example:
     */
    public let approvedBy: String
    /**
     true if the post is tagged as NSFW.  False if otherwise
     example: false
     */
    public let over18: Bool
    /**
     true if the post is hidden by the logged in user.  false if not logged in or not hidden.
     example: false
     */
    public let hidden: Bool
    /**
     full URL to the thumbnail for this link; "self" if this is a self post; "default" if a thumbnail is not available
     example:
     */
    public let thumbnail: String
    public let baseJson: JSONDictionary
    /**
     the id of the subreddit in which the thing is located
     example: t5_2qizd
     */
    public let subredditId: String
    /**
     example: false
     */
    public let edited: Int
    /**
     the CSS class of the link's flair.
     example:
     */
    public let linkFlairCssClass: String
    /**
     the CSS class of the author's flair.  subreddit specific
     example:
     */
    public let authorFlairCssClass: String
    /**
     example: 0
     */
    public let downs: Int
    /**
     example: []
     */
    public let modReports: [AnyObject]
    /**
     example:
     */
    public let secureMediaEmbed: AnyObject?
    /**
     true if this post is saved by the logged in user
     example: false
     */
    public let saved: Bool
    /**
     true if this link is a selfpost
     example: true
     */
    public let isSelf: Bool
    /**
     relative URL of the permanent link for this link
     example: /r/redditdev/comments/32wnhw/praw_comment_stream_messes_up_when_getting/
     */
    public let permalink: String
    /**
     true if the post is set as the sticky in its subreddit.
     example: false
     */
    public let stickied: Bool
    /**
     example: 1429292148
     */
    public let created: Int
    /**
     the link of this post.  the permalink if this is a self-post
     example: http://www.reddit.com/r/redditdev/comments/32wnhw/praw_comment_stream_messes_up_when_getting/
     */
    public let url: URL?
    /**
     the text of the author's flair.  subreddit specific
     example:
     */
    public let authorFlairText: String
    /**
     the title of the link. may contain newlines for some reason
     example: [PRAW] comment_stream() messes up when getting comments from a certain subreddit.
     */
    public let title: String
    /**
     example: 1429263348
     */
    public let createdUtc: Int
    /**
     example: 2
     */
    public let ups: Int
    /**
     example: 0.75
     */
    public let upvoteRatio: Double
    /**
     Used for streaming video. Detailed information about the video and it's origins are placed here
     example:
     */
    public let media: Media?
    /**
     example: false
     */
    public let visited: Bool
    /**
     example: 0
     */
    public let numReports: Int
    /**
     example: false
     */
    public let distinguished: String
    
    public init(id: String) {
        self.id = id
        self.name = "\(Link.kind)_\(self.id)"
        
        domain = ""
        bannedBy = ""
        subreddit = ""
        selftextHtml = ""
        selftext = ""
        likes = .none
        linkFlairText = ""
        gilded = 0
        archived = false
        locked = false
        clicked = false
        author = ""
        numComments = 0
        score = 0
        approvedBy = ""
        over18 = false
        hidden = false
        thumbnail = ""
        subredditId = ""
        edited = 0
        linkFlairCssClass = ""
        authorFlairCssClass = ""
        downs = 0
        saved = false
        isSelf = false
        permalink = ""
        stickied = false
        created = 0
        url = URL.init(string: "")
        authorFlairText = ""
        title = ""
        createdUtc = 0
        ups = 0
        upvoteRatio = 0
        visited = false
        numReports = 0
        distinguished = ""
        media = Media(json: [:])
        mediaEmbed = MediaEmbed(json: [:])
        
        userReports = []
        secureMedia = nil
        reportReasons = []
        modReports = []
        secureMediaEmbed = nil
        
        baseJson = JSONDictionary.init()
    }
    
    /**
     Parse t3 object.
     
     - parameter data: Dictionary, must be generated parsing "t3".
     - returns: Link object as Thing.
     */
    public init(json data: JSONDictionary) {
        baseJson = data
        id = data["id"] as? String ?? ""
        domain = data["domain"] as? String ?? ""
        bannedBy = data["banned_by"] as? String ?? ""
        subreddit = data["subreddit"] as? String ?? ""
        let tempSelftextHtml = data["selftext_html"] as? String ?? ""
        selftextHtml = tempSelftextHtml.gtm_stringByUnescapingFromHTML()
        let tempSelftext = data["selftext"] as? String ?? ""
        selftext = tempSelftext.gtm_stringByUnescapingFromHTML()
        if let temp = data["likes"] as? Bool {
            likes = temp ? .up : .down
        } else {
            likes = .none
        }
        
        let tempFlair = data["link_flair_text"] as? String ?? ""
        linkFlairText = tempFlair.gtm_stringByUnescapingFromHTML()
        
        gilded = data["gilded"] as? Int ?? 0
        archived = data["archived"] as? Bool ?? false
        locked = data["locked"] as? Bool ?? false
        clicked = data["clicked"] as? Bool ?? false
        author = data["author"] as? String ?? ""
        numComments = data["num_comments"] as? Int ?? 0
        score = data["score"] as? Int ?? 0
        approvedBy = data["approved_by"] as? String ?? ""
        over18 = data["over_18"] as? Bool ?? false
        hidden = data["hidden"] as? Bool ?? false
        thumbnail = convertObjectToEscapedURLString(data["thumbnail"])
        subredditId = data["subreddit_id"] as? String ?? ""
        edited = data["edited"] as? Int ?? 0
        linkFlairCssClass = data["link_flair_css_class"] as? String ?? ""
        authorFlairCssClass = data["author_flair_css_class"] as? String ?? ""
        downs = data["downs"] as? Int ?? 0
        saved = data["saved"] as? Bool ?? false
        isSelf = data["is_self"] as? Bool ?? false
        let tempName = data["name"] as? String ?? ""
        name = tempName.gtm_stringByUnescapingFromHTML()
        permalink = data["permalink"] as? String ?? ""
        stickied = data["stickied"] as? Bool ?? false
        created = data["created"] as? Int ?? 0
        
        var tempUrl = data["url"] as? String ?? ""
        tempUrl = tempUrl.gtm_stringByEscapingForHTML()
        url = URL.init(string: tempUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        
        authorFlairText = data["author_flair_text"] as? String ?? ""
        let tempTitle = data["title"] as? String ?? ""
        title = tempTitle.gtm_stringByUnescapingFromHTML()

        createdUtc = data["created_utc"] as? Int ?? 0
        ups = data["ups"] as? Int ?? 0
        upvoteRatio = data["upvote_ratio"] as? Double ?? 0
        visited = data["visited"] as? Bool ?? false
        numReports = data["num_reports"] as? Int ?? 0
        distinguished = data["distinguished"] as? String ?? ""
        media = Media(json: data["media"] as? JSONDictionary ?? [:])
        mediaEmbed = MediaEmbed(json: data["media_embed"] as? JSONDictionary ?? [:])
        
        userReports = []
        secureMedia = nil
        reportReasons = []
        modReports = []
        secureMediaEmbed = nil
    }
}
