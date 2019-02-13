//
//  TextDisplayStackView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import DTCoreText
import Then
import UIKit
import YYText

public protocol TextDisplayStackViewDelegate: class {
    func linkTapped(url: URL)
    func linkLongTapped(url: URL)
}

public class TextDisplayStackView: UIStackView {
    var baseString: NSAttributedString?
    let TABLE_START_TAG = "<table>"
    let HR_TAG = "<hr/>"
    let TABLE_END_TAG = "</table>"
    
    var estimatedWidth = CGFloat(0)
    var estimatedHeight = CGFloat(0)
    weak var parentLongPress: UILongPressGestureRecognizer?
    
    let firstTextView: YYLabel
    let overflow: UIStackView
    
    let fontSize: CGFloat
    let submission: Bool
    var tColor: UIColor
    var baseFontColor: UIColor
    var tableCount = 0
    var tableData = [[[NSAttributedString]]]()
    var delegate: TextDisplayStackViewDelegate

    var ignoreHeight = false
    var touchLinkAction: YYTextAction?
    var longTouchLinkAction: YYTextAction?

    var activeSet = false
    
    init(delegate: TextDisplayStackViewDelegate) {
        self.fontSize = 0
        self.submission = false
        self.tColor = .black
        self.baseFontColor = .white
        self.delegate = delegate
        self.firstTextView = YYLabel(frame: .zero)
        self.overflow = UIStackView()
        self.overflow.isUserInteractionEnabled = true
        super.init(frame: CGRect.zero)
        self.touchLinkAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
            text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, _, _) in
                for attr in attrs {
                    if attr.value is YYTextHighlight {
                        if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                            self.delegate.linkTapped(url: url)
                            return
                        }
                    }
                }
            })
        }
        self.longTouchLinkAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
            text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, _, _) in
                for attr in attrs {
                    if attr.value is YYTextHighlight {
                        if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                            self.delegate.linkLongTapped(url: url)
                            return
                        }
                    }
                }
            })
        }

        self.isUserInteractionEnabled = true
        self.firstTextView.highlightLongPressAction = longTouchLinkAction
        self.firstTextView.highlightTapAction = touchLinkAction
    }
    
    func setColor(_ color: UIColor) {
        self.tColor = color
    }
    
    init(fontSize: CGFloat, submission: Bool, color: UIColor, width: CGFloat, baseFontColor: UIColor = ColorUtil.fontColor, delegate: TextDisplayStackViewDelegate) {
        self.fontSize = fontSize
        self.submission = submission
        self.estimatedWidth = width
        self.tColor = color
        self.delegate = delegate
        self.baseFontColor = baseFontColor
        self.firstTextView = YYLabel(frame: CGRect.zero).then({
            $0.accessibilityIdentifier = "Top title"
            $0.numberOfLines = 0
            $0.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        })

        self.overflow = UIStackView().then({
            $0.accessibilityIdentifier = "Text overflow"
            $0.axis = .vertical
            $0.spacing = 8
        })
        super.init(frame: CGRect.zero)

        self.axis = .vertical
        self.addArrangedSubviews(firstTextView, overflow)
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.isUserInteractionEnabled = true

        firstTextView.horizontalAnchors == self.horizontalAnchors
        firstTextView.topAnchor == self.topAnchor
        overflow.bottomAnchor == self.bottomAnchor
        overflow.horizontalAnchors == self.horizontalAnchors
        self.touchLinkAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
            text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, range, _) in
                for attr in attrs {
                    if attr.value is YYTextHighlight {
                        if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                            self.delegate.linkTapped(url: url)
                            return
                        }
                    }
                }
            })
        }
        self.longTouchLinkAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
            text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, _, _) in
                for attr in attrs {
                    if attr.value is YYTextHighlight {
                        if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                            self.delegate.linkLongTapped(url: url)
                            return
                        }
                    }
                }
            })
        }
        self.firstTextView.highlightLongPressAction = longTouchLinkAction
        self.firstTextView.highlightTapAction = touchLinkAction
    }
    
    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setAttributedString(_ string: NSAttributedString) {
        estimatedHeight = 0
        //Clear out old UIStackView from https://gist.github.com/Deub27/5eadbf1b77ce28abd9b630eadb95c1e2
        let removedSubviews = overflow.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            overflow.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        removedSubviews.forEach({ $0.removeFromSuperview() })
        overflow.isHidden = true
        
        if !activeSet {
            activeSet = true
        }

        firstTextView.attributedText = string
        firstTextView.preferredMaxLayoutWidth = estimatedWidth

        if !ignoreHeight {
//            let framesetterB = CTFramesetterCreateWithAttributedString(string)
//            let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
//            estimatedHeight += textSizeB.height

            let size = CGSize(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude)
            let layout = YYTextLayout(containerSize: size, text: string)!
            firstTextView.textLayout = layout
            estimatedHeight += layout.textBoundingSize.height
            firstTextView.horizontalAnchors == horizontalAnchors
            firstTextView.heightAnchor == layout.textBoundingSize.height
        }

    }
    
    public func setTextWithTitleHTML(_ title: NSAttributedString, _ body: NSAttributedString? = nil, htmlString: String) {
        estimatedHeight = 0
        //Clear out old UIStackView from https://gist.github.com/Deub27/5eadbf1b77ce28abd9b630eadb95c1e2
        let removedSubviews = overflow.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            overflow.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        removedSubviews.forEach({ $0.removeFromSuperview() })
        overflow.isHidden = true
        
        if htmlString.contains("<table") || htmlString.contains("<code") || htmlString.contains("<cite") {
            var blocks = getBlocks(htmlString)
            
            var startIndex = 0
            
            let newTitle = NSMutableAttributedString(attributedString: title)
            if !blocks[0].startsWith("<table>") && !blocks[0].startsWith("<cite>") && !blocks[0].startsWith("<code>") {
                if !blocks[0].trimmed().isEmpty() && blocks[0].trimmed() != "<div class=\"md\">" {
                    newTitle.append(NSAttributedString.init(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 5)])))
                    newTitle.append(createAttributedChunk(baseHTML: blocks[0], accent: tColor))
                }
                startIndex = 1
            }
            
            firstTextView.attributedText = newTitle
            firstTextView.preferredMaxLayoutWidth = estimatedWidth

            if !ignoreHeight {
//                let framesetterB = CTFramesetterCreateWithAttributedString(newTitle)
//                let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
//                estimatedHeight += textSizeB.height

                let size = CGSize(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude)
                let layout = YYTextLayout(containerSize: size, text: newTitle)!
                estimatedHeight += layout.textBoundingSize.height
            }
            
            if blocks.count > 1 {
                if startIndex == 0 {
                    setViews(blocks)
                } else {
                    blocks.remove(at: 0)
                    setViews(blocks)
                }
            }
        } else {
            let newTitle = NSMutableAttributedString(attributedString: title)
            if body != nil {
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 5)])))
                newTitle.append(body!)
            } else if !htmlString.isEmpty() {
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 5)])))
                newTitle.append(createAttributedChunk(baseHTML: htmlString, accent: tColor))
            }
            
