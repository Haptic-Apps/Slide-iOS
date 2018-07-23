//
//  TextDisplayStackView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import TTTAttributedLabel
import Anchorage
import DTCoreText

public class TextDisplayStackView: UIStackView {
    var baseString: NSAttributedString?
    let TABLE_START_TAG = "<table>"
    let HR_TAG = "<hr/>"
    let TABLE_END_TAG = "</table>"
    
    var estimatedWidth = CGFloat(0)
    var estimatedHeight = CGFloat(0)
    
    let firstTextView: TTTAttributedLabel
    let delegate: TTTAttributedLabelDelegate?
    let overflow: UIStackView
    
    let fontSize: CGFloat
    let submission: Bool
    var tColor: UIColor
    var baseFontColor: UIColor
    var tableCount = 0
    var tableData = [[[NSAttributedString]]]()
    
    init(){
        self.fontSize = 0
        self.submission = false
        self.tColor = .black
        delegate = nil
        self.baseFontColor = .white
        self.firstTextView = TTTAttributedLabel.init(frame: CGRect.zero)
        self.overflow = UIStackView()
        self.overflow.isUserInteractionEnabled = true
        super.init(frame: CGRect.zero)
    }
    
    func setColor(_ color: UIColor){
        self.tColor = color
    }
    
    init(fontSize: CGFloat, submission: Bool, color: UIColor, delegate: TTTAttributedLabelDelegate, width: CGFloat, baseFontColor: UIColor = ColorUtil.fontColor) {
        self.fontSize = fontSize
        self.submission = submission
        self.estimatedWidth = width
        self.delegate = delegate
        self.tColor = color
        self.baseFontColor = baseFontColor
        self.firstTextView = TTTAttributedLabel.init(frame: CGRect.zero).then({
            $0.accessibilityIdentifier = "Top title"
            $0.numberOfLines = 0
        })
        self.overflow = UIStackView().then({
            $0.accessibilityIdentifier = "Text overflow"
            $0.axis = .vertical
            $0.spacing = 8
        })
        firstTextView.delegate = delegate
        super.init(frame: CGRect.zero)
        self.axis = .vertical
        self.addArrangedSubviews(firstTextView, overflow)
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        firstTextView.horizontalAnchors == self.horizontalAnchors
        firstTextView.topAnchor == self.topAnchor
        overflow.bottomAnchor == self.bottomAnchor
        overflow.horizontalAnchors == self.horizontalAnchors
    }
    
    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setAttributedString(_ string: NSAttributedString){
        //Clear out old UIStackView from https://gist.github.com/Deub27/5eadbf1b77ce28abd9b630eadb95c1e2
        let removedSubviews = overflow.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            overflow.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        removedSubviews.forEach({ $0.removeFromSuperview() })
        overflow.isHidden = true
        
        let activeLinkAttributes = NSMutableDictionary(dictionary: firstTextView.activeLinkAttributes)
        activeLinkAttributes[NSForegroundColorAttributeName] = tColor
        firstTextView.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
        firstTextView.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
        
        firstTextView.setText(string)
        
        let framesetterB = CTFramesetterCreateWithAttributedString(string)
        let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
        estimatedHeight += textSizeB.height
    }
    
