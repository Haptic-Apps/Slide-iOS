//
//  GalleryViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/18/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import UIKit

class GalleryTableViewController: MediaTableViewController {
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    var exit: UIView!
    var done = false
    public var blurView: UIVisualEffectView?
    private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()

    var items: [Submission] = []
    
    func setLinks(links: [Submission]) {
        self.items = links
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarUIView?.backgroundColor = .black
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let view = self.view.superview {
            view.addSubview(exit)
            view.bringSubviewToFront(exit)
            exit.bottomAnchor /==/ view.bottomAnchor - 8
            exit.rightAnchor /==/ view.rightAnchor - 8
            exit.widthAnchor /==/ 50
            exit.heightAnchor /==/ 50
            exit.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            
            blurView = UIVisualEffectView(frame: exit.bounds)
            blurEffect.setValue(5, forKeyPath: "blurRadius")
            blurView!.effect = blurEffect
            exit.insertSubview(blurView!, at: 0)
            blurView!.edgeAnchors /==/ exit.edgeAnchors
            
            let image = UIImageView.init(frame: CGRect.init(x: 70, y: 70, width: 0, height: 0)).then {
                $0.image = UIImage(sfString: SFSymbol.xmark, overrideString: "close")?.getCopy(withSize: CGSize.square(size: 30), withColor: .white)
                $0.contentMode = .center
            }
            exit.addSubview(image)
            image.edgeAnchors /==/ exit.edgeAnchors
            exit.addTapGestureRecognizer { (_) in
                self.exit.removeFromSuperview()
                self.doExit()
            }
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.exit.transform = .identity
            }, completion: nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.statusBarUIView?.backgroundColor = .clear
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
        
        exit = UIView.init(frame: CGRect.init(x: 70, y: 70, width: 0, height: 0)).then {
            $0.clipsToBounds = true
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            $0.layer.cornerRadius = 25
        }
    }
    
    func doExit() {
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
        let w = link.imageWidth
        let h = link.imageHeight
        return CGFloat(getHeightFromAspectRatio(imageHeight: h, imageWidth: w))
        
    }
    
    func getHeightFromAspectRatio(imageHeight: Int32, imageWidth: Int32) -> Int {
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
