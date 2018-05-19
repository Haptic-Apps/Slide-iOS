//
//  UZTextViewCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/6/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class NavigationHeaderView: UIView {
    var title = UILabel()
    var inbox = UILabel()

    var profile: UITableViewCell = UITableViewCell()
    var inboxBody = UITableViewCell()

    var account = UIButton()
    var settings = UIButton()

    var search: UISearchBar = UISearchBar()

    func doColors(_ sub: String){
        title.backgroundColor = ColorUtil.getColorForSub(sub: sub)
    }
    func doColors() {
        var titleFont = UIFont.systemFont(ofSize: 15)
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        title.textColor = .white

        if (AccountController.isLoggedIn) {
            var titleT = NSMutableAttributedString.init(string: "Hello\n", attributes: [NSFontAttributeName: titleFont])
            titleFont = UIFont.systemFont(ofSize: 20)
            titleT.append(NSMutableAttributedString.init(string: AccountController.currentName, attributes: [NSFontAttributeName: titleFont.bold()]))
            title.attributedText = titleT
            inbox.isHidden = false
        } else {
            inbox.isHidden = true
            var titleT = NSMutableAttributedString.init(string: "Guest\n", attributes: [NSFontAttributeName: titleFont])
            titleFont = UIFont.systemFont(ofSize: 20)
            titleT.append(NSMutableAttributedString.init(string: "Tap to sign in", attributes: [NSFontAttributeName: titleFont.bold()]))
            title.attributedText = titleT
        }

        title.textAlignment = .center
        title.backgroundColor = ColorUtil.getColorForSub(sub: "")
        backgroundColor = ColorUtil.foregroundColor
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.search = UISearchBar(frame: CGRect(x: 0, y: 0, width: 3, height: 50))
        self.inbox = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 60))
        self.inbox.clipsToBounds = true

        self.profile.textLabel?.text = "Go to a profile"
        self.profile.accessoryType = .none
        self.profile.backgroundColor = ColorUtil.foregroundColor
        self.profile.textLabel?.textColor = ColorUtil.fontColor
        self.profile.imageView?.image = UIImage.init(named: "user")?.menuIcon().withRenderingMode(.alwaysTemplate)

        self.account = UIButton.init(type: .custom)
        account.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        account.setImage(UIImage.init(named: "profile")!.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: UIControlState.normal)
        account.addTarget(self, action: #selector(self.switchAccounts(_:)), for: UIControlEvents.touchUpInside)
        account.frame = CGRect.init(x: 0, y: 0, width: 40, height: 40)

        self.settings = UIButton.init(type: .custom)
        settings.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        settings.setImage(UIImage.init(named: "settings")!.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: UIControlState.normal)
        settings.addTarget(self, action: #selector(self.settings(_:)), for: UIControlEvents.touchUpInside)
        settings.frame = CGRect.init(x: 0, y: 0, width: 40, height: 40)

        self.inboxBody.textLabel?.text = "Inbox"
        self.inboxBody.accessoryView = inbox
        self.inboxBody.backgroundColor = ColorUtil.foregroundColor
        self.inboxBody.textLabel?.textColor = ColorUtil.fontColor
        self.inboxBody.imageView?.image = UIImage.init(named: "inbox")?.menuIcon().withRenderingMode(.alwaysTemplate)

        search.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        profile.translatesAutoresizingMaskIntoConstraints = false
        account.translatesAutoresizingMaskIntoConstraints = false
        settings.translatesAutoresizingMaskIntoConstraints = false
        inboxBody.translatesAutoresizingMaskIntoConstraints = false

        profile.tintColor = ColorUtil.fontColor
        inboxBody.tintColor = ColorUtil.fontColor

        inbox.textColor = .white
        inbox.font = UIFont.boldSystemFont(ofSize: 16)
        inbox.backgroundColor = GMColor.red300Color()
        inbox.layer.cornerRadius = 10
        inbox.layer.masksToBounds = true
        inbox.textAlignment = .center

        let pTap = UITapGestureRecognizer(target: self, action: #selector(self.showProfileDialog(_:)))
        profile.addGestureRecognizer(pTap)
        profile.isUserInteractionEnabled = true

        if (AccountController.isLoggedIn) {
            let yTap = UITapGestureRecognizer(target: self, action: #selector(self.you(_:)))
            title.addGestureRecognizer(yTap)
        } else {
            let yTap = UITapGestureRecognizer(target: self, action: #selector(self.switchAccounts(_:)))
            title.addGestureRecognizer(yTap)
        }
        title.isUserInteractionEnabled = true

        let iTap = UITapGestureRecognizer(target: self, action: #selector(self.inbox(_:)))
        inboxBody.addGestureRecognizer(iTap)
        inboxBody.isUserInteractionEnabled = true

        addSubview(inboxBody)
        addSubview(search)
        addSubview(title)
        addSubview(inbox)
        addSubview(profile)
        self.title.addSubview(settings)
        self.title.addSubview(account)

        self.clipsToBounds = true
        updateConstraints()
        doColors()
    }

    func you(_ sender: AnyObject) {
        self.parentController?.dismiss(animated: true) {
            let profile = ProfileViewController.init(name: AccountController.currentName)
            VCPresenter.showVC(viewController: profile, popupIfPossible: true, parentNavigationController: (self.parentController as! NavigationSidebarViewController).parentController?.navigationController, parentViewController: (self.parentController as! NavigationSidebarViewController).parentController)
        }
    }

    func inbox(_ sender: AnyObject) {
        self.parentController?.dismiss(animated: true) {
            let inbox = InboxViewController.init()
            VCPresenter.showVC(viewController: inbox, popupIfPossible: true, parentNavigationController: (self.parentController as! NavigationSidebarViewController).parentController?.navigationController, parentViewController: (self.parentController as! NavigationSidebarViewController).parentController)
        }
    }

    func showMore(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: "Navigate", preferredStyle: .actionSheet)

        let prof = UIAlertAction(title: "Go to a profile", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.showProfileDialog(self.inbox)
        })
        optionMenu.addAction(prof)

        let saved = UIAlertAction(title: "Your saved content", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            let profile = ProfileViewController.init(name: AccountController.currentName)
            (self.parentController as! NavigationSidebarViewController).parentController?.navigationController?.pushViewController(profile, animated: true)
            self.parentController!.dismiss(animated: true, completion: nil)

        })
        optionMenu.addAction(saved)

        let inbox = UIAlertAction(title: "Inbox", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.inbox(self.inbox)
        })
        optionMenu.addAction(inbox)

        let settings = UIAlertAction(title: "Settings", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.settings(self.inbox)
        })
        optionMenu.addAction(settings)

        optionMenu.modalPresentationStyle = .popover
        if let presenter = optionMenu.popoverPresentationController {
            presenter.sourceView = account
            presenter.sourceRect = account.bounds
        }

        parentController?.present(optionMenu, animated: true, completion: nil)

    }


    func showProfileDialog(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Enter a username", message: "", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = ""
        }

        alert.addAction(UIAlertAction(title: "Go to user", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            let profile = ProfileViewController.init(name: (textField?.text!)!)
            (self.parentController as! NavigationSidebarViewController).parentController?.navigationController?.pushViewController(profile, animated: true)
            self.parentController!.dismiss(animated: true, completion: nil)

        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        parentController?.present(alert, animated: true, completion: nil)
    }

    func settings(_ sender: AnyObject) {
        self.parentController!.dismiss(animated: true){
            let settings = SettingsViewController()
            VCPresenter.showVC(viewController: settings, popupIfPossible: true, parentNavigationController: (self.parentController as! NavigationSidebarViewController).parentController?.navigationController, parentViewController: (self.parentController as! NavigationSidebarViewController).parentController)
        }
    }

    func switchAccounts(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)

        for s in AccountController.names {
            if (s != AccountController.currentName) {
                let add = UIAlertAction(title: s, style: .default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    AccountController.switchAccount(name: s)
                    if !UserDefaults.standard.bool(forKey: "done" + s) {
                        do {
                            try (self.parentController as! NavigationSidebarViewController).parentController?.addAccount(token: OAuth2TokenRepository.token(of: s))
                        } catch {
                            (self.parentController as! NavigationSidebarViewController).parentController?.addAccount()
                        }
                    } else {
                        Subscriptions.sync(name: s, completion: {
                            (self.parentController as! NavigationSidebarViewController).parentController?.restartVC()
                        })
                    }
                })
                optionMenu.addAction(add)
            }
        }

        if (AccountController.isLoggedIn) {
            let guest = UIAlertAction(title: "Guest", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                AccountController.switchAccount(name: "GUEST")
                Subscriptions.sync(name: "GUEST", completion: {
                    (self.parentController as! NavigationSidebarViewController).parentController?.restartVC()
                })
            })
            optionMenu.addAction(guest)

            let deleteAction = UIAlertAction(title: "Log out", style: .destructive, handler: {
                (alert: UIAlertAction!) -> Void in
                AccountController.delete(name: AccountController.currentName)
            })
            optionMenu.addAction(deleteAction)

        }

        let add = UIAlertAction(title: "Add account", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            (self.parentController as! NavigationSidebarViewController).parentController?.addAccount()
        })
        optionMenu.addAction(add)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        optionMenu.addAction(cancelAction)

        optionMenu.modalPresentationStyle = .overFullScreen
        if let presenter = optionMenu.popoverPresentationController {
            presenter.sourceView = self
            presenter.sourceRect = self.bounds
        }

        //todo better location checking
        parentController?.present(optionMenu, animated: true, completion: nil)
    }

    var parentController: UIViewController?

    func setSubreddit(subreddit: String, parent: UIViewController) {
        self.subreddit = subreddit
        self.parentController = parent
        updateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var subreddit = ""

    override func updateConstraints() {
        super.updateConstraints()

        let metrics = ["topMargin": 0]
        let views = ["title": title, "account": account, "inbox": inboxBody, "inboxc": inbox, "settings": settings, "profile": profile, "search": search] as [String: Any]

        var constraint: [NSLayoutConstraint] = []


        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[title]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[search]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[search]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[inbox]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[profile]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[title(90)]-[profile(40)]-4-[inbox(40)]-4-[search]-4-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        addConstraints(constraint)

        var titleConstraints: [NSLayoutConstraint] = []

        titleConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[account]",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        titleConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[settings]-12-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        titleConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-30-[account]",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        titleConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-30-[settings]",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        title.addConstraints(titleConstraints)
    }

    func getEstHeight() -> CGFloat {
        return CGFloat(title.frame.size.height + (3 * settings.frame.size.height) + 50)
    }

    func setMail(_ mailcount: Int) {
        inbox.text = "\(mailcount)"
    }
}

//https://stackoverflow.com/a/44698425/3697225
extension UIFont {

    func withTraits(_ traits: UIFontDescriptorSymbolicTraits) -> UIFont {

        // create a new font descriptor with the given traits
        if let fd = fontDescriptor.withSymbolicTraits(traits) {
            // return a new font with the created font descriptor
            return UIFont(descriptor: fd, size: pointSize)
        }

        // the given traits couldn't be applied, return self
        return self
    }

    func italics() -> UIFont {
        return withTraits(.traitItalic)
    }

    func bold() -> UIFont {
        return withTraits(.traitBold)
    }

    func boldItalics() -> UIFont {
        return withTraits([ .traitBold, .traitItalic ])
    }
}
