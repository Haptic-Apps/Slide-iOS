//
//  CommentViewController+UIScrollViewDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/3/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit

extension CommentViewController: UIScrollViewDelegate {
    // MARK: - Methods
    /// Sets position of scroll view when scrolling to top.
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if scrollView.contentOffset.y > oldPosition.y {
            oldPosition = scrollView.contentOffset
            return true
        } else {
            tableView.setContentOffset(oldPosition, animated: true)
            oldPosition = CGPoint.zero
        }
        return false
    }
    
    /// When the user has stopped scrolling.
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.goingToCell = false
        self.isGoingDown = false
    }
    
    /// When the user has stopped scrolling and the animation has stopped.
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.goingToCell = false
        self.isGoingDown = false
    }
    
    /// Upon the user scrolling through comments.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentY = scrollView.contentOffset.y

        if !SettingValues.pinToolbar && !isReply && !isSearch {
            if currentY > lastYUsed && currentY > 60 {
                if navigationController != nil && !isHiding && !isToolbarHidden && !(scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
                    hideNavigationBars(inHeader: true)
                }
            } else if (currentY < lastYUsed - 15 || currentY < 100) && !isHiding && navigationController != nil && (isToolbarHidden) {
                showNavigationBars()
            }
        }
        lastYUsed = currentY
        lastY = currentY
    }
    
}
