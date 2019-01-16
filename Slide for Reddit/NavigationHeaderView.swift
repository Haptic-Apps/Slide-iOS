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
    var mailBadge: BadgeSwift?

    private var layoutConstraints: [NSLayoutConstraint] = []

    var back = UIView()
    var title = UILabel()
    var account = UIButton()
    var inbox = UIButton()
    var settings = UIButton()
    var more = UIButton()
    var mod = UIButton()
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

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        if let text = searchBar.text {
          VCPresenter.openRedditLink("/r/\(text)", parentController?.navigationController, parentController)
        }
    }
    
    func configureViews() {
        self.clipsToBounds = true

        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 90))
        title.isUserInteractionEnabled = true

        self.search = UISearchBar(frame: CGRect(x: 0, y: 0, width: 3, height: 50))
        search.autocorrectionType = .no
        search.autocapitalizationType = .none
        search.spellCheckingType = .no
        search.returnKeyType = .search
        search.delegate = self
        if ColorUtil.theme != .LIGHT {
            search.keyboardAppearance = .dark
        }

        self.addSubviews(back, search)

        // Set up title children
        self.account = UIButton.init(type: .custom).then {
            $0.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
            $0.setImage(UIImage.init(named: "profile")!.getCopy(withSize: .square(size: 30), withColor: SettingValues.reduceColor ? ColorUtil.fontColor : .white), for: UIControl.State.normal)
        }

        self.more = UIButton.init(type: .custom).then {
            $0.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
            $0.setImage(UIImage.init(named: "moreh")!.getCopy(withSize: .square(size: 30), withColor: SettingValues.reduceColor ? ColorUtil.fontColor : .white), for: UIControl.State.normal)
        }

        self.inbox = UIButton.init(type: .custom).then {
            $0.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
            $0.setImage(UIImage.init(named: "inbox")!.getCopy(withSize: .square(size: 30), withColor: SettingValues.reduceColor ? ColorUtil.fontColor : .white), for: UIControl.State.normal)
            $0.isUserInteractionEnabled = true
        }
        
        self.mod = UIButton.init(type: .custom).then {
            $0.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
            $0.setImage(UIImage.init(named: "mod")!.getCopy(withSize: .square(size: 30), withColor: SettingValues.reduceColor ? ColorUtil.fontColor : .white), for: UIControl.State.normal)
            $0.isUserInteractionEnabled = true
            $0.isHidden = true
        }

        self.settings = UIButton.init(type: .custom).then {
            $0.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
            $0.setImage(UIImage.init(named: "settings")!.getCopy(withSize: .square(size: 30), withColor: SettingValues.reduceColor ? ColorUtil.fontColor : .white), for: UIControl.State.normal)
            $0.isUserInteractionEnabled = true
        }

        back.addSubviews(title, account, inbox, mod, settings)

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

        mod.addTarget(self, action: #selector(self.mod(_:)), for: UIControl.Event.touchUpInside)
        account.addTarget(self, action: #selector(self.switchAccounts(_:)), for: UIControl.Event.touchUpInside)
        more.addTarget(self, action: #selector(self.showMore(_:)), for: UIControl.Event.touchUpInside)
        inbox.addTarget(self, action: #selector(self.mod(_:)), for: UIControl.Event.touchUpInside)
    }

    func updateLayout() {
        NSLayoutConstraint.deactivate(layoutConstraints)
        layoutConstraints = []

        layoutConstraints = batch {

            back.topAnchor == self.topAnchor
            back.heightAnchor == 90
            back.horizontalAnchors == self.horizontalAnchors
            
            title.verticalAnchors == back.verticalAnchors

            search.topAnchor == title.bottomAnchor + 4
            search.horizontalAnchors == self.horizontalAnchors
            search.heightAnchor == 50
            search.bottomAnchor == self.bottomAnchor

            // Title constraints
            account.leftAnchor == back.leftAnchor + 16
            account.centerYAnchor == back.centerYAnchor
            account.widthAnchor == 30
            title.leftAnchor == account.rightAnchor + 16

            settings.rightAnchor == back.rightAnchor - 16
            settings.centerYAnchor == back.centerYAnchor
            settings.widthAnchor == 30

            inbox.rightAnchor == settings.leftAnchor - 20
            inbox.centerYAnchor == back.centerYAnchor
            inbox.widthAnchor == 30

            if isModerator {
                mod.isHidden = false
                mod.rightAnchor == inbox.leftAnchor - 16
                mod.widthAnchor == 30
                mod.centerYAnchor == title.centerYAnchor
                title.rightAnchor == mod.leftAnchor - 16
            } else {
                title.rightAnchor == inbox.leftAnchor - 16
            }
            
            // TODO: Determine if we still need this
            if #available(iOS 11.0, *) {
                account.heightAnchor == 90
                title.heightAnchor == 90
                inbox.heightAnchor == 90
                settings.heightAnchor == 90
            }
        }
    }

    func setIsMod(_ hasMail: Bool) {
        isModerator = true
        DispatchQueue.main.async {
            self.updateLayout()
        }
    }

    func doColors(_ sub: String) {
        doColors()
        back.backgroundColor = ColorUtil.getColorForSub(sub: sub)
        if SettingValues.reduceColor {
            title.textColor = ColorUtil.fontColor
            back.backgroundColor = ColorUtil.foregroundColor
        }
    }

    func doColors() {
        var titleFont = UIFont.boldSystemFont(ofSize: 25)
        title.font = titleFont
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        title.textColor = .white
        if SettingValues.reduceColor {
            title.textColor = ColorUtil.fontColor
            back.backgroundColor = ColorUtil.foregroundColor
        }
        title.textAlignment = .left
        
        if AccountController.isLoggedIn {
            title.adjustsFontSizeToFitWidth = true
            title.text = AccountController.formatUsername(input: AccountController.currentName, small: true)
            inbox.isHidden = false
        } else {
            inbox.isHidden = true
            let titleT = NSMutableAttributedString.init(string: "Guest\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): titleFont]))
            titleFont = UIFont.systemFont(ofSize: 20)
            titleT.append(NSMutableAttributedString.init(string: "Tap to sign in", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): titleFont.bold()])))
            title.attributedText = titleT
        }

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
            mailBadge?.removeFromSuperview()
            mailBadge = nil

        if mailcount != 0 {
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
    }

    private func positionBadge(_ badge: UIView) {
        badge.translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()

        // Center the badge vertically in its container
        constraints.append(NSLayoutConstraint(
                item: badge,
                attribute: NSLayoutConstraint.Attribute.centerY,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: inbox,
                attribute: NSLayoutConstraint.Attribute.centerY,
                multiplier: 1, constant: -10)
        )

        // Center the badge horizontally in its container
        constraints.append(NSLayoutConstraint(
                item: badge,
                attribute: NSLayoutConstraint.Attribute.centerX,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: inbox,
                attribute: NSLayoutConstraint.Attribute.centerX,
                multiplier: 1, constant: 15)
        )

        inbox.addConstraints(constraints)
    }

}

