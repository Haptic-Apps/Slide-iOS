//
//  MoreMenu.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import ActionSheetPicker_3_0
import RealmSwift
import reddift
import RLBAlertsPickers
import UIKit
import XLActionController

protocol SubmissionMoreDelegate: class {
    func save(_ cell: LinkCellView)
    func hide(_ cell: LinkCellView)
    func showFilterMenu(_ cell: LinkCellView)
    func applyFilters()
    func hide(index: Int)
}

class PostActions: NSObject {
    
    public static func showPostMenu(_ parent: UIViewController, sub: String) {
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "New submission"
        
        alertController.addAction(Action(ActionData(title: "Image", image: UIImage(named: "camera")!.menuIcon()), style: .default, handler: { _ in
            VCPresenter.showVC(viewController: ReplyViewController.init(subreddit: sub, type: ReplyViewController.ReplyType.SUBMIT_IMAGE, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: parent.navigationController, parentViewController: parent)
            }), popupIfPossible: true, parentNavigationController: nil, parentViewController: parent)
        }))
        
        alertController.addAction(Action(ActionData(title: "Link", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { _ in
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(subreddit: sub, type: ReplyViewController.ReplyType.SUBMIT_LINK, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: parent.navigationController, parentViewController: parent)
            })), parentVC: parent)
        }))
        
        alertController.addAction(Action(ActionData(title: "Selftext", image: UIImage(named: "size")!.menuIcon()), style: .default, handler: { _ in
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(subreddit: sub, type: ReplyViewController.ReplyType.SUBMIT_TEXT, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: parent.navigationController, parentViewController: parent)
            })), parentVC: parent)
        }))
        VCPresenter.presentAlert(alertController, parentVC: parent)

    }
    
    public static func showMoreMenu(cell: LinkCellView, parent: UIViewController, nav: UINavigationController, mutableList: Bool, delegate: SubmissionMoreDelegate, index: Int) {
        let link = cell.link!
        
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Submission by \(AccountController.formatUsername(input: link.author, small: true))"
        
        alertController.addAction(Action(ActionData(title: "\(AccountController.formatUsernamePosessive(input: link.author, small: false)) profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { _ in
            
            let prof = ProfileViewController.init(name: link.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: nav, parentViewController: parent)
        }))
        alertController.addAction(Action(ActionData(title: "r/\(link.subreddit)", image: UIImage(named: "subs")!.menuIcon()), style: .default, handler: { _ in
            
            let sub = SingleSubredditViewController.init(subName: link.subreddit, single: true)
            VCPresenter.showVC(viewController: sub, popupIfPossible: true, parentNavigationController: nav, parentViewController: parent)
            
        }))
        alertController.addAction(Action(ActionData(title: "Report content", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { _ in
            PostActions.report(cell.link!, parent: parent, index: index, delegate: delegate)
        }))
        alertController.addAction(Action(ActionData(title: "Block user", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: { _ in
            PostActions.block(cell.link!.author, parent: parent) { () in
                delegate.applyFilters()
            }
        }))

        if AccountController.isLoggedIn {
            if SettingValues.actionBarMode != .FULL && AccountController.modSubs.contains(link.subreddit) {
                alertController.addAction(Action(ActionData(title: "Moderate", image: UIImage(named: "mod")!.menuIcon()), style: .default, handler: { _ in
                    PostActions.showModMenu(cell, parent: parent)
                }))
            }
            
            if SettingValues.actionBarMode == .NONE {
                alertController.addAction(Action(ActionData(title: "Upvote", image: UIImage(named: "upvote")!.menuIcon().getCopy(withColor: ColorUtil.upvoteColor)), style: .default, handler: { _ in
                    cell.upvote()
                }))
                alertController.addAction(Action(ActionData(title: "Downvote", image: UIImage(named: "downvote")!.menuIcon().getCopy(withColor: ColorUtil.downvoteColor)), style: .default, handler: { _ in
                    cell.downvote()
                }))
            }
            
            alertController.addAction(Action(ActionData(title: "Save", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { _ in
                delegate.save(cell)
            }))
            
            alertController.addAction(Action(ActionData(title: "Crosspost", image: UIImage(named: "crosspost")!.menuIcon()), style: .default, handler: { _ in
                PostActions.crosspost(cell.link!, parent)
            }))
        }
        
        if ReadLater.isReadLater(id: cell.link!.getIdentifier()) {
            alertController.addAction(Action(ActionData(title: "Remove from Read Later", image: UIImage(named: "restore")!.menuIcon()), style: .default, handler: { _ in
                ReadLater.removeReadLater(id: cell.link!.getIdentifier())
                BannerUtil.makeBanner(text: "Added to Read Later", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController, top: true)
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Add to Read Later", image: UIImage(named: "readLater")!.menuIcon()), style: .default, handler: { _ in
                ReadLater.addReadLater(id: cell.link!.getIdentifier(), subreddit: cell.link!.subreddit)
                BannerUtil.makeBanner(text: "Added to Read Later", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController, top: true)
            }))
        }
        
        alertController.addAction(Action(ActionData(title: "Share content", image: UIImage(named: "share")!.menuIcon()), style: .default, handler: { _ in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [link.url!], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = cell.contentView
                presenter.sourceRect = cell.contentView.bounds
            }
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil)
        }))
        alertController.addAction(Action(ActionData(title: "Share Reddit link", image: UIImage(named: "comments")!.menuIcon()), style: .default, handler: { _ in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [URL.init(string: "https://reddit.com" + link.permalink)!], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = cell.contentView
                presenter.sourceRect = cell.contentView.bounds
            }
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil)
        }))
        
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            
            alertController.addAction(Action(ActionData(title: "Open in Chrome", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { _ in
                open.openInChrome(link.url!, callbackURL: nil, createNewTab: true)
            }))
        }
        alertController.addAction(Action(ActionData(title: "Open in Safari", image: UIImage(named: "world")!.menuIcon()), style: .default, handler: { _ in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(link.url!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(link.url!)
            }
        }))
        if link.isSelf {
            alertController.addAction(Action(ActionData(title: "Copy text", image: UIImage(named: "copy")!.menuIcon()), style: .default, handler: { _ in
                let alert = UIAlertController.init(title: "Copy text", message: "", preferredStyle: .alert)
                alert.addTextViewer(text: .text(cell.link!.body))
                alert.addAction(UIAlertAction.init(title: "Copy all", style: .default, handler: { (_) in
                    UIPasteboard.general.string = cell.link!.body
                }))
                alert.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: { (_) in
                    
                }))
                let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
                currentViewController.present(alert, animated: true, completion: nil)
            }))
        }
        
        if mutableList {
            alertController.addAction(Action(ActionData(title: "Filter this content", image: UIImage(named: "filter")!.menuIcon()), style: .default, handler: { _ in
                delegate.showFilterMenu(cell)
            }))
            alertController.addAction(Action(ActionData(title: "Hide", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { _ in
                delegate.hide(cell)
            }))
        }
        
        VCPresenter.presentAlert(alertController, parentVC: parent)
    }
    
    static func showModMenu(_ cell: LinkCellView, parent: UIViewController) {
        //todo remove with reason, new icons
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Submission by u/\(cell.link!.author)"
        
        alertController.addAction(Action(ActionData(title: "\(cell.link!.reports.count) reports", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { _ in
            var reports = ""
            for report in cell.link!.reports {
                reports += report + "\n"
            }
            let alert = UIAlertController(title: "Reports",
                                          message: reports,
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let cancelAction = UIAlertAction(title: "OK",
                                             style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            parent.present(alert, animated: true, completion: nil)
            
        }))
        
        if cell.link!.approved {
            var action = Action(ActionData(title: "Approved by u/\(cell.link!.approvedBy)", image: UIImage(named: "approve")!.menuIcon()), style: .default, handler: { _ in
            })
            action.enabled = false
            alertController.addAction(action)
        } else {
            alertController.addAction(Action(ActionData(title: "Approve", image: UIImage(named: "approve")!.menuIcon()), style: .default, handler: { _ in
                self.modApprove(cell)
            }))
        }
        
        if cell.link!.removed {
            var action = Action(ActionData(title: "Removed by u/\(cell.link!.removedBy)", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: { _ in
            })
            action.enabled = false
            alertController.addAction(action)
        } else {
            alertController.addAction(Action(ActionData(title: "Remove", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: { _ in
                self.modRemove(cell)
            }))
        }

        alertController.addAction(Action(ActionData(title: "Ban user", image: UIImage(named: "ban")!.menuIcon()), style: .default, handler: { _ in
            //todo show dialog for this
        }))
        
        alertController.addAction(Action(ActionData(title: "Set flair", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { _ in
            cell.flairSelf()
        }))
        
        if !cell.link!.nsfw {
            alertController.addAction(Action(ActionData(title: "Mark as NSFW", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { _ in
                self.modNSFW(cell, true)
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Unmark as NSFW", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { _ in
                self.modNSFW(cell, false)
            }))
        }
        
        if !cell.link!.spoiler {
            alertController.addAction(Action(ActionData(title: "Mark as spoiler", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { _ in
                self.modSpoiler(cell, true)
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Unmark as spoiler", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { _ in
                self.modSpoiler(cell, false)
            }))
        }
        
        if cell.link!.locked {
            alertController.addAction(Action(ActionData(title: "Unlock thread", image: UIImage(named: "lock")!.menuIcon()), style: .default, handler: { _ in
                self.modLock(cell, false)
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Lock thread", image: UIImage(named: "lock")!.menuIcon()), style: .default, handler: { _ in
                self.modLock(cell, true)
            }))
        }
        
        if cell.link!.author == AccountController.currentName {
            alertController.addAction(Action(ActionData(title: "Distinguish", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { _ in
                self.modDistinguish(cell)
            }))
        }
        
        if cell.link!.author == AccountController.currentName {
            if cell.link!.stickied {
                alertController.addAction(Action(ActionData(title: "Un-sticky", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { _ in
                    self.modSticky(cell, sticky: false)
                }))
            } else {
                alertController.addAction(Action(ActionData(title: "Sticky and distinguish", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { _ in
                    self.modSticky(cell, sticky: true)
                }))
            }
        }
        
        alertController.addAction(Action(ActionData(title: "Mark as spam", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { _ in
            self.modRemove(cell, spam: true)
        }))
        
        alertController.addAction(Action(ActionData(title: "User profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { _ in
            let prof = ProfileViewController.init(name: cell.link!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: parent.navigationController, parentViewController: parent)
        }))
        
        VCPresenter.presentAlert(alertController, parentVC: parent)
    }
    
    static func modLock(_ cell: LinkCellView, _ set: Bool) {
        let id = cell.link!.id
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.setLocked(id, locked: set, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Locking submission failed!", color: GMColor.red500Color(), seconds: 3, context: cell.parentViewController)
                    }
                case .success:
                    CachedTitle.approved.append(id)
                    if CachedTitle.removed.contains(id) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Submission locked!", color: ColorUtil.accentColorForSub(sub: cell.link!.subreddit), seconds: 3, context: cell.parentViewController)
                        cell.link!.locked = set
                        cell.refreshLink(cell.link!)
                    }
                }
            })
        } catch {
            print(error)
        }
    }
    
    static func modSpoiler(_ cell: LinkCellView, _ set: Bool) {
        let id = cell.link!.id
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.setSpoiler(id, spoiler: set, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Request failed!", color: GMColor.red500Color(), seconds: 3, context: cell.parentViewController)
                    }
                case .success:
                    CachedTitle.approved.append(id)
                    if CachedTitle.removed.contains(id) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Spoiler tag set!", color: ColorUtil.accentColorForSub(sub: cell.link!.subreddit), seconds: 3, context: cell.parentViewController)
                        cell.link!.spoiler = set
                        cell.refreshLink(cell.link!)
                    }
                }
            })
        } catch {
            print(error)
        }
    }

    static func modNSFW(_ cell: LinkCellView, _ set: Bool) {
        let id = cell.link!.id
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.setNSFW(id, nsfw: set, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Request failed!", color: GMColor.red500Color(), seconds: 3, context: cell.parentViewController)
                    }
                case .success:
                    CachedTitle.approved.append(id)
                    if CachedTitle.removed.contains(id) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "NSFW tag set!", color: ColorUtil.accentColorForSub(sub: cell.link!.subreddit), seconds: 3, context: cell.parentViewController)
                        cell.link!.nsfw = set
                        cell.refreshLink(cell.link!)
                    }
                }
            })
        } catch {
            print(error)
        }
    }
    
    static func modApprove(_ cell: LinkCellView) {
        let id = cell.link!.id
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.approve(id, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Approving submission failed!", color: GMColor.red500Color(), seconds: 3, context: cell.parentViewController)
                    }
                case .success:
                    CachedTitle.approved.append(id)
                    if CachedTitle.removed.contains(id) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        cell.refreshLink(cell.link!)
                        BannerUtil.makeBanner(text: "Submission approved!", color: ColorUtil.accentColorForSub(sub: cell.link!.subreddit), seconds: 3, context: cell.parentViewController)
                    }
                }
            })
        } catch {
            print(error)
        }
    }
    
    static func modDistinguish(_ cell: LinkCellView) {
        let id = cell.link!.id
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.distinguish(id, how: "yes", completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Distinguishing submission failed!", color: GMColor.red500Color(), seconds: 3, context: cell.parentViewController)
                    }
                case .success:
                    DispatchQueue.main.async {
                        cell.link!.distinguished = "mod"
                        cell.refreshLink(cell.link!)
                        BannerUtil.makeBanner(text: "Submission distinguished!", color: ColorUtil.accentColorForSub(sub: cell.link!.subreddit), seconds: 3, context: cell.parentViewController)
                    }
                }
            })
        } catch {
            print(error)
        }
    }
    
    static func modSticky(_ cell: LinkCellView, sticky: Bool) {
        let id = cell.link!.id
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.sticky(id, sticky: sticky, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Couldn't \(sticky ? "" : "un-")sticky submission!", color: GMColor.red500Color(), seconds: 3, context: cell.parentViewController)
                    }
                case .success:
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Submission \(sticky ? "" : "un-")stickied!", color: ColorUtil.accentColorForSub(sub: cell.link!.subreddit), seconds: 3, context: cell.parentViewController)
                        cell.link!.stickied = sticky
                        cell.refreshLink(cell.link!)
                    }
                }
            })
        } catch {
            print(error)
        }
    }
    
    static func modRemove(_ cell: LinkCellView, spam: Bool = false) {
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.ruleList(cell.link!.subreddit, completion: { (result) in
                switch result {
                case .success(let rules):
                    DispatchQueue.main.async {
                        showRemovalReasons(cell, rules: rules, spam: spam)
                    }
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.async {
                        showRemovalReasons(cell, rules: [RuleTemplate](), spam: spam)
                    }
                }
            })
        } catch {
            showRemovalReasons(cell, rules: [RuleTemplate](), spam: spam)
        }
    }
    
    static func showRemovalReasons(_ cell: LinkCellView, rules: [RuleTemplate], spam: Bool = false) {
        var reasons: [String] = ["Custom reason", "Spam", "Removal not spam"]
        for rule in rules {
            reasons.append(rule.violatonReason + "\n" + rule.description)
        }
        let picker = ActionSheetStringPicker(title: "Choose a removal reason", rows: reasons, initialSelection: 0, doneBlock: { (_, index, _) in
            //todo this
            if index == 0 {
                modRemoveReason(cell, reason: "")
            } else if index == 1 {
                removeNoReason(cell)
            } else if index == 2 {
                removeNoReason(cell, spam: true)
            } else {
                modRemoveReason(cell, reason: reasons[index])
            }
        }, cancel: { (_) in
            return
        }, origin: cell.contentView)
        
        let doneButton = UIBarButtonItem.init(title: "Remove", style: .done, target: nil, action: nil)
        picker?.setDoneButton(doneButton)
        picker?.show()

    }
    
    static func removeNoReason(_ cell: LinkCellView, spam: Bool = false) {
        let id = cell.link!.id
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.remove(id, spam: spam, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Removing submission failed!", color: GMColor.red500Color(), seconds: 3, context: cell.parentViewController)
                    }
                case .success:
                    CachedTitle.removed.append(id)
                    if CachedTitle.approved.contains(id) {
                        CachedTitle.approved.remove(at: CachedTitle.approved.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Submission removed!", color: ColorUtil.accentColorForSub(sub: cell.link!.subreddit), seconds: 3, context: cell.parentViewController)
                    }
                }
            })
            
        } catch {
            print(error)
        }
    }
    
    static func modRemoveReason(_ cell: LinkCellView, reason: String) {
        let id = cell.link!.id
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.remove(id, spam: false, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Removing submission failed!", color: GMColor.red500Color(), seconds: 3, context: cell.parentViewController)
                    }
                case .success:
                    CachedTitle.removed.append(id)
                    if CachedTitle.approved.contains(id) {
                        CachedTitle.approved.remove(at: CachedTitle.approved.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Submission removed!", color: ColorUtil.accentColorForSub(sub: cell.link!.subreddit), seconds: 3, context: cell.parentViewController)
                        VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(submission: cell.link!, sub: cell.link!.subreddit, modMessage: reason, completion: { (link) in
                            if link != nil {
                                BannerUtil.makeBanner(text: "Removal reason posted!", color: ColorUtil.accentColorForSub(sub: cell.link!.subreddit), seconds: 3, context: cell.parentViewController)
                            } else {
                                BannerUtil.makeBanner(text: "Removal reason not posted!", color: GMColor.red500Color(), seconds: 3, context: cell.parentViewController)
                            }
                        })), parentVC: cell.parentViewController!)
                    }
                }
            })
            
        } catch {
            print(error)
        }
    }
    
    static func modBan(_ cell: LinkCellView, why: String, duration: Int?) {
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.ban(cell.link!.author, banReason: why, duration: duration == nil ? 999 /*forever*/ : duration!, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Banning user failed!", color: GMColor.red500Color(), seconds: 3, context: cell.parentViewController)
                    }
                case .success:
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "u/\(cell.link!.author) banned!", color: ColorUtil.accentColorForSub(sub: cell.link!.subreddit), seconds: 3, context: cell.parentViewController)
                    }
                }
            })
        } catch {
            print(error)
        }
    }
    
    static var subText: String?
    static var titleText: String?
    
    static func crosspost(_ thing: RSubmission, _ parent: UIViewController, _ title: String? = nil, _ subreddit: String? = nil, _ error: String? = "") {
        
        let alert = UIAlertController.init(style: .actionSheet)
        
        let configS: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = "Subreddit"
            textField.left(image: UIImage.init(named: "subs"), color: .black)
            textField.leftViewPadding = 12
            textField.borderWidth = 1
            textField.cornerRadius = 8
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = .white
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.leftViewPadding = 16
            textField.returnKeyType = .done
            if subreddit != nil {
                textField.text = subreddit
            }
            textField.action { textField in
                self.subText = textField.text
            }
        }
        
        let configT: TextField.Config = { textField in
            textField.textColor = .black
            textField.placeholder = "Enter a new title"
            textField.left(image: UIImage.init(named: "size"), color: .black)
            textField.leftViewPadding = 16
            textField.borderWidth = 0
            textField.cornerRadius = 0
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = .white
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.text = thing.title
            textField.clearButtonMode = .whileEditing
            if title != nil {
                textField.text = title
            }
            textField.action { textField in
                self.titleText = textField.text
            }
        }
        
        alert.addTwoTextFields(textFieldOne: configS, textFieldTwo: configT)
        
        alert.addAction(UIAlertAction(title: "Crosspost", style: .default, handler: { [weak alert] (_) in
            let subField = self.subText ?? ""
            let titleField = self.titleText ?? ""
            
            if subField.isEmpty || titleField.isEmpty {
                if subField.isEmpty {
                    self.crosspost(thing, parent, titleField, subField, "Subreddit must not be empty!")
                } else {
                    self.crosspost(thing, parent, titleField, subField, "Title must not be empty!")
                }
            } else {
                do {
                    try (UIApplication.shared.delegate as! AppDelegate).session?.crosspost(Link.init(id: thing.id), subreddit: subField, newTitle: titleField) { result in
                        switch result {
                        case .failure(let error):
                            print(error)
                            DispatchQueue.main.async {
                                self.crosspost(thing, parent, titleField, subField, error.localizedDescription)
                            }
                        case .success(let submission):
                            if let error = self.getError(submission) {
                                DispatchQueue.main.async {
                                    self.crosspost(thing, parent, titleField, subField, error)
                                }
                            } else {
                                let string = self.getIDString(submission).value!
                                print("Got \(string)")
                                DispatchQueue.main.async {
                                    alert?.dismiss(animated: true)
                                    VCPresenter.openRedditLink("https://redd.it/\(string)", parent.navigationController, parent)
                                }
                            }
                            
                        }
                    }
                    
                } catch {
                    
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        parent.present(alert, animated: true, completion: nil)
    }
    
    static var reportText: String?
    
    static func report(_ thing: Object, parent: UIViewController, index: Int, delegate: SubmissionMoreDelegate?) {
        let alert = UIAlertController(title: "Report this content", message: "", preferredStyle: .alert)
        
        if !AccountController.isLoggedIn {
            alert.addAction(UIAlertAction(title: "Log in to report this content", style: .default, handler: { (_) in
                MainViewController.doAddAccount(register: false)
            }))
            alert.addAction(UIAlertAction(title: "Create a Reddit account", style: .default, handler: { (_) in
                let alert = UIAlertController(title: "Create a new Reddit account", message: "After finishing the process on the next screen, click the 'back' arrow to finish setting up your account!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { (_) in
                    MainViewController.doAddAccount(register: true)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    
                }))
                VCPresenter.presentAlert(alert, parentVC: parent)
            }))
            alert.addAction(UIAlertAction(title: "Remove post (log in later)", style: .default, handler: { (_) in
                DispatchQueue.main.async {
                    delegate?.hide(index: index)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            }))
            VCPresenter.presentAlert(alert, parentVC: parent)
        } else {
            let config: TextField.Config = { textField in
                textField.becomeFirstResponder()
                textField.textColor = .black
                textField.placeholder = "Reason (optional)"
                textField.left(image: UIImage.init(named: "flag"), color: .black)
                textField.leftViewPadding = 12
                textField.borderWidth = 1
                textField.cornerRadius = 8
                textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
                textField.backgroundColor = .white
                textField.keyboardAppearance = .default
                textField.keyboardType = .default
                textField.returnKeyType = .done
                textField.action { textField in
                    self.reportText = textField.text
                }
            }
            
            alert.addOneTextField(configuration: config)
            
            alert.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { (_) in
                let text = self.reportText ?? ""
                do {
                    let name = (thing is RComment) ? (thing as! RComment).id : (thing as! RSubmission).id
                    try (UIApplication.shared.delegate as! AppDelegate).session?.report(name, reason: text, otherReason: "", completion: { (_) in
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Report sent!", color: GMColor.green500Color(), seconds: 3, context: parent)
                            delegate?.hide(index: index)
                        }
                    })
                    
                } catch {
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Error sending report, try again later", color: GMColor.red500Color(), seconds: 3, context: parent)
                    }
                }
            }))
            
            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            
            VCPresenter.presentAlert(alert, parentVC: parent)

        }
    }
    
    static func block(_ username: String, parent: UIViewController, callback: @escaping () -> Void) {
        let alert = UIAlertController(title: "Really block u/\(username)?", message: "", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
            PostFilter.profiles.append(username as NSString)
            PostFilter.saveAndUpdate()
            callback()
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            
        VCPresenter.presentAlert(alert, parentVC: parent)
    }

    
    static func getIDString(_ json: JSONAny) -> reddift.Result<String> {
        if let json = json as? JSONDictionary {
            if let j = json["json"] as? JSONDictionary {
                if let data = j["data"] as? JSONDictionary {
                    if let iden = data["id"] as? String {
                        return Result(value: iden)
                    }
                }
            }
        }
        return Result(error: ReddiftError.identifierOfCAPTCHAIsMalformed as NSError)
    }
    
    static func getError(_ json: JSONAny) -> String? {
        if let json = json as? JSONDictionary, let j = json["json"] as? JSONDictionary, let errors = j["errors"] as? JSONArray {
            // Error happened.
            for obj in errors {
                if let errorStrings = obj as? [String] {
                    print(errorStrings)
                    return errorStrings[1]
                }
            }
        }
        return nil
    }
}
