//
//  ProfileInfoViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/15/19.
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

class ProfileInfoViewController: UIViewController {
    
    var user: Account?
    weak var profile: UIViewController?
    var interactionController: ProfileInfoDismissInteraction?
    
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
        $0.setImage(UIImage(sfString: SFSymbol.xmark, overrideString: "close")!.getCopy(withSize: .square(size: 30), withColor: .white), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 24, right: 24)
        $0.accessibilityLabel = "Close"
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
    
    var header = ProfileHeaderView()
    var account: String
    
    init(accountNamed: String, parent: UIViewController) {
        self.account = accountNamed
        self.profile = parent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupConstraints()
        setupActions()
                
        interactionController = ProfileInfoDismissInteraction(viewController: self)
        
        configureForAccount(named: account)
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
        
        setStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        setStyle = SettingValues.reduceColor && ColorUtil.theme.isLight ? .default : .lightContent
    }
}

// MARK: - Setup
extension ProfileInfoViewController {
    func setupViews() {
        
        view.addSubview(backgroundView)
        
        view.addSubview(closeButton)

        view.addSubview(contentView)
        contentView.addSubview(accountImageView)
        contentView.addSubview(accountNameLabel)
        contentView.addSubview(accountAgeLabel)
        
        contentView.addSubview(header)
        header.delegate = self
                
        contentView.addSubview(spinner)
        
    }
    
    func setupConstraints() {
        
        backgroundView.edgeAnchors /==/ view.edgeAnchors
        
        if #available(iOS 11, *) {
            closeButton.topAnchor /==/ view.safeTopAnchor
            closeButton.leftAnchor /==/ view.safeLeftAnchor
            
        } else {
            closeButton.topAnchor /==/ view.safeTopAnchor + 24
            closeButton.leftAnchor /==/ view.safeLeftAnchor
        }
                
        contentView.horizontalAnchors /==/ view.horizontalAnchors
        contentView.bottomAnchor /==/ view.bottomAnchor
        
        accountImageView.leftAnchor /==/ contentView.safeLeftAnchor + 20
        accountImageView.centerYAnchor /==/ contentView.topAnchor
        accountImageView.sizeAnchors /==/ CGSize.square(size: 100)
        
        accountNameLabel.topAnchor /==/ contentView.topAnchor + 8
        accountNameLabel.leftAnchor /==/ accountImageView.rightAnchor + 20
        accountNameLabel.rightAnchor /==/ contentView.rightAnchor - 20
        
        accountAgeLabel.leftAnchor /==/ accountNameLabel.leftAnchor
        accountAgeLabel.topAnchor /==/ accountNameLabel.bottomAnchor
        
        header.topAnchor /==/ accountAgeLabel.bottomAnchor + 22
        header.horizontalAnchors /==/ contentView.safeHorizontalAnchors + 20
        header.bottomAnchor /==/ contentView.safeBottomAnchor - 16
        
