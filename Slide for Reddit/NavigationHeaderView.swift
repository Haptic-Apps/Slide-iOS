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
import Anchorage
import Then

class NavigationHeaderView: UIView {

    var profileString: String?
    var parentController: UIViewController?
    var subreddit = ""
    var mod = false
    var mailBadge: BadgeSwift?

    private var layoutConstraints: [NSLayoutConstraint] = []

    var title = UILabel()
    var account = UIButton()
    var inbox = UIButton()
    var more = UIButton()
    var search: UISearchBar = UISearchBar()


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureViews()
        configureActions()
        updateLayout()

        doColors()
    }

    func configureViews() {
        self.clipsToBounds = true

        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 90))
        title.isUserInteractionEnabled = true

        self.search = UISearchBar(frame: CGRect(x: 0, y: 0, width: 3, height: 50))

        self.addSubviews(title, search)

        // Set up title children
        self.account = UIButton.init(type: .custom).then {
            $0.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            $0.setImage(UIImage.init(named: "profile")!.getCopy(withSize: .square(size: 30)), for: UIControlState.normal)
        }

        self.more = UIButton.init(type: .custom).then {
            $0.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            $0.setImage(UIImage.init(named: "moreh")!.getCopy(withSize: .square(size: 30)), for: UIControlState.normal)
        }

        self.inbox = UIButton.init(type: .custom).then {
            $0.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            $0.setImage(UIImage.init(named: "inbox")!.getCopy(withSize: .square(size: 30), withColor: .white), for: UIControlState.normal)
            $0.isUserInteractionEnabled = true
        }

        title.addSubviews(account, inbox, more)

    }

    func configureActions() {
        if (AccountController.isLoggedIn) {
            let yTap = UITapGestureRecognizer(target: self, action: #selector(self.you(_:)))
            title.addGestureRecognizer(yTap)
        } else {
            let yTap = UITapGestureRecognizer(target: self, action: #selector(self.switchAccounts(_:)))
            title.addGestureRecognizer(yTap)
        }

        let iTap = UITapGestureRecognizer(target: self, action: #selector(self.inbox(_:)))
        inbox.addGestureRecognizer(iTap)

        account.addTarget(self, action: #selector(self.switchAccounts(_:)), for: UIControlEvents.touchUpInside)
        more.addTarget(self, action: #selector(self.showMore(_:)), for: UIControlEvents.touchUpInside)
        inbox.addTarget(self, action: #selector(self.mod(_:)), for: UIControlEvents.touchUpInside)
    }

    func updateLayout() {
        NSLayoutConstraint.deactivate(layoutConstraints)
        layoutConstraints = []

        layoutConstraints = batch {

            title.topAnchor == self.topAnchor
            title.heightAnchor == 90
            title.horizontalAnchors == self.horizontalAnchors

            search.topAnchor == title.bottomAnchor + 4
            search.horizontalAnchors == self.horizontalAnchors
            search.heightAnchor == 50
            search.bottomAnchor == self.bottomAnchor

            // Title constraints
            account.leftAnchor == title.leftAnchor + 16
            account.centerYAnchor == title.centerYAnchor

            more.rightAnchor == title.rightAnchor - 16
            more.centerYAnchor == title.centerYAnchor

            inbox.rightAnchor == more.leftAnchor - 24
            inbox.centerYAnchor == title.centerYAnchor

            // TODO: Determine if we still need this
            if #available(iOS 11.0, *){
                account.heightAnchor == 90
                inbox.heightAnchor == 90
                more.heightAnchor == 90
            }
        }
    }

    func setIsMod(_ hasMail: Bool) {
        mod = true
    }

    func doColors(_ sub: String) {
        doColors()
        title.backgroundColor = ColorUtil.getColorForSub(sub: sub)
    }

    func doColors() {
        var titleFont = UIFont.systemFont(ofSize: 15)
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        title.textColor = .white

        if (AccountController.isLoggedIn) {
            let titleT = NSMutableAttributedString.init(string: "\t\t", attributes: [NSFontAttributeName: titleFont])
            if(AccountController.formatUsername(input: AccountController.currentName, small: true).length > 15){
                titleFont = UIFont.systemFont(ofSize: 15)
            } else {
                titleFont = UIFont.systemFont(ofSize: 25)
            }
            titleT.append(NSMutableAttributedString.init(string: AccountController.formatUsername(input: AccountController.currentName, small: true), attributes: [NSFontAttributeName: titleFont.bold()]))
            title.adjustsFontSizeToFitWidth = true
            title.attributedText = titleT
            inbox.isHidden = false
        } else {
            inbox.isHidden = true
            let titleT = NSMutableAttributedString.init(string: "\t\tGuest\n", attributes: [NSFontAttributeName: titleFont])
            titleFont = UIFont.systemFont(ofSize: 20)
            titleT.append(NSMutableAttributedString.init(string: "\t\tTap to sign in", attributes: [NSFontAttributeName: titleFont.bold()]))
            title.attributedText = titleT
        }

        title.textAlignment = .left
        title.backgroundColor = ColorUtil.getColorForSub(sub: "")
        backgroundColor = ColorUtil.foregroundColor
    }

    func setSubreddit(subreddit: String, parent: UIViewController) {
        self.subreddit = subreddit
        self.parentController = parent
        updateLayout()
    }

    func getEstHeight() -> CGFloat {
        return CGFloat(90 + 50 + 4)
    }

    func setMail(_ mailcount: Int) {
        guard mailcount != 0 else {
            mailBadge?.removeFromSuperview()
            mailBadge = nil
            return
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

// MARK: Actions
extension NavigationHeaderView {
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

        /*alertController.addAction(Action(ActionData(title: "Pro override (TESTING)", image: UIImage(named: "support")!.menuIcon()), style: .default, handler: { action in
         SettingValues.isPro = !SettingValues.isPro
         }))*/

        if(mod){
            alertController.addAction(Action(ActionData(title: "Moderation", image: UIImage(named: "mod")!.menuIcon()), style: .default, handler: { action in
                self.mod(self.inbox)
            }))
        }

        alertController.addAction(Action(ActionData(title: "Offline cache now", image: UIImage(named: "download")!.menuIcon()), style: .default, handler: { action in
            self.parentController!.dismiss(animated: true) {
                _ = AutoCache.init(baseController: (self.parentController as! NavigationSidebarViewController).parentController!)
            }
        }))

        alertController.addAction(Action(ActionData(title: "Go to a profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { action in
            self.showProfileDialog(self.inbox)
        }))


        if(AccountController.isLoggedIn){
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
        }

        parentController?.present(alertController, animated: true, completion: nil)

    }

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
            textField.action { [weak self] textField in
                self?.profileString = textField.text
            }
        }

        alert.addOneTextField(configuration: config)

        alert.addAction(UIAlertAction(title: "Go to user", style: .default, handler: { [weak self] (_) in
            if let strongSelf = self {
                let profile = ProfileViewController.init(name: strongSelf.profileString ?? "")
                (strongSelf.parentController as! NavigationSidebarViewController).parentController?.navigationController?.pushViewController(profile, animated: true)
                strongSelf.parentController!.dismiss(animated: true, completion: nil)
            }
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
                            (self.parentController as! NavigationSidebarViewController).parentController?.doCurrentPage(0)
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
