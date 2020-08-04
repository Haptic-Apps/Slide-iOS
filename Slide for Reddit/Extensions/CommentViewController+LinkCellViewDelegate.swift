//
//  CommentViewController+LinkCellViewDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/3/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation

extension CommentViewController: LinkCellViewDelegate {
    // MARK: - Methods
    /// Sets an upvote from the user.
    @objc func upvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.id)!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!, skipDuplicates: true)
            cell.refresh()
            if parent is PagingCommentViewController {
                _ = (parent as! PagingCommentViewController).reloadCallback?()
            }
            _ = CachedTitle.getTitle(submission: cell.link!, full: false, true, gallery: false)
        } catch {

        }
    }
    
    /// Sets a downvote from the user.
    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.id)!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!, skipDuplicates: true)
            cell.refresh()
            if parent is PagingCommentViewController {
                (parent as! PagingCommentViewController).reloadCallback?()
            }
        } catch {

        }
    }
    
    /// Saves a link cell.
    @objc func save(_ cell: LinkCellView) {
            do {
                let state = !ActionStates.isSaved(s: cell.link!)
                print(cell.link!.id)
                try session?.setSave(state, name: (cell.link?.id)!, completion: { (result) in
                    if result.error != nil {
                        print(result.error!)
                    }
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: state ? "Saved" : "Unsaved", color: ColorUtil.accentColorForSub(sub: self.subreddit), seconds: 1, context: self)
                    }
                })
                ActionStates.setSaved(s: cell.link!, saved: !ActionStates.isSaved(s: cell.link!))
                History.addSeen(s: cell.link!, skipDuplicates: true)
                cell.refresh()
                if parent is PagingCommentViewController {
                    (parent as! PagingCommentViewController).reloadCallback?()
                }
            } catch {
            }
        }
    
    /// Displays more info and presents alert.
    func more(_ cell: LinkCellView) {
        if !offline {
            PostActions.showMoreMenu(cell: cell, parent: self, nav: self.navigationController!, mutableList: false, delegate: self, index: 0)
        }
    }
    
    /// Sets a reply from user.
    @objc func reply(_ cell: LinkCellView) {
        if !offline {
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(submission: cell.link!, sub: cell.link!.subreddit, delegate: self)), parentVC: self)
        }
    }
    
    /// Hide a cell view.
    func hide(_ cell: LinkCellView) {
        // Add stuff here.
    }

    /// Undefined
    func openComments(id: String, subreddit: String?) {
        // don't do anything
    }
    
    /// Deletes a selected comment.
    func deleteSelf(_ cell: LinkCellView) {
        if !offline {
            do {
                try session?.deleteCommentOrLink(cell.link!.getId(), completion: { (_) in
                    DispatchQueue.main.async {
                        if (self.navigationController?.modalPresentationStyle ?? .formSheet) == .formSheet {
                            self.navigationController?.dismiss(animated: true)
                        } else {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                })
            } catch {
                
            }
        }
    }
    
    /// Displays users moderation menu.
    func mod(_ cell: LinkCellView) {
        PostActions.showModMenu(cell, parent: self)
    }
    
    /// Saves link to save later.
    func readLater(_ cell: LinkCellView) {
        guard let link = cell.link else {
            return
        }

        ReadLater.toggleReadLater(link: link)
        if parent is PagingCommentViewController {
            (parent as! PagingCommentViewController).reloadCallback?()
        }
        cell.refresh()
    }
    
}
