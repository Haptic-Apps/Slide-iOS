//
//  SingleSubredditViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/22/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import Embassy
import MaterialComponents.MDCActivityIndicator
import MKColorPicker

import reddift
import RLBAlertsPickers
import SDCAlertView
import SDWebImage
import UIKit

// MARK: - Base
class SingleSubredditViewController: MediaViewController, AutoplayScrollViewDelegate {
    var currentPlayingIndex = [IndexPath]()
    public static let subredditIntent = "me.ccrama.redditslide.OpenSubreddit"
    
    var isScrollingDown = true
    var emptyStateView = EmptyStateView()
    var numberFiltered = 0
    var setOffset = CGFloat.zero

    var lastScrollDirectionWasDown = false
    var fullWidthBackGestureRecognizer: UIGestureRecognizer!
    var cellGestureRecognizer: UIPanGestureRecognizer!
    var swipeBackAdded = false

    func getTableView() -> UICollectionView {
        return tableView
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var childForHomeIndicatorAutoHidden: UIViewController? {
        return nil
    }

    override var prefersStatusBarHidden: Bool {
        return SettingValues.hideStatusBar
    }
    
    var autoplayHandler: AutoplayScrollViewHandler!

    override var keyCommands: [UIKeyCommand]? {
        return UIResponder.isFirstResponderTextField ? nil : [
            UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spacePressed)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(spacePressed)),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(spacePressedUp)),
            UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(search), discoverabilityTitle: "Search"),
            UIKeyCommand(input: "p", modifierFlags: .command, action: #selector(hideReadPosts), discoverabilityTitle: "Hide read posts"),
            UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(refresh(_:)), discoverabilityTitle: "Reload"),
        ]
    }
    
    var navbarEnabled: Bool {
        return true
    }

    var toolbarEnabled: Bool {
        return true
    }
    
    let maxHeaderHeight: CGFloat = 120
    let minHeaderHeight: CGFloat = 56
    public var inHeadView: UIView?
    var lastTopItem: Int = 0
    
    var oldCount: Int = 0 //Tells us if we need to reload the dataset when going back to the view, if new posts have been added
    
    let margin: CGFloat = 10
    let cellsPerRow = 3
    var readLaterCount: Int {
        return ReadLater.readLaterIDs.allValues.filter { (value) -> Bool in
                if sub == "all" || sub == "frontpage" { return true }
                guard let valueStr = value as? String else { return false }
                return valueStr.lowercased() == sub.lowercased()
                }.count
    }
    
    var translatingCell: LinkCellView?
    var isGallery = false

    weak var parentController: MainViewController?
    var accentChosen: UIColor?
    var primaryChosen: UIColor?

    var isModal = false

    var isAccent = false

    var isCollapsed = false
    var isHiding = false
    var isToolbarHidden = false

    var oldY = CGFloat(0)

    var sub: String
    var session: Session?
    var tableView: UICollectionView!
    var single: Bool = false

    var sideView: UIView = UIView()
    var subb: UIButton = UIButton()
    var subInfo: Subreddit?
    var flowLayout: WrappingFlowLayout = WrappingFlowLayout.init()

    var sortButton = UIButton.init(type: .custom)

    static var firstPresented = true
    static var cellVersion = 0 {
        didSet {
            PagingCommentViewController.savedComment = nil
        }
    }
    
    var headerVersion = 0

    var more = UIButton()
    var searchbutton = UIButton()

    var lastY: CGFloat = CGFloat(0)
    var lastYUsed = CGFloat(0)

    var listingId: String = "" //a random id for use in Realm

    var fab: UIButton?
    var fabHelper: UIView?

    var first = true
    var indicator: MDCActivityIndicator?

    var searchText: String?

    var refreshControl: UIRefreshControl!

    var hasHeader = false
    var subLinks = [SubLinkItem]()

    var oldsize = CGFloat(0)
    var dataSource: SubmissionsDataSource

    init(subName: String, parent: MainViewController) {
        sub = subName
        self.parentController = parent
        
        single = !(parent is SplitMainViewController)
        dataSource = SubmissionsDataSource(subreddit: subName, sorting: SettingValues.getLinkSorting(forSubreddit: subName), time: SettingValues.getTimePeriod(forSubreddit: subName))

        super.init(nibName: nil, bundle: nil)
        self.autoplayHandler = AutoplayScrollViewHandler(delegate: self)
    }

    init(subName: String, single: Bool) {
        sub = subName
        self.single = true
        dataSource = SubmissionsDataSource(subreddit: subName, sorting: SettingValues.getLinkSorting(forSubreddit: subName), time: SettingValues.getTimePeriod(forSubreddit: subName))

        super.init(nibName: nil, bundle: nil)
        self.autoplayHandler = AutoplayScrollViewHandler(delegate: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    @objc func showDrawer(_ sender: AnyObject) {
        //menuNav?.expand()
    }
    
    @objc func showMenu(_ sender: AnyObject) {
        showMore(sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        CachedTitle.titles.removeAll()

        if UIDevice.current.userInterfaceIdiom == .pad && SettingValues.appMode == .SPLIT && (!UIApplication.shared.isSplitOrSlideOver || UIApplication.shared.isMac()) && !(splitViewController?.viewControllers[(splitViewController?.viewControllers.count ?? 1) - 1] is PlaceholderViewController) {
            splitViewController?.showDetailViewController(SwipeForwardNavigationController(rootViewController: PlaceholderViewController()), sender: self)
        }
        
        flowLayout.delegate = self
        self.tableView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        self.view = UIView.init(frame: CGRect.zero)
        self.view.addSubview(tableView)

        tableView.verticalAnchors /==/ view.verticalAnchors
        tableView.horizontalAnchors /==/ view.safeHorizontalAnchors

        if SettingValues.submissionGestureMode != .NONE {
            setupGestures()
        }
        
        /*Disable for now
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panCell))
        panGesture.direction = .horizontal
        panGesture.delegate = self
        self.tableView.addGestureRecognizer(panGesture)*/
        
        isModal = navigationController?.presentingViewController != nil || self.modalPresentationStyle == .fullScreen

        if single && !isModal && navigationController != nil {
            //panGesture.require(toFail: navigationController!.interactivePopGestureRecognizer!)
        } else if isModal {
            //navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
        
        if single && !(parent is SplitMainViewController) {
            self.edgesForExtendedLayout = UIRectEdge.all
        } else {
            self.edgesForExtendedLayout = []
        }
        
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.toolbar.isTranslucent = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        refreshControl = UIRefreshControl()

        reloadNeedingColor()
        self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: isGallery)
        tableView.reloadData()
        
        self.view.addSubview(emptyStateView)
        emptyStateView.setText(title: "Nothing to see here!", message: "No content was found on this subreddit")
        
        emptyStateView.isHidden = true
        emptyStateView.isUserInteractionEnabled = false
        emptyStateView.edgeAnchors /==/ self.tableView.edgeAnchors

        self.view.bringSubviewToFront(emptyStateView)

        if #available(iOS 11.0, *) {
            self.tableView.contentInsetAdjustmentBehavior = .never
        }
        
        dataSource.sorting = SettingValues.getLinkSorting(forSubreddit: self.sub)
        dataSource.time = SettingValues.getTimePeriod(forSubreddit: self.sub)
    }
    
    func reTheme() {
        self.reloadNeedingColor()
        flowLayout.reset(modal: presentingViewController != nil, vc: self, isGallery: isGallery)
        CachedTitle.titles.removeAll()
        LinkCellImageCache.initialize()
        //self.showMenuNav(true)
        self.tableView.reloadData()
        self.setupFab(self.view.bounds.size)
        self.doToolbar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setToolbarHidden(false, animated: false)
        navigationController?.toolbar.tintColor = UIColor.foregroundColor

        if !(navigationController is TapBehindModalViewController) && inHeadView == nil {
            inHeadView = UIView().then {
                $0.backgroundColor = ColorUtil.getColorForSub(sub: sub, true)
                if SettingValues.hideStatusBar {
                    $0.backgroundColor = .clear
                }
            }
            self.view.addSubview(inHeadView!)
            inHeadView!.isHidden = UIDevice.current.orientation.isLandscape

            inHeadView!.topAnchor /==/ view.topAnchor
            inHeadView!.horizontalAnchors /==/ view.horizontalAnchors
            var statusBarHeight = UIApplication.shared.statusBarUIView?.frame.size.height ?? 0
            if statusBarHeight == 0 {
                statusBarHeight = (self.navigationController?.navigationBar.frame.minY ?? 20)
            }

            inHeadView!.heightAnchor /==/ statusBarHeight
            
            let navOffset = self.navigationController?.navigationBar.frame.size.height ?? 64
            var topOffset = statusBarHeight
            if self.navigationController?.modalPresentationStyle == .pageSheet && self.navigationController?.viewControllers.count == 1 && !(self.navigationController?.viewControllers[0] is MainViewController) {
                topOffset = 0
            }

            self.tableView.contentInset = UIEdgeInsets.init(top: CGFloat(navOffset + topOffset + 8), left: 0, bottom: 65, right: 0)
        }

        dataSource.delegate = self
        isModal = navigationController?.presentingViewController != nil || self.modalPresentationStyle == .fullScreen

        if isModal {
            if self.navigationController is TapBehindModalViewController {
                self.navigationController?.delegate = self
                (self.navigationController as! TapBehindModalViewController).del = self
            }
        }

        self.isGallery = UserDefaults.standard.bool(forKey: "isgallery+" + sub)
        
        server?.stop()
        loop?.stop()

        first = false

        if single && !(parent is SplitMainViewController) {
            setupBaseBarColors(ColorUtil.getColorForSub(sub: sub, true))
        } else if #available(iOS 13, *) {} else {
            setupBaseBarColors(ColorUtil.getColorForSub(sub: sub, true))
        }
        
        if !dataSource.loaded {
            showUI()
        }
        self.view.backgroundColor = UIColor.backgroundColor
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        var isBelow13 = true
        if #available(iOS 13, *) {
            isBelow13 = false
        }
        navigationController?.navigationBar.isTranslucent = isBelow13 ? true : false
        
        if !single {
            splitViewController?.navigationController?.navigationBar.isTranslucent = isBelow13 ? true : false
            splitViewController?.navigationController?.setNavigationBarHidden(true, animated: false)
        }
        if let bar = splitViewController?.navigationController?.navigationBar {
            bar.heightAnchor /==/ 0
        }

        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.splitViewController?.navigationController?.navigationBar.shadowImage = UIImage()

        if single && !(parent is SplitMainViewController) {
            navigationController?.navigationBar.tintColor = SettingValues.reduceColor ? UIColor.fontColor : UIColor.white
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: sub, true)
        }
        
        navigationController?.toolbar.barTintColor = UIColor.backgroundColor
        navigationController?.toolbar.tintColor = UIColor.fontColor

        inHeadView?.isHidden = UIDevice.current.orientation.isLandscape
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        autoplayHandler.autoplayOnce(self.tableView)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //menuNav?.configureToolbarSwipe()
        fullWidthBackGestureRecognizer?.isEnabled = true
        cellGestureRecognizer?.isEnabled = true
        refreshControl.setValue(100, forKey: "_snappingHeight")

        if dataSource.loaded && dataSource.content.count > oldCount {
            self.tableView.reloadData()
            oldCount = dataSource.content.count
        }

        if toolbarEnabled && !MainViewController.isOffline {
            //showMenuNav()
            self.navigationController?.setToolbarHidden(false, animated: false)
            self.isToolbarHidden = false
            if fab == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {[weak self] in
                    guard let strongSelf = self else { return }
                    if strongSelf.fab == nil {
                        strongSelf.setupFab(strongSelf.view.bounds.size)
                    }
                }
            } else {
                show(true)
            }
        } else {
            if single {
                navigationController?.setToolbarHidden(true, animated: false)
            }
        }
        if !dataSource.hasContent() {
            self.autoplayHandler.autoplayOnce(self.tableView)
        }
        if parentController == nil && !swipeBackAdded {
            if SettingValues.submissionGestureMode != .FULL {
                setupSwipeGesture()
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? LinkCellView {
            var row = indexPath.row
            if hasHeader {
                row -= 1
            }

            let submission = dataSource.content[row]

            cell.configure(submission: submission, parent: self, nav: self.navigationController, baseSub: self.sub, np: false)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if self.view.bounds.width != oldsize {
            oldsize = self.view.bounds.width
            flowLayout.reset(modal: presentingViewController != nil, vc: self, isGallery: isGallery)
            tableView.reloadData()
        }
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !dataSource.offline {
            _ = self.dataSource.insertSelf(into: SlideCoreData.sharedInstance.backgroundContext, andSave: true)
        }
        
        for index in tableView.indexPathsForVisibleItems {
            if let cell = tableView.cellForItem(at: index) as? LinkCellView {
                cell.endVideos()
                self.currentPlayingIndex = self.currentPlayingIndex.filter({ (included) -> Bool in
                    return included.row != index.row
                })
            }
        }

        if single {
            UIApplication.shared.statusBarUIView?.backgroundColor = .clear
        }
        
        if fab != nil {
            self.fab?.removeFromSuperview()
            self.fab = nil
        }
        if let session = (UIApplication.shared.delegate as? AppDelegate)?.session {
            if AccountController.isLoggedIn && AccountController.isGold && !History.currentSeen.isEmpty {
                do {
                    try session.setVisited(names: History.currentSeen) { [weak self] (_) in
                        guard self != nil else { return }

                        History.currentSeen.removeAll()
                    }
                } catch let error {
                    print(error)
                }
            }
        }
    }
    
    var cancelRotationOffset: CGPoint?
    var didScroll = true

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
                
        inHeadView?.removeFromSuperview()
        fab?.removeFromSuperview()
        
        if cancelRotationOffset == nil {
            cancelRotationOffset = tableView.contentOffset
        }
        
        let indexPathRect = CGRect(x: tableView.contentOffset.x, y: tableView.contentOffset.y, width: tableView.bounds.size.width, height: tableView.bounds.size.height)
        let indexToPin = self.tableView.indexPathForItem(at: CGPoint(x: indexPathRect.width / (CGFloat(flowLayout.numberOfColumns) * 2), y: indexPathRect.midY))
        
        coordinator.animate(
            alongsideTransition: { [unowned self] _ in
                self.navigationController?.navigationBar.shadowImage = UIImage()
                self.navigationController?.navigationBar.isTranslucent = false
                self.navigationController?.navigationBar.tintColor = SettingValues.reduceColor ? UIColor.fontColor : UIColor.white
                self.navigationController?.toolbar.barTintColor = UIColor.backgroundColor
                self.navigationController?.toolbar.tintColor = UIColor.fontColor

                self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: self.isGallery)
                self.tableView.reloadData()
                self.view.setNeedsLayout()
                if let oldLocation = cancelRotationOffset, !didScroll {
                    tableView.contentOffset = oldLocation
                    cancelRotationOffset = nil
                } else if let indexPath = indexToPin {
                    self.tableView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredVertically, animated: true)
                    self.lastY = self.tableView.contentOffset.y
                }
               // TODO: - content offset
            }, completion: { [weak self] (_) in
                guard let self = self else { return }
                self.setupFab(size)
                self.didScroll = false
            }
        )

