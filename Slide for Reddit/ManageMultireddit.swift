//
//  ManageMultireddit.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 4/8/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class ManageMultireddit: UITableViewController {
    
    var multi: Multireddit
    var reloadCallback: () -> Void
    
    init(multi: Multireddit, reloadCallback: @escaping () -> Void) {
        self.multi = multi
        self.reloadCallback = reloadCallback
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var subs: [String] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight() && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        self.tableView.isEditing = true
        self.tableView.backgroundColor = ColorUtil.theme.backgroundColor
        
        subs.append(contentsOf: multi.subreddits)
        self.subs = self.subs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
        
        tableView.reloadData()
        
        let add = UIButton.init(type: .custom)
        add.setImage(UIImage.init(named: "add")!.navIcon(), for: UIControl.State.normal)
        add.addTarget(self, action: #selector(self.add(_:)), for: UIControl.Event.touchUpInside)
        add.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let addB = UIBarButtonItem.init(customView: add)
        self.navigationItem.rightBarButtonItem = addB
        
        self.tableView.tableFooterView = UIView()
    }
    
    @objc func close(_ sender: AnyObject?) {
        self.dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reloadCallback()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = ColorUtil.theme.foregroundColor
    }
    
    @objc func add(_ selector: AnyObject) {
        let searchVC = SubredditFindReturnViewController(includeSubscriptions: true, includeCollections: false, includeTrending: false, subscribe: false, callback: { (sub) in
            if !self.subs.contains(sub) {
                self.subs.append(sub)
                self.subs = self.subs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
                
                do {
                    try (UIApplication.shared.delegate as! AppDelegate).session?.addSubredditToMultireddit(self.multi, subredditDisplayName: sub, completion: { (_) in
                        
                    })
                } catch {
                    
                }

                self.tableView.reloadData()
            }
        })
        VCPresenter.showVC(viewController: searchVC, popupIfPossible: false, parentNavigationController: navigationController, parentViewController: self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thing = subs[indexPath.row]
        var cell: SubredditCellView?
        let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
        c.setSubreddit(subreddit: thing, nav: nil)
        cell = c
        cell?.backgroundColor = ColorUtil.theme.foregroundColor
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.separatorStyle = .none
        setupBaseBarColors()
        self.title = "Manage m/" + multi.name
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let sub = subs[indexPath.row]
            subs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            do {
                try (UIApplication.shared.delegate as! AppDelegate).session?.removeSubredditFromMultireddit(multi, subredditDisplayName: sub, completion: { (_) in
                    
                })
            } catch {
                
            }
        }
    }
}
