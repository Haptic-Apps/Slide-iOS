//
//  ProgressGalleryViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/16/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import ImageViewer

class ProgressGalleryViewController : GalleryViewController {
    
    var myProgressView: UIProgressView = UIProgressView()

    override func viewDidLoad() {
        super.viewDidLoad()
        myProgressView = UIProgressView(frame: CGRect(x:0, y:view.frame.origin.y, width: UIScreen.main.bounds.width, height:10))
        self.view.addSubview(myProgressView)
    }
    
    func updateProgress(current: NSInteger, total : NSInteger){
        if(myProgressView.isHidden){
            myProgressView.isHidden = false
        }
        let percent  = (Double(current) / Double(total)) * 100
        if(percent == 100){
            myProgressView.isHidden = true
        } else {
            myProgressView.setProgress(Float(percent), animated: true)
        }
    }
}