// MARK: Actions
extension NavigationHeaderView {
    @objc func you(_ sender: AnyObject) {
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

    @objc func inbox(_ sender: AnyObject) {
        self.parentController?.dismiss(animated: true) {
            let inbox = InboxViewController.init()
            VCPresenter.showVC(viewController: inbox, popupIfPossible: true, parentNavigationController: (self.parentController as! NavigationSidebarViewController).parentController?.navigationController, parentViewController: (self.parentController as! NavigationSidebarViewController).parentController)
        }
    }

    @objc func showMore(_ sender: AnyObject) {

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

    @objc func settings(_ sender: AnyObject) {
        self.parentController!.dismiss(animated: true) {
            let settings = SettingsViewController()
            VCPresenter.showVC(viewController: settings, popupIfPossible: false, parentNavigationController: (self.parentController as! NavigationSidebarViewController).parentController?.navigationController, parentViewController: (self.parentController as! NavigationSidebarViewController).parentController)
        }
    }

    @objc func mod(_ sender: AnyObject) {
        self.parentController!.dismiss(animated: true) {
            let settings = ModerationViewController()
            VCPresenter.showVC(viewController: settings, popupIfPossible: true, parentNavigationController: (self.parentController as! NavigationSidebarViewController).parentController?.navigationController, parentViewController: (self.parentController as! NavigationSidebarViewController).parentController)
        }
    }

    @objc func switchAccounts(_ sender: AnyObject) {
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

    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {

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

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
