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

public protocol TextDisplayStackViewDelegate: class {
    func linkTapped(url: URL, text: String)
    func linkLongTapped(url: URL)
    func previewProfile(profile: String)
}

public class TextDisplayStackView: UIStackView {
    var baseString: NSAttributedString?
    static let TABLE_START_TAG = "<table>"
    static let HR_TAG = "<hr/>"
    static let TABLE_END_TAG = "</table>"

    var estimatedWidth = CGFloat(0)
    var estimatedHeight = CGFloat(0)
    
    let firstTextView: TitleUITextView
    let overflow: UIStackView
    let links: UIScrollView
    
    let fontSize: CGFloat
    let submission: Bool
    var tColor: UIColor
    var baseFontColor: UIColor
    var tableCount = 0
    var tableData = [[[NSAttributedString]]]()
    weak var delegate: TextDisplayStackViewDelegate?

    var ignoreHeight = false

    var activeSet = false
    
    init(delegate: TextDisplayStackViewDelegate?) {
        self.fontSize = 0
        self.submission = false
        self.tColor = .black
        self.baseFontColor = .white
        self.delegate = delegate
        
        let layout = BadgeLayoutManager()
        let storage = NSTextStorage()
        storage.addLayoutManager(layout)
        let initialSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        let container = NSTextContainer(size: initialSize)
        container.widthTracksTextView = true
        layout.addTextContainer(container)

        self.firstTextView = TitleUITextView(delegate: delegate, textContainer: container)
        self.firstTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: tColor]
        self.firstTextView.doSetup()
        
