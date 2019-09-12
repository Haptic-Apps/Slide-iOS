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
import RLBAlertsPickers
import SDCAlertView
import SDWebImage
import Then
import UIKit

protocol CurrentAccountViewControllerDelegate: AnyObject {
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestSettingsMenu: Void)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestAccountChangeToName accountName: String)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestGuestAccount: Void)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestLogOut: Void)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestNewAccount: Void)
    func currentAccountViewController(_ controller: CurrentAccountViewController, goToMultireddit multireddit: String)
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestCacheNow: Void)
}

class CurrentAccountViewController: UIViewController {
    
    weak var delegate: CurrentAccountViewControllerDelegate?
    
    var reportText: String?
    
    var interactionController: CurrentAccountDismissInteraction?
    
    /// Overall height of the content view, including its out-of-bounds elements.
    var contentViewHeight: CGFloat {
        let converted = accountImageView.convert(accountImageView.bounds, to: view)
        return view.frame.maxY - converted.minY
    }
    
    var outOfBoundsHeight: CGFloat {
        let converted = accountImageView.convert(accountImageView.bounds, to: view)
        return contentView.frame.minY - converted.minY
    }
    
    var spinner = UIActivityIndicatorView().then {
        $0.style = UIActivityIndicatorView.Style.whiteLarge
        $0.color = ColorUtil.theme.fontColor
        $0.hidesWhenStopped = true
    }
    
    var contentView = UIView().then {
        $0.backgroundColor = ColorUtil.theme.backgroundColor
        $0.clipsToBounds = false
    }
    
    var backgroundView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    var closeButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "close")!.getCopy(withSize: .square(size: 30), withColor: .white), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 24, right: 24)
        $0.accessibilityLabel = "Close"
    }

    var settingsButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "settings")!.getCopy(withSize: .square(size: 30), withColor: .white), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 16, left: 8, bottom: 8, right: 8)
        $0.accessibilityLabel = "App Settings"
    }
    
    // Outer button stack
    
    var upperButtonStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 0
    }
    var modButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "mod")!.getCopy(withSize: .square(size: 30), withColor: ColorUtil.baseAccent), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 16, left: 8, bottom: 8, right: 8)
        $0.accessibilityLabel = "Mod Queue"
    }
    var mailButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "messages")!.getCopy(withSize: .square(size: 30), withColor: ColorUtil.baseAccent), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 8)
        $0.accessibilityLabel = "Inbox"
    }
    var switchAccountsButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "user")!.getCopy(withSize: .square(size: 30), withColor: ColorUtil.baseAccent), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 16, left: 8, bottom: 8, right: 8)
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
        $0.textColor = ColorUtil.theme.fontColor
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.5
        $0.baselineAdjustment = UIBaselineAdjustment.alignCenters
    }
    
    var accountAgeLabel = UILabel().then {
        $0.font = FontGenerator.fontOfSize(size: 12, submission: false)
        $0.textColor = ColorUtil.theme.fontColor
        $0.numberOfLines = 1
        $0.text = ""
    }
    
    var accountImageView = UIImageView().then {
        $0.backgroundColor = ColorUtil.theme.foregroundColor
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
        $0.textColor = ColorUtil.theme.fontColor
        $0.textAlignment = .center
        $0.attributedText = {
            var font = UIFont.boldSystemFont(ofSize: 20)
            let attributedString = NSMutableAttributedString.init(string: "You are logged out.\n", attributes: [NSAttributedString.Key.font: font])
            attributedString.append(NSMutableAttributedString.init(string: "Tap here to sign in!", attributes: [NSAttributedString.Key.font: font.makeBold()]))
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
    
    var setStyle: UIStatusBarStyle = .default {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return setStyle
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Focus the account label
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: accountNameLabel)
        
        updateMailBadge()
        updateModBadge()
        setStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        setStyle = SettingValues.reduceColor && ColorUtil.theme.isLight ? .default : .lightContent
    }
}

// MARK: - Setup
extension CurrentAccountViewController {
    func setupViews() {
        
        view.addSubview(backgroundView)
        
        view.addSubview(closeButton)
        
        view.addSubview(upperButtonStack)
        upperButtonStack.addArrangedSubviews(mailButton, modButton, switchAccountsButton, UIView(), settingsButton)
        
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
        
        backgroundView.edgeAnchors == view.edgeAnchors
        
        if #available(iOS 11, *) {
            closeButton.topAnchor == view.safeTopAnchor
            closeButton.leftAnchor == view.safeLeftAnchor
            
            settingsButton.rightAnchor == view.safeRightAnchor
        } else {
            closeButton.topAnchor == view.safeTopAnchor + 24
            closeButton.leftAnchor == view.safeLeftAnchor
            
            settingsButton.rightAnchor == view.safeRightAnchor
        }
        
        upperButtonStack.leftAnchor == accountImageView.rightAnchor
        upperButtonStack.bottomAnchor == contentView.topAnchor
        