        spinner.centerAnchors /==/ header.centerAnchors
    }
    
    func setupActions() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(didRequestClose))
        backgroundView.addGestureRecognizer(recognizer)
    }
    
    func generateButtons(trophy: Trophy) -> UIView {
        let baseView = UIView()
        let more = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        more.sd_setImage(with: trophy.icon70!)
        
        let subtitle = UILabel().then {
            $0.textColor = ColorUtil.theme.fontColor
            $0.font = UIFont.systemFont(ofSize: 10)
            $0.text = trophy.title
            $0.numberOfLines = 0
            $0.textAlignment = .center
        }
        
        baseView.addSubview(more)
        baseView.addSubview(subtitle)
        
        more.horizontalAnchors /==/ baseView.horizontalAnchors + 10
        more.heightAnchor /==/ 50
        more.topAnchor /==/ baseView.topAnchor
        more.widthAnchor /==/ 50
        subtitle.heightAnchor /==/ 15
        subtitle.horizontalAnchors /==/ baseView.horizontalAnchors
        subtitle.topAnchor /==/ more.bottomAnchor + 5
        subtitle.widthAnchor /==/ 70
        
        baseView.isUserInteractionEnabled = true
        return baseView
    }

    func getTrophies(_ user: Account) {
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.getTrophies(user.name, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let trophies):
                    var i = 0
                    DispatchQueue.main.async {
                        for trophy in trophies {
                            let b = self.generateButtons(trophy: trophy)
                            b.sizeAnchors /==/ CGSize(width: 70, height: 70)
                            b.addTapGestureRecognizer(action: { _ in
                                if trophy.url != nil {
                                    var trophyURL = trophy.url!.absoluteString
                                    if !trophyURL.contains("reddit.com") {
                                        trophyURL = "https://www.reddit.com" + trophyURL
                                    }
                                    VCPresenter.presentModally(viewController: WebsiteViewController(url: URL(string: trophyURL) ?? trophy.url!, subreddit: ""), self, nil)
                                }
                            })
                            self.header.trophyArea.addSubview(b)
                            b.leftAnchor /==/ self.header.trophyArea.leftAnchor + CGFloat(i * 75)
                            i += 1
                        }
                        if trophies.isEmpty {
                            let empty = UILabel(frame: CGRect(x: 0, y: 0, width: self.header.trophyArea.frame.size.width, height: 70))
                            empty.font = UIFont.boldSystemFont(ofSize: 14)
                            empty.textAlignment = .center
                            empty.text = "No trophies"
                            self.header.trophyArea.addSubview(empty)
                            self.header.trophyArea.contentSize = CGSize.init(width: self.header.trophyArea.frame.size.width, height: 70)
                        } else {
                            self.header.trophyArea.contentSize = CGSize.init(width: i * 75, height: 70)
                        }
                    }
                }
            })

        } catch {
            
        }
    }
    
    func configureForAccount(named: String) {
        setLoadingState(true)
        
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.getUserProfile(named, completion: { (result) in
                switch result {
                case .failure(_):
                   // TODO: - handle this
                    break
                case .success(let account):
                    self.user = account
                    DispatchQueue.main.async {
                        self.getTrophies(account)
                        if self.user != nil {
                            self.accountImageView.sd_setImage(with: URL(string: self.user!.image.decodeHTML()), placeholderImage: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")?.getCopy(withColor: ColorUtil.theme.fontColor), options: [.allowInvalidSSLCertificates]) {[weak self] (image, _, _, _) in
                                guard let strongSelf = self else { return }
                                strongSelf.accountImageView.image = image
                            }
                        } else {
                            self.accountImageView.image = UIImage(sfString: SFSymbol.personFill, overrideString: "profile")?.getCopy(withColor: ColorUtil.theme.fontColor)
                        }
                        
                        let accountName = self.user!.name.insertingZeroWidthSpacesBeforeCaptials()
                        
                        // Populate configurable UI elements here.
                        self.accountNameLabel.attributedText = {
                            let paragraphStyle = NSMutableParagraphStyle()
                            //            paragraphStyle.lineHeightMultiple = 0.8
                            return NSAttributedString(
                                string: accountName,
                                attributes: [
                                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                                ]
                            )
                        }()
                                
                        if let account = self.user {
                            let creationDate = NSDate(timeIntervalSince1970: Double(account.created))
                            let creationDateString: String = {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMMMd", options: 0, locale: NSLocale.current)
                                return dateFormatter.string(from: creationDate as Date)
                            }()
                            let day = Calendar.current.ordinality(of: .day, in: .month, for: Date()) == Calendar.current.ordinality(of: .day, in: .month, for: creationDate as Date)
                            let month = Calendar.current.ordinality(of: .month, in: .year, for: Date()) == Calendar.current.ordinality(of: .month, in: .year, for: creationDate as Date)
                            if day && month {
                                self.accountAgeLabel.text = "🍰 Created \(creationDateString) 🍰"
                            } else {
                                self.accountAgeLabel.text = "Created \(creationDateString)"
                            }
                            self.header.setAccount(account)
                            self.setLoadingState(false)
                        } else {
                            print("No account to show!")
                        }
                    }
                }
            })
        } catch {
            
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
        }
    }
    
}

extension ProfileInfoViewController: ProfileHeaderViewDelegate {
    func didRequestPrivateMessage() {
        if user == nil {
            return
        }
        VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(name: user!.name, completion: { (_) in })), parentVC: self)

    }
    
    func didRequestRemoveFriend() {
        if user == nil {
            return
        }

        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.unfriend(user!.name, completion: { (_) in
                DispatchQueue.main.async {
                    BannerUtil.makeBanner(text: "Unfriended u/\(self.user!.name)", seconds: 3, context: self)
                }
            })
        } catch {
            
        }
    }
    
    func didRequestAddFriend() {
        if user == nil {
            return
        }

        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.friend(user!.name, completion: { (result) in
                if result.error != nil {
                    print(result.error!)
                }
                DispatchQueue.main.async {
                    BannerUtil.makeBanner(text: "Friended u/\(self.user!.name)", seconds: 3, context: self)
                }
            })
        } catch {
            
        }
    }
    
    func didRequestSetColor() {
        if let profile = profile as? ProfileViewController {
            self.dismiss(animated: true) {
                profile.pickColor(sender: self)
            }
        }
    }
    
    func didRequestEditTag() {
        if let profile = profile as? ProfileViewController {
            self.dismiss(animated: true) {
                profile.tagUser()
            }
        }
    }
}

// MARK: - Actions
extension ProfileInfoViewController {
    @objc func didRequestClose() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func privateMessage(_ sender: UIButton) {
        self.present(ReplyViewController(name: user!.name, completion: { (_) in
            
        }), animated: true)
    }

    @objc func colorChangeRequested() {
        // TODO: - this
        
    }

    @objc func tagUserRequested() {
       // TODO: - this
    }

    @objc func friendRequested(_ sender: UIButton) {
       // TODO: - this
    }
    
    @objc func unfreindRequested(_ sender: UIButton) {
       // TODO: - this
    }
}

