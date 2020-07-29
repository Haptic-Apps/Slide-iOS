//
//  CommentTableViewDataSource.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 7/28/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit
import RealmSwift

class CommentTableViewDataSource: NSObject, UITableViewDataSource {
    // MARK: - Properties / References
    private var commentController: CommentViewController!
    
    // MARK: - Initialization
    init(parentController: CommentViewController) {
        self.commentController = parentController
    }
    // MARK: - Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (commentController.isSearching ? self.commentController.filteredData.count : self.commentController.comments.count - self.commentController.hidden.count)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if SettingValues.collapseFully {
            let datasetPosition = (indexPath as NSIndexPath).row
            if commentController.dataArray.isEmpty {
                return UITableView.automaticDimension
            }
            let thing = commentController.isSearching ? commentController.filteredData[datasetPosition] : commentController.dataArray[datasetPosition]
            if !commentController.hiddenPersons.contains(thing) && thing != self.commentController.menuId {
                if let height = commentController.oldHeights[thing] {
                    return height
                }
            }
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = nil

        let datasetPosition = (indexPath as NSIndexPath).row

        cell = tableView.dequeueReusableCell(withIdentifier: "Cell\(commentController.version)", for: indexPath) as UITableViewCell
        if commentController.content.isEmpty || commentController.text.isEmpty || commentController.cDepth.isEmpty || commentController.dataArray.isEmpty {
            self.commentController.refresh(self)
            return cell
        }
        let thing = commentController.isSearching ? commentController.filteredData[datasetPosition] : commentController.dataArray[datasetPosition]
        let parentOP = commentController.parents[thing]
        if let cell = cell as? CommentDepthCell {
            let innerContent = commentController.content[thing]
            if innerContent is RComment {
                var count = 0
                let hiddenP = commentController.hiddenPersons.contains(thing)
                if hiddenP {
                    count = commentController.getChildNumber(n: innerContent!.getIdentifier())
                }
                var t = commentController.text[thing]!
                if commentController.isSearching {
                    t = commentController.highlight(t)
                }

                cell.setComment(comment: innerContent as! RComment, depth: commentController.cDepth[thing]!, parent: commentController, hiddenCount: count, date: commentController.lastSeen, author: commentController.submission?.author, text: t, isCollapsed: hiddenP, parentOP: parentOP ?? "", depthColors: commentController.commentDepthColors, indexPath: indexPath, width: self.commentController.tableView.frame.size.width)
            } else {
                cell.setMore(more: (innerContent as! RMore), depth: commentController.cDepth[thing]!, depthColors: commentController.commentDepthColors, parent: commentController)
            }
            cell.content = commentController.content[thing]
        }
        
        return cell
    }
    
}
