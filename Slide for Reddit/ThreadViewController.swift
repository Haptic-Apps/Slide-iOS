//
//  ThreadViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 2/10/21.
//  Copyright © 2021 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import UIKit

class ThreadViewControler: MediaViewController, UICollectionViewDelegate, WrappingFlowLayoutDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UINavigationControllerDelegate {
    
    weak var profilePresentationManager: ProfileInfoPresentationManager?
    
    var longBlocking = false
    
    func getTableView() -> UICollectionView {
        return self.tableView
    }
    
    func headerOffset() -> Int {
        return 0
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if UIColor.isLightTheme && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }
    
    var baseData: SingleMessageContributionLoader
    var tableView: UICollectionView!
    var loaded = false
    
    init(threadID: String, title: String) {
        self.baseData = SingleMessageContributionLoader(threadID: threadID)

        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: ""))
        self.baseData.delegate = self
        
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func failed(error: Error) {
        print(error.localizedDescription)
        loaded = true
        loading = false
        DispatchQueue.main.async {
            self.emptyStateView.isHidden = false
            self.endAndResetRefresh()
        }
    }
    
    @objc func drefresh(_ sender: AnyObject) {
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        self.navigationController?.delegate = self
        
        if !loaded && !loading {
            self.tableView.contentOffset = CGPoint(x: 0, y: -(self.refreshControl?.frame.size.height ?? 0))
            refreshControl?.beginRefreshing()
        } else {
            self.tableView.reloadData()
        }
    }
    
    func updateToolbar() {
        navigationController?.setToolbarHidden(false, animated: false)

        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        var items: [UIBarButtonItem] = []
        items.append(space)
        
        var replyTo = AccountController.currentName //Fallback if no replies have been sent by other user
        if let last = self.baseData.content.last(where: { $0.author != AccountController.currentName }) {
            replyTo = last.author
        } else if let last = self.baseData.content.last {
            replyTo = last.author
        }
        
        let loadFullThreadButton = UIBarButtonItem.init(title: "Reply to u/\(replyTo)", style: .plain, target: self, action: #selector(sendReply))
        loadFullThreadButton.accessibilityLabel = "Reply"
        items.append(loadFullThreadButton)
        items.append(space)

        self.navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = false
        
        toolbarItems = items
        navigationController?.toolbar.barTintColor = UIColor.backgroundColor
        navigationController?.toolbar.tintColor = UIColor.fontColor
    }
    
    @objc func sendReply() {
        if let message = self.baseData.content.last(where: { $0.author != AccountController.currentName }) ?? self.baseData.content.last {
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(message: message, completion: {(_) in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.baseData.getData(reload: false)
                })
            })), parentVC: self)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !loading && !loaded {
            refresh()
        }
        
        setupBaseBarColors()
    }
    
    var flowLayout: WrappingFlowLayout = WrappingFlowLayout.init()
    var emptyStateView = EmptyStateView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseBarColors()
        
        flowLayout.delegate = self
        self.tableView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        self.view = UIView.init(frame: CGRect.zero)
        self.view.addSubview(tableView)
        tableView.verticalAnchors /==/ view.verticalAnchors
        tableView.horizontalAnchors /==/ view.safeHorizontalAnchors
                
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        if !UIApplication.shared.isMac() {
            refreshControl = UIRefreshControl()
            refreshControl?.tintColor = UIColor.fontColor
            
            refreshControl?.attributedTitle = NSAttributedString(string: "")
            refreshControl?.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControl.Event.valueChanged)
            tableView.addSubview(refreshControl!)
            refreshControl!.centerAnchors /==/ tableView.centerAnchors
        }
        
        tableView.alwaysBounceVertical = true
        
        self.tableView.register(BannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "banner")
        self.tableView.register(AutoplayBannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "autoplay")
        self.tableView.register(ThumbnailLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb")
        self.tableView.register(TextLinkCellView.classForCoder(), forCellWithReuseIdentifier: "text")
        self.tableView.register(CommentCellView.classForCoder(), forCellWithReuseIdentifier: "comment")
        self.tableView.register(MessageCellView.classForCoder(), forCellWithReuseIdentifier: "message")
        self.tableView.register(ModlogCellView.classForCoder(), forCellWithReuseIdentifier: "modlog")
        self.tableView.register(FriendCellView.classForCoder(), forCellWithReuseIdentifier: "friend")
        tableView.backgroundColor = UIColor.backgroundColor
        
        self.tableView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 65, right: 0)
        
        self.view.addSubview(emptyStateView)

        emptyStateView.setText(title: "Nothing to see here!", message: "No messages were found.")

        emptyStateView.isHidden = true
        emptyStateView.edgeAnchors /==/ self.tableView.edgeAnchors
        self.view.bringSubviewToFront(emptyStateView)
        
        flowLayout.reset(modal: presentingViewController != nil, vc: self, isGallery: false)
        tableView.reloadData()
    }
    
    var oldsize = CGFloat(0)
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.view.bounds.width != oldsize {
            oldsize = self.view.bounds.width
            flowLayout.reset(modal: presentingViewController != nil, vc: self, isGallery: false)
            tableView.reloadData()
        }
    }
        
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        oldsize = self.view.bounds.width
        coordinator.animate(
            alongsideTransition: { [unowned self] _ in
                self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: false)
                self.view.setNeedsLayout()
            }, completion: nil
        )
    }
    
    var tC: UIViewController?
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return baseData.content.count
    }
    
    func collectionView(_ tableView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let thing = baseData.content[indexPath.row]
        var cell: UICollectionViewCell?
        // Show message cell
        let c = tableView.dequeueReusableCell(withReuseIdentifier: "message", for: indexPath) as! MessageCellView
        c.delegate = self
        c.textDelegate = self
        c.state = .IN_THREAD
        c.colorMessage = thing.author == AccountController.currentName

        c.setMessage(message: thing, width: self.view.frame.size.width)
        cell = c
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is AutoplayBannerLinkCellView {
            (cell as! AutoplayBannerLinkCellView).doLoadVideo()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, width: CGFloat, indexPath: IndexPath) -> CGSize {
        let itemWidth = width
        
        if indexPath.row < baseData.content.count {
            let message = baseData.content[indexPath.row]
            
            if estimatedHeights[message.id] == nil {
                let titleText = MessageCellView.getTitleText(message: message, state: .IN_THREAD)
                let height = TextDisplayStackView.estimateHeight(fontSize: 16, submission: true, width: itemWidth - 12, titleString: titleText, htmlString: message.htmlBody)
                
                estimatedHeights[message.id] = height + 16
            }

            return CGSize(width: itemWidth, height: estimatedHeights[message.id]!)
        }
        return CGSize(width: itemWidth, height: 90)
    }
    
    var estimatedHeights: [String: CGFloat] = [:]
    
    var showing = false
    
    func showLoader() {
        showing = true
       // TODO: - maybe add this later
    }
    
    var refreshControl: UIRefreshControl?
    
    func refresh() {
        loading = true
        emptyStateView.isHidden = true
        baseData.reset()
        refreshControl?.beginRefreshing()
        flowLayout.reset(modal: presentingViewController != nil, vc: self, isGallery: false)
        flowLayout.invalidateLayout()
        tableView.reloadData()
        baseData.getData(reload: true)
    }
    
    func loadMore() {
        if loading || !loaded {
            return
        }
        if !showing {
            showLoader()
        }
        loading = true
        baseData.getData(reload: false)
    }
        
    func endAndResetRefresh() {
        if UIApplication.shared.isMac() {
            return
        }
        self.refreshControl?.endRefreshing()
        self.refreshControl?.removeFromSuperview()
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.tintColor = UIColor.fontColor
        
        self.refreshControl?.attributedTitle = NSAttributedString(string: "")
        self.refreshControl?.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(self.refreshControl!)
    }
    
    var loading: Bool = false

}

