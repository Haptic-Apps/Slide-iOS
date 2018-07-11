//
//  TableDisplayView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 05/29/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import XLActionController
import TTTAttributedLabel
import SwiftSpreadsheet
import Anchorage
import Then
import DTCoreText

class TableDisplayView: UIScrollView {

    var backupData = [[NSAttributedString]]()
    var flippedData = [[NSAttributedString]]()
    var baseStackView = UIStackView()

    var baseData = [[NSAttributedString]]()
    var scrollView: UIScrollView!
    var widths = [[CGFloat]]()
    var baseColor: UIColor

    init(baseHtml: String, color: UIColor) {
        var newData = baseHtml.replacingOccurrences(of: "http://view.table/", with: "")
        self.baseColor = color

        super.init(frame: CGRect.zero)

        baseData = TableDisplayView.parseHtml(newData.removingPercentEncoding!)
        self.bounces = true
        self.isUserInteractionEnabled = true
        
        baseStackView = UIStackView().then({
            $0.axis = .vertical
        })
        self.isScrollEnabled = true
        
        doList()
    }
    
    init(strings: [[NSAttributedString]], color: UIColor){
        self.baseColor = color
        super.init(frame: CGRect.zero)
        self.baseData = strings
        self.bounces = true
        self.isUserInteractionEnabled = true
        
        baseStackView = UIStackView().then({
            $0.axis = .vertical
        })
        self.isScrollEnabled = true
        
        doList()
    }

    //Algorighm from https://github.com/ccrama/Slide/blob/master/app/src/main/java/me/ccrama/redditslide/Views/CommentOverflow.java
    static func parseHtml(_ text: String) -> [[NSAttributedString]] {
        let tableStart = "<table>"
        let tableEnd = "</table>"
        let tableHeadStart = "<thead>"
        let tableHeadEnd = "</thead>"
        let tableRowStart = "<tr>"
        let tableRowEnd = "</tr>"
        let tableColumnStart = "<td>"
        let tableColumnEnd = "</td>"
        let tableColumnStartLeft = "<td align=\"left\">"
        let tableColumnStartRight = "<td align=\"right\">"
        let tableColumnStartCenter = "<td align=\"center\">"
        let tableHeaderStart = "<th>"
        let tableHeaderStartLeft = "<th align=\"left\">"
        let tableHeaderStartRight = "<th align=\"right\">"
        let tableHeaderStartCenter = "<th align=\"center\">"
        let tableHeaderEnd = "</th>"

        var i = 0
        var columnStart = 0
        var columnEnd = 0
        var columnStarted = false
        var isHeader = true

        var currentRow = [NSAttributedString]()
        let font =  FontGenerator.fontOfSize(size: 16, submission: false)
        var baseData = [[NSAttributedString]]()
        while (i < text.length) {
            if (text[i] != "<") {
                i += 1
            } else if (text.subsequence(i, endIndex: i + tableStart.length) == (tableStart)) {
                i += tableStart.length
            } else if (text.subsequence(i, endIndex: i + tableHeadStart.length) == tableHeadStart) {
                i += tableHeadStart.length
            } else if (text.subsequence(i, endIndex: i + tableRowStart.length) == tableRowStart) {
                currentRow = []
                i += tableRowStart.length
            } else if (text.subsequence(i, endIndex: i + tableRowEnd.length) == tableRowEnd) {
                isHeader = false
                baseData.append(currentRow)
                i += tableRowEnd.length
            } else if (text.subsequence(i, endIndex: i + tableEnd.length) == tableEnd) {
                i += tableEnd.length
            } else if (text.subsequence(i, endIndex: i + tableHeadEnd.length) == tableHeadEnd) {
                i += tableHeadEnd.length
            } else if (!columnStarted
                    && i + tableColumnStart.length < text.length
                    && (text.subsequence(i, endIndex: i + tableColumnStart.length)
                    == tableColumnStart || text.subsequence(i, endIndex: i + tableHeaderStart.length)
                    == tableHeaderStart)) {
                columnStarted = true
                //todo maybe gravity = Gravity.START;
                i += tableColumnStart.length
                columnStart = i
            } else if (!columnStarted && i + tableColumnStartRight.length < text.length && (text
                    .subsequence(i, endIndex: i + tableColumnStartRight.length)
                    == tableColumnStartRight || text.subsequence(i,
                    endIndex: i + tableHeaderStartRight.length) == tableHeaderStartRight)) {
                columnStarted = true
                //todo maybe gravity = Gravity.END;
                i += tableColumnStartRight.length
                columnStart = i;
            } else if (!columnStarted && i + tableColumnStartCenter.length < text.length && (
                    text.subsequence(i, endIndex: i + tableColumnStartCenter.length)
                            == tableColumnStartCenter
                            || text.subsequence(i, endIndex: i + tableHeaderStartCenter.length)
                            == tableHeaderStartCenter)) {
                columnStarted = true
                //todo maybe gravity = Gravity.CENTER;
                i += tableColumnStartCenter.length
                columnStart = i
            } else if (!columnStarted
                    && i + tableColumnStartLeft.length < text.length
                    && (text.subsequence(i, endIndex: i + tableColumnStartLeft.length)
                    == tableColumnStartLeft || text.subsequence(i,
                    endIndex: i + tableHeaderStartLeft.length) == tableHeaderStartLeft)) {
                columnStarted = true
               //todo maybe gravity = Gravity.START;
                i += tableColumnStartLeft.length
                columnStart = i
            }  else if (text.subsequence(i, endIndex: i + tableColumnEnd.length)
                     == tableColumnEnd || text.subsequence(i, endIndex: i + tableHeaderEnd.length)
                    == tableHeaderEnd) {
                columnEnd = i

                do {
                    let attr = DTHTMLAttributedStringBuilder.init(html: text.subsequence(columnStart, endIndex: columnEnd).data(using: .unicode)!, options: [DTUseiOS6Attributes: true, DTDefaultTextColor : ColorUtil.fontColor, DTDefaultFontFamily: font.familyName,DTDefaultFontSize: (isHeader ? 2 : 0) + 16 + SettingValues.commentFontOffset,  DTDefaultFontName: font.fontName], documentAttributes: nil).generatedAttributedString()!
                    currentRow.append(attr)
                    //todo eventually bold?
                } catch {
                    print(error.localizedDescription)
                }

                columnStart = 0
                columnStarted = false
                i += tableColumnEnd.length
            } else {
                i += 1;
            }
        }

        /*var header = [NSAttributedString]()
        for row in baseData {
            if(header.isEmpty){
                header = row
            } else {
                for index in 0...row.count - 1 {
                    flippedData.append([header[index], row[index]])
                }
            }
        }*/
        return baseData
    }

