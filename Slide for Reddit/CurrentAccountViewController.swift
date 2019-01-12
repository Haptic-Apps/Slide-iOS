//
//  CurrentAccountViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 1/9/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import BadgeSwift
import reddift
import SDWebImage
import Then
import UIKit
import XLActionController

/**
 TODO:
 - Inbox badging isn't being updated when messages are marked as read (this means the Account object isn't being updated by the cell)
 */

protocol CurrentAccountViewControllerDelegate: AnyObject {
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestSettingsMenu: Void)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestAccountChangeToName accountName: String)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestGuestAccount: Void)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestLogOut: Void)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestNewAccount: Void)
}

class CurrentAccountViewController: UIViewController {

    weak var delegate: CurrentAccountViewControllerDelegate?

    var interactionController: CurrentAccountDismissInteraction?

    /// Overall height of the content view, including its out-of-bounds elements.
    var contentViewHeight: CGFloat {
        return view.frame.maxY - accountImageView.frame.minY
    }

    var spinner = UIActivityIndicatorView().then {
        $0.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        $0.color = ColorUtil.fontColor
        $0.hidesWhenStopped = true
    }

    var contentView = UIView().then {
        $0.backgroundColor = ColorUtil.backgroundColor
        $0.clipsToBounds = false
        $0.layer.cornerRadius = 30
    }

    var closeButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "close")!.getCopy(withSize: .square(size: 30), withColor: .white), for: UIControlState.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 24, right: 24)
        $0.accessibilityLabel = "Close"
    }

    var settingsButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "settings")!.getCopy(withSize: .square(size: 30), withColor: .white), for: UIControlState.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 4, left: 24, bottom: 24, right: 16)
        $0.accessibilityLabel = "App Settings"
    }

    // Outer button stack

    var upperButtonStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 0
    }
    var modButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "mod")!.getCopy(withSize: .square(size: 30), withColor: ColorUtil.baseAccent), for: UIControlState.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 16, left: 8, bottom: 8, right: 8)
        $0.accessibilityLabel = "Mod Queue"
    }
    var mailButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "messages")!.getCopy(withSize: .square(size: 30), withColor: ColorUtil.baseAccent), for: UIControlState.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 8)
        $0.accessibilityLabel = "Inbox"
    }
    var switchAccountsButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "user")!.getCopy(withSize: .square(size: 30), withColor: ColorUtil.baseAccent), for: UIControlState.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 16, left: 8, bottom: 8, right: 16)
        $0.accessibilityLabel = "Switch Accounts"
    }

    var mailBadge = BadgeSwift().then {
        $0.insets = CGSize(width: 3, height: 3)
        $0.font = UIFont.systemFont(ofSize: 11)
        $0.textColor = UIColor.white
        $0.badgeColor = UIColor.red
        $0.shadowOpacityBadge = 0
        $0.text = "0"
    }

    var modBadge = BadgeSwift().then {
        $0.insets = CGSize(width: 3, height: 3)
        $0.font = UIFont.systemFont(ofSize: 11)
        $0.textColor = UIColor.white
        $0.badgeColor = UIColor.red
        $0.shadowOpacityBadge = 0
        $0.text = "0"
    }

    // Content

    var accountNameLabel = UILabel().then {
        $0.font = FontGenerator.boldFontOfSize(size: 28, submission: false)
        $0.textColor = ColorUtil.fontColor
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.5
        $0.baselineAdjustment = UIBaselineAdjustment.alignCenters
    }

    var accountAgeLabel = UILabel().then {
        $0.font = FontGenerator.fontOfSize(size: 12, submission: false)
        $0.textColor = ColorUtil.fontColor
        $0.numberOfLines = 1
        $0.text = ""
    }

    var accountImageView = UIImageView().then {
        $0.backgroundColor = ColorUtil.foregroundColor
        $0.contentMode = .scaleAspectFit
        if #available(iOS 11.0, *) {
            $0.accessibilityIgnoresInvertColors = true
        }
        if !SettingValues.flatMode {
            $0.elevate(elevation: 2.0)
            $0.layer.cornerRadius = 10
            $0.clipsToBounds = true
        }
    }

    var header = AccountHeaderView()

    var emptyStateLabel = UILabel().then {
        $0.numberOfLines = 0
        $0.textColor = ColorUtil.fontColor
        $0.textAlignment = .center
        $0.attributedText = {
            var font = UIFont.boldSystemFont(ofSize: 20)
            let attributedString = NSMutableAttributedString.init(string: "You are logged out.\n", attributes: [NSFontAttributeName: font])
            attributedString.append(NSMutableAttributedString.init(string: "Tap here to sign in!", attributes: [NSFontAttributeName: font.bold()]))
            return attributedString
        }()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupConstraints()
        setupActions()

        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotificationPosted), name: .onAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedToGuestNotificationPosted), name: .onAccountChangedToGuest, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountMailCountChanged), name: .onAccountMailCountChanged, object: nil)

        interactionController = CurrentAccountDismissInteraction(viewController: self)

        configureForCurrentAccount()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Focus the account label
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, accountNameLabel)

        updateMailBadge()
        updateModBadge()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

}

