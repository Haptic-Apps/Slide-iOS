//
//  UZTextViewCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/6/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import RLBAlertsPickers
import XLActionController
import BadgeSwift
import MaterialComponents.MaterialProgressView

class NavigationHeaderView: UIView {
    var title = UILabel()

    var account = UIButton()
    var inbox = UIButton()
    var more = UIButton()

    var search: UISearchBar = UISearchBar()

    var mod = false

    func setIsMod(_ hasMail: Bool) {
        mod = true
    }

    func doColors(_ sub: String) {
        title.backgroundColor = ColorUtil.getColorForSub(sub: sub)
    }

    func doColors() {
        var titleFont = UIFont.systemFont(ofSize: 15)
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        title.textColor = .white

        if (AccountController.isLoggedIn) {
            var titleT = NSMutableAttributedString.init(string: "\t\t", attributes: [NSFontAttributeName: titleFont])
            titleFont = UIFont.systemFont(ofSize: 25)
            titleT.append(NSMutableAttributedString.init(string: AccountController.formatUsername(input: AccountController.currentName, small: true), attributes: [NSFontAttributeName: titleFont.bold()]))
            title.attributedText = titleT
            inbox.isHidden = false
        } else {
            inbox.isHidden = true
            var titleT = NSMutableAttributedString.init(string: "\t\tGuest\n", attributes: [NSFontAttributeName: titleFont])
            titleFont = UIFont.systemFont(ofSize: 20)
            titleT.append(NSMutableAttributedString.init(string: "\t\tTap to sign in", attributes: [NSFontAttributeName: titleFont.bold()]))
            title.attributedText = titleT
        }

        title.textAlignment = .left
        title.backgroundColor = ColorUtil.getColorForSub(sub: "")
        backgroundColor = ColorUtil.foregroundColor
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.search = UISearchBar(frame: CGRect(x: 0, y: 0, width: 3, height: 50))
        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 90))
        self.inbox.clipsToBounds = true

        self.account = UIButton.init(type: .custom)
        account.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        account.setImage(UIImage.init(named: "profile")!.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: UIControlState.normal)
        account.addTarget(self, action: #selector(self.switchAccounts(_:)), for: UIControlEvents.touchUpInside)
        account.frame = CGRect.init(x: 0, y: 0, width: 60, height: 90)

        self.more = UIButton.init(type: .custom)
        more.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        more.setImage(UIImage.init(named: "moreh")!.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMore(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: 0, y: 0, width: 60, height: 90)

        self.inbox = UIButton.init(type: .custom)
        inbox.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        inbox.setImage(UIImage.init(named: "inbox")!.withColor(tintColor: .white).imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: UIControlState.normal)
        inbox.addTarget(self, action: #selector(self.mod(_:)), for: UIControlEvents.touchUpInside)
        inbox.frame = CGRect.init(x: 0, y: 0, width: 60, height: 90)


        search.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        account.translatesAutoresizingMaskIntoConstraints = false
        inbox.translatesAutoresizingMaskIntoConstraints = false
        more.translatesAutoresizingMaskIntoConstraints = false

        if (AccountController.isLoggedIn) {
            let yTap = UITapGestureRecognizer(target: self, action: #selector(self.you(_:)))
            title.addGestureRecognizer(yTap)
        } else {
            let yTap = UITapGestureRecognizer(target: self, action: #selector(self.switchAccounts(_:)))
            title.addGestureRecognizer(yTap)
        }

        title.isUserInteractionEnabled = true

        let iTap = UITapGestureRecognizer(target: self, action: #selector(self.inbox(_:)))
        inbox.addGestureRecognizer(iTap)
        inbox.isUserInteractionEnabled = true

        addSubview(search)
        addSubview(title)
        self.title.addSubview(more)
        self.title.addSubview(account)
        self.title.addSubview(inbox)

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

        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Navigate"


        alertController.addAction(Action(ActionData(title: "Settings", image: UIImage(named: "settings")!.menuIcon()), style: .default, handler: { action in
            self.settings(self.inbox)
        }))

        alertController.addAction(Action(ActionData(title: "Pro override (TESTING)", image: UIImage(named: "support")!.menuIcon()), style: .default, handler: { action in
            SettingValues.isPro = !SettingValues.isPro
        }))
        
        if(mod){
            alertController.addAction(Action(ActionData(title: "Moderation", image: UIImage(named: "mod")!.menuIcon()), style: .default, handler: { action in
                self.mod(self.inbox)
            }))
        }

        alertController.addAction(Action(ActionData(title: "Offline cache now", image: UIImage(named: "download")!.menuIcon()), style: .default, handler: { action in
            self.parentController!.dismiss(animated: true) {
                AutoCache.init(baseController: (self.parentController as! NavigationSidebarViewController).parentController!)
            }
        }))

        alertController.addAction(Action(ActionData(title: "Go to a profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { action in
            self.showProfileDialog(self.inbox)
        }))

        alertController.addAction(Action(ActionData(title: "Saved submissions", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { action in
            self.parentController!.dismiss(animated: true) {
                let profile = ProfileViewController.init(name: AccountController.currentName)
                profile.openTo = 6
                VCPresenter.showVC(viewController: profile, popupIfPossible: true, parentNavigationController: (self.parentController as! NavigationSidebarViewController).parentController?.navigationController, parentViewController: (self.parentController as! NavigationSidebarViewController).parentController)
            }
        }))

        alertController.addAction(Action(ActionData(title: "Upvoted submissions", image: UIImage(named: "upvote")!.menuIcon()), style: .default, handler: { action in
            self.parentController!.dismiss(animated: true) {
                let profile = ProfileViewController.init(name: AccountController.currentName)
                profile.openTo = 3
                VCPresenter.showVC(viewController: profile, popupIfPossible: true, parentNavigationController: (self.parentController as! NavigationSidebarViewController).parentController?.navigationController, parentViewController: (self.parentController as! NavigationSidebarViewController).parentController)
            }
        }))

        parentController?.present(alertController, animated: true, completion: nil)

    }

    var profileString: String?

    func showProfileDialog(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Enter a username", message: "", preferredStyle: .alert)

        let config: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = "Username"
            textField.left(image: UIImage.init(named: "user"), color: .black)
            textField.leftViewPadding = 12
            textField.borderWidth = 1
            textField.cornerRadius = 8
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = .white
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.action { textField in
                self.profileString = textField.text
            }
        }

        alert.addOneTextField(configuration: config)

        alert.addAction(UIAlertAction(title: "Go to user", style: .default, handler: { [weak alert] (_) in
            let profile = ProfileViewController.init(name: self.profileString ?? "")
            (self.parentController as! NavigationSidebarViewController).parentController?.navigationController?.pushViewController(profile, animated: true)
            self.parentController!.dismiss(animated: true, completion: nil)

        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        parentController?.present(alert, animated: true, completion: nil)
    }

    func settings(_ sender: AnyObject) {
        self.parentController!.dismiss(animated: true) {
            let settings = SettingsViewController()
            VCPresenter.showVC(viewController: settings, popupIfPossible: false, parentNavigationController: (self.parentController as! NavigationSidebarViewController).parentController?.navigationController, parentViewController: (self.parentController as! NavigationSidebarViewController).parentController)
        }
    }

    func mod(_ sender: AnyObject) {
        self.parentController!.dismiss(animated: true) {
            let settings = ModerationViewController()
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
        let views = ["title": title, "account": account, "inbox": inbox,  "more": more, "search": search] as [String: Any]

        var constraint: [NSLayoutConstraint] = []


        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[title]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[search]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[title(90)]-4-[search]",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        addConstraints(constraint)

        var titleConstraints: [NSLayoutConstraint] = []

        titleConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[account]",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        titleConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[inbox]-16-[more]-16-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        titleConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-[account(90)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        titleConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-[inbox(90)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        titleConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-[more(90)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        title.addConstraints(titleConstraints)
    }

    func getEstHeight() -> CGFloat {
        return CGFloat(90 + 50 + 4)
    }

    var mailBadge: BadgeSwift?

    func setMail(_ mailcount: Int) {
        if(mailBadge != nil){
            mailBadge!.removeFromSuperview()
            mailBadge = nil
        }

        mailBadge = BadgeSwift()
        inbox.addSubview(mailBadge!)

        mailBadge!.text = "\(mailcount)"
        mailBadge!.insets = CGSize(width: 3, height: 3)
        mailBadge!.font = UIFont.systemFont(ofSize: 11)
        mailBadge!.textColor = UIColor.white
        mailBadge!.badgeColor = UIColor.red
        mailBadge!.shadowOpacityBadge = 0
        positionBadge(mailBadge!)
    }

    private func positionBadge(_ badge: UIView) {
        badge.translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()

        // Center the badge vertically in its container
        constraints.append(NSLayoutConstraint(
                item: badge,
                attribute: NSLayoutAttribute.centerY,
                relatedBy: NSLayoutRelation.equal,
                toItem: inbox,
                attribute: NSLayoutAttribute.centerY,
                multiplier: 1, constant: -10)
        )

        // Center the badge horizontally in its container
        constraints.append(NSLayoutConstraint(
                item: badge,
                attribute: NSLayoutAttribute.centerX,
                relatedBy: NSLayoutRelation.equal,
                toItem: inbox,
                attribute: NSLayoutAttribute.centerX,
                multiplier: 1, constant: 15)
        )

        inbox.addConstraints(constraints)
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
        return withTraits([.traitBold, .traitItalic])
    }
}
