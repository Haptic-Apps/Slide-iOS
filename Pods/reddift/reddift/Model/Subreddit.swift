//
//  Subreddit.swift
//  reddift
//
//  Created by generator.rb via from https://github.com/reddit/reddit/wiki/JSON
//  Created at 2015-04-15 11:23:32 +0900
//

import Foundation

/// Protocol to integrate a code for subreddit and multireddit.
public protocol SubredditURLPath {
    var path: String {get}
}

/**
Subreddit object.
*/
public struct Subreddit: SubredditURLPath, Thing {
    /// identifier of Thing like 15bfi0.
    public let id: String
    /// name of Thing, that is fullname, like t3_15bfi0.
    public let name: String
    /// type of Thing, like t3.
    public static let kind = "t5"
    
    /**
    
    example:
    */
    public let bannerImg: String
    public let keyColor: String

    /**
    
    example: true
    */
    public let userSrThemeEnabled: Bool
    /**
    
    example: &lt;!-- SC_OFF --&gt;&lt;div class="md"&gt;&lt;p&gt;&lt;strong&gt;GIFs are banned.&lt;/strong&gt;
    If you want to post a GIF, please &lt;a href="http://imgur.com"&gt;rehost it as a GIFV&lt;/a&gt; instead. &lt;a href="http://www.reddit.com/r/woahdude/wiki/html5"&gt;(Read more)&lt;/a&gt;&lt;/p&gt;
    
    &lt;p&gt;&lt;strong&gt;Link flair is mandatory.&lt;/strong&gt;
    Click &amp;quot;Add flair&amp;quot; button after you submit. The button will be located under your post title. &lt;a href="http://www.reddit.com/r/woahdude/wiki/index#wiki_flair_is_mandatory"&gt;(read more)&lt;/a&gt;&lt;/p&gt;
    
    &lt;p&gt;&lt;strong&gt;XPOST labels are banned.&lt;/strong&gt;
    Crossposts are fine, just don&amp;#39;t label them as such. &lt;a href="http://www.reddit.com/r/woahdude/wiki/index#wiki_.5Bxpost.5D_tags.2Flabels_are_banned"&gt;(read more)&lt;/a&gt;&lt;/p&gt;
    
    &lt;p&gt;&lt;strong&gt;Trippy or Mesmerizing content only!&lt;/strong&gt;
    What is WoahDude-worthy content? &lt;a href="http://www.reddit.com/r/woahdude/wiki/index#wiki_what_is_.22woahdude_material.22.3F"&gt;(Read more)&lt;/a&gt;&lt;/p&gt;
    &lt;/div&gt;&lt;!-- SC_ON --&gt;
    */
    public let submitTextHtml: String
    /**
    whether the logged-in user is banned from the subreddit
    example: false
    */
    public let userIsBanned: Bool
    /**
    
    example: **GIFs are banned.**
    If you want to post a GIF, please [rehost it as a GIFV](http://imgur.com) instead. [(Read more)](http://www.reddit.com/r/woahdude/wiki/html5)
    
    **Link flair is mandatory.**
    Click "Add flair" button after you submit. The button will be located under your post title. [(read more)](http://www.reddit.com/r/woahdude/wiki/index#wiki_flair_is_mandatory)
    
    **XPOST labels are banned.**
    Crossposts are fine, just don't label them as such. [(read more)](http://www.reddit.com/r/woahdude/wiki/index#wiki_.5Bxpost.5D_tags.2Flabels_are_banned)
    
    **Trippy or Mesmerizing content only!**
    What is WoahDude-worthy content? [(Read more)](http://www.reddit.com/r/woahdude/wiki/index#wiki_what_is_.22woahdude_material.22.3F)
    */
    public let submitText: String
    /**
    human name of the subreddit
    example: woahdude
    */
    public let displayName: String
    /**
    full URL to the header image, or null
    example: http://b.thumbs.redditmedia.com/fnO6IreM4s_Em4dTIU2HtmZ_NTw7dZdlCoaLvtKwbzM.png
    */
    public let headerImg: String
    /**
    sidebar text, escaped HTML format
    example: &lt;!-- SC_OFF --&gt;&lt;div class="md"&gt;&lt;h5&gt;&lt;a href="https://www.reddit.com/r/woahdude/comments/2qi1jh/best_of_rwoahdude_2014_results/?"&gt;Best of WoahDude 2014 ⇦&lt;/a&gt;&lt;/h5&gt;
    
    &lt;p&gt;&lt;a href="#nyanbro"&gt;&lt;/a&gt;&lt;/p&gt;
    
    &lt;h4&gt;&lt;strong&gt;What is WoahDude?&lt;/strong&gt;&lt;/h4&gt;
    
    &lt;p&gt;&lt;em&gt;The best links to click while you&amp;#39;re stoned!&lt;/em&gt; &lt;/p&gt;
    
    &lt;p&gt;Trippy &amp;amp; mesmerizing games, video, audio &amp;amp; images that make you go &amp;#39;woah dude!&amp;#39;&lt;/p&gt;
    
    &lt;p&gt;No one wants to have to sift through the entire internet for fun links when they&amp;#39;re stoned - so make this your one-stop shop!&lt;/p&gt;
    
    &lt;p&gt;⇨ &lt;a href="http://www.reddit.com/r/woahdude/wiki/index#wiki_what_is_.22woahdude_material.22.3F"&gt;more in-depth explanation here&lt;/a&gt; ⇦&lt;/p&gt;
    
    &lt;h4&gt;&lt;strong&gt;Filter WoahDude by flair&lt;/strong&gt;&lt;/h4&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/woahdude/search?q=flair:picture&amp;amp;sort=top&amp;amp;restrict_sr=on"&gt;picture&lt;/a&gt; - Static images&lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/woahdude/search?q=flair:wallpaper+OR+%5BWALLPAPER%5D&amp;amp;sort=top&amp;amp;restrict_sr=on"&gt;wallpaper&lt;/a&gt; - PC or Smartphone&lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/woahdude/search?q=flair%3Agifv+OR+flair%3Awebm&amp;amp;restrict_sr=on&amp;amp;sort=top&amp;amp;t=all"&gt;gifv&lt;/a&gt; - Animated images&lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/woahdude/search?q=flair:audio&amp;amp;sort=top&amp;amp;restrict_sr=on"&gt;audio&lt;/a&gt; - Non-musical audio &lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/woahdude/search?q=flair:music&amp;amp;sort=top&amp;amp;restrict_sr=on"&gt;music&lt;/a&gt;  - Include: Band &amp;amp; Song Title&lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/woahdude/search?q=flair:musicvideo&amp;amp;sort=top&amp;amp;restrict_sr=on"&gt;music video&lt;/a&gt; - If slideshow, tag [music] &lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/woahdude/search?q=flair:video&amp;amp;sort=top&amp;amp;restrict_sr=on"&gt;video&lt;/a&gt; - Non-musical video&lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://redd.it/29owi1#movies"&gt;movies&lt;/a&gt; - Movies&lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/woahdude/search?q=flair:game&amp;amp;restrict_sr=on&amp;amp;sort=top&amp;amp;t=all"&gt;game&lt;/a&gt; - Goal oriented games&lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/woahdude/search?q=flair%3Ainteractive+OR+sandbox&amp;amp;sort=top&amp;amp;restrict_sr=on&amp;amp;t=all"&gt;interactive&lt;/a&gt; - Interactive pages&lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/woahdude/comments/1jri9s/woahdude_featured_apps_get_free_download_codes/"&gt;mobile app&lt;/a&gt; - Mod-curated selection of apps&lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/WoahDude/search?q=flair%3Atext&amp;amp;restrict_sr=on&amp;amp;sort=top&amp;amp;t=all"&gt;text&lt;/a&gt; - Articles, selfposts &amp;amp; textpics&lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/r/woahdude/search?q=flair%3Awoahdude%2Bapproved&amp;amp;sort=new&amp;amp;restrict_sr=on&amp;amp;t=all"&gt;WOAHDUDE APPROVED&lt;/a&gt; - Mod-curated selection of the best WoahDude submissions.&lt;/p&gt;
    
    &lt;h4&gt;RULES  &lt;a href="http://www.reddit.com/r/woahdude/wiki"&gt;⇨ FULL VERSION&lt;/a&gt;&lt;/h4&gt;
    
    &lt;blockquote&gt;
    &lt;ol&gt;
    &lt;li&gt;LINK FLAIR &lt;strong&gt;is &lt;a href="http://www.reddit.com/r/woahdude/wiki/index#wiki_flair_is_mandatory"&gt;mandatory&lt;/a&gt;.&lt;/strong&gt;&lt;/li&gt;
    &lt;li&gt;XPOST &lt;strong&gt;labels are &lt;a href="http://www.reddit.com/r/woahdude/wiki/index#wiki_.5Bxpost.5D_tags.2Flabels_are_banned"&gt;banned&lt;/a&gt;. Crossposts are fine, just don&amp;#39;t label them as such.&lt;/strong&gt;&lt;/li&gt;
    &lt;li&gt; NO &lt;strong&gt;hostility!&lt;/strong&gt; PLEASE &lt;strong&gt;giggle like a giraffe :)&lt;/strong&gt;&lt;/li&gt;
    &lt;/ol&gt;
    &lt;/blockquote&gt;
    
    &lt;p&gt;Certain reposts are allowed. &lt;a href="http://www.reddit.com/r/woahdude/wiki/index#wiki_reposts"&gt;Learn more&lt;/a&gt;. Those not allowed may be reported via this form:&lt;/p&gt;
    
    &lt;p&gt;&lt;a href="http://www.reddit.com/message/compose?to=%2Fr%2Fwoahdude&amp;amp;subject=Repost%20Report&amp;amp;message=Here%20%5bLINK%5d%20is%20an%20illegitimate%20repost,%20and%20here%20%5bLINK%5d%20is%20proof%20that%20the%20original%20woahdude%20post%20had%201500%2b%20upvotes.#reportwarning"&gt;&lt;/a&gt; &lt;a href="http://www.reddit.com/message/compose?to=%2Fr%2Fwoahdude&amp;amp;subject=Repost%20Report&amp;amp;message=Here%20%5bLINK%5d%20is%20an%20illegitimate%20repost,%20and%20here%20%5bLINK%5d%20is%20proof%20that%20the%20original%20woahdude%20post%20had%201500%2b%20upvotes."&gt;&lt;strong&gt;REPORT AN ILLEGITIMATE REPOST&lt;/strong&gt;&lt;/a&gt;&lt;/p&gt;
    
    &lt;h4&gt;WoahDude community&lt;/h4&gt;
    
    &lt;ul&gt;
    &lt;li&gt;&lt;a href="/r/WoahDude"&gt;/r/WoahDude&lt;/a&gt; - All media&lt;/li&gt;
    &lt;li&gt;&lt;a href="/r/WoahTube"&gt;/r/WoahTube&lt;/a&gt; - Videos only&lt;/li&gt;
    &lt;li&gt;&lt;a href="/r/WoahTunes"&gt;/r/WoahTunes&lt;/a&gt; - Music only&lt;/li&gt;
    &lt;li&gt;&lt;a href="/r/StonerPhilosophy"&gt;/r/StonerPhilosophy&lt;/a&gt; - Text posts only&lt;/li&gt;
    &lt;li&gt;&lt;a href="/r/WoahPoon"&gt;/r/WoahPoon&lt;/a&gt; - NSFW&lt;/li&gt;
    &lt;li&gt;&lt;strong&gt;&lt;a href="http://www.reddit.com/user/rWoahDude/m/woahdude"&gt;MULTIREDDIT&lt;/a&gt;&lt;/strong&gt;&lt;/li&gt;
    &lt;/ul&gt;
    
    &lt;h5&gt;&lt;a href="http://facebook.com/rWoahDude"&gt;&lt;/a&gt;&lt;/h5&gt;
    
    &lt;h5&gt;&lt;a href="http://twitter.com/rWoahDude"&gt;&lt;/a&gt;&lt;/h5&gt;
    
    &lt;h5&gt;&lt;a href="http://emilydavis.bandcamp.com/track/sagans-song"&gt;http://emilydavis.bandcamp.com/track/sagans-song&lt;/a&gt;&lt;/h5&gt;
    &lt;/div&gt;&lt;!-- SC_ON --&gt;
    */
    public let descriptionHtml: String
    /**
    title of the main page
    example: The BEST links to click while you're STONED
    */
    public let  title: String
    /**
    
    example: true
    */
    public let collapseDeletedComments: Bool
    /**
    whether the subreddit is marked as NSFW
    example: false
    */
    public let  over18: Bool
    /**
    
    example: &lt;!-- SC_OFF --&gt;&lt;div class="md"&gt;&lt;p&gt;The best links to click while you&amp;#39;re stoned!&lt;/p&gt;
    
    &lt;p&gt;Trippy, mesmerizing, and mindfucking games, video, audio &amp;amp; images that make you go &amp;#39;woah dude!&amp;#39;&lt;/p&gt;
    
    &lt;p&gt;If you like to look at amazing stuff while smoking weed or doing other drugs, come inside for some Science, Philosophy, Mindfucks, Math, Engineering, Illusions and Cosmic weirdness.&lt;/p&gt;
    &lt;/div&gt;&lt;!-- SC_ON --&gt;
    */
    public let publicDescriptionHtml: String
    /**
    
    example:
    */
    public let iconSize: [Int]
    /**
    
    example:
    */
    public let iconImg: String
    /**
    description of header image shown on hover, or null
    example: Turn on the stylesheet and click Carl Sagan's head
    */
    public let headerTitle: String
    /**
    sidebar text
    example: #####[Best of WoahDude 2014 ⇦](https://www.reddit.com/r/woahdude/comments/2qi1jh/best_of_rwoahdude_2014_results/?)
    
    [](#nyanbro)
    
    ####**What is WoahDude?**
    
    *The best links to click while you're stoned!*
    
    Trippy &amp; mesmerizing games, video, audio &amp; images that make you go 'woah dude!'
    
    No one wants to have to sift through the entire internet for fun links when they're stoned - so make this your one-stop shop!
    
    ⇨ [more in-depth explanation here](http://www.reddit.com/r/woahdude/wiki/index#wiki_what_is_.22woahdude_material.22.3F) ⇦
    
    ####**Filter WoahDude by flair**
    
    [picture](http://www.reddit.com/r/woahdude/search?q=flair:picture&amp;sort=top&amp;restrict_sr=on) - Static images
    
    [wallpaper](http://www.reddit.com/r/woahdude/search?q=flair:wallpaper+OR+[WALLPAPER]&amp;sort=top&amp;restrict_sr=on) - PC or Smartphone
    
    [gifv](http://www.reddit.com/r/woahdude/search?q=flair%3Agifv+OR+flair%3Awebm&amp;restrict_sr=on&amp;sort=top&amp;t=all) - Animated images
    
    [audio](http://www.reddit.com/r/woahdude/search?q=flair:audio&amp;sort=top&amp;restrict_sr=on) - Non-musical audio
    
    [music](http://www.reddit.com/r/woahdude/search?q=flair:music&amp;sort=top&amp;restrict_sr=on)  - Include: Band &amp; Song Title
    
    [music video](http://www.reddit.com/r/woahdude/search?q=flair:musicvideo&amp;sort=top&amp;restrict_sr=on) - If slideshow, tag [music]
    
    [video](http://www.reddit.com/r/woahdude/search?q=flair:video&amp;sort=top&amp;restrict_sr=on) - Non-musical video
    
    [movies](http://redd.it/29owi1#movies) - Movies
    
    [game](http://www.reddit.com/r/woahdude/search?q=flair:game&amp;restrict_sr=on&amp;sort=top&amp;t=all) - Goal oriented games
    
    [interactive](http://www.reddit.com/r/woahdude/search?q=flair%3Ainteractive+OR+sandbox&amp;sort=top&amp;restrict_sr=on&amp;t=all) - Interactive pages
    
    [mobile app](http://www.reddit.com/r/woahdude/comments/1jri9s/woahdude_featured_apps_get_free_download_codes/) - Mod-curated selection of apps
    
    [text](http://www.reddit.com/r/WoahDude/search?q=flair%3Atext&amp;restrict_sr=on&amp;sort=top&amp;t=all) - Articles, selfposts &amp; textpics
    
    [WOAHDUDE APPROVED](http://www.reddit.com/r/woahdude/search?q=flair%3Awoahdude%2Bapproved&amp;sort=new&amp;restrict_sr=on&amp;t=all) - Mod-curated selection of the best WoahDude submissions.
    
    ####RULES  [⇨ FULL VERSION](http://www.reddit.com/r/woahdude/wiki)
    
    &gt; 1. LINK FLAIR **is [mandatory](http://www.reddit.com/r/woahdude/wiki/index#wiki_flair_is_mandatory).**
    2. XPOST **labels are [banned](http://www.reddit.com/r/woahdude/wiki/index#wiki_.5Bxpost.5D_tags.2Flabels_are_banned). Crossposts are fine, just don't label them as such.**
    3.  NO **hostility!** PLEASE **giggle like a giraffe :)**
    
    Certain reposts are allowed. [Learn more](http://www.reddit.com/r/woahdude/wiki/index#wiki_reposts). Those not allowed may be reported via this form:
    
    [](http://www.reddit.com/message/compose?to=%2Fr%2Fwoahdude&amp;subject=Repost%20Report&amp;message=Here%20%5bLINK%5d%20is%20an%20illegitimate%20repost,%20and%20here%20%5bLINK%5d%20is%20proof%20that%20the%20original%20woahdude%20post%20had%201500%2b%20upvotes.#reportwarning) [**REPORT AN ILLEGITIMATE REPOST**](http://www.reddit.com/message/compose?to=%2Fr%2Fwoahdude&amp;subject=Repost%20Report&amp;message=Here%20%5bLINK%5d%20is%20an%20illegitimate%20repost,%20and%20here%20%5bLINK%5d%20is%20proof%20that%20the%20original%20woahdude%20post%20had%201500%2b%20upvotes.)
    
    ####WoahDude community
    
    * /r/WoahDude - All media
    * /r/WoahTube - Videos only
    * /r/WoahTunes - Music only
    * /r/StonerPhilosophy - Text posts only
    * /r/WoahPoon - NSFW
    * **[MULTIREDDIT](http://www.reddit.com/user/rWoahDude/m/woahdude)**
    
    #####[](http://facebook.com/rWoahDude)
    #####[](http://twitter.com/rWoahDude)
    
    #####http://emilydavis.bandcamp.com/track/sagans-song
    */
    public let  description: String
    /**
    the subreddit's custom label for the submit link button, if any
    example: SUBMIT LINK
    */
    public let submitLinkLabel: String
    /**
    number of users active in last 15 minutes
    example:
    */
    public let accountsActive: Int
    /**
    whether the subreddit's traffic page is publicly-accessible
    example: false
    */
    public let publicTraffic: Bool
    /**
    width and height of the header image, or null
    example: [145, 60]
    */
    public let headerSize: [Int]
    /**
    the number of redditors subscribed to this subreddit
    example: 778611
    */
    public let  subscribers: Int
    /**
    the subreddit's custom label for the submit text button, if any
    example: SUBMIT TEXT
    */
    public let submitTextLabel: String
    /**
    whether the logged-in user is a moderator of the subreddit
    example: false
    */
    public let userIsModerator: Bool
    /**
    
    example: 1254666760
    */
    public let  created: Int
    /**
    The relative URL of the subreddit.  Ex: "/r/pics/"
    example: /r/woahdude/
    */
    public let  url: String
    /**
    
    example: false
    */
    public let hideAds: Bool
    /**
    
    example: 1254663160
    */
    public let createdUtc: Int
    /**
    
    example:
    */
    public let bannerSize: [Int]
    /**
    whether the logged-in user is an approved submitter in the subreddit
    example: false
    */
    public let userIsContributor: Bool
    /**
    Description shown in subreddit search results?
    example: The best links to click while you're stoned!
    
    Trippy, mesmerizing, and mindfucking games, video, audio &amp; images that make you go 'woah dude!'
    
    If you like to look at amazing stuff while smoking weed or doing other drugs, come inside for some Science, Philosophy, Mindfucks, Math, Engineering, Illusions and Cosmic weirdness.
    
    
    */
    public let publicDescription: String
    /**
    number of minutes the subreddit initially hides comment scores
    example: 0
    */
    public let commentScoreHideMins: Int
    /**
    the subreddit's type - one of "public", "private", "restricted", or in very special cases "gold_restricted" or "archived"
    example: public
    */
    public let subredditType: String
    /**
    the type of submissions the subreddit allows - one of "any", "link" or "self"
    example: any
    */
    public let submissionType: String
    /**
    whether the logged-in user is subscribed to the subreddit
    example: true
    */
    public let userIsSubscriber: Bool
    