//        if self.viewIfLoaded?.window != nil {
//            tableView.reloadData()
//        }
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
    
    static func getHeightFromAspectRatio(imageHeight: CGFloat, imageWidth: CGFloat, viewWidth: CGFloat) -> CGFloat {
        let ratio = imageHeight / imageWidth
        return viewWidth * ratio
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fullWidthBackGestureRecognizer?.isEnabled = false
        cellGestureRecognizer?.isEnabled = false

        if fab != nil {
            fab?.removeFromSuperview()
            fab = nil
        }
    }
    
    var lastCenter = CGPoint.zero
    func didScrollExtras(_ currentY: CGFloat) {
        if !SettingValues.dontHideTopBar {
            if currentY > lastYUsed && currentY > 60 {
                if navigationController != nil && !isHiding && !isToolbarHidden && !(self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.frame.size.height)) {
                    hideUI(inHeader: true)
                } else if fab != nil && !fab!.isHidden && !isHiding && SettingValues.hideBottomBar {
                    UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                        self.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
                    }, completion: { _ in
                        self.fab?.isHidden = true
                        self.isHiding = false
                    })
                }
            } else if (currentY < lastYUsed - 15 || currentY < 100) && !isHiding && navigationController != nil && (isToolbarHidden) {
                showUI()
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !(dataSource.delegate is SingleSubredditViewController) {
            dataSource.delegate = self
            if dataSource.loaded && dataSource.content.count > oldCount {
                self.tableView.reloadData()
                self.oldCount = dataSource.content.count
            }
            
        }
        autoplayHandler.scrollViewDidScroll(scrollView)
        didScroll = true
    }
    
    func hideUI(inHeader: Bool) {
        isHiding = true
        
        if navbarEnabled {
            (navigationController)?.setNavigationBarHidden(true, animated: true)
        }
                
        if SettingValues.hideBottomBar {
            self.fabHelper?.isUserInteractionEnabled = false

            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                self.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
            }, completion: { _ in
                self.fab?.isHidden = true
                self.isHiding = false
            })
        } else {
            self.isHiding = false
        }
        
        if single || parent is SplitMainViewController {
            if SettingValues.hideBottomBar {
                self.navigationController?.setToolbarHidden(true, animated: true)
            }

            //hideMenuNav()
        //} else {
            /*if let topView = self.menuNav?.topView {
                self.menu.deactivateImmediateConstraints()
                self.menu.topAnchor /==/ topView.topAnchor - 10
                self.menu.widthAnchor /==/ 56
                self.menu.heightAnchor /==/ 56
                self.menu.leftAnchor /==/ topView.leftAnchor
                
                self.more.deactivateImmediateConstraints()
                self.more.topAnchor /==/ topView.topAnchor - 10
                self.more.widthAnchor /==/ 56
                self.more.heightAnchor /==/ 56
                self.more.rightAnchor /==/ topView.rightAnchor
            }
            UIView.animate(withDuration: 0.25) {
                self.menuNav?.view.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - (SettingValues.totallyCollapse ? 0 : ((self.menuNav?.bottomOffset ?? 56) / 2)), width: self.menuNav?.view.frame.width ?? 0, height: self.menuNav?.view.frame.height ?? 0)
                self.parentController?.menu.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                self.parentController?.more.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            }*/
            //            if !single && parentController != nil {
            //                parentController!.drawerButton.isHidden = false
            //            }
        }
        self.isToolbarHidden = true
    }

    func showUI(_ disableBottom: Bool = false) {
        
        self.fabHelper?.isUserInteractionEnabled = true

        if navbarEnabled {
            (navigationController)?.setNavigationBarHidden(false, animated: true)
        }
        
        if parentController != nil {
            parentController!.doToolbarOffset()
        }
        
        if self.fab?.superview != nil && SettingValues.hideBottomBar {
            self.fab?.isHidden = false
            self.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
            
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                self.fab?.transform = CGAffineTransform.identity
            })
        }

        if (single || parent is SplitMainViewController) && !MainViewController.isOffline {
            self.navigationController?.setToolbarHidden(false, animated: true)
        } else if !disableBottom {
            /*UIView.animate(withDuration: 0.25) {
                if self.menu.superview != nil, let topView = self.menuNav?.topView {
                    self.menu.deactivateImmediateConstraints()
                    self.menu.topAnchor /==/ topView.topAnchor
                    self.menu.widthAnchor /==/ 56
                    self.menu.heightAnchor /==/ 56
                    self.menu.leftAnchor /==/ topView.leftAnchor

                    self.more.deactivateImmediateConstraints()
                    self.more.topAnchor /==/ topView.topAnchor
                    self.more.widthAnchor /==/ 56
                    self.more.heightAnchor /==/ 56
                    self.more.rightAnchor /==/ topView.rightAnchor
                }

                self.menuNav?.view.frame = CGRect(x: 0, y: (UIScreen.main.bounds.height - (self.menuNav?.bottomOffset ?? 0)), width: self.view.frame.width, height: self.menuNav?.view.frame.height ?? 0)
                self.menu.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.more.transform = CGAffineTransform(scaleX: 1, y: 1)
            }*/
        }
        self.isToolbarHidden = false
    }

    func show(_ animated: Bool = true) {
        if fab != nil && (fab!.isHidden || fab!.superview == nil) {
            if animated && SettingValues.hideBottomBar {
                if fab!.superview == nil {
                    //if single {
                        self.navigationController?.toolbar.addSubview(fab!)
                    //} else {
                    //    toolbar?.addSubview(fab!)
                    //}
                }
                self.fab!.isHidden = false
                self.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)

                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.fab?.transform = CGAffineTransform.identity
                })
            } else {
                self.fab!.isHidden = false
            }
        }
    }

    func hideFab(_ animated: Bool = true) {
        if self.fab != nil {
            if animated {
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.fab!.alpha = 0
                }, completion: { [weak self] _ in
                    guard let self = self else { return }

                    self.fab!.isHidden = true
                })
            } else {
                self.fab!.isHidden = true
            }
        }
    }

    func setupFab(_ size: CGSize) {
        addNewFab(size)
    }
    
    func addNewFab(_ size: CGSize) {
        if parentController is SplitMainViewController {
            if parentController!.currentTitle != sub {
                return
            }
        }
        if navigationController?.topViewController != self && navigationController?.topViewController != parent {
            return
        }
        for view in self.navigationController?.toolbar.subviews ?? [UIView]() {
            if view.tag == 1337 {
                view.removeFromSuperview()
            }
        }

        if self.fab != nil {
            self.fab!.removeFromSuperview()
            self.fab = nil
        }
        
        if self.fabHelper != nil {
            self.fabHelper?.removeFromSuperview()
            self.fabHelper = nil
        }
        
        if !MainViewController.isOffline && !SettingValues.hiddenFAB {
            self.fab = ExpandedHitTestButton(frame: CGRect.init(x: (size.width / 2) - 70, y: -20, width: 140, height: 45))
            self.fab!.backgroundColor = ColorUtil.getNavColorForSub(sub: sub) ?? ColorUtil.accentColorForSub(sub: sub)
            self.fab!.accessibilityHint = sub
            self.fab!.accessibilityFrame = self.fab!.frame
            self.fab!.layer.cornerRadius = 22.5
            self.fab!.clipsToBounds = true
            let title = "  " + SettingValues.fabType.getTitleShort()
            self.fab!.setTitle(title, for: .normal)
            self.fab!.leftImage(image: SettingValues.fabType.getPhoto()!.navIcon(true), renderMode: UIImage.RenderingMode.alwaysOriginal)
            self.fab!.elevate(elevation: 2)
            self.fab!.tag = 1337
            self.fab!.titleLabel?.textAlignment = .center
            self.fab!.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            
            fabHelper = UIView(frame: self.fab!.frame)
            fabHelper?.addTapGestureRecognizer(action: { (_) in
                self.doFabActions()
            })
            fabHelper?.addLongTapGestureRecognizer(action: { (_) in
                self.changeFab()
            })
                        
            let width = title.size(with: self.fab!.titleLabel!.font).width + CGFloat(65)
            self.fab!.frame = CGRect.init(x: (size.width / 2) - (width / 2), y: -20, width: width, height: CGFloat(45))
            
            self.fab!.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
            self.navigationController?.toolbar.addSubview(self.fab!)
            self.view.addSubview(fabHelper!)
            self.fabHelper!.bottomAnchor /==/ self.view.safeBottomAnchor
            self.fabHelper!.backgroundColor = .clear
            
            self.fabHelper!.heightAnchor /==/ 45
            self.fabHelper!.widthAnchor /==/ self.fab!.frame.size.width
            self.fabHelper!.centerXAnchor /==/ self.view.centerXAnchor

            self.fab?.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                self.fab?.transform = CGAffineTransform.identity
            }, completion: { [weak self] (_) in
                guard let strongSelf = self else { return }
                strongSelf.fab?.addTarget(strongSelf, action: #selector(strongSelf.doFabActions), for: .touchUpInside)
                strongSelf.fab?.addLongTapGestureRecognizer { (_) in
                    strongSelf.changeFab()
                }
                
            })
        }
    }

    @objc func doFabActions() {
        if UserDefaults.standard.bool(forKey: "FAB_SHOWN") == false {
            let a = UIAlertController(title: "Subreddit Action Button", message: "This is the subreddit action button!\n\nThis button's actions can be customized by long pressing on it at any time, and this button can be removed completely in Settings > General.", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "Change action", style: .default, handler: { [weak self] (_) in
                guard let self = self else { return }

                UserDefaults.standard.set(true, forKey: "FAB_SHOWN")
                UserDefaults.standard.synchronize()
                self.changeFab()
            }))
            a.addAction(UIAlertAction(title: "Hide button", style: .default, handler: { [weak self] (_) in
                guard let self = self else { return }
                
                SettingValues.hiddenFAB = true
                UserDefaults.standard.set(true, forKey: SettingValues.pref_hiddenFAB)
                UserDefaults.standard.set(true, forKey: "FAB_SHOWN")
                UserDefaults.standard.synchronize()
                self.setupFab(self.view.bounds.size)
            }))
            a.addAction(UIAlertAction(title: "Continue", style: .default, handler: { [weak self] (_) in
                guard let self = self else { return }

                UserDefaults.standard.set(true, forKey: "FAB_SHOWN")
                UserDefaults.standard.synchronize()
                self.doFabActions()
            }))
            
            self.present(a, animated: true, completion: nil)
        } else {
            switch SettingValues.fabType {
            case .SIDEBAR:
                self.doDisplaySidebar()
            case .NEW_POST:
                self.newPost(self.fab!)
            case .SHADOWBOX:
                self.shadowboxMode()
            case .RELOAD:
                self.refresh()
            case .HIDE_READ:
                self.hideReadPosts()
            case .HIDE_PERMANENTLY:
                self.hideReadPostsPermanently()
            case .GALLERY:
                self.galleryMode()
            case .SEARCH:
                self.search()
            }
        }
    }
    
    var headerImage: URL?
    
    func loadBubbles() {
        self.subLinks.removeAll()
        if self.sub == ("all") || self.sub == ("frontpage") || self.sub == ("popular") || self.sub == ("friends") || self.sub.lowercased() == ("myrandom") || self.sub.lowercased() == ("random") || self.sub.lowercased() == ("randnsfw") || self.sub.hasPrefix("/m/") || self.sub.contains("+") {
            return
        }
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.getStyles(sub, completion: { [weak self] (result) in
                guard let self = self else { return }

                switch result {
                case .failure(let error):
                    print(error)
                    return
                case .success(let r):
                    if let baseData = r as? JSONDictionary, let data = baseData["data"] as? [String: Any] {
                        if let content = data["content"] as? [String: Any],
                            let widgets = content["widgets"] as? [String: Any],
                            let items = widgets["items"] as? [String: Any] {
                            for item in items.values {
                                if let body = item as? [String: Any] {
                                    if let kind = body["kind"] as? String, kind == "menu" {
                                        if let data = body["data"] as? JSONArray {
                                            for link in data {
                                                if let children = link["children"] as? JSONArray {
                                                    for subItem in children {
                                                        if let content = subItem as? JSONDictionary {
                                                            self.subLinks.append(SubLinkItem((content["text"] as? String ?? "").unescapeHTML, link: URL(string: (content["url"] as! String).decodeHTML())))
                                                        }
                                                    }
                                                } else {
                                                    self.subLinks.append(SubLinkItem((link["text"] as? String ?? "").unescapeHTML, link: URL(string: (link["url"] as! String).decodeHTML())))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if let styles = data["style"] as? [String: Any] {
                            if let headerUrl = styles["bannerBackgroundImage"] as? String {
                                if !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi() && SettingValues.dataSavingEnabled) {
                                    self.headerImage = URL(string: headerUrl.unescapeHTML)
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.hasHeader = true
                        if self.dataSource.loaded && !self.dataSource.loading {
                            self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: self.isGallery)
                            self.tableView.reloadData()
                            if UIDevice.current.userInterfaceIdiom != .pad {
                                var newOffset = self.tableView.contentOffset
                                newOffset.y -= self.headerHeight(false)
                                self.tableView.setContentOffset(newOffset, animated: false)
                            }
                        }
                    }
                }
            })
        } catch {
        }
    }
    
    func changeFab() {
        if !UserDefaults.standard.bool(forKey: "FAB_SHOWN") {
            UserDefaults.standard.set(true, forKey: "FAB_SHOWN")
            UserDefaults.standard.synchronize()
        }
        
        let actionSheetController = DragDownAlertMenu(title: "Change button action", subtitle: "", icon: nil, themeColor: ColorUtil.baseAccent, full: true)

        for t in SettingValues.FabType.cases {
            actionSheetController.addAction(title: t.getTitle(), icon: t.getPhoto()?.menuIcon(), action: {
                UserDefaults.standard.set(t.rawValue, forKey: SettingValues.pref_fabType)
                SettingValues.fabType = t
                self.setupFab(self.view.bounds.size)
            })
        }

        actionSheetController.show(self)
    }

    var lastVersion = 0
    
    func doToolbar() {
        if let mainVC = self.parent as? MainViewController, (!self.single || mainVC is SplitMainViewController) {
            doSortImage(mainVC.sortButton)
        }
        
        more = UIButton(buttonImage: UIImage(sfString: SFSymbol.ellipsis, overrideString: "moreh"), toolbar: true)
        more.addTarget(self, action: #selector(self.showMoreNone(_:)), for: UIControl.Event.touchUpInside)
        let moreB = UIBarButtonItem.init(customView: more)
        
        searchbutton = UIButton(buttonImage: UIImage(sfString: SFSymbol.magnifyingglass, overrideString: "search"), toolbar: true)
        searchbutton.addTarget(self, action: #selector(self.search), for: UIControl.Event.touchUpInside)
        let searchB = UIBarButtonItem.init(customView: searchbutton)

        let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        if parent is SplitMainViewController {
            parent!.toolbarItems = [searchB, flexButton, moreB]
        } else {
            toolbarItems = [searchB, flexButton, moreB]
        }
    }
    
    func reloadNeedingColor() {
        tableView.backgroundColor = UIColor.backgroundColor
        inHeadView?.backgroundColor = ColorUtil.getColorForSub(sub: sub, true)
        if SettingValues.hideStatusBar {
            inHeadView?.backgroundColor = .clear
        }

        refreshControl.tintColor = UIColor.fontColor
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControl.Event.valueChanged)

        tableView.addSubview(refreshControl) // not required when using UITableViewController
        tableView.alwaysBounceVertical = true

        self.automaticallyAdjustsScrollViewInsets = false

        // TODO: - Can just use .self instead of .classForCoder()
        self.tableView.register(BannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "banner\(SingleSubredditViewController.cellVersion)")
        self.tableView.register(AutoplayBannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "autoplay\(SingleSubredditViewController.cellVersion)")
        self.tableView.register(GalleryLinkCellView.classForCoder(), forCellWithReuseIdentifier: "gallery\(SingleSubredditViewController.cellVersion)")
        self.tableView.register(ThumbnailLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb\(SingleSubredditViewController.cellVersion)")
        self.tableView.register(TextLinkCellView.classForCoder(), forCellWithReuseIdentifier: "text\(SingleSubredditViewController.cellVersion)")
        self.tableView.register(LoadingCell.classForCoder(), forCellWithReuseIdentifier: "loading")
        self.tableView.register(NothingHereCell.classForCoder(), forCellWithReuseIdentifier: "nothing")
        self.tableView.register(ReadLaterCell.classForCoder(), forCellWithReuseIdentifier: "readlater")
        self.tableView.register(PageCell.classForCoder(), forCellWithReuseIdentifier: "page")
        self.tableView.register(LinksHeaderCellView.classForCoder(), forCellWithReuseIdentifier: "header\(headerVersion)")
        lastVersion = SingleSubredditViewController.cellVersion

        let navOffset = self.navigationController?.navigationBar.frame.size.height ?? 64
        var statusBarHeight = UIApplication.shared.statusBarUIView?.frame.size.height ?? 0
        if statusBarHeight == 0 {
            statusBarHeight = (self.navigationController?.navigationBar.frame.minY ?? 20)
        }

        var topOffset = statusBarHeight
        if self.navigationController?.modalPresentationStyle == .pageSheet && self.navigationController?.viewControllers.count == 1 && !(self.navigationController?.viewControllers[0] is MainViewController) {
            topOffset = 0
        }

        self.tableView.contentInset = UIEdgeInsets.init(top: CGFloat(navOffset + topOffset + 8), left: 0, bottom: 65, right: 0)

        session = (UIApplication.shared.delegate as! AppDelegate).session

        if (SingleSubredditViewController.firstPresented && !single && !dataSource.hasContent()) || (!dataSource.hasContent() && !single && !SettingValues.subredditBar) {
            dataSource.delegate = self
            dataSource.getData(reload: true, force: true)
            SingleSubredditViewController.firstPresented = false
        }
                
        let offline = MainViewController.isOffline

        if single && !offline {
            doToolbar()
            
            sortButton = UIButton.init(type: .custom)
            sortButton.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControl.Event.touchUpInside)
            sortButton.frame = CGRect.init(x: 0, y: 0, width: 30, height: 44)
            let sortB = UIBarButtonItem.init(customView: sortButton)
            doSortImage(sortButton)

            subb = UIButton.init(type: .custom)
            subb.setImage(UIImage(named: Subscriptions.subreddits.contains(sub) ? "subbed" : "addcircle")?.navIcon(), for: UIControl.State.normal)
            subb.addTarget(self, action: #selector(self.subscribeSingle(_:)), for: UIControl.Event.touchUpInside)
            subb.frame = CGRect.init(x: 0, y: 0, width: 30, height: 44)
            if !(parent is SplitMainViewController) {
                navigationItem.rightBarButtonItems = [sortB]
            }
            
            let label = UILabel()
            label.text = "   \(SettingValues.reduceColor ? "      " : "")\(sub)"
            label.textColor = SettingValues.reduceColor ? UIColor.fontColor : .white
            label.adjustsFontSizeToFitWidth = true
            label.font = UIFont.boldSystemFont(ofSize: 20)
            
            if SettingValues.reduceColor {
                let sideView = UIImageView(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
                let subreddit = sub
                sideView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
                
                if let icon = Subscriptions.icon(for: subreddit) {
                    sideView.contentMode = .scaleAspectFill
                    sideView.image = UIImage()
                    sideView.sd_setImage(with: URL(string: icon.unescapeHTML), completed: nil)
                } else {
                    sideView.contentMode = .center
                    if subreddit.contains("m/") {
                        sideView.image = SubredditCellView.defaultIconMulti
                    } else if subreddit.lowercased() == "all" {
                        sideView.image = SubredditCellView.allIcon
                    } else if subreddit.lowercased() == "frontpage" {
                        sideView.image = SubredditCellView.frontpageIcon
                    } else if subreddit.lowercased() == "popular" {
                        sideView.image = SubredditCellView.popularIcon
                    } else {
                        sideView.image = SubredditCellView.defaultIcon
                    }
                }
                
                label.addSubview(sideView)
                sideView.sizeAnchors /==/ CGSize.square(size: 30)
                sideView.centerYAnchor /==/ label.centerYAnchor
                sideView.leftAnchor /==/ label.leftAnchor

                sideView.layer.cornerRadius = 15
                sideView.clipsToBounds = true
            }
            
            label.sizeToFit()
            self.navigationItem.titleView = label

            if !dataSource.loaded {
                do {
                    try (UIApplication.shared.delegate as! AppDelegate).session?.about(sub, completion: { [weak self] (result) in
                        guard let self = self else { return }

                        switch result {
                        case .failure:
                            print(result.error!.description)
                            DispatchQueue.main.async {
                                if self.sub == ("all") || self.sub == ("frontpage") || self.sub == ("popular") || self.sub == ("friends") || self.sub.lowercased() == ("myrandom") || self.sub.lowercased() == ("random") || self.sub.lowercased() == ("randnsfw") || self.sub.hasPrefix("/m/") || self.sub.contains("+") {
                                    if !self.dataSource.loading && !self.dataSource.loaded {
                                        self.dataSource.getData(reload: true, force: true)
                                    }
                                    self.loadBubbles()
                                }
                            }
                        case .success(let r):
                            self.subInfo = r
                            DispatchQueue.main.async {
                                //TODO: Hook into Shortcuts
                                if self.subInfo != nil {
                                    if !self.subInfo!.over18 {

                                    }
                                    if self.subInfo!.over18 && !SettingValues.nsfwEnabled {
                                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                                            let alert = UIAlertController.init(title: "r/\(self.sub) is NSFW", message: "You must log into Reddit and enable NSFW content at Reddit.com to view this subreddit", preferredStyle: .alert)
                                            alert.addAction(UIAlertAction.init(title: "Close", style: .default, handler: { (_) in
                                                self.navigationController?.popViewController(animated: true)
                                                self.dismiss(animated: true, completion: nil)
                                            }))
                                            self.present(alert, animated: true, completion: nil)
                                        }
                                    } else {
                                        if self.sub != ("all") && self.sub != ("frontpage") && !self.sub.hasPrefix("/m/") {
                                            //self.menuNav?.setSubredditObject(subreddit: r)

                                            if SettingValues.saveHistory {
                                                if SettingValues.saveNSFWHistory && self.subInfo!.over18 {
                                                    Subscriptions.addHistorySub(name: AccountController.currentName, sub: self.subInfo!.displayName)
                                                } else if !self.subInfo!.over18 {
                                                    Subscriptions.addHistorySub(name: AccountController.currentName, sub: self.subInfo!.displayName)
                                                }
                                            }
                                        }
                                        if !self.dataSource.loading && !self.dataSource.loaded {
                                            self.dataSource.getData(reload: true, force: true)
                                        }
                                        self.loadBubbles()
                                    }
                                } else {
                                    if !self.dataSource.loading && !self.dataSource.loaded {
                                        self.dataSource.getData(reload: true, force: true)
                                    }
                                    self.loadBubbles()
                                }
                            }
                        }
                    })
                } catch {
                }
            }
        } else if offline && single && !self.dataSource.loading && !self.dataSource.loaded {
            title = sub
            //hideMenuNav()
            dataSource.getData(reload: true, force: true)
        } else if !dataSource.loaded {
            self.loadBubbles()
        }
    }
    
    func doSortImage(_ sortButton: UIButton) {
        switch dataSource.sorting {
        case .best:
            sortButton.setImage(UIImage(sfString: SFSymbol.handThumbsupFill, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        case .hot:
            sortButton.setImage(UIImage(sfString: SFSymbol.flameFill, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        case .controversial:
            sortButton.setImage(UIImage(sfString: SFSymbol.boltFill, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        case .new:
            sortButton.setImage(UIImage(sfString: SFSymbol.sparkles, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        case .rising:
            sortButton.setImage(UIImage(sfString: SFSymbol.arrowUturnUp, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        case .top:
            if #available(iOS 14, *) {
                sortButton.setImage(UIImage(sfString: SFSymbol.crownFill, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
            } else {
                sortButton.setImage(UIImage(sfString: SFSymbol.arrowUp, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
            }
        }
    }

    func exit() {
        self.navigationController?.popViewController(animated: true)
        if self.navigationController!.modalPresentationStyle == .pageSheet {
            self.navigationController!.dismiss(animated: true, completion: nil)
        }
    }

    func doDisplayMultiSidebar(_ sub: Multireddit) {
        VCPresenter.presentModally(viewController: ManageMultireddit(multi: sub, reloadCallback: {
            self.refresh()
        }), self, nil)
    }

    @objc func subscribeSingle(_ selector: AnyObject) {
        if subChanged && !Subscriptions.isSubscriber(sub) || Subscriptions.isSubscriber(sub) {
            //was not subscriber, changed, and unsubscribing again
            Subscriptions.unsubscribe(sub, session: session!)
            subChanged = false
            BannerUtil.makeBanner(text: "Unsubscribed", color: ColorUtil.accentColorForSub(sub: sub), seconds: 3, context: self, top: true)
            subb.setImage(UIImage(sfString: SFSymbol.plusCircleFill, overrideString: "addcircle")?.navIcon(), for: UIControl.State.normal)
        } else {
            let alrController = UIAlertController.init(title: "Follow r/\(sub)", message: nil, preferredStyle: .alert)
            if AccountController.isLoggedIn {
                let somethingAction = UIAlertAction(title: "Subscribe", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) in
                    Subscriptions.subscribe(self.sub, true, session: self.session!)
                    self.subChanged = true
                    BannerUtil.makeBanner(text: "Subscribed to r/\(self.sub)", color: ColorUtil.accentColorForSub(sub: self.sub), seconds: 3, context: self, top: true)
                    self.subb.setImage(UIImage(sfString: SFSymbol.bookmarkFill, overrideString: "subbed")?.navIcon(), for: UIControl.State.normal)
                })
                alrController.addAction(somethingAction)
            }

            let somethingAction = UIAlertAction(title: "Casually subscribe", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) in
                Subscriptions.subscribe(self.sub, false, session: self.session!)
                self.subChanged = true
                BannerUtil.makeBanner(text: "r/\(self.sub) added to your subreddit list", color: ColorUtil.accentColorForSub(sub: self.sub), seconds: 3, context: self, top: true)
                self.subb.setImage(UIImage(sfString: SFSymbol.bookmarkFill, overrideString: "subbed")?.navIcon(), for: UIControl.State.normal)
            })
            
            alrController.addAction(somethingAction)
            alrController.addCancelButton()

            self.present(alrController, animated: true, completion: {})

        }

    }

    func displayMultiredditSidebar() {
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.getMultireddit(Multireddit.init(name: sub.substring(3, length: sub.length - 3), user: AccountController.currentName), completion: { (result) in
                switch result {
                case .success(let r):
                    DispatchQueue.main.async {
                        self.doDisplayMultiSidebar(r)
                    }
                default:
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Multireddit information not found", color: GMColor.red500Color(), seconds: 3, context: self)
                    }
                }

            })
        } catch {
        }
    }

    @objc func hideReadPosts() {
        dataSource.hideReadPosts { [weak self] (indexPaths: [IndexPath]) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if !indexPaths.isEmpty {
                    self.tableView.performBatchUpdates({
                        self.tableView.deleteItems(at: indexPaths)
                    }, completion: { (_) in
                        self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: self.isGallery)
                        self.tableView.reloadData()
                    })
                }
            }
        }
    }
    
    func hideReadPostsPermanently() {
        dataSource.hideReadPostsPermanently { [weak self] (indexPaths: [IndexPath]) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if !indexPaths.isEmpty {
                    self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: self.isGallery)
                    self.tableView.performBatchUpdates({
                        self.tableView.deleteItems(at: indexPaths)
                    }, completion: { (_) in
                        self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: self.isGallery)
                        self.tableView.reloadData()
                    })
                }
            }
        }
    }

    func resetColors() {
        if single && !(parent is SplitMainViewController) {
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: sub, true)
        }
        setupFab(UIScreen.main.bounds.size)
        if parentController != nil {
            parentController?.colorChanged(ColorUtil.getColorForSub(sub: sub))
        }
    }

    func reloadDataReset() {
        self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: isGallery)
        tableView.reloadData()
        tableView.layoutIfNeeded()
        setupFab(UIScreen.main.bounds.size)
    }
    
    var oldPosition: CGPoint = CGPoint.zero

    @objc func search() {
        let alert = DragDownAlertMenu(title: "Search", subtitle: sub, icon: nil, full: true)
        alert.setSearch(sub)

        let searchAction = {
            alert.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                if !AccountController.isLoggedIn {
                    let alert = UIAlertController(title: "Log in to search!", message: "You must be logged into Reddit to search", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
                    VCPresenter.presentAlert(alert, parentVC: self)
                } else {
                    let search = SearchViewController.init(subreddit: self.sub, searchFor: alert.getText() ?? "")
                    VCPresenter.showVC(viewController: search, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
                }
            }
        }
        
        let searchAllAction = {
            alert.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                if !AccountController.isLoggedIn {
                    let alert = UIAlertController(title: "Log in to search!", message: "You must be logged into Reddit to search", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
                    VCPresenter.presentAlert(alert, parentVC: self)
                } else {
                    let search = SearchViewController.init(subreddit: "all", searchFor: alert.getText() ?? "")
                    VCPresenter.showVC(viewController: search, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
                }
            }
        }

        if sub != "all" && sub != "frontpage" && sub != "popular" && sub != "random" && sub != "randnsfw" && sub != "friends" {
            alert.addTextInput(title: "All results in \(sub)...", icon: nil, enabled: false, action: searchAction, inputPlaceholder: "What are you looking for?", inputIcon: UIImage(sfString: SFSymbol.magnifyingglass, overrideString: "search")!, textRequired: true, exitOnAction: true)
            alert.addAction(title: "All results in all of Reddit...", icon: nil, enabled: true, action: searchAllAction)
        } else {
            alert.addTextInput(title: "All results...", icon: nil, enabled: false, action: searchAllAction, inputPlaceholder: "What are you looking for?", inputIcon: UIImage(sfString: SFSymbol.magnifyingglass, overrideString: "search")!, textRequired: true, exitOnAction: true)
        }
        alert.show(self)
    }
    
    @objc func doDisplaySidebar() {
        Sidebar.init(parent: self, subname: self.sub).displaySidebar()
    }

    func filterContent(_ reload: Bool = false) {
        let alert = AlertController(title: "Content to hide on", message: "r/\(sub)", preferredStyle: .alert)

        let settings = Filter(subreddit: sub, parent: self)
        
        alert.addChild(settings)
        let filterView = settings.view!
        settings.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        alert.setupTheme()
        
        alert.attributedTitle = NSAttributedString(string: "Content to hide on", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
        alert.attributedMessage = NSAttributedString(string: "r/\(sub)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
        
        alert.contentView.addSubview(filterView)
        settings.didMove(toParent: alert)

        filterView.verticalAnchors /==/ alert.contentView.verticalAnchors
        filterView.horizontalAnchors /==/ alert.contentView.horizontalAnchors + 8
        filterView.heightAnchor /==/ CGFloat(50 * settings.tableView(settings.tableView, numberOfRowsInSection: 0))
        alert.addAction(AlertAction(title: "Apply", style: .preferred, handler: { (_) in
            if reload {
                self.dataSource.getData(reload: true, force: true)
            } else {
                self.applyFilters()
            }
        }))

        alert.addBlurView()

        present(alert, animated: true, completion: nil)
    }

    func galleryMode() {
        UserDefaults.standard.set(!isGallery, forKey: "isgallery+" + sub)
        UserDefaults.standard.synchronize()
        isGallery = !isGallery
        self.refresh(true)
    }

    func shadowboxMode() {
        if !VCPresenter.proDialogShown(feature: true, self) && self.dataSource.hasContent() && !dataSource.loading && dataSource.loaded {
            let visibleRect = CGRect(origin: tableView.contentOffset, size: tableView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            let visibleIndexPath = tableView.indexPathForItem(at: visiblePoint)

            let controller = ShadowboxViewController(index: visibleIndexPath?.row ?? 0, submissionDataSource: dataSource)
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func showSortMenu(_ selector: UIView?) {
        let isDefault = UISwitch()
        isDefault.onTintColor = ColorUtil.accentColorForSub(sub: self.sub)
        let defaultLabel = UILabel()
        defaultLabel.text = "Default for sub"
        let group = UIView()
        group.isUserInteractionEnabled = true
        group.addSubviews(isDefault, defaultLabel)
        defaultLabel.textColor = ColorUtil.accentColorForSub(sub: self.sub)
        defaultLabel.centerYAnchor /==/ group.centerYAnchor
        isDefault.leftAnchor /==/ group.leftAnchor
        isDefault.centerYAnchor /==/ group.centerYAnchor
        defaultLabel.leftAnchor /==/ isDefault.rightAnchor + 10
        defaultLabel.rightAnchor /==/ group.rightAnchor

        let actionSheetController = DragDownAlertMenu(title: "Sorting", subtitle: "", icon: nil, extraView: group, themeColor: ColorUtil.accentColorForSub(sub: sub), full: true)
        
        // TODO: show sort default? let defaultSort = SettingValues.getLinkSorting(forSubreddit: self.sub)
        
        for link in LinkSortType.cases {
            if link == LinkSortType.best && sub.lowercased() != "frontpage"{
                continue
            }
            var sortIcon = UIImage()
            switch link {
            case .best:
                sortIcon = UIImage(sfString: SFSymbol.handThumbsupFill, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
            case .hot:
                sortIcon = UIImage(sfString: SFSymbol.flameFill, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
            case .controversial:
                sortIcon = UIImage(sfString: SFSymbol.boltFill, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
            case .new:
                sortIcon = UIImage(sfString: SFSymbol.sparkles, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
            case .rising:
                sortIcon = UIImage(sfString: SFSymbol.arrowUturnUp, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
            case .top:
                if #available(iOS 14, *) {
                    sortIcon = UIImage(sfString: SFSymbol.crownFill, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
                } else {
                    sortIcon = UIImage(sfString: SFSymbol.arrowUp, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
                }
            }
            
            actionSheetController.addAction(title: link.description, icon: sortIcon, primary: dataSource.sorting == link) {
                self.showTimeMenu(s: link, selector: selector, isDefault: isDefault)
            }
        }

        actionSheetController.show(self)
    }

    func showTimeMenu(s: LinkSortType, selector: UIView?, isDefault: UISwitch) {
        if s == .hot || s == .new || s == .rising || s == .best {
            dataSource.sorting = s
            if let mainVC = self.parent as? MainViewController, (!self.single || mainVC is SplitMainViewController) {
                self.doSortImage(mainVC.sortButton)
            } else {
                self.doSortImage(sortButton)
            }

            refresh()
            if isDefault.isOn {
                SettingValues.setSubSorting(forSubreddit: self.sub, linkSorting: s, timePeriod: TimeFilterWithin.hour)
                BannerUtil.makeBanner(text: "Default sorting set", color: ColorUtil.accentColorForSub(sub: self.sub), seconds: 2, context: self, top: false, callback: nil)
            }
            return
        } else {
            let actionSheetController = DragDownAlertMenu(title: "Select a time period", subtitle: "", icon: nil, themeColor: ColorUtil.accentColorForSub(sub: sub), full: true)

            for t in TimeFilterWithin.cases {
                actionSheetController.addAction(title: t.param, icon: nil) {
                    self.dataSource.sorting = s
                    if let mainVC = self.parent as? MainViewController, (!self.single || mainVC is SplitMainViewController) {
                        self.doSortImage(mainVC.sortButton)
                    } else {
                        self.doSortImage(self.sortButton)
                    }

                    self.dataSource.time = t
                    if isDefault.isOn {
                        SettingValues.setSubSorting(forSubreddit: self.sub, linkSorting: s, timePeriod: t)
                        BannerUtil.makeBanner(text: "Default sorting set", color: ColorUtil.accentColorForSub(sub: self.sub), seconds: 2, context: self, top: false, callback: nil)
                    }
                    self.refresh()
                }
            }
            
            actionSheetController.show(self)
        }
    }

    @objc func refresh(_ indicator: Bool = true) {
        if indicator {
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y - (self.refreshControl!.frame.size.height)), animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: {
                self.refreshControl?.beginRefreshing()
            })
        }
        
        dataSource.removeData()
        
        self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: isGallery)
        flowLayout.invalidateLayout()
        UIView.transition(with: self.tableView, duration: 0.10, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        }, completion: nil)
        
        dataSource.getData(reload: true, force: true)
    }

    func deleteSelf(_ cell: LinkCellView) {
        do {
            try session?.deleteCommentOrLink(cell.link!.id, completion: { (_) in
                DispatchQueue.main.async {
                    if self.navigationController!.modalPresentationStyle == .formSheet {
                        self.navigationController!.dismiss(animated: true)
                    } else {
                        self.navigationController!.popViewController(animated: true)
                    }
                }
            })
        } catch {

        }
    }
        
    var hasTopNotch: Bool {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
        }
        return false
    }

    func preloadImages(_ values: [SubmissionObject]) {
        var urls: [URL] = []
        if (SettingValues.dataSavingEnabled && (SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi()) && SettingValues.noImages) || !SettingValues.dataSavingEnabled {
            for submission in values {
                var thumb = submission.hasThumbnail
                var big = submission.hasBanner
                var height = submission.imageHeight
                if submission.url != nil {
                var type = ContentType.getContentType(baseUrl: submission.url)
                if submission.isSelf {
                    type = .SELF
                }

                if thumb && type == .SELF {
                    thumb = false
                } else if type == .SELF && !SettingValues.hideImageSelftext && submission.imageHeight > 0 && SettingValues.postImageMode != .THUMBNAIL {
                    big = true
                }
                
                    if SettingValues.postImageMode == .THUMBNAIL {
                    big = false
                    thumb = true
                }

                let fullImage = ContentType.fullImage(t: type)

                if !fullImage && height < 75 {
                    big = false
                    thumb = true
                } else if big && (SettingValues.postImageMode == .CROPPED_IMAGE) {
                    height = 200
                }

                if type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big || type == .SELF {
                    big = false
                    thumb = false
                }

                if height < 75 {
                    thumb = true
                    big = false
                }

                let shouldShowLq = SettingValues.dataSavingEnabled && submission.isLQ && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi())
                if type == ContentType.CType.SELF && SettingValues.hideImageSelftext
                        || SettingValues.noImages && submission.isSelf {
                    big = false
                    thumb = false
                }

                if big || !submission.hasThumbnail {
                    thumb = false
                }

                if !big && !thumb && submission.type != .SELF && submission.type != .NONE {
                    thumb = true
                }

                if thumb && !big {
                    if submission.thumbnailUrl == "nsfw" {
                    } else if submission.thumbnailUrl == "web" || (submission.thumbnailUrl ?? "").isEmpty {
                    } else {
                        if let url = URL.init(string: submission.thumbnailUrl ?? "") {
                            urls.append(url)
                        }
                    }
                }

                if big {
                    if shouldShowLq {
                        if let url = URL.init(string: submission.lqURL ?? "") {
                            urls.append(url)
                        }

                    } else {
                        if let url = URL.init(string: submission.smallerBannerUrl ?? "") {
                            urls.append(url)
                        }
                    }
                }
            }
        }
        SDWebImagePrefetcher.shared.prefetchURLs(urls)
        }
    }
    
    static func sizeWith(_ submission: SubmissionObject, _ width: CGFloat, _ isCollection: Bool, _ isGallery: Bool) -> CGSize {
        var itemWidth = width
        
        if itemWidth < 10 { //Not a valid width
            itemWidth = UIScreen.main.bounds.width
        }
        var thumb = submission.hasThumbnail
        var big = submission.hasBanner
        
        var submissionHeight = CGFloat(submission.imageHeight)
        
        var type = ContentType.getContentType(baseUrl: submission.url)
        if submission.isSelf {
            type = .SELF
        }
        
        if SettingValues.postImageMode == .THUMBNAIL {
            big = false
            thumb = true
        }
        
        let fullImage = ContentType.fullImage(t: type)
        let halfScreen = UIScreen.main.bounds.height / 2
        
        if !fullImage && submissionHeight < 75 {
            big = false
            thumb = true
        }
        
        if type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big {
            big = false
            thumb = false
        }
        
        if submissionHeight < 75 {
            thumb = true
            big = false
        }
        
        if type == ContentType.CType.SELF && SettingValues.hideImageSelftext
            || SettingValues.noImages && submission.isSelf {
            big = false
            thumb = false
        }
        
        if big || !submission.hasThumbnail {
            thumb = false
        }
        
        if (thumb || big) && submission.isNSFW && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection && isCollection) {
            big = false
            thumb = true
        }
        
        if SettingValues.noImages && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi()) && SettingValues.dataSavingEnabled {
            big = false
            thumb = false
        }
        
        if thumb && type == .SELF {
            thumb = false
        } else if type == .SELF && !SettingValues.hideImageSelftext && submissionHeight > 0 && SettingValues.postImageMode != .THUMBNAIL {
            big = true
        }
        
        if !big && !thumb && submission.type != .SELF && submission.type != .NONE { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
        }
        
        if type == .LINK && SettingValues.linkAlwaysThumbnail && !isGallery {
            thumb = true
            big = false
        }
        
        if (thumb || big) && submission.isSpoiler {
            thumb = true
            big = false
        }
        
        if isGallery {
            big = true
            thumb = false
        }
        
        if big {
            let imageSize = CGSize(width: submission.imageWidth == 0 ? 400 : Double(submission.imageWidth), height: ((SettingValues.postImageMode == .CROPPED_IMAGE) && !isGallery && !(SettingValues.shouldAutoPlay() && (ContentType.displayVideo(t: type) && type != .VIDEO)) ? 200 : (submission.imageHeight == 0 ? 275 : Double(submission.imageHeight))))
            
            var aspect = imageSize.width / imageSize.height
            if aspect == 0 || aspect > 10000 || aspect.isNaN {
                aspect = 1
            }
            if SettingValues.postImageMode == .CROPPED_IMAGE && !isGallery && !(SettingValues.shouldAutoPlay() && (ContentType.displayVideo(t: type) && type != .VIDEO)) {
                aspect = width / 200
                if aspect == 0 || aspect > 10000 || aspect.isNaN {
                    aspect = 1
                }
                
                submissionHeight = 200
            }
        }
        
        var paddingTop = CGFloat(0)
        var paddingBottom = CGFloat(2)
        var paddingLeft = CGFloat(0)
        var paddingRight = CGFloat(0)
        var innerPadding = CGFloat(0)
        
        if (SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !isGallery {
            paddingTop = 5
            paddingBottom = 5
            paddingLeft = 5
            paddingRight = 5
        }
        
        let actionbar = CGFloat(!SettingValues.actionBarMode.isFull() ? 0 : 30) //5px is subtracted from the bottom
        
        let thumbheight = (SettingValues.largerThumbnail ? CGFloat(75) : CGFloat(50)) - (SettingValues.postViewMode == .COMPACT ? 15 : 0)
        let textHeight = CGFloat(submission.isSelf ? 5 : 0)
        
        if thumb {
            innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 8 : 12) //between top and thumbnail
            innerPadding -= 5 //ThumbLinkCellView L#65
            if SettingValues.actionBarMode.isFull() {
                innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 4 : 8) //between label and bottom box
                innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 4 : 8) //between box and end
                innerPadding -= 5 //LinkCellView L#1191
            } else {
                innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 8 : 12) //between thumbnail and bottom
            }
        } else if big {
            if SettingValues.postViewMode == .CENTER {
                innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 8 : 16) //between label
                if SettingValues.actionBarMode.isFull() {
                    innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 8 : 12) //between banner and box
                } else {
                    innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 8 : 12) //between buttons and bottom
                }
            } else {
                innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 4 : 8) //between banner and label
                if SettingValues.actionBarMode.isFull() {
                    innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 8 : 12) //between label and box
                } else {
                    innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 4 : 8) //between label and bottom
                }
            }
            if SettingValues.actionBarMode.isFull() {
                innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 4 : 8) //between box and end
                innerPadding -= 5 //LinkCellView L#1191
            }
        } else {
            innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between top and title
            if SettingValues.actionBarMode.isFull() {
                innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 4 : 8) //between box and end
                innerPadding -= 5 //LinkCellView L#1191
            } else {
                innerPadding += (SettingValues.postViewMode == .COMPACT || isGallery ? 4 : 8) //between title and bottom
            }
        }
        
        var estimatedUsableWidth = itemWidth - paddingLeft - paddingRight
        if thumb {
            estimatedUsableWidth -= thumbheight //is the same as the width
            estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT || isGallery ? 8 : 12) //between edge and thumb
            if !SettingValues.actionBarMode.isSide() {
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT || isGallery ? 8 : 12) //title label padding left
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT || isGallery ? 4 : 8) //title label padding right
            }
        } else if !SettingValues.actionBarMode.isSide() { //Not side
            estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT || isGallery ? 16 : 24) //title label padding
        }

        if big && SettingValues.postImageMode == .CROPPED_IMAGE && !(SettingValues.shouldAutoPlay() && (ContentType.displayVideo(t: type) && type != .VIDEO)) {
            submissionHeight = 200
        } else if big && SettingValues.postImageMode == .SHORT_IMAGE && !(SettingValues.shouldAutoPlay() && (ContentType.displayVideo(t: type) && type != .VIDEO)) {
            let bannerPadding = (SettingValues.postViewMode != .CARD || isGallery) ? (isGallery ? CGFloat(3) : CGFloat(5)) : CGFloat(0)
            let tempHeight = getHeightFromAspectRatio(imageHeight: submissionHeight == 200 ? CGFloat(200) : CGFloat(submission.imageHeight == 0 ? 275 : submission.imageHeight), imageWidth: CGFloat(submission.imageWidth == 0 ? 400 : submission.imageWidth), viewWidth: width - paddingLeft - paddingRight - (bannerPadding * 2))
            submissionHeight = tempHeight > halfScreen ? halfScreen : tempHeight
        } else if big {
            let bannerPadding = (SettingValues.postViewMode != .CARD || isGallery) ? (isGallery ? CGFloat(3) : CGFloat(5)) : CGFloat(0)
            submissionHeight = getHeightFromAspectRatio(imageHeight: submissionHeight == 200 ? CGFloat(200) : CGFloat(submission.imageHeight == 0 ? 275 : submission.imageHeight), imageWidth: CGFloat(submission.imageWidth == 0 ? 400 : submission.imageWidth), viewWidth: width - paddingLeft - paddingRight - (bannerPadding * 2))
        }
        
        if type == .SELF && !SettingValues.hideImageSelftext && submissionHeight > 200 && SettingValues.postImageMode != .THUMBNAIL {
             submissionHeight = 200
        }
        
        var imageHeight = big && !thumb ? CGFloat(submissionHeight) : CGFloat(0)
        
        if thumb {
            imageHeight = thumbheight
        }
        
        if SettingValues.actionBarMode.isSide() {
            estimatedUsableWidth -= 40
            estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 4 : 8) //buttons left margin
            estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 4 : 8) //buttons right margin with title
            if thumb {
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 4 : 8) //title side padding
            } else {
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 8 : 12) //title side padding
            }
        }
                
        let height = CachedTitle.getTitleAttributedString(submission, force: false, gallery: isGallery, full: false, loadImages: false).height(containerWidth: estimatedUsableWidth)
        
        if height < 100000 { //Make sure it's a valid height
            var totalHeight = paddingTop + paddingBottom
            if thumb {
                totalHeight += max(SettingValues.actionBarMode.isSide() ? 62 : 0, ceil(height), imageHeight)
            } else {
                totalHeight += max(SettingValues.actionBarMode.isSide() ? 62 : 0, ceil(height)) + imageHeight
            }
                 
            totalHeight += innerPadding + actionbar + textHeight
            if SettingValues.postViewMode != .CARD || isGallery {
                totalHeight += 5
            }
            
            return CGSize(width: itemWidth, height: totalHeight)
        } else { //If layout is nil, just return a size that won't crash the app...
            let textSize = CGSize(width: 100, height: 100)

            let totalHeight = paddingTop + paddingBottom + (thumb ? max(SettingValues.actionBarMode.isSide() ? 72 : 0, ceil(textSize.height), imageHeight) : max(SettingValues.actionBarMode.isSide() ? 72 : 0, ceil(textSize.height)) + imageHeight) + innerPadding + actionbar + textHeight + CGFloat(5) + CGFloat(SettingValues.postViewMode == .CARD && !isGallery ? -5 : 0) + CGFloat(submission.awardsDictionary.keys.count > 0 ? 23 : 0)
            return CGSize(width: itemWidth, height: totalHeight)
        }
    }
    
    // TODO: - This is mostly replicated by `Submission.getLinkView()`. Can we consolidate?
    static func cellType(foSubmission submission: SubmissionObject, _ isCollection: Bool, cellWidth: CGFloat) -> CurrentType {
        var target: CurrentType = .none

        var thumb = submission.hasThumbnail
        var big = submission.hasBanner
        let height = CGFloat(submission.imageHeight)

        var type = ContentType.getContentType(baseUrl: submission.url)
        if submission.isSelf {
            type = .SELF
        }

        if SettingValues.postImageMode == .THUMBNAIL {
            big = false
            thumb = true
        }

        let fullImage = ContentType.fullImage(t: type)

        var submissionHeight = height == 0 ? 275 : height
        if !fullImage && submissionHeight < 75 {
            big = false
            thumb = true
        } else if big && SettingValues.postImageMode == .CROPPED_IMAGE {
            submissionHeight = 200
        } else if big {
            let h = getHeightFromAspectRatio(imageHeight: submissionHeight, imageWidth: CGFloat(submission.imageWidth == 0 ? 400 : submission.imageWidth), viewWidth: cellWidth)
            if h == 0 {
                submissionHeight = 200
            } else {
                submissionHeight = h
            }
        }

        if type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big {
            big = false
            thumb = false
        }

        if submissionHeight < 75 {
            thumb = true
            big = false
        }

        if type == ContentType.CType.SELF && SettingValues.hideImageSelftext
            || SettingValues.noImages && submission.isSelf {
            big = false
            thumb = false
        }

        if big || !submission.hasThumbnail {
            thumb = false
        }
        
        if SettingValues.noImages && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi()) && SettingValues.dataSavingEnabled {
            big = false
            thumb = false
        }
        
        if thumb && type == .SELF {
            thumb = false
        }

        if !big && !thumb && submission.type != .SELF && submission.type != .NONE { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
        }

        if (thumb || big) && submission.isNSFW && (!SettingValues.nsfwPreviews || (SettingValues.hideNSFWCollection && isCollection)) {
            big = false
            thumb = true
        }
        
        if (thumb || big) && submission.isSpoiler {
            thumb = true
            big = false
        }

        if thumb && !big {
            target = .thumb
        } else if big {
            if SettingValues.autoPlayMode != .NEVER && (ContentType.displayVideo(t: type) && type != .VIDEO) {
                target = .autoplay
            } else {
                target = .banner
            }
        } else {
            target = .text
        }
        
        if big && submissionHeight < 75 {
            target = .thumb
        }

        if type == .LINK && SettingValues.linkAlwaysThumbnail {
            target = .thumb
        }

        return target
    }
    
    var loop: SelectorEventLoop?
    var server: DefaultHTTPServer?
    
    func addToHomescreen() {
        DispatchQueue.global(qos: .background).async { () -> Void in
            self.loop = try! SelectorEventLoop(selector: try! KqueueSelector())
            self.server = DefaultHTTPServer(eventLoop: self.loop!, port: 8080) { (_, startResponse: ((String, [(String, String)]) -> Void), sendBody: ((Data) -> Void)
                ) in
                // Start HTTP response
                startResponse("200 OK", [])
                
                let sub = ColorUtil.getColorForSub(sub: self.sub)
                let lighterSub = sub.add(overlay: UIColor.white.withAlphaComponent(0.4))
                var coloredIcon = UIImage.convertGradientToImage(colors: [lighterSub, sub], frame: CGSize.square(size: 150))
                coloredIcon = coloredIcon.overlayWith(image: UIImage(named: "slideoverlay")!.getCopy(withSize: CGSize.square(size: 150)), posX: 0, posY: 0)
                let imageData: Data = coloredIcon.pngData()! 
                let base64String = imageData.base64EncodedString()

                // send EOF
                let baseHTML = Bundle.main.url(forResource: "html", withExtension: nil)!
                var htmlString = try! String.init(contentsOf: baseHTML, encoding: String.Encoding.utf8)
                htmlString = htmlString.replacingOccurrences(of: "{{subname}}", with: self.sub)
                htmlString = htmlString.replacingOccurrences(of: "{{subcolor}}", with: ColorUtil.getColorForSub(sub: self.sub).toHexString())
                htmlString = htmlString.replacingOccurrences(of: "{{subicon}}", with: base64String)

                print(htmlString)
                let bodyString = htmlString.toBase64()
                sendBody(Data.init(base64Encoded: bodyString!)!)
                sendBody(Data())
            }
            
            // Start HTTP server to listen on the port
            do {
                try self.server?.start()
            } catch let error {
                print(error)
                self.server?.stop()
                do {
                    try self.server?.start()
                } catch {
                    
                }
            }
            
            // Run event loop
            self.loop?.runForever()
            
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL.init(string: "http://[::1]:8080/foo-bar")!)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(URL.init(string: "http://[::1]:8080/foo-bar")!)
        }
    }
}

