//
//  ViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/6/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import SideMenu
import AudioToolbox

class NavigationSidebarViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIGestureRecognizerDelegate{
    weak var tableView : UITableView!
    var filteredContent: [String] = []
    var parentController: MainViewController?
    
    func setViewController(controller: MainViewController){
        parentController = controller
    }
    
    override func loadView(){
        self.view = UITableView(frame: CGRect.zero, style: .plain)
        self.tableView = self.view as! UITableView
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")

        
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.separatorColor = ColorUtil.backgroundColor
        tableView.separatorInset = .zero

        tableView.layer.cornerRadius = 15
        tableView.clipsToBounds = true

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! SubredditCellView
        let sub = cell.subreddit
        parentController?.goToSubreddit(subreddit: sub)
        searchBar?.text = ""
        filteredContent = []
        isSearching = false
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    var searchBar:UISearchBar?
    var isSearching  = false
    
    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String)
    {
        filteredContent = []
        if(textSearched.length != 0) {
            isSearching = true
            searchTableList()
        }
        else {
            isSearching = false
        }
        tableView.reloadData()
    }
    
    func searchTableList(){
        let searchString = searchBar?.text
        for s in Subscriptions.subreddits {
            if (s.localizedCaseInsensitiveContains(searchString!)) {
                filteredContent.append(s)
            }
        }
        
        if(searchString != nil && !(searchString?.isEmpty())!){
            for s in Subscriptions.historySubs {
                if (s.localizedCaseInsensitiveContains(searchString!)) {
                    filteredContent.append(s)
                }
            }
        }
        if(!filteredContent.contains(searchString!)){
            filteredContent.append(searchString!)
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    var header: NavigationHeaderView = NavigationHeaderView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 400.0
        tableView.rowHeight = UITableViewAutomaticDimension
        header.frame.size.height = header.getEstHeight()
        tableView.tableHeaderView = header
        tableView.contentInset = UIEdgeInsetsMake(0, 0, header.getEstHeight(), 0)
        
        searchBar = header.search
        searchBar?.searchBarStyle = UISearchBarStyle.minimal
        searchBar?.placeholder = " Go to subreddit"
        searchBar?.sizeToFit()
        searchBar?.isTranslucent = true
        searchBar?.barStyle = .blackTranslucent
        searchBar?.delegate = self
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func setSubreddit(subreddit: String){
        header.setSubreddit(subreddit: subreddit, parent: self)
        header.frame.size.height = header.getEstHeight()
    }
    
    func setmail(mailcount: Int){
        header.setMail(mailcount)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadData(){
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(isSearching){
            return filteredContent.count
        } else {
            return Subscriptions.subreddits.count
        }
    }
      
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var thing = ""
        if(isSearching){
            thing = filteredContent[indexPath.row]
        } else {
            thing = Subscriptions.subreddits[indexPath.row]
        }
        var cell: SubredditCellView?
        let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
        c.setSubreddit(subreddit: thing, nav: parentController!)
        cell = c
    
        return cell!
    }
    
}