// MARK: - Setup
extension CurrentAccountViewController {
    func setupViews() {

        view.addSubview(closeButton)
        view.addSubview(settingsButton)

        view.addSubview(upperButtonStack)
        upperButtonStack.addArrangedSubviews(mailButton, modButton, switchAccountsButton)

        mailButton.addSubview(mailBadge)
        modButton.addSubview(modBadge)

        view.addSubview(contentView)
        contentView.addSubview(accountImageView)
        contentView.addSubview(accountNameLabel)
        contentView.addSubview(accountAgeLabel)

        contentView.addSubview(header)
        header.delegate = self

        contentView.addSubview(emptyStateLabel)

        contentView.addSubview(spinner)

    }

    func setupConstraints() {

        closeButton.topAnchor == view.safeTopAnchor
        closeButton.leftAnchor == view.safeLeftAnchor

        settingsButton.topAnchor == view.safeTopAnchor
        settingsButton.rightAnchor == view.safeRightAnchor

        upperButtonStack.leftAnchor == accountImageView.rightAnchor
        upperButtonStack.bottomAnchor == contentView.topAnchor

        contentView.topAnchor == view.safeTopAnchor + 400 // TODO: Switch this out for a height anchor at some point
        contentView.horizontalAnchors == view.horizontalAnchors
        contentView.bottomAnchor == view.bottomAnchor

        accountImageView.leftAnchor == contentView.leftAnchor + 20
        accountImageView.centerYAnchor == contentView.topAnchor
        accountImageView.sizeAnchors == CGSize.square(size: 100)

        accountNameLabel.topAnchor == contentView.topAnchor + 8
        accountNameLabel.leftAnchor == accountImageView.rightAnchor + 20
        accountNameLabel.rightAnchor == contentView.rightAnchor - 20

        accountAgeLabel.leftAnchor == accountNameLabel.leftAnchor
        accountAgeLabel.topAnchor == accountNameLabel.bottomAnchor

        header.topAnchor == accountAgeLabel.bottomAnchor + 22
        header.horizontalAnchors == contentView.horizontalAnchors + 20

        spinner.centerAnchors == header.centerAnchors

        mailBadge.centerYAnchor == mailButton.centerYAnchor - 10
        mailBadge.centerXAnchor == mailButton.centerXAnchor + 16

        modBadge.centerYAnchor == modButton.centerYAnchor - 10
        modBadge.centerXAnchor == modButton.centerXAnchor + 16

        emptyStateLabel.edgeAnchors == header.edgeAnchors
    }

