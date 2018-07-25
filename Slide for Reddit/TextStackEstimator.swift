//
//  TextStackEstimator.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/10/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import DTCoreText
import TTTAttributedLabel
import UIKit

public class TextStackEstimator: NSObject {
    let TABLE_START_TAG = "<table>"
    let HR_TAG = "<hr/>"
    let TABLE_END_TAG = "</table>"
    
    var estimatedWidth = CGFloat(0)
    var estimatedHeight = CGFloat(0)
    
    let fontSize: CGFloat
    let submission: Bool
    let color: UIColor
    
    init(fontSize: CGFloat, submission: Bool, color: UIColor, width: CGFloat) {
        self.fontSize = fontSize
        self.submission = submission
        self.estimatedWidth = width
        self.color = color
    }
    
    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setAttributedString(_ string: NSAttributedString) {
        let framesetterB = CTFramesetterCreateWithAttributedString(string)
        let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
        estimatedHeight += textSizeB.height
    }
    
    public func setTextWithTitleHTML(_ title: NSMutableAttributedString, _ body: NSAttributedString? = nil, htmlString: String) {
        
        if htmlString.contains("<table") || htmlString.contains("<code") {
            var blocks = getBlocks(htmlString)
            
            var startIndex = 0
            
            var newTitle = title
            
            if !blocks[0].startsWith("<table>") && !blocks[0].startsWith("<code>") {
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 5)]))
                newTitle.append(createAttributedChunk(baseHTML: blocks[0]))
                startIndex = 1
            }
            let framesetterB = CTFramesetterCreateWithAttributedString(newTitle)
            let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
            estimatedHeight += textSizeB.height
            
            if blocks.count > 1 {
                if startIndex == 0 {
                    setViews(blocks)
                } else {
                    blocks.remove(at: 0)
                    setViews(blocks)
                }
            }
        } else {
            var newTitle = title
            if body != nil {
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 5)]))
                newTitle.append(body!)
            } else {
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 5)]))
                newTitle.append(createAttributedChunk(baseHTML: htmlString))
            }
            let framesetterB = CTFramesetterCreateWithAttributedString(newTitle)
            let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
            estimatedHeight += textSizeB.height
        }
        
    }
    
    public func setData(htmlString: String) {
        
        //Start HTML parse
        var blocks = getBlocks(htmlString)
        
        var startIndex = 0
        
        if !blocks[0].startsWith("<table>") && !blocks[0].startsWith("<code>") {
            let text = createAttributedChunk(baseHTML: blocks[0])
            let framesetterB = CTFramesetterCreateWithAttributedString(text)
            let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
            estimatedHeight += textSizeB.height
            startIndex = 1
        }
        
        if blocks.count > 1 {
            if startIndex == 0 {
                setViews(blocks)
            } else {
                blocks.remove(at: 0)
                setViews(blocks)
            }
        }
    }
    
    func setViews(_ blocks: [String]) {
        for block in blocks {
            estimatedHeight += 8
            if block.startsWith("<table>") {
                let table = TableDisplayView.getEstimatedHeight(baseHtml: block)
                estimatedHeight += table
            } else if block.startsWith("<hr/>") {
                estimatedHeight += 1
            } else if block.startsWith("<code>") {
                let body = CodeDisplayView.init(baseHtml: block, color: ColorUtil.fontColor)
                estimatedHeight += body.globalHeight
            } else {
                let text = createAttributedChunk(baseHTML: block)
                let framesetterB = CTFramesetterCreateWithAttributedString(text)
                let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
                estimatedHeight += textSizeB.height
            }
        }
    }
    
    public func createAttributedChunk(baseHTML: String) -> NSAttributedString {
        let font = FontGenerator.fontOfSize(size: fontSize, submission: submission)
        let htmlBase = TextStackEstimator.addSpoilers(baseHTML)
        let html = DTHTMLAttributedStringBuilder.init(html: htmlBase.trimmed().data(using: .unicode)!, options: [DTUseiOS6Attributes: true, DTDefaultTextColor: ColorUtil.fontColor, DTDefaultFontFamily: font.familyName, DTDefaultFontSize: font.pointSize, DTDefaultFontName: font.fontName], documentAttributes: nil).generatedAttributedString()!
        
        return LinkParser.parse(html, .white)
    }

    public func getBlocks(_ html: String) -> [String] {
        
        var codeBlockSeperated = parseCodeTags(html)
        
        if html.contains(HR_TAG) {
            codeBlockSeperated = parseHR(codeBlockSeperated)
        }
        
        if html.contains("<table") {
            return parseTableTags(codeBlockSeperated)
        } else {
            return codeBlockSeperated
        }
    }
    
    /* Might add this in later, but iOS seems to handle this better than Android
     public func parseLists(_ html: String){
     var firstIndex = 0
     var isNumbered = false
     let firstOl = html.indexOf("<ol") ?? -1
     let firstUl = html.indexOf("<ul") ?? -1
     
     if ((firstUl != -1 && firstOl > firstUl) || firstOl == -1) {
     firstIndex = firstUl
     isNumbered = false
     } else {
     firstIndex = firstOl
     isNumbered = true
     }
     
     var listNumbers = [Int]()
     
     var indent = -1
     var i = firstIndex
     
     while (i < html.length - 4 && i != -1) {
     if (html.substring(i, length: 3) == "<ol" || html.substring(i, length: 3) == "<ul") {
     if (html.substring(i, length: 3) == "<ol") {
     isNumbered = true
     indent += 1
     listNumbers.insert(1, at: indent)
     } else {
     isNumbered = false
     }
     i = html.indexOf("<li", i)
     } else if (html.substring(i, length: 3) == "<li") {
     var tagEnd = html.indexOf(">", i)
     var itemClose = html.indexOf("</li", tagEnd)
     var ulClose = html.indexOf("<ul", tagEnd)
     var olClose = html.indexOf("<ol", tagEnd)
     var closeTag = ""
     
     // Find what is closest: </li>, <ul>, or <ol>
     if (((ulClose == -1 && itemClose != -1) || (itemClose != -1 && ulClose != -1 && itemClose < ulClose)) && ((olClose == -1 && itemClose != -1) || (itemClose != -1 && olClose != -1 && itemClose < olClose))) {
     closeTag = itemClose;
     } else if (((ulClose == -1 && olClose != -1) || (olClose != -1 && ulClose != -1 && olClose < ulClose)) && ((olClose == -1 && itemClose != -1) || (olClose != -1 && itemClose != -1 && olClose < itemClose))) {
     closeTag = olClose;
     } else {
     closeTag = ulClose;
     }
     
     String text = html.substring(tagEnd + 1, closeTag);
     String indentSpacing = "";
     for (int j = 0; j < indent; j++) {
     indentSpacing += "&nbsp;&nbsp;&nbsp;&nbsp;";
     }
     if (isNumbered) {
     html = html.substring(0, tagEnd + 1)
     + indentSpacing +
     listNumbers.get(indent)+ ". " +
     text + "<br/>" +
     html.substring(closeTag);
     listNumbers.set(indent, listNumbers.get(indent) + 1);
     i = closeTag + 3;
     } else {
     html = html.substring(0, tagEnd + 1) + indentSpacing + "• " + text + "<br/>" + html.substring(closeTag);
     i = closeTag + 2;
     }
     } else {
     i = html.indexOf("<", i + 1);
     if (i != -1 && html.substring(i, i + 4).equals("</ol")) {
     indent--;
     if(indent == -1){
     isNumbered = false;
     }
     }
     }
     }
     
     html = html.replace("<ol>","").replace("<ul>","").replace("<li>","").replace("</li>","").replace("</ol>", "").replace("</ul>",""); //Remove the tags, which actually work in Android 7.0 on
     
     return html
     }*/
    
    public func parseCodeTags(_ html: String) -> [String] {
        let startTag = "<code>"
        let endTag = "</code>"
        var startSeperated = html.components(separatedBy: startTag)
        var preSeperated = [String]()
        
        var text = ""
        var code = ""
        var split = [String]()
        
        preSeperated.append(startSeperated[0])
        if startSeperated.count > 1 {
            for i in 1...startSeperated.count - 1 {
                text = startSeperated[i]
                split = text.components(separatedBy: endTag)
                code = split[0]
                
                preSeperated.append(startTag + code + endTag)
                if split.count > 1 {
                    preSeperated.append(split[1])
                }
            }
        }
        
        return preSeperated
    }
    
    public func parseHR(_ blocks: [String]) -> [String] {
        var newBlocks = [String]()
        for block in blocks {
            if block.contains(HR_TAG) {
                for s in block.components(separatedBy: HR_TAG) {
                    newBlocks.append(s)
                    newBlocks.append(HR_TAG)
                }
                newBlocks.remove(at: newBlocks.count - 1)
            } else {
                newBlocks.append(block)
            }
        }
        
        return newBlocks
    }
    
    public func parseTableTags(_ blocks: [String]) -> [String] {
        var newBlocks = [String]()
        for block in blocks {
            if block.contains(TABLE_START_TAG) {
                var startSeperated = block.components(separatedBy: TABLE_START_TAG)
                newBlocks.append(startSeperated[0].trimmed())
                for i in 1...startSeperated.count - 1 {
                    var split = startSeperated[i].components(separatedBy: TABLE_END_TAG)
                    newBlocks.append("<table>" + split[0] + "</table>")
                    if split.count > 1 {
                        newBlocks.append(split[1])
                    }
                }
            } else {
                newBlocks.append(block)
            }
        }
        
        return newBlocks
    }
    
    public static func addSpoilers(_ text: String) -> String {
        var base = text
        var spoil = false
        
        for match in base.capturedGroups(withRegex: "<a[^>]*title=\"([^\"]*)\"[^>]*>([^<]*)</a>") {
            spoil = true
            let tag = match[0]
            let spoilerText = match[1]
            let spoilerTeaser = match[2]
            // Remove the last </a> tag, but keep the < for parsing.
            if !tag.contains("<a href=\"http") {
                base = base.replacingOccurrences(of: tag, with: tag.substring(0, length: tag.length - 4) + (spoilerTeaser.isEmpty() ? "spoiler" : "") + " [[s[ \(spoilerText)]s]]</a> ")
            }
        }
        
        //match unconventional spoiler tags
        for match in base.capturedGroups(withRegex: "<a href=\"([#/](?:spoiler|sp|s))\">([^<]*)</a>") {
            let newPiece = match[0]
            let inner = "<a href=\"/spoiler\">spoiler [[s[ \(newPiece.subsequence(newPiece.indexOf(">")! + 1, endIndex: newPiece.lastIndexOf("<")!))]s]]</a> "
            base = base.replacingOccurrences(of: match[0], with: inner)
        }
        
        //match native Reddit spoilers
        for match in base.capturedGroups(withRegex: "<span class=\"[^\"]*md-spoiler-text+[^\"]*\">([^<]*)</span>") {
            let tag = match[0]
            let spoilerText = match[1]
            base = base.replacingOccurrences(of: tag, with: "<a href=\"/spoiler\">spoiler  [[s[ \(spoilerText)]s]]</a> ")
        }
        
        return base
    }
}