// MARK: - Accessibility
extension ProfileInfoViewController {
    
    override func accessibilityPerformEscape() -> Bool {
        super.accessibilityPerformEscape()
        didRequestClose()
        return true
    }
    
    override var accessibilityViewIsModal: Bool {
        get {
            return true
        }
        set { } // swiftlint:disable:this unused_setter_value
    }
}

protocol ProfileHeaderViewDelegate: AnyObject {
    func didRequestPrivateMessage()
    func didRequestRemoveFriend()
    func didRequestAddFriend()
    func didRequestSetColor()
    func didRequestEditTag()
}

class ProfileHeaderView: UIView {
    
    weak var delegate: ProfileHeaderViewDelegate?
    
    var commentKarmaLabel: UILabel = UILabel().then {
        $0.numberOfLines = 0
        $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
        $0.textAlignment = .center
        $0.textColor = ColorUtil.theme.fontColor
        $0.accessibilityTraits = UIAccessibilityTraits.button
    }
    
    var trophyArea: UIScrollView = UIScrollView().then {
        $0.backgroundColor = .clear
        
    }
    var postKarmaLabel: UILabel = UILabel().then {
        $0.numberOfLines = 0
        $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
        $0.textAlignment = .center
        $0.textColor = ColorUtil.theme.fontColor
        $0.accessibilityTraits = UIAccessibilityTraits.button
    }
    
    var messageCell = UITableViewCell().then {
        $0.configure(text: "Private Message", imageName: "inbox", sfSymbolName: .envelopeFill, imageColor: GMColor.yellow500Color())
    }

    var user: Account?

    var friendCell = UITableViewCell()

    var colorCell = UITableViewCell().then {
        $0.configure(text: "Set user color", imageName: "add", sfSymbolName: .eyedropperFull, imageColor: GMColor.yellow500Color())
    }

    //let tag = ColorUtil.getTagForUser(name: user.name)
    var tagCell = UITableViewCell().then {
        //\((tag != nil) ? " (currently \(tag!))" : "")"
        $0.configure(text: "Tag user", imageName: "flag", sfSymbolName: .tagFill, imageColor: GMColor.orange500Color())
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
        
        addSubviews(infoStack, trophyArea, cellStack)
        infoStack.addArrangedSubviews(commentKarmaLabel, postKarmaLabel)
        cellStack.addArrangedSubviews(messageCell, friendCell, colorCell, tagCell)
        
        self.clipsToBounds = true
        
        setupAnchors()
        setupActions()
        
        setAccount(nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setAccount(_ account: Account?) {
        if account == nil {
            return
        }
        self.user = account
        commentKarmaLabel.attributedText = {
            let attrs = [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 16, submission: true)]
            let attributedString = NSMutableAttributedString(string: "\(account?.commentKarma.delimiter ?? "0")", attributes: attrs)
            let subt = NSMutableAttributedString(string: "\nCOMMENT KARMA")
            attributedString.append(subt)
            return attributedString
        }()
        
        self.friendCell.configure(text: account?.isFriend ?? false ? "Remove friend" : "Add friend", imageName: "profile", sfSymbolName: account?.isFriend ?? false ? SFSymbol.personBadgeMinusFill : SFSymbol.personBadgePlusFill, imageColor: GMColor.yellow500Color())
        
        postKarmaLabel.attributedText = {
            let attrs = [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 16, submission: true)]
            let attributedString = NSMutableAttributedString(string: "\(account?.linkKarma.delimiter ?? "0")", attributes: attrs)
            let subt = NSMutableAttributedString(string: "\nPOST KARMA")
            attributedString.append(subt)
            return attributedString
        }()
    }
    
    func setupAnchors() {
        infoStack.topAnchor /==/ topAnchor
        infoStack.horizontalAnchors /==/ horizontalAnchors
        
        trophyArea.topAnchor /==/ infoStack.bottomAnchor + 25
        trophyArea.heightAnchor /==/ 70
        trophyArea.horizontalAnchors /==/ horizontalAnchors + 8
        
        cellStack.topAnchor /==/ trophyArea.bottomAnchor + 26
        cellStack.horizontalAnchors /==/ horizontalAnchors
        
        messageCell.heightAnchor /==/ 50
        friendCell.heightAnchor /==/ 50
        tagCell.heightAnchor /==/ 50
        colorCell.heightAnchor /==/ 50
        
        cellStack.bottomAnchor /==/ bottomAnchor
    }
    
    func setupActions() {
        friendCell.addTapGestureRecognizer { [weak self] (_) in
            guard let strongSelf = self else { return }
            if strongSelf.user?.isFriend ?? false {
                strongSelf.delegate?.didRequestRemoveFriend()
            } else {
                strongSelf.delegate?.didRequestAddFriend()
            }
        }
        messageCell.addTapGestureRecognizer { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.didRequestPrivateMessage()
        }
        colorCell.addTapGestureRecognizer { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.didRequestSetColor()
        }
        tagCell.addTapGestureRecognizer { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.didRequestEditTag()
        }
    }
}
