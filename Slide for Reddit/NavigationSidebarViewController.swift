//
//  ViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/6/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import reddift
import reddift
import SDWebImage
import UIKit

import UIKit.UIGestureRecognizerSubclass

class NavigationSidebarViewController: UIViewController, UIGestureRecognizerDelegate {
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var filteredContent: [String] = []
    var suggestions = [String]()
    var parentController: MainViewController?
    var backgroundView = UIView()
    var topView: UIView?
    var bottomOffset: CGFloat = 64
    var muxColor = ColorUtil.foregroundColor
    var lastY: CGFloat = 0.0
    var timer: Timer?

    var header: NavigationHeaderView = NavigationHeaderView()

    var searchBar: UISearchBar?
    var isSearching = false

    var task: URLSessionDataTask?
    
    init(controller: MainViewController) {
        self.parentController = controller
        super.init(nibName: nil, bundle: nil)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            if UIScreen.main.bounds.height >= 812 {
                bottomOffset = 84
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = UITouchCapturingView()

        configureViews()
        configureLayout()
        configureGestures()
        
        configureBackground()
        
        self.header.account.isUserInteractionEnabled = false
        self.header.inbox.isUserInteractionEnabled = false
        self.header.mod.isUserInteractionEnabled = false
        self.header.settings.isUserInteractionEnabled = false
        self.header.title.isUserInteractionEnabled = false
    }
    
    struct Callbacks {
        var didBeginPanning: (() -> Void)?
        var didCollapse: (() -> Void)?
    }
    var callbacks = Callbacks()
    
    var gestureRecognizer: UIPanGestureRecognizer!
    var lastPercentY = CGFloat(0)
    
    // MARK: User interaction
    @objc func viewPanned(sender: UIPanGestureRecognizer) {
        sender.view?.endEditing(true)
        let velocity = sender.velocity(in: sender.view).y
        
        switch sender.state {
        case .began:
            lastPercentY = CGFloat(0)
            callbacks.didBeginPanning?()
            if let navVC = parentController!.navigationController {
                navVC.view.addSubviews(backgroundView, self.view)
                navVC.view.bringSubview(toFront: backgroundView)
                backgroundView.edgeAnchors == navVC.view.edgeAnchors
                navVC.view.bringSubview(toFront: self.view)
            } else {
                NSLog("Warning: No parentController!.navigationController. Background behind drawer probably won't show up.")
            }
        case .changed:
            update(sender)
        case .ended:
            let percentComplete = percentCompleteForTranslation(sender)
            if (velocity < 0 ? percentComplete : 1 - percentComplete) > 0.25 || abs(velocity) > 350 {
                if velocity < 0 {
                    expand()
                } else {
                    collapse()
                }
            } else {
                if velocity > 0 {
                    expand()
                } else {
                    collapse()
                }
            }
        case .cancelled:
            collapse()
        default:
            return
        }

    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return tableView.contentOffset.y == 0 && !self.view.isHidden
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer is UIPanGestureRecognizer && (tableView.contentOffset.y == 0) && !self.view.isHidden
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !self.view.isHidden && (gestureRecognizer is UIPanGestureRecognizer && (gestureRecognizer as! UIPanGestureRecognizer).velocity(in: self.view).y < 0 && topView?.alpha ?? 1 == 0) ? false : true
    }
    
    func update(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        let y = self.view.frame.minY
        self.view.frame = CGRect(x: 0, y: max(y + translation.y, UIScreen.main.bounds.height - self.view.frame.height), width: view.frame.width, height: view.frame.height)
        recognizer.setTranslation(CGPoint.zero, in: self.view)
        
        let percentMoved = percentCompleteForTranslation(recognizer)
        let normalizedPercentBar = min(1, percentMoved * 5)
        let normalizedAlphaBar = percentMoved < 0.5 ? 0 : ((percentMoved - 0.5) * 5)
        
        if percentMoved < 0.01 {
            UIView.animate(withDuration: 0.1) {
                self.topView?.backgroundColor = self.muxColor
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.topView?.backgroundColor = self.header.back.backgroundColor
            }
        }

        backgroundView.alpha = percentMoved
        topView?.alpha = 1 - normalizedAlphaBar
        topView?.layer.cornerRadius = SettingValues.flatMode ? 0 : max(15, 30 * normalizedPercentBar)
    }
    
    private func percentCompleteForTranslation(_ recognizer: UIPanGestureRecognizer) -> CGFloat {
        let percent = (UIScreen.main.bounds.height - self.view.frame.maxY - bottomOffset) / (self.view.frame.size.height - bottomOffset) * -1
        return 1 - percent
    }
    
    func collapse() {
        self.header.account.isUserInteractionEnabled = false
        self.header.inbox.isUserInteractionEnabled = false
        self.header.mod.isUserInteractionEnabled = false
        self.header.settings.isUserInteractionEnabled = false
        self.header.title.isUserInteractionEnabled = false

        let y = UIScreen.main.bounds.height - bottomOffset
        if let parent = self.parentController, parent.menu.superview != nil {
            parent.menu.deactivateImmediateConstraints()
            parent.menu.topAnchor == parent.toolbar!.topAnchor
            parent.menu.widthAnchor == 56
            parent.menu.heightAnchor == 56
            parent.menu.leftAnchor == parent.toolbar!.leftAnchor
            
            parent.more.deactivateImmediateConstraints()
            parent.more.topAnchor == parent.toolbar!.topAnchor
            parent.more.widthAnchor == 56
            parent.more.heightAnchor == 56
            parent.more.rightAnchor == parent.toolbar!.rightAnchor
        }
        let animateBlock = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.backgroundView.alpha = 0
            strongSelf.topView?.alpha = 1
            strongSelf.view.frame = CGRect(x: 0, y: y, width: strongSelf.view.frame.width, height: strongSelf.view.frame.height)
            strongSelf.topView?.backgroundColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.theme.isLight() ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))
            strongSelf.topView?.layer.cornerRadius = SettingValues.flatMode ? 0 : 15
            strongSelf.parentController?.menu.transform = CGAffineTransform(scaleX: 1, y: 1)
            strongSelf.parentController?.more.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        self.callbacks.didCollapse?()
        self.view.endEditing(true)
        