extension ThreadViewControler: SingleMessageContributionLoaderDelegate {
    func doneLoading(before: Int) {
        loading = false
        loaded = true
        DispatchQueue.main.async {
            // If there is no data after loading, show the empty state view.
            if self.baseData.content.count == 0 {
                self.emptyStateView.isHidden = false
            } else {
                self.updateToolbar()
                self.title = self.baseData.content.first?.subject
                self.emptyStateView.isHidden = true
            }
            
            if before == 0 || before > self.baseData.content.count {
                self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: false)
                self.tableView.reloadData()
                
                var top = CGFloat(0)
                if #available(iOS 11, *) {
                    top += 22
                }
                
                // New xcode is complaining about computation times...
                let totalOffset = (-1 * (self.navigationController?.navigationBar.frame.size.height ?? 64))
                self.tableView.contentOffset = CGPoint.init(x: 0, y: -18 + totalOffset - top)
            } else {
                var paths = [IndexPath]()
                for i in before..<self.baseData.content.count {
                    paths.append(IndexPath.init(item: i, section: 0))
                }
                
                self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: false)
                self.tableView.insertItems(at: paths)
            }
            
            if self.baseData.content.count > 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.tableView.scrollToItem(at: IndexPath(row: self.baseData.content.count - 1, section: 0), at: .bottom, animated: true)
                }
            }

            self.endAndResetRefresh()
        }
        self.loading = false

    }
    
    func failedLoading() {
        
    }
}

extension ThreadViewControler: TextDisplayStackViewDelegate {
    func linkTapped(url: URL, text: String) {
        if !text.isEmpty {
            self.showSpoiler(text)
        } else {
            self.doShow(url: url, heroView: nil, finalSize: nil, heroVC: nil, link: SubmissionObject())
        }
    }

    func linkLongTapped(url: URL) {
        longBlocking = true
        
        let alertController = DragDownAlertMenu(title: "Link options", subtitle: url.absoluteString, icon: url.absoluteString)
        
        alertController.addAction(title: "Share URL", icon: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")!.menuIcon()) {
            let shareItems: Array = [url]
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
        }
        
        alertController.addAction(title: "Copy URL", icon: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()) {
            UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
            BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self)
        }
        
