//
//  ReadLaterViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/29/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import reddift
import RLBAlertsPickers
import UIKit

class ReadLaterViewController: ContentListingViewController {
    
    var sub = ""
    init(subreddit: String) {
        super.init(dataSource: ReadLaterContributionLoader(sub: subreddit))
        baseData.delegate = self
        self.title = "Read Later" + subreddit == "all" ? "" : "r/" + subreddit
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
        sub = subreddit
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