    public func setTextWithTitleHTML(_ title: NSAttributedString, _ body: NSAttributedString? = nil, htmlString: String){
        
        //Clear out old UIStackView from https://gist.github.com/Deub27/5eadbf1b77ce28abd9b630eadb95c1e2
        let removedSubviews = overflow.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            overflow.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        removedSubviews.forEach({ $0.removeFromSuperview() })
        overflow.isHidden = true
        
        if(htmlString.contains("<table") || htmlString.contains("<code") || htmlString.contains("<cite")) {
            var blocks = getBlocks(htmlString)
            
            var startIndex = 0
            
            var newTitle = NSMutableAttributedString(attributedString: title)
            
            if (!blocks[0].startsWith("<table>") && !blocks[0].startsWith("<cite>") && !blocks[0].startsWith("<code>")) {
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 5)]))
                newTitle.append(createAttributedChunk(baseHTML: blocks[0]))
                startIndex = 1
            }
            
            let activeLinkAttributes = NSMutableDictionary(dictionary: firstTextView.activeLinkAttributes)
            activeLinkAttributes[NSForegroundColorAttributeName] = tColor
            firstTextView.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            firstTextView.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            
            firstTextView.setText(newTitle)
            
            let framesetterB = CTFramesetterCreateWithAttributedString(newTitle)
            let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
            estimatedHeight += textSizeB.height
            
            if (blocks.count > 1) {
                if (startIndex == 0) {
                    setViews(blocks)
                } else {
                    blocks.remove(at: 0)
                    setViews(blocks)
                }
            }
        } else {
            var newTitle = NSMutableAttributedString(attributedString: title)
            if(body != nil){
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 5)]))
                newTitle.append(body!)
            } else if(!htmlString.isEmpty()){
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 5)]))
                newTitle.append(createAttributedChunk(baseHTML: htmlString))
            }
            
            let activeLinkAttributes = NSMutableDictionary(dictionary: firstTextView.activeLinkAttributes)
            activeLinkAttributes[NSForegroundColorAttributeName] = tColor
            firstTextView.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            firstTextView.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            
            firstTextView.setText(newTitle)
            
            let framesetterB = CTFramesetterCreateWithAttributedString(newTitle)
            let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
            estimatedHeight += textSizeB.height
        }
        
    }
    
    public func setData(htmlString: String){
        
        //Clear out old UIStackView from https://gist.github.com/Deub27/5eadbf1b77ce28abd9b630eadb95c1e2
        let removedSubviews = overflow.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            overflow.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        removedSubviews.forEach({ $0.removeFromSuperview() })
        overflow.isHidden = true
        
        //Start HTML parse
        var blocks = getBlocks(htmlString)
        
        var startIndex = 0
        
        if (!blocks[0].startsWith("<table>") && !blocks[0].startsWith("<cite>") && !blocks[0].startsWith("<code>")) {
            let text = createAttributedChunk(baseHTML: blocks[0])
            
            let activeLinkAttributes = NSMutableDictionary(dictionary: firstTextView.activeLinkAttributes)
            activeLinkAttributes[NSForegroundColorAttributeName] = tColor
            firstTextView.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            firstTextView.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            
            firstTextView.setText(text)
            
            let framesetterB = CTFramesetterCreateWithAttributedString(text)
            let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
            estimatedHeight += textSizeB.height
            startIndex = 1
        }
        
        if (blocks.count > 1) {
            if (startIndex == 0) {
                setViews(blocks)
            } else {
                blocks.remove(at: 0)
                setViews(blocks)
            }
        }
    }
    
    func setViews(_ blocks: [String]){
        if (!blocks.isEmpty) {
            overflow.isHidden = false
        }
        
        for block in blocks {
            estimatedHeight += 8
            if(block.startsWith("<table>")) {
                let table = TableDisplayView.init(baseHtml: block, color: baseFontColor, accentColor: tColor, delegate: delegate!)
                table.accessibilityIdentifier = "Table"
                overflow.addArrangedSubview(table)
                table.horizontalAnchors == overflow.horizontalAnchors
                table.heightAnchor == table.globalHeight
                table.backgroundColor = ColorUtil.backgroundColor.withAlphaComponent(0.5)
                table.clipsToBounds = true
                table.layer.cornerRadius = 10
                table.isUserInteractionEnabled = true
                table.contentOffset = CGPoint.init(x: -8, y: 0)
                estimatedHeight += table.globalHeight
                tableCount += 1
            } else if(block.startsWith("<hr/>")){
                let line = UIView()
                line.backgroundColor = ColorUtil.fontColor
                overflow.addArrangedSubview(line)
                estimatedHeight += 1
                line.heightAnchor == CGFloat(1)
                line.horizontalAnchors == overflow.horizontalAnchors
            } else if(block.startsWith("<code>")){
                let body = CodeDisplayView.init(baseHtml: block, color: baseFontColor)
                body.accessibilityIdentifier = "Code block"
                overflow.addArrangedSubview(body)
                body.horizontalAnchors == overflow.horizontalAnchors
                body.heightAnchor == body.globalHeight
                body.backgroundColor = ColorUtil.backgroundColor.withAlphaComponent(0.5)
                body.clipsToBounds = true
                estimatedHeight += body.globalHeight
                body.layer.cornerRadius = 10
                body.contentOffset = CGPoint.init(x: -8, y: -8)
            } else if(block.startsWith("<cite>")){
                let label = TTTAttributedLabel.init(frame: CGRect.zero)
                label.accessibilityIdentifier = "Quote"
                let text = createAttributedChunk(baseHTML: block)
                label.delegate = delegate
                label.alpha = 0.7
                label.numberOfLines = 0
                label.setText(text)
                
                let baseView = UIView()
                baseView.accessibilityIdentifier = "Quote box view"
                label.setBorder(border: .left, weight: 2, color: tColor)
                let framesetterB = CTFramesetterCreateWithAttributedString(text)
                let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth - 12, height: CGFloat.greatestFiniteMagnitude), nil)
                estimatedHeight += textSizeB.height
                baseView.addSubview(label)
                overflow.addArrangedSubview(baseView)

                baseView.horizontalAnchors == overflow.horizontalAnchors
                label.leftAnchor == baseView.leftAnchor + CGFloat(8)
                label.rightAnchor == baseView.rightAnchor - CGFloat(4)
                label.verticalAnchors == baseView.verticalAnchors
                label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
            } else {
                let label = TTTAttributedLabel.init(frame: CGRect.zero)
                label.accessibilityIdentifier = "New text"
                let text = createAttributedChunk(baseHTML: block)
                label.delegate = delegate
                let activeLinkAttributes = NSMutableDictionary(dictionary: label.activeLinkAttributes)
                activeLinkAttributes[NSForegroundColorAttributeName] = tColor
                label.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
                label.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
                label.numberOfLines = 0
                label.setText(text)
                let framesetterB = CTFramesetterCreateWithAttributedString(text)
                let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
                estimatedHeight += textSizeB.height
                label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
                overflow.addArrangedSubview(label)
                label.horizontalAnchors == overflow.horizontalAnchors
                label.heightAnchor == textSizeB.height
            }
        }
    }
    
    public func createAttributedChunk(baseHTML: String) -> NSAttributedString {
        let font = FontGenerator.fontOfSize(size: fontSize, submission: submission)
        let htmlBase = TextStackEstimator.addSpoilers(baseHTML)
        let baseHtml = DTHTMLAttributedStringBuilder.init(html: htmlBase.trimmed().data(using: .unicode)!, options: [DTUseiOS6Attributes: true, DTDefaultTextColor : ColorUtil.fontColor, DTDefaultFontFamily: font.familyName,DTDefaultFontSize: font.pointSize,  DTDefaultFontName: font.fontName], documentAttributes: nil).generatedAttributedString()!
        let html = NSMutableAttributedString(attributedString: baseHtml)
        
        while html.mutableString.contains("\t•\t") {
            let rangeOfStringToBeReplaced = html.mutableString.range(of: "\t•\t")
            html.replaceCharacters(in: rangeOfStringToBeReplaced, with: " • ")
        }
        while html.mutableString.contains("\t◦\t") {
            let rangeOfStringToBeReplaced = html.mutableString.range(of: "\t◦\t")
            html.replaceCharacters(in: rangeOfStringToBeReplaced, with: "  ◦ ")
        }
        while html.mutableString.contains("\t▪\t") {
            let rangeOfStringToBeReplaced = html.mutableString.range(of: "\t▪\t")
            html.replaceCharacters(in: rangeOfStringToBeReplaced, with: "   ▪ ")
        }
        
        html.enumerateAttribute(NSStrikethroughStyleAttributeName, in: NSRange(location:0, length: html.length), options: [], using: { (value: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if(value != nil && value is NSNumber && (value as! NSNumber) == 1){
                html.addAttributes([kCTForegroundColorAttributeName as String: ColorUtil.fontColor, NSBaselineOffsetAttributeName:NSNumber(floatLiteral: 0),"TTTStrikeOutAttribute": 1, NSStrikethroughStyleAttributeName:NSNumber(value:1)], range: range)
            }
        })
        
        return LinkParser.parse(html, .white)
    }
    
    public static func createAttributedChunk(baseHTML: String, fontSize: CGFloat, submission: Bool, accentColor: UIColor) -> NSAttributedString {
        let font = FontGenerator.fontOfSize(size: fontSize, submission: submission)
        let htmlBase = TextStackEstimator.addSpoilers(baseHTML)
        let baseHtml = DTHTMLAttributedStringBuilder.init(html: htmlBase.trimmed().data(using: .unicode)!, options: [DTUseiOS6Attributes: true, DTDefaultTextColor : ColorUtil.fontColor, DTDefaultFontFamily: font.familyName, DTDefaultFontSize: font.pointSize,  DTDefaultFontName: font.fontName], documentAttributes: nil).generatedAttributedString()!
        let html = NSMutableAttributedString(attributedString: baseHtml)
        
        while html.mutableString.contains("\t•\t") {
            let rangeOfStringToBeReplaced = html.mutableString.range(of: "\t•\t")
            html.replaceCharacters(in: rangeOfStringToBeReplaced, with: " • ")
        }
        while html.mutableString.contains("\t◦\t") {
            let rangeOfStringToBeReplaced = html.mutableString.range(of: "\t◦\t")
            html.replaceCharacters(in: rangeOfStringToBeReplaced, with: "\t\t◦ ")
        }
        while html.mutableString.contains("\t▪\t") {
            let rangeOfStringToBeReplaced = html.mutableString.range(of: "\t▪\t")
            html.replaceCharacters(in: rangeOfStringToBeReplaced, with: "\t\t\t▪ ")
        }

        html.enumerateAttribute(NSStrikethroughStyleAttributeName, in: NSRange(location:0, length: html.length), options: [], using: { (value: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if(value != nil && value is NSNumber && (value as! NSNumber) == 1){
                html.addAttributes([kCTForegroundColorAttributeName as String: ColorUtil.fontColor, NSBaselineOffsetAttributeName:NSNumber(floatLiteral: 0),"TTTStrikeOutAttribute": 1, NSStrikethroughStyleAttributeName:NSNumber(value:1)], range: range)
            }
        })
        return LinkParser.parse(html, accentColor)
    }
    
    public func link(at: CGPoint, withTouch: UITouch) -> TTTAttributedLabelLink? {
        if let link = firstTextView.link(at: at){
            return link
        }
        if(overflow.isHidden){
            return nil
        }
        
        for view in self.overflow.subviews {
            if(view is TTTAttributedLabel){
                if let link = (view as! TTTAttributedLabel).link(at: withTouch.location(in: view)){
                    return link
                }
            } else if(view is TableDisplayView){
                //Dont pass any touches through Table
                if(view.bounds.contains( withTouch.location(in: view))){
                    return TTTAttributedLabelLink.init()
                }
            }
        }
        return nil
    }
    
    public func getBlocks(_ html: String) -> [String] {
        
        var codeBlockSeperated = parseCodeTags(html)
        
        if (html.contains(HR_TAG)) {
            codeBlockSeperated = parseHR(codeBlockSeperated)
        }
        
        if (html.contains("<cite>")) {
            codeBlockSeperated = parseBlockquote(codeBlockSeperated)
        }
        
        if (html.contains("<table")) {
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
        if(startSeperated.count > 1){
            for i in 1...startSeperated.count - 1 {
                text = startSeperated[i]
                split = text.components(separatedBy: endTag)
                code = split[0]
                
                preSeperated.append(startTag + code + endTag)
                if (split.count > 1) {
                    preSeperated.append(split[1])
                }
            }
        }
        
        return preSeperated
    }
    
    public func parseHR(_ blocks: [String]) -> [String] {
        var newBlocks = [String]()
        for block in blocks {
            if (block.contains(HR_TAG)) {
                for s in block.components(separatedBy: HR_TAG){
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
    
    public func parseBlockquote(_ blocks: [String]) -> [String] {
        let startTag = "<cite>"
        let endTag = "</cite>"
        
        var preSeperated = [String]()
        for html in blocks {
            var startSeperated = html.components(separatedBy: startTag)
            
            var text = ""
            var code = ""
            var split = [String]()
            
            preSeperated.append(startSeperated[0])
            if(startSeperated.count > 1){
                for i in 1...startSeperated.count - 1 {
                    text = startSeperated[i]
                    split = text.components(separatedBy: endTag)
                    code = split[0]
                    
                    preSeperated.append(startTag + code + endTag)
                    if (split.count > 1) {
                        preSeperated.append(split[1])
                    }
                }
            }
        }
        
        return preSeperated
    }
    
    public func parseTableTags(_ blocks: [String]) -> [String] {
        var newBlocks = [String]()
        for block in blocks {
            if (block.contains(TABLE_START_TAG)) {
                var startSeperated = block.components(separatedBy: TABLE_START_TAG)
                newBlocks.append(startSeperated[0].trimmed())
                for i in 1...startSeperated.count - 1 {
                    var split = startSeperated[i].components(separatedBy: TABLE_END_TAG)
                    let table = "<table>" + split[0] + "</table>"
                    newBlocks.append(table)
                    if (split.count > 1) {
                        newBlocks.append(split[1])
                    }
                }
            } else {
                newBlocks.append(block)
            }
        }
        
        return newBlocks
    }
    
    public func addSpoilers(_ text: String) -> String {
        var base = text
        var spoil = false
        
        for match in base.capturedGroups(withRegex: "<a[^>]*title=\"([^\"]*)\"[^>]*>([^<]*)</a>") {
            spoil = true
            let tag = match[0]
            let spoilerText = match[1]
            let spoilerTeaser = match[2]
            // Remove the last </a> tag, but keep the < for parsing.
            if (!tag.contains("<a href=\"http")) {
                base = base.replacingOccurrences(of: tag, with: tag.substring(0, length: tag.length - 4) + (spoilerTeaser.isEmpty() ? "spoiler" : "") + " [[s[ \(spoilerText)]s]]</a> ");
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
