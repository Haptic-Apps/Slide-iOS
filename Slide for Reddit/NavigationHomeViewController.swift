//
//  NavigationHomeViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/19/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Alamofire
import Anchorage
import AudioToolbox
import BadgeSwift
import SDCAlertView
import SwiftyJSON
import reddift
import SDWebImage
import Then
import UIKit

class NavigationHomeViewController: UIViewController {
    var tableView = UITableView(frame: CGRect.zero, style: .grouped)
    var filteredContent: [String] = []
    var suggestions = [String]()
    var users = [String]()
    var parentController: SplitMainViewController?
    var topView: UIView?
    var bottomOffset: CGFloat = 64
    var muxColor = ColorUtil.theme.foregroundColor
    var lastY: CGFloat = 0.0
    var timer: Timer?
    static var edgeGesture: UIScreenEdgePanGestureRecognizer?

    var subsSource = SubscribedSubredditsSectionProvider()

    var headerView = UIView()
    
    var expanded = false

    var isSearching = false

    var task: DataRequest?

    var accessibilityCloseButton = UIButton().then {
        $0.accessibilityIdentifier = "Close button"
        $0.accessibilityLabel = "Close"
        $0.accessibilityHint = "Close navigation drawer"
    }

    var multiButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(sfString: SFSymbol.folderBadgePlusFill, overrideString: "compact")!.getCopy(withSize: .square(size: 30), withColor: .white), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 24, right: 24)
        $0.accessibilityLabel = "Create a Multireddit"
    }

    // Guaranteed amount of space between top edge of menu and top edge of screen
    let minTopOffset: CGFloat = 42

    var searchBar = UISearchBar().then {
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.spellCheckingType = .no
        $0.returnKeyType = .search
        if !ColorUtil.theme.isLight {
            $0.keyboardAppearance = .dark
        }
        $0.searchBarStyle = UISearchBar.Style.minimal
        $0.placeholder = " Search subs, posts, or profiles"
        $0.isTranslucent = true
        $0.barStyle = .blackTranslucent
        $0.accessibilityLabel = "Search"
        $0.accessibilityHint = "Search subreddits, posts, or profiles"
    }
    
    var accountHeader: CurrentAccountHeaderView?

    //let horizontalSubGroup = HorizontalSubredditGroup()
    
    init(controller: SplitMainViewController) {
        self.parentController = controller
        super.init(nibName: nil, bundle: nil)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            if UIScreen.main.bounds.height >= 812 {
                bottomOffset = 84
            }
        } else if UIApplication.shared.isSplitOrSlideOver {
            bottomOffset = 84
            if let w = UIApplication.shared.delegate?.window, let window = w {
                bottomOffset += (window.screen.bounds.height - window.frame.height) / 2
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doViews()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeShown),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        
        updateAccessibility()
        searchBar.isUserInteractionEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(onThemeChanged), name: .onThemeChanged, object: nil)
    }

    @objc func onThemeChanged() {
        doViews()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if let themeChanged = previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) {
                if themeChanged {
                    ColorUtil.matchTraitCollection()
                }
            }
        }
    }

    func doViews() {
        tableView.backgroundColor = ColorUtil.theme.foregroundColor
        tableView.separatorColor = ColorUtil.theme.foregroundColor
        
        self.navigationController?.navigationBar.barTintColor = ColorUtil.theme.foregroundColor
        self.splitViewController?.view.backgroundColor = ColorUtil.theme.foregroundColor

        tableView.sectionIndexColor = ColorUtil.baseAccent

        subsSource.reload()

        self.view = UITouchCapturingView()

        configureViews()
        configureLayout()
        
        self.tableView.reloadData()
    }
    
    struct Callbacks {
        var didBeginPanning: (() -> Void)?
        var didCollapse: (() -> Void)?
    }
    var callbacks = Callbacks()
    
    var lastPercentY = CGFloat(0)
        
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            if text.isEmpty {
                return
            }
            if text.contains(" ") {
                //do search
                VCPresenter.showVC(viewController: SearchViewController(subreddit: MainViewController.current, searchFor: text), popupIfPossible: false, parentNavigationController: parentController?.navigationController, parentViewController: parentController)
            } else {
                //go to sub
                parentController?.goToSubreddit(subreddit: text)
            }
        }
    }
    
    var doneOnce = false

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.endEditing(true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update any things that can change due to user settings here
        tableView.backgroundColor = ColorUtil.theme.foregroundColor
        tableView.separatorColor = ColorUtil.theme.foregroundColor
        
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true

        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.setToolbarHidden(true, animated: false)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = ColorUtil.theme.foregroundColor
        self.splitViewController?.view.backgroundColor = ColorUtil.theme.foregroundColor
        
        self.tableView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if SettingValues.autoKeyboard {
            //TODO enable this? searchBar.becomeFirstResponder()
        }
        if let sectionIndex = tableView.sectionIndexView, let nav = (navigationController as? SwipeForwardNavigationController) {
            NavigationHomeViewController.edgeGesture = UIScreenEdgePanGestureRecognizer(target: nav, action: #selector(nav.handleRightSwipe(_:)))
            NavigationHomeViewController.edgeGesture!.edges = UIRectEdge.right
            NavigationHomeViewController.edgeGesture!.delegate = nav
            sectionIndex.addGestureRecognizer(NavigationHomeViewController.edgeGesture!)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.endEditing(true)
        NavigationHomeViewController.edgeGesture = nil
    }

    func configureViews() {

        //horizontalSubGroup.setSubreddits(subredditNames: ["FRONTPAGE", "ALL", "POPULAR"])
        //horizontalSubGroup.delegate = self
        //view.addSubview(horizontalSubGroup)

        accountHeader = CurrentAccountHeaderView()
        accountHeader?.delegate = parentController
        accountHeader!.initCurrentAccount(self)
        
        searchBar.sizeToFit()
        searchBar.delegate = self
        
        headerView.isUserInteractionEnabled = true
        headerView.addSubviews(accountHeader!, searchBar)

        headerView.addSubview(accessibilityCloseButton)
        accessibilityCloseButton.addTarget(self, action: #selector(accessibilityCloseButtonActivated), for: .touchUpInside)

        tableView.bounces = true
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
        setColors(MainViewController.current)
    }

    func configureLayout() {
    
        //horizontalSubGroup.topAnchor == view.topAnchor
        //horizontalSubGroup.horizontalAnchors == view.horizontalAnchors
        //horizontalSubGroup.heightAnchor == 90
        accountHeader!.topAnchor == headerView.topAnchor
        accountHeader!.horizontalAnchors == headerView.horizontalAnchors
        accountHeader!.heightAnchor == accountHeader!.estimateHeight()
        searchBar.topAnchor == accountHeader!.bottomAnchor + 4
        searchBar.horizontalAnchors == headerView.horizontalAnchors + 8
        searchBar.heightAnchor == 50
        searchBar.bottomAnchor == headerView.bottomAnchor

        tableView.topAnchor == view.safeTopAnchor
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        tableView.horizontalAnchors == view.horizontalAnchors
        tableView.bottomAnchor == view.bottomAnchor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setViewController(controller: SplitMainViewController) {
        parentController = controller
    }

    func setColors(_ sub: String) {
        DispatchQueue.main.async {
            //self.horizontalSubGroup.setColors()
            //self.horizontalSubGroup.backgroundColor = ColorUtil.theme.foregroundColor
            self.headerView.backgroundColor = ColorUtil.theme.foregroundColor
            self.searchBar.tintColor = ColorUtil.theme.fontColor
            self.searchBar.textColor = ColorUtil.theme.fontColor
            self.searchBar.backgroundColor = .clear
            self.tableView.backgroundColor = ColorUtil.theme.foregroundColor
            self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
    }
    
    func setSubreddit(subreddit: String) {
        setColors(subreddit)
        tableView.backgroundColor = ColorUtil.theme.foregroundColor
    }
    
    func reloadData() {
        tableView.reloadData()
    }
}

extension NavigationHomeViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! SubredditCellView
        if !cell.profile.isEmpty() {
            let user = cell.profile
            VCPresenter.openRedditLink("/u/" + user.replacingOccurrences(of: " ", with: ""), self.navigationController, self)
        } else if !cell.search.isEmpty() {
            VCPresenter.showVC(viewController: SearchViewController(subreddit: cell.subreddit, searchFor: cell.search), popupIfPossible: false, parentNavigationController: parentController?.navigationController, parentViewController: parentController)
        } else {
            let sub = cell.subreddit
            if let nav = self.navigationController as? SwipeForwardNavigationController, nav.topViewController == self {
                nav.pushNextViewControllerFromRight() {
                    self.parentController?.goToSubreddit(subreddit: sub)
                }
            } else {
                parentController?.goToSubreddit(subreddit: sub)
            }
        }
        searchBar.text = ""
        searchBar.endEditing(true)
        filteredContent = []
        isSearching = false
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return !isSearching ? subsSource.sections.count : (suggestions.count + users.count > 0 ? 2 : 1)
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
                return suggestions.count + users.count
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 50 + 4 + accountHeader!.estimateHeight()
        }
        if isSearching && section == 0 {
            return 0
        }
        return 28
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false && !isSearching //Disable pinning for now
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
                    self.tableView.deleteRows(at: [oldSubIndex], with: .automatic)
                    
                    // Remove old section if it's gone
                    if self.subsSource.sections[oldSubSectionName] == nil {
                        self.tableView.deleteSections([oldSubIndex.section], with: .automatic)
                    }
                    self.tableView.endUpdates()
                    self.tableView.reloadData()
                }
            }
            pin.backgroundColor = GMColor.red500Color()
            return [pin]
        } else {
            let pin = UITableViewRowAction(style: .normal, title: "Pin") { _, _ in
                if Subscriptions.pinned.filter({ $0.lowercased() == sub.lowercased() }).count > 0 {
                    return
                }
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
                    self.tableView.reloadData()
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

        if section == 0 {
            return headerView
        }
        if isSearching {
            switch section {
            case 0: label.text  = ""
            default: label.text  = "REDDIT SUGGESTIONS"
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
        toReturn.backgroundColor = ColorUtil.theme.foregroundColor
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
                    // "Search Reddit for <text>" cell
                    let thing = searchBar.text!
                    let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
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
                print(users)
                print(suggestions)
                print(indexPath.row)
                if (indexPath.row > suggestions.count - 1 || suggestions.count == 0) && users.count > 0 {
                    thing = users[indexPath.row - suggestions.count]
                    let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                    c.setProfile(profile: thing, nav: self)
                    cell = c
                } else {
                    thing = suggestions[indexPath.row]
                    let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                    c.setSubreddit(subreddit: thing, nav: self, exists: true)
                    cell = c
                }
            } else {
                thing = subsSource.subredditsInSection(indexPath.section)![indexPath.row]
                let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                c.setSubreddit(subreddit: thing, nav: self, exists: true)
                cell = c
            }
        }

        cell.backgroundColor = ColorUtil.theme.foregroundColor

        return cell
    }
}

