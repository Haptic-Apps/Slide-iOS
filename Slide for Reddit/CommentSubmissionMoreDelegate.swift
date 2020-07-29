//
//  CommentSubmissionMoreDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 7/28/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation

class CommentSubmissionMoreDelegate: NSObject, SubmissionMoreDelegate {
    // MARK: - Properties / References
    private var commentController: CommentViewController!
    
    // MARK: - Initialization
    init(parentController: CommentViewController) {
        self.commentController = parentController
    }
    
    // MARK: - Methods
    func save(_ cell: LinkCellView) {
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
    
    func hide(_ cell: LinkCellView) {

    }
    
    func showFilterMenu(_ cell: LinkCellView) {
        //Not implemented
    }
    
    func applyFilters() {
        if PostFilter.filter([commentController.submission!], previous: nil, baseSubreddit: "all").isEmpty {
            self.commentController.navigationController?.popViewController(animated: true)
        }
    }
    
    func hide(index: Int) {
        if index >= 0 {
            self.commentController.navigationController?.popViewController(animated: true)
        }
    }
    
    func subscribe(link: RSubmission) {
        let sub = link.subreddit
        let alrController = UIAlertController.init(title: "Follow r/\(sub)", message: nil, preferredStyle: .alert)
        if AccountController.isLoggedIn {
            let somethingAction = UIAlertAction(title: "Subscribe", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) in
                Subscriptions.subscribe(sub, true, session: self.commentController.session!)
                self.commentController.subChanged = true
                BannerUtil.makeBanner(text: "Subscribed to r/\(sub)", color: ColorUtil.accentColorForSub(sub: sub), seconds: 3, context: self.commentController, top: true)
            })
            alrController.addAction(somethingAction)
        }
        
        let somethingAction = UIAlertAction(title: "Casually subscribe", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) in
            Subscriptions.subscribe(sub, false, session: self.commentController.session!)
            self.commentController.subChanged = true
            BannerUtil.makeBanner(text: "r/\(sub) added to your subreddit list", color: ColorUtil.accentColorForSub(sub: sub), seconds: 3, context: self.commentController, top: true)
        })
        alrController.addAction(somethingAction)
        
        alrController.addCancelButton()
        
        alrController.modalPresentationStyle = .fullScreen
        self.commentController.present(alrController, animated: true, completion: {})
    }
}