        let completionBlock: (Bool) -> Void = { [weak self] finished in
            guard let strongSelf = self else { return }
            strongSelf.topView?.layer.cornerRadius = SettingValues.flatMode ? 0 : 15
        }

        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.45,
                       options: .curveEaseInOut,
                       animations: animateBlock,
                       completion: completionBlock)
    }
    
    func doRotate(_ animated: Bool = false) {
        let y = UIScreen.main.bounds.height - bottomOffset
        self.view.frame = CGRect(x: 0, y: self.view.frame.height, width: parentController?.view.frame.width ?? self.view.frame.size.width, height: (self.parentController?.view.frame.size.height ?? self.view.frame.size.height) * 0.9)
        if animated {
            let animateBlock = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.backgroundView.alpha = 0
                strongSelf.topView?.alpha = 1
                strongSelf.view.frame = CGRect(x: 0, y: y, width: strongSelf.parentController?.view.frame.width ?? strongSelf.view.frame.size.width, height: (strongSelf.parentController?.view.frame.size.height ?? strongSelf.view.frame.size.height) * 0.9)
                strongSelf.topView?.backgroundColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.theme.isLight() ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))
                strongSelf.topView?.layer.cornerRadius = SettingValues.flatMode ? 0 : 15
            }
            
            self.callbacks.didCollapse?()
            self.view.endEditing(true)
            
            let completionBlock: (Bool) -> Void = { [weak self] finished in
                guard let strongSelf = self else { return }
                strongSelf.topView?.layer.cornerRadius = SettingValues.flatMode ? 0 : 15
            }
            
            UIView.animate(withDuration: 0.4,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.45,
                           options: .curveEaseInOut,
                           animations: animateBlock,
                           completion: completionBlock)
        } else {
            self.backgroundView.alpha = 0
            self.topView?.alpha = 1
            self.view.frame = CGRect(x: 0, y: y, width: parentController?.view.frame.width ?? self.view.frame.size.width, height: (self.parentController?.view.frame.size.height ?? self.view.frame.size.height) * 0.9)
            self.topView?.backgroundColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.theme.isLight() ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))
            self.topView?.layer.cornerRadius = SettingValues.flatMode ? 0 : 15
        }
    }
    
    func expand() {
        if self.view.isHidden {
            return
        }

        if let navVC = parentController!.navigationController {
            navVC.view.addSubviews(backgroundView, self.view)
            navVC.view.bringSubview(toFront: backgroundView)
            backgroundView.edgeAnchors == navVC.view.edgeAnchors
            navVC.view.bringSubview(toFront: self.view)
        } else {
            NSLog("Warning: No parentController!.navigationController. Background behind drawer probably won't show up.")
        }

        let y = UIScreen.main.bounds.height - self.view.frame.size.height
        if let parent = self.parentController, parent.menu.superview != nil {
            parent.menu.deactivateImmediateConstraints()
            parent.menu.topAnchor == parent.toolbar!.topAnchor
            parent.menu.widthAnchor == 56
            parent.menu.heightAnchor == 56
            parent.menu.leftAnchor == parent.toolbar!.leftAnchor
            
            parent.more.deactivateImmediateConstraints()
            parent.more.topAnchor == parent.toolbar!.topAnchor
            parent.more.widthAnchor == 56
            parent.more.heightAnchor == 56
            parent.more.rightAnchor == parent.toolbar!.rightAnchor
        }
        let animateBlock = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.backgroundView.alpha = 1
            strongSelf.topView?.alpha = 0
            strongSelf.view.frame = CGRect(x: 0, y: y, width: strongSelf.view.frame.width, height: strongSelf.view.frame.height)
            strongSelf.topView?.backgroundColor = strongSelf.header.back.backgroundColor
            strongSelf.parentController?.menu.transform = CGAffineTransform(scaleX: 1, y: 1)
            strongSelf.parentController?.more.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        let completionBlock: (Bool) -> Void = { [weak self] finished in
            guard let strongSelf = self else { return }
            if SettingValues.autoKeyboard {
                strongSelf.header.search.becomeFirstResponder()
            }
            strongSelf.header.title.isUserInteractionEnabled = true
            strongSelf.header.account.isUserInteractionEnabled = true
            strongSelf.header.inbox.isUserInteractionEnabled = true
            strongSelf.header.mod.isUserInteractionEnabled = true
            strongSelf.header.settings.isUserInteractionEnabled = true
        }

        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.45,
                       options: .curveEaseInOut,
                       animations: animateBlock,
                       completion: completionBlock)
    }
    
    func configureBackground() {
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        
        if #available(iOS 11, *) {
            let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
            let blurView = UIVisualEffectView(frame: backgroundView.frame)
            blurEffect.setValue(3, forKeyPath: "blurRadius")
            blurView.effect = blurEffect
            backgroundView.insertSubview(blurView, at: 0)
            blurView.horizontalAnchors == backgroundView.horizontalAnchors
            blurView.verticalAnchors == backgroundView.verticalAnchors
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(collapse))
        backgroundView.addGestureRecognizer(tapGesture)
        
        parentController!.view.addSubview(backgroundView)
        backgroundView.edgeAnchors == parentController!.view.edgeAnchors

        backgroundView.alpha = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update any things that can change due to user settings here
        tableView.backgroundColor = ColorUtil.foregroundColor
        tableView.separatorColor = ColorUtil.backgroundColor
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        collapse()
        completion?()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if SettingValues.autoKeyboard {
            header.search.becomeFirstResponder()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !SettingValues.flatMode {
            header.roundCorners([.topLeft, .topRight], radius: 30)
        }
    }

    func configureViews() {

        header.frame.size.height = header.getEstHeight()
        header.parentController = self.parentController
        view.addSubview(header)

        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView.clipsToBounds = true
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorInset = .zero

        tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "search")
        tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "profile")

        view.addSubview(tableView)

        searchBar = header.search
        searchBar?.searchBarStyle = UISearchBarStyle.minimal
        searchBar?.placeholder = " Go to subreddit or profile"
        searchBar?.sizeToFit()
        searchBar?.isTranslucent = true
        searchBar?.barStyle = .blackTranslucent
        searchBar?.delegate = self
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        self.header.doColors(MainViewController.current)
    }

    func configureLayout() {
        header.topAnchor == view.topAnchor
        header.heightAnchor == header.getEstHeight()
        header.horizontalAnchors == view.horizontalAnchors

        tableView.topAnchor == header.bottomAnchor
        tableView.horizontalAnchors == view.horizontalAnchors
        tableView.bottomAnchor == view.bottomAnchor
    }

    func configureGestures() {
        gestureRecognizer = UIPanGestureRecognizer()
        view.addGestureRecognizer(gestureRecognizer)
        
        gestureRecognizer.delegate = self
        gestureRecognizer.addTarget(self, action: #selector(viewPanned(sender:)))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setViewController(controller: MainViewController) {
        parentController = controller
    }

    func setMod(_ hasMail: Bool) {
        header.setIsMod(hasMail)
    }

    func setColors(_ sub: String) {
        DispatchQueue.main.async {
            self.header.doColors(sub)
            self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
    }
    
    func setSubreddit(subreddit: String) {
        header.setSubreddit(subreddit: subreddit, parent: self)
        header.frame.size.height = header.getEstHeight()
        tableView.backgroundColor = ColorUtil.backgroundColor
    }
    
    func setmail(mailcount: Int) {
        header.setMail(mailcount)
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
}

extension NavigationSidebarViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! SubredditCellView
        if !cell.profile.isEmpty() {
            let user = cell.profile
            parentController?.goToUser(profile: user)
        } else if !cell.search.isEmpty() {
            VCPresenter.showVC(viewController: SearchViewController(subreddit: cell.subreddit, searchFor: cell.search), popupIfPossible: false, parentNavigationController: parentController?.navigationController, parentViewController: parentController)
        } else {
            let sub = cell.subreddit
            parentController?.goToSubreddit(subreddit: sub)
        }
        searchBar?.text = ""
        filteredContent = []
        isSearching = false
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return suggestions.count > 0 ? 2 : 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if isSearching {
                return filteredContent.count + (filteredContent.contains(searchBar!.text!) ? 0 : 1) + 3
            } else {
                return Subscriptions.subreddits.count
            }
        } else {
            return suggestions.count
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 40
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.fontColor
        label.font = FontGenerator.boldFontOfSize(size: 14, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor

        switch section {
        case 0: label.text  = ""
        default: label.text  = "SUBREDDIT SUGGESTIONS"
        }
        return toReturn
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SubredditCellView
        if indexPath.section == 0 {
            if indexPath.row == filteredContent.count && isSearching {
                let thing = searchBar!.text!
                let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                c.setSubreddit(subreddit: thing, nav: self, exists: false)
                cell = c
            } else if isSearching && indexPath.row == filteredContent.count + 1 {
                let thing = searchBar!.text!
                let c = tableView.dequeueReusableCell(withIdentifier: "profile", for: indexPath) as! SubredditCellView
                c.setProfile(profile: thing, nav: self)
                cell = c
            } else if isSearching && indexPath.row == filteredContent.count + 2 {
                // "Search Reddit for <text>" cell
                let thing = searchBar!.text!
                let c = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as! SubredditCellView
                c.setSearch(string: thing, sub: nil, nav: self)
                cell = c
            } else if isSearching && indexPath.row == filteredContent.count + 3 {
                // "Search r/subreddit for <text>" cell
                let thing = searchBar!.text!
                let c = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as! SubredditCellView
                c.setSearch(string: thing, sub: MainViewController.current, nav: self)
                cell = c
            } else {
                var thing = ""
                if isSearching {
                    thing = filteredContent[indexPath.row]
                } else {
                    thing = Subscriptions.subreddits[indexPath.row]
                }
                let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                c.setSubreddit(subreddit: thing, nav: self, exists: true)
                cell = c
            }
        } else {
            let thing = suggestions[indexPath.row]
            let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
            c.setSubreddit(subreddit: thing, nav: self, exists: false)
            cell = c
        }

        cell.backgroundColor = ColorUtil.foregroundColor

        return cell
    }
}

extension NavigationSidebarViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String) {
        timer?.invalidate()
        filteredContent = []
        suggestions = []
        if textSearched.length != 0 {
            isSearching = true
            searchTableList()
        } else {
            isSearching = false
        }
        
