//
//  MoreMenu.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import XLActionController
import RLBAlertsPickers
import reddift
import RealmSwift
import MaterialComponents.MaterialSnackbar

protocol SubmissionMoreDelegate: class {
    func save(_ cell: LinkCellView)
    func hide(_ cell: LinkCellView)
    func showFilterMenu(_ cell: LinkCellView)
}

class PostActions : NSObject {
    public static func showMoreMenu(cell: LinkCellView, parent: UIViewController, nav: UINavigationController, mutableList: Bool, delegate: SubmissionMoreDelegate){
        let link = cell.link!
        
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Post by \(AccountController.formatUsername(input: link.author, small: true))"
        
        
        alertController.addAction(Action(ActionData(title: "\(AccountController.formatUsernamePosessive(input: link.author, small: false)) profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { action in
            
            let prof = ProfileViewController.init(name: link.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: nav, parentViewController: parent)
        }))
        alertController.addAction(Action(ActionData(title: "r/\(link.subreddit)", image: UIImage(named: "subs")!.menuIcon()), style: .default, handler: { action in
            
            let sub = SingleSubredditViewController.init(subName: link.subreddit, single: true)
            VCPresenter.showVC(viewController: sub, popupIfPossible: true, parentNavigationController:nav, parentViewController: parent)
            
        }))
        
        if (AccountController.isLoggedIn) {
            alertController.addAction(Action(ActionData(title: "Save", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { action in
                delegate.save(cell)
            }))
            
            alertController.addAction(Action(ActionData(title: "Crosspost", image: UIImage(named: "crosspost")!.menuIcon()), style: .default, handler: { action in
                PostActions.crosspost(cell.link!, parent)
            }))
            
            alertController.addAction(Action(ActionData(title: "Report", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
                PostActions.report(cell.link!, parent: parent)
            }))
        }
        
        alertController.addAction(Action(ActionData(title: "Share content", image: UIImage(named: "share")!.menuIcon()), style: .default, handler: { action in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [link.url!], applicationActivities: nil);
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }))
        alertController.addAction(Action(ActionData(title: "Share comments", image: UIImage(named: "comments")!.menuIcon()), style: .default, handler: { action in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [URL.init(string: "https://reddit.com" + link.permalink)!], applicationActivities: nil);
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }))
        
