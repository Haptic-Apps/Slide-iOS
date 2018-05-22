//
//  ContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/4/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import RealmSwift

protocol ContributionLoader {
    
    var paginator: Paginator {get}
    var delegate: ContentListingViewController? {get set}
    func getData(reload: Bool)
    var content: [Object] {get}
    var color: UIColor {get set}
    var paging: Bool {get}
    var canGetMore: Bool {get}
    
    func reset()
    
}
