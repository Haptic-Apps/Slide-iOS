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
        var currentY = scrollView.contentOffset.y
        
        //Sometimes the ScrollView will jump one time in the wrong direction. Unsure why this is happening, but this
        //will check for that case and ignore it
        if currentY > lastY && lastY < olderY {
            currentY = lastY
        }
        
        if !SettingValues.dontHideTopBar && !isReply && !isSearch {
            if currentY <= (tableView.tableHeaderView?.frame.size.height ?? 20) + 64 + 10 {
                liveView?.removeFromSuperview()
                liveView = nil
                liveNewCount = 0
            }
            if currentY > lastY && currentY > 60 {
                if navigationController != nil && !isHiding && !isToolbarHidden && !(scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
                    hideUI(inHeader: true)
                }
            } else if (currentY < lastY - 15 || currentY < 100) && !isHiding && navigationController != nil && (isToolbarHidden) {
                showUI()
            }
        }
        olderY = lastY
        lastY = currentY
    }
    
}
