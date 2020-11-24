//
//  ModerationOverviewViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 11/16/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import RealmSwift
import reddift
import UIKit
import UserNotifications

class ModerationOverviewViewController: UITableViewController {
    
    var subs: [String]
    
    init() {
        self.subs = ["All moderated subs"]
        self.subs.append(contentsOf: AccountController.modSubs)
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = ColorUtil.theme.backgroundColor

        self.title = "Subs you Moderate"
        self.tableView.separatorStyle = .none
        
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sub") as? SubredditCellView
        cell?.setSubreddit(subreddit: subs[indexPath.row], nav: self.navigationController)
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ModerationViewController(indexPath.row == 0 ? "mod" : subs[indexPath.row])
        VCPresenter.showVC(viewController: vc, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return self.subs.count //+ 1
        default: fatalError("Unknown number of sections")
        }
    }
    
}
