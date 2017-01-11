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
        subs.append(contentsOf: Subscriptions.subreddits)
        tableView.reloadData()
        
        let save = UIButton.init(type: .custom)
        save.setTitle("Save", for: .normal)
        save.addTarget(self, action: #selector(self.save(_:)), for: UIControlEvents.touchUpInside)
        let saveB = UIBarButtonItem.init(customView: save)
        
        let sync = UIButton.init(type: .custom)
        sync.setImage(UIImage.init(named: "sync"), for: UIControlState.normal)
        sync.addTarget(self, action: #selector(self.sync(_:)), for: UIControlEvents.touchUpInside)
        sync.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let syncB = UIBarButtonItem.init(customView: sync)

        self.navigationItem.rightBarButtonItems = [saveB, syncB]
    }
    public static var changed = false

    func save(_ selector: AnyObject){
        SubredditReorderViewController.changed = true
        Subscriptions.set(name: AccountController.currentName, subs: subs, completion: {
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func sync(_ selector: AnyObject){
        let alertController = UIAlertController(title: nil, message: "Syncing subscriptions...\n\n", preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()
        
        alertController.view.addSubview(spinnerIndicator)
        self.present(alertController,animated: true, completion: nil)
        
        Subscriptions.getSubscriptionsFully(session: (UIApplication.shared.delegate as! AppDelegate).session!, completion: {(newSubs) in
            for s in newSubs {
                if(!self.subs.contains(s.displayName)){
                    self.subs.append(s.displayName)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
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
        return cell!
    }

    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove:String = subs[sourceIndexPath.row]
        subs.remove(at: sourceIndexPath.row)
        subs.insert(itemToMove, at: destinationIndexPath.row)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            subs.remove(at: indexPath.row)
            tableView.reloadData()
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
