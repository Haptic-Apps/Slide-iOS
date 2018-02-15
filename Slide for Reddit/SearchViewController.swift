//
//  SearchViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class SearchViewController: ContentListingViewController {
    
    init(subreddit: String, searchFor: String){
        super.init(dataSource: SearchContributionLoader.init(query: searchFor, sub: subreddit))
        baseData.delegate = self
        self.title = searchFor
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
