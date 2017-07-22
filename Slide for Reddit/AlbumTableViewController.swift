//
//  AlbumTableViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/9/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class AlbumTableViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource {
        
    func getAlbum(hash: String){
        let urlString = "http://imgur.com/ajaxalbums/getimages/\(hash)/hit.json?all=true"
        print(urlString)
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "Error loading album...")
            } else {
                do {
                    if(NSString(data: data!, encoding: String.Encoding.utf8.rawValue)?.contains("[]"))!{
                        //single album image
                        self.present(self.getControllerForUrl(baseUrl: URL.init(string: "https://imgur.com/\(hash).png")!)!, animated: true)
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                            return
                        }
                        
                        let album = AlbumJSONBase.init(dictionary: json)
                        DispatchQueue.main.async{
                        self.setImages(images: (album?.data?.images)!)
                    }
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
            
            }.resume()
    }

        var items: [Images] = []
        
        func setImages(images: [Images]){
            self.items = images
            tableView.reloadData()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
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
            self.view = UITableView(frame: CGRect.zero, style: .plain)
            self.tableView = self.view as! UITableView
            self.tableView.delegate = self
            self.tableView.dataSource = self
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            self.tableView.register(AlbumCellView.classForCoder(), forCellReuseIdentifier: "cell")
            self.tableView.backgroundColor = UIColor.black
            self.tableView.separatorStyle = .none
            // Uncomment the following line to preserve selection between presentations
            // self.clearsSelectionOnViewWillAppear = false
            
            // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
            // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
            var t = link.description
            if(t == nil){
                t = ""
            }
            let attr = NSMutableAttributedString(string: t!)
            let font = FontGenerator.fontOfSize(size: 16, submission: false)
            let attr2 = attr.reconstruct(with: font, color: .white, linkColor: ColorUtil.getColorForSub(sub: ""))
            let content = CellContent.init(string:LinkParser.parse(attr2), width:(self.tableView.frame.size.width))
            return CGFloat(getHeightFromAspectRatio(imageHeight: h!, imageWidth: w!)) + content.textHeight + CGFloat(10)
            
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AlbumCellView
            cell.setLink(self.items[indexPath.row], navigationVC: self.navigationController!, parent: self)
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
