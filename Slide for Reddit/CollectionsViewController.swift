//
//  CollectionsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/15/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import UIKit

class CollectionsViewController: TabsContentPagingViewController {
    public init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        self.session = (UIApplication.shared.delegate as! AppDelegate).session

        self.titles = Collections.getAllCollections()
        self.title = "Collections"

        for place in titles {
            vCs.append(ContentListingViewController(dataSource: CollectionsContributionLoader(collectionTitle: place)))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
