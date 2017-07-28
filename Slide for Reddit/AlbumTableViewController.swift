//
//  AlbumTableViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/9/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class AlbumTableViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
        
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
    var isTrackingPanLocation = false
    var panGestureRecognizer : UIPanGestureRecognizer!

        var items: [Images] = []
        
        func setImages(images: [Images]){
            self.items = images
            tableView.reloadData()
            var headerHeight: CGFloat = (tableView.frame.size.height - CGFloat(Int(tableView.rowHeight) * tableView.numberOfRows(inSection: 0))) / 2
            if headerHeight > 0 {
                tableView.contentInset = UIEdgeInsetsMake(headerHeight, 0, 0/*-headerHeight*/, 0)
            } else {
                headerHeight = 0
                tableView.contentInset = UIEdgeInsetsMake(headerHeight, 0, 0/*-headerHeight*/, 0)
            }

        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.navigationBar.backgroundColor = .black
            
            
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
    public func panRecognized(_ recognizer:UIPanGestureRecognizer)
    {
        if recognizer.state == .began && tableView.contentOffset.y == 0
        {
            recognizer.setTranslation(CGPoint.zero, in : tableView)
            
            isTrackingPanLocation = true
        }
        else if recognizer.state != .ended && recognizer.state != .cancelled &&
            recognizer.state != .failed && isTrackingPanLocation
        {
            let panOffset = recognizer.translation(in: tableView)
            
            // determine offset of the pan from the start here.
            // When offset is far enough from table view top edge -
            // dismiss your view controller. Additionally you can
            // determine if pan goes in the wrong direction and
            // then reset flag isTrackingPanLocation to false
            
            let eligiblePanOffset = panOffset.y > 200
            if eligiblePanOffset
            {
                recognizer.isEnabled = false
                recognizer.isEnabled = true
                self.dismiss(animated: true, completion: nil)
            }
            
            if panOffset.y < 0
            {
                isTrackingPanLocation = false
            }
        }
        else
        {
            isTrackingPanLocation = false
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith 
        otherGestureRecognizer : UIGestureRecognizer)->Bool
    {
        return true
    }

        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.bounces = false
            
            panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector ( self.panRecognized(_:)))
            panGestureRecognizer.delegate = self
            tableView.addGestureRecognizer(panGestureRecognizer)

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
            cell.setLink(self.items[indexPath.row], parent: self)
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