        tableView.reloadData()
        if searchBar.text!.count >= 2 {
            timer = Timer.scheduledTimer(timeInterval: 0.35,
                                         target: self,
                                         selector: #selector(self.getSuggestions),
                                         userInfo: nil,
                                         repeats: false)
        }

        if textSearched == "uuddlrlrba" {
            UIColor.💀()
        }
    }

    func getSuggestions() {
        if task != nil {
            task?.cancel()
        }
        do {
            task = try! (UIApplication.shared.delegate as? AppDelegate)?.session?.getSubredditSearch(searchBar?.text ?? "", paginator: Paginator(), completion: { (result) in
                switch result {
                case .success(let subs):
                    for sub in subs.children {
                        self.suggestions.append((sub as! Subreddit).displayName)
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print(error)
                }
            })
        }
    }

    func searchTableList() {
        var searchItems = [String]()
        let searchString = searchBar?.text
        for s in Subscriptions.subreddits {
            if s.localizedCaseInsensitiveContains(searchString ?? "") {
                searchItems.append(s)
            }
        }

        if searchString != nil && !(searchString?.isEmpty())! {
            for s in Subscriptions.historySubs {
                if s.localizedCaseInsensitiveContains(searchString!) && !searchItems.contains(s) {
                    searchItems.append(s)
                }
            }
        }

        for item in searchItems {
            if item.startsWith(searchString!) {
                filteredContent.append(item)
            }
        }
        for item in searchItems {
            if !item.startsWith(searchString!) {
                filteredContent.append(item)
            }
        }
    }

}

extension NavigationSidebarViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentY = scrollView.contentOffset.y
        if self.searchBar?.text?.isEmpty() ?? false {
            self.tableView.endEditing(true)
            header.search.resignFirstResponder()
        }
        let currentBottomY = scrollView.frame.size.height + currentY
        if currentY > lastY {
            tableView.bounces = true
        } else {
            if currentBottomY < scrollView.contentSize.height + scrollView.contentInset.bottom {
                tableView.bounces = false
            }
        }
        lastY = scrollView.contentOffset.y
    }
}

class UITouchCapturingView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isHidden || alpha == 0 {
            return nil
        }

        for subview in subviews.reversed() {
            let subPoint = subview.convert(point, from: self)
            if let result = subview.hitTest(subPoint, with: event) {
                return result
            }
        }
        
        return nil
    }
}