extension NavigationHomeViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        tableView.setContentOffset(searchBar.frame.origin, animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String) {
        timer?.invalidate()
        filteredContent = []
        suggestions = []
        users = []
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
            let requestString = "https://www.reddit.com/api/subreddit_autocomplete_v2.json?always_show_media=1&api_type=json&expand_srs=1&feature=link_preview&from_detail=1&include_users=true&obey_over18=1&raw_json=1&rtj=debug&sr_detail=1&query=\(searchBar.text?.addPercentEncoding ?? "")&include_over_18=\((AccountController.isLoggedIn && SettingValues.nsfwEnabled) ? "true" : "false")"
            print("Requesting \(requestString)")
            task = Alamofire.request(requestString, method: .get).responseString { response in
                do {
                    guard let data = response.data else {
                        return
                    }
                    let json = try JSON(data: data)
                    if let subs = json["data"]["children"].array {
                        for sub in subs {
                            if sub["kind"].string == "t5", let subName = sub["data"]["display_name"].string {
                                if let icon = sub["data"]["icon_img"].string, let communityIcon = sub["data"]["community_icon"].string, let keyColor = sub["data"]["key_color"].string {
                                    Subscriptions.subIcons[subName.lowercased()] = icon == "" ? communityIcon : icon
                                    Subscriptions.subColors[subName.lowercased()] = keyColor
                                }
                                self.suggestions.append(subName)
                            } else if sub["kind"].string == "t2", let userName = sub["data"]["name"].string {
                                self.users.append(userName)
                            }
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                } catch {
                }
            }
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
        
        filteredContent = filteredContent.sorted(by: { (a, b) -> Bool in
            let aPrefix = a.lowercased().hasPrefix(searchString!.lowercased())
            let bPrefix = b.lowercased().hasPrefix(searchString!.lowercased())
            if aPrefix && bPrefix {
                return a.lowercased() < b.lowercased()
            } else if aPrefix {
                return true
            } else if bPrefix {
                return false
            } else {
                return a.lowercased() < b.lowercased()
            }
        })
    }

}

extension NavigationHomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentY = scrollView.contentOffset.y
        if self.searchBar.text?.isEmpty() ?? false {
            //TODO this?
            //self.tableView.endEditing(true)
            //searchBar.resignFirstResponder()
        }
        lastY = scrollView.contentOffset.y
    }
}

