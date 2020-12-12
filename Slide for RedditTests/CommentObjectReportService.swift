//
//  CommentObjectReportService.swift
//  Slide for RedditTests
//
//  Created by Carlos Crane on 12/12/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import reddift
@testable import Slide_for_Reddit
import XCTest

class CommentObjectReportService: XCTestCase {

    var commentObject: CommentObject!
    var coreDataStack: TestSlideCoreData!

    override func setUp() {
        super.setUp()
    
        coreDataStack = TestSlideCoreData()
        commentObject = CommentObject()
    }
    
    func testConvertToCDAndBack() {
        commentObject.id = "lk234j"
        commentObject.author = "ccrama"
        commentObject.created = Date()
        commentObject.isEdited = true
        commentObject.edited = Date()
        commentObject.htmlBody = "<!-- SC_OFF --><div class=\"md\"><p>Here&#39;s some text.</p>\n\n<blockquote>\n<p>This should be quoted  </p>\n\n<p>This is the second line of the quoted text.</p>\n</blockquote>\n\n<pre><code>This is a code block.\n</code></pre>\n\n<p>​ <code>This is inline code.</code></p>\n\n<p><span class=\"md-spoiler-text\">Haha spoilers</span></p>\n\n<h1>Heading Text</h1>\n\n<ul>\n<li>Bullet 1</li>\n<li>Bullet 2</li>\n<li>Bullet 3</li>\n</ul>\n\n<p>Text</p>\n\n<ol>\n<li>Numbered list 1</li>\n<li>Numbered list 2</li>\n<li>Numbered list 3\n\n<ol>\n<li>Sub item\n\n<ol>\n<li>Sub sub item</li>\n</ol></li>\n</ol></li>\n<li>Numbered list 4</li>\n</ol>\n\n<ul>\n<li>Bullet 1\n\n<ul>\n<li>Sub bullet\n\n<ul>\n<li>Sub sub bullet</li>\n</ul></li>\n</ul></li>\n<li>Bullet 2</li>\n</ul>\n\n<table><thead>\n<tr>\n<th align=\"left\">Table Column 1</th>\n<th align=\"left\">Table Column 2</th>\n<th align=\"left\">Table Column 3</th>\n</tr>\n</thead><tbody>\n<tr>\n<td align=\"left\">Wow</td>\n<td align=\"left\">Neat</td>\n<td align=\"left\">Cool</td>\n</tr>\n</tbody></table>\n\n<p><strong>Bold text</strong></p>\n\n<p><em>Italic text</em></p>\n\n<p><strong><em>Bold and italic text</em></strong></p>\n\n<p><del>Strikethrough text</del></p>\n\n<p><strong><em><del>Bold italic strikethrough</del></em></strong></p>\n\n<p>Text<sup>superscript</sup></p>\n\n<p>Text<sup>superscript 1superscript 2superscript 3</sup></p>\n\n<p>Text<sup>sup1sup2sup3sup4sup5sup6sup7sup8sup9</sup></p>\n\n<p>Text<sup>abcdefghijklmnopqrstuvwxyz</sup></p>\n\n<p>Text<sup>ABCDEFGHIJKLMNOPQRSTUVWXYZ</sup></p>\n\n<p>Text<sup>1234567890</sup></p>\n\n<blockquote>\n<p><strong>Here&#39;s some bolded quoted text.</strong>  </p>\n\n<p><em>Here&#39;s some italicized quoted text.</em>  </p>\n\n<p><del>Here&#39;s some strikethrough quoted text.</del></p>\n</blockquote>\n\n<p><a href=\"https://jons.website\">This is a link.</a></p>\n\n<blockquote>\n<p><a href=\"https://jons.website\">This is a quoted link.</a>  </p>\n\n<p><a href=\"https://jons.website\">This is a quoted link with <strong>bold</strong>, <em>italics</em>, and <del>strikethrough</del>.</a></p>\n</blockquote>\n\n<p><a href=\"https://jons.website\">This is a link that&#39;s <em>partially italicized</em> and here&#39;s some more text.</a></p>\n\n<p><a href=\"https://jons.website\">This is a link that&#39;s <strong>partially bolded</strong> and here&#39;s some more text.</a></p>\n\n<p>Emojis:</p>\n\n<p>😀😃😄😁😎🥳🏀🥅🏹🚗</p>\n\n<p>Skin tone variations:</p>\n\n<p>🧑‍💻🧑🏻‍💻🧑🏼‍💻🧑🏽‍💻🧑🏾‍💻🧑🏿‍💻</p>\n\n<p>Flags:</p>\n\n<p>🏳️🏳️‍🌈🇦🇺🇯🇵🇺🇸🇬🇧</p>\n\n<p>Other:</p>\n\n<p>0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣🔟🔢#️⃣*️⃣🔤🔡🔠</p>\n\n<p>Reddit Stuff:</p>\n\n<ul>\n<li><a href=\"/u/ccrama\">u/ccrama</a></li>\n<li><a href=\"/u/ccrama\">/u/ccrama</a></li>\n<li><a href=\"/r/Slide_iOS\">r/Slide_iOS</a></li>\n<li><a href=\"/r/Slide_iOS\">/r/Slide_iOS</a></li>\n</ul>\n</div><!-- SC_ON -->"
        commentObject.subreddit = "testslideforreddit"
        commentObject.submissionTitle = "submissiontitle"
        commentObject.isSaved = true
        commentObject.markdownBody = "Here's some text.\n\n>This should be quoted  \n>  \n>This is the second line of the quoted text.\n\n    This is a code block.\n\n​ `This is inline code.`\n\n>!Haha spoilers!<\n\n# Heading Text\n\n* Bullet 1\n* Bullet 2\n* Bullet 3\n\nText\n\n1. Numbered list 1\n2. Numbered list 2\n3. Numbered list 3\n   1. Sub item\n      1. Sub sub item\n4. Numbered list 4\n\n* Bullet 1\n   * Sub bullet\n      * Sub sub bullet\n* Bullet 2\n\n|Table Column 1|Table Column 2|Table Column 3|\n|:-|:-|:-|\n|Wow|Neat|Cool|\n\n**Bold text**\n\n*Italic text*\n\n***Bold and italic text***\n\n~~Strikethrough text~~\n\n***~~Bold italic strikethrough~~***\n\nText^(superscript)\n\nText^(superscript 1superscript 2superscript 3)\n\nText^(sup1sup2sup3sup4sup5sup6sup7sup8sup9)\n\nText^(abcdefghijklmnopqrstuvwxyz)\n\nText^(ABCDEFGHIJKLMNOPQRSTUVWXYZ)\n\nText^(1234567890)\n\n>**Here's some bolded quoted text.**  \n>  \n>*Here's some italicized quoted text.*  \n>  \n>~~Here's some strikethrough quoted text.~~\n\n[This is a link.](https://jons.website)\n\n>[This is a quoted link.](https://jons.website)  \n>  \n>[This is a quoted link with **bold**, *italics*, and ~~strikethrough~~.](https://jons.website)\n\n[This is a link that's *partially italicized* and here's some more text.](https://jons.website)\n\n[This is a link that's **partially bolded** and here's some more text.](https://jons.website)\n\nEmojis:\n\n😀😃😄😁😎🥳🏀🥅🏹🚗\n\nSkin tone variations:\n\n🧑‍💻🧑🏻‍💻🧑🏼‍💻🧑🏽‍💻🧑🏾‍💻🧑🏿‍💻\n\nFlags:\n\n🏳️🏳️‍🌈🇦🇺🇯🇵🇺🇸🇬🇧\n\nOther:\n\n0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣🔟🔢#️⃣\\*️⃣🔤🔡🔠\n\nReddit Stuff:\n\n* u/ccrama\n* /u/ccrama\n* r/Slide_iOS\n* /r/Slide_iOS"
        commentObject.removalReason = "reason"
        commentObject.removalNote = "note"
        commentObject.removedBy = "removed"
        commentObject.isRemoved = true
        commentObject.approvedBy = "approved"
        commentObject.isApproved = true
        commentObject.isStickied = true
        commentObject.awardsJSON = "{\"author_flair_richtext\": [{\"a\": \":cake:\",\"e\": \"emoji\",\"u\": \"https://emoji.redditmedia.com/46kel8lf1guz_t5_3nqvj/cake\"}]}"
        commentObject.flairJSON = "{\"author_flair_richtext\": [{\"a\": \":cake:\",\"e\": \"emoji\",\"u\": \"https://emoji.redditmedia.com/46kel8lf1guz_t5_3nqvj/cake\"}]}"
        commentObject.reportsJSON = "{\"author_flair_richtext\": [{\"a\": \":cake:\",\"e\": \"emoji\",\"u\": \"https://emoji.redditmedia.com/46kel8lf1guz_t5_3nqvj/cake\"}]}"
        commentObject.isCakeday = true

        commentObject.score = 2030030320
        commentObject.depth = 3242342342
        
        commentObject.isMod = true
        commentObject.linkID = "asdf420"
        commentObject.isArchived = true
        commentObject.distinguished = "mod"
        commentObject.controversality = 45
        commentObject.hasVoted = true
        commentObject.voteDirection = true
        commentObject.name = "asdfjf"
        commentObject.parentID = "asdfasdf"
        commentObject.scoreHidden = true
        commentObject.permalink = "https://www.reddit.com"

        let context = coreDataStack.storeContainer.newBackgroundContext()
        context.performAndWait {
            //Create and insert into CoreData
            let coreDataItem = commentObject.insertSelf(into: context, andSave: true) as? CommentModel
            XCTAssertNotNil(coreDataItem, "Failed saving CommentObject into CoreData")

            //Create new SubmissionObject from previously converted model
            let newCommentObject = CommentObject(model: coreDataItem!)
            
            let mirroredOriginal = Mirror(reflecting: commentObject!)
            let mirroredNew = Mirror(reflecting: newCommentObject)

            for (_, attr) in mirroredOriginal.children.enumerated() {
                if let property_name = attr.label, (attr.value is String || attr.value is Int || attr.value is Date || attr.value is Double) {
                    let firstValue = attr.value
                    if let secondValue = mirroredNew.children.first { $0.label == property_name }?.value {
                        if firstValue is String {
                            XCTAssertEqual(firstValue as! String, secondValue as? String, "\(property_name) not equal")
                        } else if firstValue is Int {
                            XCTAssertEqual(firstValue as! Int, secondValue as? Int, "\(property_name) not equal")
                        } else if firstValue is Date {
                            XCTAssertEqual(firstValue as! Date, secondValue as? Date, "\(property_name) not equal")
                        } else if firstValue is Double {
                            XCTAssertEqual(firstValue as! Double, secondValue as? Double, "\(property_name) not equal")
                        }
                    } else {
                        XCTAssert(false, "\(property_name) doesnt have a value in new object")
                    }
                }
            }
        }
    }
    
    override func tearDown() {
      super.tearDown()
      commentObject = nil
      coreDataStack = nil
    }
}
