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
    var pinnedItems: [UIBarButtonItem] = []
    
    private var selectedRows: [IndexPath] {
        return tableView.indexPathsForSelectedRows ?? []
    }
    
    private var selectedSubRows: [IndexPath] {
        return selectedRows.filter { indexPath in
            if self.pinned.isEmpty {
                return indexPath.section == 0
            } else {
                return indexPath.section == 1
            }
        }
    }
    
    private var selectedPinnedRows: [IndexPath] {
        return selectedRows.filter { indexPath in
            if self.pinned.isEmpty {
                return false
            } else {
                return indexPath.section == 0
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        self.tableView.isEditing = true
        self.tableView.backgroundColor = ColorUtil.theme.backgroundColor
        self.tableView.allowsSelectionDuringEditing = true
        self.tableView.allowsMultipleSelectionDuringEditing = true
        
        subs.append(contentsOf: Subscriptions.subreddits)
        self.subs = self.subs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

        pinned.append(contentsOf: Subscriptions.pinned)
        tableView.reloadData()

        let sync = UIButton.init(type: .custom)
        sync.setImage(UIImage(sfString: SFSymbol.arrow2Circlepath, overrideString: "sync")!.navIcon(), for: UIControl.State.normal)
        sync.addTarget(self, action: #selector(self.sync(_:)), for: UIControl.Event.touchUpInside)
        sync.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let syncB = UIBarButtonItem.init(customView: sync)

        let add = UIButton.init(type: .custom)
        add.setImage(UIImage(sfString: SFSymbol.plusCircleFill, overrideString: "add")!.navIcon(), for: UIControl.State.normal)
        add.addTarget(self, action: #selector(self.add(_:)), for: UIControl.Event.touchUpInside)
        add.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let addB = UIBarButtonItem.init(customView: add)

        let delete = UIButton.init(type: .custom)
        delete.setImage(UIImage(sfString: SFSymbol.trashFill, overrideString: "delete")!.navIcon(), for: UIControl.State.normal)
        delete.addTarget(self, action: #selector(self.remove(_:)), for: UIControl.Event.touchUpInside)
        delete.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let deleteB = UIBarButtonItem.init(customView: delete)

        let pin = UIButton.init(type: .custom)
        pin.setImage(UIImage(sfString: SFSymbol.pinFill, overrideString: "lock")!.navIcon(), for: UIControl.State.normal)
        pin.addTarget(self, action: #selector(self.pin(_:)), for: UIControl.Event.touchUpInside)
        pin.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let pinB = UIBarButtonItem.init(customView: pin)

        editItems = [deleteB, pinB]
        normalItems = [addB, syncB]
        pinnedItems = [pinB]

        self.navigationItem.rightBarButtonItems = normalItems

        self.tableView.tableFooterView = UIView()
        if #available(iOS 13, *) {
            self.isModalInPresentation = true
        }
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
        if let nav = self.navigationController as? SwipeForwardNavigationController {
            nav.fullWidthBackGestureRecognizer.isEnabled = true
        }
        if #available(iOS 13, *) {
            self.isModalInPresentation = false
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func save(_ selector: AnyObject?) {
        SubredditReorderViewController.changed = true
        Subscriptions.setPinned(name: AccountController.currentName, subs: pinned, completion: {
            Subscriptions.set(name: AccountController.currentName, subs: self.subs, completion: {
            })
        })
    }

    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = ColorUtil.theme.foregroundColor
    }
    
    @objc func add(_ selector: AnyObject) {
        let searchVC = SubredditFindReturnViewController(includeSubscriptions: false, includeCollections: true, includeTrending: true, subscribe: true, callback: { (sub) in
            if !self.subs.contains(sub) {
                self.subs.append(sub)
                self.subs = self.subs.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending })

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    let indexPath = IndexPath.init(row: self.subs.indexes(of: sub), section: self.pinned.isEmpty ? 0 : 1)
                    self.tableView.scrollToRow(at: indexPath,
                                               at: UITableView.ScrollPosition.top, animated: true)
                }
            }
        })
        VCPresenter.showVC(viewController: searchVC, popupIfPossible: false, parentNavigationController: navigationController, parentViewController: self)
    }
    
    @objc func sync(_ selector: AnyObject) {
        let alertController = UIAlertController(title: "Syncing subscriptions...\n\n\n", message: nil, preferredStyle: .alert)

        let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = ColorUtil.theme.fontColor
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
                let indexPath = IndexPath.init(row: end - 1, section: self.pinned.isEmpty ? 0 : 1)
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
        cell?.backgroundColor = ColorUtil.theme.foregroundColor
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
        toReturn.backgroundColor = ColorUtil.theme.backgroundColor
        switch section {
        case 0: label.text = pinned.isEmpty ? "All Subreddits" : "Pinned"
        case 1: label.text =  "All Subreddits"
        default: label.text  = ""
        }
        return toReturn
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }

    @objc func pin(_ selector: AnyObject) {
        guard !selectedRows.isEmpty else {
            return
        }
        
        // Need to use copy and not modify the original
        // until after we decide what to pin or unpin
        var newPins = pinned
        
        for i in selectedPinnedRows {
            print("Unpin \(pinned[i.row])")
            newPins.remove(at: i.row)
        }
        
        for i in selectedSubRows {
            print("Pin \(subs[i.row])")
            newPins.append(subs[i.row])
        }
        
        // Prevents duplicate pins, which causes problems elsewhere in the app
        pinned = newPins.unique()
    
        tableView.reloadData()
        let indexPath = IndexPath.init(row: 0, section: 0)
        self.tableView.scrollToRow(at: indexPath,
                at: UITableView.ScrollPosition.top, animated: true)

        self.navigationItem.setRightBarButtonItems(normalItems, animated: true)
    }

    @objc func remove(_ selector: AnyObject) {
        guard !selectedSubRows.isEmpty else {
            return
        }
    
        let actionSheetController: UIAlertController = UIAlertController(title: "Remove subscriptions", message: "", preferredStyle: .alert)

        actionSheetController.addCancelButton()
        var cancelActionButton = UIAlertAction()

        if AccountController.isLoggedIn {
            cancelActionButton = UIAlertAction(title: "Remove and unsubscribe", style: .default) { _ -> Void in
               // TODO: - unsub
                var top: [String] = []
                for i in self.selectedSubRows {
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
            for i in self.selectedSubRows {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.separatorStyle = .none
        setupBaseBarColors()
        self.title = "Manage subscriptions"
        if let nav = self.navigationController as? SwipeForwardNavigationController {
            nav.fullWidthBackGestureRecognizer.isEnabled = false
        }
    }
    
    private func refreshListActionButtons() {
        guard !selectedRows.isEmpty else {
            self.navigationItem.setRightBarButtonItems(normalItems, animated: true)
            return
        }
        
        if !selectedPinnedRows.isEmpty && selectedSubRows.isEmpty {
            self.navigationItem.setRightBarButtonItems(pinnedItems, animated: true)
        } else {
            self.navigationItem.setRightBarButtonItems(editItems, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        refreshListActionButtons()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        refreshListActionButtons()
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            subs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
