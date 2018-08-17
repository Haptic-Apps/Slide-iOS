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
import SideMenu
import UIKit

import UIKit.UIGestureRecognizerSubclass

class NavigationSidebarViewController: UIViewController, UIGestureRecognizerDelegate {
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var filteredContent: [String] = []
    var suggestions = [String]()
    var parentController: MainViewController?

    var header: NavigationHeaderView = NavigationHeaderView()

    var searchBar: UISearchBar?
    var isSearching = false

    var task: URLSessionDataTask?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        configureLayout()
        configureGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        header.search.becomeFirstResponder()

        // Update any things that can change due to user settings here
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.separatorColor = ColorUtil.backgroundColor
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if !SettingValues.flatMode {
            view.roundCorners([.topLeft, .topRight], radius: 30)
        }
    }

    func configureViews() {

        header.frame.size.height = header.getEstHeight()
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

        view.addSubview(tableView)

        searchBar = header.search
        searchBar?.searchBarStyle = UISearchBarStyle.minimal
        searchBar?.placeholder = " Go to subreddit or profile"
        searchBar?.sizeToFit()
        searchBar?.isTranslucent = true
        searchBar?.barStyle = .blackTranslucent
        searchBar?.delegate = self
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func configureLayout() {
        header.heightAnchor == header.getEstHeight()
        header.horizontalAnchors == view.horizontalAnchors
        header.topAnchor == view.topAnchor

        tableView.topAnchor == view.topAnchor + header.getEstHeight()
        tableView.horizontalAnchors == view.horizontalAnchors
        tableView.bottomAnchor == view.bottomAnchor
    }

    func configureGestures() {
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
    }
    
    func setmail(mailcount: Int) {
        header.setMail(mailcount)
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
}

//// MARK: - Actions
//
//extension NavigationSidebarViewController {
//    @objc func handlePan(_ sender: UIPanGestureRecognizerWithInitialTouch) {
//        // Ignore the gesture if it didn't originate in the draggable area of the view
//        guard header.frame.contains(sender.initialTouchLocation) else {
//            return
//        }
//
//        // Hide the keyboard
//        if header.search.isFirstResponder {
//            header.search.resignFirstResponder()
//        }
//    }
//}

extension NavigationSidebarViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! SubredditCellView
        if !cell.profile.isEmpty() {
            let user = cell.profile
            parentController?.goToUser(profile: user)
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
                return filteredContent.count + (filteredContent.contains(searchBar!.text!) ? 0 : 1) + 1
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
                c.setSubreddit(subreddit: thing, nav: parentController!, exists: false)
                cell = c
            } else if isSearching && indexPath.row == filteredContent.count + 1 {
                let thing = searchBar!.text!
                let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                c.setProfile(profile: thing, nav: parentController!)
                cell = c
            } else {
                var thing = ""
                if isSearching {
                    thing = filteredContent[indexPath.row]
                } else {
                    thing = Subscriptions.subreddits[indexPath.row]
                }
                let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                c.setSubreddit(subreddit: thing, nav: parentController!, exists: true)
                cell = c
            }
        } else {
            let thing = suggestions[indexPath.row]
            let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
            c.setSubreddit(subreddit: thing, nav: parentController!, exists: false)
            cell = c
        }

        cell.backgroundColor = ColorUtil.foregroundColor

        return cell
    }
}

extension NavigationSidebarViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String) {
        filteredContent = []
        suggestions = []
        if textSearched.length != 0 {
            isSearching = true
            searchTableList()
        } else {
            isSearching = false
        }
        tableView.reloadData()
        getSuggestions()

        if textSearched == "uuddlrlrba" {
            UIColor.💀()
        }
    }

    func getSuggestions() {
        if task != nil {
            task?.cancel()
        }
        do {
            task = try! (UIApplication.shared.delegate as? AppDelegate)?.session?.getSubredditSearch(searchBar!.text!, paginator: Paginator(), completion: { (result) in
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
        self.tableView.endEditing(true)
        header.search.resignFirstResponder()
    }

}
