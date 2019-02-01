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
        self.subs = self.subs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

        pinned.append(contentsOf: Subscriptions.pinned)
        tableView.reloadData()

        let sync = UIButton.init(type: .custom)
        sync.setImage(UIImage.init(named: "sync")!.navIcon(), for: UIControl.State.normal)
        sync.addTarget(self, action: #selector(self.sync(_:)), for: UIControl.Event.touchUpInside)
        sync.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let syncB = UIBarButtonItem.init(customView: sync)

        let add = UIButton.init(type: .custom)
        add.setImage(UIImage.init(named: "add")!.navIcon(), for: UIControl.State.normal)
        add.addTarget(self, action: #selector(self.add(_:)), for: UIControl.Event.touchUpInside)
        add.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let addB = UIBarButtonItem.init(customView: add)

        let delete = UIButton.init(type: .custom)
        delete.setImage(UIImage.init(named: "delete")!.navIcon(), for: UIControl.State.normal)
        delete.addTarget(self, action: #selector(self.remove(_:)), for: UIControl.Event.touchUpInside)
        delete.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let deleteB = UIBarButtonItem.init(customView: delete)

        let pin = UIButton.init(type: .custom)
        pin.setImage(UIImage.init(named: "lock")!.navIcon(), for: UIControl.State.normal)
        pin.addTarget(self, action: #selector(self.pin(_:)), for: UIControl.Event.touchUpInside)
        pin.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let pinB = UIBarButtonItem.init(customView: pin)

        editItems = [deleteB, pinB]
        normalItems = [addB, syncB]

        self.navigationItem.rightBarButtonItems = normalItems

        self.tableView.tableFooterView = UIView()

    }

    @objc func close(_ sender: AnyObject?) {
        self.dismiss(animated: true)
    }

    var delete = UIButton()

    public static var changed = false

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        save(nil)
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func save(_ selector: AnyObject?) {
        SubredditReorderViewController.changed = true
        Subscriptions.setPinned(name: AccountController.currentName, subs: pinned, completion: {
            Subscriptions.set(name: AccountController.currentName, subs: self.subs, completion: {
                self.dismiss(animated: true, completion: nil)
            })
        })
    }

    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = ColorUtil.foregroundColor
    }
    
    @objc func add(_ selector: AnyObject) {
        let searchVC = SubredditFindReturnViewController(includeSubscriptions: false, includeCollections: true, includeTrending: true) { (sub) in
            if !self.subs.contains(sub) {
                self.subs.append(sub)
                self.subs = self.subs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    let indexPath = IndexPath.init(row: self.subs.count - 1, section: 0)
                    self.tableView.scrollToRow(at: indexPath,
                                               at: UITableView.ScrollPosition.top, animated: true)
                }
            }
        }
        VCPresenter.showVC(viewController: searchVC, popupIfPossible: false, parentNavigationController: navigationController, parentViewController: self)
    }
    
    @objc func sync(_ selector: AnyObject) {
        let alertController = UIAlertController(title: nil, message: "Syncing subscriptions...\n\n", preferredStyle: .alert)

        let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
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
            self.subs = self.subs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })
            DispatchQueue.main.async {
                self.tableView.reloadData()
                let indexPath = IndexPath.init(row: end - 1, section: 0)
                self.tableView.scrollToRow(at: indexPath,
                        at: UITableView.ScrollPosition.top, animated: true)
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
        return pinned.isEmpty ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 && pinned.isEmpty ? subs.count : (section == 0 ? pinned.count : subs.count)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thing = indexPath.section == 0 && !self.pinned.isEmpty ? self.pinned[indexPath.row] : subs[indexPath.row]
        var cell: SubredditCellView?
        let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
        c.setSubreddit(subreddit: thing, nav: nil)
        cell = c
        cell?.backgroundColor = ColorUtil.foregroundColor
        let pinned = self.pinned.contains(thing)
        cell?.showPin(pinned)
        cell?.showsReorderControl = pinned
        
        return cell!
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 && !pinned.isEmpty
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        } else {
            return proposedDestinationIndexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove: String = pinned[sourceIndexPath.row]
        pinned.remove(at: sourceIndexPath.row)
        pinned.insert(itemToMove, at: destinationIndexPath.row)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        switch section {
        case 0: label.text = pinned.isEmpty ? "All Subreddits" : "Pinned"
        case 1: label.text =  "All Subreddits"
        default: label.text  = ""
        }
        return toReturn
    }
    
    @objc func pin(_ selector: AnyObject) {
        if let rows = tableView.indexPathsForSelectedRows {
            var pinned2: [String] = []
            var pinned3: [String] = []
            for i in rows {
                print(i)
                if i.section == 1 || pinned.isEmpty {
                    pinned2.append(self.subs[i.row])
                    print("pin \(self.subs[i.row])")
                } else {
                    pinned3.append(self.pinned[i.row])
                    print("Unpin \(self.pinned[i.row])")
                }
            }
            
            //Are all pinned, need to unpin
            self.pinned = self.pinned.filter({ (input) -> Bool in
                return !pinned3.contains(input)
            })

            //Need to pin remaining and move to top
            pinned.append(contentsOf: pinned2)
            tableView.reloadData()
            let indexPath = IndexPath.init(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath,
                    at: UITableView.ScrollPosition.top, animated: true)

            self.navigationItem.setRightBarButtonItems(normalItems, animated: true)
        }
    }

    @objc func remove(_ selector: AnyObject) {
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
            self.navigationItem.setRightBarButtonItems(editItems, animated: true)
        } else {
            self.navigationItem.setRightBarButtonItems(normalItems, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            subs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
