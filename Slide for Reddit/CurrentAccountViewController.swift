//
//  CurrentAccountViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 1/9/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import SDWebImage
import Then
import UIKit
import XLActionController

protocol CurrentAccountViewControllerDelegate: AnyObject {
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestSettingsMenu: Void)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestAccountChangeToName accountName: String)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestGuestAccount: Void)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestLogOut: Void)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestNewAccount: Void)
}

class CurrentAccountViewController: UIViewController {

    weak var delegate: CurrentAccountViewControllerDelegate?

    var backgroundView = UIView().then {
        $0.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
    }

    var contentView = UIView().then {
        $0.backgroundColor = ColorUtil.foregroundColor
        $0.clipsToBounds = false
    }

    var accountNameLabel = UILabel().then {
        $0.font = FontGenerator.fontOfSize(size: 36, submission: false)
        $0.textColor = ColorUtil.fontColor
        $0.numberOfLines = 1
        $0.lineBreakMode = .byWordWrapping
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.5
    }

    var accountImageView = UIImageView().then {
        $0.backgroundColor = .white
        $0.contentMode = .scaleAspectFit
    }

    var settingsButton = UIButton(type: .custom).then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(UIImage(named: "settings")!.getCopy(withSize: .square(size: 30), withColor: .white), for: UIControlState.normal)
        $0.isUserInteractionEnabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupConstraints()
        setupActions()

        configureForCurrentAccount()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switchAccounts()
    }
}

// MARK: - Setup
private extension CurrentAccountViewController {
    func setupViews() {
        view.addSubview(backgroundView)

        // Add blur
        if #available(iOS 11, *) {
            let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
            let blurView = UIVisualEffectView(frame: .zero)
            blurEffect.setValue(3, forKeyPath: "blurRadius")
            blurView.effect = blurEffect
            backgroundView.insertSubview(blurView, at: 0)
            blurView.edgeAnchors == backgroundView.edgeAnchors
        }

        backgroundView.addSubview(settingsButton)

        view.addSubview(contentView)
        contentView.addSubview(accountImageView)
        contentView.addSubview(accountNameLabel)
    }

    func setupConstraints() {
        backgroundView.edgeAnchors == view.edgeAnchors

        settingsButton.topAnchor == backgroundView.safeTopAnchor + 4
        settingsButton.rightAnchor == backgroundView.safeRightAnchor - 16

        contentView.horizontalAnchors == view.horizontalAnchors
        contentView.bottomAnchor == view.bottomAnchor
        contentView.topAnchor == view.safeTopAnchor + 250 // TODO: Switch this out for a height anchor at some point

        accountImageView.leftAnchor == contentView.leftAnchor + 20
        accountImageView.centerYAnchor == contentView.topAnchor
        accountImageView.sizeAnchors == CGSize.square(size: 100)

        accountNameLabel.leftAnchor == accountImageView.rightAnchor + 20
        accountNameLabel.rightAnchor == contentView.rightAnchor - 20
        accountNameLabel.topAnchor == contentView.topAnchor + 4
    }

    func setupActions() {
        let bgTap = UITapGestureRecognizer(target: self, action: #selector(didRequestClose))
        backgroundView.addGestureRecognizer(bgTap)

        let sTap = UITapGestureRecognizer(target: self, action: #selector(settingsButtonPressed))
        settingsButton.addGestureRecognizer(sTap)
    }

    func configureForCurrentAccount() {

        if !AccountController.isLoggedIn {
            // TODO: Show empty state
            return
        }

        // Populate configurable UI elements here.
        accountNameLabel.attributedText = {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 1.0
            paragraphStyle.lineHeightMultiple = 0.7
            return NSAttributedString(
                string: AccountController.currentName.insertingZeroWidthSpacesBeforeCaptials(),
                attributes: [
                    NSParagraphStyleAttributeName: paragraphStyle,
                ]
            )
        }()

        accountImageView.image = UIImage(named: "profile")?.getCopy(withColor: .darkGray)
    }
}

// MARK: - Actions
extension CurrentAccountViewController {
    @objc func didRequestClose() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func settingsButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.delegate?.currentAccountViewController(self, didRequestSettingsMenu: ())
        }
    }
}

// MARK: - Account Switching
extension CurrentAccountViewController {
    func switchAccounts() {
        let optionMenu = BottomSheetActionController()
        optionMenu.headerData = "Accounts"

        for accountName in AccountController.names {
            if accountName != AccountController.currentName {
                optionMenu.addAction(Action(ActionData(title: "\(accountName)", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { _ in
                    self.delegate?.currentAccountViewController(self, didRequestAccountChangeToName: accountName)
                    self.configureForCurrentAccount()
                }))
            } else {
                var action = Action(ActionData(title: "\(accountName) (current)", image: UIImage(named: "selected")!.menuIcon().getCopy(withColor: GMColor.green500Color())), style: .default, handler: nil)
                action.enabled = false
                optionMenu.addAction(action)
            }
        }

        if AccountController.isLoggedIn {
            optionMenu.addAction(Action(ActionData(title: "Browse as guest", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { _ in
                self.delegate?.currentAccountViewController(self, didRequestGuestAccount: ())
                self.configureForCurrentAccount()
            }))

            optionMenu.addAction(Action(ActionData(title: "Log out", image: UIImage(named: "delete")!.menuIcon().getCopy(withColor: GMColor.red500Color())), style: .default, handler: { _ in
                self.delegate?.currentAccountViewController(self, didRequestLogOut: ())
                self.configureForCurrentAccount()
            }))

        }

        optionMenu.addAction(Action(ActionData(title: "Add a new account", image: UIImage(named: "add")!.menuIcon().getCopy(withColor: ColorUtil.baseColor)), style: .default, handler: { _ in
            self.delegate?.currentAccountViewController(self, didRequestNewAccount: ())
            self.configureForCurrentAccount()
        }))

        present(optionMenu, animated: true, completion: nil)
    }
}
