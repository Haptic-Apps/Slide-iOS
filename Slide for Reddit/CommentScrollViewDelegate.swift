//
//  CommentScrollViewDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 7/28/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit

class CommentScrollViewDelegate: NSObject, UIScrollViewDelegate {
    // MARK: - Properties / References
    private var commentController: CommentViewController!
    
    // MARK: - Initialization
    init(parentController: CommentViewController) {
        self.commentController = parentController
    }
    // MARK: - Methods
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if scrollView.contentOffset.y > commentController.oldPosition.y {
            commentController.oldPosition = scrollView.contentOffset
            return true
        } else {
            commentController.tableView.setContentOffset(commentController.oldPosition, animated: true)
            commentController.oldPosition = CGPoint.zero
        }
        return false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.commentController.goingToCell = false
        self.commentController.isGoingDown = false
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.commentController.goingToCell = false
        self.commentController.isGoingDown = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentY = scrollView.contentOffset.y

        if !SettingValues.pinToolbar && !commentController.isReply && !commentController.isSearch {
            if currentY > commentController.lastYUsed && currentY > 60 {
                if commentController.navigationController != nil && !commentController.isHiding && !commentController.isToolbarHidden && !(scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
                    commentController.hideUI(inHeader: true)
                }
            } else if (currentY < commentController.lastYUsed - 15 || currentY < 100) && !commentController.isHiding && commentController.navigationController != nil && (commentController.isToolbarHidden) {
                commentController.showUI()
            }
        }
        commentController.lastYUsed = currentY
        commentController.lastY = currentY
    }
    
}
