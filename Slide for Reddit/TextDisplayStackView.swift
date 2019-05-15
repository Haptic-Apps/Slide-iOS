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
    func linkTapped(url: URL, text: String)
    func linkLongTapped(url: URL)
}

public class TextDisplayStackView: UIStackView {
    var baseString: NSAttributedString?
    static let TABLE_START_TAG = "<table>"
    static let HR_TAG = "<hr/>"
    static let TABLE_END_TAG = "</table>"
    
    var estimatedWidth = CGFloat(0)
    var estimatedHeight = CGFloat(0)
    weak var parentLongPress: UILongPressGestureRecognizer?
    
    let firstTextView: YYLabel
    let overflow: UIStackView
    let links: UIScrollView
    
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
        self.links = TouchUIScrollView()
        self.links.isUserInteractionEnabled = true
        super.init(frame: CGRect.zero)
        self.distribution = .fill

        self.touchLinkAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
            text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, smallRange, _) in
                for attr in attrs {
                    if attr.value is YYTextHighlight {
                        if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                            self.delegate.linkTapped(url: url, text: "")
                            return
                        } else if (attr.value as! YYTextHighlight).userInfo?["spoiler"] as? Bool ?? false {
                            self.delegate.linkTapped(url: URL(string: "/s")!, text: text.attributedSubstring(from: smallRange).string)
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
    
    init(fontSize: CGFloat, submission: Bool, color: UIColor, width: CGFloat, baseFontColor: UIColor = ColorUtil.theme.fontColor, delegate: TextDisplayStackViewDelegate) {
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
        self.links = TouchUIScrollView()
        self.links.isUserInteractionEnabled = true
        self.overflow = UIStackView().then({
            $0.accessibilityIdentifier = "Text overflow"
            $0.axis = .vertical
            $0.spacing = 8
        })
        super.init(frame: CGRect.zero)

        self.axis = .vertical
        self.addArrangedSubviews(firstTextView, overflow, links)
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.isUserInteractionEnabled = true

        firstTextView.horizontalAnchors == self.horizontalAnchors
        overflow.horizontalAnchors == self.horizontalAnchors
        links.horizontalAnchors == self.horizontalAnchors

        self.touchLinkAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
            text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, smallRange, _) in
                for attr in attrs {
                    if attr.value is YYTextHighlight {
                        if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                            self.delegate.linkTapped(url: url, text: "")
                            return
                        } else if (attr.value as! YYTextHighlight).userInfo?["spoiler"] as? Bool ?? false {
                            self.delegate.linkTapped(url: URL(string: "/s")!, text: text.attributedSubstring(from: smallRange).string)
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
        clearOverflow()
        
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
            firstTextView.removeConstraints(addedConstraints)
            addedConstraints = batch {
                firstTextView.heightAnchor == layout.textBoundingSize.height
            }
        }

    }
    
    var addedConstraints = [NSLayoutConstraint]()
    
    func clearOverflow() {
        //Clear out old UIStackView from https://gist.github.com/Deub27/5eadbf1b77ce28abd9b630eadb95c1e2
        let removedSubviews = overflow.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            overflow.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        removedSubviews.forEach({ $0.removeFromSuperview() })
        overflow.isHidden = true
        
        NSLayoutConstraint.deactivate(links.subviews.flatMap({ $0.constraints }))
        
        links.subviews.forEach({ $0.removeFromSuperview() })
        links.isHidden = true
    }
    
    public func setTextWithTitleHTML(_ title: NSAttributedString, _ body: NSAttributedString? = nil, htmlString: String) {
        estimatedHeight = 0
        clearOverflow()
        
        var allLinks = [URL]()
        let linkCallback = { link in
            allLinks.append(link)
        }
        let indexCallback: () -> Int = {
            return allLinks.count
        }
        if htmlString.contains("<table") || htmlString.contains("<pre><code") || htmlString.contains("<cite") {
            var blocks = TextDisplayStackView.getBlocks(htmlString)
            
            var startIndex = 0
            
            let newTitle = NSMutableAttributedString(attributedString: title)
            if !blocks[0].startsWith("<table>") && !blocks[0].startsWith("<cite>") && !blocks[0].startsWith("<pre><code>") {
                if !blocks[0].trimmed().isEmpty() && blocks[0].trimmed() != "<div class=\"md\">" {
                    if !newTitle.string.trimmed().isEmpty {
                        newTitle.append(NSAttributedString.init(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 5)])))
                    }
                    newTitle.append(createAttributedChunk(baseHTML: blocks[0], accent: tColor, linksCallback: linkCallback, indexCallback: indexCallback))
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
                    setViews(blocks, linksCallback: linkCallback, indexCallback: indexCallback)
                } else {
                    blocks.remove(at: 0)
                    setViews(blocks, linksCallback: linkCallback, indexCallback: indexCallback)
                }
            }
        } else {
            let newTitle = NSMutableAttributedString(attributedString: title)
            if body != nil {
                let mutableBody = NSMutableAttributedString(attributedString: body!)
                if !newTitle.string.trimmed().isEmpty {
                    newTitle.append(NSAttributedString.init(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 5)])))
                }
                if allLinks.isEmpty && body != nil {
                    mutableBody.enumerateAttributes(in: NSRange.init(location: 0, length: body!.length), options: .longestEffectiveRangeNotRequired, using: { (attrs, range, _) in
                        for attr in attrs {
                            if let url = attr.value as? URL {
                                let type = ContentType.getContentType(baseUrl: url)
                                if type != .SPOILER {
                                    linkCallback(url)
                                    let positionString = NSMutableAttributedString.init(string: "†\(indexCallback())", attributes: [NSAttributedString.Key.foregroundColor: baseFontColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10)])
                                    mutableBody.insert(positionString, at: range.location + range.length)
                                }
                                break
                            }
                        }
                    })
                }
                newTitle.append(mutableBody)
            } else if !htmlString.isEmpty() {
                if !newTitle.string.trimmed().isEmpty {
                    newTitle.append(NSAttributedString.init(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 5)])))
                }
                newTitle.append(createAttributedChunk(baseHTML: htmlString, accent: tColor, linksCallback: linkCallback, indexCallback: indexCallback))
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
                firstTextView.removeConstraints(addedConstraints)
                addedConstraints = batch {
                    firstTextView.heightAnchor == layout.textBoundingSize.height
                }
                firstTextView.horizontalAnchors == horizontalAnchors
            }

        }
        
        if !allLinks.isEmpty {
            let buttonBase = UIStackView().then {
                $0.accessibilityIdentifier = "Content links"
                $0.axis = .horizontal
                $0.spacing = 8
            }
            
            var finalWidth = CGFloat(0)
            var counter = 1
            for url in allLinks {
                let type = ContentType.getContentType(baseUrl: url)
                let view = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 45)).then {
                    $0.layer.cornerRadius = 12.5
                    $0.clipsToBounds = true
                    $0.setTitle("    \(counter): \(url.host ?? url.absoluteString)", for: .normal)
                    $0.setTitleColor(ColorUtil.theme.fontColor, for: .normal)
                    $0.setTitleColor(.white, for: .selected)
                    $0.titleLabel?.textAlignment = .center
                    $0.setImage(UIImage(named: type.getImage())!.getCopy(withSize: CGSize.square(size: 12), withColor: ColorUtil.theme.fontColor), for: .normal)
                    //todo icon
                    $0.titleLabel?.font = UIFont.systemFont(ofSize: 10)
                    $0.backgroundColor = UIColor.clear
                    $0.addTapGestureRecognizer(action: {
                        self.delegate.linkTapped(url: url, text: "")
                    })
                    counter += 1
                }
                
                view.layer.borderWidth = 1
                view.layer.borderColor = ColorUtil.theme.fontColor.withAlphaComponent(0.7).cgColor

                let widthS = view.currentTitle!.size(with: view.titleLabel!.font).width + CGFloat(35)
                
                view.heightAnchor == CGFloat(25)
                view.widthAnchor == widthS
                
                finalWidth += widthS
                finalWidth += 8
                
                buttonBase.addArrangedSubview(view.withPadding(padding: UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)))
            }
            
            finalWidth -= 8
            
            buttonBase.isUserInteractionEnabled = true
            if !ignoreHeight {
                links.heightAnchor == CGFloat(30)
            }
            links.horizontalAnchors == self.horizontalAnchors
            
            links.addSubview(buttonBase)
            links.isHidden = false
            if !ignoreHeight {
                buttonBase.heightAnchor == CGFloat(30)
            }
            buttonBase.edgeAnchors == links.edgeAnchors
            buttonBase.centerYAnchor == links.centerYAnchor
            buttonBase.widthAnchor == finalWidth
            links.alwaysBounceHorizontal = true
            links.showsHorizontalScrollIndicator = false
            links.contentSize = CGSize.init(width: finalWidth + 30, height: CGFloat(30))
            estimatedHeight += 30
        }
    }
    
    public func setData(htmlString: String) {
        estimatedHeight = 0
        clearOverflow()
        
        //Start HTML parse
        var blocks = TextDisplayStackView.getBlocks(htmlString)
        
        var startIndex = 0
        
        if !blocks[0].startsWith("<table>") && !blocks[0].startsWith("<cite>") && !blocks[0].startsWith("<pre><code>") {
            let text = createAttributedChunk(baseHTML: blocks[0], accent: tColor, linksCallback: nil, indexCallback: nil)
            
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
                setViews(blocks, linksCallback: nil, indexCallback: nil)
            } else {
                blocks.remove(at: 0)
                setViews(blocks, linksCallback: nil, indexCallback: nil)
            }
        }
    }
    
    func setViews(_ blocks: [String], linksCallback: ((URL) -> Void)?, indexCallback: (() -> Int)?) {
        if !blocks.isEmpty {
            overflow.isHidden = false
        }
        
        for block in blocks {
            estimatedHeight += 8
            if block.startsWith("<table>") {
                let table = TableDisplayView(baseHtml: block, color: baseFontColor, accentColor: tColor, action: self.touchLinkAction, longAction: self.longTouchLinkAction, linksCallback: linksCallback, indexCallback: indexCallback)
                table.accessibilityIdentifier = "Table"
                overflow.addArrangedSubview(table)
                table.horizontalAnchors == overflow.horizontalAnchors
                if !ignoreHeight {
                    table.heightAnchor == table.globalHeight
                }
                table.backgroundColor = ColorUtil.theme.backgroundColor.withAlphaComponent(0.5)
                table.clipsToBounds = true
                table.layer.cornerRadius = 10
                table.isUserInteractionEnabled = true
                table.contentOffset = CGPoint.init(x: -8, y: 0)
                estimatedHeight += table.globalHeight
                tableCount += 1
            } else if block.startsWith("<hr/>") {
                let line = UIView()
                line.backgroundColor = ColorUtil.theme.fontColor
                overflow.addArrangedSubview(line)
                estimatedHeight += 1
                line.heightAnchor == CGFloat(1)
                line.horizontalAnchors == overflow.horizontalAnchors
            } else if block.startsWith("<pre><code>") {
                let body = CodeDisplayView.init(baseHtml: block, color: baseFontColor, linksCallback: linksCallback, indexCallback: indexCallback)
                body.accessibilityIdentifier = "Code block"
                overflow.addArrangedSubview(body)
                body.horizontalAnchors == overflow.horizontalAnchors
                if !ignoreHeight {
                    body.heightAnchor >= body.globalHeight
                }
                body.backgroundColor = ColorUtil.theme.backgroundColor.withAlphaComponent(0.5)
                body.clipsToBounds = true
                estimatedHeight += body.globalHeight
                body.layer.cornerRadius = 10
                body.contentOffset = CGPoint.init(x: -8, y: -8)
                body.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
            } else if block.startsWith("<cite>") {
                let label = YYLabel(frame: .zero)
                label.accessibilityIdentifier = "Quote"
                let text = createAttributedChunk(baseHTML: block.replacingOccurrences(of: "<cite>", with: "").replacingOccurrences(of: "</cite>", with: "").trimmed(), accent: tColor, linksCallback: linksCallback, indexCallback: indexCallback)
                label.alpha = 0.7
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
                label.highlightLongPressAction = longTouchLinkAction
                label.highlightTapAction = touchLinkAction
                
                let baseView = UIView()
                baseView.accessibilityIdentifier = "Quote box view"
                label.setBorder(border: .left, weight: 2, color: tColor)
                
                let size = CGSize(width: estimatedWidth - 12, height: CGFloat.greatestFiniteMagnitude)
                let layout = YYTextLayout(containerSize: size, text: text)!
                estimatedHeight += layout.textBoundingSize.height
                label.textLayout = layout
                label.preferredMaxLayoutWidth = layout.textBoundingSize.width
                label.attributedText = text

                baseView.addSubview(label)
                label.leftAnchor == baseView.leftAnchor + CGFloat(8)
                label.rightAnchor == baseView.rightAnchor - CGFloat(4)
                label.topAnchor == baseView.topAnchor
                label.bottomAnchor == baseView.bottomAnchor
                baseView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
                overflow.addArrangedSubview(baseView)
                            
                baseView.horizontalAnchors == overflow.horizontalAnchors
                if !ignoreHeight {
                    baseView.heightAnchor == layout.textBoundingSize.height
                }
            } else {
                if block.trimmed().isEmpty || block.trimmed() == "\n" {
                    continue
                }
                let text = createAttributedChunk(baseHTML: block.trimmed(), accent: tColor, linksCallback: linksCallback, indexCallback: indexCallback)
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
                label.textLayout = layout
                label.preferredMaxLayoutWidth = layout.textBoundingSize.width

                estimatedHeight += layout.textBoundingSize.height

                overflow.addArrangedSubview(label)

                label.horizontalAnchors == overflow.horizontalAnchors
                if !ignoreHeight {
                    label.heightAnchor == layout.textBoundingSize.height
                }
            }
        }
        
        overflow.setNeedsLayout()
    }
    
    public func createAttributedChunk(baseHTML: String, accent: UIColor, linksCallback: ((URL) -> Void)?, indexCallback: (() -> Int)?) -> NSAttributedString {
        return TextDisplayStackView.createAttributedChunk(baseHTML: baseHTML, fontSize: fontSize, submission: submission, accentColor: accent, fontColor: baseFontColor, linksCallback: linksCallback, indexCallback: indexCallback)
    }
    
    public static func
        createAttributedChunk(baseHTML: String, fontSize: CGFloat, submission: Bool, accentColor: UIColor, fontColor: UIColor, linksCallback: ((URL) -> Void)?, indexCallback: (() -> Int)?) -> NSAttributedString {
        let font = FontGenerator.fontOfSize(size: fontSize, submission: submission)
        let htmlBase = TextDisplayStackView.addSpoilers(baseHTML).replacingOccurrences(of: "<sup>", with: "<font size=\"1\">").replacingOccurrences(of: "</sup>", with: "</font>").replacingOccurrences(of: "<del>", with: "<font color=\"green\">").replacingOccurrences(of: "</del>", with: "</font>").replacingOccurrences(of: "<code>", with: "<font color=\"blue\">").replacingOccurrences(of: "</code>", with: "</font>")
        let baseHtml = DTHTMLAttributedStringBuilder.init(html: htmlBase.trimmed().data(using: .unicode)!, options: [DTUseiOS6Attributes: true, DTDefaultTextColor: fontColor, DTDefaultFontFamily: font.familyName, DTDefaultFontSize: font.pointSize, DTDefaultFontName: font.fontName], documentAttributes: nil).generatedAttributedString()!
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
        
        return LinkParser.parse(html, accentColor, font: font, fontColor: fontColor, linksCallback: linksCallback, indexCallback: indexCallback)
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

    public static func getBlocks(_ html: String) -> [String] {
        
        var codeBlockSeperated = TextDisplayStackView.parseCodeTags(html)
        
        if html.contains(HR_TAG) {
            codeBlockSeperated = parseHR(codeBlockSeperated)
        }
        
        if html.contains("<cite>") {
            codeBlockSeperated = parseBlockquote(codeBlockSeperated)
        }
        
        if html.contains("<table") {
            return TextDisplayStackView.parseTableTags(codeBlockSeperated)
        } else {
            return codeBlockSeperated
        }
    }
    
    public static func parseCodeTags(_ html: String) -> [String] {
        let startTag = "<pre><code>"
        let endTag = "</code></pre>"
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
    
    public static func parseHR(_ blocks: [String]) -> [String] {
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
    
    public static func parseBlockquote(_ blocks: [String]) -> [String] {
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
    
    public static func parseTableTags(_ blocks: [String]) -> [String] {
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
    
    public static func estimateHeight(fontSize: CGFloat, submission: Bool, width: CGFloat, titleString: NSAttributedString, htmlString: String) -> CGFloat {
        var totalHeight = CGFloat(0)
        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let layout = YYTextLayout(containerSize: size, text: titleString)!
        var blocks: [String]
        if htmlString.contains("<table") || htmlString.contains("<pre><code") || htmlString.contains("<cite") {
            blocks = TextDisplayStackView.getBlocks(htmlString)
            
            var startIndex = 0
            
            let newTitle = NSMutableAttributedString(attributedString: titleString)
            if !blocks[0].startsWith("<table>") && !blocks[0].startsWith("<cite>") && !blocks[0].startsWith("<pre><code>") {
                if !blocks[0].trimmed().isEmpty() && blocks[0].trimmed() != "<div class=\"md\">" {
                    newTitle.append(NSAttributedString.init(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 5)])))
                    newTitle.append(createAttributedChunk(baseHTML: blocks[0], fontSize: fontSize, submission: submission, accentColor: .white, fontColor: .white, linksCallback: nil, indexCallback: nil))
                }
                startIndex = 1
            }
            
            let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
            let layout = YYTextLayout(containerSize: size, text: newTitle)!
            totalHeight += layout.textBoundingSize.height
            
            if blocks.count > 1 {
                if startIndex == 0 {
                } else {
                    blocks.remove(at: 0)
                }
            }
        } else {
            blocks = [String]()
            let newTitle = NSMutableAttributedString(attributedString: titleString)
            if !htmlString.isEmpty() {
                newTitle.append(NSAttributedString.init(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 5)])))
                newTitle.append(createAttributedChunk(baseHTML: htmlString, fontSize: fontSize, submission: submission, accentColor: .white, fontColor: .white, linksCallback: nil, indexCallback: nil))
            }
            
            let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
            let layout = YYTextLayout(containerSize: size, text: newTitle)!
            totalHeight += layout.textBoundingSize.height
        }
        
        for block in blocks {
            totalHeight += 8
            if block.startsWith("<table>") {
                let table = TableDisplayView.getEstimatedHeight(baseHtml: block)
                totalHeight += table
            } else if block.startsWith("<hr/>") {
                totalHeight += 1
            } else if block.startsWith("<pre><code>") {
                let body = CodeDisplayView.init(baseHtml: block, color: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
                totalHeight += body.globalHeight
            } else {
                let text = createAttributedChunk(baseHTML: block, fontSize: fontSize, submission: submission, accentColor: .white, fontColor: .white, linksCallback: nil, indexCallback: nil)
                let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
                let layout = YYTextLayout(containerSize: size, text: text)!
                let textSize = layout.textBoundingSize
                
                totalHeight += textSize.height
            }
        }
        return totalHeight
    }
    
    public static func addSpoilers(_ text: String) -> String {
        var base = text
        
        for match in base.capturedGroups(withRegex: "<a[^>]*title=\"([^\"]*)\"[^>]*>([^<]*)</a>") {
            let tag = match[0]
            let spoilerText = match[1]
            let spoilerTeaser = match[2]
            // Remove the last </a> tag, but keep the < for parsing.
            if !tag.contains("<a href=\"http") && !tag.contains("<a href=\"/r") {
                base = base.replacingOccurrences(of: tag, with: (spoilerTeaser.isEmpty() ? "spoiler" : spoilerTeaser) + "[[s[\(spoilerText)]s]]")
            }
        }
        
        //match unconventional spoiler tags
        for match in base.capturedGroups(withRegex: "<a href=\"([#/](?:spoiler|sp|s))\">([^<]*)</a>") {
            let newPiece = match[0]
            let inner = "Spoiler [[s[\(newPiece.subsequence(newPiece.indexOf(">")! + 1, endIndex: newPiece.lastIndexOf("<")!))]s]]"
            base = base.replacingOccurrences(of: match[0], with: inner)
        }
        
        //match native Reddit spoilers
        for match in base.capturedGroups(withRegex: "<span class=\"[^\"]*md-spoiler-text+[^\"]*\">([^<]*)</span>") {
            let tag = match[0]
            let spoilerText = match[1]
            base = base.replacingOccurrences(of: tag, with: "Spoiler [[s[\(spoilerText)]s]]")
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
