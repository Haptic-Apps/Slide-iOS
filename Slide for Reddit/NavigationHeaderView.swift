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
    var you = UITableViewCell()
    var settings = UITableViewCell()
    var inboxBody = UITableViewCell()

    var search: UISearchBar = UISearchBar()

    func doColors() {
        title.textColor = ColorUtil.fontColor
        backgroundColor = ColorUtil.foregroundColor
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.search = UISearchBar(frame: CGRect(x: 0, y: 0, width: 3, height: 50))
        self.inbox = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        self.inbox.clipsToBounds = true

        self.profile.textLabel?.text = "Go to a profile"
        self.profile.accessoryType = .none
        self.profile.backgroundColor = ColorUtil.foregroundColor
        self.profile.textLabel?.textColor = ColorUtil.fontColor
        self.profile.imageView?.image = UIImage.init(named: "user")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.profile.imageView?.tintColor = ColorUtil.fontColor

        self.you.textLabel?.text = "Account"
        self.you.accessoryType = .none
        self.you.backgroundColor = ColorUtil.foregroundColor
        self.you.textLabel?.textColor = ColorUtil.fontColor
        self.you.imageView?.image = UIImage.init(named: "profile")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.you.imageView?.tintColor = ColorUtil.fontColor

        self.settings.textLabel?.text = "Settings"
        self.settings.accessoryType = .none
        self.settings.backgroundColor = ColorUtil.foregroundColor
        self.settings.textLabel?.textColor = ColorUtil.fontColor
        self.settings.imageView?.image = UIImage.init(named: "settings")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.settings.imageView?.tintColor = ColorUtil.fontColor

        self.inboxBody.textLabel?.text = "Inbox"
        self.inboxBody.accessoryView = inbox
        self.inboxBody.backgroundColor = ColorUtil.foregroundColor
        self.inboxBody.textLabel?.textColor = ColorUtil.fontColor
        self.inboxBody.imageView?.image = UIImage.init(named: "inbox")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.inboxBody.imageView?.tintColor = ColorUtil.fontColor

        search.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        profile.translatesAutoresizingMaskIntoConstraints = false
        you.translatesAutoresizingMaskIntoConstraints = false
        settings.translatesAutoresizingMaskIntoConstraints = false
        inboxBody.translatesAutoresizingMaskIntoConstraints = false

        settings.tintColor = ColorUtil.fontColor
        you.tintColor = ColorUtil.fontColor
        profile.tintColor = ColorUtil.fontColor
        inboxBody.tintColor = ColorUtil.fontColor

        inbox.textColor = .white
        inbox.font = UIFont.boldSystemFont(ofSize: 16)
        inbox.backgroundColor = GMColor.red300Color()
        inbox.layer.cornerRadius = 10
        inbox.layer.masksToBounds = true
        inbox.textAlignment = .center

        title.font = UIFont.boldSystemFont(ofSize: 26)

        let aTap = UITapGestureRecognizer(target: self, action: #selector(self.switchAccounts(_:)))
        you.addGestureRecognizer(aTap)
        you.isUserInteractionEnabled = true

        let setTap = UITapGestureRecognizer(target: self, action: #selector(self.settings(_:)))
        settings.addGestureRecognizer(setTap)
        settings.isUserInteractionEnabled = true

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
        addSubview(settings)
        addSubview(search)
        addSubview(title)
        addSubview(inbox)
        addSubview(you)
        addSubview(profile)

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
            presenter.sourceView = you
            presenter.sourceRect = you.bounds
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
        //self.parentController!.dismiss(animated: true, completion: nil)

        let settings = SettingsViewController()
        VCPresenter.showVC(viewController: settings, popupIfPossible: true, parentNavigationController: parentController?.navigationController, parentViewController: parentController)
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
        let views = ["title": title, "you": you, "inbox": inboxBody, "inboxc": inbox, "settings": settings, "profile": profile, "search": search] as [String: Any]

        var constraint: [NSLayoutConstraint] = []


        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[title]-8-|",
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
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[settings]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[you]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[profile]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[title]-[settings(40)]-4-[profile(40)]-4-[you(40)]-4-[inbox(40)]-4-[search]-4-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))


        if (AccountController.isLoggedIn) {
            title.text = AccountController.currentName
            inbox.isHidden = false
        } else {
            inbox.isHidden = true
            title.text = "guest"
        }

        addConstraints(constraint)
    }

    func getEstHeight() -> CGFloat {
        return CGFloat(title.frame.size.height + (5 * settings.frame.size.height) + 50)
    }

    func setMail(_ mailcount: Int) {
        inbox.text = "\(mailcount)"
    }
}