extension SingleSubredditViewController: SubmissionDataSouceDelegate {
    func vcIsGallery() -> Bool {
        return isGallery
    }
    
    func showIndicator() {
        if indicator == nil {
            //TODO implement something like this and get rid of Google https://medium.com/better-programming/lets-build-a-circular-loading-indicator-in-swift-5-b06fcdf1260d
            indicator = MDCActivityIndicator.init(frame: CGRect.init(x: CGFloat(0), y: CGFloat(0), width: CGFloat(80), height: CGFloat(80)))
            indicator?.strokeWidth = 5
            indicator?.radius = 15
            indicator?.indicatorMode = .indeterminate
            indicator?.cycleColors = [ColorUtil.getColorForSub(sub: sub), ColorUtil.accentColorForSub(sub: sub)]
            self.view.addSubview(indicator!)
            indicator!.centerAnchors /==/ self.view.centerAnchors
            indicator?.startAnimating()
        }
    }
    
    func generalError(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "Close", style: .default, handler: { (_) in
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        self.refreshControl.endRefreshing()
    }
        
    func loadSuccess(before: Int, count: Int) {
        self.oldPosition = CGPoint.zero
        var paths = [IndexPath]()
        emptyStateView.isHidden = true
        
        if count < before {
            self.flowLayout.invalidateLayout()
            self.tableView.reloadData()
            return
        }
        for i in before..<count {
            paths.append(IndexPath.init(item: i + self.headerOffset(), section: 0))
        }

        if before == 0 {
            self.flowLayout.invalidateLayout()
            UIView.transition(with: self.tableView, duration: 0.15, options: .transitionCrossDissolve, animations: {
                self.tableView.reloadData()
            }, completion: { [weak self] (_) in
                guard let self = self else { return }

                self.autoplayHandler.autoplayOnce(self.tableView)
            })

            let navOffset = (-1 * ( (self.navigationController?.navigationBar.frame.size.height ?? 64)))
            var statusBarHeight = UIApplication.shared.statusBarUIView?.frame.size.height ?? 0
            if statusBarHeight == 0 {
                statusBarHeight = (self.navigationController?.navigationBar.frame.minY ?? 20)
            }

            var topOffset = (-1 * statusBarHeight)
            if self.navigationController?.modalPresentationStyle == .pageSheet && self.navigationController?.viewControllers.count == 1 && !(self.navigationController?.viewControllers[0] is MainViewController) {
                topOffset = 0
            }
            let headerHeight = (UIDevice.current.userInterfaceIdiom == .pad && SettingValues.appMode == .MULTI_COLUMN ? 0 : self.headerHeight(false))
            let paddingOffset = CGFloat(headerHeight == 0 ? -4 : 0)
            
            setOffset = paddingOffset + navOffset + topOffset + headerHeight
            
            let newNavOffset = self.navigationController?.navigationBar.frame.size.height ?? 64
            var newTopOffset = statusBarHeight
            if self.navigationController?.modalPresentationStyle == .pageSheet && self.navigationController?.viewControllers.count == 1 && !(self.navigationController?.viewControllers[0] is MainViewController) {
                newTopOffset = 0
            }

            if newNavOffset + newTopOffset + 8 > self.tableView.contentInset.top {
                self.tableView.contentInset = UIEdgeInsets.init(top: CGFloat(newNavOffset + newTopOffset + 8), left: 0, bottom: 65, right: 0)
            }

            self.tableView.contentOffset = CGPoint.init(x: 0, y: setOffset)
        } else {
            self.flowLayout.invalidateLayout()
            self.tableView.insertItems(at: paths)
        }
        self.tableView.isUserInteractionEnabled = true

        self.indicator?.stopAnimating()
        self.indicator?.isHidden = true
        self.refreshControl.endRefreshing()
        if MainViewController.first {
            MainViewController.first = false
            self.parentController?.checkForMail()
            self.parentController?.checkSubs()
        }
        
        oldCount = dataSource.content.count
    }
    
    func preLoadItems() {
        self.isGallery = UserDefaults.standard.bool(forKey: "isgallery+" + sub)
        self.emptyStateView.isHidden = true
        PagingCommentViewController.savedComment = nil
        LinkCellView.checkedWifi = false
    }
    
    func loadOffline() {
        self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: self.isGallery)
        self.tableView.reloadData()
        
        self.refreshControl.endRefreshing()
        self.indicator?.stopAnimating()
        self.indicator?.isHidden = true
        
        let navOffset = self.navigationController?.navigationBar.frame.size.height ?? 64
        var statusBarHeight = UIApplication.shared.statusBarUIView?.frame.size.height ?? 0
        if statusBarHeight == 0 {
            statusBarHeight = (self.navigationController?.navigationBar.frame.minY ?? 20)
        }

        var topOffset = statusBarHeight
        if self.navigationController?.modalPresentationStyle == .pageSheet && self.navigationController?.viewControllers.count == 1 && !(self.navigationController?.viewControllers[0] is MainViewController) {
            topOffset = 0
        }

        self.tableView.contentInset = UIEdgeInsets.init(top: CGFloat(navOffset + topOffset + 8), left: 0, bottom: 65, right: 0)

        DispatchQueue.main.async {
            self.dataSource.handleTries { [weak self] (isEmpty: Bool) in
                guard let self = self else { return }
                
                if isEmpty {
                    self.emptyStateView.setText(title: "No offline content found!", message: "When online, you can set up subreddit caching in Settings > Auto Cache")
                    self.emptyStateView.isHidden = false
                } else {
                    self.navigationItem.titleView = self.setTitle(title: self.sub, subtitle: "Content \(DateFormatter().timeSince(from: self.dataSource.updated as NSDate, numericDates: true)) old")
                }
            }
        }
        
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.tableView)
    }
    
    func doPreloadImages(values: [SubmissionObject]) {
        self.preloadImages(values)
    }
    
    func emptyState(_ listing: Listing) {
        self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: self.isGallery)
        self.tableView.reloadData()
        
        self.refreshControl.endRefreshing()
        self.indicator?.stopAnimating()
        self.indicator?.isHidden = true
        if MainViewController.first {
            MainViewController.first = false
            self.parentController?.checkForMail()
        }
        
        if listing.children.isEmpty {
            self.emptyStateView.setText(title: "Nothing to see here!", message: "No content was found on this subreddit with \(dataSource.sorting.path.substring(1, length: dataSource.sorting.path.length - 1)) sorting.")
            self.emptyStateView.isHidden = false
        } else {
            self.emptyStateView.setText(title: "Nothing to see here!", message: "All posts were filtered while loading this subreddit. Check your global filters in Slide's Settings, or tap here to view this subreddit's content filters")
            self.emptyStateView.isHidden = false
            self.emptyStateView.addTapGestureRecognizer { (_) in
                self.filterContent(true)
            }
        }

    }
}

