//
//  GalleryViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/18/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class GalleryTableViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource {
    
    var items: [RSubmission] = []
    
    func setLinks(links: [RSubmission]){
        self.items = links
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarView?.backgroundColor = .black

        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    var tableView: UITableView = UITableView()
    
    override func loadView() {
        super.loadView()
        self.tableView = UITableView(frame: self.view.frame, style: .plain)
        self.view.addSubview(tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.contentInset = UIEdgeInsets.init(top: 56, left: 0, bottom: 0, right: 0)
    }

    var navItem: UINavigationItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(GalleryCellView.classForCoder(), forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = UIColor.black
        self.tableView.separatorStyle = .none
        let navigationBar = UINavigationBar.init(frame: CGRect.init(x: 0, y: 20, width: self.view.frame.size.width, height: 56))
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = .black

        navItem = UINavigationItem(title: "")
        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close")?.navIcon(), for: UIControlState.normal)
        close.addTarget(self, action: #selector(self.exit), for: UIControlEvents.touchUpInside)
        close.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let closeB = UIBarButtonItem.init(customView: close)
        navItem?.leftBarButtonItem = closeB

        // navItem?.rightBarButtonItem = gridB

        navigationBar.setItems([navItem!], animated: false)
        self.view.addSubview(navigationBar)
    }

    func exit() {
        self.dismiss(animated: true, completion: nil)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let link = items[indexPath.row]
        let w = link.width
        let h = link.height
        return CGFloat(getHeightFromAspectRatio(imageHeight: h, imageWidth: w))

        
    }
    
    func getHeightFromAspectRatio(imageHeight:Int, imageWidth: Int) -> Int {
        let ratio = Double(imageHeight)/Double(imageWidth)
        let width = Double(tableView.frame.size.width);
        return Int(width * ratio)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! GalleryCellView
        cell.setLink(self.items[indexPath.row],  parent: self)
        // Configure the cell...

        return cell
    }

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
