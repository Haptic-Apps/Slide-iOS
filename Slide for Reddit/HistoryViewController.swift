//
//  HistoryViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/14/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import RLBAlertsPickers
import UIKit

class HistoryViewController: ContentListingViewController {
    
    init() {
        let dataSource = HistoryContributionLoader()
        super.init(dataSource: dataSource)
        baseData.delegate = self

        self.title = "History"
        setBarColors(color: ColorUtil.getColorForSub(sub: ""))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
