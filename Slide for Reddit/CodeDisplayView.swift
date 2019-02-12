//
//  CodeDisplayView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/10/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import DTCoreText
import reddift
import SDWebImage
import SwiftSpreadsheet
import Then
import YYText
import UIKit
import XLActionController

class CodeDisplayView: UIScrollView {
    
    var baseData = [NSAttributedString]()
    var scrollView: UIScrollView!
    var widths = [CGFloat]()
    var baseColor: UIColor
    var baseLabel: UILabel
    var globalHeight: CGFloat
    
    init(baseHtml: String, color: UIColor) {
        self.baseColor = color
        globalHeight = CGFloat(0)
        baseLabel = UILabel()
        baseLabel.numberOfLines = 0
        super.init(frame: CGRect.zero)
        parseText(baseHtml.removingPercentEncoding ?? baseHtml)
        self.bounces = true
        self.isUserInteractionEnabled = true
        self.isScrollEnabled = true
        
        doData()
    }
    
    func parseText(_ text: String) {
        for string in text.split("\n") {
            if string.trimmed().isEmpty() {
                continue
            }
            let baseHtml = DTHTMLAttributedStringBuilder.init(html: string.trimmed().data(using: .unicode)!, options: [DTUseiOS6Attributes: true, DTDefaultTextColor: baseColor, DTDefaultFontFamily: "Courier", DTDefaultFontSize: FontGenerator.fontOfSize(size: 16, submission: false).pointSize, DTDefaultFontName: "Courier"], documentAttributes: nil).generatedAttributedString()!
            let attr = NSMutableAttributedString(attributedString: baseHtml)
            let cell = LinkParser.parse(attr, baseColor)
            baseData.append(cell)
        }
    }
    
    func doData() {
        widths.removeAll()
        for row in baseData {
            let framesetter = CTFramesetterCreateWithAttributedString(row)
            let textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat(40)), nil)
            let length = textSize.width + 25
            widths.append(length)
        }
        addSubviews()
    }
    
    func addSubviews() {
        let finalString = NSMutableAttributedString.init()
        var index = 0
        for row in baseData {
            finalString.append(row)
            if index != baseData.count - 1 {
                finalString.append(NSAttributedString.init(string: "\n"))
            }
            index += 1
        }
        baseLabel.attributedText = finalString
        
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let layout = YYTextLayout(containerSize: size, text: finalString)!
        let textSizeB = layout.textBoundingSize
        
        addSubview(baseLabel)
        contentInset = UIEdgeInsets.init(top: 8, left: 8, bottom: 0, right: 8)
        baseLabel.widthAnchor == getWidestCell()
        globalHeight = textSizeB.height + 16
        baseLabel.heightAnchor == textSizeB.height
        baseLabel.leftAnchor == leftAnchor
        baseLabel.topAnchor == topAnchor
        contentSize = CGSize.init(width: getWidestCell() + 16, height: textSizeB.height)
    }
    
    func getWidestCell() -> CGFloat {
        var widest = CGFloat(0)
        for row in widths {
            if row > widest {
                widest = row
            }
        }
        return widest
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