extension NavigationHomeViewController: HorizontalSubredditGroupDelegate {
    func horizontalSubredditGroup(_ horizontalSubredditGroup: HorizontalSubredditGroup, didRequestSubredditWithName name: String) {
        parentController?.goToSubreddit(subreddit: name)
    }
}

extension NavigationHomeViewController {
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
extension NavigationHomeViewController {
    func updateAccessibility() {
        tableView.accessibilityElementsHidden = !expanded
        searchBar.accessibilityElementsHidden = !expanded
        accessibilityCloseButton.accessibilityElementsHidden = !expanded
        self.view.accessibilityViewIsModal = expanded // Block sibling elements from being interacted with
    }

    @objc func accessibilityCloseButtonActivated(_ sender: UIButton) {
        //todo go back home
    }
}

// MARK: - Header view
protocol CurrentAccountHeaderViewDelegate: AnyObject {
    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestSettingsMenu: Void)
    func currentAccountViewController(_ view: CurrentAccountHeaderView?, didRequestAccountChangeToName accountName: String)
    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestGuestAccount: Void)
    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestLogOut: Void)
    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestNewAccount: Void)
    func currentAccountViewController(_ view: CurrentAccountHeaderView, goToMultireddit multireddit: String)
    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestCacheNow: Void)
    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestHistory: Void)
    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestAction: SettingValues.NavigationHeaderActions)
}

