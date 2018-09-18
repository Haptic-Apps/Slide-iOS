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
import RealmSwift
import reddift
import RLBAlertsPickers
import SDWebImage
import SideMenu
import SloppySwiper
import TTTAttributedLabel
import UIKit
import XLActionController

// MARK: - Base
class SingleSubredditViewController: MediaViewController {

    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spacePressed))]
    }
    
    static var nextSingle = false
    
    var navbarEnabled: Bool {
        return single || !SettingValues.viewType
    }

    var toolbarEnabled: Bool {
        return !SettingValues.bottomBarHidden || SettingValues.viewType
    }

    let maxHeaderHeight: CGFloat = 120
    let minHeaderHeight: CGFloat = 56
    public var inHeadView = UIView()

    let margin: CGFloat = 10
    let cellsPerRow = 3
    
    var panGesture: UIPanGestureRecognizer!
    var translatingCell: LinkCellView?

    var times = 0
    var startTime = Date()

    var parentController: MainViewController?
    var accentChosen: UIColor?
    
    var isModal = false

    var isAccent = false

    var isCollapsed = false
    var isHiding = false
    var isToolbarHidden = false

    var oldY = CGFloat(0)

    var links: [RSubmission] = []
    var paginator = Paginator()
    var sub: String
    var session: Session?
    var tableView: UICollectionView!
    var single: Bool = false

    var loaded = false
    var sideView: UIView = UIView()
    var subb: UIButton = UIButton()

    var subInfo: Subreddit?
    var flowLayout: WrappingFlowLayout = WrappingFlowLayout.init()

    static var firstPresented = true
    static var cellVersion = 0
    var swiper: SloppySwiper?

    var headerView = UIView()
    var more = UIButton()

    var lastY: CGFloat = CGFloat(0)
    var lastYUsed = CGFloat(0)

    var listingId: String = "" //a random id for use in Realm

    var fab: UIButton?

    var first = true
    var indicator: MDCActivityIndicator?

    var searchText: String?

    var loading = false
    var nomore = false

    var showing = false

    var sort = SettingValues.defaultSorting
    var time = SettingValues.defaultTimePeriod

    var refreshControl: UIRefreshControl!

    var savedIndex: IndexPath?
    var realmListing: RListing?

    var oldsize = CGFloat(0)

    init(subName: String, parent: MainViewController) {
        sub = subName
        self.parentController = parent

        super.init(nibName: nil, bundle: nil)
        self.sort = SettingValues.getLinkSorting(forSubreddit: self.sub)
        self.time = SettingValues.getTimePeriod(forSubreddit: self.sub)
    }

    init(subName: String, single: Bool) {
        sub = subName
        self.single = true
        SingleSubredditViewController.nextSingle = true
        super.init(nibName: nil, bundle: nil)
        self.sort = SettingValues.getLinkSorting(forSubreddit: self.sub)
        self.time = SettingValues.getTimePeriod(forSubreddit: self.sub)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        flowLayout.delegate = self
        self.tableView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        self.view = UIView.init(frame: CGRect.zero)
        self.view.addSubview(tableView)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panCell))
        panGesture.direction = .horizontal
        panGesture.delegate = self
        self.tableView.addGestureRecognizer(panGesture)
        if single && navigationController != nil {
            panGesture.require(toFail: navigationController!.interactivePopGestureRecognizer!)
        }
    
        self.tableView.delegate = self
        self.tableView.dataSource = self
        refreshControl = UIRefreshControl()

        reloadNeedingColor()
        
//        if false && single && !isModal { //todo reimplement soon?
//            swiper = SloppySwiper.init(navigationController: self.navigationController!)
//            self.navigationController!.delegate = swiper!
//            for view in view.subviews {
//                if view is UIScrollView {
//                    let scrollView = view as! UIScrollView
//                    scrollView.panGestureRecognizer.require(toFail: swiper!.panRecognizer)
//                    break
//                }
//            }
//        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        server?.stop()
        loop?.stop()

        if SubredditReorderViewController.changed {
            self.reloadNeedingColor()
            flowLayout.reset()
            CachedTitle.titles.removeAll()
            self.tableView.reloadData()
        }

        doHeadView()

        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "", true)
        navigationController?.navigationBar.tintColor = SettingValues.reduceColor ? ColorUtil.fontColor : UIColor.white

        self.navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = false

        showUI()

        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: sub, true)

        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true

        first = false
        tableView.delegate = self

        if savedIndex != nil {
            tableView.reloadItems(at: [savedIndex!])
        } else {
            tableView.reloadData()
        }

        if single {
            setupBaseBarColors()
        }
        self.view.backgroundColor = ColorUtil.backgroundColor
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if toolbarEnabled {
            if single {
                navigationController?.setToolbarHidden(false, animated: false)
            } else {
                parentController?.menuNav?.view.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - (parentController?.menuNav?.bottomOffset ?? 64), width: parentController?.menuNav?.view.frame.width ?? 0, height: parentController?.menuNav?.view.frame.height ?? 0)
            }
            self.isToolbarHidden = false
            if fab == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.setupFab(UIScreen.main.bounds.size)
                }
            } else {
                show(true)
            }
        } else {
            if single {
                navigationController?.setToolbarHidden(true, animated: false)
            }
        }
        SingleSubredditViewController.nextSingle = self.single
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        tableView.frame = self.view.bounds

        if self.view.bounds.width != oldsize {
            oldsize = self.view.bounds.width
            flowLayout.reset()
            tableView.reloadData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIApplication.shared.statusBarStyle = .lightContent

        if single {
            UIApplication.shared.statusBarView?.backgroundColor = .clear
        }
        if fab != nil {
                UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                    self.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
                }, completion: { _ in
                    self.fab?.removeFromSuperview()
                })
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.fab?.removeFromSuperview()
        self.fab = nil
        
        self.setupFab(size)

        if self.viewIfLoaded?.window != nil {
            tableView.reloadData()
        }
    }
    
    static func getHeightFromAspectRatio(imageHeight: CGFloat, imageWidth: CGFloat, viewWidth: CGFloat) -> CGFloat {
        let ratio = imageHeight / imageWidth
        return viewWidth * ratio
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentY = scrollView.contentOffset.y
        
        if !SettingValues.pinToolbar {
            if currentY > lastYUsed && currentY > 60 {
                if navigationController != nil && !isHiding && !isToolbarHidden && !(scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
                    hideUI(inHeader: true)
                }
            } else if (currentY < lastYUsed - 15 || currentY < 100) && !isHiding && navigationController != nil && (isToolbarHidden) {
                showUI()
            }
        }
        lastYUsed = currentY
        lastY = currentY
    }
    
    func hideUI(inHeader: Bool) {
        isHiding = true
        if navbarEnabled {
            (navigationController)?.setNavigationBarHidden(true, animated: true)
        }
        
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                self.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
            }, completion: { _ in
                self.fab?.isHidden = true
                self.isHiding = false
            })
        
        if !SettingValues.bottomBarHidden || SettingValues.viewType {
            if single {
                navigationController?.setToolbarHidden(true, animated: true)
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.parentController?.menuNav?.view.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - ((self.parentController?.menuNav?.bottomOffset ?? 1) / 2), width: self.parentController?.menuNav?.view.frame.width ?? 0, height: self.parentController?.menuNav?.view.frame.height ?? 0)
                }
            }
