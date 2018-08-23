//
//  SubredditReorderViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SubredditReorderViewController: UITableViewController {

    var subs: [String] = []
    var pinned: [String] = []
    var editItems: [UIBarButtonItem] = []
    var normalItems: [UIBarButtonItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        self.tableView.isEditing = true
        self.tableView.backgroundColor = ColorUtil.backgroundColor
        self.tableView.allowsSelectionDuringEditing = true
        self.tableView.allowsMultipleSelectionDuringEditing = true
        subs.append(contentsOf: Subscriptions.subreddits)
        pinned.append(contentsOf: Subscriptions.pinned)
        tableView.reloadData()

        let sync = UIButton.init(type: .custom)
        sync.setImage(UIImage.init(named: "sync")!.navIcon(), for: UIControlState.normal)
        sync.addTarget(self, action: #selector(self.sync(_:)), for: UIControlEvents.touchUpInside)
        sync.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let syncB = UIBarButtonItem.init(customView: sync)

        let add = UIButton.init(type: .custom)
        add.setImage(UIImage.init(named: "add")!.navIcon(), for: UIControlState.normal)
        add.addTarget(self, action: #selector(self.add(_:)), for: UIControlEvents.touchUpInside)
        add.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let addB = UIBarButtonItem.init(customView: add)

        let az = UIButton.init(type: .custom)
        az.setImage(UIImage.init(named: "az")!.navIcon(), for: UIControlState.normal)
        az.addTarget(self, action: #selector(self.sortAz(_:)), for: UIControlEvents.touchUpInside)
        az.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let azB = UIBarButtonItem.init(customView: az)

        let top = UIButton.init(type: .custom)
        top.setImage(UIImage.init(named: "upvote")!.navIcon(), for: UIControlState.normal)
        top.addTarget(self, action: #selector(self.top(_:)), for: UIControlEvents.touchUpInside)
        top.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let topB = UIBarButtonItem.init(customView: top)

        let delete = UIButton.init(type: .custom)
        delete.setImage(UIImage.init(named: "delete")!.navIcon(), for: UIControlState.normal)
        delete.addTarget(self, action: #selector(self.remove(_:)), for: UIControlEvents.touchUpInside)
        delete.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let deleteB = UIBarButtonItem.init(customView: delete)

        let pin = UIButton.init(type: .custom)
        pin.setImage(UIImage.init(named: "lock")!.navIcon(), for: UIControlState.normal)
        pin.addTarget(self, action: #selector(self.pin(_:)), for: UIControlEvents.touchUpInside)
        pin.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let pinB = UIBarButtonItem.init(customView: pin)

        editItems = [deleteB, topB, pinB]
        normalItems = [addB, syncB, azB]

        self.navigationItem.rightBarButtonItems = normalItems

        self.tableView.tableFooterView = UIView()

    }

    func close(_ sender: AnyObject?) {
        self.dismiss(animated: true)
    }

    var delete = UIButton()

    public static var changed = false

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        save(nil)
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func save(_ selector: AnyObject?) {
        SubredditReorderViewController.changed = true
        Subscriptions.set(name: AccountController.currentName, subs: subs, completion: {
            self.dismiss(animated: true, completion: nil)
        })
    }

    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = ColorUtil.foregroundColor
    }
    
    func add(_ selector: AnyObject) {
        let searchVC = SubredditFindReturnViewController(includeSubscriptions: false, includeCollections: true, includeTrending: true) { (sub) in
            if !self.subs.contains(sub) {
                self.subs.append(sub)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    let indexPath = IndexPath.init(row: self.subs.count - 1, section: 0)
                    self.tableView.scrollToRow(at: indexPath,
                                               at: UITableViewScrollPosition.top, animated: true)
                }
            }
        }
        VCPresenter.showVC(viewController: searchVC, popupIfPossible: false, parentNavigationController: navigationController, parentViewController: self)
    }
    
    func sync(_ selector: AnyObject) {
        let alertController = UIAlertController(title: nil, message: "Syncing subscriptions...\n\n", preferredStyle: .alert)

        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()

        alertController.view.addSubview(spinnerIndicator)
        self.present(alertController, animated: true, completion: nil)

        Subscriptions.getSubscriptionsFully(session: (UIApplication.shared.delegate as! AppDelegate).session!, completion: { (newSubs, newMultis) in
            let end = self.subs.count
            for s in newSubs {
                if !self.subs.contains(s.displayName) {
                    self.subs.append(s.displayName)
                }
            }
            for m in newMultis {
                if !self.subs.contains("/m/" + m.displayName) {
                    self.subs.append("/m/" + m.displayName)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                let indexPath = IndexPath.init(row: end - 1, section: 0)
                self.tableView.scrollToRow(at: indexPath,
                        at: UITableViewScrollPosition.top, animated: true)
                alertController.dismiss(animated: true, completion: nil)
            }
        })

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: – Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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
        cell?.backgroundColor = ColorUtil.foregroundColor
        cell?.showPin(pinned.contains(thing))
        return cell!
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    var stuck: [String] = []

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return !stuck.contains(subs[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove: String = subs[sourceIndexPath.row]
        subs.remove(at: sourceIndexPath.row)
        subs.insert(itemToMove, at: destinationIndexPath.row)
    }

    func top(_ selector: AnyObject) {
        if let rows = tableView.indexPathsForSelectedRows {
            var top: [String] = []
            for i in rows {
                top.append(self.subs[i.row])
                self.tableView.deselectRow(at: i, animated: true)
            }
            self.subs = self.subs.filter({ (input) -> Bool in
                return !top.contains(input)
            })
            self.subs.insert(contentsOf: top, at: 0)
            tableView.reloadData()
            let indexPath = IndexPath.init(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath,
                    at: UITableViewScrollPosition.top, animated: true)
            self.navigationItem.setRightBarButtonItems(normalItems, animated: true)

        }
    }

    func pin(_ selector: AnyObject) {
        if let rows = tableView.indexPathsForSelectedRows {
            var pinned2: [String] = []
            var pinned3: [String] = []
            for i in rows {
                if !pinned.contains(self.subs[i.row]) {
                    pinned2.append(self.subs[i.row])
                } else {
                    pinned3.append(self.subs[i.row])
                }
            }
            if pinned2.isEmpty {
                //Are all pinned, need to unpin
                self.pinned = self.pinned.filter({ (input) -> Bool in
                    return !pinned3.contains(input)
                })
                tableView.reloadData()
                //todo saved pin
            } else {
                //Need to pin remaining and move to top
                pinned.append(contentsOf: pinned2)
                self.subs = self.subs.filter({ (input) -> Bool in
                    return !pinned.contains(input)
                })
                self.subs.insert(contentsOf: pinned, at: 0)
                tableView.reloadData()
                let indexPath = IndexPath.init(row: 0, section: 0)
                self.tableView.scrollToRow(at: indexPath,
                        at: UITableViewScrollPosition.top, animated: true)
                //todo saved pin
            }

            SubredditReorderViewController.changed = true
            Subscriptions.setPinned(name: AccountController.currentName, subs: pinned, completion: {
            })
            self.navigationItem.setRightBarButtonItems(normalItems, animated: true)

        }
    }

    func sortAz(_ selector: AnyObject) {
        self.subs = self.subs.filter({ (input) -> Bool in
            return !pinned.contains(input)
        })
        self.subs = self.subs.sorted() {
            $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
        }
        self.subs.insert(contentsOf: pinned, at: 0)
        if self.subs.contains("all") {
            self.subs.remove(at: self.subs.index(of: "all")!)
            self.subs.insert("all", at: 0)
        }
        if self.subs.contains("popular") {
            self.subs.remove(at: self.subs.index(of: "popular")!)
            self.subs.insert("popular", at: 0)
        }
        if self.subs.contains("frontpage") {
            self.subs.remove(at: self.subs.index(of: "frontpage")!)
            self.subs.insert("frontpage", at: 0)
        }

        tableView.reloadData()
        let indexPath = IndexPath.init(row: 0, section: 0)
        self.tableView.scrollToRow(at: indexPath,
                at: UITableViewScrollPosition.top, animated: true)
    }

    func remove(_ selector: AnyObject) {
        if let rows = tableView.indexPathsForSelectedRows {

            let actionSheetController: UIAlertController = UIAlertController(title: "Remove subscriptions", message: "", preferredStyle: .alert)

            var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)

            if AccountController.isLoggedIn {
                cancelActionButton = UIAlertAction(title: "Remove and unsubscribe", style: .default) { _ -> Void in
                    //todo unsub
                    var top: [String] = []
                    for i in rows {
                        top.append(self.subs[i.row])
                    }
                    self.subs = self.subs.filter({ (input) -> Bool in
                        return !top.contains(input)
                    })
                    self.tableView.reloadData()
                    self.navigationItem.setRightBarButtonItems(self.normalItems, animated: true)
                    
                    for sub in top {
                        do {
                            try (UIApplication.shared.delegate as! AppDelegate).session?.setSubscribeSubreddit(Subreddit.init(subreddit: sub), subscribe: false, completion: { (_) in
                                
                            })
                        } catch {
                            
                        }
                    }
                }
                actionSheetController.addAction(cancelActionButton)
            }

            cancelActionButton = UIAlertAction(title: "Just remove", style: .default) { _ -> Void in
                var top: [String] = []
                for i in rows {
                    top.append(self.subs[i.row])
                }
                self.subs = self.subs.filter({ (input) -> Bool in
                    return !top.contains(input)
                })
                self.tableView.reloadData()
                self.navigationItem.setRightBarButtonItems(self.normalItems, animated: true)

            }
            actionSheetController.addAction(cancelActionButton)
            self.present(actionSheetController, animated: true, completion: nil)
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.separatorStyle = .none
        setupBaseBarColors()
        self.title = "Manage subscriptions"
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.indexPathsForSelectedRows != nil && !tableView.indexPathsForSelectedRows!.isEmpty {
            self.navigationItem.setRightBarButtonItems(editItems, animated: true)
        } else {
            self.navigationItem.setRightBarButtonItems(normalItems, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !tableView.indexPathsForSelectedRows!.isEmpty {
            print(tableView.indexPathsForSelectedRows!.count)
            self.navigationItem.setRightBarButtonItems(editItems, animated: true)
        } else {
            self.navigationItem.setRightBarButtonItems(normalItems, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            subs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