// MARK: - Actions
extension SingleSubredditViewController {

    @objc func spacePressed() {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.tableView.contentOffset.y = min(self.tableView.contentOffset.y + 350, self.tableView.contentSize.height - self.tableView.frame.size.height)
        }, completion: nil)
    }
    
    @objc func spacePressedUp() {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.tableView.contentOffset.y = max(self.tableView.contentOffset.y - 350, -64)
        }, completion: nil)
    }

    @objc func drefresh(_ sender: AnyObject) {
        refresh()
    }

    @objc func showMoreNone(_ sender: AnyObject) {
        showMore(sender, parentVC: nil)
    }
    
    @available(iOS 14.0, *)
    func editTheme() {
        let vc = SubredditThemeEditViewController(subreddit: sub, delegate: self)
        VCPresenter.presentModally(viewController: vc, self, CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: 300))
    }
    
    @objc func pickTheme(sender: AnyObject?, parent: MainViewController?) {
        parentController = parent
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        isAccent = false
        let margin: CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 314 - margin * 4.0: alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.scrollToPreselectedIndex = true
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColor()
        MKColorPicker.selectionStyle = .check
        MKColorPicker.scrollDirection = .vertical
        MKColorPicker.style = .circle

        let baseColor = ColorUtil.getColorForSub(sub: sub).toHexString()
        var index = 0
        for color in GMPalette.allColor() {
            if color.toHexString() == baseColor {
                break
            }
            index += 1
        }

        MKColorPicker.preselectedIndex = index

        alertController.view.addSubview(MKColorPicker)

        // TODO: - maybe ?
        /*alertController.addAction(image: UIImage(named: "accent"), title: "Custom color", color: ColorUtil.accentColorForSub(sub: sub), style: .default, isEnabled: true) { (action) in
         if(!VCPresenter.proDialogShown(feature: false, self)){
         let alert = UIAlertController.init(title: "Choose a color", message: nil, preferredStyle: .actionSheet)
         alert.addColorPicker(color: (self.navigationController?.navigationBar.barTintColor)!, selection: { (c) in
         ColorUtil.setColorForSub(sub: self.sub, color: (self.navigationController?.navigationBar.barTintColor)!)
         self.reloadDataReset()
         self.navigationController?.navigationBar.barTintColor = c
         UIApplication.shared.statusBarUIView?.backgroundColor = c
         self.sideView.backgroundColor = c
         self.add.backgroundColor = c
         self.sideView.backgroundColor = c
         if (self.parentController != nil) {
         self.parentController?.colorChanged()
         }
         })
         alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
         self.pickTheme(sender: sender, parent: parent)
         }))
         self.present(alert, animated: true)
         }

         }*/

        alertController.addAction(image: UIImage(named: "colors"), title: "Accent color", color: ColorUtil.accentColorForSub(sub: sub), style: .default) { _ in
            ColorUtil.setColorForSub(sub: self.sub, color: self.primaryChosen ?? ColorUtil.baseColor)
            self.pickAccent(sender: sender, parent: parent)
            if self.parentController != nil {
                self.parentController?.colorChanged(ColorUtil.getColorForSub(sub: self.sub))
            }
            self.reloadDataReset()
        }

        alertController.addAction(image: nil, title: "Save", color: ColorUtil.accentColorForSub(sub: sub), style: .default) { _ in
            ColorUtil.setColorForSub(sub: self.sub, color: self.primaryChosen ?? ColorUtil.baseColor)
            self.reloadDataReset()
            if self.parentController != nil {
                self.parentController?.colorChanged(ColorUtil.getColorForSub(sub: self.sub))
            }
        }

        alertController.addCancelButton()

        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = sender as! UIButton
            presenter.sourceRect = (sender as! UIButton).bounds
        }

        present(alertController, animated: true, completion: nil)
    }
    
    func pickAccent(sender: AnyObject?, parent: MainViewController?) {
        parentController = parent
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        isAccent = true
        let margin: CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 314 - margin * 4.0: alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.scrollToPreselectedIndex = true
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColorAccent()
        MKColorPicker.selectionStyle = .check
        MKColorPicker.scrollDirection = .vertical
        MKColorPicker.style = .circle

        let baseColor = ColorUtil.accentColorForSub(sub: sub).toHexString()
        var index = 0
        for color in GMPalette.allColorAccent() {
            if color.toHexString() == baseColor {
                break
            }
            index += 1
        }

        MKColorPicker.preselectedIndex = index

        alertController.view.addSubview(MKColorPicker)

        alertController.addAction(image: UIImage(named: "palette"), title: "Primary color", color: ColorUtil.accentColorForSub(sub: sub), style: .default) { _ in
            ColorUtil.setAccentColorForSub(sub: self.sub, color: self.accentChosen ?? ColorUtil.accentColorForSub(sub: self.sub))
            self.pickTheme(sender: sender, parent: parent)
            self.reloadDataReset()
        }

        alertController.addAction(image: nil, title: "Save", color: ColorUtil.accentColorForSub(sub: sub), style: .default) { _ in
            ColorUtil.setAccentColorForSub(sub: self.sub, color: self.accentChosen!)
            self.reloadDataReset()
            if self.parentController != nil {
                self.parentController?.colorChanged(ColorUtil.getColorForSub(sub: self.sub))
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_: UIAlertAction!) in
            self.resetColors()
        })

        alertController.addAction(cancelAction)

        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = sender as! UIButton
            presenter.sourceRect = (sender as! UIButton).bounds
        }

        present(alertController, animated: true, completion: nil)
    }

    @objc func newPost(_ sender: AnyObject) {
        PostActions.showPostMenu(self, sub: self.sub)
    }

    @objc func showMore(_ sender: AnyObject, parentVC: MainViewController? = nil) {

        let alertController = DragDownAlertMenu(title: "Subreddit options", subtitle: sub, icon: nil)
        
        let special = !(sub != "all" && sub != "frontpage" && sub != "popular" && sub != "random" && sub != "randnsfw" && sub != "friends" && !sub.startsWith("/m/"))
        
        alertController.addAction(title: "Search", icon: UIImage(sfString: SFSymbol.magnifyingglass, overrideString: "search")!.menuIcon()) {
            self.search()
        }

        if single && !special {
            alertController.addAction(title: Subscriptions.isSubscriber(self.sub) ? "Un-subscribe" : "Subscribe", icon: UIImage(named: Subscriptions.isSubscriber(self.sub) ? "subbed" : "addcircle")!.menuIcon()) {
                self.subscribeSingle(sender)
            }
        }

        alertController.addAction(title: "Sort (currently \(dataSource.sorting.path))", icon: UIImage(named: "filter")!.menuIcon()) {
            self.showSortMenu(self.more)
        }

        if sub.contains("/m/") {
            alertController.addAction(title: "Manage multireddit", icon: UIImage(sfString: SFSymbol.infoCircle, overrideString: "info")!.menuIcon()) {
                self.displayMultiredditSidebar()
            }
        } else if !special {
            alertController.addAction(title: "Show sidebar", icon: UIImage(sfString: SFSymbol.infoCircle, overrideString: "info")!.menuIcon()) {
                self.doDisplaySidebar()
            }
        }
        
        alertController.addAction(title: "Edit \(sub) theme", icon: generateThemePreviewImage(subreddit: sub).getCopy(withSize: CGSize(width: 20, height: 20))) {
            if #available(iOS 14, *) {
                self.editTheme()
            } else {
                if parentVC != nil {
                    let p = (parentVC!)
                    self.pickTheme(sender: sender, parent: p)
                } else {
                    self.pickTheme(sender: sender, parent: nil)
                }
            }
        }

        alertController.addAction(title: "Cache for offline viewing", icon: UIImage(sfString: SFSymbol.arrow2Circlepath, overrideString: "save-1")!.menuIcon()) {
            _ = AutoCache.init(subs: [self.sub])
        }

        alertController.addAction(title: "Shadowbox", icon: UIImage(named: "shadowbox")!.menuIcon()) {
            self.shadowboxMode()
        }

        alertController.addAction(title: "Hide read posts", icon: UIImage(sfString: SFSymbol.xmark, overrideString: "hide")!.menuIcon()) {
            self.hideReadPosts()
        }

        alertController.addAction(title: "Refresh posts", icon: UIImage(sfString: SFSymbol.arrow2Circlepath, overrideString: "sync")!.menuIcon()) {
            self.refresh()
        }

        alertController.addAction(title: "\(self.isGallery ? "Disable" : "Enable") Gallery view", icon: UIImage(sfString: SFSymbol.photoFillOnRectangleFill, overrideString: "image")!.menuIcon()) {
            self.galleryMode()
        }

        if !special {
            alertController.addAction(title: "Submit new post", icon: UIImage(sfString: SFSymbol.pencil, overrideString: "edit")!.menuIcon()) {
                self.newPost(sender)
            }
        }

        alertController.addAction(title: "Filter content from \(sub)", icon: UIImage(named: "filter")!.menuIcon()) {
            if self.dataSource.hasContent() || self.dataSource.loaded {
                self.filterContent()
            }
        }

        alertController.addAction(title: "Add homescreen shortcut", icon: UIImage(sfString: SFSymbol.plusSquareFill, overrideString: "add_homescreen")!.menuIcon()) {
            self.addToHomescreen()
        }

        alertController.show(self)
    }
    
    func generateThemePreviewImage(subreddit: String) -> UIImage {
        let baseImage = UIImage(named: "circle")!
        let rect = CGRect(x: 0, y: 0, width: baseImage.size.width, height: baseImage.size.height)

        UIGraphicsBeginImageContextWithOptions(baseImage.size, false, baseImage.scale)
        baseImage.draw(in: rect)

        let context = UIGraphicsGetCurrentContext()!
        context.setBlendMode(CGBlendMode.sourceIn)

        context.setFillColor(ColorUtil.getColorForSub(sub: subreddit).cgColor)

        var rectToFill = CGRect(x: 0, y: 0, width: baseImage.size.width * 0.5, height: baseImage.size.height)
        context.fill(rectToFill)

        context.setFillColor(ColorUtil.accentColorForSub(sub: subreddit).cgColor)

        rectToFill = CGRect(x: baseImage.size.width * 0.5, y: 0, width: baseImage.size.width, height: baseImage.size.height)
        context.fill(rectToFill)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

}

