//
//  TableDisplayView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 05/29/18.
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

class TableDisplayView: UIScrollView {

    var baseStackView = UIStackView()

    var baseData = [[NSAttributedString]]()
    var scrollView: UIScrollView!
    var widths = [[CGFloat]]()
    var baseColor: UIColor
    var tColor: UIColor
    var action: YYTextAction?
    var longAction: YYTextAction?

    init(baseHtml: String, color: UIColor, accentColor: UIColor, action: YYTextAction?, longAction: YYTextAction?) {
        let newData = baseHtml.replacingOccurrences(of: "http://view.table/", with: "")
        self.baseColor = color
        self.tColor = accentColor
        self.action = action
        self.longAction = longAction
        super.init(frame: CGRect.zero)

        parseHtml(newData.removingPercentEncoding ?? newData)
        self.bounces = true
        self.isUserInteractionEnabled = true
        
        baseStackView = UIStackView().then({
            $0.axis = .vertical
        })
        self.isScrollEnabled = true
        doList()
    }

    //Algorighm from https://github.com/ccrama/Slide/blob/master/app/src/main/java/me/ccrama/redditslide/Views/CommentOverflow.java
    func parseHtml(_ text: String) {
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

        var columnStarted = false
        var isHeader = true

        var currentRow = [NSAttributedString]()
        var currentString = ""
        for string in text.trimmed().components(separatedBy: "<") {
            let current = "<\(string)".trimmed()
            if current == "<" {
                continue
            }
            //print(current)
            if current == tableStart {
            } else if current == tableHeadStart {
            } else if current == tableRowStart {
                currentRow = []
            } else if current == tableRowEnd {
                isHeader = false
                baseData.append(currentRow)
            } else if current == tableEnd {
            } else if current == tableHeadEnd {
            } else if !columnStarted
                && (current == tableColumnStart || current == tableHeaderStart) {
                columnStarted = true
                //todo maybe gravity = Gravity.START;
            } else if !columnStarted && (current == tableColumnStartRight || current == tableHeaderStartRight) {
                columnStarted = true
                //todo maybe gravity = Gravity.END;
            } else if !columnStarted && (current == tableColumnStartCenter || current == tableHeaderStartCenter) {
                columnStarted = true
                //todo maybe gravity = Gravity.CENTER;
            } else if !columnStarted && (current == tableColumnStartLeft || current == tableHeaderStartLeft) {
                columnStarted = true
                //todo maybe gravity = Gravity.START;
            } else if current == tableColumnEnd || current == tableHeaderEnd {
                if currentString.startsWith("<td") {
                    let index = currentString.indexOf(">")
                    currentString = currentString.substring(index! + 1, length: currentString.length - index! - 1)
                }
                columnStarted = false
                currentRow.append(TextDisplayStackView.createAttributedChunk(baseHTML: currentString.trimmed(), fontSize: CGFloat((isHeader ? 3 : 0) + 16 ), submission: false, accentColor: tColor, fontColor: baseColor))
                currentString = ""
            } else {
                currentString.append(current)
            }
        }

        /*var header = [NSAttributedString]()
        for row in baseData {
            if(header.isEmpty){
                header = row
            } else {
                for index in 0 ..< row.count {
                    flippedData.append([header[index], row[index]])
                }
            }
        }

        backupData = baseData*/
    }

    func doData() {

        widths.removeAll()
        var currentWidths = [CGFloat]()
        for row in baseData {
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
    
    func addSubviews() {
        var odd = false
        for row in baseData {
            let rowStack = UIStackView().then({
                $0.axis = .horizontal
                $0.spacing = 4
            })
            var column = 0
            globalHeight += 30
            globalWidth = 0
            for string in row {
                let text = YYLabel.init(frame: CGRect.zero).then({
                    $0.heightAnchor == CGFloat(30)
                })
                text.highlightLongPressAction = longAction
                text.highlightTapAction = action
                text.attributedText = string
                if odd {
                    text.backgroundColor = ColorUtil.foregroundColor
                }
                let width = getWidestCell(column: column)
                globalWidth += width
                globalWidth += 4
                text.widthAnchor == width
                rowStack.addArrangedSubview(text)
                column += 1
            }
            globalWidth -= 4
            baseStackView.addArrangedSubview(rowStack)
            odd = !odd
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

    func getWidestCell(column: Int) -> CGFloat {
        var widest = CGFloat(0)
        for row in widths {
            if column < row.count && row[column] > widest {
                widest = row[column]
            }
        }
        return widest
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var list = true

    func doList() {
        list = !list
        doData()
    }
    
    public static func getEstimatedHeight(baseHtml: String) -> CGFloat {
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
        
        var columnStarted = false
        
        var currentString = ""
        var estHeight = CGFloat(0)
        for string in baseHtml.trimmed().components(separatedBy: "<") {
            let current = "<\(string)".trimmed()
            if current == "<" {
                continue
            }
            //print(current)
            if current == tableStart {
            } else if current == tableHeadStart {
            } else if current == tableRowStart {
            } else if current == tableRowEnd {
                estHeight += 30
            } else if current == tableEnd {
            } else if current == tableHeadEnd {
            } else if !columnStarted
                && (current == tableColumnStart || current == tableHeaderStart) {
                columnStarted = true
                //todo maybe gravity = Gravity.START;
            } else if !columnStarted && (current == tableColumnStartRight || current == tableHeaderStartRight) {
                columnStarted = true
                //todo maybe gravity = Gravity.END;
            } else if !columnStarted && (current == tableColumnStartCenter || current == tableHeaderStartCenter) {
                columnStarted = true
                //todo maybe gravity = Gravity.CENTER;
            } else if !columnStarted && (current == tableColumnStartLeft || current == tableHeaderStartLeft) {
                columnStarted = true
                //todo maybe gravity = Gravity.START;
            } else if current == tableColumnEnd || current == tableHeaderEnd {
                if currentString.startsWith("<td") {
                    let index = currentString.indexOf(">")
                    currentString = currentString.substring(index! + 1, length: currentString.length - index! - 1)
                }
                columnStarted = false
                currentString = ""
            } else {
                currentString.append(current)
            }
        }
        return estHeight
    }
}
