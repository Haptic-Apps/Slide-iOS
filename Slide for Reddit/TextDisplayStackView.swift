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
    var tableCount = 0
    var tableData = [[[NSAttributedString]]]()
    
    init(){
        self.fontSize = 0
        self.submission = false
        self.tColor = .black
        delegate = nil
        self.firstTextView = TTTAttributedLabel.init(frame: CGRect.zero)
        self.overflow = UIStackView()
        super.init(frame: CGRect.zero)
    }
    
    func setColor(_ color: UIColor){
        self.tColor = color
    }

    init(fontSize: CGFloat, submission: Bool, color: UIColor, delegate: TTTAttributedLabelDelegate, width: CGFloat) {
        self.fontSize = fontSize
        self.submission = submission
        self.estimatedWidth = width
        self.delegate = delegate
        self.tColor = color
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
        
        firstTextView.setText(string)
        let framesetterB = CTFramesetterCreateWithAttributedString(string)
        let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
        estimatedHeight += textSizeB.height
    }
    
    public func setTextWithTitleHTML(_ title: NSMutableAttributedString, _ body: NSAttributedString? = nil, htmlString: String){
        
        //Clear out old UIStackView from https://gist.github.com/Deub27/5eadbf1b77ce28abd9b630eadb95c1e2
        let removedSubviews = overflow.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            overflow.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        removedSubviews.forEach({ $0.removeFromSuperview() })
        overflow.isHidden = true

        if(htmlString.contains("<table") || htmlString.contains("<code")) {
            let rawHTML = addSpoilers(htmlString)
            var blocks = getBlocks(rawHTML)
            
            var startIndex = 0
            
            var newTitle = title
            
            if (!blocks[0].startsWith("<table>") && !blocks[0].startsWith("<code>")) {
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 5)]))
                newTitle.append(createAttributedChunk(baseHTML: blocks[0]))
                startIndex = 1
            }
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
            var newTitle = title
            if(body != nil){
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 5)]))
                newTitle.append(body!)
            } else {
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 5)]))
                newTitle.append(createAttributedChunk(baseHTML: htmlString))
            }
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
        let rawHTML = addSpoilers(htmlString)
        var blocks = getBlocks(rawHTML)
        
        var startIndex = 0

        if (!blocks[0].startsWith("<table>") && !blocks[0].startsWith("<code>")) {
            let text = createAttributedChunk(baseHTML: blocks[0])
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
                let table = TableDisplayView.init(baseHtml: block, color: ColorUtil.fontColor)
                table.accessibilityIdentifier = "Table"
                overflow.addArrangedSubview(table)
                table.horizontalAnchors == overflow.horizontalAnchors
                table.heightAnchor == table.globalHeight
                table.backgroundColor = ColorUtil.backgroundColor
                table.clipsToBounds = true
                table.layer.cornerRadius = 10
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
                let body = CodeDisplayView.init(baseHtml: block, color: ColorUtil.fontColor)
                body.accessibilityIdentifier = "Code block"
                overflow.addArrangedSubview(body)
                body.horizontalAnchors == overflow.horizontalAnchors
                body.heightAnchor == body.globalHeight
                body.backgroundColor = ColorUtil.backgroundColor
                body.clipsToBounds = true
                estimatedHeight += body.globalHeight
                body.layer.cornerRadius = 10
                body.contentOffset = CGPoint.init(x: -8, y: 0)
            } else {
                let label = TTTAttributedLabel.init(frame: CGRect.zero)
                label.accessibilityIdentifier = "New text"
                let text = createAttributedChunk(baseHTML: block)
                label.setText(text)
                let framesetterB = CTFramesetterCreateWithAttributedString(text)
                let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
                estimatedHeight += textSizeB.height
                label.numberOfLines = 0
                overflow.addArrangedSubview(label)
                label.horizontalAnchors == overflow.horizontalAnchors
                label.heightAnchor == textSizeB.height
                label.delegate = delegate
            }
        }
    }
    
    public func createAttributedChunk(baseHTML: String) -> NSAttributedString {
        do {
            let baseAttributedString = try NSMutableAttributedString(data: baseHTML.data(using: .unicode)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
            let font = FontGenerator.fontOfSize(size: fontSize, submission: submission)
            let constructedString = baseAttributedString.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: tColor)
            return LinkParser.parse(constructedString, tColor)
        } catch {
            return NSMutableAttributedString.init(string: baseHTML)
        }
    }
    
    public func getBlocks(_ html: String) -> [String] {

        var codeBlockSeperated = parseCodeTags(html)
        
        if (html.contains(HR_TAG)) {
            codeBlockSeperated = parseHR(codeBlockSeperated)
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