        let open = OpenInChromeController.init()
        if (open.isChromeInstalled()) {
            
            alertController.addAction(Action(ActionData(title: "Open in Chrome", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { action in
                open.openInChrome(link.url!, callbackURL: nil, createNewTab: true)
            }))
        }
        alertController.addAction(Action(ActionData(title: "Open in Safari", image: UIImage(named: "world")!.menuIcon()), style: .default, handler: { action in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(link.url!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(link.url!)
            }
        }))
        if(link.isSelf){
            alertController.addAction(Action(ActionData(title: "Copy text", image: UIImage(named: "copy")!.menuIcon()), style: .default, handler: { action in
                let alert = UIAlertController.init(title: "Copy text", message: "", preferredStyle: .alert)
                alert.addTextViewer(text: .text(cell.link!.body))
                alert.addAction(UIAlertAction.init(title: "Copy all", style: .default, handler: { (action) in
                    UIPasteboard.general.string = cell.link!.body
                }))
                alert.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: { (action) in
                    
                }))
                let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
                currentViewController.present(alert, animated: true, completion: nil);
            }))
        }
        
        if(mutableList){
            alertController.addAction(Action(ActionData(title: "Filter this content", image: UIImage(named: "filter")!.menuIcon()), style: .default, handler: { action in
                delegate.showFilterMenu(cell)
            }))
            alertController.addAction(Action(ActionData(title: "Hide", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { action in
                delegate.hide(cell)
            }))
        }
        
        VCPresenter.presentAlert(alertController, parentVC: parent)
    }
    
    static func showModMenu(_ cell: LinkCellView, parent: UIViewController){
        //todo remove with reason, new icons
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Submission by u/\(cell.link!.author)"
        
        alertController.addAction(Action(ActionData(title: "\(cell.link!.reports.count) reports", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { action in
            var reports = ""
            for report in cell.link!.reports {
                reports = reports + report + "\n"
            }
            let alert = UIAlertController(title: "Reports",
                                          message: reports,
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let cancelAction = UIAlertAction(title: "OK",
                                             style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            parent.present(alert, animated: true, completion: nil)
            
        }))
        alertController.addAction(Action(ActionData(title: "Approve", image: UIImage(named: "approve")!.menuIcon()), style: .default, handler: { action in
            self.modApprove(cell)
        }))
        
        alertController.addAction(Action(ActionData(title: "Ban user", image: UIImage(named: "ban")!.menuIcon()), style: .default, handler: { action in
            //todo show dialog for this
        }))
        
        alertController.addAction(Action(ActionData(title: "Set flair", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
            cell.flairSelf()
        }))
        
        if(!cell.link!.nsfw){
            alertController.addAction(Action(ActionData(title: "Mark as NSFW", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { action in
                self.modNSFW(cell, true)
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Unmark as NSFW", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { action in
                self.modNSFW(cell, false)
            }))
        }
        
        if(!cell.link!.spoiler){
            alertController.addAction(Action(ActionData(title: "Mark as spoiler", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { action in
                self.modSpoiler(cell, true)
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Unmark as spoiler", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { action in
                self.modSpoiler(cell, false)
            }))
        }
        
        if(cell.link!.locked){
            alertController.addAction(Action(ActionData(title: "Unlock thread", image: UIImage(named: "lock")!.menuIcon()), style: .default, handler: { action in
                self.modLock(cell, false)
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Lock thread", image: UIImage(named: "lock")!.menuIcon()), style: .default, handler: { action in
                self.modLock(cell, true)
            }))
        }
        
        if (cell.link!.author == AccountController.currentName) {
            alertController.addAction(Action(ActionData(title: "Distinguish", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { action in
                self.modDistinguish(cell)
            }))
        }
        
        if (cell.link!.author == AccountController.currentName) {
            if (cell.link!.stickied) {
                alertController.addAction(Action(ActionData(title: "Un-sticky", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
                    self.modSticky(cell, sticky: false)
                }))
            } else {
                alertController.addAction(Action(ActionData(title: "Sticky and distinguish", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
                    self.modSticky(cell, sticky: true)
                }))
            }
        }
        
        alertController.addAction(Action(ActionData(title: "Remove", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: { action in
            self.modRemove(cell)
        }))
        
        alertController.addAction(Action(ActionData(title: "Remove with reason", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: { action in
            self.modRemove(cell)
            //todo this
        }))
        
        alertController.addAction(Action(ActionData(title: "Mark as spam", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
            self.modRemove(cell, spam: true)
        }))
        
        alertController.addAction(Action(ActionData(title: "User profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { action in
            let prof = ProfileViewController.init(name: cell.link!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: parent.navigationController, parentViewController: parent);
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
                        let message = MDCSnackbarMessage()
                        message.text = "Locking submission failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    CachedTitle.approved.append(id)
                    if (CachedTitle.removed.contains(id)) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Submission locked!"
                        MDCSnackbarManager.show(message)
                        cell.link!.locked = set
                        cell.refreshLink(cell.link!)
                    }
                    break
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
                        let message = MDCSnackbarMessage()
                        message.text = "Request failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    CachedTitle.approved.append(id)
                    if (CachedTitle.removed.contains(id)) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Spoiler tag set!"
                        cell.link!.spoiler = set
                        cell.refreshLink(cell.link!)
                        MDCSnackbarManager.show(message)
                    }
                    break
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
                        let message = MDCSnackbarMessage()
                        message.text = "Request failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    CachedTitle.approved.append(id)
                    if (CachedTitle.removed.contains(id)) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "NSFW tag set!"
                        cell.link!.nsfw = set
                        cell.refreshLink(cell.link!)
                        MDCSnackbarManager.show(message)
                    }
                    break
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
                        let message = MDCSnackbarMessage()
                        message.text = "Approving submission failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    CachedTitle.approved.append(id)
                    if (CachedTitle.removed.contains(id)) {
                        CachedTitle.removed.remove(at: CachedTitle.removed.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Submission approved!"
                        cell.refreshLink(cell.link!)
                        MDCSnackbarManager.show(message)
                    }
                    break
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
                        let message = MDCSnackbarMessage()
                        message.text = "Distinguishing submission failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Submission distinguished!"
                        cell.link!.distinguished = "mod"
                        cell.refreshLink(cell.link!)
                        MDCSnackbarManager.show(message)
                    }
                    break
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
                        let message = MDCSnackbarMessage()
                        message.text = "Couldn't \(sticky ? "" : "un-")sticky submission!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Submission \(sticky ? "" : "un-")stickied!"
                        cell.link!.stickied = sticky
                        cell.refreshLink(cell.link!)
                        MDCSnackbarManager.show(message)
                    }
                    break
                }
            })
        } catch {
            print(error)
        }
    }
    
    static func modRemove(_ cell: LinkCellView, spam: Bool = false) {
        let id = cell.link!.id
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.remove(id, spam: spam, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Removing submission failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    CachedTitle.removed.append(id)
                    if (CachedTitle.approved.contains(id)) {
                        CachedTitle.approved.remove(at: CachedTitle.approved.index(of: id)!)
                    }
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Submission removed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                }
            })
            
        } catch {
            print(error)
        }
    }
    
    static func modBan(_ cell: LinkCellView, why: String, duration: Int?) {
        let id = cell.link!.id
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.ban(cell.link!.author, banReason: why, duration: duration == nil ? 999 /*forever*/ : duration!, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Banning user failed!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(_):
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "u/\(cell.link!.author) banned!"
                        MDCSnackbarManager.show(message)
                    }
                    break
                }
            })
        } catch {
            print(error)
        }
    }
    
    
    static var subText : String?
    static var titleText : String?
    
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
            if(subreddit != nil){
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
            if(title != nil){
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
            
            if (subField.isEmpty || titleField.isEmpty) {
                if (subField.isEmpty) {
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
                            break
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
    
    static var reportText : String?
    
    static func report(_ thing: Object, parent: UIViewController) {
        let alert = UIAlertController(title: "Report this content", message: "", preferredStyle: .alert)
        
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
        
        alert.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { [weak alert] (_) in
            let text = self.reportText ?? ""
            do {
                let name = (thing is RComment) ? (thing as! RComment).id : (thing as! RSubmission).id
                try (UIApplication.shared.delegate as! AppDelegate).session?.report(name, reason: text, otherReason: "", completion: { (result) in
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Report sent"
                        MDCSnackbarManager.show(message)
                    }
                })
            } catch {
                DispatchQueue.main.async {
                    let message = MDCSnackbarMessage()
                    message.text = "Error sending report. Try again later"
                    MDCSnackbarManager.show(message)
                }
            }
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
