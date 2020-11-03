//
//  CommentViewController+UIViewControllerPreviewingDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/3/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit
import YYText
import reddift

extension CommentViewController: UIViewControllerPreviewingDelegate {
    // MARK: - Methods
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