        contentView.horizontalAnchors == view.horizontalAnchors
        contentView.bottomAnchor == view.bottomAnchor
        
        accountImageView.leftAnchor == contentView.safeLeftAnchor + 20
        accountImageView.centerYAnchor == contentView.topAnchor
        accountImageView.sizeAnchors == CGSize.square(size: 100)
        
        accountNameLabel.topAnchor == contentView.topAnchor + 8
        accountNameLabel.leftAnchor == accountImageView.rightAnchor + 20
        accountNameLabel.rightAnchor == contentView.rightAnchor - 20
        
        accountAgeLabel.leftAnchor == accountNameLabel.leftAnchor
        accountAgeLabel.topAnchor == accountNameLabel.bottomAnchor
        
        header.topAnchor == accountAgeLabel.bottomAnchor + 22
        header.horizontalAnchors == contentView.safeHorizontalAnchors + 20
        header.bottomAnchor == contentView.safeBottomAnchor - 16
        
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
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(didRequestClose))
        backgroundView.addGestureRecognizer(recognizer)
    }
    
    func configureForCurrentAccount() {
        
        updateMailBadge()
        updateModBadge()
        
        if AccountController.current != nil {
            accountImageView.sd_setImage(with: URL(string: AccountController.current!.image.decodeHTML()), placeholderImage: UIImage(named: "profile")?.getCopy(withColor: ColorUtil.theme.fontColor), options: [.allowInvalidSSLCertificates]) {[weak self] (image, _, _, _) in
                guard let strongSelf = self else { return }
                strongSelf.accountImageView.image = image
            }
        } else {
            accountImageView.image = UIImage(named: "profile")?.getCopy(withColor: ColorUtil.theme.fontColor)
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
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                ]
            )
        }()
        
        accountNameLabel.addTapGestureRecognizer {
            [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.accountHeaderView(strongSelf.header, didRequestProfilePageAtIndex: 0)
        }
        
        modButton.isHidden = !(AccountController.current?.isMod ?? false)
        
        if let account = AccountController.current {
            let creationDate = NSDate(timeIntervalSince1970: Double(account.created))
            let creationDateString: String = {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMMMd", options: 0, locale: NSLocale.current)
                return dateFormatter.string(from: creationDate as Date)
            }()
            let day = Calendar.current.ordinality(of: .day, in: .month, for: Date()) == Calendar.current.ordinality(of: .day, in: .month, for: creationDate as Date)
            let month = Calendar.current.ordinality(of: .month, in: .year, for: Date()) == Calendar.current.ordinality(of: .month, in: .year, for: creationDate as Date)
            if day && month {
                accountAgeLabel.text = "🍰 Created \(creationDateString) 🍰"
            } else {
                accountAgeLabel.text = "Created \(creationDateString)"
            }
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
            self.mailButton.alpha = isOn ? 0 : 1
            self.modButton.alpha = isOn ? 0 : 1
            self.switchAccountsButton.alpha = isOn ? 0 : 1

            self.mailButton.isUserInteractionEnabled = !isOn
            self.modButton.isUserInteractionEnabled = !isOn
            self.switchAccountsButton.isUserInteractionEnabled = !isOn
            
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

    @objc func cacheButtonPressed() {
        self.dismiss(animated: true)
        self.delegate?.currentAccountViewController(self, didRequestCacheNow: ())
    }

    @objc func multiButtonPressed() {
        let alert = DragDownAlertMenu(title: "Create a new Multireddit", subtitle: "Name your  Multireddit", icon: nil)
        
        alert.addTextInput(title: "Create", icon: UIImage(named: "add")?.menuIcon(), enabled: true, action: {
            var text = alert.getText() ?? ""
            text = text.replacingOccurrences(of: " ", with: "_")
            if text == "" {
                let alert = AlertController(attributedTitle: nil, attributedMessage: nil, preferredStyle: .alert)
                alert.setupTheme()
                alert.attributedTitle = NSAttributedString(string: "Name cannot be empty!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
                alert.addAction(AlertAction(title: "Ok", style: .normal, handler: { (_) in
                    self.multiButtonPressed()
                }))
                return
            }
            do {
                try (UIApplication.shared.delegate as! AppDelegate).session?.createMultireddit(text, descriptionMd: "", completion: { (result) in
                    switch result {
                    case .success(let multireddit):
                        DispatchQueue.main.async {
                            VCPresenter.presentModally(viewController: ManageMultireddit(multi: multireddit, reloadCallback: {
                            }, dismissCallback: {
                                Subscriptions.subscribe("/m/" + text, false, session: nil)
                                self.dismiss(animated: true, completion: {
                                    self.delegate?.currentAccountViewController(self, goToMultireddit: "/m/" + text)
                                })
                            }), self)
                        }
                    case .failure(_):
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Error creating Multireddit, try again later", color: GMColor.red500Color(), seconds: 3, context: self)
                        }
                    }
                })
            } catch {
                DispatchQueue.main.async {
                    BannerUtil.makeBanner(text: "Error creating Multireddit, try again later", color: GMColor.red500Color(), seconds: 3, context: self.parent)
                }
            }

        }, inputPlaceholder: "Name...", inputValue: nil, inputIcon: UIImage(named: "wiki")!.menuIcon(), textRequired: true, exitOnAction: false)
        
        alert.show(self)
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
    func didRequestCache() {
        self.cacheButtonPressed()
    }
    
    func didRequestNewMulti() {
        self.multiButtonPressed()
    }
    
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
        let optionMenu = DragDownAlertMenu(title: "Accounts", subtitle: "Currently signed in as \(AccountController.isLoggedIn ? AccountController.currentName : "Guest")", icon: nil)

        for accountName in AccountController.names.unique().sorted() {
            if accountName != AccountController.currentName {
                optionMenu.addAction(title: accountName, icon: UIImage(named: "profile")!.menuIcon()) {
                    self.setLoadingState(true)
                    self.delegate?.currentAccountViewController(self, didRequestAccountChangeToName: accountName)
                }
            } else {
                //todo enabled
                optionMenu.addAction(title: "\(accountName) (current)", icon: UIImage(named: "selected")!.menuIcon().getCopy(withColor: GMColor.green500Color())) {
                }
            }
        }
        
        if AccountController.isLoggedIn {
            optionMenu.addAction(title: "Browse as Guest", icon: UIImage(named: "hide")!.menuIcon()) {
                self.setEmptyState(true, animate: false)
                self.delegate?.currentAccountViewController(self, didRequestGuestAccount: ())
            }

            optionMenu.addAction(title: "Log out of u/\(AccountController.currentName)", icon: UIImage(named: "delete")!.menuIcon().getCopy(withColor: GMColor.red500Color())) {
                self.setEmptyState(true, animate: false)
                self.delegate?.currentAccountViewController(self, didRequestLogOut: ())
            }
        }
        
        optionMenu.addAction(title: "Add a new account", icon: UIImage(named: "add")!.menuIcon().getCopy(withColor: ColorUtil.baseColor)) {
            self.delegate?.currentAccountViewController(self, didRequestNewAccount: ())
        }
        
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
    func didRequestCache()
    func didRequestNewMulti()
}

class AccountHeaderView: UIView {
    
    weak var delegate: AccountHeaderViewDelegate?
    
    var commentKarmaLabel: UILabel = UILabel().then {
        $0.numberOfLines = 0
        $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
        $0.textAlignment = .center
        $0.textColor = ColorUtil.theme.fontColor
        $0.accessibilityTraits = UIAccessibilityTraits.button
    }
    var postKarmaLabel: UILabel = UILabel().then {
        $0.numberOfLines = 0
        $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
        $0.textAlignment = .center
        $0.textColor = ColorUtil.theme.fontColor
        $0.accessibilityTraits = UIAccessibilityTraits.button
    }
    
    var savedCell = UITableViewCell().then {
        $0.configure(text: "Saved Posts", imageName: "save", imageColor: GMColor.yellow500Color())
    }

    var cacheCell = UITableViewCell().then {
        $0.configure(text: "Start Auto Cache now", imageName: "save-1", imageColor: GMColor.yellow500Color())
    }

    var multiCell = UITableViewCell().then {
        $0.configure(text: "Create a Multireddit", imageName: "add", imageColor: GMColor.yellow500Color())
    }

    var likedCell = UITableViewCell().then {
        $0.configure(text: "Liked Posts", imageName: "upvote", imageColor: GMColor.orange500Color())
    }
    
    var detailsCell = UITableViewCell().then {
        $0.configure(text: "Your profile", imageName: "profile", imageColor: ColorUtil.theme.fontColor)
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
        cellStack.addArrangedSubviews(savedCell, likedCell, detailsCell, multiCell, cacheCell)
        
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
            let attrs = [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 16, submission: true)]
            let attributedString = NSMutableAttributedString(string: "\(account?.commentKarma.delimiter ?? "0")", attributes: attrs)
            let subt = NSMutableAttributedString(string: "\nCOMMENT KARMA")
            attributedString.append(subt)
            return attributedString
        }()
        
        postKarmaLabel.attributedText = {
            let attrs = [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 16, submission: true)]
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
        cacheCell.heightAnchor == 50
        multiCell.heightAnchor == 50
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
        multiCell.addTapGestureRecognizer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.didRequestNewMulti()
        }
        cacheCell.addTapGestureRecognizer { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.didRequestCache()
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
        imageView?.image = UIImage(named: imageName)?.menuIcon()
        imageView?.tintColor = imageColor
        
        accessoryType = .none
        backgroundColor = ColorUtil.theme.foregroundColor
        textLabel?.textColor = ColorUtil.theme.fontColor
        layer.cornerRadius = 5
        clipsToBounds = true
    }
}