        alertController.addAction(title: "Open in default app", icon: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alertController.addAction(title: "Open in Chrome", icon: UIImage(named: "world")!.menuIcon()) {
                open.openInChrome(url, callbackURL: nil, createNewTab: true)
            }
        }
        
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionStrong()
        } else if SettingValues.hapticFeedback {
            AudioServicesPlaySystemSound(1519)
        }
        
        alertController.show(self)
    }
    
    func previewProfile(profile: String) {
        let vc = ProfileInfoViewController(accountNamed: profile)
        vc.modalPresentationStyle = .custom
        let presentation = ProfileInfoPresentationManager()
        self.profilePresentationManager = presentation
        vc.transitioningDelegate = presentation
        self.present(vc, animated: true)
    }
}

extension ThreadViewControler: MessageCellViewDelegate {
    func showThread(id: String, title: String) {
        VCPresenter.showVC(viewController: ThreadViewControler(threadID: id, title: title), popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
    }
    
    func doReply(to message: MessageObject, cell: MessageCellView) {
        if !ActionStates.isRead(s: message) {
            let session = (UIApplication.shared.delegate as! AppDelegate).session
            do {
                try session?.markMessagesAsRead([message.name.contains("_") ? message.name : (message.wasComment ? "t1_" : "t4_") + message.name], completion: { (result) in
                    if result.error != nil {
                        print(result.error!.description)
                    } else {
                        NotificationCenter.default.post(name: .accountRefreshRequested, object: nil, userInfo: nil)
                    }
                })
            } catch {
            }
            ActionStates.setRead(s: message, read: true)
            let titleText = MessageCellView.getTitleText(message: message, state: cell.state)
            cell.text.setTextWithTitleHTML(titleText, htmlString: message.htmlBody)

        } else {
            if let context = message.context, message.wasComment {
                let url = "https://www.reddit.com\(context)"
                let vc = RedditLink.getViewControllerForURL(urlS: URL.initPercent(string: url)!)
                VCPresenter.showVC(viewController: vc, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
            } else {
                VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(message: message, completion: {(_) in
                    DispatchQueue.main.async(execute: { () -> Void in
                        BannerUtil.makeBanner(text: "Message sent!", seconds: 3, context: self)
                    })
                })), parentVC: self)
            }
        }
    }
    
    func showMenu(for message: MessageObject, cell: MessageCellView) {
        let alertController = DragDownAlertMenu(title: "Message from u/\(message.author)", subtitle: message.subject, icon: nil)

        alertController.addAction(title: "\(AccountController.formatUsernamePosessive(input: message.author, small: false)) profile", icon: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon()) {
            let prof = ProfileViewController.init(name: message.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }

        alertController.addAction(title: "Reply to message", icon: UIImage(sfString: SFSymbol.arrowshapeTurnUpLeftFill, overrideString: "reply")!.menuIcon()) {
            self.doReply(to: message, cell: cell)
        }

        alertController.addAction(title: ActionStates.isRead(s: message) ? "Mark as unread" : "Mark as read", icon: ActionStates.isRead(s: message) ? UIImage(sfString: SFSymbol.eyeSlashFill, overrideString: "seen")!.menuIcon() : UIImage(sfString: SFSymbol.eyeFill, overrideString: "seen")!.menuIcon()) {
            if ActionStates.isRead(s: message) {
                let session = (UIApplication.shared.delegate as! AppDelegate).session
                do {
                    try session?.markMessagesAsUnread([message.name.contains("_") ? message.name : (message.wasComment ? "t1_" : "t4_") + message.name], completion: { (result) in
                        if result.error != nil {
                            print(result.error!.description)
                        }
                    })
                } catch {
                    
                }
                ActionStates.setRead(s: message, read: false)
                let titleText = MessageCellView.getTitleText(message: message, state: cell.state)
                cell.text.setTextWithTitleHTML(titleText, htmlString: message.htmlBody)
                
            } else {
                let session = (UIApplication.shared.delegate as! AppDelegate).session
                do {
                    try session?.markMessagesAsRead([message.name.contains("_") ? message.name : (message.wasComment ? "t1_" : "t4_") + message.name], completion: { (result) in
                        if result.error != nil {
                            print(result.error!.description)
                        }
                    })
                } catch {
                    
                }
                ActionStates.setRead(s: message, read: true)
                let titleText = MessageCellView.getTitleText(message: message, state: cell.state)
                cell.text.setTextWithTitleHTML(titleText, htmlString: message.htmlBody)
            }
        }

        if let context = message.context, message.wasComment {
            alertController.addAction(title: "View comment thread", icon: UIImage(sfString: SFSymbol.bubbleLeftAndBubbleRightFill, overrideString: "comments")!.menuIcon()) {
                let url = "https://www.reddit.com\(context)"
                VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.initPercent(string: url)!), popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
            }
        }

        alertController.show(self)
    }
}