// MARK: - Collection View Delegate
extension SingleSubredditViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let cell = cell as? AutoplayBannerLinkCellView {
            if cell.videoView != nil {
                cell.endVideos()
                self.currentPlayingIndex = self.currentPlayingIndex.filter({ (included) -> Bool in
                    return included.row != indexPath.row
                })
            }
        }
        if let cell = cell as? GalleryLinkCellView {
            if cell.videoView != nil {
                cell.endVideos()
                self.currentPlayingIndex = self.currentPlayingIndex.filter({ (included) -> Bool in
                    return included.row != indexPath.row
                })
            }
        }
    }
}

extension SingleSubredditViewController: UIScrollViewDelegate {
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if scrollView.contentOffset.y > oldPosition.y {
            oldPosition = scrollView.contentOffset
            return true
        } else {
            tableView.setContentOffset(oldPosition, animated: true)
            oldPosition = CGPoint.zero
        }
        return false
    }
    
    func markReadScroll() {
        if SettingValues.markReadOnScroll {
            let top = tableView.indexPathsForVisibleItems
            print(top)
            print(lastTopItem)
            if !top.isEmpty {
                let topItem = top[0].row - 1
                if topItem > lastTopItem && topItem < dataSource.content.count {
                    for item in lastTopItem..<topItem {
                        History.addSeen(s: dataSource.content[item], skipDuplicates: true)
                    }
                    lastTopItem = topItem
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        markReadScroll()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        markReadScroll()
    }
}

// MARK: - Collection View Data Source
extension SingleSubredditViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (dataSource.loaded && (!dataSource.loading || dataSource.hasContent()) ? headerOffset() : 0) + dataSource.content.count + (dataSource.loaded && !dataSource.isReset && dataSource.hasContent() ? 1 : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var row = indexPath.row
        if row == 0 && hasHeader {
            let cell = tableView.dequeueReusableCell(withReuseIdentifier: "header\(headerVersion)", for: indexPath) as! LinksHeaderCellView
            cell.setLinks(links: self.subLinks, sub: self.sub, delegate: self)
            return cell
        }
        if hasHeader {
            row -= 1
        }
        if row >= dataSource.content.count {
            if dataSource.nomore {
                let cell = tableView.dequeueReusableCell(withReuseIdentifier: "nothing", for: indexPath) as! NothingHereCell
                if dataSource.content.count < 10 {
                    let title = NSMutableAttributedString(string: "You've reached the end!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
                    title.append(NSAttributedString(string: "\n"))
                    title.append(NSMutableAttributedString(string: "\(numberFiltered) posts were filtered out", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.fontColor]))
                    cell.text.attributedText = title
                }
                
                return cell
            }
            let cell = tableView.dequeueReusableCell(withReuseIdentifier: "loading", for: indexPath) as! LoadingCell
            cell.loader.color = UIColor.fontColor
            cell.loader.startAnimating()
            if !dataSource.loading && !dataSource.nomore {
                dataSource.getData(reload: false)
            }
            return cell
        }

        let submission = dataSource.content[row]

        if submission.author == "PAGE_SEPARATOR" {
            let cell = tableView.dequeueReusableCell(withReuseIdentifier: "page", for: indexPath) as! PageCell
            
            let textParts = submission.title.components(separatedBy: "\n")
            
            let finalText: NSMutableAttributedString!
            if textParts.count > 1 {
                let firstPart = NSMutableAttributedString.init(string: textParts[0], attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)])
                let secondPart = NSMutableAttributedString.init(string: "\n" + textParts[1], attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)])
                firstPart.append(secondPart)
                finalText = firstPart
            } else {
                finalText = NSMutableAttributedString.init(string: submission.title, attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)])
            }

            cell.time.font = UIFont.systemFont(ofSize: 12)
            cell.time.textColor = UIColor.fontColor
            cell.time.alpha = 0.7
            cell.time.text = submission.subreddit
            
            cell.title.attributedText = finalText
            return cell
        }

        var cell: LinkCellView!
        
        if lastVersion != SingleSubredditViewController.cellVersion {
            self.tableView.register(BannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "banner\(SingleSubredditViewController.cellVersion)")
            self.tableView.register(GalleryLinkCellView.classForCoder(), forCellWithReuseIdentifier: "gallery\(SingleSubredditViewController.cellVersion)")
            self.tableView.register(AutoplayBannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "autoplay\(SingleSubredditViewController.cellVersion)")
            self.tableView.register(ThumbnailLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb\(SingleSubredditViewController.cellVersion)")
            self.tableView.register(TextLinkCellView.classForCoder(), forCellWithReuseIdentifier: "text\(SingleSubredditViewController.cellVersion)")
        }
        
        var numberOfColumns = CGFloat.zero
        let portraitCount = SettingValues.portraitMultiColumnCount
        
        let pad = UIScreen.main.traitCollection.userInterfaceIdiom == .pad
        
        if SettingValues.appMode == .MULTI_COLUMN {
            if UIApplication.shared.statusBarOrientation.isPortrait {
                if UIScreen.main.traitCollection.userInterfaceIdiom != .pad {
                    numberOfColumns = 1
                } else {
                    numberOfColumns = CGFloat(portraitCount)
                }
            } else {
                numberOfColumns = CGFloat(SettingValues.multiColumnCount)
            }
        } else {
            numberOfColumns = 1
        }
        
        if pad && UIApplication.shared.keyWindow?.frame != UIScreen.main.bounds {
            numberOfColumns = 1
        }
        
        if isGallery {
            numberOfColumns = CGFloat(SettingValues.galleryCount)
        }

        let tableWidth = self.tableView.frame.size.width
        if isGallery {
            cell = tableView.dequeueReusableCell(withReuseIdentifier: "gallery\(SingleSubredditViewController.cellVersion)", for: indexPath) as! GalleryLinkCellView
        } else {
            switch SingleSubredditViewController.cellType(foSubmission: submission, Subscriptions.isCollection(sub), cellWidth: (tableWidth == 0 ? UIScreen.main.bounds.size.width : tableWidth) / numberOfColumns ) {
            case .thumb:
                cell = tableView.dequeueReusableCell(withReuseIdentifier: "thumb\(SingleSubredditViewController.cellVersion)", for: indexPath) as! ThumbnailLinkCellView
            case .autoplay:
                cell = tableView.dequeueReusableCell(withReuseIdentifier: "autoplay\(SingleSubredditViewController.cellVersion)", for: indexPath) as! AutoplayBannerLinkCellView
            case .banner:
                cell = tableView.dequeueReusableCell(withReuseIdentifier: "banner\(SingleSubredditViewController.cellVersion)", for: indexPath) as! BannerLinkCellView
            default:
                if !SettingValues.hideImageSelftext && submission.imageHeight > 0 {
                    cell = tableView.dequeueReusableCell(withReuseIdentifier: "banner\(SingleSubredditViewController.cellVersion)", for: indexPath) as! BannerLinkCellView
                } else {
                    cell = tableView.dequeueReusableCell(withReuseIdentifier: "text\(SingleSubredditViewController.cellVersion)", for: indexPath) as! TextLinkCellView
                }
            }
        }
        
        cell.preservesSuperviewLayoutMargins = false
        cell.del = self
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        
        //cell.panGestureRecognizer?.require(toFail: self.tableView.panGestureRecognizer)
        //ecell.panGestureRecognizer2?.require(toFail: self.tableView.panGestureRecognizer)

        if row > dataSource.content.count - 4 {
            if !dataSource.loading && !dataSource.nomore {
                self.dataSource.getData(reload: false)
            }
        }
        return cell
    }
}

