//
//  MainViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/4/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import MaterialComponents.MDCTabBar
import MKColorPicker
import reddift
import RLBAlertsPickers
import SDCAlertView
import UIKit

class ProfileViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, ColorPickerViewDelegate, UIScrollViewDelegate {
    var content: [UserContent] = []
    var name: String = ""
    var isReload = false
    var session: Session?
    var vCs: [UIViewController] = []
    var openTo = 0
    var newColor = UIColor.white
    var friends = false

    public func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        newColor = colorPickerView.colors[indexPath.row]
        self.navigationController?.navigationBar.barTintColor = SettingValues.reduceColor ? ColorUtil.theme.backgroundColor : colorPickerView.colors[indexPath.row]
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }

    func pickColor(sender: AnyObject) {
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let margin: CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 314 - margin * 4.0: alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColor()
        MKColorPicker.selectionStyle = .check
        MKColorPicker.scrollDirection = .vertical

        MKColorPicker.style = .circle

        alertController.view.addSubview(MKColorPicker)
        
        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: {(_: UIAlertAction!) in
            ColorUtil.setColorForUser(name: self.name, color: self.newColor)
        })
        
        alertController.addAction(somethingAction)
        alertController.addCancelButton()
        
        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = (moreB!.value(forKey: "view") as! UIView)
            presenter.sourceRect = (moreB!.value(forKey: "view") as! UIView).bounds
        }

        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = sender as! UIButton
            presenter.sourceRect = (sender as! UIButton).bounds
        }

        present(alertController, animated: true, completion: nil)
    }

    var tagText: String?

    func tagUser() {
        let alert = DragDownAlertMenu(title: AccountController.formatUsername(input: name, small: true), subtitle: "Tag profile", icon: nil, full: true)
        
        alert.addTextInput(title: "Set tag", icon: UIImage(named: "save-1")?.menuIcon(), action: {
            ColorUtil.setTagForUser(name: self.name, tag: alert.getText() ?? "")
        }, inputPlaceholder: "Enter a tag...", inputValue: ColorUtil.getTagForUser(name: name), inputIcon: UIImage(sfString: SFSymbol.tagFill, overrideString: "subs")!.menuIcon(), textRequired: true, exitOnAction: true)

        if !(ColorUtil.getTagForUser(name: name) ?? "").isEmpty {
            alert.addAction(title: "Remove tag", icon: UIImage(named: "delete")?.menuIcon(), enabled: true) {
                ColorUtil.removeTagForUser(name: self.name)
            }
        }
        
        alert.show(self)
    }

    init(name: String) {
        self.name = name
        self.session = (UIApplication.shared.delegate as! AppDelegate).session
        if let n = (session?.token.flatMap { (token) -> String? in
            return token.name
            }) as String? {
            if name == n {
                friends = true
                self.content = [.overview, .submitted, .comments, .liked, .saved, .disliked, .hidden, .gilded]
            } else {
                self.content = ProfileViewController.doDefault()
            }
        } else {
            self.content = ProfileViewController.doDefault()
        }
        
        if friends {
            self.vCs.append(ContentListingViewController.init(dataSource: FriendsContributionLoader.init()))
        }
        
        for place in content {
            self.vCs.append(ContentListingViewController.init(dataSource: ProfileContributionLoader.init(name: name, whereContent: place)))
        }
        
        tabBar = MDCTabBar()
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage(named: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControl.Event.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        sortB = UIBarButtonItem.init(customView: sort)
        
        let more = UIButton.init(type: .custom)
        more.setImage(UIImage(named: "info")?.navIcon(), for: UIControl.State.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControl.Event.touchUpInside)
        more.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        moreB = UIBarButtonItem.init(customView: more)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func doDefault() -> [UserContent] {
        return [UserContent.overview, UserContent.comments, UserContent.submitted, UserContent.gilded]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    var moreB: UIBarButtonItem?
    var sortB: UIBarButtonItem?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = AccountController.formatUsername(input: name, small: true)
        navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        if navigationController != nil {
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "", true)
            navigationController?.navigationBar.tintColor = SettingValues.reduceColor ? ColorUtil.theme.fontColor : UIColor.white
        }
        
        if navigationController != nil {
            self.navigationController?.navigationBar.shadowImage = UIImage()
        }
    }
    
    func showMenu(sender: AnyObject, user: Account) {
        let date = Date(timeIntervalSince1970: TimeInterval(user.createdUtc))
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy"
        let alrController = UIAlertController(title: "", message: "\(user.linkKarma) post karma\n\(user.commentKarma) comment karma\nRedditor since \(df.string(from: date))", preferredStyle: UIAlertController.Style.actionSheet)
        
        let margin: CGFloat = 8.0
        let rect = CGRect.init(x: margin, y: margin + 23, width: alrController.view.bounds.size.width - margin * 4.0, height: 75)
        let scrollView = UIScrollView(frame: rect)
        scrollView.backgroundColor = UIColor.clear
        
        //todo add trophies
        do {
            try session?.getTrophies(user.name, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                    alrController.title = ""
                case .success(let trophies):
                    var i = 0
                    DispatchQueue.main.async {
                        for trophy in trophies {
                            let b = self.generateButtons(trophy: trophy)
                            b.frame = CGRect.init(x: i * 75, y: 0, width: 70, height: 70)
                            b.addTapGestureRecognizer(action: {
                                if trophy.url != nil {
                                    self.dismiss(animated: true)
                                    VCPresenter.showVC(viewController: WebsiteViewController(url: trophy.url!, subreddit: ""), popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
                                }
                            })
                            scrollView.addSubview(b)
                            i += 1
                        }
                        scrollView.contentSize = CGSize.init(width: i * 75, height: 70)
                        if trophies.count == 0 {
                            alrController.title = ""
                        } else {
                            alrController.title = "\n\n\n\n\n"
                        }
                    }
                }
            })
        } catch {
            
        }
        scrollView.delaysContentTouches = false
    
        alrController.view.addSubview(scrollView)
        if AccountController.isLoggedIn {
            alrController.addAction(UIAlertAction.init(title: "Private message", style: .default, handler: { (_) in
                VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(name: user.name, completion: { (_) in })), parentVC: self)
            }))
            if user.isFriend {
                alrController.addAction(UIAlertAction.init(title: "Unfriend", style: .default, handler: { (_) in
                    do {
                        try self.session?.unfriend(user.name, completion: { (_) in
                            DispatchQueue.main.async {
                                BannerUtil.makeBanner(text: "Unfriended u/\(user.name)", seconds: 3, context: self)
                            }
                        })
                    } catch {
                        
                    }
                }))
            } else {
                alrController.addAction(UIAlertAction.init(title: "Friend", style: .default, handler: { (_) in
                    do {
                        try self.session?.friend(user.name, completion: { (result) in
                            if result.error != nil {
                                print(result.error!)
                            }
                            DispatchQueue.main.async {
                                BannerUtil.makeBanner(text: "Friended u/\(user.name)", seconds: 3, context: self)
                            }
                        })
                    } catch {
                        
                    }
                }))
            }
        }
        alrController.addAction(UIAlertAction.init(title: "Change color", style: .default, handler: { (_) in
            self.pickColor(sender: sender)
        }))
        let tag = ColorUtil.getTagForUser(name: name)
        alrController.addAction(UIAlertAction.init(title: "Tag user\((tag != nil) ? " (currently \(tag!))" : "")", style: .default, handler: { (_) in
            self.tagUser()
        }))
        
        alrController.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: { (_) in
        }))

        alrController.modalPresentationStyle = .popover
        if let presenter = alrController.popoverPresentationController {
            presenter.sourceView = (moreB!.value(forKey: "view") as! UIView)
            presenter.sourceRect = (moreB!.value(forKey: "view") as! UIView).bounds
        }

        alrController.modalPresentationStyle = .popover
        if let presenter = alrController.popoverPresentationController {
            presenter.sourceView = sender as! UIButton
            presenter.sourceRect = (sender as! UIButton).bounds
        }
        
        self.present(alrController, animated: true, completion: {})
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setupBaseBarColors()
    }
    
    func generateButtons(trophy: Trophy) -> UIImageView {
        let more = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 70, height: 70))
        more.sd_setImage(with: trophy.icon70!)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.trophyTapped(_:)))
        singleTap.numberOfTapsRequired = 1
        
        more.isUserInteractionEnabled = true
        more.addGestureRecognizer(singleTap)
        
        return more
    }

    @objc func trophyTapped(_ sender: AnyObject) {
    }
    
    func close() {
        navigationController?.popViewController(animated: true)
    }
    
    var tabBar: MDCTabBar

    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = navigationController {
            if navigationController.viewControllers.count == 1 {
                navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Close", style: .done, target: self, action: #selector(closeButtonPressed))
            }
        }

        view.backgroundColor = ColorUtil.theme.backgroundColor
        var items: [String] = []
        if friends {
            items.append("FRIENDS")
        }
        for i in content {
            items.append(i.title)
        }

        tabBar = MDCTabBar.init(frame: CGRect.zero)
        tabBar.itemAppearance = .titles
        tabBar.items = items.enumerated().map { index, source in
            return UITabBarItem(title: source, image: nil, tag: index)
        }
        
        tabBar.backgroundColor = ColorUtil.getColorForSub(sub: "", true)
        tabBar.selectedItemTintColor = (SettingValues.reduceColor ? ColorUtil.theme.fontColor : UIColor.white)
        tabBar.unselectedItemTintColor = (SettingValues.reduceColor ? ColorUtil.theme.fontColor : UIColor.white).withAlphaComponent(0.45)

        if friends {
            openTo += 1
        }
        currentIndex = openTo
        
        tabBar.selectedItem = tabBar.items[openTo]
        tabBar.delegate = self
        tabBar.inkColor = UIColor.clear
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: "NONE")
        
        self.view.addSubview(tabBar)
        tabBar.heightAnchor == 48

        tabBar.horizontalAnchors == self.view.horizontalAnchors
        
        self.edgesForExtendedLayout = UIRectEdge.all
        
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        
        var isModal13 = false
        if #available(iOS 13, *), (self.navigationController?.viewControllers[0] == self) {
            isModal13 = true
        }
        tabBar.topAnchor == self.view.topAnchor + (self.navigationController?.navigationBar.frame.size.height ?? 64) + (isModal13 ? 0 : UIApplication.shared.statusBarFrame.height)
        tabBar.sizeToFit()
        
        self.dataSource = self
        self.delegate = self
        
        self.navigationController?.view.backgroundColor = UIColor.clear
        let firstViewController = vCs[openTo]
        for view in view.subviews {
            if view is UIScrollView {
                (view as! UIScrollView).delegate = self

                break
            }
        }

        if self.navigationController?.interactivePopGestureRecognizer != nil {
            for view in view.subviews {
                if let scrollView = view as? UIScrollView {
                    scrollView.panGestureRecognizer.require(toFail: self.navigationController!.interactivePopGestureRecognizer!)
                    scrollView.delegate = self
                }
            }
        }

        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: true,
                           completion: nil)
        
        self.currentVc = vCs[openTo]
        let current = content[openTo]
        if current == .comments || current == .submitted || current == .overview {
            navigationItem.rightBarButtonItems = [ moreB!, sortB!]
        } else {
            navigationItem.rightBarButtonItems = [ moreB!]
        }
    }

    var currentVc = UIViewController()
    
    @objc func showSortMenu(_ sender: UIButton?) {
        (self.currentVc as? ContentListingViewController)?.showSortMenu(sender)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = vCs.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard vCs.count > previousIndex else {
            return nil
        }
        
        return vCs[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = vCs.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = vCs.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return vCs[nextIndex]
    }

    @objc func showMenu(_ sender: AnyObject) {
        do {
            try session?.getUserProfile(self.name, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let account):
                    self.showMenu(sender: sender, user: account)
                }
            })
        } catch {
            
        }
    }
    var selected = false
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        let page = vCs.index(of: self.viewControllers!.first!)

        tabBar.setSelectedItem(tabBar.items[page! ], animated: true)
        currentVc = self.viewControllers!.first!
        currentIndex = page!
        
        let contentIndex = page! - (friends ? 1 : 0)
        if contentIndex >= 0 {
            let current = content[contentIndex]
            if current == .comments || current == .submitted || current == .overview {
                navigationItem.rightBarButtonItems = [ moreB!, sortB!]
            } else {
                navigationItem.rightBarButtonItems = [ moreB!]
            }
        } else {
            navigationItem.rightBarButtonItems = [ moreB!]
        }
    }

    var currentIndex = 0
    var lastPosition: CGFloat = 0

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.lastPosition = scrollView.contentOffset.x
        
        if currentIndex == 0 && scrollView.contentOffset.x < scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndex == vCs.count - 1 && scrollView.contentOffset.x > scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }

    }
    
    //From https://stackoverflow.com/a/25167681/3697225
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if currentIndex == 0 && scrollView.contentOffset.x <= scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndex == vCs.count - 1 && scrollView.contentOffset.x >= scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }

}
extension ProfileViewController: MDCTabBarDelegate {
    
    func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
        selected = true
        let firstViewController = vCs[tabBar.items.index(of: item)!]
        currentIndex = tabBar.items.index(of: item)!
        currentVc = firstViewController
        
        let contentIndex = currentIndex - (friends ? 1 : 0)
        if contentIndex >= 0 {
            let current = content[contentIndex]
            if current == .comments || current == .overview || current == .submitted {
                navigationItem.rightBarButtonItems = [ moreB!, sortB!]
            } else {
                navigationItem.rightBarButtonItems = [ moreB!]
            }
        }
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: false,
                           completion: nil)
        
    }
    
}

// MARK: - Actions
extension ProfileViewController {
    @objc func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
}
