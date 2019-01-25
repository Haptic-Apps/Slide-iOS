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

    var subsSource = SubscribedSubredditsSectionProvider()

    var headerView = UIView()
    var dragHandleView = UIView()
    
    var expanded = false

    var isSearching = false

    var task: URLSessionDataTask?

    var accessibilityCloseButton = UIButton().then {
        $0.accessibilityIdentifier = "Close button"
        $0.accessibilityLabel = "Close"
        $0.accessibilityHint = "Close navigation drawer"
    }

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
        $0.accessibilityLabel = "Search"
        $0.accessibilityHint = "Search subreddits, posts, or profiles"
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
    
//    func loadSections() {
//        subsAlphabetical.removeAll()
//        sectionTitles.removeAll()
//        for string in Subscriptions.pinned {
//            var current = subsAlphabetical["★"] ?? [String]()
//            current.append(string)
//            print(current)
//            print(Subscriptions.pinned)
//            subsAlphabetical["★"] = current
//        }
//
//        for string in subs.filter({ !Subscriptions.pinned.contains($0) }).sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending }) {
//            let letter = string.substring(0, length: 1).uppercased()
//            var current = subsAlphabetical[letter] ?? [String]()
//            current.append(string)
//            subsAlphabetical[letter] = current
//        }
//
//        sectionTitles = subsAlphabetical.keys.sorted { $0.caseInsensitiveCompare($1) == .orderedAscending }
//        if sectionTitles.contains("★") {
//            sectionTitles.remove(at: sectionTitles.count - 1)
//            sectionTitles.insert("★", at: 0)
//        }
//    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.sectionIndexColor = ColorUtil.baseAccent
        subsSource.reload()

        self.view = UITouchCapturingView()

        configureViews()
        configureLayout()
        configureGestures()
        
        configureBackground()

        headerView.addTapGestureRecognizer {
            self.expand()
        }
        (searchBar.value(forKey: "searchField") as? UITextField)?.isEnabled = false

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeShown),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)

        updateAccessibility()
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
        if let recognizer = gestureRecognizer as? UIPanGestureRecognizer,
            recognizer.velocity(in: self.view).y < 0,
            let topView = topView,
            topView.alpha == 0 {
            return false
        }
        return true
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
        doneOnce = false
        searchBar.isUserInteractionEnabled = false
        (searchBar.value(forKey: "searchField") as? UITextField)?.isEnabled = false

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
            strongSelf.expanded = false
            strongSelf.updateAccessibility()
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
    
    var doneOnce = false
    func expand() {
        if self.view.isHidden {
            return
        }
        (searchBar.value(forKey: "searchField") as? UITextField)?.isEnabled = true

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
            strongSelf.topView?.backgroundColor = strongSelf.headerView.backgroundColor
            strongSelf.parentController?.menu.transform = CGAffineTransform(scaleX: 1, y: 1)
            strongSelf.parentController?.more.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        let completionBlock: (Bool) -> Void = { [weak self] finished in
            guard let strongSelf = self else { return }
            if SettingValues.autoKeyboard && !strongSelf.doneOnce {
                strongSelf.doneOnce = true
                strongSelf.expanded = true
                strongSelf.updateAccessibility()
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
            headerView.roundCorners([.topLeft, .topRight], radius: 25)
        }
    }

    func configureViews() {

        //horizontalSubGroup.setSubreddits(subredditNames: ["FRONTPAGE", "ALL", "POPULAR"])
        //horizontalSubGroup.delegate = self
        //view.addSubview(horizontalSubGroup)

        view.addSubview(headerView)

        headerView.addSubview(dragHandleView)

        searchBar.sizeToFit()
        searchBar.delegate = self
        headerView.addSubview(searchBar)

        headerView.addSubview(accessibilityCloseButton)
        accessibilityCloseButton.addTarget(self, action: #selector(accessibilityCloseButtonActivated), for: .touchUpInside)

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

        headerView.topAnchor == view.topAnchor
        headerView.horizontalAnchors == view.horizontalAnchors

        accessibilityCloseButton.topAnchor == headerView.topAnchor
        accessibilityCloseButton.leftAnchor == headerView.leftAnchor
        accessibilityCloseButton.sizeAnchors == .square(size: 10)

        dragHandleView.topAnchor == headerView.topAnchor + 8
        dragHandleView.centerXAnchor == headerView.centerXAnchor
        dragHandleView.sizeAnchors == CGSize(width: 60, height: 6)
        dragHandleView.layer.cornerRadius = 3
        
        searchBar.topAnchor == dragHandleView.bottomAnchor + 4
        searchBar.horizontalAnchors == headerView.horizontalAnchors
        searchBar.heightAnchor == 50
        searchBar.bottomAnchor == headerView.bottomAnchor

        tableView.topAnchor == headerView.bottomAnchor - 2
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
            self.headerView.backgroundColor = ColorUtil.foregroundColor
            self.dragHandleView.backgroundColor = ColorUtil.fontColor.withAlphaComponent(0.2)
            self.searchBar.tintColor = ColorUtil.fontColor
            self.searchBar.textColor = ColorUtil.fontColor
            self.searchBar.backgroundColor = .clear
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
        return !isSearching ? subsSource.sections.count : (suggestions.count > 0 ? 2 : 1)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return !isSearching ? subsSource.sortedSectionTitles : nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isSearching {
            return subsSource.numberOfRowsInSection(section)
        } else {
            if section == 0 {
                return filteredContent.count + (filteredContent.contains(searchBar.text!) ? 0 : 1) + 3
            } else {
                return suggestions.count
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isSearching && section == 0 {
            return 0
        }
        return 28
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !isSearching
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        tableView.contentOffset = CGPoint(x: 0, y: tableView.contentOffset.y + 1)
        let sub = subsSource.subredditsInSection(editActionsForRowAt.section)![editActionsForRowAt.row]
        let wasEmpty = Subscriptions.pinned.isEmpty
        let isPinned = editActionsForRowAt.section == 0 && !wasEmpty
        if isPinned {
            let pin = UITableViewRowAction(style: .normal, title: "Un-Pin") { _, _ in
                Subscriptions.setPinned(name: AccountController.currentName, subs: Subscriptions.pinned.filter({ $0 != sub })) {
                    self.tableView.beginUpdates()

                    let oldSubIndex = self.subsSource.getIndexPath(forSubreddit: sub)!
                    let oldSubSectionName = self.subsSource.sortedSectionTitles[oldSubIndex.section]
                    self.subsSource.reload()
                    let newSubIndex = self.subsSource.getIndexPath(forSubreddit: sub)!
                    let newSubSectionName = self.subsSource.sortedSectionTitles[newSubIndex.section]

                    // Add new section if it doesn't exist
                    if let newSection = self.subsSource.sections[newSubSectionName],
                        newSection.count == 1,
                        newSection[0] == sub {
                        self.tableView.insertSections([newSubIndex.section], with: .automatic)
                    }

                    self.tableView.deleteRows(at: [oldSubIndex], with: .automatic)
                    
                    // Remove old section if it's gone
                    if self.subsSource.sections[oldSubSectionName] == nil {
                        self.tableView.deleteSections([oldSubIndex.section], with: .automatic)
                    }
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
                    
                    let oldSubIndex = self.subsSource.getIndexPath(forSubreddit: sub)!
                    let oldSubSectionName = self.subsSource.sortedSectionTitles[oldSubIndex.section]
                    self.subsSource.reload()
                    let newSubIndex = self.subsSource.getIndexPath(forSubreddit: sub)!
                    let newSubSectionName = self.subsSource.sortedSectionTitles[newSubIndex.section]

                    // Add new section if it doesn't exist
                    if let newSection = self.subsSource.sections[newSubSectionName],
                        newSection.count == 1,
                        newSection[0] == sub {
                        self.tableView.insertSections([newSubIndex.section], with: .automatic)
                    }

                    self.tableView.insertRows(at: [newSubIndex], with: .automatic)

                    // Remove old section if it's gone
                    if self.subsSource.sections[oldSubSectionName] == nil {
                        self.tableView.deleteSections([oldSubIndex.section], with: .automatic)
                    }

                    self.tableView.endUpdates()
                }
            }
            pin.backgroundColor = GMColor.yellow500Color()
            return [pin]
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 14, submission: true)

        if isSearching {
            switch section {
            case 0: label.text  = ""
            default: label.text  = "SUBREDDIT SUGGESTIONS"
            }
        } else {
            let sectionTitle = subsSource.sortedSectionTitles[section]
            if sectionTitle == SubscribedSubredditsSectionProvider.Keys.pinned.rawValue {
                label.text = SubscribedSubredditsSectionProvider.Keys.pinned.rawValue
                label.accessibilityLabel = SubscribedSubredditsSectionProvider.Keys.pinned.accessibleName
            } else if sectionTitle == SubscribedSubredditsSectionProvider.Keys.multi.rawValue {
                label.text = "MULTIREDDITS"
                label.accessibilityLabel = SubscribedSubredditsSectionProvider.Keys.multi.accessibleName
            } else if sectionTitle == SubscribedSubredditsSectionProvider.Keys.numeric.rawValue {
                label.text = SubscribedSubredditsSectionProvider.Keys.numeric.rawValue
                label.accessibilityLabel = SubscribedSubredditsSectionProvider.Keys.numeric.accessibleName
            } else {
                label.text = sectionTitle
                label.accessibilityLabel = sectionTitle.lowercased()
            }
        }

        let toReturn = label.withPadding(padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.foregroundColor
        return toReturn
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SubredditCellView
        if indexPath.section == 0 {
            if isSearching {
                if indexPath.row == filteredContent.count {
                    let thing = searchBar.text!
                    let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                    c.setSubreddit(subreddit: thing, nav: self, exists: false)
                    cell = c
                } else if indexPath.row == filteredContent.count + 1 {
                    let thing = searchBar.text!
                    let c = tableView.dequeueReusableCell(withIdentifier: "profile", for: indexPath) as! SubredditCellView
                    c.setProfile(profile: thing, nav: self)
                    cell = c
                } else if indexPath.row == filteredContent.count + 2 {
                    // "Search Reddit for <text>" cell
                    let thing = searchBar.text!
                    let c = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as! SubredditCellView
                    c.setSearch(string: thing, sub: nil, nav: self)
                    cell = c
                } else if indexPath.row == filteredContent.count + 3 {
                    // "Search r/subreddit for <text>" cell
                    let thing = searchBar.text!
                    let c = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as! SubredditCellView
                    c.setSearch(string: thing, sub: MainViewController.current, nav: self)
                    cell = c
                } else {
                    var thing = ""
                    thing = filteredContent[indexPath.row]
                    let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                    c.setSubreddit(subreddit: thing, nav: self, exists: true)
                    cell = c
                }
            } else {
                var thing = ""
                thing = subsSource.subredditsInSection(indexPath.section)![indexPath.row]
                let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                c.setSubreddit(subreddit: thing, nav: self, exists: true)
                cell = c
            }
        } else {
            let thing: String
            if isSearching {
                thing = suggestions[indexPath.row]
            } else {
                thing = subsSource.subredditsInSection(indexPath.section)![indexPath.row]
            }
            let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
            c.setSubreddit(subreddit: thing, nav: self, exists: true)
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

// MARK: - Accessibility
extension NavigationSidebarViewController {
    func updateAccessibility() {
        tableView.accessibilityElementsHidden = !expanded
        searchBar.accessibilityElementsHidden = !expanded
        accessibilityCloseButton.accessibilityElementsHidden = !expanded
        self.view.accessibilityViewIsModal = expanded // Block sibling elements from being interacted with
    }

    @objc func accessibilityCloseButtonActivated(_ sender: UIButton) {
        self.collapse()
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

class SubscribedSubredditsSectionProvider {
    private(set) var sections: [String: [String]] = [:]

    enum Keys: String, CaseIterable {
        case pinned = "★"
        case multi = "+"
        case numeric = "#"

        var accessibleName: String {
            switch self {
            case .pinned:
                return "Pinned"
            case .multi:
                return "Multi reddits"
            case .numeric:
                return "Numbered"
            }
        }
    }

    private(set) var sortedSectionTitles: [String] = []

    private var pinnedSubs: Set<String> = Set()
    private var multiSubs: Set<String> = Set()
    private var numericSubs: Set<String> = Set()

    init() {
        reload()
    }

    func reload() {
        reloadSections()
        reloadSortedTitles()
    }

    private func reloadSortedTitles() {
        var titles: [String] = []
        if sections[Keys.pinned.rawValue] != nil {
            titles.append(Keys.pinned.rawValue)
        }
        if sections[Keys.multi.rawValue] != nil {
            titles.append(Keys.multi.rawValue)
        }
        if sections[Keys.numeric.rawValue] != nil {
            titles.append(Keys.numeric.rawValue)
        }

        let azKeys = sections.keys
            .filter { !Keys.allCases.map { $0.rawValue }.contains($0) }
            .sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
        titles.append(contentsOf: azKeys)

        sortedSectionTitles = titles
    }

    private func reloadSections() {
        sections.removeAll()

        pinnedSubs = Set(Subscriptions.pinned)
        numericSubs = Set(Subscriptions.subreddits
            .filter { return String($0[0]).isNumeric() })
        multiSubs = Set(Subscriptions.subreddits
            .filter { return $0[0] == "/" })

        // Insert pinned section if any pinned subs exist
        if !pinnedSubs.isEmpty {
            sections[Keys.pinned.rawValue] = Subscriptions.pinned//.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
        }

        // Insert "multi" section for multireddits
        if !multiSubs.isEmpty {
            sections[Keys.multi.rawValue] = multiSubs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
        }

        // Insert "#" section for numeric subs
        if !numericSubs.isEmpty {
            sections[Keys.numeric.rawValue] = numericSubs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
        }

        // All the subs that aren't in a special category
        let otherSubs = Set(Subscriptions.subreddits)
            .subtracting(numericSubs.union(multiSubs))

        // Make sections for a-z
        for sub in otherSubs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending }) {
            let firstChar = String(sub[0]).uppercased()
            if sections[firstChar] == nil {
                sections[firstChar] = []
            }
            sections[firstChar]!.append(sub)
        }
    }

    func subredditsInSection(_ section: Int) -> [String]? {
        return sections[sortedSectionTitles[section]]
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        return subredditsInSection(section)?.count ?? 0
    }

    func getIndexPath(forSubreddit sub: String) -> IndexPath? {
        
        if let index = Array(pinnedSubs).firstIndex(of: sub),
            let sectionIndex = sortedSectionTitles.firstIndex(of: Keys.pinned.rawValue) {
            return IndexPath(row: index, section: sectionIndex)
        }

        if let index = Array(multiSubs).firstIndex(of: sub),
            let sectionIndex = sortedSectionTitles.firstIndex(of: Keys.multi.rawValue) {
            return IndexPath(row: index, section: sectionIndex)
        }

        if let index = Array(numericSubs).firstIndex(of: sub),
            let sectionIndex = sortedSectionTitles.firstIndex(of: Keys.numeric.rawValue) {
            return IndexPath(row: index, section: sectionIndex)
        }

        let firstChar = String(sub[0]).uppercased()
        if let sectionIndex = sortedSectionTitles.firstIndex(of: firstChar),
            let section = sections[firstChar],
            let rowIndex = section.firstIndex(of: sub) {
            return IndexPath(row: rowIndex, section: sectionIndex)
        }

        return nil
    }

}
