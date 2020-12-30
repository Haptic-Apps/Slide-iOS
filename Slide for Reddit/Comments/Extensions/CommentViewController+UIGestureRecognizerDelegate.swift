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
    func setupGestures() {
        cellGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panCell(_:)))
        cellGestureRecognizer.delegate = self
        cellGestureRecognizer.maximumNumberOfTouches = 1
        tableView.addGestureRecognizer(cellGestureRecognizer)
        if UIDevice.current.userInterfaceIdiom != .pad {
           // cellGestureRecognizer.require(toFail: tableView.panGestureRecognizer)
        }
        if let parent = parent as? ColorMuxPagingViewController {
            parent.requireFailureOf(cellGestureRecognizer)
        }
        if let nav = self.navigationController as? SwipeForwardNavigationController {
            nav.fullWidthBackGestureRecognizer.require(toFail: cellGestureRecognizer)
            nav.interactivePushGestureRecognizer?.require(toFail: cellGestureRecognizer)
            if let interactivePop = nav.interactivePopGestureRecognizer {
                cellGestureRecognizer.require(toFail: interactivePop)
            }
        }
    }
        
    func setupSwipeGesture() {
        shouldSetupSwipe = true
        if swipeBackAdded {
            return
        }

        if UIDevice.current.userInterfaceIdiom == .pad && SettingValues.appMode != .SINGLE {
            if #available(iOS 14, *) {
                return
            }
        }
        if SettingValues.commentGesturesMode == .FULL {
            if let full = fullWidthBackGestureRecognizer {
                full.view?.removeGestureRecognizer(full)
            }
            return
        }
        
        setupFullSwipeView(self.tableView)
        shouldSetupSwipe = false
        swipeBackAdded = true
    }
        
    func setupFullSwipeView(_ view: UIView?) {
        if shouldSetupSwipe == false || SettingValues.commentGesturesMode == .FULL {
            return
        }
        if let full = fullWidthBackGestureRecognizer {
            full.view?.removeGestureRecognizer(full)
        }

        fullWidthBackGestureRecognizer = UIPanGestureRecognizer()
        if let interactivePopGestureRecognizer = parent?.navigationController?.interactivePopGestureRecognizer, let targets = interactivePopGestureRecognizer.value(forKey: "targets"), parent is ColorMuxPagingViewController, !swipeBackAdded {
            setupSwipeWithTarget(fullWidthBackGestureRecognizer, interactivePopGestureRecognizer: interactivePopGestureRecognizer, targets: targets)
        } else if !(parent is ColorMuxPagingViewController) && !swipeBackAdded {
            if let interactivePopGestureRecognizer = self.navigationController?.interactivePopGestureRecognizer, let targets = interactivePopGestureRecognizer.value(forKey: "targets") {
                setupSwipeWithTarget(fullWidthBackGestureRecognizer, interactivePopGestureRecognizer: interactivePopGestureRecognizer, targets: targets)
            }
        }
        if let nav = navigationController as? SwipeForwardNavigationController {
            let gesture = nav.fullWidthBackGestureRecognizer
            nav.interactivePushGestureRecognizer?.require(toFail: fullWidthBackGestureRecognizer)
            gesture.require(toFail: fullWidthBackGestureRecognizer)
        }
    }

    func setupSwipeWithTarget(_ fullWidthBackGestureRecognizer: UIPanGestureRecognizer, interactivePopGestureRecognizer: UIGestureRecognizer, targets: Any?) {
        fullWidthBackGestureRecognizer.require(toFail: tableView.panGestureRecognizer)
        if let navGesture = self.navigationController?.interactivePopGestureRecognizer {
            fullWidthBackGestureRecognizer.require(toFail: navGesture)
        }
        if let navGesture = (self.navigationController as? SwipeForwardNavigationController)?.fullWidthBackGestureRecognizer {
            navGesture.require(toFail: fullWidthBackGestureRecognizer)
        }
        fullWidthBackGestureRecognizer.require(toFail: interactivePopGestureRecognizer)
        for view in parent?.view.subviews ?? [] {
            if view is UIScrollView {
                (view as! UIScrollView).panGestureRecognizer.require(toFail: fullWidthBackGestureRecognizer)
            }
        }

        fullWidthBackGestureRecognizer.setValue(targets, forKey: "targets")
        fullWidthBackGestureRecognizer.delegate = self
        //parent.requireFailureOf(fullWidthBackGestureRecognizer)
        view?.addGestureRecognizer(fullWidthBackGestureRecognizer)
        if #available(iOS 13.4, *) {
            fullWidthBackGestureRecognizer.allowedScrollTypesMask = .continuous
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return !(otherGestureRecognizer == cellGestureRecognizer && otherGestureRecognizer.state != .ended)
    }
        
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: tableView)
            if panGestureRecognizer == cellGestureRecognizer {
                if abs(translation.y) >= abs(translation.x) {
                    return false
                }
                if translation.x < 0 {
                    if gestureRecognizer.location(in: tableView).x > tableView.frame.width * 0.5 || !SettingValues.commentGesturesMode.shouldPage() {
                        return true
                    }
                } else if !SettingValues.commentGesturesMode.shouldPage() && abs(translation.x) > abs(translation.y) {
                    return gestureRecognizer.location(in: tableView).x > tableView.frame.width * 0.1
                }
                return false
            }
            if panGestureRecognizer == fullWidthBackGestureRecognizer && translation.x >= 0 {
                return true
            }
            return false
        }
        return false
    }

    @objc func panCell(_ recognizer: UIPanGestureRecognizer) {
        
        if recognizer.view != nil {
            let velocity = recognizer.velocity(in: recognizer.view!)

            if (velocity.x < 0 && (SettingValues.commentActionLeftLeft == .NONE && SettingValues.commentActionLeftRight == .NONE) && translatingCell == nil) || (velocity.x > 0 && (SettingValues.commentGesturesMode == .HALF || SettingValues.commentGesturesMode == .HALF_FULL || (SettingValues.commentActionRightLeft == .NONE && SettingValues.commentActionRightRight == .NONE)) && translatingCell == nil) {
                return
            }
        }

        if recognizer.state == .began || translatingCell == nil {
            let point = recognizer.location(in: self.tableView)
            let indexpath = self.tableView.indexPathForRow(at: point)
            if indexpath == nil {
                recognizer.cancel()
                return
            }

            guard let cell = self.tableView.cellForRow(at: indexpath!) as? CommentDepthCell else { return }
            for view in cell.commentBody.recursiveSubviews {
                let cellPoint = recognizer.location(in: view)
                if (view is UIScrollView || view is CodeDisplayView || view is TableDisplayView) && view.bounds.contains(cellPoint) {
                    recognizer.cancel()
                    return
                }
            }
            tableView.panGestureRecognizer.cancel()
            disableDismissalRecognizers()
            translatingCell = cell
        }
        
        translatingCell?.handlePan(recognizer)
        if recognizer.state == .ended || recognizer.state == .cancelled {
            translatingCell = nil
            enableDismissalRecognizers()
        }
    }

}