class CurrentAccountHeaderView: UIView {
    
    weak var delegate: CurrentAccountHeaderViewDelegate?
    weak var parent: UIViewController?
    
    var reportText: String?
    var defaultActions: [SettingValues.NavigationHeaderActions] = []
    
    /// Overall height of the content view, including its out-of-bounds elements.
    var contentViewHeight: CGFloat {
        let converted = accountImageView.convert(accountImageView.bounds, to: self)
        return self.frame.maxY - converted.minY
    }
    
    var outOfBoundsHeight: CGFloat {
        let converted = accountImageView.convert(accountImageView.bounds, to: self)
        return contentView.frame.minY - converted.minY
    }
    
    func estimateHeight() -> CGFloat {
        return 12 + 70 + shortcutsView.estimateHeight() //TODO estimate account label height
    }
    
    var spinner = UIActivityIndicatorView().then {
        $0.style = UIActivityIndicatorView.Style.whiteLarge
        $0.color = ColorUtil.theme.fontColor
        $0.hidesWhenStopped = true
    }
    
    var contentView = UIView().then {
        $0.clipsToBounds = false
    }
    
    var settingsButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(sfString: .gear, overrideString: "settings")!.getCopy(withSize: .square(size: 30), withColor: ColorUtil.theme.fontColor), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 7, left: 8, bottom: 7, right: 8)
        $0.accessibilityLabel = "App Settings"
    }
    
    var forwardButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(sfString: .chevronRight, overrideString: "next")!.getCopy(withSize: .square(size: 20), withColor: ColorUtil.theme.fontColor), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 7, left: 8, bottom: 7, right: 8)
        $0.accessibilityLabel = "Go home"
    }

    // Outer button stack
    
    var upperButtonStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 0
    }
    var modButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(sfString: SFSymbol.shieldLefthalfFill, overrideString: "mod")!.getCopy(withSize: .square(size: 30), withColor: ColorUtil.baseAccent), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 7, left: 8, bottom: 7, right: 8)
        $0.accessibilityLabel = "Mod Queue"
    }
    var mailButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(sfString: SFSymbol.trayFill, overrideString: "messages")!.getCopy(withSize: .square(size: 30), withColor: ColorUtil.baseAccent), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 7, left: 8, bottom: 7, right: 8)
        $0.accessibilityLabel = "Inbox"
    }
    var switchAccountsButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(sfString: SFSymbol.personAndPersonFill, overrideString: "user")!.getCopy(withSize: .square(size: 30), withColor: ColorUtil.baseAccent), for: UIControl.State.normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 7, left: 8, bottom: 7, right: 8)
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
        $0.font = FontGenerator.boldFontOfSize(size: 18, submission: false)
        $0.textColor = ColorUtil.theme.fontColor
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.5
        $0.baselineAdjustment = UIBaselineAdjustment.alignCenters
    }
    
    var accountAgeLabel = UILabel().then {
        $0.font = FontGenerator.fontOfSize(size: 10, submission: false)
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
    
    var shortcutsView: AccountShortcutsView!
    
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
    
    func initCurrentAccount(_ parent: UIViewController) {
        self.parent = parent
        
        defaultActions = SettingValues.NavigationHeaderActions.getMenuNone()

        shortcutsView = AccountShortcutsView(frame: CGRect.zero, actions: defaultActions)
        
        setupViews()
        setupConstraints()
        setupActions()

        let leftItem = UIBarButtonItem(customView: upperButtonStack)
        let rightItem = UIBarButtonItem(customView: settingsButton)
        let forwardItem = UIBarButtonItem(customView: forwardButton)

        parent.navigationItem.leftBarButtonItem = leftItem
        parent.navigationItem.rightBarButtonItems = [forwardItem, rightItem]

        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotificationPosted), name: .onAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedToGuestNotificationPosted), name: .onAccountChangedToGuest, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountMailCountChanged), name: .onAccountMailCountChanged, object: nil)
        
        configureForCurrentAccount()
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: accountNameLabel)
        
        updateMailBadge()
        updateModBadge()
    }
}