// MARK: - Collection View Prefetching Data Source
//extension SingleSubredditViewController: UICollectionViewDataSourcePrefetching {
//    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
//        // TODO: - Implement
//    }
//}

// MARK: - Link Cell View Delegate
extension SingleSubredditViewController: LinkCellViewDelegate {

    func openComments(id: String, subreddit: String?) {
        if let nav = ((self.splitViewController?.viewControllers.count ?? 0 > 1) ? self.splitViewController?.viewControllers[1] : nil) as? UINavigationController, let detail = nav.viewControllers[0] as? PagingCommentViewController {
            if detail.submissionDataSource.content[detail.startIndex].id == id {
                return
            }
        }
        var index = 0
        for s in dataSource.content {
            if s.id == id {
                break
            }
            index += 1
        }

        let comment = PagingCommentViewController.init(submissionDataSource: dataSource, currentIndex: index, reloadCallback: { [weak self] in
            if let strongSelf = self {
                strongSelf.tableView.reloadData()
            }
            return
        })
        VCPresenter.showVC(viewController: comment, popupIfPossible: (UIDevice.current.userInterfaceIdiom == .pad && SettingValues.disablePopupIpad || UIDevice.current.userInterfaceIdiom != .pad) ? false : true, parentNavigationController: self.navigationController, parentViewController: self)
    }
}

