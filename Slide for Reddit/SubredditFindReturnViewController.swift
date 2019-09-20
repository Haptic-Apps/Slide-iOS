//
//  SubredditFindReturnViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/8/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import AudioToolbox
import reddift
import SDWebImage
import UIKit

class SubredditFindReturnViewController: MediaTableViewController, UISearchBarDelegate, UIGestureRecognizerDelegate {
    
    var baseSubs: [String] = []
    var popular: [String] = []
    var subscribe: Bool

    var filteredContent: [String] = []
    var callback: (_ sub: String) -> Void?
    var includeTrending = false
    var includeCollections = false
    var includeSubscriptions = false

    init(includeSubscriptions: Bool, includeCollections: Bool, includeTrending: Bool, subscribe: Bool, callback: @escaping (_ sub: String) -> Void) {
        self.callback = callback
        self.subscribe = subscribe
        super.init(nibName: nil, bundle: nil)
        self.includeTrending = includeTrending
        self.includeCollections = includeCollections
        self.includeSubscriptions = includeSubscriptions
        
        if includeSubscriptions {
            baseSubs.append(contentsOf: Subscriptions.subreddits)
            if !includeCollections {
                baseSubs = baseSubs.filter({ (sub) -> Bool in
                    let contained = sub != "all" && sub != "frontpage" && sub != "popular" && sub != "random" && sub != "randnsfw" && sub != "friends" && !sub.startsWith("/m/") && !sub.contains("+")
                    return contained
                })
            }
        }
        if includeCollections {
            baseSubs.append(contentsOf: ["all", "friends", "frontpage", "popular", "random", "myrandom", "randnsfw"])
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }
    
    func getTrending() {
        try! (UIApplication.shared.delegate as? AppDelegate)?.session?.getList(Paginator(), subreddit: Subreddit(subreddit: "trendingsubreddits"), sort: LinkSortType.new, timeFilterWithin: TimeFilterWithin.day, completion: { (result) in
            switch result {
            case .success(let data):
                let first = data.children.first as! Link
                let title = first.title
                let split = title.split(" ")
                DispatchQueue.main.async {
                    for sub in split {
                        if sub.startsWith("/r/") {
                            self.popular.append(sub.substring(3, length: sub.length - 4))
                        }
                    }
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        self.automaticallyAdjustsScrollViewInsets = false
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        
        tableView.backgroundColor = ColorUtil.theme.backgroundColor
        tableView.separatorColor = ColorUtil.theme.backgroundColor
        tableView.separatorInset = .zero
        
        tableView.reloadData()
        if includeTrending {
            getTrending()
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! SubredditCellView
        let sub = cell.subreddit
        
        if !subscribe {
            self.navigationController?.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
            self.callback(sub)
            return
        }

        if Subscriptions.isCollection(sub) {
            self.navigationController?.popViewController(animated: true)
            self.callback(sub)
            return
        }
        
        let alrController = DragDownAlertMenu(title: "Follow r/\(sub)", subtitle: "", icon: nil, themeColor: ColorUtil.accentColorForSub(sub: sub), full: true)

        if AccountController.isLoggedIn {
            alrController.addAction(title: "Subscribe", icon: nil) {
                Subscriptions.subscribe(sub, true, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                BannerUtil.makeBanner(text: "Subscribed", seconds: 5, context: self.parent, top: true)
                self.navigationController?.popViewController(animated: true)
                self.callback(sub)
            }
        } else {
            self.navigationController?.popViewController(animated: true)
            self.callback(sub)
            return
        }
        
        alrController.addAction(title: "Casually subscribe", icon: nil) {
            Subscriptions.subscribe(sub, false, session: (UIApplication.shared.delegate as! AppDelegate).session!)
            self.navigationController?.popViewController(animated: true)
            self.callback(sub)
        }
        
        alrController.show(self)
    }
    
    var searchBar: UISearchBar = UISearchBar()
    var isSearching = false
    
    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String) {
        filteredContent = []
        if textSearched.length != 0 {
            isSearching = true
            searchTableList()
        } else {
            isSearching = false
        }
        tableView.reloadData()
        getSuggestions()
    }
    
    var task: URLSessionDataTask?
    func getSuggestions() {
        if task != nil {
            task?.cancel()
        }
        do {
            task = try! (UIApplication.shared.delegate as? AppDelegate)?.session?.getSubredditSearch(searchBar.text!, paginator: Paginator(), completion: { (result) in
                switch result {
                case .success(let subs):
                    for sub in subs.children {
                        self.filteredContent.append((sub as! Subreddit).displayName)
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
        let searchString = searchBar.text
        for s in baseSubs {
            if s.localizedCaseInsensitiveContains(searchString!) {
                filteredContent.append(s)
            }
        }
        
        if searchString != nil && !(searchString?.isEmpty())! {
            for s in Subscriptions.historySubs {
                if s.localizedCaseInsensitiveContains(searchString!) {
                    filteredContent.append(s)
                }
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return popular.isEmpty ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 400.0
        tableView.rowHeight = UITableView.automaticDimension
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none

        self.searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 3, height: 50))
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .none
        searchBar.spellCheckingType = .no
        searchBar.frame.size.height = 50
        searchBar.becomeFirstResponder()
        if !ColorUtil.theme.isLight {
            searchBar.keyboardAppearance = .dark
        }

        tableView.tableHeaderView = searchBar
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        searchBar.searchBarStyle = UISearchBar.Style.minimal
        searchBar.placeholder = " Search for a subreddit"
        searchBar.sizeToFit()
        searchBar.isTranslucent = true
        searchBar.barStyle = .blackTranslucent
        searchBar.delegate = self
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.title = "Search for a Subreddit"
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if isSearching {
                return filteredContent.count
            } else {
                return baseSubs.count
            }
        } else {
            return popular.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 70
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.theme.backgroundColor
        
        switch section {
        case 0: label.text  = "Preview"
        case 1: label.text  = "Trending"
        default: label.text  = ""
        }
        return toReturn
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SubredditCellView?
        if indexPath.section == 0 {
                var thing = ""
                if isSearching {
                    thing = filteredContent[indexPath.row]
                } else {
                    thing = self.baseSubs[indexPath.row]
                }
                let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
                c.setSubreddit(subreddit: thing, nav: nil, exists: true)
                cell = c
        } else {
            let thing = popular[indexPath.row]
            let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
            c.setSubreddit(subreddit: thing, nav: nil, exists: true)
            cell = c
        }
        
        return cell!
    }
    
}