        self.overflow = UIStackView()
        self.overflow.isUserInteractionEnabled = true
        self.links = TouchUIScrollView()
        self.links.isUserInteractionEnabled = true
        super.init(frame: CGRect.zero)
        self.distribution = .fill
        self.isUserInteractionEnabled = true
    }
    
    func setColor(_ color: UIColor) {
        self.tColor = color
        self.firstTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: tColor]
    }
    
    init(fontSize: CGFloat, submission: Bool, color: UIColor, width: CGFloat, baseFontColor: UIColor = UIColor.fontColor, delegate: TextDisplayStackViewDelegate?) {
        self.fontSize = fontSize
        self.submission = submission
        self.estimatedWidth = width
        self.tColor = color
        self.delegate = delegate
        self.baseFontColor = baseFontColor
        
        let layout = BadgeLayoutManager()
        let storage = NSTextStorage()
        storage.addLayoutManager(layout)
        let initialSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        let container = NSTextContainer(size: initialSize)
        container.widthTracksTextView = true
        layout.addTextContainer(container)

        self.firstTextView = TitleUITextView(delegate: delegate, textContainer: container).then({
            $0.accessibilityIdentifier = "Top title"
            $0.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
            $0.doSetup()
        })
        self.links = TouchUIScrollView()
        self.links.isUserInteractionEnabled = true
        self.overflow = UIStackView().then({
            $0.accessibilityIdentifier = "Text overflow"
            $0.axis = .vertical
            $0.spacing = 8
        })
        super.init(frame: CGRect.zero)

        self.firstTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: tColor]
        self.axis = .vertical
        self.addArrangedSubviews(firstTextView, overflow, links)
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.isUserInteractionEnabled = true

        firstTextView.horizontalAnchors /==/ self.horizontalAnchors
        overflow.horizontalAnchors /==/ self.horizontalAnchors
        links.horizontalAnchors /==/ self.horizontalAnchors
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
        firstTextView.sizeToFit()

        if !ignoreHeight {
            let textHeight = firstTextView.attributedText!.height(containerWidth: estimatedWidth)
            estimatedHeight += textHeight
            firstTextView.horizontalAnchors /==/ horizontalAnchors
            firstTextView.removeConstraints(addedConstraints)
            addedConstraints = batch {
                firstTextView.heightAnchor /==/ textHeight ~ .low
                firstTextView.verticalCompressionResistancePriority = .required
            }
        }
    }
    
    var addedConstraints = [NSLayoutConstraint]()
    
    func clearOverflow() {
        // Clear out old UIStackView from https://gist.github.com/Deub27/5eadbf1b77ce28abd9b630eadb95c1e2
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
    
    public func setTextWithTitleHTML(_ title: NSAttributedString, _ body: NSAttributedString? = nil, htmlString: String, images: Bool = false) {
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
            if blocks[0] == "<div class=\"md\">" {
                blocks.remove(at: 0)
            }
            var startIndex = 0
            
            let newTitle = NSMutableAttributedString(attributedString: title)
            if !blocks[0].startsWith("<table>") && !blocks[0].startsWith("<cite>") && !blocks[0].startsWith("<pre><code>") {
                if !blocks[0].trimmed().isEmpty() && blocks[0].trimmed() != "<div class=\"md\">" {
                    if !newTitle.string.trimmed().isEmpty {
                        newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 5)]))
                    }
                    newTitle.append(createAttributedChunk(baseHTML: blocks[0], accent: tColor, linksCallback: linkCallback, indexCallback: indexCallback))
                }
                startIndex = 1
            }
            
            if !newTitle.string.isEmpty {
                firstTextView.isHidden = false
                firstTextView.attributedText = newTitle
                firstTextView.sizeToFit()
            } else {
                firstTextView.attributedText = nil
                firstTextView.frame = CGRect.zero
                firstTextView.isHidden = true
            }

            if !ignoreHeight && !newTitle.string.isEmpty {
//                let framesetterB = CTFramesetterCreateWithAttributedString(newTitle)
//                let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
//                estimatedHeight += textSizeB.height

                let textHeight = firstTextView.attributedText?.height(containerWidth: estimatedWidth) ?? 0
                estimatedHeight += textHeight
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
                    newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 5)]))
                }
                if allLinks.isEmpty && body != nil {
                    mutableBody.enumerateAttributes(in: NSRange.init(location: 0, length: body!.length), options: .longestEffectiveRangeNotRequired, using: { (attrs, range, _) in
                        for attr in attrs {
                            if let highlight = attr.value as? TextHighlight, let url = highlight.userInfo["url"] as? URL {
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
                    newTitle.append(NSAttributedString.init(string: "\n\n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 5)]))
                }
                newTitle.append(createAttributedChunk(baseHTML: htmlString, accent: tColor, linksCallback: linkCallback, indexCallback: indexCallback))
            }
            
            firstTextView.attributedText = newTitle
            if images {
                firstTextView.layoutTitleImageViews()
            }
            
            if !ignoreHeight {
                firstTextView.sizeToFit()

                let textHeight = newTitle.height(containerWidth: estimatedWidth)
                estimatedHeight += textHeight
                firstTextView.removeConstraints(addedConstraints)
                addedConstraints = batch {
                    firstTextView.heightAnchor /==/ textHeight ~ .low
                }
                firstTextView.horizontalAnchors /==/ horizontalAnchors
            }
        }
        
        if !allLinks.isEmpty && !SettingValues.disablePreviews {
            let buttonBase = UIStackView().then {
                $0.accessibilityIdentifier = "Content links"
                $0.axis = .horizontal
                $0.spacing = 8
            }
            
            var finalWidth = CGFloat(0)
            var counter = 1
            for url in allLinks {
                let type = ContentType.getContentType(baseUrl: url)
                var urlText = url.host ?? url.absoluteString
                if url.absoluteString.contains("slide://theme") {
                    urlText = "Slide Theme"
                }
                let view = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 45)).then {
                    $0.layer.cornerRadius = 12.5
                    $0.clipsToBounds = true
                    $0.setTitle("    \(counter): \(urlText)", for: .normal)
                    $0.setTitleColor(UIColor.fontColor, for: .normal)
                    $0.setTitleColor(.white, for: .selected)
                    $0.titleLabel?.textAlignment = .center
                    $0.setImage(UIImage(named: type.getImage())!.getCopy(withSize: CGSize.square(size: 12), withColor: UIColor.fontColor), for: .normal)
                   // TODO: - icon
                    $0.titleLabel?.font = UIFont.systemFont(ofSize: 10)
                    $0.backgroundColor = UIColor.clear
                    $0.addTapGestureRecognizer(action: { _ in
                        self.delegate?.linkTapped(url: url, text: "")
                    })
                    $0.addLongTapGestureRecognizer(action: { _ in
                        self.delegate?.linkLongTapped(url: url)
                    })
                    counter += 1
                }
                
                view.layer.borderWidth = 1
                view.layer.borderColor = UIColor.fontColor.withAlphaComponent(0.7).cgColor

                let widthS = view.currentTitle!.size(with: view.titleLabel!.font).width + CGFloat(35)
                
                view.heightAnchor /==/ CGFloat(25)
                view.widthAnchor /==/ widthS
                
                finalWidth += widthS
                finalWidth += 8
                
                buttonBase.addArrangedSubview(view.withPadding(padding: UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)))
            }
            
            finalWidth -= 8
            
            buttonBase.isUserInteractionEnabled = true
            if !ignoreHeight {
                links.heightAnchor /==/ CGFloat(30)
            }
            links.horizontalAnchors /==/ self.horizontalAnchors
            
            links.addSubview(buttonBase)
            links.isHidden = false
            if !ignoreHeight {
                buttonBase.heightAnchor /==/ CGFloat(30)
            }
            buttonBase.edgeAnchors /==/ links.edgeAnchors
            buttonBase.centerYAnchor /==/ links.centerYAnchor
            buttonBase.widthAnchor /==/ finalWidth
            links.alwaysBounceHorizontal = true
            links.showsHorizontalScrollIndicator = false
            links.contentSize = CGSize.init(width: finalWidth + 30, height: CGFloat(30))
            estimatedHeight += 30
        }
    }
    
    public func setData(htmlString: String) {
        estimatedHeight = 0
        clearOverflow()
        
        // Start HTML parse
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
            firstTextView.sizeToFit()

            if !ignoreHeight {
//                let framesetterB = CTFramesetterCreateWithAttributedString(text)
//                let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: estimatedWidth, height: CGFloat.greatestFiniteMagnitude), nil)
//                estimatedHeight += textSizeB.height

                let textHeight = firstTextView.attributedText!.height(containerWidth: estimatedWidth)
                estimatedHeight += textHeight
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
                let table = TableDisplayView(baseHtml: block, color: baseFontColor, accentColor: tColor, delegate: self.delegate, linksCallback: linksCallback, indexCallback: indexCallback)
                table.accessibilityIdentifier = "Table"
                overflow.addArrangedSubview(table)
                table.horizontalAnchors /==/ overflow.horizontalAnchors
                table.heightAnchor /==/ table.globalHeight ~ .low
                table.backgroundColor = UIColor.backgroundColor.withAlphaComponent(0.5)
                table.clipsToBounds = true
                table.layer.cornerRadius = 10
                table.isUserInteractionEnabled = true
                table.contentOffset = CGPoint.init(x: -8, y: 0)
                table.verticalCompressionResistancePriority = .required
                estimatedHeight += table.globalHeight
                tableCount += 1
            } else if block.startsWith("<hr/>") {
                let line = UIView()
                line.backgroundColor = UIColor.fontColor
                line.verticalCompressionResistancePriority = .required
                overflow.addArrangedSubview(line)
                estimatedHeight += 1
                line.heightAnchor /==/ CGFloat(1)
                line.horizontalAnchors /==/ overflow.horizontalAnchors
            } else if block.startsWith("<pre><code>") {
                let body = CodeDisplayView.init(baseHtml: block, color: baseFontColor, linksCallback: linksCallback, indexCallback: indexCallback)
                body.accessibilityIdentifier = "Code block"
                body.scrollView?.panGestureRecognizer.cancelsTouchesInView = true
                overflow.addArrangedSubview(body)
                body.horizontalAnchors /==/ overflow.horizontalAnchors
                // if !ignoreHeight {
                    body.heightAnchor /==/ body.globalHeight
                // }
                body.backgroundColor = UIColor.backgroundColor.withAlphaComponent(0.5)
                body.clipsToBounds = true
                body.verticalCompressionResistancePriority = .required
                estimatedHeight += body.globalHeight
                body.layer.cornerRadius = 10
                body.contentOffset = CGPoint.init(x: -8, y: -8)
                body.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
            } else if block.startsWith("<cite>") {
                let body = block.replacingOccurrences(of: "<cite>", with: "").replacingOccurrences(of: "</cite>", with: "").trimmed()
                
                if body.isEmpty {
                    continue
                }
                
                let layout = BadgeLayoutManager()
                let storage = NSTextStorage()
                storage.addLayoutManager(layout)
                let initialSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
                let container = NSTextContainer(size: initialSize)
                container.widthTracksTextView = true
                layout.addTextContainer(container)

                let label = TitleUITextView(delegate: self.delegate, textContainer: container).then {
                    $0.doSetup()
                    $0.linkTextAttributes = [NSAttributedString.Key.foregroundColor: tColor]
                }
                label.accessibilityIdentifier = "Quote"
                let text = createAttributedChunk(baseHTML: body, accent: tColor, linksCallback: linksCallback, indexCallback: indexCallback)
                label.alpha = 0.7
                                
                let baseView = UIView()
                baseView.accessibilityIdentifier = "Quote box view"
                baseView.setBorder(border: .left, weight: 2, color: tColor)
                
                label.attributedText = text
                label.sizeToFit()
                
                let textHeight = text.height(containerWidth: estimatedWidth - 14)
                estimatedHeight += textHeight

                baseView.addSubview(label)
                label.leftAnchor /==/ baseView.leftAnchor + CGFloat(8)
                label.rightAnchor /==/ baseView.rightAnchor - CGFloat(4)
                label.topAnchor /==/ baseView.topAnchor
                label.bottomAnchor /==/ baseView.bottomAnchor
                baseView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
                overflow.addArrangedSubview(baseView)
                            
                baseView.horizontalAnchors /==/ overflow.horizontalAnchors
                if !ignoreHeight {
                    baseView.heightAnchor /==/ textHeight
                    baseView.verticalCompressionResistancePriority = .required
                }
            } else {
                if block.trimmed().isEmpty || block.trimmed() == "\n" {
                    continue
                }
                let text = createAttributedChunk(baseHTML: block.trimmed(), accent: tColor, linksCallback: linksCallback, indexCallback: indexCallback)
                
                let layout = BadgeLayoutManager()
                let storage = NSTextStorage()
                storage.addLayoutManager(layout)
                let initialSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
                let container = NSTextContainer(size: initialSize)
                container.widthTracksTextView = true
                layout.addTextContainer(container)

                let label = TitleUITextView(delegate: self.delegate, textContainer: container).then {
                    $0.accessibilityIdentifier = "Paragraph"
                    $0.doSetup()
                    $0.linkTextAttributes = [NSAttributedString.Key.foregroundColor: tColor]
                    $0.attributedText = text
                    $0.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
                }

                let textHeight = label.attributedText!.height(containerWidth: estimatedWidth)
                estimatedHeight += textHeight
                overflow.addArrangedSubview(label)

                label.horizontalAnchors /==/ overflow.horizontalAnchors
                if !ignoreHeight {
                    label.heightAnchor /==/ textHeight
                    label.verticalCompressionResistancePriority = .required
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
        var htmlBase = TextDisplayStackView
            .addSpoilers(baseHTML)
            .replacingOccurrences(of: "<del>", with: "<font color=\"green\">")
            .replacingOccurrences(of: "<!-- SC_OFF -->", with: "")
            .replacingOccurrences(of: "<!-- SC_ON -->", with: "")
            .replacingOccurrences(of: "</del>", with: "</font>")
            .replacingOccurrences(of: "<code>", with: "<font color=\"blue\">")
            .replacingOccurrences(of: "</code>", with: "</font>")
            .replacingOccurrences(of: "<div class=\"md\">", with: "")
        if htmlBase.endsWith("\n</div>") {
            htmlBase = htmlBase.substring(0, length: htmlBase.length - 7)
        }
        if htmlBase.endsWith("<br/>") {
            htmlBase = htmlBase.substring(0, length: htmlBase.length - 5)
        }
        let htmlString = DTHTMLAttributedStringBuilder.init(html: htmlBase.trimmed().data(using: .unicode)!, options: [DTUseiOS6Attributes: true, DTDefaultTextColor: fontColor, DTDefaultFontSize: font.pointSize], documentAttributes: nil).generatedAttributedString()!

        let html = NSMutableAttributedString(attributedString: htmlString)
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

        let fixedHTML = html.fixCoreTextIssues(withFont: font)
        
        return LinkParser.parse(fixedHTML, accentColor, font: font, fontColor: fontColor, linksCallback: linksCallback, indexCallback: indexCallback)
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

        if html.contains("<img") {
            codeBlockSeperated = parseImage(codeBlockSeperated)
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
        let startSeperated = html.components(separatedBy: startTag)
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
            let startSeperated = html.components(separatedBy: startTag)
            
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
                        for i in 1..<split.count {
                            let text = split[i]
                            if !text.trimmed().isEmpty {
                                preSeperated.append(text)
                            }
                        }
                    }
                }
            }
        }
        return preSeperated
    }

    public static func parseImage(_ blocks: [String]) -> [String] {
        var preSeperated = [String]()
        
        // TODO we can render this inline eventually
        
        for html in blocks {
            let imgPattern = "\\<img.+src\\=(?:\\\"|\\')(.+?)(?:\\\"|\\')(?:.+?)\\>"
            
            if let regex = try? NSRegularExpression(pattern: imgPattern, options: .caseInsensitive) {
                let modString = regex.stringByReplacingMatches(in: html, options: .withTransparentBounds, range: NSMakeRange(0, html.length), withTemplate: "Image")
                preSeperated.append(modString)
            } else {
                preSeperated.append(html)
            }
        }
        return preSeperated
    }

    public static func parseTableTags(_ blocks: [String]) -> [String] {
        var newBlocks = [String]()
        for block in blocks {
            if block.contains(TABLE_START_TAG) {
                let startSeperated = block.components(separatedBy: TABLE_START_TAG)
                newBlocks.append(startSeperated[0].trimmed())
                for i in 1 ..< startSeperated.count {
                    let split = startSeperated[i].components(separatedBy: TABLE_END_TAG)
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
        var totalHeight = titleString.height(containerWidth: width)
        let blocks: [String] = TextDisplayStackView.getBlocks(htmlString)
        var hasLinks = false
        var newlineHeight = CGFloat.zero
        let newline = NSAttributedString.init(string: "\n\n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 5)])
        newlineHeight = newline.height(containerWidth: width)

        totalHeight += newlineHeight

        for block in blocks {
            let parsedBlock = block.replacingOccurrences(of: "<div class=\"md\">", with: "")
                .replacingOccurrences(of: "<p>", with: "<span>")
                .replacingOccurrences(of: "</p>", with: "</span><br/>")
                .replacingOccurrences(of: "\n</div>", with: "")
            if parsedBlock.isEmpty {
                continue
            }

            totalHeight += 8
            if block.contains("<a") {
                hasLinks = true
            }
            if block.startsWith("<table>") {
                let table = TableDisplayView.getEstimatedHeight(baseHtml: block)
                totalHeight += table
            } else if block.startsWith("<hr/>") {
                totalHeight += 1
            } else if block.startsWith("<pre><code>") {
                let body = CodeDisplayView.init(baseHtml: block, color: UIColor.fontColor, linksCallback: nil, indexCallback: nil)
                totalHeight += body.globalHeight
            } else if block.startsWith("<cite>") {
                let body = block.replacingOccurrences(of: "<cite>", with: "").replacingOccurrences(of: "</cite>", with: "").trimmed()
                
                if body.isEmpty {
                    continue
                }
                
                let text = createAttributedChunk(baseHTML: body, fontSize: fontSize, submission: submission, accentColor: .white, fontColor: .white, linksCallback: nil, indexCallback: nil)
                totalHeight += text.height(containerWidth: width - 14)
            } else {
                let text = createAttributedChunk(baseHTML: block, fontSize: fontSize, submission: submission, accentColor: .white, fontColor: .white, linksCallback: nil, indexCallback: nil)
                let textHeight = text.height(containerWidth: width)
                
                totalHeight += textHeight
            }
        }
        if hasLinks && !SettingValues.disablePreviews {
            totalHeight += 30
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
        
        // match unconventional spoiler tags
        for match in base.capturedGroups(withRegex: "<a href=\"([#/](?:spoiler|sp|s))\">([^<]*)</a>") {
            let newPiece = match[0]
            let inner = "Spoiler [[s[\(newPiece.subsequence(newPiece.indexOf(">")! + 1, endIndex: newPiece.lastIndexOf("<")!))]s]]"
            base = base.replacingOccurrences(of: match[0], with: inner)
        }
        
        // match native Reddit spoilers
        for match in base.capturedGroups(withRegex: "<span class=\"[^\"]*md-spoiler-text+[^\"]*\">([^<]*)</span>") {
            let tag = match[0]
            let spoilerText = match[1]
            base = base.replacingOccurrences(of: tag, with: "Spoiler [[s[\(spoilerText)]s]]")
        }
        return base
    }
}

private extension NSAttributedString {

    private static let superscriptKeys = [
        NSAttributedString.Key(rawValue: "NSSuperScript"), // Used by Apple, but not documented.
        NSAttributedString.Key(rawValue: "CTSuperscript"), // Used by Apple, but not documented. Typically created by DTCoreText.
    ]

    /**
     Fixes the following:
     - Superscript is rendered incorrectly depending on the font
     */
    func fixCoreTextIssues(withFont font: UIFont) -> NSAttributedString {
        return self.fixSuperscript(withFont: font).trimmedAttributedString()
    }

    /**
     Superscript rendering is flaky for different fonts. Superscript is
     typically accomplished by using dedicated superscript font glyphs. Not
     all the fonts have superscript glyphs for every character that might be
     superscripted by a user, which can look bad. Furthermore, different
     NSAttributedString generators will accomplish superscript in different ways.

     To solve this, we go through each attribute in the string. We remove the attribute
     while adding our own. Instead of using a superscript attribute, we simulate the
     look by adjusting the baseline and font size.
     */
    private func fixSuperscript(withFont font: UIFont) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)

        var superscriptLevel: Int = 0

        // Go through each chunk in the attributed string
        mutable.enumerateAttributes(in: NSRange(location: 0, length: mutable.length), options: .longestEffectiveRangeNotRequired) { (value, range, _) in
            let value = value as [NSAttributedString.Key: Any]
            // If the chunk has a superscript attribute from either CoreText or DTCoreText,
            // remove the attribute and adjust the chunk's baseline and size ourselves.
            if !NSAttributedString.superscriptKeys.compactMap({ value[$0] }).isEmpty { // kCTSuperscriptAttributeName
                // Remove existing superscript keys
                for key in NSAttributedString.superscriptKeys where value[key] != nil {
                    mutable.removeAttribute(key, range: range)
                }

                // Extract font from attributed string; this includes bold/italic information
                let fontForChunk = value[NSAttributedString.Key.font] as! UIFont
                superscriptLevel += 1
                let newFontSize = max(CGFloat(font.pointSize / 2), 10)
                let newFont = UIFont(name: fontForChunk.fontName, size: newFontSize) ?? fontForChunk
                let newBaseline = (font.pointSize * 0.25) + (CGFloat(superscriptLevel) * (font.pointSize / 4.0))

                // Add attributes to make "fake" superscript by changing baseline and font size
                mutable.addAttributes([
                    .font: newFont,
                    .baselineOffset: newBaseline,
                ], range: range)
            } else {
                // Reset superscript level if we hit a chunk with no superscript attribute
                superscriptLevel = 0
            }
        }

        return mutable
    }

    // From https://github.com/rwbutler/TailorSwift/blob/master/TailorSwift/Classes/NSAttributedStringAdditions.swift
    func trimmedAttributedString() -> NSAttributedString {
        let invertedSet = CharacterSet.whitespacesAndNewlines.inverted
        let startRange = string.utf16.description.rangeOfCharacter(from: invertedSet)
        let endRange = string.utf16.description.rangeOfCharacter(from: invertedSet, options: .backwards)
        guard let startLocation = startRange?.upperBound, let endLocation = endRange?.lowerBound else {
            return NSAttributedString(string: string)
        }

        let location = string.utf16.distance(from: string.startIndex, to: startLocation) - 1
        let length = string.utf16.distance(from: startLocation, to: endLocation) + 2

        let composedRange = (self.string as NSString).rangeOfComposedCharacterSequences(for: NSRange(location: location, length: length)) // Required or emojis cut off if they are at the end of the line
        return attributedSubstring(from: composedRange)
    }
}
