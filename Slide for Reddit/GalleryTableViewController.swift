//
//  GalleryViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/18/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class GalleryTableViewController: MediaTableViewController {
    var panGestureRecognizer: UIPanGestureRecognizer?
    public var background: UIView?
        var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    
    var items: [RSubmission] = []
    
    func setLinks(links: [RSubmission]) {
        self.items = links
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarView?.backgroundColor = .black
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.statusBarView?.backgroundColor = .clear
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func loadView() {
        super.loadView()
        self.tableView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 56, right: 0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(GalleryCellView.classForCoder(), forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = UIColor.black
        self.tableView.separatorStyle = .none
        let exit = UIView.init(frame: CGRect.init(x: 0, y: UIScreen.main.bounds.height - 56, width: self.view.frame.size.width, height: 56))
        exit.backgroundColor = .black

        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close")?.navIcon(), for: UIControlState.normal)
        close.addTarget(self, action: #selector(self.exit), for: UIControlEvents.touchUpInside)
        close.frame = CGRect.init(x: self.view.frame.size.width - 40, y: 13, width: 30, height: 30)

        exit.addSubview(close)
        self.view.addSubview(exit)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        panGestureRecognizer!.direction = .vertical
        view.addGestureRecognizer(panGestureRecognizer!)
        panGestureRecognizer?.require(toFail: tableView.panGestureRecognizer)
        background = UIView()
        background!.frame = self.view.frame
        background!.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        background!.backgroundColor = .black

    }
    
    func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)
        
        if panGesture.state == .began {
            originalPosition = view.center
            currentPositionTouched = panGesture.location(in: view)
        } else if panGesture.state == .changed {
            view.frame.origin = CGPoint(
                x: 0,
                y: translation.y
            )
            let progress = translation.y / (self.view.frame.size.height / 2)
            background!.alpha = 1 - (abs(progress) * 0.9)
            
        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: view)
            
            let down = panGesture.velocity(in: view).y > 0
            if abs(velocity.y) >= 1000 || abs(self.view.frame.origin.y) > self.view.frame.size.height / 2 {
                
                UIView.animate(withDuration: 0.2, animations: {
                        self.view.frame.origin = CGPoint(
                            x: self.view.frame.origin.x,
                            y: self.view.frame.size.height * (down ? 1 : -1) )
                        
                        self.background!.alpha = 0.1
                        
                }, completion: { (isCompleted) in
                    if isCompleted {
                        self.dismiss(animated: false, completion: nil)
                    }
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.center = self.originalPosition!
                    self.background!.alpha = 1
                    
                })
            }
        }
    }

    func exit() {
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let link = items[indexPath.row]
        let w = link.width
        let h = link.height
        return CGFloat(getHeightFromAspectRatio(imageHeight: h, imageWidth: w))
        
    }
    
    func getHeightFromAspectRatio(imageHeight: Int, imageWidth: Int) -> Int {
        let ratio = Double(imageHeight) / Double(imageWidth)
        let width = Double(tableView.frame.size.width)
        return Int(width * ratio)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! GalleryCellView
        cell.setLink(self.items[indexPath.row], parent: self)
        // Configure the cell...

        return cell
    }
}
