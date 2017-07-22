//
//  SubredditReorderViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class SubredditReorderViewController: UITableViewController {
    
    var subs: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        self.tableView.isEditing = true
        self.tableView.allowsSelectionDuringEditing = true
        self.tableView.allowsMultipleSelectionDuringEditing = true
        subs.append(contentsOf: Subscriptions.subreddits)
        tableView.reloadData()
        
        let sync = UIButton.init(type: .custom)
        sync.setImage(UIImage.init(named: "sync"), for: UIControlState.normal)
        sync.addTarget(self, action: #selector(self.sync(_:)), for: UIControlEvents.touchUpInside)
        sync.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let syncB = UIBarButtonItem.init(customView: sync)
        
        let top = UIButton.init(type: .custom)
        top.setImage(UIImage.init(named: "upvote"), for: UIControlState.normal)
        top.addTarget(self, action: #selector(self.top(_:)), for: UIControlEvents.touchUpInside)
        top.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let topB = UIBarButtonItem.init(customView: top)
        
        delete = UIButton.init(type: .custom)
        delete.setImage(UIImage.init(named: "delete"), for: UIControlState.normal)
        delete.addTarget(self, action: #selector(self.remove(_:)), for: UIControlEvents.touchUpInside)
        delete.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let deleteB = UIBarButtonItem.init(customView: delete)
        
        let save = UIBarButtonItem.init(title: "Save", style: .done, target: self, action: #selector(self.save(_:)))
        
        self.navigationItem.rightBarButtonItems = [save, syncB, deleteB, topB]
    }
    
    var delete = UIButton()

    public static var changed = false
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    func save(_ selector: AnyObject){
        SubredditReorderViewController.changed = true
        Subscriptions.set(name: AccountController.currentName, subs: subs, completion: {
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = ColorUtil.foregroundColor
    }
    
    func sync(_ selector: AnyObject){
        let alertController = UIAlertController(title: nil, message: "Syncing subscriptions...\n\n", preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()
        
        alertController.view.addSubview(spinnerIndicator)
        self.present(alertController,animated: true, completion: nil)
        
        Subscriptions.getSubscriptionsFully(session: (UIApplication.shared.delegate as! AppDelegate).session!, completion: {(newSubs, newMultis) in
            let end = self.subs.count
            for s in newSubs {
                if(!self.subs.contains(s.displayName)){
                    self.subs.append(s.displayName)
                }
            }
            for m in newMultis {
                if(!self.subs.contains("/m/" + m.displayName)){
                    self.subs.append("/m/" + m.displayName)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                let indexPath = IndexPath.init(row: end, section: 0)
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
        c.setSubreddit(subreddit: thing)
        cell = c
        cell?.backgroundColor = ColorUtil.foregroundColor
        return cell!
    }
    
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove:String = subs[sourceIndexPath.row]
        subs.remove(at: sourceIndexPath.row)
        subs.insert(itemToMove, at: destinationIndexPath.row)
    }
    
    func top(_ selector: AnyObject){
        if let rows = tableView.indexPathsForSelectedRows{
            var top : [String] = []
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
            
        }
    }
    
    func remove(_ selector: AnyObject){
        if let rows = tableView.indexPathsForSelectedRows{

        let actionSheetController: UIAlertController = UIAlertController(title: "Remove subscriptions", message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Remove and unsubscribe", style: .default) { action -> Void in
            //todo unsub
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Just remove", style: .default) { action -> Void in
            var top : [String] = []
            for i in rows {
                top.append(self.subs[i.row])
            }
            self.subs = self.subs.filter({ (input) -> Bool in
                return !top.contains(input)
            })
            self.tableView.reloadData()
            
        }
        actionSheetController.addAction(cancelActionButton)
            actionSheetController.modalPresentationStyle = .popover
            if let presenter = actionSheetController.popoverPresentationController {
                presenter.sourceView = delete
                presenter.sourceRect = delete.bounds
            }

        self.present(actionSheetController, animated: true, completion: nil)
        }

    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       /* deprecated tableView.deselectRow(at: indexPath, animated: true)
        let item = subs[indexPath.row]
        let actionSheetController: UIAlertController = UIAlertController(title: item, message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Unsubscribe", style: .default) { action -> Void in
            //todo unsub
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Move to top", style: .default) { action -> Void in
            self.subs.remove(at: indexPath.row)
            self.subs.insert(item, at: 0)
            tableView.reloadData()
            let indexPath = IndexPath.init(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath,
                                       at: UITableViewScrollPosition.top, animated: true)
            
        }
        actionSheetController.addAction(cancelActionButton)
        
        self.present(actionSheetController, animated: true, completion: nil)*/
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            subs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
    /*
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
     
     // Configure the cell...
     
     return cell
     }
     */
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