//            let activeLinkAttributes = NSMutableDictionary(dictionary: firstTextView.activeLinkAttributes)
//            activeLinkAttributes[kCTForegroundColorAttributeName] = tColor
//            firstTextView.activeLinkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
//            firstTextView.linkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]

            firstTextView.attributedText = newTitle
            firstTextView.preferredMaxLayoutWidth = estimatedWidth
            
            if !ignoreHeight {
//                let framesetterB = CTFramesetterCreateWithAttributedString(newTitle)
//                let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
//                estimatedHeight += textSizeB.height

                let size = CGSize(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude)
                let layout = YYTextLayout(containerSize: size, text: newTitle)!
                firstTextView.textLayout = layout
                estimatedHeight += layout.textBoundingSize.height
                firstTextView.heightAnchor == layout.textBoundingSize.height
                firstTextView.horizontalAnchors == horizontalAnchors
            }

        }
        
    }
    
    public func setData(htmlString: String) {
        estimatedHeight = 0
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
        
        if !blocks[0].startsWith("<table>") && !blocks[0].startsWith("<cite>") && !blocks[0].startsWith("<code>") {
            let text = createAttributedChunk(baseHTML: blocks[0], accent: tColor)
            
            if !activeSet {
                activeSet = true
//                let activeLinkAttributes = NSMutableDictionary(dictionary: firstTextView.activeLinkAttributes)
//                activeLinkAttributes[kCTForegroundColorAttributeName] = tColor
//                firstTextView.activeLinkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
//                firstTextView.linkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
            }
            
            firstTextView.attributedText = text
            firstTextView.preferredMaxLayoutWidth = estimatedWidth

            if !ignoreHeight {
//                let framesetterB = CTFramesetterCreateWithAttributedString(text)
//                let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
//                estimatedHeight += textSizeB.height

                let size = CGSize(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude)
                let layout = YYTextLayout(containerSize: size, text: text)!
                estimatedHeight += layout.textBoundingSize.height
            }

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
        if !blocks.isEmpty {
            overflow.isHidden = false
        }
        
        for block in blocks {
            estimatedHeight += 8
            if block.startsWith("<table>") {
                let table = TableDisplayView(baseHtml: block, color: baseFontColor, accentColor: tColor, action: self.touchLinkAction, longAction: self.longTouchLinkAction)
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
            } else if block.startsWith("<hr/>") {
                let line = UIView()
                line.backgroundColor = ColorUtil.fontColor
                overflow.addArrangedSubview(line)
                estimatedHeight += 1
                line.heightAnchor == CGFloat(1)
                line.horizontalAnchors == overflow.horizontalAnchors
            } else if block.startsWith("<code>") {
                let body = CodeDisplayView.init(baseHtml: block, color: baseFontColor)
                body.accessibilityIdentifier = "Code block"
                overflow.addArrangedSubview(body)
                body.horizontalAnchors == overflow.horizontalAnchors
                body.heightAnchor >= body.globalHeight
                body.backgroundColor = ColorUtil.backgroundColor.withAlphaComponent(0.5)
                body.clipsToBounds = true
                estimatedHeight += body.globalHeight
                body.layer.cornerRadius = 10
                body.contentOffset = CGPoint.init(x: -8, y: -8)
                body.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
            } else if block.startsWith("<cite>") {
                let label = YYLabel(frame: .zero)
                label.accessibilityIdentifier = "Quote"
                let text = createAttributedChunk(baseHTML: block.replacingOccurrences(of: "<cite>", with: "").replacingOccurrences(of: "</cite>", with: "").trimmed(), accent: tColor)
                label.alpha = 0.7
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
                label.highlightLongPressAction = longTouchLinkAction
                label.highlightTapAction = touchLinkAction
                
                let baseView = UIView()
                baseView.accessibilityIdentifier = "Quote box view"
                label.setBorder(border: .left, weight: 2, color: tColor)
                
                let size = CGSize(width: estimatedWidth - 8, height: CGFloat.greatestFiniteMagnitude)
                let layout = YYTextLayout(containerSize: size, text: text)!
                estimatedHeight += layout.textBoundingSize.height
                label.textLayout = layout
                label.attributedText = text

                baseView.addSubview(label)
                label.leftAnchor == baseView.leftAnchor + CGFloat(8)
                label.rightAnchor == baseView.rightAnchor - CGFloat(4)
                label.topAnchor == baseView.topAnchor
                label.bottomAnchor == baseView.bottomAnchor
                label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
                overflow.addArrangedSubview(baseView)
                            
                baseView.horizontalAnchors == overflow.horizontalAnchors
                baseView.heightAnchor == layout.textBoundingSize.height
            } else {
                let text = createAttributedChunk(baseHTML: block.trimmed(), accent: tColor)
                let label = YYLabel(frame: CGRect.zero).then {
                    $0.accessibilityIdentifier = "Paragraph"
                    $0.numberOfLines = 0
                    $0.lineBreakMode = .byWordWrapping
                    $0.attributedText = text
                    $0.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
                }
                label.highlightLongPressAction = longTouchLinkAction
                label.highlightTapAction = touchLinkAction

                let size = CGSize(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude)
                let layout = YYTextLayout(containerSize: size, text: text)!
                estimatedHeight += layout.textBoundingSize.height

                overflow.addArrangedSubview(label)

                label.horizontalAnchors == overflow.horizontalAnchors
                label.heightAnchor == layout.textBoundingSize.height
            }
        }
        overflow.setNeedsLayout()
    }
    
    public func createAttributedChunk(baseHTML: String, accent: UIColor) -> NSAttributedString {
        let font = FontGenerator.fontOfSize(size: fontSize, submission: submission)
        let htmlBase = TextStackEstimator.addSpoilers(baseHTML).replacingOccurrences(of: "<sup>", with: "<font size=\"1\">").replacingOccurrences(of: "</sup>", with: "</font>")
        let baseHtml = DTHTMLAttributedStringBuilder.init(html: htmlBase.trimmed().data(using: .unicode)!, options: [DTUseiOS6Attributes: true, DTDefaultTextColor: ColorUtil.fontColor, DTDefaultFontFamily: font.familyName, DTDefaultFontSize: font.pointSize, DTDefaultFontName: font.fontName], documentAttributes: nil).generatedAttributedString()!
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
        
        html.enumerateAttribute(NSAttributedString.Key.strikethroughStyle, in: NSRange(location: 0, length: html.length), options: [], using: { (value: Any?, range: NSRange, _: UnsafeMutablePointer<ObjCBool>) -> Void in
            if value != nil && value is NSNumber && (value as! NSNumber) == 1 {
                html.addAttributes(convertToNSAttributedStringKeyDictionary([kCTForegroundColorAttributeName as String: ColorUtil.fontColor, convertFromNSAttributedStringKey(NSAttributedString.Key.baselineOffset): 0, "TTTStrikeOutAttribute": 1, convertFromNSAttributedStringKey(NSAttributedString.Key.strikethroughStyle): NSNumber(value: 1)]), range: range)
            }
        })
        
        html.enumerateAttribute(NSAttributedString.Key.strikethroughStyle, in: NSRange(location: 0, length: html.length), options: [], using: { (value: Any?, range: NSRange, _: UnsafeMutablePointer<ObjCBool>) -> Void in
            if value != nil && value is NSNumber && (value as! NSNumber) == 1 {
                html.addAttributes(convertToNSAttributedStringKeyDictionary([kCTForegroundColorAttributeName as String: ColorUtil.fontColor, convertFromNSAttributedStringKey(NSAttributedString.Key.baselineOffset): 0, "TTTStrikeOutAttribute": 1, convertFromNSAttributedStringKey(NSAttributedString.Key.strikethroughStyle): NSNumber(value: 1)]), range: range)
            }
        })

        return LinkParser.parse(html, accent)
    }
    
    public static func
        createAttributedChunk(baseHTML: String, fontSize: CGFloat, submission: Bool, accentColor: UIColor) -> NSAttributedString {
        let font = FontGenerator.fontOfSize(size: fontSize, submission: submission)
        let htmlBase = TextStackEstimator.addSpoilers(baseHTML)
        let options = [DTUseiOS6Attributes: true, DTDefaultTextColor: ColorUtil.fontColor, DTDefaultFontFamily: font.familyName, DTDefaultFontSize: font.pointSize, DTDefaultFontName: font.fontName] as [String: Any]
        let baseHtml = DTHTMLAttributedStringBuilder.init(html: htmlBase.trimmed().data(using: .unicode)!, options: options, documentAttributes: nil).generatedAttributedString()!
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

        html.enumerateAttribute(NSAttributedString.Key.strikethroughStyle, in: NSRange(location: 0, length: html.length), options: [], using: { (value: Any?, range: NSRange, _: UnsafeMutablePointer<ObjCBool>) -> Void in
            if value != nil && value is NSNumber && (value as! NSNumber) == 1 {
                html.addAttributes(convertToNSAttributedStringKeyDictionary([kCTForegroundColorAttributeName as String: ColorUtil.fontColor, convertFromNSAttributedStringKey(NSAttributedString.Key.baselineOffset): 0, "TTTStrikeOutAttribute": 1, convertFromNSAttributedStringKey(NSAttributedString.Key.strikethroughStyle): NSNumber(value: 1)]), range: range)
            }
        })
        return LinkParser.parse(html, accentColor)
    }
    
//    public func link(at: CGPoint, withTouch: UITouch) -> TTTAttributedLabelLink? {
//        if let link = firstTextView.link(at: at) {
//            return link
//        }
//        if overflow.isHidden {
//            return nil
//        }
//
//        for view in self.overflow.subviews {
//            if view is TTTAttributedLabel {
//                if let link = (view as! TTTAttributedLabel).link(at: withTouch.location(in: view)) {
//                    return link
//                }
//            } else if view is TableDisplayView {
//                //Dont pass any touches through Table
//                if view.bounds.contains( withTouch.location(in: view)) {
//                    return TTTAttributedLabelLink.init()
//                }
//            }
//        }
//        return nil
//    }

    public func getBlocks(_ html: String) -> [String] {
        
        var codeBlockSeperated = parseCodeTags(html)
        
        if html.contains(HR_TAG) {
            codeBlockSeperated = parseHR(codeBlockSeperated)
        }
        
        if html.contains("<cite>") {
            codeBlockSeperated = parseBlockquote(codeBlockSeperated)
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
            for i in 1 ..< startSeperated.count {
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
            if startSeperated.count > 1 {
                for i in 1 ..< startSeperated.count {
                    text = startSeperated[i]
                    split = text.components(separatedBy: endTag)
                    code = split[0]
                    
                    preSeperated.append(startTag + code + endTag)
                    if split.count > 1 {
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
            if block.contains(TABLE_START_TAG) {
                var startSeperated = block.components(separatedBy: TABLE_START_TAG)
                newBlocks.append(startSeperated[0].trimmed())
                for i in 1 ..< startSeperated.count {
                    var split = startSeperated[i].components(separatedBy: TABLE_END_TAG)
                    let table = "<table>" + split[0] + "</table>"
                    newBlocks.append(table)
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
    
    public func addSpoilers(_ text: String) -> String {
        var base = text
        
        for match in base.capturedGroups(withRegex: "<a[^>]*title=\"([^\"]*)\"[^>]*>([^<]*)</a>") {
            let tag = match[0]
            let spoilerText = match[1]
            let spoilerTeaser = match[2]
            // Remove the last </a> tag, but keep the < for parsing.
            if !tag.contains("<a href=\"http") && !tag.contains("<a href=\"/r") {
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

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
