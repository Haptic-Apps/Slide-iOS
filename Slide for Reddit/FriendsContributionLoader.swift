//
//  FriendsContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/8/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation
import RealmSwift
import reddift

class FriendsContributionLoader: ContributionLoader {
    var content: [Object]
    
    var color: UIColor
    var canGetMore: Bool
    
    func reset() {
        content = []
    }
    
    init() {
        color = ColorUtil.getColorForUser(name: "")
        paginator = Paginator()
        content = []
        canGetMore = false
    }
    
    var paginator: Paginator
    var delegate: ContentListingViewController?
    var paging = false
    
    func getData(reload: Bool) {
        if delegate != nil && (canGetMore || reload) {
            do {
                if reload {
                    paginator = Paginator()
                }
                try delegate?.session?.getFriends(paginator, limit: 50, completion: { (result) in
                    switch result {
                    case .failure(let error):
                        print(error.localizedDescription)
                    case .success(let listing):
                        if reload {
                            self.content = []
                        }
                        let before = self.content.count
                        for user in listing {
                            self.content.append(RealmDataWrapper.friendToRealm(user: user))
                        }
                        //self.paginator = listing.paginator
                        //self.canGetMore = listing.paginator.hasMore()
                        DispatchQueue.main.async {
                            self.delegate?.doneLoading(before: before, filter: false)
                        }
                    }
                })
            } catch {
                print(error)
            }
            
        }
    }
}
