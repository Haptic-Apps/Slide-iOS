//
//  RelatedViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/20/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class RelatedViewController: ContentListingViewController {
    
    init(thing: Link){
        super.init(dataSource: RelatedContributionLoader.init(thing: thing, sub: thing.subreddit))
        baseData.delegate = self
        self.title = "Other discussions"
        setBarColors(color: ColorUtil.getColorForSub(sub: thing.subreddit))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
