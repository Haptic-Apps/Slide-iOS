//
//  NavigationHeaderView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/6/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import BadgeSwift
import MaterialComponents.MaterialProgressView
import reddift
import RLBAlertsPickers
import Then
import UIKit
import XLActionController

class NavigationHeaderView: UIView, UISearchBarDelegate {

    var profileString: String?
    var parentController: UIViewController?
    var subreddit = ""
    var isModerator = false

    private var layoutConstraints: [NSLayoutConstraint] = []

    var accountContainer = UIStackView().then {
        $0.axis = .horizontal
//        $0.alignment = .fill
//        $0.distribution = .fillProportionally
        $0.spacing = 8
    }
    var buttonContainer = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
    }

    var title = UILabel()
    var account = UIButton()
    var inbox = UIButton()
    var inboxBadge = BadgeSwift().then {
        $0.insets = CGSize(width: 3, height: 3)
        $0.font = UIFont.systemFont(ofSize: 11)
        $0.textColor = UIColor.white
        $0.badgeColor = UIColor.red
        $0.shadowOpacityBadge = 0
    }
    var settings = UIButton()
    var more = UIButton()
    var mod = UIButton()
    var search = UISearchBar().then {
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.spellCheckingType = .no
        $0.returnKeyType = .search
        if ColorUtil.theme != .LIGHT {
            $0.keyboardAppearance = .dark
        }
    }
    
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

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        if let text = searchBar.text {
          VCPresenter.openRedditLink("/r/\(text)", parentController?.navigationController, parentController)
        }
    }
    
    func configureViews() {
        self.clipsToBounds = false

//        title.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        title.isUserInteractionEnabled = true

        search.delegate = self

        self.addSubviews(accountContainer, buttonContainer, search)

        // Set up title children
        self.account = UIButton(type: .custom).then {
            $0.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            $0.setImage(UIImage(named: "profile")!.getCopy(withSize: .square(size: 30), withColor: SettingValues.reduceColor ? ColorUtil.fontColor : .white), for: UIControlState.normal)
        }

        self.more = UIButton(type: .custom).then {
            $0.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            $0.setImage(UIImage(named: "moreh")!.getCopy(withSize: .square(size: 30), withColor: SettingValues.reduceColor ? ColorUtil.fontColor : .white), for: UIControlState.normal)
        }

        self.inbox = UIButton(type: .custom).then {
            $0.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            $0.setImage(UIImage(named: "inbox")!.getCopy(withSize: .square(size: 30), withColor: SettingValues.reduceColor ? ColorUtil.fontColor : .white), for: UIControlState.normal)
            $0.isUserInteractionEnabled = true
        }
        
        self.mod = UIButton(type: .custom).then {
            $0.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            $0.setImage(UIImage(named: "mod")!.getCopy(withSize: .square(size: 30), withColor: SettingValues.reduceColor ? ColorUtil.fontColor : .white), for: UIControlState.normal)
            $0.isUserInteractionEnabled = true
            $0.isHidden = true
        }

        self.settings = UIButton(type: .custom).then {
            $0.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            $0.setImage(UIImage(named: "settings")!.getCopy(withSize: .square(size: 30), withColor: SettingValues.reduceColor ? ColorUtil.fontColor : .white), for: UIControlState.normal)
            $0.isUserInteractionEnabled = true
        }

        account.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        title.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)

        accountContainer.addArrangedSubviews(account, title, .flexSpace(), mod, inbox)

        buttonContainer.addArrangedSubviews(settings, .flexSpace())

        inbox.addSubview(inboxBadge)

    }

    func configureActions() {
        if AccountController.isLoggedIn {
            let yTap = UITapGestureRecognizer(target: self, action: #selector(self.you(_:)))
            title.addGestureRecognizer(yTap)
        } else {
            let yTap = UITapGestureRecognizer(target: self, action: #selector(self.switchAccounts(_:)))
            title.addGestureRecognizer(yTap)
        }

        let iTap = UITapGestureRecognizer(target: self, action: #selector(self.inbox(_:)))
        inbox.addGestureRecognizer(iTap)

        let mTap = UITapGestureRecognizer(target: self, action: #selector(self.mod(_:)))
        mod.addGestureRecognizer(mTap)

        let sTap = UITapGestureRecognizer(target: self, action: #selector(self.settings(_:)))
        settings.addGestureRecognizer(sTap)

        mod.addTarget(self, action: #selector(self.mod(_:)), for: UIControlEvents.touchUpInside)
        account.addTarget(self, action: #selector(self.switchAccounts(_:)), for: UIControlEvents.touchUpInside)
        more.addTarget(self, action: #selector(self.showMore(_:)), for: UIControlEvents.touchUpInside)
        inbox.addTarget(self, action: #selector(self.mod(_:)), for: UIControlEvents.touchUpInside)
    }

    func updateLayout() {
        NSLayoutConstraint.deactivate(layoutConstraints)
        layoutConstraints = []

        layoutConstraints = batch {

            accountContainer.topAnchor == self.topAnchor + 12
            accountContainer.horizontalAnchors == self.horizontalAnchors + 16

            buttonContainer.topAnchor == accountContainer.bottomAnchor + 4
            buttonContainer.horizontalAnchors == self.horizontalAnchors + 16
            buttonContainer.heightAnchor == 0
            
            search.topAnchor == buttonContainer.bottomAnchor + 4
            search.horizontalAnchors == self.horizontalAnchors
            search.heightAnchor == 50
            search.bottomAnchor == self.bottomAnchor
            mod.isHidden = !isModerator

            inboxBadge.centerYAnchor == inbox.centerYAnchor - 10
            inboxBadge.centerXAnchor == inbox.centerXAnchor + 16
        }
    }

    func setIsMod(_ hasMail: Bool) {
        isModerator = true
        DispatchQueue.main.async {
            self.mod.isHidden = !self.isModerator
        }
    }

    func doColors(_ sub: String) {
        doColors()
        buttonContainer.backgroundColor = ColorUtil.getColorForSub(sub: sub)
        if SettingValues.reduceColor {
            title.textColor = ColorUtil.fontColor
            buttonContainer.backgroundColor = ColorUtil.foregroundColor
        }
    }

    func doColors() {
        var titleFont = UIFont.boldSystemFont(ofSize: 20)
        title.font = titleFont
        title.textColor = .white
        title.textAlignment = .left
        if SettingValues.reduceColor {
            title.textColor = ColorUtil.fontColor
            buttonContainer.backgroundColor = ColorUtil.foregroundColor
        }
        
        if AccountController.isLoggedIn {
            title.numberOfLines = 1
            title.adjustsFontSizeToFitWidth = true
            title.allowsDefaultTighteningForTruncation = true
            title.minimumScaleFactor = 10.0
//            title.preferredMaxLayoutWidth = 1000
            title.text = AccountController.formatUsername(input: AccountController.currentName, small: true)
            title.text = "Wow this is a long username jeez"
            inbox.isHidden = false
        } else {
            title.numberOfLines = 0
            inbox.isHidden = true
            let titleT = NSMutableAttributedString.init(string: "Guest\n", attributes: [NSFontAttributeName: titleFont])
            titleFont = UIFont.systemFont(ofSize: 20)
            titleT.append(NSMutableAttributedString.init(string: "Tap to sign in", attributes: [NSFontAttributeName: titleFont.bold()]))
            title.attributedText = titleT
        }

        backgroundColor = ColorUtil.foregroundColor
    }

    func setSubreddit(subreddit: String, parent: UIViewController) {
        self.subreddit = subreddit
        self.parentController = parent
        updateLayout()
    }

    func setMail(_ mailCount: Int) {
        inboxBadge.isHidden = mailCount == 0
        inboxBadge.text = "\(mailCount)"
    }

}

// MARK: Actions
extension NavigationHeaderView {
    func you(_ sender: AnyObject) {
        if !account.isUserInteractionEnabled {
            (self.parentController as? NavigationSidebarViewController)?.expand()
        } else {
            if AccountController.isLoggedIn {
                self.parentController?.dismiss(animated: true) {
                    let profile = ProfileViewController.init(name: AccountController.currentName)
                    VCPresenter.showVC(viewController: profile, popupIfPossible: true, parentNavigationController: (self.parentController as! NavigationSidebarViewController).parentController?.navigationController, parentViewController: (self.parentController as! NavigationSidebarViewController).parentController)
                    
                }
            } else {
                self.switchAccounts(sender)
            }
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

        if isModerator {
            alertController.addAction(Action(ActionData(title: "Moderation", image: UIImage(named: "mod")!.menuIcon()), style: .default, handler: { _ in
                self.mod(self.inbox)
            }))
        }

        alertController.addAction(Action(ActionData(title: "Offline cache now", image: UIImage(named: "download")!.menuIcon()), style: .default, handler: { _ in
            self.parentController!.dismiss(animated: true) {
                _ = AutoCache.init(baseController: (self.parentController as! NavigationSidebarViewController).parentController!)
            }
        }))

        alertController.addAction(Action(ActionData(title: "Go to a profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { _ in
            self.showProfileDialog(self.inbox)
        }))

        if AccountController.isLoggedIn {
            alertController.addAction(Action(ActionData(title: "Saved submissions", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { _ in
                self.parentController!.dismiss(animated: true) {
                    let profile = ProfileViewController.init(name: AccountController.currentName)
                    profile.openTo = 6
                    VCPresenter.showVC(viewController: profile, popupIfPossible: true, parentNavigationController: (self.parentController as! NavigationSidebarViewController).parentController?.navigationController, parentViewController: (self.parentController as! NavigationSidebarViewController).parentController)
                }
            }))

            alertController.addAction(Action(ActionData(title: "Upvoted submissions", image: UIImage(named: "upvote")!.menuIcon()), style: .default, handler: { _ in
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
        let optionMenu = BottomSheetActionController()
        optionMenu.headerData = "Accounts"

        for s in AccountController.names.unique() {
            if s != AccountController.currentName {
                optionMenu.addAction(Action(ActionData(title: "\(s)", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { _ in
                    AccountController.switchAccount(name: s)
                    if !UserDefaults.standard.bool(forKey: "done" + s) {
                        do {
                            try (self.parentController as! NavigationSidebarViewController).parentController?.addAccount(token: OAuth2TokenRepository.token(of: s), register: false)
                        } catch {
                            (self.parentController as! NavigationSidebarViewController).parentController?.addAccount(register: false)
                        }
                    } else {
                        Subscriptions.sync(name: s, completion: {
                            (self.parentController as! NavigationSidebarViewController).parentController?.hardReset()
                        })
                    }
                }))
            } else {
                var action = Action(ActionData(title: "\(s) (current)", image: UIImage(named: "selected")!.menuIcon().getCopy(withColor: GMColor.green500Color())), style: .default, handler: { _ in
                })
                action.enabled = false
                optionMenu.addAction(action)
            }
        }

        if AccountController.isLoggedIn {
            optionMenu.addAction(Action(ActionData(title: "Browse as guest", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { _ in
                AccountController.switchAccount(name: "GUEST")
                Subscriptions.sync(name: "GUEST", completion: {
                    (self.parentController as! NavigationSidebarViewController).parentController?.hardReset()
                })
            }))

            optionMenu.addAction(Action(ActionData(title: "Log out", image: UIImage(named: "delete")!.menuIcon().getCopy(withColor: GMColor.red500Color())), style: .default, handler: { _ in
                AccountController.delete(name: AccountController.currentName)
                AccountController.switchAccount(name: "GUEST")
                Subscriptions.sync(name: "GUEST", completion: {
                    (self.parentController as! NavigationSidebarViewController).parentController?.hardReset()
                })
            }))

        }

        optionMenu.addAction(Action(ActionData(title: "Add a new account", image: UIImage(named: "add")!.menuIcon().getCopy(withColor: ColorUtil.baseColor)), style: .default, handler: { _ in
            (self.parentController as! NavigationSidebarViewController).parentController?.addAccount(register: false)
        }))
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