    func setupActions() {
        closeButton.addTarget(self, action: #selector(didRequestClose), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsButtonPressed), for: .touchUpInside)

        mailButton.addTarget(self, action: #selector(mailButtonPressed), for: .touchUpInside)
        modButton.addTarget(self, action: #selector(modButtonPressed), for: .touchUpInside)
        switchAccountsButton.addTarget(self, action: #selector(switchAccountsButtonPressed), for: .touchUpInside)

        let emptyStateLabelTap = UITapGestureRecognizer(target: self, action: #selector(emptyStateLabelTapped))
        emptyStateLabel.addGestureRecognizer(emptyStateLabelTap)
    }

    func configureForCurrentAccount() {

        updateMailBadge()
        updateModBadge()

        if AccountController.current != nil {
            accountImageView.sd_setImage(with: URL(string: AccountController.current!.image), placeholderImage: UIImage(named: "profile")?.getCopy(withColor: ColorUtil.fontColor), options: [.allowInvalidSSLCertificates]) {[weak self] (image, _, _, _) in
                guard let strongSelf = self else { return }
                strongSelf.accountImageView.image = image
            }
        } else {
            accountImageView.image = UIImage(named: "profile")?.getCopy(withColor: ColorUtil.fontColor)
        }
        setEmptyState(!AccountController.isLoggedIn, animate: true)

        let accountName = SettingValues.nameScrubbing ? "You" : AccountController.currentName.insertingZeroWidthSpacesBeforeCaptials()

        // Populate configurable UI elements here.
        accountNameLabel.attributedText = {
            let paragraphStyle = NSMutableParagraphStyle()
//            paragraphStyle.lineHeightMultiple = 0.8
            return NSAttributedString(
                string: accountName,
                attributes: [
                    NSParagraphStyleAttributeName: paragraphStyle,
                ]
            )
        }()

        modButton.isHidden = !(AccountController.current?.isMod ?? false)

        if let account = AccountController.current {
            let creationDateString: String = {
                let creationDate = NSDate(timeIntervalSince1970: Double(account.created))
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMMMd", options: 0, locale: NSLocale.current)
                return dateFormatter.string(from: creationDate as Date)
            }()
            accountAgeLabel.text = "Created \(creationDateString)"
            header.setAccount(account)
            setLoadingState(false)
        } else {
            print("No account to show!")
        }
    }

    func setLoadingState(_ isOn: Bool) {
        if isOn {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }

        UIView.animate(withDuration: 0.2) {
            self.header.alpha = isOn ? 0 : 1
            self.accountNameLabel.alpha = isOn ? 0 : 1
            self.accountAgeLabel.alpha = isOn ? 0 : 1
            self.upperButtonStack.isUserInteractionEnabled = !isOn
        }
    }

    func setEmptyState(_ isOn: Bool, animate: Bool) {
        func animationBlock() {
            self.upperButtonStack.alpha = isOn ? 0 : 1
            self.upperButtonStack.isUserInteractionEnabled = !isOn

            self.accountNameLabel.alpha = isOn ? 0 : 1
            self.accountAgeLabel.alpha = isOn ? 0 : 1

            self.header.alpha = isOn ? 0 : 1
            self.header.isUserInteractionEnabled = !isOn

            self.emptyStateLabel.alpha = isOn ? 1 : 0
            self.emptyStateLabel.isUserInteractionEnabled = isOn
        }
        if animate {
            UIView.animate(withDuration: 0.2) {
                animationBlock()
            }
        } else {
            animationBlock()
        }
    }

    func updateMailBadge() {
        if let account = AccountController.current {
            mailBadge.isHidden = !account.hasMail
            mailBadge.text = "\(account.inboxCount)"
        } else {
            mailBadge.isHidden = true
            mailBadge.text = ""
        }
    }

    func updateModBadge() {
        if let account = AccountController.current {
            modBadge.isHidden = !account.hasModMail
            // TODO: How do we know the mod mail count?
            modBadge.text = ""
        } else {
            modBadge.isHidden = true
            modBadge.text = ""
        }
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

    @objc func mailButtonPressed(_ sender: UIButton) {
        let vc = InboxViewController()
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.isTranslucent = false
        present(navVC, animated: true)
    }

    @objc func modButtonPressed(_ sender: UIButton) {
        let vc = ModerationViewController()
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.isTranslucent = false
        present(navVC, animated: true)
    }

    @objc func switchAccountsButtonPressed(_ sender: UIButton) {
        showSwitchAccountsMenu()
    }

    @objc func emptyStateLabelTapped() {
        showSwitchAccountsMenu()
    }
}

// MARK: - AccountHeaderViewDelegate
extension CurrentAccountViewController: AccountHeaderViewDelegate {
    func accountHeaderView(_ view: AccountHeaderView, didRequestProfilePageAtIndex index: Int) {
        let vc = ProfileViewController(name: AccountController.currentName)
        vc.openTo = index
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.isTranslucent = false
        present(navVC, animated: true)
    }
}

// MARK: - Account Switching
extension CurrentAccountViewController {
    func showSwitchAccountsMenu() {
        let optionMenu = BottomSheetActionController()
        optionMenu.headerData = "Accounts"

        for accountName in AccountController.names.unique().sorted() {
            if accountName != AccountController.currentName {
                optionMenu.addAction(Action(ActionData(title: "\(accountName)", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { _ in
                    self.setLoadingState(true)
                    self.delegate?.currentAccountViewController(self, didRequestAccountChangeToName: accountName)
                }))
            } else {
                var action = Action(ActionData(title: "\(accountName) (current)", image: UIImage(named: "selected")!.menuIcon().getCopy(withColor: GMColor.green500Color())), style: .default, handler: nil)
                action.enabled = false
                optionMenu.addAction(action)
            }
        }

        if AccountController.isLoggedIn {
            optionMenu.addAction(Action(ActionData(title: "Browse as guest", image: UIImage(named: "hide")!.menuIcon()), style: .default, handler: { _ in
                self.setEmptyState(true, animate: false)
                self.delegate?.currentAccountViewController(self, didRequestGuestAccount: ())
            }))

            optionMenu.addAction(Action(ActionData(title: "Log out", image: UIImage(named: "delete")!.menuIcon().getCopy(withColor: GMColor.red500Color())), style: .default, handler: { _ in
                self.setEmptyState(true, animate: false)
                self.delegate?.currentAccountViewController(self, didRequestLogOut: ())
            }))

        }

        optionMenu.addAction(Action(ActionData(title: "Add a new account", image: UIImage(named: "add")!.menuIcon().getCopy(withColor: ColorUtil.baseColor)), style: .default, handler: { _ in
            self.delegate?.currentAccountViewController(self, didRequestNewAccount: ())
        }))

        present(optionMenu, animated: true, completion: nil)
    }
}

extension CurrentAccountViewController {
    // Called from AccountController when the account changes
    @objc func onAccountChangedNotificationPosted(_ notification: NSNotification) {
        DispatchQueue.main.async {
            self.configureForCurrentAccount()
        }
    }

    @objc func onAccountChangedToGuestNotificationPosted(_ notification: NSNotification) {
        DispatchQueue.main.async {
            self.configureForCurrentAccount()
        }
    }

    @objc func onAccountMailCountChanged(_ notification: NSNotification) {
        DispatchQueue.main.async {
            self.updateMailBadge()
        }
    }
}

// MARK: - Accessibility
extension CurrentAccountViewController {

    override func accessibilityPerformEscape() -> Bool {
        super.accessibilityPerformEscape()
        didRequestClose()
        return true
    }

    override var accessibilityViewIsModal: Bool {
        get {
            return true
        }
        set {}
    }
}

protocol AccountHeaderViewDelegate: AnyObject {
    func accountHeaderView(_ view: AccountHeaderView, didRequestProfilePageAtIndex index: Int)
}

class AccountHeaderView: UIView {

    weak var delegate: AccountHeaderViewDelegate?

    var commentKarmaLabel: UILabel = UILabel().then {
        $0.numberOfLines = 0
        $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
        $0.textAlignment = .center
        $0.textColor = ColorUtil.fontColor
        $0.accessibilityTraits = UIAccessibilityTraitButton
    }
    var postKarmaLabel: UILabel = UILabel().then {
        $0.numberOfLines = 0
        $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
        $0.textAlignment = .center
        $0.textColor = ColorUtil.fontColor
        $0.accessibilityTraits = UIAccessibilityTraitButton
    }

    var savedCell = UITableViewCell().then {
        $0.configure(text: "Saved Posts", imageName: "save", imageColor: GMColor.yellow500Color())
    }

    var likedCell = UITableViewCell().then {
        $0.configure(text: "Liked Posts", imageName: "upvote", imageColor: GMColor.orange500Color())
    }

    var detailsCell = UITableViewCell().then {
        $0.configure(text: "Your profile", imageName: "profile", imageColor: ColorUtil.fontColor)
    }

    var infoStack = UIStackView().then {
        $0.spacing = 8
        $0.axis = .horizontal
        $0.distribution = .equalSpacing
    }

    var cellStack = UIStackView().then {
        $0.spacing = 2
        $0.axis = .vertical
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubviews(infoStack, cellStack)
        infoStack.addArrangedSubviews(commentKarmaLabel, postKarmaLabel)
        cellStack.addArrangedSubviews(savedCell, likedCell, detailsCell)

        self.clipsToBounds = true

        setupAnchors()
        setupActions()

        setAccount(nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAccount(_ account: Account?) {
        commentKarmaLabel.attributedText = {
            let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 16, submission: true)]
            let attributedString = NSMutableAttributedString(string: "\(account?.commentKarma.delimiter ?? "0")", attributes: attrs)
            let subt = NSMutableAttributedString(string: "\nCOMMENT KARMA")
            attributedString.append(subt)
            return attributedString
        }()

        postKarmaLabel.attributedText = {
            let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 16, submission: true)]
            let attributedString = NSMutableAttributedString(string: "\(account?.linkKarma.delimiter ?? "0")", attributes: attrs)
            let subt = NSMutableAttributedString(string: "\nPOST KARMA")
            attributedString.append(subt)
            return attributedString
        }()
    }

    func setupAnchors() {
        infoStack.topAnchor == topAnchor
        infoStack.horizontalAnchors == horizontalAnchors

        cellStack.topAnchor == infoStack.bottomAnchor + 26
        cellStack.horizontalAnchors == horizontalAnchors

        savedCell.heightAnchor == 50
        detailsCell.heightAnchor == 50
        likedCell.heightAnchor == 50

        cellStack.bottomAnchor == bottomAnchor
    }

    func setupActions() {
        savedCell.addTapGestureRecognizer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.accountHeaderView(strongSelf, didRequestProfilePageAtIndex: 4)
        }
        likedCell.addTapGestureRecognizer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.accountHeaderView(strongSelf, didRequestProfilePageAtIndex: 3)
        }
        detailsCell.addTapGestureRecognizer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.accountHeaderView(strongSelf, didRequestProfilePageAtIndex: 0)
        }
        commentKarmaLabel.addTapGestureRecognizer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.accountHeaderView(strongSelf, didRequestProfilePageAtIndex: 2)
        }
        postKarmaLabel.addTapGestureRecognizer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.accountHeaderView(strongSelf, didRequestProfilePageAtIndex: 1)
        }
    }
}

// MARK: - Actions
extension AccountHeaderView {

}

// Styling
private extension UITableViewCell {
    func configure(text: String, imageName: String, imageColor: UIColor) {
        textLabel?.text = text
        imageView?.image = UIImage.init(named: imageName)?.menuIcon()
        imageView?.tintColor = imageColor

        accessoryType = .none
        backgroundColor = ColorUtil.foregroundColor
        textLabel?.textColor = ColorUtil.fontColor
        layer.cornerRadius = 5
        clipsToBounds = true
    }
}
