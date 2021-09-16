//
//  MoreMenu.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import CoreData
import reddift
import RLBAlertsPickers
import SDCAlertView
import UIKit

protocol SubmissionMoreDelegate: class {
    func save(_ cell: LinkCellView)
    func hide(_ cell: LinkCellView)
    func showFilterMenu(_ cell: LinkCellView)
    func applyFilters()
    func hide(index: Int)
    func subscribe(link: SubmissionObject)
}

class PostActions: NSObject {
    
    public static func showPostMenu(_ parent: UIViewController, sub: String) {
        let alertController = DragDownAlertMenu(title: "New submission", subtitle: "in r/" + sub, icon: nil)
        
        alertController.addAction(title: "Image", icon: UIImage(sfString: SFSymbol.cameraFill, overrideString: "camera")!.menuIcon()) {
            VCPresenter.showVC(viewController: ReplyViewController.init(subreddit: sub, type: ReplyViewController.ReplyType.SUBMIT_IMAGE, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: parent.navigationController, parentViewController: parent)
            }), popupIfPossible: true, parentNavigationController: nil, parentViewController: parent)
        }
        
        alertController.addAction(title: "Link", icon: UIImage(sfString: SFSymbol.link, overrideString: "link")!.menuIcon()) {
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(subreddit: sub, type: ReplyViewController.ReplyType.SUBMIT_LINK, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: parent.navigationController, parentViewController: parent)
            })), parentVC: parent)
        }
        
        alertController.addAction(title: "Selftext", icon: UIImage(sfString: SFSymbol.textbox, overrideString: "size")!.menuIcon()) {
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(subreddit: sub, type: ReplyViewController.ReplyType.SUBMIT_TEXT, completion: { (submission) in
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: parent.navigationController, parentViewController: parent)
            })), parentVC: parent)
        }
        alertController.show(parent)
    }
    
    public static func handleAction(action: SettingValues.PostOverflowAction, cell: LinkCellView, parent: UIViewController, nav: UINavigationController?, mutableList: Bool, delegate: SubmissionMoreDelegate, index: Int) {
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
                if !ReadLater.isReadLater(id: link.id) {
                    ReadLater.addReadLater(id: cell.link!.id, subreddit: cell.link!.subreddit)
                    BannerUtil.makeBanner(text: "Added to Read Later", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController, top: true)
                } else {
                    ReadLater.removeReadLater(id: cell.link!.id)
                    BannerUtil.makeBanner(text: "Removed from Read Later", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController, top: true)
                }
            case .SHARE_CONTENT:
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [SubjectItemSource(subject: link.title.decodeHTML(), url: link.url!)], applicationActivities: nil)
                if let presenter = activityViewController.popoverPresentationController {
                    presenter.sourceView = cell.contentView
                    presenter.sourceRect = cell.contentView.bounds
                }
                parent.present(activityViewController, animated: true, completion: nil)
            case .SUBSCRIBE:
                delegate.subscribe(link: cell.link!)
            case .SHARE_REDDIT:
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [SubjectItemSource(subject: link.title.decodeHTML(), url: URL.init(string: "https://reddit.com" + (link.permalink.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) ?? link.permalink))!)], applicationActivities: nil)
                if let presenter = activityViewController.popoverPresentationController {
                    presenter.sourceView = cell.contentView
                    presenter.sourceRect = cell.contentView.bounds
                }
                
                parent.present(activityViewController, animated: true, completion: nil)
            case .CHROME:
                if link.url != nil {
                    let open = OpenInChromeController.init()
                    open.openInChrome(link.url!, callbackURL: nil, createNewTab: true)
                }
            case .SAFARI:
                if link.url != nil {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(link.url!, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(link.url!)
                    }
                }
            case .FILTER:
                delegate.showFilterMenu(cell)
            case .COPY:
                let alert = AlertController.init(title: "Copy text", message: nil, preferredStyle: .alert)
                
                alert.setupTheme()
                
                alert.attributedTitle = NSAttributedString(string: "Copy text", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
                
                let text = UITextView().then {
                    $0.font = FontGenerator.fontOfSize(size: 14, submission: false)
                    $0.textColor = UIColor.fontColor
                    $0.backgroundColor = .clear
                    $0.isEditable = false
                    $0.text = cell.link?.markdownBody?.decodeHTML() ?? ""
                }
                
                alert.contentView.addSubview(text)
                text.edgeAnchors /==/ alert.contentView.edgeAnchors
                
                let height = text.sizeThatFits(CGSize(width: 238, height: CGFloat.greatestFiniteMagnitude)).height
                text.heightAnchor /==/ height
                
                alert.addCloseButton()
                alert.addAction(AlertAction(title: "Copy all", style: AlertAction.Style.normal, handler: { (_) in
                    UIPasteboard.general.string = cell.link?.markdownBody?.decodeHTML() ?? ""
                }))
                
                alert.addBlurView()
                
                parent.present(alert, animated: true)
            case .COPYTITLE:
                let text = cell.link?.title
                UIPasteboard.general.string = text
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
    
    public static func showMoreMenu(cell: LinkCellView, parent: UIViewController, nav: UINavigationController?, mutableList: Bool, delegate: SubmissionMoreDelegate, index: Int) {
        let link = cell.link!
        
        let alertController: DragDownAlertMenu = DragDownAlertMenu(title: "Submission", subtitle: link.title, icon: link.isNSFW ? "" : link.thumbnailUrl)
        
        for item in SettingValues.PostOverflowAction.getMenu(link, mutableList: mutableList) {
            alertController.addAction(title: item.getTitle(link), icon: item.getImage(link)) {
                handleAction(action: item, cell: cell, parent: parent, nav: nav, mutableList: mutableList, delegate: delegate, index: index)
            }
        }
        alertController.show(parent)
    }
    
    @available(iOS 13.0, *)
    public static func getMoreContextMenu(cell: LinkCellView, parent: UIViewController, nav: UINavigationController?, mutableList: Bool, delegate: SubmissionMoreDelegate, index: Int) -> UIMenu {
        // Create a UIAction for sharing
        var buttons = [UIAction]()
        if let link = cell.link {
            for item in SettingValues.PostOverflowAction.getMenu(link, mutableList: mutableList) {
                buttons.append(UIAction(title: item.getTitle(), image: item.getImage(), handler: { (action) in
                    handleAction(action: item, cell: cell, parent: parent, nav: nav, mutableList: mutableList, delegate: delegate, index: index)
                }))
            }
        }
        // Create and return a UIMenu with the share action
        return UIMenu(title: "Submission Options", children: buttons)
    }
    
    static func showModMenu(_ cell: LinkCellView, parent: UIViewController) {
       // TODO: - remove with reason, new icons
        let alertController = DragDownAlertMenu(title: "Moderation", subtitle: "Submission by u/\(cell.link!.author)", icon: cell.link!.thumbnailUrl, themeColor: GMColor.lightGreen500Color())
        if let reportsDictionary = cell.link?.reportsDictionary {
            alertController.addAction(title: "\(reportsDictionary.keys.count > 0 ? "\(reportsDictionary.keys.count)" : "No") reports", icon: UIImage(sfString: SFSymbol.exclamationmarkCircleFill, overrideString: "reports")!.menuIcon()) {
                var reports = ""
                for reporter in reportsDictionary.keys {
                    reports += "\(reporter): \(reportsDictionary[reporter] as? String ?? "")\n"
                }
                let alert = UIAlertController(title: "Reports",
                                              message: reports,
                                              preferredStyle: UIAlertController.Style.alert)
                
                let cancelAction = UIAlertAction(title: "OK",
                                                 style: .cancel, handler: nil)
                
                alert.addAction(cancelAction)
                parent.present(alert, animated: true, completion: nil)
            }
        }
        
        if cell.link!.isApproved {
            alertController.addAction(title: "Approved by \(cell.link!.approvedBy ?? "unknown")", icon: UIImage(sfString: SFSymbol.handThumbsupFill, overrideString: "approve")!.menuIcon(), enabled: false) {
            }
        } else {
            alertController.addAction(title: "Approve", icon: UIImage(sfString: SFSymbol.handThumbsupFill, overrideString: "approve")!.menuIcon()) {
                self.modApprove(cell)
            }
        }
        
        if cell.link!.isRemoved {
            alertController.addAction(title: "Removed by \(cell.link!.approvedBy ?? "unknown")", icon: UIImage(sfString: SFSymbol.xmark, overrideString: "close")!.menuIcon(), enabled: false) {
            }
        } else {
            alertController.addAction(title: "Remove", icon: UIImage(sfString: SFSymbol.xmark, overrideString: "close")!.menuIcon()) {
                self.modRemove(cell)
            }
        }

        alertController.addAction(title: "Ban u/\(cell.link!.author)", icon: UIImage(sfString: SFSymbol.hammerFill, overrideString: "ban")!.menuIcon()) {
            self.modBan(cell)
        }

        alertController.addAction(title: "Set flair", icon: UIImage(sfString: SFSymbol.flagFill, overrideString: "flag")!.menuIcon()) {
            cell.flairSelf()
        }

        if !cell.link!.isNSFW {
            alertController.addAction(title: "Mark as NSFW", icon: UIImage(sfString: SFSymbol.xmark, overrideString: "hide")!.menuIcon()) {
                self.modNSFW(cell, true)
            }
        } else {
            alertController.addAction(title: "Unmark as NSFW", icon: UIImage(sfString: SFSymbol.xmark, overrideString: "hide")!.menuIcon()) {
                self.modNSFW(cell, false)
            }
        }
        
        if !cell.link!.isSpoiler {
            alertController.addAction(title: "Mark as spoiler", icon: UIImage(sfString: SFSymbol.exclamationmarkCircleFill, overrideString: "reports")!.menuIcon()) {
                self.modSpoiler(cell, true)
            }
        } else {
            alertController.addAction(title: "Unmark as spoiler", icon: UIImage(sfString: SFSymbol.exclamationmarkCircleFill, overrideString: "reports")!.menuIcon()) {
                self.modSpoiler(cell, false)
            }
        }
        
        if cell.link!.isLocked {
            alertController.addAction(title: "Unlock thread", icon: UIImage(named: "lock")!.menuIcon()) {
                self.modLock(cell, false)
            }
        } else {
            alertController.addAction(title: "Lock thread", icon: UIImage(named: "lock")!.menuIcon()) {
                self.modLock(cell, true)
            }
        }
        
        if cell.link!.author == AccountController.currentName {
            alertController.addAction(title: "Distinguish", icon: UIImage(sfString: SFSymbol.starFill, overrideString: "save")!.menuIcon()) {
                self.modDistinguish(cell)
            }
        }
        
        if cell.link!.isStickied {
            alertController.addAction(title: "Un-sticky post", icon: UIImage(sfString: SFSymbol.pinSlashFill, overrideString: "flag")!.menuIcon()) {
                self.modSticky(cell, sticky: false)
            }
        } else {
            alertController.addAction(title: "Sticky post", icon: UIImage(sfString: SFSymbol.pinFill, overrideString: "flag")!.menuIcon()) {
                self.modSticky(cell, sticky: true)
            }
        }
        
        alertController.addAction(title: "Mark as spam", icon: UIImage(sfString: SFSymbol.exclamationmarkBubbleFill, overrideString: "flag")!.menuIcon()) {
            self.modRemove(cell, spam: true)
        }

        alertController.addAction(title: "u/\(cell.link!.author)'s profile", icon: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon()) {
            let prof = ProfileViewController.init(name: cell.link!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: parent.navigationController, parentViewController: parent)
        }
        
        alertController.show(parent)
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
                        CachedTitle.removed.remove(at: CachedTitle.removed.firstIndex(of: id)!)
                    }
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Submission \(!set ? "un" : "")locked!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
                        cell.link!.isLocked = set
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
                        CachedTitle.removed.remove(at: CachedTitle.removed.firstIndex(of: id)!)
                    }
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Spoiler tag set!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
                        cell.link!.isSpoiler = set
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
                        CachedTitle.removed.remove(at: CachedTitle.removed.firstIndex(of: id)!)
                    }
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "NSFW tag set!", color: GMColor.green500Color(), seconds: 3, context: cell.parentViewController)
                        cell.link!.isNSFW = set
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
                        CachedTitle.removed.remove(at: CachedTitle.removed.firstIndex(of: id)!)
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
                        cell.link!.isStickied = sticky
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
    
    static func modBan(_ cell: LinkCellView, spam: Bool = false) {
       /* do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.ban(cell.link!.subreddit, completion: { (result) in
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
        }*/
    }

    static func showRemovalReasons(_ cell: LinkCellView, rules: [RuleTemplate], spam: Bool = false) {
        var reasons: [String] = ["Custom reason", "Spam", "Removal not spam"]
        for rule in rules {
            reasons.append(rule.violatonReason + "\n" + rule.description)
        }
        let sheet = DragDownAlertMenu(title: "Remove post", subtitle: "Choose a removal reason", icon: nil, themeColor: GMColor.lightGreen500Color(), full: true)
        
        for reason in reasons {
            sheet.addAction(title: reason, icon: nil) {
                let index = reasons.firstIndex(of: reason) ?? 0
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
        }
        
        sheet.show(cell.parentViewController)
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
                        CachedTitle.approved.remove(at: CachedTitle.approved.firstIndex(of: id)!)
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
                        CachedTitle.approved.remove(at: CachedTitle.approved.firstIndex(of: id)!)
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
    
    static func crosspost(_ thing: SubmissionObject, _ parent: UIViewController, _ title: String? = nil, _ subreddit: String? = nil, _ error: String? = "") {
        VCPresenter.showVC(viewController: ReplyViewController.init(submission: thing, completion: { (submission) in
            VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: submission!.permalink)!), popupIfPossible: true, parentNavigationController: parent.navigationController, parentViewController: parent)
        }), popupIfPossible: true, parentNavigationController: nil, parentViewController: parent)
    }
    
    static var reportText: String?
    
    static func report(_ thing: RedditObject, parent: UIViewController, index: Int, delegate: SubmissionMoreDelegate?) {
        let alert = AlertController(title: "Report this content", message: "", preferredStyle: .alert)
        
        if !AccountController.isLoggedIn {
            alert.addAction(AlertAction(title: "Log in to report this content", style: .normal, handler: { (_) in
                // TODO how to do this now MainViewController.doAddAccount(register: false)
            }))
            alert.addAction(AlertAction(title: "Create a Reddit account", style: .normal, handler: { (_) in
                let alert = UIAlertController(title: "Create a new Reddit account", message: "After finishing the process on the next screen, click the 'back' arrow to finish setting up your account!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { (_) in
                    // TODO how to do this now MainViewController.doAddAccount(register: true)
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
                textField.textColor = UIColor.fontColor
                textField.attributedPlaceholder = NSAttributedString(string: "Reason (optional)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor.withAlphaComponent(0.3)])
                textField.left(image: UIImage(sfString: SFSymbol.exclamationmarkBubbleFill, overrideString: "flag")?.menuIcon(), color: UIColor.fontColor)
                textField.layer.borderColor = UIColor.fontColor.withAlphaComponent(0.3) .cgColor
                textField.backgroundColor = UIColor.foregroundColor
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
            
            alert.attributedTitle = NSAttributedString(string: "Report this content", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
            
            alert.contentView.addSubview(textField)
            
            textField.edgeAnchors /==/ alert.contentView.edgeAnchors
            textField.heightAnchor /==/ CGFloat(44 + 12)
            
            alert.addAction(AlertAction(title: "Report", style: .destructive, handler: { (_) in
                let text = self.reportText ?? ""
                do {
                    let name = (thing is CommentObject) ? (thing as! CommentObject).id : (thing as! SubmissionObject).id
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
            BannerUtil.makeBanner(text: "User blocked", color: GMColor.red500Color(), seconds: 3, context: parent, top: true, callback: nil)
            if AccountController.isLoggedIn {
                do {
                    try (UIApplication.shared.delegate as! AppDelegate).session?.getUserProfile(username, completion: { (result) in
                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(let account):
                                DispatchQueue.main.async {
                                    do {
                                        try (UIApplication.shared.delegate as! AppDelegate).session?.blockViaId(account.id, completion: { (result) in
                                            print(result)
                                        })
                                    } catch {
                                        print(error)
                                    }
                                }
                        }
                    })
                } catch {
                    print(error)
                }
            }
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