//            if !single && parentController != nil {
//                parentController!.drawerButton.isHidden = false
//            }
        }
        self.isToolbarHidden = true

        if !single {
            if AutoCache.progressView != nil {
                oldY = AutoCache.progressView!.frame.origin.y
                UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                    AutoCache.progressView!.frame.origin.y = self.view.frame.size.height - 56
                }, completion: nil)
            }
        }
    }

    func showUI() {
        if navbarEnabled {
            (navigationController)?.setNavigationBarHidden(false, animated: true)
        }

        if !single && AutoCache.progressView != nil {
                UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                    AutoCache.progressView!.frame.origin.y = self.oldY
                }, completion: { _ in
                    self.fab?.isHidden = false
                    self.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)

                    UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                        self.fab?.transform = CGAffineTransform.identity
                    }, completion: { _ in
                    })

                    if !SettingValues.bottomBarHidden || SettingValues.viewType {
                        if self.single {
                            self.navigationController?.setToolbarHidden(false, animated: true)
                        } else {
                            UIView.animate(withDuration: 0.25) {
                                self.parentController?.menuNav?.view.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - (self.parentController?.menuNav?.bottomOffset ?? 0), width: self.parentController?.menuNav?.view.frame.width ?? 0, height: self.parentController?.menuNav?.view.frame.height ?? 0)
                            }
                        }
                    }
                    self.isToolbarHidden = false
                })
        } else {
            
            if self.fab?.superview != nil {
                self.fab?.isHidden = false
                self.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
                
                UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                    self.fab?.transform = CGAffineTransform.identity
                }, completion: { _ in
                    
                })
            }

            if !SettingValues.bottomBarHidden || SettingValues.viewType {
                if single {
                    navigationController?.setToolbarHidden(false, animated: true)
                } else {
                    UIView.animate(withDuration: 0.25) {
                        self.parentController?.menuNav?.view.frame = CGRect(x: 0, y: (UIScreen.main.bounds.height - (self.parentController?.menuNav?.bottomOffset ?? 0)), width: self.parentController?.menuNav?.view.frame.width ?? 0, height: self.parentController?.menuNav?.view.frame.height ?? 0)
                    }
                }
//                if !single && parentController != nil {
//                    self.parentController!.drawerButton.isHidden = true
//                }
            }
            self.isToolbarHidden = false
        }
    }

    func show(_ animated: Bool = true) {
        if fab != nil && (fab!.isHidden || fab!.superview == nil) {
            if animated {
                if fab!.superview == nil {
                    if single {
                        self.navigationController?.toolbar.addSubview(fab!)
                    } else {
                        parentController?.toolbar?.addSubview(fab!)
                    }
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
                }, completion: { _ in
                    self.fab!.isHidden = true
                })
            } else {
                self.fab!.isHidden = true
            }
        }
    }

    func setupFab(_ size: CGSize) {
        if !SettingValues.bottomBarHidden || SettingValues.viewType {
            addNewFab(size)
        }
    }
    
    func addNewFab(_ size: CGSize) {
        if self.fab != nil {
            self.fab!.removeFromSuperview()
            self.fab = nil
        }
        if !MainViewController.isOffline && !SettingValues.hiddenFAB {
            self.fab = UIButton(frame: CGRect.init(x: (size.width / 2) - 70, y: -20, width: 140, height: 45))
            self.fab!.backgroundColor = ColorUtil.accentColorForSub(sub: sub)
            self.fab!.accessibilityHint = sub
            self.fab!.layer.cornerRadius = 22.5
            self.fab!.clipsToBounds = true
            let title = "  " + SettingValues.fabType.getTitle()
            self.fab!.setTitle(title, for: .normal)
            self.fab!.leftImage(image: (UIImage.init(named: SettingValues.fabType.getPhoto())?.navIcon(true))!, renderMode: UIImageRenderingMode.alwaysOriginal)
            self.fab!.elevate(elevation: 2)
            self.fab!.titleLabel?.textAlignment = .center
            self.fab!.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            
            let width = title.size(with: self.fab!.titleLabel!.font).width + CGFloat(65)
            self.fab!.frame = CGRect.init(x: (size.width / 2) - (width / 2), y: -20, width: width, height: CGFloat(45))
            
            self.fab!.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
            if single {
                self.navigationController?.toolbar.addSubview(self.fab!)
            } else {
                self.parentController?.toolbar?.addSubview(self.fab!)
                self.parentController?.menuNav?.callbacks.didBeginPanning = {
                    if !(self.fab?.isHidden ?? true) && !self.isHiding {
                        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                            self.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
                        }, completion: { _ in
                            self.fab?.isHidden = true
                            self.isHiding = false
                        })
                    }
                }
                self.parentController?.menuNav?.callbacks.didCollapse = {
                    self.fab?.isHidden = false
                    self.fab?.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
                    
                    UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                        self.fab?.transform = CGAffineTransform.identity
                    }, completion: { _ in
                    })
                }
            }

            self.fab!.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                self.fab!.transform = CGAffineTransform.identity
            }, completion: { (_)  in
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.doFabActions))
                self.fab!.addGestureRecognizer(tap)
                
                self.fab!.addLongTapGestureRecognizer {
                    self.changeFab()
                }
            })
        }
    }

    func doFabActions() {
        if UserDefaults.standard.bool(forKey: "FAB_SHOWN") == false {
            let a = UIAlertController(title: "Subreddit Action Button", message: "This is the subreddit action button!\n\nThis button's actions can be customized by long pressing on it at any time, and this button can be removed completely in Settings > General.", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "Change action", style: .default, handler: { (_) in
                UserDefaults.standard.set(true, forKey: "FAB_SHOWN")
                UserDefaults.standard.synchronize()
                self.changeFab()
            }))
            a.addAction(UIAlertAction(title: "Hide button", style: .default, handler: { (_) in
                SettingValues.hiddenFAB = true
                UserDefaults.standard.set(true, forKey: SettingValues.pref_hiddenFAB)
                UserDefaults.standard.set(true, forKey: "FAB_SHOWN")
                UserDefaults.standard.synchronize()
                self.setupFab(UIScreen.main.bounds.size)
            }))
            a.addAction(UIAlertAction(title: "Continue", style: .default, handler: { (_) in
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
            case .GALLERY:
                self.galleryMode()
            case .SEARCH:
                self.search()
            }
        }
    }
    
    func changeFab() {
        if !UserDefaults.standard.bool(forKey: "FAB_SHOWN") {
            UserDefaults.standard.set(true, forKey: "FAB_SHOWN")
            UserDefaults.standard.synchronize()
        }
        
        let actionSheetController: UIAlertController = UIAlertController(title: "Change button type", message: "", preferredStyle: .alert)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        for t in SettingValues.FabType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: t.getTitle(), style: .default) { _ -> Void in
                UserDefaults.standard.set(t.rawValue, forKey: SettingValues.pref_fabType)
                SettingValues.fabType = t
                self.setupFab(UIScreen.main.bounds.size)
            }
            actionSheetController.addAction(saveActionButton)
        }

        self.present(actionSheetController, animated: true, completion: nil)
    }

    var lastVersion = 0
    
    func reloadNeedingColor() {
        tableView.backgroundColor = ColorUtil.backgroundColor

        refreshControl.tintColor = ColorUtil.fontColor
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
        tableView.alwaysBounceVertical = true
        
        self.automaticallyAdjustsScrollViewInsets = false

        // TODO: Can just use .self instead of .classForCoder()
        self.tableView.register(BannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "banner\(SingleSubredditViewController.cellVersion)")
        self.tableView.register(AutoplayBannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "autoplay\(SingleSubredditViewController.cellVersion)")
        self.tableView.register(ThumbnailLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb\(SingleSubredditViewController.cellVersion)")
        self.tableView.register(TextLinkCellView.classForCoder(), forCellWithReuseIdentifier: "text\(SingleSubredditViewController.cellVersion)")
        self.tableView.register(LoadingCell.classForCoder(), forCellWithReuseIdentifier: "loading")
        self.tableView.register(PageCell.classForCoder(), forCellWithReuseIdentifier: "page")
        lastVersion = SingleSubredditViewController.cellVersion

        var top = 20
        if #available(iOS 11.0, *) {
            top = 0
        } else {
            top = 64
        }

        top += ((SettingValues.viewType && !single) ? 52 : 0)
 
        self.tableView.contentInset = UIEdgeInsets.init(top: CGFloat(top), left: 0, bottom: 65, right: 0)

        session = (UIApplication.shared.delegate as! AppDelegate).session

        if (SingleSubredditViewController.firstPresented && !single) || (self.links.count == 0 && !single && !SettingValues.viewType) {
            load(reset: true)
            SingleSubredditViewController.firstPresented = false
        }

        self.sort = SettingValues.getLinkSorting(forSubreddit: self.sub)
        self.time = SettingValues.getTimePeriod(forSubreddit: self.sub)

        if single {
            let sort = UIButton.init(type: .custom)
            sort.setImage(UIImage.init(named: "ic_sort_white")?.navIcon(), for: UIControlState.normal)
            sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControlEvents.touchUpInside)
            sort.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            let sortB = UIBarButtonItem.init(customView: sort)

            subb = UIButton.init(type: .custom)
            subb.setImage(UIImage.init(named: Subscriptions.subreddits.contains(sub) ? "subbed" : "addcircle")?.navIcon(), for: UIControlState.normal)
            subb.addTarget(self, action: #selector(self.subscribeSingle(_:)), for: UIControlEvents.touchUpInside)
            subb.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            let subbB = UIBarButtonItem.init(customView: subb)

            let info = UIButton.init(type: .custom)
            info.setImage(UIImage.init(named: "info")?.toolbarIcon(), for: UIControlState.normal)
            info.addTarget(self, action: #selector(self.doDisplaySidebar), for: UIControlEvents.touchUpInside)
            info.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            let infoB = UIBarButtonItem.init(customView: info)

            if false && (SettingValues.bottomBarHidden || SettingValues.viewType) {
                more = UIButton.init(type: .custom)
                more.setImage(UIImage.init(named: "moreh")?.navIcon(), for: UIControlState.normal)
                more.addTarget(self, action: #selector(self.showMoreNone(_:)), for: UIControlEvents.touchUpInside)
                more.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
                let moreB = UIBarButtonItem.init(customView: more)
                
                navigationItem.rightBarButtonItems = [moreB, sortB, subbB]
            } else {
                more = UIButton.init(type: .custom)
                more.setImage(UIImage.init(named: "moreh")?.menuIcon(), for: UIControlState.normal)
                more.addTarget(self, action: #selector(self.showMoreNone(_:)), for: UIControlEvents.touchUpInside)
                more.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
                let moreB = UIBarButtonItem.init(customView: more)
                
                navigationItem.rightBarButtonItems = [sortB, subbB]
                let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
                
                toolbarItems = [infoB, flexButton, moreB]
            }
            title = sub

            do {
                try (UIApplication.shared.delegate as! AppDelegate).session?.about(sub, completion: { (result) in
                    switch result {
                    case .failure:
                        print(result.error!.description)
                        DispatchQueue.main.async {
                            if self.sub == ("all") || self.sub == ("frontpage") || self.sub.lowercased() == ("myrandom") || self.sub.lowercased() == ("random") || self.sub.lowercased() == ("randnsfw") || self.sub.hasPrefix("/m/") || self.sub.contains("+") {
                                self.load(reset: true)
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                                    let alert = UIAlertController.init(title: "Subreddit not found", message: "r/\(self.sub) could not be found, is it spelled correctly?", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction.init(title: "Close", style: .default, handler: { (_) in
                                        self.navigationController?.popViewController(animated: true)
                                        self.dismiss(animated: true, completion: nil)

                                    }))
                                    self.present(alert, animated: true, completion: nil)
                                }

                            }
                        }
                    case .success(let r):
                        self.subInfo = r
                        DispatchQueue.main.async {
                            if self.subInfo!.over18 && !SettingValues.nsfwEnabled {
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                                    let alert = UIAlertController.init(title: "r/\(self.sub) is NSFW", message: "If you are 18 and willing to see adult content, enable NSFW content in Settings > Content", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction.init(title: "Close", style: .default, handler: { (_) in
                                        self.navigationController?.popViewController(animated: true)
                                        self.dismiss(animated: true, completion: nil)
                                    }))
                                    self.present(alert, animated: true, completion: nil)
                                }
                            } else {
                                if self.sub != ("all") && self.sub != ("frontpage") && !self.sub.hasPrefix("/m/") {
                                    if SettingValues.saveHistory {
                                        if SettingValues.saveNSFWHistory && self.subInfo!.over18 {
                                            Subscriptions.addHistorySub(name: AccountController.currentName, sub: self.subInfo!.displayName)
                                        } else if !self.subInfo!.over18 {
                                            Subscriptions.addHistorySub(name: AccountController.currentName, sub: self.subInfo!.displayName)
                                        }
                                    }
                                }
                                print("Loading")
                                self.load(reset: true)
                            }

                        }
                    }
                })
            } catch {
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
        let alrController = UIAlertController(title: sub.displayName, message: sub.descriptionMd, preferredStyle: UIAlertControllerStyle.alert)
        for s in sub.subreddits {
            let somethingAction = UIAlertAction(title: "r/" + s, style: UIAlertActionStyle.default, handler: { (_: UIAlertAction!) in
                VCPresenter.showVC(viewController: SingleSubredditViewController.init(subName: s, single: true), popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
            })
            let color = ColorUtil.getColorForSub(sub: s)
            if color != ColorUtil.baseColor {
                somethingAction.setValue(color, forKey: "titleTextColor")

            }
            alrController.addAction(somethingAction)

        }
        var somethingAction = UIAlertAction(title: "Edit multireddit", style: UIAlertActionStyle.default, handler: { (_: UIAlertAction!) in print("something") })
        alrController.addAction(somethingAction)

        somethingAction = UIAlertAction(title: "Delete multireddit", style: UIAlertActionStyle.destructive, handler: { (_: UIAlertAction!) in print("something") })
        alrController.addAction(somethingAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (_: UIAlertAction!) in print("cancel") })

        alrController.addAction(cancelAction)

        //todo make this work on ipad
        self.present(alrController, animated: true, completion: {})
    }

    func subscribeSingle(_ selector: AnyObject) {
        if subChanged && !Subscriptions.isSubscriber(sub) || Subscriptions.isSubscriber(sub) {
            //was not subscriber, changed, and unsubscribing again
            Subscriptions.unsubscribe(sub, session: session!)
            subChanged = false
            BannerUtil.makeBanner(text: "Unsubscribed", color: ColorUtil.accentColorForSub(sub: sub), seconds: 3, context: self, top: true)
            subb.setImage(UIImage.init(named: "addcircle")?.navIcon(), for: UIControlState.normal)
        } else {
            let alrController = UIAlertController.init(title: "Follow r/\(sub)", message: nil, preferredStyle: .actionSheet)
            if AccountController.isLoggedIn {
                let somethingAction = UIAlertAction(title: "Subscribe", style: UIAlertActionStyle.default, handler: { (_: UIAlertAction!) in
                    Subscriptions.subscribe(self.sub, true, session: self.session!)
                    self.subChanged = true
                    BannerUtil.makeBanner(text: "Subscribed to r/\(self.sub)", color: ColorUtil.accentColorForSub(sub: self.sub), seconds: 3, context: self, top: true)
                    self.subb.setImage(UIImage.init(named: "subbed")?.navIcon(), for: UIControlState.normal)
                })
                alrController.addAction(somethingAction)
            }

            let somethingAction = UIAlertAction(title: "Casually subscribe", style: UIAlertActionStyle.default, handler: { (_: UIAlertAction!) in
                Subscriptions.subscribe(self.sub, false, session: self.session!)
                self.subChanged = true
                BannerUtil.makeBanner(text: "r/\(self.sub) added to your subreddit list", color: ColorUtil.accentColorForSub(sub: self.sub), seconds: 3, context: self, top: true)
                self.subb.setImage(UIImage.init(named: "subbed")?.navIcon(), for: UIControlState.normal)
            })
            alrController.addAction(somethingAction)

            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (_: UIAlertAction!) in print("cancel") })

            alrController.addAction(cancelAction)

            alrController.modalPresentationStyle = .fullScreen
            if let presenter = alrController.popoverPresentationController {
                presenter.sourceView = subb
                presenter.sourceRect = subb.bounds
            }

            self.present(alrController, animated: true, completion: {})

        }

    }

    func displayMultiredditSidebar() {
        do {
            print("Getting \(sub.substring(3, length: sub.length - 3))")
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

    func hideReadPosts() {
        var indexPaths: [IndexPath] = []

        var index = 0
        var count = 0
        for submission in links {
            if History.getSeen(s: submission) {
                indexPaths.append(IndexPath(row: count, section: 0))
                links.remove(at: index)
            } else {
                index += 1
            }
            count += 1
        }

        //todo save realm
        DispatchQueue.main.async {
            if !indexPaths.isEmpty {
                self.flowLayout.reset()
                self.tableView.performBatchUpdates({
                    self.tableView.deleteItems(at: indexPaths)
                }, completion: nil)
            }
        }
    }

    func doHeadView() {
        inHeadView.removeFromSuperview()
        inHeadView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: max(self.view.frame.size.width, self.view.frame.size.height), height: (UIApplication.shared.statusBarView?.frame.size.height ?? 20)))
        self.inHeadView.backgroundColor = ColorUtil.getColorForSub(sub: sub, true)
        
        if !(navigationController is TapBehindModalViewController) {
            self.view.addSubview(inHeadView)
        }
    }
    
    func resetColors() {
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: sub, true)
        setupFab(UIScreen.main.bounds.size)
        if parentController != nil {
            parentController?.colorChanged(ColorUtil.getColorForSub(sub: sub))
        }
    }

    func reloadDataReset() {
        self.flowLayout.reset()
        tableView.reloadData()
        tableView.layoutIfNeeded()
        setupFab(UIScreen.main.bounds.size)
    }

    func search() {
        let alert = UIAlertController(title: "Search", message: "", preferredStyle: .alert)

        let config: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = "Search for a post..."
            textField.left(image: UIImage.init(named: "search"), color: .black)
            textField.leftViewPadding = 12
            textField.borderWidth = 1
            textField.cornerRadius = 8
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = .white
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.action { textField in
                self.searchText = textField.text
            }
        }

        alert.addOneTextField(configuration: config)

        alert.addAction(UIAlertAction(title: "Search All", style: .default, handler: { (_) in
            let text = self.searchText ?? ""
            let search = SearchViewController.init(subreddit: "all", searchFor: text)
            VCPresenter.showVC(viewController: search, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }))

        if sub != "all" && sub != "frontpage" && sub != "friends" && !sub.startsWith("/m/") {
            alert.addAction(UIAlertAction(title: "Search \(sub)", style: .default, handler: { (_) in
                let text = self.searchText ?? ""
                let search = SearchViewController.init(subreddit: self.sub, searchFor: text)
                VCPresenter.showVC(viewController: search, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
            }))
        }

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)

    }
    
    func doDisplaySidebar() {
        Sidebar.init(parent: self, subname: self.sub).displaySidebar()
    }

    func filterContent() {
        let alert = UIAlertController(title: "Content to hide on", message: "r/\(sub)", preferredStyle: .alert)

        let settings = Filter(subreddit: sub, parent: self)

        alert.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: nil))
        alert.setValue(settings, forKey: "contentViewController")
        present(alert, animated: true, completion: nil)
    }

    func galleryMode() {
        if !VCPresenter.proDialogShown(feature: true, self) {
            let controller = GalleryTableViewController()
            var gLinks: [RSubmission] = []
            for l in links {
                if l.banner {
                    gLinks.append(l)
                }
            }
            controller.setLinks(links: gLinks)
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true, completion: nil)
        }
    }

    func shadowboxMode() {
        if !VCPresenter.proDialogShown(feature: true, self) && !links.isEmpty {
            let controller = ShadowboxViewController.init(submissions: links, subreddit: sub)
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadMore() {
        if !showing {
            showLoader()
        }
        load(reset: false)
    }

    func showLoader() {
        showing = true
        //todo maybe?
    }

    func showSortMenu(_ selector: UIView?) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

        for link in LinkSortType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default) { _ -> Void in
                self.showTimeMenu(s: link, selector: selector)
            }
            if sort == link {
                saveActionButton.setValue(selected, forKey: "image")
            }
            actionSheetController.addAction(saveActionButton)
        }

        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = selector!
            presenter.sourceRect = selector!.bounds
        }

        self.present(actionSheetController, animated: true, completion: nil)

    }

    func showTimeMenu(s: LinkSortType, selector: UIView?) {
        if s == .hot || s == .new || s == .rising {
            sort = s
            refresh()
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { _ -> Void in
            }
            actionSheetController.addAction(cancelActionButton)

            let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default) { _ -> Void in
                    self.sort = s
                    self.time = t
                    self.refresh()
                }
                if time == t {
                    saveActionButton.setValue(selected, forKey: "image")
                }

                actionSheetController.addAction(saveActionButton)
            }

            if let presenter = actionSheetController.popoverPresentationController {
                presenter.sourceView = selector!
                presenter.sourceRect = selector!.bounds
            }

            self.present(actionSheetController, animated: true, completion: nil)
        }
    }

    func refresh(_ indicator: Bool = true) {
        if indicator {
            refreshControl.beginRefreshing()
        }
        
        links = []
        flowLayout.reset()
        flowLayout.invalidateLayout()
        tableView.reloadData()
        load(reset: true)
    }

    func deleteSelf(_ cell: LinkCellView) {
        do {
            try session?.deleteCommentOrLink(cell.link!.getId(), completion: { (_) in
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
    
    var page = 0

    func load(reset: Bool) {
        PagingCommentViewController.savedComment = nil
        if sub.lowercased() == "randnsfw" && !SettingValues.nsfwEnabled {
            DispatchQueue.main.async {
                let alert = UIAlertController.init(title: "r/\(self.sub) is NSFW", message: "If you are 18 and willing to see adult content, enable NSFW content in Settings > Content", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "Close", style: .default, handler: { (_) in
                    self.navigationController?.popViewController(animated: true)
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
            self.refreshControl.endRefreshing()
            return
        } else if sub.lowercased() == "myrandom" && !AccountController.isGold {
            DispatchQueue.main.async {
                let alert = UIAlertController.init(title: "r/\(self.sub) requires gold", message: "See reddit.com/gold/about for more details", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "Close", style: .default, handler: { (_) in
                    self.navigationController?.popViewController(animated: true)
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
            self.refreshControl.endRefreshing()
            return
        }
        if !loading {
            if !loaded {
                if indicator == nil {
                    indicator = MDCActivityIndicator.init(frame: CGRect.init(x: CGFloat(0), y: CGFloat(0), width: CGFloat(80), height: CGFloat(80)))
                    indicator?.strokeWidth = 5
                    indicator?.radius = 15
                    indicator?.indicatorMode = .indeterminate
                    indicator?.cycleColors = [ColorUtil.getColorForSub(sub: sub), ColorUtil.accentColorForSub(sub: sub)]
                    let center = CGPoint.init(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                    indicator?.center = center
                    self.tableView.addSubview(indicator!)
                    indicator?.startAnimating()
                }
            }
            loaded = true

            do {
                loading = true
                if reset {
                    paginator = Paginator()
                    self.page = 0
                }
                if reset || !loaded {
                    self.startTime = Date()
                }
                var subreddit: SubredditURLPath = Subreddit.init(subreddit: sub)

                if sub.hasPrefix("/m/") {
                    subreddit = Multireddit.init(name: sub.substring(3, length: sub.length - 3), user: AccountController.currentName)
                }

                try session?.getList(paginator, subreddit: subreddit, sort: sort, timeFilterWithin: time, completion: { (result) in
                    switch result {
                    case .failure:
                        print(result.error!)
                        //test if realm exists and show that
                            print("Getting realm data")
                                DispatchQueue.main.async {
                                    do {
                                        let realm = try Realm()
                                        var updated = NSDate()
                                        if let listing = realm.objects(RListing.self).filter({ (item) -> Bool in
                                            return item.subreddit == self.sub
                                        }).first {
                                            self.links = []
                                            for i in listing.links {
                                                self.links.append(i)
                                            }
                                            updated = listing.updated
                                        }
                                        var paths = [IndexPath]()
                                        for i in 0..<self.links.count {
                                            paths.append(IndexPath.init(item: i, section: 0))
                                        }
                                        self.flowLayout.reset()
                                        self.tableView.reloadData()
                                        
                                        self.refreshControl.endRefreshing()
                                        self.indicator?.stopAnimating()
                                        self.indicator?.isHidden = true
                                        self.loading = false
                                        self.loading = false
                                        self.nomore = true
                                        
                                        self.tableView.contentOffset = CGPoint.init(x: 0, y: -64 + ((SettingValues.viewType && !self.single) ? -20 : 0))
                                        
                                        if self.links.isEmpty {
                                            BannerUtil.makeBanner(text: "No offline content found! You can set up subreddit caching in Settings > Auto Cache", color: ColorUtil.accentColorForSub(sub: self.sub), seconds: 5, context: self)
                                        } else {
                                            BannerUtil.makeBanner(text: "Showing offline content (\(DateFormatter().timeSince(from: updated, numericDates: true)))", color: ColorUtil.accentColorForSub(sub: self.sub), seconds: 3, context: self)
                                        }
                                    } catch {
                                        
                                    }

                                }
                    case .success(let listing):

                        if reset {
                            self.links = []
                            self.page = 0
                        }
                        let before = self.links.count
                        if self.realmListing == nil {
                            self.realmListing = RListing()
                            self.realmListing!.subreddit = self.sub
                            self.realmListing!.updated = NSDate()
                        }
                        if reset && self.realmListing!.links.count > 0 {
                            self.realmListing!.links.removeAll()
                        }

                        let newLinks = listing.children.flatMap({ $0 as? Link })
                        var converted: [RSubmission] = []
                        for link in newLinks {
                            let newRS = RealmDataWrapper.linkToRSubmission(submission: link)
                            converted.append(newRS)
                            CachedTitle.addTitle(s: newRS)
                        }
                        var values = PostFilter.filter(converted, previous: self.links, baseSubreddit: self.sub)
                        if self.page > 0 && !values.isEmpty && SettingValues.showPages {
                            let pageItem = RSubmission()
                            pageItem.subreddit = DateFormatter().timeSince(from: self.startTime as NSDate, numericDates: true)
                            pageItem.author = "PAGE_SEPARATOR"
                            pageItem.title = "Page \(self.page + 1)\n\(self.links.count + values.count - self.page) posts"
                            values.insert(pageItem, at: 0)
                        }
                        self.page += 1
                        
                        self.links += values
                        self.paginator = listing.paginator
                        self.nomore = !listing.paginator.hasMore() || values.isEmpty
                        do {
                            let realm = try! Realm()
                            //todo insert
                            realm.beginWrite()
                            for submission in self.links {
                                if submission.author != "PAGE_SEPARATOR" {
                                    realm.create(type(of: submission), value: submission, update: true)
                                    self.realmListing!.links.append(submission)
                                }
                            }
                            realm.create(type(of: self.realmListing!), value: self.realmListing!, update: true)
                            try realm.commitWrite()
                        } catch {

                        }
                        
                        self.preloadImages(values)
                        DispatchQueue.main.async {
                            if self.links.isEmpty {
                                self.flowLayout.reset()
                                self.tableView.reloadData()
                                
                                self.refreshControl.endRefreshing()
                                self.indicator?.stopAnimating()
                                self.indicator?.isHidden = true
                                self.loading = false
                                if MainViewController.first {
                                    MainViewController.first = false
                                    self.parentController?.checkForMail()
                                }
                                if listing.children.isEmpty {
                                    BannerUtil.makeBanner(text: "No posts found!\nMake sure this sub exists and you have permission to view it", color: GMColor.red500Color(), seconds: 5, context: self)
                                } else {
                                    BannerUtil.makeBanner(text: "No posts found!\nCheck your filter settings, or tap here to reload.", color: GMColor.red500Color(), seconds: 5, context: self) {
                                        self.refresh()
                                    }
                                }
                            } else {
                                var paths = [IndexPath]()
                                for i in before..<self.links.count {
                                    paths.append(IndexPath.init(item: i, section: 0))
                                }

                                if before == 0 {
                                    self.flowLayout.invalidateLayout()
                                    self.tableView.reloadData()
                                    var top = CGFloat(0)
                                    if #available(iOS 11, *) {
                                        top += 22
                                        if !SettingValues.viewType {
                                            top += 4
                                        }
                                    }
                                
                                    self.tableView.contentOffset = CGPoint.init(x: 0, y: -18 + (-1 * ((SettingValues.viewType && !self.single) ? 52 : (self.navigationController?.navigationBar.frame.size.height ?? 64))) - top)
                                } else {
                                    self.flowLayout.invalidateLayout()
                                    self.tableView.insertItems(at: paths)
                                }

                                self.indicator?.stopAnimating()
                                self.indicator?.isHidden = true
                                self.refreshControl.endRefreshing()
                                self.loading = false
                                if MainViewController.first {
                                    MainViewController.first = false
                                    self.parentController?.checkForMail()
                                }
                                
                            }
                        }
                    }
                })
            } catch {
                print(error)
            }

        }
    }

    func preloadImages(_ values: [RSubmission]) {
        var urls: [URL] = []
        if !SettingValues.noImages {
        for submission in values {
            var thumb = submission.thumbnail
            var big = submission.banner
            var height = submission.height
            if submission.url != nil {
            var type = ContentType.getContentType(baseUrl: submission.url)
            if submission.isSelf {
                type = .SELF
            }

            if thumb && type == .SELF {
                thumb = false
            }

            let fullImage = ContentType.fullImage(t: type)

            if !fullImage && height < 50 {
                big = false
                thumb = true
            } else if big && (SettingValues.postImageMode == .CROPPED_IMAGE) {
                height = 200
            }

            if type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big || type == .SELF {
                big = false
                thumb = false
            }

            if height < 50 {
                thumb = true
                big = false
            }

            let shouldShowLq = SettingValues.dataSavingEnabled && submission.lQ && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi())
            if type == ContentType.CType.SELF && SettingValues.hideImageSelftext
                    || SettingValues.noImages && submission.isSelf {
                big = false
                thumb = false
            }

            if big || !submission.thumbnail {
                thumb = false
            }

            if !big && !thumb && submission.type != .SELF && submission.type != .NONE {
                thumb = true
            }

            if thumb && !big {
                if submission.thumbnailUrl == "nsfw" {
                } else if submission.thumbnailUrl == "web" || submission.thumbnailUrl.isEmpty {
                } else {
                    if let url = URL.init(string: submission.thumbnailUrl) {
                        urls.append(url)
                    }
                }
            }

            if big {
                if shouldShowLq {
                    if let url = URL.init(string: submission.lqUrl) {
                        urls.append(url)
                    }

                } else {
                    if let url = URL.init(string: submission.bannerUrl) {
                        urls.append(url)
                    }
                }
            }
            }
        }
        SDWebImagePrefetcher.init().prefetchURLs(urls)
        }
    }
    
    static func sizeWith(_ submission: RSubmission, _ width: CGFloat, _ isCollection: Bool) -> CGSize {
        let itemWidth = width
        var thumb = submission.thumbnail
        var big = submission.banner
        
        var submissionHeight = CGFloat(submission.height)
        
        var type = ContentType.getContentType(baseUrl: submission.url)
        if submission.isSelf {
            type = .SELF
        }
        
        if SettingValues.postImageMode == .THUMBNAIL {
            big = false
            thumb = true
        }
        
        let fullImage = ContentType.fullImage(t: type)
        
        if !fullImage && submissionHeight < 50 {
            big = false
            thumb = true
        } else if big && (( SettingValues.postImageMode == .CROPPED_IMAGE)) && !(SettingValues.shouldAutoPlay() && (ContentType.displayVideo(t: type) && type != .VIDEO)) {
            submissionHeight = 200
        } else if big {
            let h = getHeightFromAspectRatio(imageHeight: submissionHeight, imageWidth: CGFloat(submission.width), viewWidth: itemWidth - ((SettingValues.postViewMode != .CARD) ? CGFloat(5) : CGFloat(0)))
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
        
        if submissionHeight < 50 {
            thumb = true
            big = false
        }
        
        if type == ContentType.CType.SELF && SettingValues.hideImageSelftext
            || SettingValues.noImages && submission.isSelf {
            big = false
            thumb = false
        }
        
        if big || !submission.thumbnail {
            thumb = false
        }
        
        if (thumb || big) && submission.nsfw && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection && isCollection) {
            big = false
            thumb = true
        }
        
        if SettingValues.noImages {
            big = false
            thumb = false
        }
        
        if thumb && type == .SELF {
            thumb = false
        }
        
        if !big && !thumb && submission.type != .SELF && submission.type != .NONE { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
        }
        
        if type == .LINK && SettingValues.linkAlwaysThumbnail {
            thumb = true
            big = false
        }
        
        if (thumb || big) && submission.spoiler {
            thumb = true
            big = false
        }
        
        if big {
            let imageSize = CGSize.init(width: submission.width, height: ((SettingValues.postImageMode == .CROPPED_IMAGE)) ? 200 : submission.height)
            
            var aspect = imageSize.width / imageSize.height
            if aspect == 0 || aspect > 10000 || aspect.isNaN {
                aspect = 1
            }
            if SettingValues.postImageMode == .CROPPED_IMAGE && !(SettingValues.shouldAutoPlay() && (ContentType.displayVideo(t: type) && type != .VIDEO)) {
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
        if SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER {
            paddingTop = 5
            paddingBottom = 5
            paddingLeft = 5
            paddingRight = 5
        }
        
        let actionbar = CGFloat(SettingValues.actionBarMode != .FULL ? 0 : 24)
        
        let thumbheight = (SettingValues.largerThumbnail ? CGFloat(75) : CGFloat(50)) - (SettingValues.postViewMode == .COMPACT ? 15 : 0)
        let textHeight = CGFloat(submission.isSelf ? 5 : 0)
        
        if thumb {
            innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between top and thumbnail
            if SettingValues.actionBarMode == .FULL {
                innerPadding += 18 - (SettingValues.postViewMode == .COMPACT ? 4 : 0) //between label and bottom box
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between box and end
            } else {
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between thumbnail and bottom
            }
        } else if big {
            if SettingValues.postViewMode == .CENTER {
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 16) //between label
                if SettingValues.actionBarMode == .FULL {
                    innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between banner and box
                } else {
                    innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between buttons and bottom
                }
            } else {
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between banner and label
                if SettingValues.actionBarMode == .FULL {
                    innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between label and box
                } else {
                    innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between buttons and bottom
                }
            }
            if SettingValues.actionBarMode == .FULL {
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between box and end
            }
        } else {
            if !submission.body.trimmed().isEmpty() && SettingValues.showFirstParagraph {
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8)
            }
            innerPadding += (SettingValues.postViewMode == .COMPACT ? 16 : 24) //between top and title
            if SettingValues.actionBarMode == .FULL {
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between body and box
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between box and end
            }
        }
        
        var estimatedUsableWidth = itemWidth - paddingLeft - paddingRight
        if thumb {
            estimatedUsableWidth -= thumbheight //is the same as the width
            estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 16 : 24) //between edge and thumb
            estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between thumb and label
        } else {
            estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 16 : 24) //12 padding on either side
        }
        
        if SettingValues.postImageMode == .CROPPED_IMAGE && !(SettingValues.shouldAutoPlay() && (ContentType.displayVideo(t: type) && type != .VIDEO)) {
            submissionHeight = 200
        } else {
            let bannerPadding = (SettingValues.postViewMode != .CARD) ? CGFloat(5) : CGFloat(0)
            submissionHeight = getHeightFromAspectRatio(imageHeight: submissionHeight == 200 ? CGFloat(200) : CGFloat(submission.height), imageWidth: CGFloat(submission.width), viewWidth: width - paddingLeft - paddingRight - (bannerPadding * 2))
        }
        var imageHeight = big && !thumb ? CGFloat(submissionHeight) : CGFloat(0)
        
        if thumb {
            imageHeight = thumbheight
        }
        
        if SettingValues.actionBarMode.isSide() {
            estimatedUsableWidth -= 40
            estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 8 : 16) //buttons horizontal margins
            if thumb {
                estimatedUsableWidth += (SettingValues.postViewMode == .COMPACT ? 16 : 24) //between edge and thumb no longer exists
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 4 : 8) //buttons buttons and thumb
            }
        }
        
        let framesetter = CTFramesetterCreateWithAttributedString(CachedTitle.getTitle(submission: submission, full: false, false))
        let textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize.init(width: estimatedUsableWidth, height: CGFloat.greatestFiniteMagnitude), nil)
        let totalHeight = paddingTop + paddingBottom + (thumb ? max(SettingValues.actionBarMode.isSide() ? 60 : 0, ceil(textSize.height), imageHeight) : max(SettingValues.actionBarMode.isSide() ? 60 : 0, ceil(textSize.height)) + imageHeight) + innerPadding + actionbar + textHeight
        return CGSize(width: itemWidth, height: totalHeight)
    }

    // TODO: This is mostly replicated by `RSubmission.getLinkView()`. Can we consolidate?
    static func cellType(forSubmission submission: RSubmission, _ isCollection: Bool) -> CurrentType {
        var target: CurrentType = .none

        var thumb = submission.thumbnail
        var big = submission.banner
        let height = submission.height

        var type = ContentType.getContentType(baseUrl: submission.url)
        if submission.isSelf {
            type = .SELF
        }

        if SettingValues.postImageMode == .THUMBNAIL {
            big = false
            thumb = true
        }

        let fullImage = ContentType.fullImage(t: type)

        if !fullImage && height < 50 {
            big = false
            thumb = true
        }

        if type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big {
            big = false
            thumb = false
        }

        if height < 50 {
            thumb = true
            big = false
        }

        if type == ContentType.CType.SELF && SettingValues.hideImageSelftext
            || SettingValues.noImages && submission.isSelf {
            big = false
            thumb = false
        }

        if big || !submission.thumbnail {
            thumb = false
        }
        
        if SettingValues.noImages {
            big = false
            thumb = false
        }
        
        if thumb && type == .SELF {
            thumb = false
        }

        if !big && !thumb && submission.type != .SELF && submission.type != .NONE { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
        }

        if (thumb || big) && submission.nsfw && (!SettingValues.nsfwPreviews || (SettingValues.hideNSFWCollection && isCollection)) {
            big = false
            thumb = true
        }
        
        if (thumb || big) && submission.spoiler {
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
                let imageData: Data = UIImagePNGRepresentation(coloredIcon)! 
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

// MARK: - Actions
extension SingleSubredditViewController {

    @objc func spacePressed() {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.tableView.contentOffset.y += 350
        }, completion: nil)
    }

    func drefresh(_ sender: AnyObject) {
        refresh()
    }

    func showMoreNone(_ sender: AnyObject) {
        showMore(sender, parentVC: nil)
    }

    func hideAll(_ sender: AnyObject) {
        for submission in links {
            if History.getSeen(s: submission) {
                let index = links.index(of: submission)!
                links.remove(at: index)
            }
        }
        self.flowLayout.reset()
        tableView.reloadData()
    }

    func pickTheme(sender: AnyObject?, parent: MainViewController?) {
        parentController = parent
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

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

        /*todo maybe ?alertController.addAction(image: UIImage.init(named: "accent"), title: "Custom color", color: ColorUtil.accentColorForSub(sub: sub), style: .default, isEnabled: true) { (action) in
         if(!VCPresenter.proDialogShown(feature: false, self)){
         let alert = UIAlertController.init(title: "Choose a color", message: nil, preferredStyle: .actionSheet)
         alert.addColorPicker(color: (self.navigationController?.navigationBar.barTintColor)!, selection: { (c) in
         ColorUtil.setColorForSub(sub: self.sub, color: (self.navigationController?.navigationBar.barTintColor)!)
         self.reloadDataReset()
         self.navigationController?.navigationBar.barTintColor = c
         UIApplication.shared.statusBarView?.backgroundColor = c
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
            ColorUtil.setColorForSub(sub: self.sub, color: (self.navigationController?.navigationBar.barTintColor)!)
            self.pickAccent(sender: sender, parent: parent)
            self.reloadDataReset()
        }

        alertController.addAction(image: nil, title: "Save", color: ColorUtil.accentColorForSub(sub: sub), style: .default) { _ in
            ColorUtil.setColorForSub(sub: self.sub, color: (self.navigationController?.navigationBar.barTintColor)!)
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
    
    func pickAccent(sender: AnyObject?, parent: MainViewController?) {
        parentController = parent
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

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

    func newPost(_ sender: AnyObject) {
        PostActions.showPostMenu(self, sub: self.sub)
    }

    func showMore(_ sender: AnyObject, parentVC: MainViewController? = nil) {

        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "r/\(sub)"

        alertController.addAction(Action(ActionData(title: "Search", image: UIImage(named: "search")!.menuIcon()), style: .default, handler: { _ in
            self.search()
        }))

        if !single && SettingValues.viewType {
            alertController.addAction(Action(ActionData(title: "Sort (currently \(sort.path))", image: UIImage(named: "filter")!.menuIcon()), style: .default, handler: { _ in
                self.showSortMenu(self.more)
            }))
        }

        if sub.contains("/m/") {
            alertController.addAction(Action(ActionData(title: "Manage multireddit", image: UIImage(named: "info")!.menuIcon()), style: .default, handler: { _ in
                self.displayMultiredditSidebar()
            }))
        } else {
            alertController.addAction(Action(ActionData(title: "Sidebar", image: UIImage(named: "info")!.menuIcon()), style: .default, handler: { _ in
                self.doDisplaySidebar()
            }))
        }

        alertController.addAction(Action(ActionData(title: "Refresh", image: UIImage(named: "sync")!.menuIcon()), style: .default, handler: { _ in
            self.refresh()
        }))
        
        alertController.addAction(Action(ActionData(title: "Gallery", image: UIImage(named: "image")!.menuIcon()), style: .default, handler: { _ in
            self.galleryMode()
        }))

        alertController.addAction(Action(ActionData(title: "Shadowbox", image: UIImage(named: "shadowbox")!.menuIcon()), style: .default, handler: { _ in
            self.shadowboxMode()
        }))

        alertController.addAction(Action(ActionData(title: "Subreddit theme", image: UIImage(named: "colors")!.menuIcon()), style: .default, handler: { _ in
            if parentVC != nil {
                let p = (parentVC!)
                self.pickTheme(sender: sender, parent: p)
            } else {
                self.pickTheme(sender: sender, parent: nil)
            }
        }))

        if sub != "all" && sub != "frontpage" && !sub.contains("+") && !sub.contains("/m/") {
            alertController.addAction(Action(ActionData(title: "Submit", image: UIImage(named: "edit")!.menuIcon()), style: .default, handler: { _ in
                self.newPost(sender)
            }))
        }

        alertController.addAction(Action(ActionData(title: "Filter content", image: UIImage(named: "filter")!.menuIcon()), style: .default, handler: { _ in
            if !self.links.isEmpty || self.loaded {
                self.filterContent()
            }
        }))
        
        alertController.addAction(Action(ActionData(title: "Add to homescreen", image: UIImage(named: "add_homescreen")!.menuIcon()), style: .default, handler: { _ in
            self.addToHomescreen()
        }))

        VCPresenter.presentAlert(alertController, parentVC: self)

    }

}

// MARK: - Collection View Delegate
extension SingleSubredditViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is LinkCellView && (cell as! LinkCellView).videoView != nil {
            (cell as! LinkCellView).videoView!.player?.pause()
            (cell as! LinkCellView).videoView!.player?.currentItem?.asset.cancelLoading()
            (cell as! LinkCellView).videoView!.player?.currentItem?.cancelPendingSeeks()
            (cell as! LinkCellView).videoView!.player = nil
            (cell as! LinkCellView).updater?.invalidate()
        }
        if SettingValues.markReadOnScroll && indexPath.row < links.count {
            History.addSeen(s: links[indexPath.row])
        }
    }
}

// MARK: - Collection View Data Source
extension SingleSubredditViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return links.count + ((links.count != 0 && loaded) ? 1 : 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row >= self.links.count {
            let cell = tableView.dequeueReusableCell(withReuseIdentifier: "loading", for: indexPath) as! LoadingCell
            cell.loader.color = ColorUtil.fontColor
            cell.loader.startAnimating()
            if !loading && !nomore {
                self.loadMore()
            }
            return cell
        }

        let submission = self.links[(indexPath as NSIndexPath).row]

        if submission.author == "PAGE_SEPARATOR" {
            let cell = tableView.dequeueReusableCell(withReuseIdentifier: "page", for: indexPath) as! PageCell
            
            let textParts = submission.title.components(separatedBy: "\n")
            
            let finalText: NSMutableAttributedString!
            if textParts.count > 1 {
                let firstPart = NSMutableAttributedString.init(string: textParts[0], attributes: [NSForegroundColorAttributeName: ColorUtil.fontColor, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16)])
                let secondPart = NSMutableAttributedString.init(string: "\n" + textParts[1], attributes: [NSForegroundColorAttributeName: ColorUtil.fontColor, NSFontAttributeName: UIFont.systemFont(ofSize: 13)])
                firstPart.append(secondPart)
                finalText = firstPart
            } else {
                finalText = NSMutableAttributedString.init(string: submission.title, attributes: [NSForegroundColorAttributeName: ColorUtil.fontColor, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
            }

            cell.time.font = UIFont.systemFont(ofSize: 12)
            cell.time.textColor = ColorUtil.fontColor
            cell.time.alpha = 0.7
            cell.time.text = submission.subreddit
            
            cell.title.attributedText = finalText
            return cell
        }

        var cell: LinkCellView!
        
        if lastVersion != SingleSubredditViewController.cellVersion {
            self.tableView.register(BannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "banner\(SingleSubredditViewController.cellVersion)")
            self.tableView.register(AutoplayBannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "autoplay\(SingleSubredditViewController.cellVersion)")
            self.tableView.register(ThumbnailLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb\(SingleSubredditViewController.cellVersion)")
            self.tableView.register(TextLinkCellView.classForCoder(), forCellWithReuseIdentifier: "text\(SingleSubredditViewController.cellVersion)")
        }

        switch SingleSubredditViewController.cellType(forSubmission: submission, Subscriptions.isCollection(sub)) {
        case .thumb:
            cell = tableView.dequeueReusableCell(withReuseIdentifier: "thumb\(SingleSubredditViewController.cellVersion)", for: indexPath) as! ThumbnailLinkCellView
        case .autoplay:
            cell = tableView.dequeueReusableCell(withReuseIdentifier: "autoplay\(SingleSubredditViewController.cellVersion)", for: indexPath) as! AutoplayBannerLinkCellView
        case .banner:
            cell = tableView.dequeueReusableCell(withReuseIdentifier: "banner\(SingleSubredditViewController.cellVersion)", for: indexPath) as! BannerLinkCellView
        default:
            cell = tableView.dequeueReusableCell(withReuseIdentifier: "text\(SingleSubredditViewController.cellVersion)", for: indexPath) as! TextLinkCellView
        }

        cell.preservesSuperviewLayoutMargins = false
        cell.del = self
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        
        //cell.panGestureRecognizer?.require(toFail: self.tableView.panGestureRecognizer)
        //ecell.panGestureRecognizer2?.require(toFail: self.tableView.panGestureRecognizer)

        cell.configure(submission: submission, parent: self, nav: self.navigationController, baseSub: self.sub)

        return cell
    }

}

// MARK: - Collection View Prefetching Data Source
//extension SingleSubredditViewController: UICollectionViewDataSourcePrefetching {
//    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
//        // TODO: Implement
//    }
//}

// MARK: - Link Cell View Delegate
extension SingleSubredditViewController: LinkCellViewDelegate {

    func openComments(id: String, subreddit: String?) {
        var index = 0
        for s in links {
            if s.getId() == id {
                break
            }
            index += 1
        }
        var newLinks: [RSubmission] = []
        for i in index ..< links.count {
            newLinks.append(links[i])
        }

        if self.splitViewController != nil && UIScreen.main.traitCollection.userInterfaceIdiom == .pad && !SettingValues.multiColumn {
            let comment = CommentViewController.init(submission: newLinks[0])
            let nav = UINavigationController.init(rootViewController: comment)
            self.splitViewController?.showDetailViewController(nav, sender: self)
        } else {
            let comment = PagingCommentViewController.init(submissions: newLinks)
            VCPresenter.showVC(viewController: comment, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }
    }
}

// MARK: - Color Picker View Delegate
extension SingleSubredditViewController: ColorPickerViewDelegate {
    public func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        if isAccent {
            accentChosen = colorPickerView.colors[indexPath.row]
            self.fab?.backgroundColor = accentChosen
        } else {
            let c = colorPickerView.colors[indexPath.row]
            self.navigationController?.navigationBar.barTintColor = SettingValues.reduceColor ? ColorUtil.backgroundColor : c
            sideView.backgroundColor = c
            sideView.backgroundColor = c
            inHeadView.backgroundColor = SettingValues.reduceColor ? ColorUtil.backgroundColor : c
            if parentController != nil {
                parentController?.colorChanged(c)
            }
        }
    }
}

// MARK: - Wrapping Flow Layout Delegate
extension SingleSubredditViewController: WrappingFlowLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, width: CGFloat, indexPath: IndexPath) -> CGSize {
        if indexPath.row < links.count {
            let submission = links[indexPath.row]
            if submission.author == "PAGE_SEPARATOR" {
                return CGSize(width: width, height: 80)
            }
            return SingleSubredditViewController.sizeWith(submission, width, Subscriptions.isCollection(sub))
        }
        return CGSize(width: width, height: 80)
    }
}

// MARK: - Submission More Delegate
extension SingleSubredditViewController: SubmissionMoreDelegate {
    func reply(_ cell: LinkCellView) {

    }

    func save(_ cell: LinkCellView) {
        do {
            try session?.setSave(!ActionStates.isSaved(s: cell.link!), name: (cell.link?.getId())!, completion: { (_) in

            })
            ActionStates.setSaved(s: cell.link!, saved: !ActionStates.isSaved(s: cell.link!))
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func upvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.getId())!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!)
            cell.refresh()
            cell.refreshTitle()
        } catch {

        }
    }

    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.getId())!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!)
            cell.refresh()
            cell.refreshTitle()
        } catch {

        }
    }

    func hide(_ cell: LinkCellView) {
        do {
            try session?.setHide(true, name: cell.link!.getId(), completion: { (_) in })
            let id = cell.link!.getId()
            var location = 0
            var item = links[0]
            for submission in links {
                if submission.getId() == id {
                    item = links[location]
                    print("Removing link")
                    links.remove(at: location)
                    break
                }
                location += 1
            }

            self.flowLayout.reset()

            tableView.performBatchUpdates({
                self.tableView.deleteItems(at: [IndexPath.init(item: location, section: 0)])
                BannerUtil.makeBanner(text: "Submission hidden forever!\nTap to undo", color: GMColor.red500Color(), seconds: 4, context: self, callback: {
                    self.links.insert(item, at: location)
                    self.tableView.insertItems(at: [IndexPath.init(item: location, section: 0)])
                    do {
                        try self.session?.setHide(true, name: cell.link!.getId(), completion: { (_) in })
                    } catch {

                    }
                })
            }, completion: nil)

        } catch {

        }
    }

    func more(_ cell: LinkCellView) {
        PostActions.showMoreMenu(cell: cell, parent: self, nav: self.navigationController!, mutableList: true, delegate: self)
    }

    func mod(_ cell: LinkCellView) {
        PostActions.showModMenu(cell, parent: self)
    }

    func showFilterMenu(_ cell: LinkCellView) {
        let link = cell.link!
        let actionSheetController: UIAlertController = UIAlertController(title: "What would you like to filter?", message: "", preferredStyle: .alert)

        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Posts by u/\(link.author)", style: .default) { _ -> Void in
            PostFilter.profiles.append(link.author as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil, baseSubreddit: self.sub)
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Posts from r/\(link.subreddit)", style: .default) { _ -> Void in
            PostFilter.subreddits.append(link.subreddit as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil, baseSubreddit: self.sub)
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Posts linking to \(link.domain)", style: .default) { _ -> Void in
            PostFilter.domains.append(link.domain as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil, baseSubreddit: self.sub)
            self.reloadDataReset()
        }
        actionSheetController.addAction(cancelActionButton)

        //todo make this work on ipad
        self.present(actionSheetController, animated: true, completion: nil)

    }
}

extension SingleSubredditViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == panGesture {
            if !SettingValues.submissionGesturesEnabled {
                return false
            }
            
            if SettingValues.submissionActionLeft == .NONE && SettingValues.submissionActionRight == .NONE {
                return false
            }
        }
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Limit angle of pan gesture recognizer to avoid interfering with scrolling
        if gestureRecognizer == panGesture {
            if !SettingValues.submissionGesturesEnabled {
                return false
            }
            
            if SettingValues.submissionActionLeft == .NONE && SettingValues.submissionActionRight == .NONE {
                return false
            }
        }
        
        if let recognizer = gestureRecognizer as? UIPanGestureRecognizer, recognizer == panGesture {
            return recognizer.shouldRecognizeForDirection(.horizontal, withAngleToleranceInDegrees: 45)
        }

        return true
    }
    
    func panCell(_ recognizer: UIPanGestureRecognizer) {
        
        if recognizer.view != nil {
            let velocity = recognizer.velocity(in: recognizer.view!).x
            if (velocity > 0 && SettingValues.submissionActionLeft == .NONE) || (velocity < 0 && SettingValues.submissionActionRight == .NONE) {
                return
            }
        }
        if recognizer.state == .began || translatingCell == nil {
            let point = recognizer.location(in: self.tableView)
            let indexpath = self.tableView.indexPathForItem(at: point)
            if indexpath == nil {
                return
            }
            
            guard let cell = self.tableView.cellForItem(at: indexpath!) as? LinkCellView else {
                return
            }
            translatingCell = cell
        }
        translatingCell?.handlePan(recognizer)
        if recognizer.state == .ended {
            translatingCell = nil
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
        
        loader.heightAnchor == 60
        loader.widthAnchor == 60
        loader.topAnchor == self.contentView.topAnchor + 10
        loader.bottomAnchor == self.contentView.bottomAnchor - 10
        loader.centerXAnchor == self.contentView.centerXAnchor
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
        
        title.heightAnchor == 60
        title.horizontalAnchors == self.contentView.horizontalAnchors
        title.topAnchor == self.contentView.topAnchor + 10
        title.bottomAnchor == self.contentView.bottomAnchor - 10
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        title.textAlignment = .center
        
        time.heightAnchor == 60
        time.leftAnchor == self.contentView.leftAnchor
        time.topAnchor == self.contentView.topAnchor + 10
        time.bottomAnchor == self.contentView.bottomAnchor - 10
        time.numberOfLines = 0
        time.widthAnchor == 70
        time.lineBreakMode = .byWordWrapping
        time.textAlignment = .center
    }
}