// MARK: - Setup
extension CurrentAccountHeaderView {
    func setupViews() {
        
        upperButtonStack.addArrangedSubviews(mailButton, modButton, switchAccountsButton)
        
        mailButton.addSubview(mailBadge)
        modButton.addSubview(modBadge)
        
        self.addSubview(contentView)
        contentView.addSubview(accountImageView)
        contentView.addSubview(accountNameLabel)
        contentView.addSubview(accountAgeLabel)
        
        contentView.addSubview(shortcutsView)
        shortcutsView.delegate = self
        
        contentView.addSubview(emptyStateLabel)
        
        contentView.addSubview(spinner)
        
    }
    
    func setupConstraints() {
                        
        upperButtonStack.heightAnchor == 44
        
        contentView.horizontalAnchors == self.horizontalAnchors
        contentView.verticalAnchors == self.verticalAnchors
        
        accountImageView.leftAnchor == contentView.safeLeftAnchor + 10
        accountImageView.topAnchor == contentView.topAnchor
        accountImageView.sizeAnchors == CGSize.square(size: 70)
        
        accountNameLabel.topAnchor == contentView.safeTopAnchor
        accountNameLabel.leftAnchor == accountImageView.rightAnchor + 10
        accountNameLabel.rightAnchor == contentView.rightAnchor - 10
        
        accountAgeLabel.leftAnchor == accountNameLabel.leftAnchor
        accountAgeLabel.topAnchor == accountNameLabel.bottomAnchor
        
        shortcutsView.topAnchor == accountImageView.bottomAnchor + 8
        shortcutsView.horizontalAnchors == contentView.safeHorizontalAnchors + 10
        
        spinner.centerAnchors == shortcutsView.centerAnchors
        
        mailBadge.centerYAnchor == mailButton.centerYAnchor - 10
        mailBadge.centerXAnchor == mailButton.centerXAnchor + 16
        
        modBadge.centerYAnchor == modButton.centerYAnchor - 10
        modBadge.centerXAnchor == modButton.centerXAnchor + 16

        emptyStateLabel.edgeAnchors == shortcutsView.edgeAnchors
    }
    