    public var path: String {
        var p = "/r/\(displayName)"
        if(displayName == "frontpage"){
            p = ""
        }
        return p
    }
    
    public init(subreddit: String) {
        self.id = "dummy"
        self.name = "\(Subreddit.kind)_\(self.id)"
        
        bannerImg = ""
        userSrThemeEnabled = false
        submitTextHtml = ""
        userIsBanned = false
        submitText = ""
        displayName = subreddit
        headerImg = ""
        descriptionHtml = ""
        title = ""
        collapseDeletedComments = false
        over18 = false
        publicDescriptionHtml = ""
        iconSize = []
        iconImg = ""
        headerTitle = ""
        description = ""
        submitLinkLabel = ""
        accountsActive = 0
        publicTraffic = false
        headerSize = []
        subscribers = 0
        submitTextLabel = ""
        userIsModerator = false
        created = 0
        keyColor = ""
        url = ""
        hideAds = false
        createdUtc = 0
        bannerSize = []
        userIsContributor = false
        publicDescription = ""
        commentScoreHideMins = 0
        subredditType = ""
        submissionType = ""
        userIsSubscriber = false
    }

    public init(id: String) {
        self.id = id
        self.name = "\(Subreddit.kind)_\(self.id)"
        
        bannerImg = ""
        userSrThemeEnabled = false
        submitTextHtml = ""
        userIsBanned = false
        submitText = ""
        displayName = ""
        headerImg = ""
        descriptionHtml = ""
        title = ""
        collapseDeletedComments = false
        over18 = false
        publicDescriptionHtml = ""
        iconSize = []
        iconImg = ""
        headerTitle = ""
        description = ""
        submitLinkLabel = ""
        accountsActive = 0
        publicTraffic = false
        headerSize = []
        subscribers = 0
        submitTextLabel = ""
        userIsModerator = false
        keyColor = ""
        created = 0
        url = ""
        hideAds = false
        createdUtc = 0
        bannerSize = []
        userIsContributor = false
        publicDescription = ""
        commentScoreHideMins = 0
        subredditType = ""
        submissionType = ""
        userIsSubscriber = false
    }
    
