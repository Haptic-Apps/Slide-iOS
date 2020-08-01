//
//  CommentLinkCellViewDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 7/28/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation

class CommentLinkCellViewDelegate: NSObject, LinkCellViewDelegate {
    // MARK: - Properties / Delegates
    private var commentController: CommentViewController!
    
    // MARK: - Initialization
    init(parentController: CommentViewController) {
        self.commentController = parentController
    }
    // MARK: - Methods
    /// Sets an upvote from the user.
    @objc func upvote(_ cell: LinkCellView) {
        do {
            try commentController.session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.id)!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!, skipDuplicates: true)
            cell.refresh()
            if commentController.parent is PagingCommentViewController {
                _ = (commentController.parent as! PagingCommentViewController).reloadCallback?()
            }
            _ = CachedTitle.getTitle(submission: cell.link!, full: false, true, gallery: false)
        } catch {

        }
    }
    
    /// Sets a downvote from the user.
    func downvote(_ cell: LinkCellView) {
        do {
            try commentController.session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.id)!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!, skipDuplicates: true)
            cell.refresh()
            if commentController.parent is PagingCommentViewController {
                (commentController.parent as! PagingCommentViewController).reloadCallback?()
            }
        } catch {

        }
    }
    
    /// Saves a selected comment.
    @objc func save(_ cell: LinkCellView) {
        do {
            let state = !ActionStates.isSaved(s: cell.link!)
            print(cell.link!.id)
            try commentController.session?.setSave(state, name: (cell.link?.id)!, completion: { (result) in
                if result.error != nil {
                    print(result.error!)
                }
                DispatchQueue.main.async {
                    BannerUtil.makeBanner(text: state ? "Saved" : "Unsaved", color: ColorUtil.accentColorForSub(sub: self.commentController.subreddit), seconds: 1, context: self.commentController)
                }
            })
            ActionStates.setSaved(s: cell.link!, saved: !ActionStates.isSaved(s: cell.link!))
            History.addSeen(s: cell.link!, skipDuplicates: true)
            cell.refresh()
            if commentController.parent is PagingCommentViewController {
                (commentController.parent as! PagingCommentViewController).reloadCallback?()
            }
        } catch {
        }
    }
    
    /// Displays more info and presents alert.
    func more(_ cell: LinkCellView) {
        if !commentController.offline {
            commentController.submissionMoreDelegate = CommentSubmissionMoreDelegate(parentController: commentController)
            PostActions.showMoreMenu(cell: cell, parent: commentController, nav: self.commentController.navigationController!, mutableList: false, delegate: commentController.submissionMoreDelegate, index: 0)
        }
    }
    
    /// Sets a reply from user.
    @objc func reply(_ cell: LinkCellView) {
        if !commentController.offline {
            commentController.commentReplyDelegate = CommentReplyDelegate(parentController: commentController)
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(submission: cell.link!, sub: cell.link!.subreddit, delegate: commentController.commentReplyDelegate)), parentVC: commentController)
        }
    }

    /// Undefined
    func hide(_ cell: LinkCellView) {

    }
    
    /// Undefined
    func openComments(id: String, subreddit: String?) {
        //don't do anything
    }
    
    /// Deletes a selected comment/
    func deleteSelf(_ cell: LinkCellView) {
        if !commentController.offline {
            do {
                try commentController.session?.deleteCommentOrLink(cell.link!.getId(), completion: { (_) in
                    DispatchQueue.main.async {
                        if (self.commentController.navigationController?.modalPresentationStyle ?? .formSheet) == .formSheet {
                            self.commentController.navigationController?.dismiss(animated: true)
                        } else {
                            self.commentController.navigationController?.popViewController(animated: true)
                        }
                    }
                })
            } catch {

            }
        }
    }
    
    /// Displays users moderation menu.
    func mod(_ cell: LinkCellView) {
        PostActions.showModMenu(cell, parent: commentController)
    }
    
    /// Saves link to save later.
    func readLater(_ cell: LinkCellView) {
        guard let link = cell.link else {
            return
        }

        ReadLater.toggleReadLater(link: link)
        if commentController.parent is PagingCommentViewController {
            (commentController.parent as! PagingCommentViewController).reloadCallback?()
        }
        cell.refresh()
    }
    
}