    func setupActions() {
        settingsButton.addTarget(self, action: #selector(settingsButtonPressed), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(goForward), for: .touchUpInside)

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
            accountImageView.contentMode = .scaleAspectFill
            accountImageView.sd_setImage(with: URL(string: AccountController.current!.image.decodeHTML()), placeholderImage: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")?.getCopy(withColor: ColorUtil.theme.fontColor), options: [.allowInvalidSSLCertificates]) {[weak self] (image, _, _, _) in
                guard let strongSelf = self else { return }
                strongSelf.accountImageView.image = image
            }
        } else {
            accountImageView.contentMode = .center
            accountImageView.image = UIImage(sfStringHQ: SFSymbol.personFill, overrideString: "profile")?.getCopy(withSize: CGSize.square(size: 50), withColor: ColorUtil.theme.fontColor)
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
            strongSelf.accountHeaderView(strongSelf.shortcutsView, didRequestProfilePageAtIndex: 0)
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
            self.shortcutsView.alpha = isOn ? 0 : 1
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
            
            self.shortcutsView.alpha = isOn ? 0 : 1
            self.shortcutsView.isUserInteractionEnabled = !isOn
            
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
            // TODO: - How do we know the mod mail count?
            modBadge.text = ""
        } else {
            modBadge.isHidden = true
            modBadge.text = ""
        }
    }
}

// MARK: - Actions
extension CurrentAccountHeaderView {

    @objc func settingsButtonPressed(_ sender: UIButton) {
        self.delegate?.currentAccountViewController(self, didRequestSettingsMenu: ())
    }
    
    @objc func goForward(_ sender: UIButton) {
        if let nav = self.parent?.navigationController as? SwipeForwardNavigationController {
            nav.pushNextViewControllerFromRight(nil)
        }
    }
    
    @objc func mailButtonPressed(_ sender: UIButton) {
        let vc = InboxViewController()
        let navVC = SwipeForwardNavigationController(rootViewController: vc)
        navVC.navigationBar.isTranslucent = false
        parent?.present(navVC, animated: true)
    }
    
    @objc func cacheButtonPressed() {
        self.delegate?.currentAccountViewController(self, didRequestCacheNow: ())
    }
    
    @objc func historyButtonPressed() {
        self.delegate?.currentAccountViewController(self, didRequestHistory: ())
    }

