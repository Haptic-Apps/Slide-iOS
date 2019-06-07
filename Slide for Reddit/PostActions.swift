//
//  MoreMenu.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import RealmSwift
import reddift
import RLBAlertsPickers
import UIKit
import SDCAlertView
import XLActionController

protocol SubmissionMoreDelegate: class {
    func save(_ cell: LinkCellView)
    func hide(_ cell: LinkCellView)
    func showFilterMenu(_ cell: LinkCellView)
    func applyFilters()
    func hide(index: Int)
    func subscribe(link: RSubmission)
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
    
    public static func handleAction(action: SettingValues.PostOverflowAction, cell: LinkCellView, parent: UIViewController, nav: UINavigationController, mutableList: Bool, delegate: SubmissionMoreDelegate, index: Int) {
        let link = cell.link!
        switch action {
        case .PROFILE:
            let prof = ProfileViewController.init(name: link.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: nav, parentViewController: parent)
        case .SUBREDDIT:
            let sub = SingleSubredditViewController.init(subName: link.subreddit, single: true)
            VCPresenter.showVC(viewController: sub, popupIfPossible: true, parentNavigationController: nav, parentViewController: parent)
        case .REPORT:
            PostActions.report(cell.link!, parent: parent, index: index, delegate: delegate)
        case .BLOCK:
            PostActions.block(cell.link!.author, parent: parent) { () in
                delegate.applyFilters()
            }
        case .SAVE:
            delegate.save(cell)
        case .CROSSPOST:
            PostActions.crosspost(cell.link!, parent)
        case .READ_LATER:
            if !ReadLater.isReadLater(id: link.getIdentifier()) {
                ReadLater.addReadLater(id: cell.link!.getIdentifier(), subreddit: cell.link!.subreddit)
                BannerUtil.makeBanner(text: "Added to Read Later", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController, top: true)
            } else {
                ReadLater.removeReadLater(id: cell.link!.getIdentifier())
                BannerUtil.makeBanner(text: "Removed from Read Later", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController, top: true)
            }
        case .SHARE_CONTENT:
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [SubjectItemSource(subject: link.title.decodeHTML(), url: link.url!)], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = cell.contentView
                presenter.sourceRect = cell.contentView.bounds
            }
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil)
        case .SUBSCRIBE:
            delegate.subscribe(link: cell.link!)
        case .SHARE_REDDIT:
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [SubjectItemSource(subject: link.title.decodeHTML(), url: URL.init(string: "https://reddit.com" + link.permalink)!)], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = cell.contentView
                presenter.sourceRect = cell.contentView.bounds
            }
            
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil)
        case .CHROME:
            let open = OpenInChromeController.init()
            open.openInChrome(link.url!, callbackURL: nil, createNewTab: true)
        case .SAFARI:
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(link.url!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(link.url!)
            }
        case .FILTER:
            delegate.showFilterMenu(cell)
        case .COPY:
            let alert = AlertController.init(title: "Copy text", message: nil, preferredStyle: .alert)
            
            alert.setupTheme()
            
            alert.attributedTitle = NSAttributedString(string: "Copy text", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
            
            let text = UITextView().then {
                $0.font = FontGenerator.fontOfSize(size: 14, submission: false)
                $0.textColor = ColorUtil.theme.fontColor
                $0.backgroundColor = .clear
                $0.isEditable = false
                $0.text = cell.link!.body.decodeHTML()
            }
            
            alert.contentView.addSubview(text)
            text.edgeAnchors == alert.contentView.edgeAnchors
            
            let height = text.sizeThatFits(CGSize(width: 238, height: CGFloat.greatestFiniteMagnitude)).height
            text.heightAnchor == height
            
            alert.addCloseButton()
            alert.addAction(AlertAction(title: "Copy all", style: AlertAction.Style.normal, handler: { (_) in
                UIPasteboard.general.string = cell.link!.body.decodeHTML()
            }))
            
            alert.addBlurView()
            
            parent.present(alert, animated: true)
        case .HIDE:
            delegate.hide(cell)
        case .UPVOTE:
            cell.upvote()
        case .DOWNVOTE:
            cell.downvote()
        case .MODERATE:
            PostActions.showModMenu(cell, parent: parent)
        }
    }
    
    public static func showMoreMenu(cell: LinkCellView, parent: UIViewController, nav: UINavigationController, mutableList: Bool, delegate: SubmissionMoreDelegate, index: Int) {
        let link = cell.link!
        
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Submission by \(AccountController.formatUsername(input: link.author, small: true))"
        
        for item in SettingValues.PostOverflowAction.getMenu(link, mutableList: mutableList) {
            alertController.addAction(Action(ActionData(title: item.getTitle(link), image: item.getImage(link)), style: .default, handler: { _ in
                handleAction(action: item, cell: cell, parent: parent, nav: nav, mutableList: mutableList, delegate: delegate, index: index)
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
                                          preferredStyle: UIAlertController.Style.alert)
            
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
        
        if cell.link!.stickied {
            alertController.addAction(Action(ActionData(title: "Un-sticky", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { _ in
                self.modSticky(cell, sticky: false)
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Sticky and distinguish", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { _ in
                self.modSticky(cell, sticky: true)
            }))
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
                        BannerUtil.makeBanner(text: "Submission \(!set ? "un" : "")locked!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
                        cell.link!.locked = set
                        cell.refreshLink(cell.link!, np: false)
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
                        BannerUtil.makeBanner(text: "Spoiler tag set!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
                        cell.link!.spoiler = set
                        cell.refreshLink(cell.link!, np: false)
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
                        BannerUtil.makeBanner(text: "NSFW tag set!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
                        cell.link!.nsfw = set
                        cell.refreshLink(cell.link!, np: false)
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
                        cell.refreshLink(cell.link!, np: false)
                        BannerUtil.makeBanner(text: "Submission approved!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
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
                        cell.refreshLink(cell.link!, np: false)
                        BannerUtil.makeBanner(text: "Submission distinguished!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
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
                        BannerUtil.makeBanner(text: "Submission \(sticky ? "" : "un-")stickied!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
                        cell.link!.stickied = sticky
                        cell.refreshLink(cell.link!, np: false)
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
        let sheet = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        sheet.setupTheme()
        sheet.attributedTitle = NSAttributedString(string: "Choose a removal reason", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        for reason in reasons {
            let somethingAction = AlertAction(title: reason, style: .normal) { (_) in
                var index = reasons.index(of: reason) ?? 0
                if index == 0 {
                    modRemoveReason(cell, reason: "")
                } else if index == 1 {
                    removeNoReason(cell)
                } else if index == 2 {
                    removeNoReason(cell, spam: true)
                } else {
                    modRemoveReason(cell, reason: reasons[index])
                }
            }
            
            sheet.addAction(somethingAction)
        }
        sheet.addCloseButton()
        sheet.addBlurView()
        cell.parentViewController?.present(sheet, animated: true)
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
                        BannerUtil.makeBanner(text: "Submission removed!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
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
                        BannerUtil.makeBanner(text: "Submission removed!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
                        VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(submission: cell.link!, sub: cell.link!.subreddit, modMessage: reason, completion: { (link) in
                            if link != nil {
                                BannerUtil.makeBanner(text: "Removal reason posted!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
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
        VCPresenter.showVC(viewController: ReplyViewController.init(submission: thing, completion: { (submission) in
            VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: parent.navigationController, parentViewController: parent)
        }), popupIfPossible: true, parentNavigationController: nil, parentViewController: parent)
    }
    
    static var reportText: String?
    
    static func report(_ thing: Object, parent: UIViewController, index: Int, delegate: SubmissionMoreDelegate?) {
        let alert = AlertController(title: "Report this content", message: "", preferredStyle: .alert)
        
        if !AccountController.isLoggedIn {
            alert.addAction(AlertAction(title: "Log in to report this content", style: .normal, handler: { (_) in
                MainViewController.doAddAccount(register: false)
            }))
            alert.addAction(AlertAction(title: "Create a Reddit account", style: .normal, handler: { (_) in
                let alert = UIAlertController(title: "Create a new Reddit account", message: "After finishing the process on the next screen, click the 'back' arrow to finish setting up your account!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { (_) in
                    MainViewController.doAddAccount(register: true)
                }))
                alert.addCancelButton()
                VCPresenter.presentAlert(alert, parentVC: parent)
            }))
            alert.addAction(AlertAction(title: "Remove post (log in later)", style: .normal, handler: { (_) in
                DispatchQueue.main.async {
                    delegate?.hide(index: index)
                }
            }))
            alert.addCancelButton()
            VCPresenter.presentAlert(alert, parentVC: parent)
        } else {
            let config: TextField.Config = { textField in
                textField.becomeFirstResponder()
                textField.textColor = ColorUtil.theme.fontColor
                textField.attributedPlaceholder = NSAttributedString(string: "Reason (optional)", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor.withAlphaComponent(0.3)])
                textField.left(image: UIImage.init(named: "flag"), color: ColorUtil.theme.fontColor)
                textField.layer.borderColor = ColorUtil.theme.fontColor.withAlphaComponent(0.3) .cgColor
                textField.backgroundColor = ColorUtil.theme.foregroundColor
                textField.leftViewPadding = 12
                textField.layer.borderWidth = 1
                textField.layer.cornerRadius = 8
                textField.keyboardAppearance = .default
                textField.keyboardType = .default
                textField.returnKeyType = .done
                textField.action { textField in
                    self.reportText = textField.text
                }
            }
            
            let textField = OneTextFieldViewController(vInset: 12, configuration: config).view!
            
            alert.setupTheme()
            
            alert.attributedTitle = NSAttributedString(string: "Report this content", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
            
            alert.contentView.addSubview(textField)
            
            textField.edgeAnchors == alert.contentView.edgeAnchors
            textField.heightAnchor == CGFloat(44 + 12)
            
            alert.addAction(AlertAction(title: "Report", style: .destructive, handler: { (_) in
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
            
            alert.addCancelButton()
            alert.addBlurView()
            
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
        alert.addCancelButton()
            
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

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}

class SubjectItemSource: NSObject, UIActivityItemSource {
    var subject: String
    var content: URL
    init(subject: String, url: URL) {
        self.subject = subject
        self.content = url
        super.init()
    }
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return content
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return content
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return subject
    }
}