    /**
    Parse t5 object.
    
    - parameter data: Dictionary, must be generated parsing "t5".
    - returns: Subreddit object as Thing.
    */
    public init(json data: JSONDictionary) {
        id = data["id"] as? String ?? ""
        bannerImg = data["banner_img"] as? String ?? ""
        userSrThemeEnabled = data["user_sr_theme_enabled"] as? Bool ?? false
        let tempSubmitTextHtml = data["submit_text_html"] as? String ?? ""
        submitTextHtml = tempSubmitTextHtml.gtm_stringByUnescapingFromHTML()
        userIsBanned = data["user_is_banned"] as? Bool ?? false
        submitText = data["submit_text"] as? String ?? ""
        displayName = data["display_name"] as? String ?? ""
        headerImg = data["header_img"] as? String ?? ""
        let tempDescriptionHtml = data["description_html"] as? String ?? ""
        descriptionHtml = tempDescriptionHtml.gtm_stringByUnescapingFromHTML()
        title = data["title"] as? String ?? ""
        collapseDeletedComments = data["collapse_deleted_comments"] as? Bool ?? false
        over18 = data["over18"] as? Bool ?? false
        let tempPublicDescriptionHtml = data["public_description_html"] as? String ?? ""
        publicDescriptionHtml = tempPublicDescriptionHtml.gtm_stringByUnescapingFromHTML()
        iconSize = data["icon_size"] as? [Int] ?? []
        iconImg = data["icon_img"] as? String ?? ""
        keyColor = data["key_color"] as? String ?? ""
        headerTitle = data["header_title"] as? String ?? ""
        let tempDescription = data["description"] as? String ?? ""
        description = tempDescription.gtm_stringByUnescapingFromHTML()
        submitLinkLabel = data["submit_link_label"] as? String ?? ""
        accountsActive = data["accounts_active"] as? Int ?? 0
        publicTraffic = data["public_traffic"] as? Bool ?? false
        headerSize = data["header_size"] as? [Int] ?? []
        subscribers = data["subscribers"] as? Int ?? 0
        submitTextLabel = data["submit_text_label"] as? String ?? ""
        userIsModerator = data["user_is_moderator"] as? Bool ?? false
        name = data["name"] as? String ?? ""
        created = data["created"] as? Int ?? 0
        url = data["url"] as? String ?? ""
        hideAds = data["hide_ads"] as? Bool ?? false
        createdUtc = data["created_utc"] as? Int ?? 0
        bannerSize = data["banner_size"] as? [Int] ?? []
        userIsContributor = data["user_is_contributor"] as? Bool ?? false
        let tempPublicDescription = data["public_description"] as? String ?? ""
        publicDescription = tempPublicDescription.gtm_stringByUnescapingFromHTML()
        commentScoreHideMins = data["comment_score_hide_mins"] as? Int ?? 0
        subredditType = data["subreddit_type"] as? String ?? ""
        submissionType = data["submission_type"] as? String ?? ""
        userIsSubscriber = data["user_is_subscriber"] as? Bool ?? false
    }
}
