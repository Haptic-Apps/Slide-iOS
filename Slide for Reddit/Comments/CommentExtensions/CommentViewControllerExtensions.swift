//
//  CommentViewControllerExtensions.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 7/29/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import UIKit

extension CommentViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == panGesture {
            if SettingValues.commentGesturesMode == .NONE || SettingValues.commentGesturesMode == .SWIPE_ANYWHERE {
                return false
            }
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if SettingValues.commentGesturesMode == .GESTURES {
            if gestureRecognizer.numberOfTouches == 2 {
                return true
            }
        }
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Limit angle of pan gesture recognizer to avoid interfering with scrolling
        if gestureRecognizer == panGesture {
            if SettingValues.commentGesturesMode == .NONE || SettingValues.commentGesturesMode == .SWIPE_ANYWHERE {
                return false
            }
        }
        
        if let recognizer = gestureRecognizer as? UIPanGestureRecognizer, recognizer == panGesture {
            return recognizer.shouldRecognizeForAxis(.horizontal, withAngleToleranceInDegrees: 45)
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return SettingValues.commentActionRightLeft == .NONE && SettingValues.commentActionRightRight == .NONE && translatingCell == nil
    }
    
    @objc func panCell(_ recognizer: UIPanGestureRecognizer) {
        
        if recognizer.view != nil {
            let velocity = recognizer.velocity(in: recognizer.view!).x
            if (velocity < 0 && (SettingValues.commentActionLeftLeft == .NONE && SettingValues.commentActionLeftRight == .NONE) && translatingCell == nil) || (velocity > 0 && (SettingValues.commentActionRightLeft == .NONE && SettingValues.commentActionRightRight == .NONE) && translatingCell == nil) {
                return
            }
        }

        if recognizer.state == .began || translatingCell == nil {
            let point = recognizer.location(in: self.tableView)
            let indexpath = self.tableView.indexPathForRow(at: point)
            if indexpath == nil {
                return
            }

            guard let cell = self.tableView.cellForRow(at: indexpath!) as? CommentDepthCell else { return }
            for view in cell.commentBody.subviews {
                let cellPoint = recognizer.location(in: view)
                if (view is UIScrollView || view is CodeDisplayView || view is TableDisplayView) && view.bounds.contains(cellPoint) {
                    recognizer.cancel()
                    return
                }
            }
            translatingCell = cell
        }
        
        translatingCell?.handlePan(recognizer)
        if recognizer.state == .ended {
            translatingCell = nil
        }
    }
}


extension CommentViewController: UIViewControllerPreviewingDelegate {
        
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location) else {
            return nil
        }
        
        guard let cell = self.tableView.cellForRow(at: indexPath) as? CommentDepthCell else {
            return nil
        }
        
        if SettingValues.commentActionForceTouch != .PARENT_PREVIEW {
           // TODO: - maybe
            /*let textView =
            let locationInTextView = textView.convert(location, to: textView)
            
            if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
                previewingContext.sourceRect = textView.convert(rect, from: textView)
                if let controller = parentViewController?.getControllerForUrl(baseUrl: url) {
                    return controller
                }
            }*/
            return nil
        }
        
        if cell.depth == 1 {
            return nil
        }
        self.setAlphaOfBackgroundViews(alpha: 0.5)

        var topCell = (indexPath as NSIndexPath).row
        
        var contents = content[dataArray[topCell]]
        
        while (contents is RComment ? (contents as! RComment).depth >= cell.depth : true) && dataArray.count > topCell && topCell - 1 >= 0 {
            topCell -= 1
            contents = content[dataArray[topCell]]
        }

        let parentCell = CommentDepthCell(style: .default, reuseIdentifier: "test")
        if let comment = contents as? RComment {
            parentCell.contentView.layer.cornerRadius = 10
            parentCell.contentView.clipsToBounds = true
            parentCell.commentBody.ignoreHeight = false
            parentCell.commentBody.estimatedWidth = UIScreen.main.bounds.size.width * 0.85 - 36
            if contents is RComment {
                var count = 0
                let hiddenP = hiddenPersons.contains(comment.getIdentifier())
                if hiddenP {
                    count = getChildNumber(n: comment.getIdentifier())
                }
                var t = text[comment.getIdentifier()]!
                if isSearching {
                    t = highlight(t)
                }
                
                parentCell.setComment(comment: contents as! RComment, depth: 0, parent: self, hiddenCount: count, date: lastSeen, author: submission?.author, text: t, isCollapsed: hiddenP, parentOP: "", depthColors: commentDepthColors, indexPath: indexPath, width: UIScreen.main.bounds.size.width * 0.85)
            } else {
                parentCell.setMore(more: (contents as! RMore), depth: cDepth[comment.getIdentifier()]!, depthColors: commentDepthColors, parent: self)
            }
            parentCell.content = comment
            parentCell.contentView.isUserInteractionEnabled = false

            var size = CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: CGFloat.greatestFiniteMagnitude)
            let layout = YYTextLayout(containerSize: size, text: parentCell.title.attributedText!)!
            let textSize = layout.textBoundingSize

            size = CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: parentCell.commentBody.estimatedHeight + 24 + textSize.height)// TODO: - fix height
            let detailViewController = ParentCommentViewController(view: parentCell.contentView, size: size)
            detailViewController.preferredContentSize = CGSize(width: size.width, height: min(size.height, 300))

            previewingContext.sourceRect = cell.frame
            detailViewController.dismissHandler = {() in
                self.setAlphaOfBackgroundViews(alpha: 1)
            }
            return detailViewController
        }
        return nil
    }
        
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewControllerToCommit.modalPresentationStyle = .popover
        if let popover = viewControllerToCommit.popoverPresentationController {
            popover.sourceView = self.tableView
            popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            popover.backgroundColor = ColorUtil.theme.foregroundColor
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            //detailViewController.frame = CGRect(x: (self.view.frame.bounds.width / 2 - (UIScreen.main.bounds.size.width * 0.85)), y: (self.view.frame.bounds.height / 2 - (cell2.title.estimatedHeight + 12)), width: UIScreen.main.bounds.size.width * 0.85, height: cell2.title.estimatedHeight + 12)
            popover.delegate = self
            viewControllerToCommit.preferredContentSize = (viewControllerToCommit as! ParentCommentViewController).estimatedSize
        }

        self.present(viewControllerToCommit, animated: true, completion: {
        })
    }
}


extension CommentViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Fixes bug with corrupt nav stack
        // https://stackoverflow.com/a/39457751/7138792
        navigationController.interactivePopGestureRecognizer?.isEnabled = navigationController.viewControllers.count > 1
        if navigationController.viewControllers.count == 1 {
            self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}


extension CommentViewController: TapBehindModalViewControllerDelegate {
    func shouldDismiss() -> Bool {
        return false
    }
}