    func doData(){
        if(list){
            baseData = flippedData
        } else {
            baseData = backupData
        }

        widths.removeAll()
        var currentWidths = [CGFloat]()
        for row in baseData{
            currentWidths = []
            for cell in row {
                let framesetter = CTFramesetterCreateWithAttributedString(cell)
                let textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat(40)), nil)
                let length = textSize.width + 16
                currentWidths.append(length)
            }
            widths.append(currentWidths)
        }
        addSubviews()
    }
    
    func addSubviews(){
        for row in baseData {
            let rowStack = UIStackView().then({
                $0.axis = .horizontal
                $0.spacing = 4
            })
            var column = 0
            globalHeight += 30
            globalWidth = 0
            for string in row {
                let text = UILabel.init().then({
                    $0.heightAnchor == CGFloat(30)
                })
                text.attributedText = string
                
                let width = getWidestCell(column: column)
                globalWidth += width
                globalWidth += 4
                text.widthAnchor == width
                rowStack.addArrangedSubview(text)
                column += 1
            }
            globalWidth -= 4
            baseStackView.addArrangedSubview(rowStack)
        }
        addSubview(baseStackView)
        contentInset = UIEdgeInsets.init(top: 0, left: 8, bottom: 0, right: 8)
        baseStackView.widthAnchor == globalWidth
        baseStackView.heightAnchor == globalHeight
        baseStackView.leftAnchor == leftAnchor
        baseStackView.verticalAnchors == verticalAnchors
        baseStackView.leadingAnchor == leadingAnchor
        baseStackView.trailingAnchor == trailingAnchor
        baseStackView.topAnchor == topAnchor
        baseStackView.bottomAnchor == bottomAnchor
        contentSize = CGSize.init(width: globalWidth, height: globalHeight)
    }
    
    var globalHeight = CGFloat(0)
    var globalWidth = CGFloat(0)

    func getWidestCell(column: Int) -> CGFloat{
        var widest = CGFloat(0)
        for row in widths {
            if(row[column] > widest){
                widest = row[column]
            }
        }
        return widest
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var list = true

    func doList(){
        list = !list
        doData()
    }
}

class TextCollectionViewCell: UICollectionViewCell {
    var textLabel: TTTAttributedLabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        textLabel = TTTAttributedLabel.init(frame:  CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        textLabel.textColor = ColorUtil.fontColor
        textLabel.textAlignment = .center
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textLabel)

        contentView.layer.borderWidth = 0.25
        contentView.layer.borderColor = ColorUtil.fontColor.cgColor
        updateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[text]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: [:], views: ["text": textLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[text]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: [:], views: ["text": textLabel]))
    }
}

extension TableDisplayView: SpreadsheetLayoutDelegate {
    func spreadsheet(layout: SpreadsheetLayout, heightForRowsInSection section: Int) -> CGFloat {
        return 40
    }

    func widthsOfSideRowsInSpreadsheet(layout: SpreadsheetLayout) -> (left: CGFloat?, right: CGFloat?) {
        return (0, 0)
    }

    func spreadsheet(layout: SpreadsheetLayout, widthForColumnAtIndex index: Int) -> CGFloat {
        return getWidestCell(column: index)
    }

    func heightsOfHeaderAndFooterColumnsInSpreadsheet(layout: SpreadsheetLayout) -> (headerHeight: CGFloat?, footerHeight: CGFloat?) {
        return (0, 0)
    }
}
