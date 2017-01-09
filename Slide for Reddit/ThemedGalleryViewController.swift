//
//  ThemedGalleryViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/5/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import MHVideoPhotoGallery

class ThemedGalleryViewController: MHGalleryController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let customization = MHUICustomization.init()
        customization.barButtonsTintColor = UIColor.white
        customization.setMHGalleryBackgroundColor(UIColor.black, for: .imageViewerNavigationBarHidden)
        customization.setMHGalleryBackgroundColor(UIColor.black, for: .imageViewerNavigationBarShown)
        customization.setMHGalleryBackgroundColor(UIColor.black, for: .overView)
        customization.barStyle = .blackTranslucent
        customization.barTintColor = .black
        customization.barButtonsTintColor = .white
        customization.videoProgressTintColor = ColorUtil.accentColorForSub(sub: "")
        uiCustomization = customization
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        
        self.navigationController?.navigationBar.barTintColor = .black
        navigationBar.barTintColor = .black

        setStatusBarStyle(.lightContent)

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
