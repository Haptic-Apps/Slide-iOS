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
import SideMenu

class SubSidebarViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource {
    weak var tableView: UITableView!
    var subreddit: Subreddit?
    var filteredContent: [String] = []
    var parentController: MediaViewController?

    init(sub: Subreddit, parent: MediaViewController) {
        super.init(nibName: nil, bundle: nil)
        self.subreddit = sub
        self.parentController = parent
    }

    func doSubreddit(sub: Subreddit, _ width: CGFloat) {
        header.setSubreddit(subreddit: sub, parent: self, width)
        print("Height is \(header.getEstHeight())")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let button = UIButtonWithContext.init(type: .custom)
        button.parentController = navigationController!
        button.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        button.setImage(UIImage.init(named: "close")!.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        button.addTarget(self, action: #selector(SubSidebarViewController.close(_:)), for: .touchUpInside)
        let barButton = UIBarButtonItem.init(customView: button)

        navigationItem.leftBarButtonItems = [barButton]
        title = subreddit!.displayName
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: subreddit!.displayName)

        self.view = UITableView(frame: CGRect.zero, style: .plain)
        self.tableView = self.view as! UITableView
        self.tableView.delegate = self
        self.tableView.dataSource = self

        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.separatorColor = ColorUtil.backgroundColor
        tableView.separatorInset = .zero
    }

    func close(_ sender: AnyObject){
        self.dismiss(animated: true)
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

        self.doSubreddit(sub: subreddit!, tableView.frame.size.width)
        header.frame.size.height = header.getEstHeight()

        print(header.frame.size.height)

        print("Estimated height is \(header.getEstHeight())")

        tableView.tableHeaderView = header
        tableView.tableHeaderView!.frame.size = CGSize.init(width: self.tableView.frame.size.width, height: header.getEstHeight())

        print("Height 2 is \(header.frame.size.height)")

    }

    override func viewWillAppear(_ animated: Bool) {
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func reloadData() {
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

}