    @objc func multiButtonPressed() {
        let alert = DragDownAlertMenu(title: "Create a new Multireddit", subtitle: "Name your  Multireddit", icon: nil)
        
        alert.addTextInput(title: "Create", icon: UIImage(sfString: SFSymbol.plusCircleFill, overrideString: "add")?.menuIcon(), enabled: true, action: {
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
                        if let parent = self.parent {
                            DispatchQueue.main.async {
                                VCPresenter.presentModally(viewController: ManageMultireddit(multi: multireddit, reloadCallback: {
                                }, dismissCallback: {
                                    Subscriptions.subscribe("/m/" + text, false, session: nil)
                                    self.delegate?.currentAccountViewController(self, goToMultireddit: "/m/" + text)
                                }), parent, nil)
                            }
                        }
                    case .failure:
                        if let parent = self.parent {
                            DispatchQueue.main.async {
                                BannerUtil.makeBanner(text: "Error creating Multireddit, try again later", color: GMColor.red500Color(), seconds: 3, context: parent)
                            }
                        }
                    }
                })
            } catch {
                DispatchQueue.main.async {
                    BannerUtil.makeBanner(text: "Error creating Multireddit, try again later", color: GMColor.red500Color(), seconds: 3, context: self.parent)
                }
            }

        }, inputPlaceholder: "Name...", inputValue: nil, inputIcon: UIImage(named: "wiki")!.menuIcon(), textRequired: true, exitOnAction: false)
        
        if let parent = parent {
            alert.show(parent)
        }
    }

    @objc func modButtonPressed(_ sender: UIButton) {
        let vc = ModerationViewController()
        let navVC = SwipeForwardNavigationController(rootViewController: vc)
        navVC.navigationBar.isTranslucent = false
        parent?.present(navVC, animated: true)
    }
    
    @objc func switchAccountsButtonPressed(_ sender: UIButton) {
        showSwitchAccountsMenu()
    }
    
    @objc func emptyStateLabelTapped() {
        showSwitchAccountsMenu()
    }
}

// MARK: - AccountHeaderViewDelegate
extension CurrentAccountHeaderView: AccountShortcutsViewDelegate {
    func displayMenu(_ menu: DragDownAlertMenu) {
        parent?.present(menu, animated: true, completion: nil)
    }
    
    func didRequestAction(_ action: SettingValues.NavigationHeaderActions) {
        delegate?.currentAccountViewController(self, didRequestAction: action)
    }

    func accountHeaderView(_ view: AccountShortcutsView, didRequestProfilePageAtIndex index: Int) {
        let vc = ProfileViewController(name: AccountController.currentName)
        vc.openTo = index
        let navVC = SwipeForwardNavigationController(rootViewController: vc)
        navVC.navigationBar.isTranslucent = false
        parent?.present(navVC, animated: true)
    }
}

// MARK: - Account Switching
extension CurrentAccountHeaderView {
    func showSwitchAccountsMenu() {
        let optionMenu = DragDownAlertMenu(title: "Accounts", subtitle: "Currently signed in as \(AccountController.isLoggedIn ? AccountController.currentName : "Guest")", icon: nil)

        for accountName in AccountController.names.unique().sorted() {
            if accountName != AccountController.currentName {
                optionMenu.addAction(title: accountName, icon: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon()) {
                    self.setLoadingState(true)
                    self.delegate?.currentAccountViewController(self, didRequestAccountChangeToName: accountName)
                }
            } else {
               // TODO: - enabled
                optionMenu.addAction(title: "\(accountName) (current)", icon: UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon().getCopy(withColor: GMColor.green500Color())) {
                }
            }
        }
        
        if AccountController.isLoggedIn {
            optionMenu.addAction(title: "Browse as Guest", icon: UIImage(sfString: SFSymbol.xmark, overrideString: "hide")!.menuIcon()) {
                self.setEmptyState(true, animate: false)
                self.delegate?.currentAccountViewController(self, didRequestGuestAccount: ())
            }

            optionMenu.addAction(title: "Log out of u/\(AccountController.currentName)", icon: UIImage(sfString: SFSymbol.trashFill, overrideString: "delete")!.menuIcon().getCopy(withColor: GMColor.red500Color())) {
                self.setEmptyState(true, animate: false)
                self.delegate?.currentAccountViewController(self, didRequestLogOut: ())
            }
        }
        
        optionMenu.addAction(title: "Add a new account", icon: UIImage(sfString: SFSymbol.plusCircleFill, overrideString: "add")!.menuIcon().getCopy(withColor: ColorUtil.baseColor)) {
            self.delegate?.currentAccountViewController(self, didRequestNewAccount: ())
        }
        
        parent?.present(optionMenu, animated: true, completion: nil)
    }
}