// MARK: - Color Picker View Delegates
extension SingleSubredditViewController: ColorPickerViewDelegate {
    public func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        self.fab?.backgroundColor = ColorUtil.getNavColorForSub(sub: sub) ?? ColorUtil.accentColorForSub(sub: sub)
        CachedTitle.titles.removeAll()
        
        headerVersion += 1
        self.tableView.register(LinksHeaderCellView.classForCoder(), forCellWithReuseIdentifier: "header\(headerVersion)")

        self.tableView.reloadData()
        if let parent = self.parentController as? SplitMainViewController {
            parent.tabBar.collectionView.reloadData()
            parent.doToolbarOffset()
        }
    }
}

extension SingleSubredditViewController: SubredditThemeEditViewControllerDelegate {
    public func didChangeColors(_ isAccent: Bool, color: UIColor) {
        self.fab?.backgroundColor = ColorUtil.getNavColorForSub(sub: sub) ?? ColorUtil.accentColorForSub(sub: sub)
        CachedTitle.titles.removeAll()
        
        headerVersion += 1
        self.tableView.register(LinksHeaderCellView.classForCoder(), forCellWithReuseIdentifier: "header\(headerVersion)")

        self.tableView.reloadData()
        if let parent = self.parentController as? SplitMainViewController {
            parent.tabBar.collectionView.reloadData()
            parent.doToolbarOffset()
        }
    }
    
    public func didClear() -> Bool {
        return false
    }
}

// MARK: - Wrapping Flow Layout Delegate
extension SingleSubredditViewController: WrappingFlowLayoutDelegate {
    func headerOffset() -> Int {
        return hasHeader ? 1 : 0
    }
    
    func headerHeight(_ estimate: Bool = true) -> CGFloat {
        if !estimate && SettingValues.alwaysShowHeader {
            return CGFloat(0)
        }
        return CGFloat(hasHeader ? (headerImage != nil ? 180 : 38) : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, width: CGFloat, indexPath: IndexPath) -> CGSize {
        var row = indexPath.row
        if row == 0 && hasHeader {
            return CGSize(width: width, height: headerHeight())
        }
        if hasHeader {
            row -= 1
        }
        if row < dataSource.content.count {
            let submission = dataSource.content[row]
            if submission.author == "PAGE_SEPARATOR" {
                return CGSize(width: width, height: 80)
            }
            return SingleSubredditViewController.sizeWith(submission, width, Subscriptions.isCollection(sub), isGallery)
        }
        return CGSize(width: width, height: 80)
    }
}

// MARK: - Submission More Delegate
extension SingleSubredditViewController: SubmissionMoreDelegate {
    func hide(index: Int) {
        dataSource.content.remove(at: index)
        self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: isGallery)
        tableView.reloadData()
    }

    func subscribe(link: SubmissionObject) {
        let sub = link.subreddit
        let alrController = UIAlertController.init(title: "Follow r/\(sub)", message: nil, preferredStyle: .alert)
        if AccountController.isLoggedIn {
            let somethingAction = UIAlertAction(title: "Subscribe", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) in
                Subscriptions.subscribe(sub, true, session: self.session!)
                self.subChanged = true
                BannerUtil.makeBanner(text: "Subscribed to r/\(sub)", color: ColorUtil.accentColorForSub(sub: sub), seconds: 3, context: self, top: true)
            })
            alrController.addAction(somethingAction)
        }
        
        let somethingAction = UIAlertAction(title: "Casually subscribe", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) in
            Subscriptions.subscribe(sub, false, session: self.session!)
            self.subChanged = true
            BannerUtil.makeBanner(text: "r/\(sub) added to your subreddit list", color: ColorUtil.accentColorForSub(sub: sub), seconds: 3, context: self, top: true)
        })
        alrController.addAction(somethingAction)
        
        alrController.addCancelButton()
        
        alrController.modalPresentationStyle = .fullScreen
        self.present(alrController, animated: true, completion: {})
    }

    func reply(_ cell: LinkCellView) {

    }

    func save(_ cell: LinkCellView) {
        do {
            try session?.setSave(!ActionStates.isSaved(s: cell.link!), name: (cell.link?.id)!, completion: { (_) in

            })
            ActionStates.setSaved(s: cell.link!, saved: !ActionStates.isSaved(s: cell.link!))
            cell.refresh()
        } catch {

        }
    }

    func upvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.id)!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!)
            cell.refresh()
            cell.refreshTitle(force: true)
        } catch {
            
        }
    }

    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.id)!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!)
            cell.refresh()
            cell.refreshTitle(force: true)
        } catch {

        }
    }

    func hide(_ cell: LinkCellView) {
        do {
            try session?.setHide(true, name: cell.link!.id, completion: { (_) in })
            let id = cell.link!.id
            var location = 0
            var item = dataSource.content[0]
            for submission in dataSource.content {
                if submission.id == id {
                    item = dataSource.content[location]
                    dataSource.content.remove(at: location)
                    break
                }
                location += 1
            }

            self.tableView.isUserInteractionEnabled = false

            if !dataSource.loading {
                tableView.performBatchUpdates({
                    self.tableView.deleteItems(at: [IndexPath.init(item: location, section: 0)])
                }, completion: { (_) in
                    self.tableView.isUserInteractionEnabled = true
                    self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: self.isGallery)
                    self.tableView.reloadData()
                })
            } else {
                self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: isGallery)
                tableView.reloadData()
            }
            BannerUtil.makeBanner(text: "Hidden forever!\nTap to undo", color: GMColor.red500Color(), seconds: 4, context: self, top: false, callback: {
                self.dataSource.content.insert(item, at: location)
                self.tableView.insertItems(at: [IndexPath.init(item: location + self.headerOffset(), section: 0)])
                self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: self.isGallery)
                self.tableView.reloadData()
                do {
                    try self.session?.setHide(false, name: cell.link!.id, completion: { (_) in })
                } catch {
                }
            })
        } catch {

        }
    }

    func more(_ cell: LinkCellView) {
        if let nav = self.navigationController {
            PostActions.showMoreMenu(cell: cell, parent: self, nav: nav, mutableList: true, delegate: self, index: tableView.indexPath(for: cell)?.row ?? 0)
        }
    }

    @available(iOS 13, *)
    func getMoreMenu(_ cell: LinkCellView) -> UIMenu? {
        if let nav = self.navigationController {
            return PostActions.getMoreContextMenu(cell: cell, parent: self, nav: nav, mutableList: true, delegate: self, index: tableView.indexPath(for: cell)?.row ?? 0)
        }
        return nil
    }

    func readLater(_ cell: LinkCellView) {
        guard let link = cell.link else {
            return
        }

        ReadLater.toggleReadLater(link: link)
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionComplete()
        }
        cell.refresh()
    }

    func mod(_ cell: LinkCellView) {
        PostActions.showModMenu(cell, parent: self)
    }
    
    func applyFilters() {
        self.dataSource.content = PostFilter.filter(self.dataSource.content, previous: nil, baseSubreddit: self.sub).map { $0 as! SubmissionObject }
        self.reloadDataReset()
    }

    func showFilterMenu(_ cell: LinkCellView) {
        let link = cell.link!
        let actionSheetController: UIAlertController = UIAlertController(title: "What would you like to filter?", message: "", preferredStyle: .alert)

        actionSheetController.addCancelButton()
        
        var cancelActionButton = UIAlertAction()
        cancelActionButton = UIAlertAction(title: "Posts by u/\(link.author)", style: .default) { _ -> Void in
            PostFilter.profiles.append(link.author as NSString)
            PostFilter.saveAndUpdate()
            self.dataSource.content = PostFilter.filter(self.dataSource.content, previous: nil, baseSubreddit: self.sub).map { $0 as! SubmissionObject }
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Posts from r/\(link.subreddit)", style: .default) { _ -> Void in
            PostFilter.subreddits.append(link.subreddit as NSString)
            PostFilter.saveAndUpdate()
            self.dataSource.content = PostFilter.filter(self.dataSource.content, previous: nil, baseSubreddit: self.sub).map { $0 as! SubmissionObject }
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Posts linking to \(link.domain)", style: .default) { _ -> Void in
            PostFilter.domains.append(link.domain as NSString)
            PostFilter.saveAndUpdate()
            self.dataSource.content = PostFilter.filter(self.dataSource.content, previous: nil, baseSubreddit: self.sub).map { $0 as! SubmissionObject }
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)

       // TODO: - make this work on ipad
        self.present(actionSheetController, animated: true, completion: nil)
    }
}

extension SingleSubredditViewController: UIGestureRecognizerDelegate {

    func setupGestures() {
        if cellGestureRecognizer != nil {
            return
        }
        cellGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panCell(_:)))
        cellGestureRecognizer.delegate = self
        cellGestureRecognizer.maximumNumberOfTouches = 1
        tableView.addGestureRecognizer(cellGestureRecognizer)

        if let parent = parent as? ColorMuxPagingViewController, SettingValues.subredditBar {
            parent.requireFailureOf(cellGestureRecognizer)
        }
        if let nav = self.navigationController as? SwipeForwardNavigationController {
            nav.fullWidthBackGestureRecognizer.require(toFail: cellGestureRecognizer)
            if let interactivePop = nav.interactivePopGestureRecognizer {
                cellGestureRecognizer.require(toFail: interactivePop)
            }
        } else if let nav = self.parent?.navigationController as? SwipeForwardNavigationController {
            nav.fullWidthBackGestureRecognizer.require(toFail: cellGestureRecognizer)
            nav.interactivePushGestureRecognizer?.require(toFail: cellGestureRecognizer)
            if let interactivePop = nav.interactivePopGestureRecognizer {
                cellGestureRecognizer.require(toFail: interactivePop)
            }
        }
        if let swipe = fullWidthBackGestureRecognizer {
            swipe.require(toFail: cellGestureRecognizer)
        }
        
        if #available(iOS 13.4, *) {
            cellGestureRecognizer.allowedScrollTypesMask = .continuous
        }
    }
        
    func setupSwipeGesture() {
        if SettingValues.submissionGestureMode == .FULL || swipeBackAdded {
            return
        }
        
        if let full = fullWidthBackGestureRecognizer {
            full.view?.removeGestureRecognizer(full)
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            fullWidthBackGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(showParentMenu(_:)))
            guard let swipe = fullWidthBackGestureRecognizer as? UISwipeGestureRecognizer else { return }
            swipe.direction = .right
            swipe.delegate = self
            tableView.addGestureRecognizer(swipe)
            return
        }
        fullWidthBackGestureRecognizer = UIPanGestureRecognizer()
        if let interactivePopGestureRecognizer = parent?.navigationController?.interactivePopGestureRecognizer, let targets = interactivePopGestureRecognizer.value(forKey: "targets"), parent is ColorMuxPagingViewController {
            setupSwipeWithTarget(fullWidthBackGestureRecognizer as! UIPanGestureRecognizer, targets: targets)
        } else if !(parent is ColorMuxPagingViewController) {
            if let interactivePopGestureRecognizer = self.navigationController?.interactivePopGestureRecognizer, let targets = interactivePopGestureRecognizer.value(forKey: "targets") {
                setupSwipeWithTarget(fullWidthBackGestureRecognizer as! UIPanGestureRecognizer, targets: targets)
            }
        }
        if let nav = navigationController as? SwipeForwardNavigationController {
            let gesture = nav.fullWidthBackGestureRecognizer
            nav.interactivePushGestureRecognizer?.require(toFail: fullWidthBackGestureRecognizer)
            gesture.require(toFail: fullWidthBackGestureRecognizer)
        }
    }
    
    func setupSwipeWithTarget(_ fullWidthBackGestureRecognizer: UIPanGestureRecognizer, targets: Any?) {
        fullWidthBackGestureRecognizer.setValue(targets, forKey: "targets")
        fullWidthBackGestureRecognizer.require(toFail: tableView.panGestureRecognizer)
        if let navGesture = self.navigationController?.interactivePopGestureRecognizer {
            fullWidthBackGestureRecognizer.require(toFail: navGesture)
        }
        if let navGesture = (self.navigationController as? SwipeForwardNavigationController)?.fullWidthBackGestureRecognizer {
            navGesture.require(toFail: fullWidthBackGestureRecognizer)
        }
        swipeBackAdded = true
        fullWidthBackGestureRecognizer.delegate = self
        //parent.requireFailureOf(fullWidthBackGestureRecognizer)
        tableView.addGestureRecognizer(fullWidthBackGestureRecognizer)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return !(otherGestureRecognizer == cellGestureRecognizer && otherGestureRecognizer.state != .ended)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: tableView)
            if panGestureRecognizer == cellGestureRecognizer {
                if abs(translation.y) >= abs(translation.x) {
                    return false
                }
                if translation.x < 0 {
                    if gestureRecognizer.location(in: tableView).x > tableView.frame.width * 0.5 || !SettingValues.submissionGestureMode.shouldPage() || (SettingValues.appMode == .MULTI_COLUMN && UIDevice.current.userInterfaceIdiom == .pad) {
                        return true
                    }
                } else if !SettingValues.submissionGestureMode.shouldPage() && abs(translation.x) > abs(translation.y) {
                    return gestureRecognizer.location(in: tableView).x > tableView.frame.width * 0.1
                }
                return false
            }
            if panGestureRecognizer == fullWidthBackGestureRecognizer && translation.x >= 0 {
                return true
            }
            return false
        }
        
        if gestureRecognizer is UISwipeGestureRecognizer {
            return true
        }

        return false
    }
        
    @objc func showParentMenu(_ recognizer: UISwipeGestureRecognizer) {
        if let parent = self.parentController as? SplitMainViewController {
            parent.openDrawer(recognizer)
        }
    }
    
    @objc func panCell(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.view != nil && recognizer.state == .began {
            let velocity = recognizer.velocity(in: self.tableView).x
            if (velocity > 0 && (SettingValues.submissionActionRight == .NONE || SettingValues.submissionGestureMode == .HALF || SettingValues.submissionGestureMode == .HALF_FULL)) || (velocity < 0 && SettingValues.submissionActionLeft == .NONE) {
                recognizer.cancel()
                return
            }
        }
        if recognizer.state == .began || translatingCell == nil {
            let point = recognizer.location(in: self.tableView)
            let indexpath = self.tableView.indexPathForItem(at: point)
            if indexpath == nil {
                recognizer.cancel()
                return
            }
            
            guard let cell = self.tableView.cellForItem(at: indexpath!) as? LinkCellView else {
                recognizer.cancel()
                return
            }
            
            if recognizer.location(in: cell).x < cell.contentView.bounds.width / 2 && SettingValues.submissionGestureMode.shouldPage() {
                recognizer.cancel()
                return
            }
            tableView.panGestureRecognizer.cancel()
            disableDismissalRecognizers()
            translatingCell = cell
        }
        translatingCell?.handlePan(recognizer)
        if recognizer.state == .ended || recognizer.state == .cancelled {
            translatingCell = nil
            enableDismissalRecognizers()
        }
    }
}

