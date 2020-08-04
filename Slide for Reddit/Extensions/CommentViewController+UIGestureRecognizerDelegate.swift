//
//  CommentViewController+UIGestureRecognizerDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/3/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit

extension CommentViewController: UIGestureRecognizerDelegate {
    // MARK: - Methods
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
