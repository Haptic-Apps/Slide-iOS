//
//  SubSidebarViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import ChameleonFramework
import SideMenu

class SubSidebarViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    weak var tableView : UITableView!
    var subreddit: Subreddit?
    var filteredContent: [String] = []
    var parentController: SubredditLinkViewController?
    
    init(parentController: SubredditLinkViewController, sub: String, completion: @escaping (Bool) -> Void){
        self.parentController = parentController
        super.init(nibName: nil, bundle:  nil)
        do {
        try (UIApplication.shared.delegate as! AppDelegate).session?.about(sub, completion: { (result) in
            switch result {
            case .failure:
                completion(false)
            case .success(let r):
                DispatchQueue.main.async{
                    self.doSubreddit(sub: r)
                }
                completion(true)
            }
        })
        } catch {
            completion(false)
        }
    }
    
    func doSubreddit(sub: Subreddit){
        header.setSubreddit(subreddit: sub, parent: parentController!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView(){
        self.view = UITableView(frame: CGRect.zero, style: .plain)
        self.tableView = self.view as! UITableView
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.separatorColor = ColorUtil.backgroundColor
        tableView.separatorInset = .zero
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    var header: SubredditHeaderView = SubredditHeaderView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 400.0
        tableView.rowHeight = UITableViewAutomaticDimension
        header.frame.size.height = header.getEstHeight()
        tableView.tableHeaderView = header
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
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
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
}
