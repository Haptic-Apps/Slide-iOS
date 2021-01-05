//
//  CommentViewController+UITableViewDataSource.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 7/28/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit
import RealmSwift

extension CommentViewController: UITableViewDataSource {
    // MARK: - Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (isSearching ? self.filteredData.count : self.comments.count - self.hidden.count)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if SettingValues.collapseFully {
            let datasetPosition = (indexPath as NSIndexPath).row
            if dataArray.isEmpty {
                return UITableView.automaticDimension
            }
            let thing = isSearching ? filteredData[datasetPosition] : dataArray[datasetPosition]
            if !hiddenPersons.contains(thing) && thing != self.menuId {
                if let height = oldHeights[thing] {
                    return height
                }
            }
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = nil

        let datasetPosition = (indexPath as NSIndexPath).row

        cell = tableView.dequeueReusableCell(withIdentifier: "Cell\(version)", for: indexPath) as UITableViewCell
        if content.isEmpty || text.isEmpty || cDepth.isEmpty || dataArray.isEmpty {
            self.refreshComments(self)
            return cell
        }
        let thing = isSearching ? filteredData[datasetPosition] : dataArray[datasetPosition]
        let parentOP = parents[thing]
        if let cell = cell as? CommentDepthCell {
            let innerContent = content[thing]
            if innerContent is RComment {
                var count = 0
                let hiddenP = hiddenPersons.contains(thing)
                if hiddenP {
                    count = getChildNumber(n: innerContent!.getIdentifier())
                }
                var t = text[thing]!
                if isSearching {
                    t = highlight(t)
                }

                cell.setComment(comment: innerContent as! RComment, depth: cDepth[thing]!, parent: self, hiddenCount: count, date: lastSeen, author: submission?.author, text: t, isCollapsed: hiddenP, parentOP: parentOP ?? "", depthColors: commentDepthColors, indexPath: indexPath, width: self.tableView.frame.size.width)
            } else {
                cell.setMore(more: (innerContent as! RMore), depth: cDepth[thing]!, depthColors: commentDepthColors, parent: self)
            }
            cell.content = content[thing]
        }
        
        return cell
    }
    
}