public class LoadingCell: UICollectionViewCell {
    var loader = UIActivityIndicatorView()
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        loader.startAnimating()
        
        self.contentView.addSubview(loader)

        loader.topAnchor /==/ self.contentView.topAnchor + 10
        loader.bottomAnchor /==/ self.contentView.bottomAnchor - 10
        loader.centerXAnchor /==/ self.contentView.centerXAnchor
    }
}

public class NothingHereCell: UICollectionViewCell {
    var text = UILabel()
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        self.contentView.addSubview(text)

        let title = NSMutableAttributedString(string: "You've reached the end!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
        
        text.attributedText = title
        text.topAnchor /==/ self.contentView.topAnchor + 10
        text.bottomAnchor /==/ self.contentView.bottomAnchor - 10
        text.centerXAnchor /==/ self.contentView.centerXAnchor
    }
}

public class ReadLaterCell: UICollectionViewCell {
    let title = UILabel()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setArticles(articles: Int) {
        let text = "Read Later "
        let numberText = "(\(articles))"
        let number = NSMutableAttributedString.init(string: numberText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)])
        let readLater = NSMutableAttributedString.init(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])
        let finalText = readLater
        finalText.append(number)

        title.attributedText = finalText
    }
    
    func setupView() {
        title.backgroundColor = UIColor.foregroundColor
        title.textAlignment = .center
        
        title.numberOfLines = 0
        
        let titleView: UIView
        if SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER {
            if !SettingValues.flatMode {
                title.layer.cornerRadius = 15
            }
            titleView = title.withPadding(padding: UIEdgeInsets(top: 8, left: 5, bottom: 0, right: 5))
        } else {
            titleView = title.withPadding(padding: UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0))
        }
        title.clipsToBounds = true
        self.contentView.addSubview(titleView)
        
        titleView.heightAnchor /==/ 60
        titleView.horizontalAnchors /==/ self.contentView.horizontalAnchors
        titleView.topAnchor /==/ self.contentView.topAnchor
    }
}

public class PageCell: UICollectionViewCell {
    var title = UILabel()
    var time = UILabel()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        self.contentView.addSubviews(title, time)
        
        title.heightAnchor /==/ 60
        title.horizontalAnchors /==/ self.contentView.horizontalAnchors
        title.topAnchor /==/ self.contentView.topAnchor + 10
        title.bottomAnchor /==/ self.contentView.bottomAnchor - 10
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        title.textAlignment = .center
        title.textColor = UIColor.fontColor
        
        time.heightAnchor /==/ 60
        time.leftAnchor /==/ self.contentView.leftAnchor
        time.topAnchor /==/ self.contentView.topAnchor + 10
        time.bottomAnchor /==/ self.contentView.bottomAnchor - 10
        time.numberOfLines = 0
        time.widthAnchor /==/ 70
        time.lineBreakMode = .byWordWrapping
        time.textAlignment = .center
    }
}

public class LinksHeaderCellView: UICollectionViewCell {
    var scroll: TouchUIScrollView!
    var links = [SubLinkItem]()
    var sub = ""
    var header = UIView()
    var sort = UIView()
    var sortImage = UIImageView()
    var sortTitle = UILabel()
    var hasHeaderImage = false
    weak var del: SingleSubredditViewController?
    
    func setLinks(links: [SubLinkItem], sub: String, delegate: SingleSubredditViewController) {
        self.links = links
        self.sub = sub
        self.del = delegate
        self.hasHeaderImage = delegate.headerImage != nil
        setupViews()
        switch del?.dataSource.sorting ?? LinkSortType.top {
        case .best:
            sortImage.image = UIImage(sfString: SFSymbol.handThumbsupFill, overrideString: "ic_sort_white")?.getCopy(withSize: CGSize(width: 25, height: 25), withColor: ColorUtil.getNavColorForSub(sub: sub) ?? UIColor.navIconColor)
        case .hot:
            sortImage.image = UIImage(sfString: SFSymbol.flameFill, overrideString: "ic_sort_white")?.getCopy(withSize: CGSize(width: 25, height: 25), withColor: ColorUtil.getNavColorForSub(sub: sub) ?? UIColor.navIconColor)
        case .controversial:
            sortImage.image = UIImage(sfString: SFSymbol.boltFill, overrideString: "ic_sort_white")?.getCopy(withSize: CGSize(width: 25, height: 25), withColor: ColorUtil.getNavColorForSub(sub: sub) ?? UIColor.navIconColor)
        case .new:
            sortImage.image = UIImage(sfString: SFSymbol.sparkles, overrideString: "ic_sort_white")?.getCopy(withSize: CGSize(width: 25, height: 25), withColor: ColorUtil.getNavColorForSub(sub: sub) ?? UIColor.navIconColor)
        case .rising:
            sortImage.image = UIImage(sfString: SFSymbol.arrowUturnUp, overrideString: "ic_sort_white")?.getCopy(withSize: CGSize(width: 25, height: 25), withColor: ColorUtil.getNavColorForSub(sub: sub) ?? UIColor.navIconColor)
        case .top:
            if #available(iOS 14, *) {
                sortImage.image = UIImage(sfString: SFSymbol.crownFill, overrideString: "ic_sort_white")?.getCopy(withSize: CGSize(width: 25, height: 25), withColor: ColorUtil.getNavColorForSub(sub: sub) ?? UIColor.navIconColor)
            } else {
                sortImage.image = UIImage(sfString: SFSymbol.arrowUp, overrideString: "ic_sort_white")?.getCopy(withSize: CGSize(width: 25, height: 25), withColor: ColorUtil.getNavColorForSub(sub: sub) ?? UIColor.navIconColor)
            }
        }
        sortTitle.font = UIFont.boldSystemFont(ofSize: 14)
        sortTitle.textColor = UIColor.fontColor
        sortTitle.text = (del?.dataSource.sorting ?? LinkSortType.top).description.uppercased()
    }
    
    func addSubscribe(_ stack: UIStackView, _ scroll: UIScrollView) -> CGFloat {
        let view = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 45)).then {
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 15
            $0.setImage(UIImage(sfString: SFSymbol.plusCircleFill, overrideString: "add")?.menuIcon().getCopy(withColor: .white), for: .normal)
            $0.backgroundColor = ColorUtil.getNavColorForSub(sub: sub) ?? ColorUtil.accentColorForSub(sub: sub)
            $0.imageView?.contentMode = .center
        }
        
        view.addTapGestureRecognizer { (_) in
            self.del?.subscribeSingle(view)
            stack.removeArrangedSubview(view)
            var oldSize = scroll.contentSize
            oldSize.width -= 38
            stack.widthAnchor /==/ oldSize.width
            scroll.contentSize = oldSize
            view.removeFromSuperview()
        }

        let widthS = CGFloat(30)

        view.heightAnchor /==/ CGFloat(30)
        view.widthAnchor /==/ widthS
        
        stack.addArrangedSubview(view)
        return 30
    }
    func addSubmit(_ stack: UIStackView) -> CGFloat {
        let view = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 45)).then {
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 15
            $0.setImage(UIImage(sfString: SFSymbol.pencil, overrideString: "edit")?.menuIcon().getCopy(withColor: .white), for: .normal)
            $0.backgroundColor = ColorUtil.getNavColorForSub(sub: sub) ?? ColorUtil.accentColorForSub(sub: sub)
            $0.imageView?.contentMode = .center
            $0.addTapGestureRecognizer { (_) in
                PostActions.showPostMenu(self.del!, sub: self.sub)
            }
        }
        
        let widthS = CGFloat(30)
        
        view.heightAnchor /==/ CGFloat(30)
        view.widthAnchor /==/ widthS
        
        stack.addArrangedSubview(view)
        return 30
    }
    func addSidebar(_ stack: UIStackView) -> CGFloat {
        let view = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 45)).then {
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 15
            $0.setImage(UIImage(sfString: SFSymbol.infoCircle, overrideString: "info")?.menuIcon().getCopy(withColor: .white), for: .normal)
            $0.backgroundColor = ColorUtil.getNavColorForSub(sub: sub) ?? ColorUtil.accentColorForSub(sub: sub)
            $0.imageView?.contentMode = .center
            $0.addTapGestureRecognizer { (_) in
                self.del?.doDisplaySidebar()
            }
        }
        
        let widthS = CGFloat(30)

        view.heightAnchor /==/ CGFloat(30)
        view.widthAnchor /==/ widthS
        
        stack.addArrangedSubview(view)
        return 30
    }

    func setupViews() {
        if scroll == nil {
            scroll = TouchUIScrollView()
            
            let buttonBase = UIStackView().then {
                $0.accessibilityIdentifier = "Subreddit links"
                $0.axis = .horizontal
                $0.spacing = 8
            }
            
            var finalWidth = CGFloat(8)
            
            var spacerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
            buttonBase.addArrangedSubview(spacerView)

            /*sort.heightAnchor /==/ 30
            sort.addSubviews(sortImage, sortTitle)
            sortImage.sizeAnchors /==/ CGSize.square(size: 25)
            sortImage.centerYAnchor /==/ sort.centerYAnchor
            sortImage.leftAnchor /==/ sort.leftAnchor + 8
            sortTitle.leftAnchor /==/ sortImage.rightAnchor + 8
            sortTitle.centerYAnchor /==/ sortImage.centerYAnchor
            sortTitle.rightAnchor /==/ sort.rightAnchor
            sort.addTapGestureRecognizer { (_) in
                self.del?.showSortMenu(self)
            }
            sortTitle.text = (del?.sort ?? LinkSortType.top).description.uppercased()

            var sortWidth = 25 + 8 + 8 + (sortTitle.text ?? "").size(with: sortTitle.font).width
            sort.widthAnchor /==/ sortWidth

            buttonBase.addArrangedSubview(sort)
            finalWidth += sortWidth + 8*/
            if Subscriptions.subreddits.contains(sub) {
                finalWidth += self.addSubmit(buttonBase) + 8
            } else {
                finalWidth += self.addSubscribe(buttonBase, scroll) + 8
            }
            
            finalWidth += self.addSidebar(buttonBase) + 8

            for link in self.links {
                let view = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 45)).then {
                    $0.layer.cornerRadius = 15
                    $0.clipsToBounds = true
                    $0.setTitle(link.title, for: .normal)
                    $0.setTitleColor(UIColor.white, for: .normal)
                    $0.setTitleColor(.white, for: .selected)
                    $0.titleLabel?.textAlignment = .center
                    $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                    $0.backgroundColor = ColorUtil.getNavColorForSub(sub: sub) ?? UIColor.navIconColor
                    $0.addTapGestureRecognizer { (_) in
                        self.del?.doShow(url: link.link!, heroView: nil, finalSize: nil, heroVC: nil, link: SubmissionObject())
                    }
                }
                
                let widthS = view.currentTitle!.size(with: view.titleLabel!.font).width + CGFloat(45)
                
                view.heightAnchor /==/ CGFloat(30)
                view.widthAnchor /==/ widthS
                
                finalWidth += widthS
                finalWidth += 8
                
                buttonBase.addArrangedSubview(view)
            }
            
            spacerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
            buttonBase.addArrangedSubview(spacerView)
            
            self.contentView.addSubviews(scroll)
            self.scroll.isUserInteractionEnabled = true
            self.contentView.isUserInteractionEnabled = true
            buttonBase.isUserInteractionEnabled = true
            
            scroll.heightAnchor /==/ CGFloat(30)
            scroll.horizontalAnchors /==/ self.contentView.horizontalAnchors

            scroll.addSubview(buttonBase)
            buttonBase.heightAnchor /==/ CGFloat(30)
            buttonBase.edgeAnchors /==/ scroll.edgeAnchors
            buttonBase.centerYAnchor /==/ scroll.centerYAnchor
            buttonBase.widthAnchor /==/ finalWidth
            scroll.alwaysBounceHorizontal = true
            scroll.showsHorizontalScrollIndicator = false

            if hasHeaderImage && del != nil {
                self.contentView.addSubview(header)

                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                header.addSubview(imageView)
                imageView.clipsToBounds = true
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    imageView.verticalAnchors /==/ header.verticalAnchors
                    imageView.horizontalAnchors /==/ header.horizontalAnchors + 4
                    imageView.layer.cornerRadius = 15
                } else {
                    imageView.edgeAnchors /==/ header.edgeAnchors
                }
                
                header.heightAnchor /==/ 180
                header.horizontalAnchors /==/ self.contentView.horizontalAnchors
                header.topAnchor /==/ self.contentView.topAnchor + 4
                scroll.topAnchor /==/ self.header.bottomAnchor + 4
                if let headerImage = del?.headerImage {
                    imageView.sd_setImage(with: headerImage, placeholderImage: UIImage(), options: [.decodeFirstFrameOnly, .allowInvalidSSLCertificates, .scaleDownLargeImages], context: [:], progress: nil)
                }

                header.heightAnchor /==/ 140
                
            } else {
                scroll.topAnchor /==/ self.contentView.topAnchor + 4
            }

            scroll.contentSize = CGSize.init(width: finalWidth + 30, height: CGFloat(30))
        }
    }
}

public class SubLinkItem {
    var title = ""
    var link: URL?
    
    init(_ title: String?, link: URL?) {
        self.title = title ?? "LINK"
        self.link = link
    }
}

extension SingleSubredditViewController: TapBehindModalViewControllerDelegate {
    func shouldDismiss() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}

extension SingleSubredditViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Fixes bug with corrupt nav stack
        // https://stackoverflow.com/a/39457751/7138792
        navigationController.interactivePopGestureRecognizer?.isEnabled = navigationController.viewControllers.count > 1
        if navigationController.viewControllers.count == 1 || isModal {
            self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}
