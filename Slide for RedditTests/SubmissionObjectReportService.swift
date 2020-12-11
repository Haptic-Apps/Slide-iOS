//
//  SubmissionObjectReportService.swift
//  Slide for RedditTests
//
//  Created by Carlos Crane on 12/10/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import reddift
@testable import Slide_for_Reddit
import XCTest

class SubmissionObjectReportService: XCTestCase {

    var submissionObject: SubmissionObject!
    var coreDataStack: TestSlideCoreData!

    override func setUp() {
        super.setUp()
    
        coreDataStack = TestSlideCoreData()
        submissionObject = SubmissionObject()
    }
    
    func testConvertToCDAndBack() {
        submissionObject.id = "i1f7ry"
        submissionObject.smallPreview = "https://external-preview.redd.it/DgX4-q3FE37RKmaXOfThOssb0-IEogOUHZe-DZTLOKU.jpg?auto=webp&s=0ac8cf74bf743944f2634c407f89ed88ec8c12e1"
        submissionObject.subredditIcon = "https://styles.redditmedia.com/t5_3847x/styles/communityIcon_1xp01fat7gi51.png?width=256&s=bbe9b10dddee54a05e98df357af8eb853dac3ea6"
        submissionObject.author = "sandwicheconomist"
        submissionObject.created = Date(timeIntervalSince1970: 1596257102)
        submissionObject.isEdited = true
        submissionObject.edited = Date(timeIntervalSince1970: 1596257102)
        submissionObject.htmlBody = "<!-- SC_OFF --><div class=\"md\"><p>Here&#39;s some text.</p>\n\n<blockquote>\n<p>This should be quoted  </p>\n\n<p>This is the second line of the quoted text.</p>\n</blockquote>\n\n<pre><code>This is a code block.\n</code></pre>\n\n<p>​ <code>This is inline code.</code></p>\n\n<p><span class=\"md-spoiler-text\">Haha spoilers</span></p>\n\n<h1>Heading Text</h1>\n\n<ul>\n<li>Bullet 1</li>\n<li>Bullet 2</li>\n<li>Bullet 3</li>\n</ul>\n\n<p>Text</p>\n\n<ol>\n<li>Numbered list 1</li>\n<li>Numbered list 2</li>\n<li>Numbered list 3\n\n<ol>\n<li>Sub item\n\n<ol>\n<li>Sub sub item</li>\n</ol></li>\n</ol></li>\n<li>Numbered list 4</li>\n</ol>\n\n<ul>\n<li>Bullet 1\n\n<ul>\n<li>Sub bullet\n\n<ul>\n<li>Sub sub bullet</li>\n</ul></li>\n</ul></li>\n<li>Bullet 2</li>\n</ul>\n\n<table><thead>\n<tr>\n<th align=\"left\">Table Column 1</th>\n<th align=\"left\">Table Column 2</th>\n<th align=\"left\">Table Column 3</th>\n</tr>\n</thead><tbody>\n<tr>\n<td align=\"left\">Wow</td>\n<td align=\"left\">Neat</td>\n<td align=\"left\">Cool</td>\n</tr>\n</tbody></table>\n\n<p><strong>Bold text</strong></p>\n\n<p><em>Italic text</em></p>\n\n<p><strong><em>Bold and italic text</em></strong></p>\n\n<p><del>Strikethrough text</del></p>\n\n<p><strong><em><del>Bold italic strikethrough</del></em></strong></p>\n\n<p>Text<sup>superscript</sup></p>\n\n<p>Text<sup>superscript 1superscript 2superscript 3</sup></p>\n\n<p>Text<sup>sup1sup2sup3sup4sup5sup6sup7sup8sup9</sup></p>\n\n<p>Text<sup>abcdefghijklmnopqrstuvwxyz</sup></p>\n\n<p>Text<sup>ABCDEFGHIJKLMNOPQRSTUVWXYZ</sup></p>\n\n<p>Text<sup>1234567890</sup></p>\n\n<blockquote>\n<p><strong>Here&#39;s some bolded quoted text.</strong>  </p>\n\n<p><em>Here&#39;s some italicized quoted text.</em>  </p>\n\n<p><del>Here&#39;s some strikethrough quoted text.</del></p>\n</blockquote>\n\n<p><a href=\"https://jons.website\">This is a link.</a></p>\n\n<blockquote>\n<p><a href=\"https://jons.website\">This is a quoted link.</a>  </p>\n\n<p><a href=\"https://jons.website\">This is a quoted link with <strong>bold</strong>, <em>italics</em>, and <del>strikethrough</del>.</a></p>\n</blockquote>\n\n<p><a href=\"https://jons.website\">This is a link that&#39;s <em>partially italicized</em> and here&#39;s some more text.</a></p>\n\n<p><a href=\"https://jons.website\">This is a link that&#39;s <strong>partially bolded</strong> and here&#39;s some more text.</a></p>\n\n<p>Emojis:</p>\n\n<p>😀😃😄😁😎🥳🏀🥅🏹🚗</p>\n\n<p>Skin tone variations:</p>\n\n<p>🧑‍💻🧑🏻‍💻🧑🏼‍💻🧑🏽‍💻🧑🏾‍💻🧑🏿‍💻</p>\n\n<p>Flags:</p>\n\n<p>🏳️🏳️‍🌈🇦🇺🇯🇵🇺🇸🇬🇧</p>\n\n<p>Other:</p>\n\n<p>0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣🔟🔢#️⃣*️⃣🔤🔡🔠</p>\n\n<p>Reddit Stuff:</p>\n\n<ul>\n<li><a href=\"/u/ccrama\">u/ccrama</a></li>\n<li><a href=\"/u/ccrama\">/u/ccrama</a></li>\n<li><a href=\"/r/Slide_iOS\">r/Slide_iOS</a></li>\n<li><a href=\"/r/Slide_iOS\">/r/Slide_iOS</a></li>\n</ul>\n</div><!-- SC_ON -->"
        submissionObject.subreddit = "testslideforreddit"
        submissionObject.isArchived = true
        submissionObject.isLocked = true
        submissionObject.contentUrl = "https://www.reddit.com/r/testslideforreddit/comments/i1f7ry/post_with_lots_of_text_formatting/"
        submissionObject.title = "Post with lots of text formatting"
        submissionObject.commentCount = 4234234322
        submissionObject.isSaved = true
        submissionObject.isStickied = true
        submissionObject.isVisited = true
        submissionObject.bannerUrl = "https://emoji.redditmedia.com/ot9guim1v6g21_t5_3847x/icon"
        submissionObject.thumbnailUrl = "https://emoji.redditmedia.com/ot9guim1v6g21_t5_3847x/icon"
        submissionObject.hasThumbnail = true
        submissionObject.isNSFW = true
        submissionObject.hasBanner = true
        submissionObject.lqURL = "https://emoji.redditmedia.com/ot9guim1v6g21_t5_3847x/icon"
        submissionObject.domain = "XCTAssertEqual(submissionObject.testslideforreddit"
        submissionObject.isLQ = true
        submissionObject.score = 10234000
        submissionObject.hasVoted = true
        submissionObject.upvoteRatio = 0.3
        submissionObject.voteDirection = true
        submissionObject.name = "test"
        submissionObject.videoPreview = "https://emoji.redditmedia.com/ot9guim1v6g21_t5_3847x/icon"
        submissionObject.videoMP4 = "https://emoji.redditmedia.com/ot9guim1v6g21_t5_3847x/icon"
        submissionObject.imageHeight = 234234234
        submissionObject.imageWidth = 234234
        submissionObject.distinguished = "test"
        submissionObject.isMod = true
        submissionObject.isSelf = true
        submissionObject.markdownBody = "Here's some text.\n\n>This should be quoted  \n>  \n>This is the second line of the quoted text.\n\n    This is a code block.\n\n​ `This is inline code.`\n\n>!Haha spoilers!<\n\n# Heading Text\n\n* Bullet 1\n* Bullet 2\n* Bullet 3\n\nText\n\n1. Numbered list 1\n2. Numbered list 2\n3. Numbered list 3\n   1. Sub item\n      1. Sub sub item\n4. Numbered list 4\n\n* Bullet 1\n   * Sub bullet\n      * Sub sub bullet\n* Bullet 2\n\n|Table Column 1|Table Column 2|Table Column 3|\n|:-|:-|:-|\n|Wow|Neat|Cool|\n\n**Bold text**\n\n*Italic text*\n\n***Bold and italic text***\n\n~~Strikethrough text~~\n\n***~~Bold italic strikethrough~~***\n\nText^(superscript)\n\nText^(superscript 1superscript 2superscript 3)\n\nText^(sup1sup2sup3sup4sup5sup6sup7sup8sup9)\n\nText^(abcdefghijklmnopqrstuvwxyz)\n\nText^(ABCDEFGHIJKLMNOPQRSTUVWXYZ)\n\nText^(1234567890)\n\n>**Here's some bolded quoted text.**  \n>  \n>*Here's some italicized quoted text.*  \n>  \n>~~Here's some strikethrough quoted text.~~\n\n[This is a link.](https://jons.website)\n\n>[This is a quoted link.](https://jons.website)  \n>  \n>[This is a quoted link with **bold**, *italics*, and ~~strikethrough~~.](https://jons.website)\n\n[This is a link that's *partially italicized* and here's some more text.](https://jons.website)\n\n[This is a link that's **partially bolded** and here's some more text.](https://jons.website)\n\nEmojis:\n\n😀😃😄😁😎🥳🏀🥅🏹🚗\n\nSkin tone variations:\n\n🧑‍💻🧑🏻‍💻🧑🏼‍💻🧑🏽‍💻🧑🏾‍💻🧑🏿‍💻\n\nFlags:\n\n🏳️🏳️‍🌈🇦🇺🇯🇵🇺🇸🇬🇧\n\nOther:\n\n0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣🔟🔢#️⃣\\*️⃣🔤🔡🔠\n\nReddit Stuff:\n\n* u/ccrama\n* /u/ccrama\n* r/Slide_iOS\n* /r/Slide_iOS"
        submissionObject.permalink = "https://emoji.redditmedia.com/46kel8lf1guz_t5_3nqvj/cake"
        submissionObject.isSpoiler = true
        submissionObject.isOC = true
        submissionObject.removedBy = "ccrama"
        submissionObject.removalReason = "he's cool"
        submissionObject.removalNote = "no."
        submissionObject.isRemoved = true
        submissionObject.isCakeday = true
        submissionObject.hidden = true
        submissionObject.reportsJSON = "{\"author_flair_richtext\": [{\"a\": \":cake:\",\"e\": \"emoji\",\"u\": \"https://emoji.redditmedia.com/46kel8lf1guz_t5_3nqvj/cake\"}]}"
        submissionObject.awardsJSON = "{\"author_flair_richtext\": [{\"a\": \":cake:\",\"e\": \"emoji\",\"u\": \"https://emoji.redditmedia.com/46kel8lf1guz_t5_3nqvj/cake\"}]}"
        submissionObject.flairJSON = "{\"author_flair_richtext\": [{\"a\": \":cake:\",\"e\": \"emoji\",\"u\": \"https://emoji.redditmedia.com/46kel8lf1guz_t5_3nqvj/cake\"}]}"
        submissionObject.galleryJSON = "{\"author_flair_richtext\": [{\"a\": \":cake:\",\"e\": \"emoji\",\"u\": \"https://emoji.redditmedia.com/46kel8lf1guz_t5_3nqvj/cake\"}]}"
        submissionObject.pollJSON = "{\"author_flair_richtext\": [{\"a\": \":cake:\",\"e\": \"emoji\",\"u\": \"https://emoji.redditmedia.com/46kel8lf1guz_t5_3nqvj/cake\"}]}"
        submissionObject.approvedBy = "ccrama"
        submissionObject.isApproved = true
        submissionObject.isCrosspost = true
        submissionObject.crosspostSubreddit = "testslideforreddit"
        submissionObject.crosspostAuthor = "ccrama"
        submissionObject.crosspostPermalink = "https://emoji.redditmedia.com/46kel8lf1guz_t5_3nqvj/cake"

        let context = coreDataStack.storeContainer.newBackgroundContext()
        context.performAndWait {
            //Create and insert into CoreData
            let coreDataItem = submissionObject.insertSelf(into: context, andSave: true) as? SubmissionModel
            XCTAssertNotNil(coreDataItem, "Failed saving SubmissionObject into CoreData")

            //Create new SubmissionObject from previously converted model
            let newSubmissionObject = SubmissionObject(model: coreDataItem!)
            
            XCTAssertEqual(submissionObject.id, newSubmissionObject.id, "id not equal")
            XCTAssertEqual(submissionObject.smallPreview, newSubmissionObject.smallPreview, "smallPreview not equal")
            XCTAssertEqual(submissionObject.subredditIcon, newSubmissionObject.subredditIcon, "subredditIcon not equal")

            XCTAssertEqual(submissionObject.author, newSubmissionObject.author, "author not equal")
            XCTAssertEqual(submissionObject.created, newSubmissionObject.created, "created not equal")
            XCTAssertEqual(submissionObject.isEdited, newSubmissionObject.isEdited, "isEdited not equal")
            XCTAssertEqual(submissionObject.edited, newSubmissionObject.edited, "edited not equal")
            XCTAssertEqual(submissionObject.htmlBody, newSubmissionObject.htmlBody, "htmlBody not equal")
            XCTAssertEqual(submissionObject.subreddit, newSubmissionObject.subreddit, "subreddit not equal")
            XCTAssertEqual(submissionObject.isArchived, newSubmissionObject.isArchived, "isArchived not equal")
            XCTAssertEqual(submissionObject.isLocked, newSubmissionObject.isLocked, "isLocked not equal")
            XCTAssertEqual(submissionObject.contentUrl, newSubmissionObject.contentUrl, "contentUrl not equal")
            
            XCTAssertEqual(submissionObject.title, newSubmissionObject.title, "title not equal")
            XCTAssertEqual(submissionObject.commentCount, newSubmissionObject.commentCount, "commentCount not equal")
            XCTAssertEqual(submissionObject.isSaved, newSubmissionObject.isSaved, "isSaved not equal")
            XCTAssertEqual(submissionObject.isStickied, newSubmissionObject.isStickied, "isStickied not equal")
            XCTAssertEqual(submissionObject.isVisited, newSubmissionObject.isVisited, "isVisited not equal")
            XCTAssertEqual(submissionObject.bannerUrl, newSubmissionObject.bannerUrl, "bannerUrl not equal")
            XCTAssertEqual(submissionObject.thumbnailUrl, newSubmissionObject.thumbnailUrl, "thumbnailUrl not equal")
            XCTAssertEqual(submissionObject.hasThumbnail, newSubmissionObject.hasThumbnail, "hasThumbnail not equal")
            XCTAssertEqual(submissionObject.isNSFW, newSubmissionObject.isNSFW, "isNSFW not equal")
            XCTAssertEqual(submissionObject.hasBanner, newSubmissionObject.hasBanner, "hasBanner not equal")
            XCTAssertEqual(submissionObject.lqURL, newSubmissionObject.lqURL, "lqURL not equal")
            XCTAssertEqual(submissionObject.domain, newSubmissionObject.domain, "domain not equal")
            XCTAssertEqual(submissionObject.isLQ, newSubmissionObject.isLQ, "isLQ not equal")
            XCTAssertEqual(submissionObject.score, newSubmissionObject.score, "score not equal")
            XCTAssertEqual(submissionObject.hasVoted, newSubmissionObject.hasVoted, "hasVoted not equal")
            XCTAssertEqual(submissionObject.upvoteRatio, newSubmissionObject.upvoteRatio, "upvoteRatio not equal")
            XCTAssertEqual(submissionObject.voteDirection, newSubmissionObject.voteDirection, "voteDirection not equal")
            XCTAssertEqual(submissionObject.name, newSubmissionObject.name, "name not equal")
            XCTAssertEqual(submissionObject.videoPreview, newSubmissionObject.videoPreview, "videoPreview not equal")
                    
            XCTAssertEqual(submissionObject.videoMP4, newSubmissionObject.videoMP4, "videoMP4 not equal")
            
            XCTAssertEqual(submissionObject.imageHeight, newSubmissionObject.imageHeight, "imageHeight not equal")
            XCTAssertEqual(submissionObject.imageWidth, newSubmissionObject.imageWidth, "imageWidth not equal")
            XCTAssertEqual(submissionObject.distinguished, newSubmissionObject.distinguished, "distinguished not equal")
            XCTAssertEqual(submissionObject.isMod, newSubmissionObject.isMod, "isMod not equal")
            XCTAssertEqual(submissionObject.isSelf, newSubmissionObject.isSelf, "isSelf not equal")
            XCTAssertEqual(submissionObject.markdownBody, newSubmissionObject.markdownBody, "markdownBody not equal")
            XCTAssertEqual(submissionObject.permalink, newSubmissionObject.permalink, "permalink not equal")

            XCTAssertEqual(submissionObject.isSpoiler, newSubmissionObject.isSpoiler, "isSpoiler not equal")
            XCTAssertEqual(submissionObject.isOC, newSubmissionObject.isOC, "isOC not equal")
            XCTAssertEqual(submissionObject.removedBy, newSubmissionObject.removedBy, "removalReason not equal")
            XCTAssertEqual(submissionObject.removalReason, newSubmissionObject.removalReason, "removalReason not equal")
            XCTAssertEqual(submissionObject.removalNote, newSubmissionObject.removalNote, "removalNote not equal")
            XCTAssertEqual(submissionObject.isRemoved, newSubmissionObject.isRemoved, "isRemoved not equal")
            XCTAssertEqual(submissionObject.isCakeday, newSubmissionObject.isCakeday, "isCakeday not equal")
            XCTAssertEqual(submissionObject.hidden, newSubmissionObject.hidden, "hidden not equal")

            XCTAssertEqual(submissionObject.reportsJSON, newSubmissionObject.reportsJSON, "reportsJSON not equal")
            XCTAssertEqual(submissionObject.awardsJSON, newSubmissionObject.awardsJSON, "awardsJSON not equal")
            XCTAssertEqual(submissionObject.flairJSON, newSubmissionObject.flairJSON, "flairJSON not equal")
            XCTAssertEqual(submissionObject.galleryJSON, newSubmissionObject.galleryJSON, "galleryJSON not equal")
            XCTAssertEqual(submissionObject.pollJSON, newSubmissionObject.pollJSON, "pollJSON not equal")
            
            XCTAssertEqual(submissionObject.approvedBy, newSubmissionObject.approvedBy, "approvedBy not equal")
            XCTAssertEqual(submissionObject.isApproved, newSubmissionObject.isApproved, "isApproved not equal")
            
            XCTAssertEqual(submissionObject.isCrosspost, newSubmissionObject.isCrosspost, "isCrosspost not equal")

            XCTAssertEqual(submissionObject.crosspostSubreddit, newSubmissionObject.crosspostSubreddit, "crosspostSubreddit not equal")
            XCTAssertEqual(submissionObject.crosspostAuthor, newSubmissionObject.crosspostAuthor, "crosspostAuthor not equal")
            XCTAssertEqual(submissionObject.crosspostPermalink, newSubmissionObject.crosspostPermalink, "crosspostPermalink not equal")
        }
    }
    
    override func tearDown() {
      super.tearDown()
      submissionObject = nil
      coreDataStack = nil
    }
}
