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
    var alphabetical = true
    var subs = Subscriptions.subreddits
    var subsAlphabetical: [String: [String]] = [:]
    var sectionTitles = [String]()
    
    var expanded = false

    var isSearching = false

    var task: URLSessionDataTask?

    // Guaranteed amount of space between top edge of menu and top edge of screen
    let minTopOffset: CGFloat = 42

    var searchBar = UISearchBar().then {
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.spellCheckingType = .no
        $0.returnKeyType = .search
        if ColorUtil.theme != .LIGHT {
            $0.keyboardAppearance = .dark
        }
        $0.searchBarStyle = UISearchBar.Style.minimal
        $0.placeholder = " Search subs, posts, or profiles"
        $0.isTranslucent = true
        $0.barStyle = .blackTranslucent
    }

    //let horizontalSubGroup = HorizontalSubredditGroup()
    
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
    
    func loadSections() {
        subsAlphabetical.removeAll()
        sectionTitles.removeAll()
        for string in Subscriptions.pinned {
            var current = subsAlphabetical["★"] ?? [String]()
            current.append(string)
            print(current)
            print(Subscriptions.pinned)
            subsAlphabetical["★"] = current
        }
        
        for string in subs.filter({ !Subscriptions.pinned.contains($0) }).sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending }) {
            let letter = string.substring(0, length: 1).uppercased()
            var current = subsAlphabetical[letter] ?? [String]()
            current.append(string)
            subsAlphabetical[letter] = current
        }
        
        sectionTitles = subsAlphabetical.keys.sorted { $0.caseInsensitiveCompare($1) == .orderedAscending }
        if sectionTitles.contains("★") {
            sectionTitles.remove(at: sectionTitles.count - 1)
            sectionTitles.insert("★", at: 0)
        }
    }
    
    override func viewDidLoad() {
        tableView.sectionIndexColor = ColorUtil.baseAccent
        loadSections()
        super.viewDidLoad()
        self.view = UITouchCapturingView()

        configureViews()
        configureLayout()
        configureGestures()
        
        configureBackground()

        searchBar.isUserInteractionEnabled = true

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeShown),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
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
            backgroundView.isHidden = false
            lastPercentY = CGFloat(0)
            callbacks.didBeginPanning?()
            if let navVC = parentController!.navigationController {
                navVC.view.addSubviews(backgroundView, self.view)
                navVC.view.bringSubviewToFront(backgroundView)
                backgroundView.edgeAnchors == navVC.view.edgeAnchors
                navVC.view.bringSubviewToFront(self.view)
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

        backgroundView.alpha = percentMoved
        topView?.alpha = 1 - normalizedAlphaBar
        topView?.layer.cornerRadius = SettingValues.flatMode ? 0 : max(15, 30 * normalizedPercentBar)
    }
    
    private func percentCompleteForTranslation(_ recognizer: UIPanGestureRecognizer) -> CGFloat {
        let percent = (UIScreen.main.bounds.height - self.view.frame.maxY - bottomOffset) / (self.view.frame.size.height - bottomOffset) * -1
        return 1 - percent
    }
    
    @objc func collapse() {

        searchBar.isUserInteractionEnabled = true

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
        
        self.view.endEditing(true)
        
        let completionBlock: (Bool) -> Void = { [weak self] finished in
            guard let strongSelf = self else { return }
            strongSelf.topView?.layer.cornerRadius = SettingValues.flatMode ? 0 : 15
            strongSelf.callbacks.didCollapse?()
            strongSelf.backgroundView.isHidden = true
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
        let desiredHeight: CGFloat = {
            let height = self.parentController?.view.frame.size.height ?? self.view.frame.size.height
            return min(height - minTopOffset, height * 0.9)
        }()
        self.view.frame = CGRect(x: 0, y: self.view.frame.height, width: parentController?.view.frame.width ?? self.view.frame.size.width, height: desiredHeight)
        if animated {
            let animateBlock = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.backgroundView.alpha = 0
                strongSelf.topView?.alpha = 1
                strongSelf.view.frame = CGRect(x: 0, y: y, width: strongSelf.parentController?.view.frame.width ?? strongSelf.view.frame.size.width, height: desiredHeight)
                strongSelf.topView?.backgroundColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.theme.isLight() ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))
                strongSelf.topView?.layer.cornerRadius = SettingValues.flatMode ? 0 : 15
            }
            
            self.callbacks.didCollapse?()
            self.view.endEditing(true)
            
            let completionBlock: (Bool) -> Void = { [weak self] finished in
                guard let strongSelf = self else { return }
                strongSelf.topView?.layer.cornerRadius = SettingValues.flatMode ? 0 : 15
                strongSelf.backgroundView.isHidden = true
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
            self.backgroundView.isHidden = true
            self.topView?.alpha = 1
            self.view.frame = CGRect(x: 0, y: y, width: parentController?.view.frame.width ?? self.view.frame.size.width, height: desiredHeight)
            self.topView?.backgroundColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.theme.isLight() ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))
            self.topView?.layer.cornerRadius = SettingValues.flatMode ? 0 : 15
        }
    }
    
    func expand() {
        if self.view.isHidden {
            return
        }

        backgroundView.isHidden = false

        if let navVC = parentController!.navigationController {
            navVC.view.addSubviews(backgroundView, self.view)
            navVC.view.bringSubviewToFront(backgroundView)
            backgroundView.edgeAnchors == navVC.view.edgeAnchors
            navVC.view.bringSubviewToFront(self.view)
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
            strongSelf.topView?.backgroundColor = strongSelf.searchBar.backgroundColor
            strongSelf.parentController?.menu.transform = CGAffineTransform(scaleX: 1, y: 1)
            strongSelf.parentController?.more.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        let completionBlock: (Bool) -> Void = { [weak self] finished in
            guard let strongSelf = self else { return }
            if SettingValues.autoKeyboard {
                strongSelf.searchBar.becomeFirstResponder()
            }
            strongSelf.searchBar.isUserInteractionEnabled = true
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
            blurEffect.setValue(5, forKeyPath: "blurRadius")

            let blurView = UIVisualEffectView(frame: backgroundView.frame)
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
        backgroundView.isHidden = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.endEditing(true)
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
            searchBar.becomeFirstResponder()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !SettingValues.flatMode {
            searchBar.roundCorners([.topLeft, .topRight], radius: 25)
        }
    }

    func configureViews() {

        //horizontalSubGroup.setSubreddits(subredditNames: ["FRONTPAGE", "ALL", "POPULAR"])
        //horizontalSubGroup.delegate = self
        //view.addSubview(horizontalSubGroup)

        searchBar.sizeToFit()
        searchBar.delegate = self
        view.addSubview(searchBar)

        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.clipsToBounds = true
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorInset = .zero

        tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "search")
        tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "profile")

        view.addSubview(tableView)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        setColors(MainViewController.current)
    }

    func configureLayout() {
    
        //horizontalSubGroup.topAnchor == view.topAnchor
        //horizontalSubGroup.horizontalAnchors == view.horizontalAnchors
        //horizontalSubGroup.heightAnchor == 90
        
        searchBar.topAnchor == view.topAnchor
        searchBar.horizontalAnchors == view.horizontalAnchors
        searchBar.heightAnchor == 50

        tableView.topAnchor == searchBar.bottomAnchor
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

    func setColors(_ sub: String) {
        DispatchQueue.main.async {
            //self.horizontalSubGroup.setColors()
            //self.horizontalSubGroup.backgroundColor = ColorUtil.foregroundColor
            self.searchBar.tintColor = ColorUtil.fontColor
            self.searchBar.textColor = ColorUtil.fontColor
            self.searchBar.backgroundColor = ColorUtil.foregroundColor
            self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
    }
    
    func setSubreddit(subreddit: String) {
        setColors(subreddit)
        tableView.backgroundColor = ColorUtil.backgroundColor
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
        searchBar.text = ""
        filteredContent = []
        isSearching = false
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return (alphabetical && !isSearching) ? sectionTitles.count : (suggestions.count > 0 ? 2 : 1)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return alphabetical && !isSearching ? sectionTitles : nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if alphabetical && !isSearching {
            return subsAlphabetical[sectionTitles[section]]!.count
        }
        if section == 0 {
            if isSearching {
                return filteredContent.count + (filteredContent.contains(searchBar.text!) ? 0 : 1) + 3
            } else {
                return subs.count
            }
        } else {
            return suggestions.count
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && !alphabetical {
            return 28
        } else {
            return 28
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !isSearching
    }
    
    func getIndexPath(sub: String) -> IndexPath {
        var section = 0
        var row = 0
        for item in self.sectionTitles {
            let array = self.subsAlphabetical[item]!
            row = 0
            for innerSub in array {
                if sub == innerSub {
                    return IndexPath(row: row, section: section)
                }
                row += 1
            }
            section += 1
        }
        return IndexPath(row: 0, section: 0) //Should not get here
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let sub = subsAlphabetical[sectionTitles[editActionsForRowAt.section]]![editActionsForRowAt.row]
        let pinned = editActionsForRowAt.section == 0
        if pinned {
            let pin = UITableViewRowAction(style: .normal, title: "Un-Pin") { _, _ in
                Subscriptions.setPinned(name: AccountController.currentName, subs: Subscriptions.pinned.filter({ $0 != sub })) {
                    self.tableView.beginUpdates()
                    self.loadSections()
                    let newIndexPath = self.getIndexPath(sub: sub)
                    print(editActionsForRowAt)
                    print(newIndexPath)
                    self.tableView.moveRow(at: editActionsForRowAt, to: newIndexPath)
                    self.tableView.endUpdates()
                }
            }
            pin.backgroundColor = GMColor.red500Color()
            return [pin]
        } else {
            let pin = UITableViewRowAction(style: .normal, title: "Pin") { _, _ in
                var newPinned = Subscriptions.pinned
                newPinned.append(sub)
                Subscriptions.setPinned(name: AccountController.currentName, subs: newPinned) {
                    self.tableView.beginUpdates()
                    self.loadSections()
                    let newIndexPath = self.getIndexPath(sub: sub)
                    self.tableView.moveRow(at: editActionsForRowAt, to: newIndexPath)
                    self.tableView.endUpdates()
                }
            }
            pin.backgroundColor = GMColor.yellow500Color()
            return [pin]
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 14, submission: true)
        label.backgroundColor = ColorUtil.foregroundColor
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor

        if isSearching {
            switch section {
            case 0: label.text  = ""
            default: label.text  = "    SUBREDDIT SUGGESTIONS"
            }
        } else {
            label.text = "    \(sectionTitles[section])"
            if sectionTitles[section] == "/" {
                label.text = "    MULTIREDDITS"
            } else if sectionTitles[section] == "★" {
                label.text = "    PINNED"
            }
        }
        return toReturn
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SubredditCellView
        if indexPath.section == 0 {
            if indexPath.row == filteredContent.count && isSearching {
                let thing = searchBar.text!
                let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                c.setSubreddit(subreddit: thing, nav: self, exists: false)
                cell = c
            } else if isSearching && indexPath.row == filteredContent.count + 1 {
                let thing = searchBar.text!
                let c = tableView.dequeueReusableCell(withIdentifier: "profile", for: indexPath) as! SubredditCellView
                c.setProfile(profile: thing, nav: self)
                cell = c
            } else if isSearching && indexPath.row == filteredContent.count + 2 {
                // "Search Reddit for <text>" cell
                let thing = searchBar.text!
                let c = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as! SubredditCellView
                c.setSearch(string: thing, sub: nil, nav: self)
                cell = c
            } else if isSearching && indexPath.row == filteredContent.count + 3 {
                // "Search r/subreddit for <text>" cell
                let thing = searchBar.text!
                let c = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as! SubredditCellView
                c.setSearch(string: thing, sub: MainViewController.current, nav: self)
                cell = c
            } else {
                var thing = ""
                if isSearching {
                    thing = filteredContent[indexPath.row]
                } else if !alphabetical {
                    thing = subs[indexPath.row]
                } else {
                    thing = subsAlphabetical[sectionTitles[indexPath.section]]![indexPath.row]
                }
                let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                c.setSubreddit(subreddit: thing, nav: self, exists: true)
                cell = c
            }
        } else {
            let thing: String
            if isSearching {
                thing = suggestions[indexPath.row]
            } else {
                thing = subsAlphabetical[sectionTitles[indexPath.section]]![indexPath.row]
            }
            let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
            c.setSubreddit(subreddit: thing, nav: self, exists: alphabetical)
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

    @objc func getSuggestions() {
        if task != nil {
            task?.cancel()
        }
        do {
            task = try! (UIApplication.shared.delegate as? AppDelegate)?.session?.getSubredditSearch(searchBar.text ?? "", paginator: Paginator(), completion: { (result) in
                switch result {
                case .success(let subs):
                    for sub in subs.children {
                        let s = sub as! Subreddit
                        // Ignore nsfw subreddits if nsfw is disabled
                        if s.over18 && !SettingValues.nsfwEnabled {
                            continue
                        }
                        self.suggestions.append(s.displayName)
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
        let searchString = searchBar.text
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
        if self.searchBar.text?.isEmpty() ?? false {
            self.tableView.endEditing(true)
            searchBar.resignFirstResponder()
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

extension NavigationSidebarViewController: HorizontalSubredditGroupDelegate {
    func horizontalSubredditGroup(_ horizontalSubredditGroup: HorizontalSubredditGroup, didRequestSubredditWithName name: String) {
        parentController?.goToSubreddit(subreddit: name)
    }
}

extension NavigationSidebarViewController {
    @objc func keyboardWillBeShown(notification: NSNotification) {
        //get the end position keyboard frame
        let keyInfo: Dictionary = notification.userInfo!
        var keyboardFrame: CGRect = keyInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        //convert it to the same view coords as the tableView it might be occluding
        keyboardFrame = self.tableView.convert(keyboardFrame, to: self.tableView)
        //calculate if the rects intersect
        let intersect: CGRect = keyboardFrame.intersection(self.tableView.bounds)
        if !intersect.isNull {
            //yes they do - adjust the insets on tableview to handle it
            //first get the duration of the keyboard appearance animation
            let duration: TimeInterval = keyInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            // Change the table insets to match - animated to the same duration of the keyboard appearance
            UIView.animate(withDuration: duration, animations: {
                let edgeInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.size.height, right: 0)
                self.tableView.contentInset = edgeInset
                self.tableView.scrollIndicatorInsets = edgeInset
            })
        }
    }

    @objc func keyboardWillBeHidden(notification: NSNotification) {
        let keyInfo: Dictionary = notification.userInfo!
        let duration: TimeInterval = keyInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        // Clear the table insets - animated to the same duration of the keyboard disappearance
        UIView.animate(withDuration: duration) {
            self.tableView.contentInset = UIEdgeInsets.zero
            self.tableView.scrollIndicatorInsets = UIEdgeInsets.zero
        }
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

protocol HorizontalSubredditGroupDelegate: AnyObject {
    func horizontalSubredditGroup(_ horizontalSubredditGroup: HorizontalSubredditGroup, didRequestSubredditWithName name: String)
}

class HorizontalSubredditGroup: UIView {

    weak var delegate: HorizontalSubredditGroupDelegate?

    let stack = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
    }

    private var buttons: [UIButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(stack)
        stack.edgeAnchors == edgeAnchors
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setColors() {
        for button in buttons {
            button.setTitleColor(ColorUtil.baseAccent, for: .normal)
            button.setTitleColor(ColorUtil.fontColor, for: .highlighted)
        }
    }

    func setSubreddits(subredditNames: [String]) {
        // Remove all buttons
        for button in buttons {
            stack.removeArrangedSubview(button)
        }

        // Make new buttons
        for name in subredditNames {
            let button = UIButton().then {
                $0.setTitle("\n\n\n\n\(name)", for: .normal)
                $0.titleLabel?.font = FontGenerator.boldFontOfSize(size: 14, submission: false)
                $0.titleLabel?.textAlignment = .center
                $0.accessibilityLabel = name
                $0.titleLabel?.numberOfLines = 0
                $0.accessibilityHint = "Navigates to the subreddit \(name)"
            }
            let dot = UIImageView().then {
                $0.backgroundColor = ColorUtil.baseAccent
                $0.layer.cornerRadius = 25
                $0.heightAnchor == 50
                $0.contentMode = .center
                $0.widthAnchor == 50
                $0.image = UIImage(named: "subs")!.getCopy(withSize: CGSize.square(size: 25), withColor: .white)
            }
            button.addSubview(dot)
            dot.centerXAnchor == button.centerXAnchor
            dot.bottomAnchor == button.bottomAnchor - 25
            stack.addArrangedSubview(button)
            button.addTarget(self, action: #selector(buttonWasTapped), for: .touchUpInside)
            buttons.append(button)
        }

        setColors()
    }

    @objc private func buttonWasTapped(_ sender: UIButton) {
        delegate?.horizontalSubredditGroup(self, didRequestSubredditWithName: sender.currentTitle!.lowercased().trimmed())
    }

}
