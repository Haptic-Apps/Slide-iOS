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
import Then
import UIKit


class TableDisplayView: UIScrollView {

    var baseStackView = UIStackView()

    var baseData = [[NSAttributedString]]()
    var scrollView: UIScrollView!
    var baseColor: UIColor
    var tColor: UIColor
    var linksCallback: ((URL) -> Void)?
    var indexCallback: (() -> Int)?
    weak var textDelegate: TextDisplayStackViewDelegate?
    
    init(baseHtml: String, color: UIColor, accentColor: UIColor, delegate: TextDisplayStackViewDelegate?, linksCallback: ((URL) -> Void)?, indexCallback: (() -> Int)?) {
        self.textDelegate = delegate
        self.linksCallback = linksCallback
        self.indexCallback = indexCallback
        let newData = baseHtml.replacingOccurrences(of: "http://view.table/", with: "")
        self.baseColor = color
        self.tColor = accentColor
        super.init(frame: CGRect.zero)

        parseHtml(newData.removingPercentEncoding ?? newData)
        self.bounces = true
        self.isUserInteractionEnabled = true
        
        baseStackView = UIStackView().then({
            $0.axis = .vertical
        })
        self.isScrollEnabled = true
        makeViews()
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
               // TODO: - maybe gravity = Gravity.START;
            } else if !columnStarted && (current == tableColumnStartRight || current == tableHeaderStartRight) {
                columnStarted = true
               // TODO: - maybe gravity = Gravity.END;
            } else if !columnStarted && (current == tableColumnStartCenter || current == tableHeaderStartCenter) {
                columnStarted = true
               // TODO: - maybe gravity = Gravity.CENTER;
            } else if !columnStarted && (current == tableColumnStartLeft || current == tableHeaderStartLeft) {
                columnStarted = true
               // TODO: - maybe gravity = Gravity.START;
            } else if current == tableColumnEnd || current == tableHeaderEnd {
                if currentString.startsWith("<td") {
                    let index = currentString.indexOf(">")
                    currentString = currentString.substring(index! + 1, length: currentString.length - index! - 1)
                }
                columnStarted = false
                currentRow.append(TextDisplayStackView.createAttributedChunk(baseHTML: currentString.trimmed(), fontSize: CGFloat((isHeader ? 3 : 0) + 16 ), submission: false, accentColor: tColor, fontColor: baseColor, linksCallback: linksCallback, indexCallback: indexCallback))
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

    var maxCellWidth: CGFloat {
        if traitCollection.userInterfaceIdiom == .phone {
            return UIScreen.main.bounds.width - 50
        } else {
            return 400
        }
    }
    let verticalPadding: CGFloat = 4
    let horizontalPadding: CGFloat = 4

    var globalWidth: CGFloat = 0
    var globalHeight: CGFloat = 0

    func makeViews() {
        var columnWidths = [CGFloat](repeating: 0, count: baseData[safeIndex: 0]?.count ?? 0)
        // Determine width of each column
        for row in baseData {
            for (x, text) in row.enumerated() {
                let framesetter = CTFramesetterCreateWithAttributedString(text)
                let singleLineTextWidth = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), nil).width
                let width = min(singleLineTextWidth, maxCellWidth) + (horizontalPadding * 2)
                columnWidths[x] = max(columnWidths[x], width)
            }
        }
        globalWidth = columnWidths.reduce(0, +)

        // Determine heights of rows now that we know column widths
        var rowHeights = [CGFloat](repeating: 0, count: baseData.count)
        for (y, row) in baseData.enumerated() {
            for (x, text) in row.enumerated() {
                let framesetter = CTFramesetterCreateWithAttributedString(text)
                let height = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize.init(width: columnWidths[x], height: CGFloat.greatestFiniteMagnitude), nil).height + (verticalPadding * 2)
                rowHeights[y] = max(rowHeights[y], height)
            }
        }
        globalHeight = rowHeights.reduce(0, +)

        // Create each row
        for (y, row) in baseData.enumerated() {
            let rowStack = UIStackView().then({
                $0.axis = .horizontal
                $0.spacing = 0
                $0.alignment = .top
                $0.distribution = .fill
            })
            for (x, text) in row.enumerated() {
                let layout = BadgeLayoutManager()
                let storage = NSTextStorage()
                storage.addLayoutManager(layout)
                let initialSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
                let container = NSTextContainer(size: initialSize)
                container.widthTracksTextView = true
                layout.addTextContainer(container)

                let label = TitleUITextView(delegate: textDelegate, textContainer: container)
                label.doSetup()
                if y % 2 != 0 {
                    label.backgroundColor = ColorUtil.theme.foregroundColor
                } else {
                    label.backgroundColor = ColorUtil.theme.backgroundColor
                }
                label.attributedText = text
                label.sizeToFit()
                label.widthAnchor /==/ columnWidths[x]// + 100
                label.heightAnchor /==/ rowHeights[y]
                label.verticalCompressionResistancePriority = .required
                rowStack.addArrangedSubview(label)
            }
            baseStackView.addArrangedSubview(rowStack)
        }

        addSubview(baseStackView)
        contentInset = UIEdgeInsets.init(top: 0, left: 8, bottom: 0, right: 8)
        baseStackView.edgeAnchors /==/ edgeAnchors
        contentSize = CGSize.init(width: globalWidth, height: globalHeight)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
               // TODO: - maybe gravity = Gravity.START;
            } else if !columnStarted && (current == tableColumnStartRight || current == tableHeaderStartRight) {
                columnStarted = true
               // TODO: - maybe gravity = Gravity.END;
            } else if !columnStarted && (current == tableColumnStartCenter || current == tableHeaderStartCenter) {
                columnStarted = true
               // TODO: - maybe gravity = Gravity.CENTER;
            } else if !columnStarted && (current == tableColumnStartLeft || current == tableHeaderStartLeft) {
                columnStarted = true
               // TODO: - maybe gravity = Gravity.START;
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

private extension Array {
    subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}