extension CurrentAccountHeaderView {
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
extension CurrentAccountHeaderView {
    
    override func accessibilityPerformEscape() -> Bool {
        super.accessibilityPerformEscape()
        //TODO go back home
        return true
    }
    
    override var accessibilityViewIsModal: Bool {
        get {
            return true
        }
        set { } // swiftlint:disable:this unused_setter_value
    }
}

protocol AccountShortcutsViewDelegate: AnyObject {
    func accountHeaderView(_ view: AccountShortcutsView, didRequestProfilePageAtIndex index: Int)
    func didRequestAction(_ action: SettingValues.NavigationHeaderActions)
    func displayMenu(_ menu: DragDownAlertMenu)
}

class AccountShortcutsView: UIView {
    
    weak var delegate: AccountShortcutsViewDelegate?
        
    var actions: [SettingValues.NavigationHeaderActions]
    
    init(frame: CGRect, actions: [SettingValues.NavigationHeaderActions]) {
        self.actions = actions
        super.init(frame: frame)
        
        addSubviews(cellStack)
        //infoStack.addArrangedSubviews(commentKarmaLabel, postKarmaLabel)
        for action in actions {
            print(action)
            cellStack.addArrangedSubview(UITableViewCell().then {
                $0.configure(text: action.getTitle(), image: action.getImage())
                $0.addTapGestureRecognizer {
                    self.delegate?.didRequestAction(action)
                }
                $0.heightAnchor >= 50
                $0.accessoryType = .disclosureIndicator
            })
        }
        
        cellStack.addArrangedSubview(UITableViewCell().then {
            $0.configure(text: "More shortcuts", image: UIImage(sfString: SFSymbol.ellipsis, overrideString: "moreh")!.menuIcon())
            $0.addTapGestureRecognizer {
                let optionMenu = DragDownAlertMenu(title: "Slide shortcuts", subtitle: "Displayed shortcuts can be changed in Settings", icon: nil)
                for action in SettingValues.NavigationHeaderActions.cases {
                    optionMenu.addAction(title: action.getTitle(), icon: action.getImage()) {
                        self.delegate?.didRequestAction(action)
                    }
                }
                self.delegate?.displayMenu(optionMenu)
            }
            $0.heightAnchor >= 50
            $0.accessoryType = .disclosureIndicator
        })

        self.clipsToBounds = true
        
        setupAnchors()
    }
    
    var cellStack = UIStackView().then {
        $0.spacing = 2
        $0.axis = .vertical
    }
    
    func estimateHeight() -> CGFloat {
        return CGFloat((actions.count + 1) * 50) + 10 + CGFloat((actions.count + 1) * 2)
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    func setupAnchors() {
        //infoStack.topAnchor == topAnchor
        //infoStack.horizontalAnchors == horizontalAnchors
        
        cellStack.topAnchor == topAnchor + 10
        cellStack.horizontalAnchors == horizontalAnchors
        
        cellStack.bottomAnchor == bottomAnchor
    }
}

public extension UITableView {
    var sectionIndexView: UIView? {
        for view in self.subviews {
            if String(describing: view).contains("UITableViewIndex") {
                return view
            }
        }
        return nil
    }
}
