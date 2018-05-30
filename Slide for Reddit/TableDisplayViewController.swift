//
//  TableDisplayViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 05/29/18.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import MaterialComponents.MaterialSnackbar
import XLActionController
import TTTAttributedLabel
import SwiftSpreadsheet

class TableDisplayViewController: MediaViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var backupData = [[NSAttributedString]]()
    var flippedData = [[NSAttributedString]]()

    var baseData = [[NSAttributedString]]()
    var tableView: UICollectionView!
    var scrollView: UIScrollView!
    var widths = [[CGFloat]]()
    var baseColor: UIColor

    init(baseHtml: String, color: UIColor) {
        var newData = baseHtml.replacingOccurrences(of: "http://view.table/", with: "")
        self.baseColor = color
        super.init(nibName: nil, bundle: nil)
        parseHtml(newData.removingPercentEncoding!)
        setBarColors(color: color)
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

        var i = 0
        var columnStart = 0
        var columnEnd = 0
        var columnStarted = false

        var currentRow = [NSAttributedString]()
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
                    let attr = try NSMutableAttributedString(data: text.subsequence(columnStart, endIndex: columnEnd).data(using: .unicode)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                    let font = FontGenerator.fontOfSize(size: 16, submission: false)
                    let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: baseColor)
                    let cell = LinkParser.parse(attr2, baseColor)
                    currentRow.append(cell)
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

        var header = [NSAttributedString]()
        for row in baseData {
            if(header.isEmpty){
                header = row
            } else {
                for index in 0...row.count - 1 {
                    flippedData.append([header[index], row[index]])
                }
            }
        }

        backupData = baseData
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
                var length = textSize.width + 25
                currentWidths.append(length)
            }
            widths.append(currentWidths)
        }
    }

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
    }

    var list = true

    override func viewDidLoad() {
        super.viewDidLoad()
        let frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        let layout = SpreadsheetLayout(delegate: self,
                topLeftDecorationViewNib: nil,
                topRightDecorationViewNib: nil,
                bottomLeftDecorationViewNib: nil,
                bottomRightDecorationViewNib: nil)

        self.tableView = UICollectionView.init(frame: frame, collectionViewLayout: layout)
        self.view = tableView
        self.tableView.bounces = false

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.isUserInteractionEnabled = true
        self.tableView.register(TextCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "content")
        self.view.backgroundColor = ColorUtil.backgroundColor

        doList()
    }

    func doList(){
        list = !list
        doData()
        if(list){
            let list = UIButton.init(type: .custom)
            list.setImage(UIImage.init(named: "grid")?.menuIcon(), for: UIControlState.normal)
            list.addTarget(self, action: #selector(self.doList), for: UIControlEvents.touchUpInside)
            list.frame = CGRect.init(x: 0, y: 0, width: 35, height: 35)
            let listB = UIBarButtonItem.init(customView: list)
            navigationItem.rightBarButtonItem = listB
        } else {
            let list = UIButton.init(type: .custom)
            list.setImage(UIImage.init(named: "list")?.menuIcon(), for: UIControlState.normal)
            list.addTarget(self, action: #selector(self.doList), for: UIControlEvents.touchUpInside)
            list.frame = CGRect.init(x: 0, y: 0, width: 35, height: 35)
            let listB = UIBarButtonItem.init(customView: list)
            navigationItem.rightBarButtonItem = listB
        }
        tableView.reloadData()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return baseData.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return baseData[section].count
    }

    func collectionView(_ tableView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = tableView.dequeueReusableCell(withReuseIdentifier: "content", for: indexPath) as! TextCollectionViewCell
        cell.textLabel.setText(baseData[indexPath.section][indexPath.row])

        if(list){
            if(indexPath.row == 0){
                cell.contentView.backgroundColor = baseColor
            } else {
                if indexPath.section%2 == 0 {
                    cell.contentView.backgroundColor = ColorUtil.foregroundColor
                } else {
                    cell.contentView.backgroundColor = ColorUtil.backgroundColor
                }
            }

        } else {
            if indexPath.row%2 == 0 {
                cell.contentView.backgroundColor = ColorUtil.foregroundColor
            } else {
                cell.contentView.backgroundColor = ColorUtil.backgroundColor
            }

            if(indexPath.section == 0){
                cell.contentView.backgroundColor = baseColor
            }
        }
        return cell
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

extension TableDisplayViewController: SpreadsheetLayoutDelegate {
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
