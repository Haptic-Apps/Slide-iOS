//
//  ModlogContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 11/16/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation

import reddift

class ModlogContributionLoader: ContributionLoader {
    func reset() {
        content = []
    }
    
    var subreddit: String
    var color: UIColor
    var canGetMore = true

    init(subreddit: String) {
        self.subreddit = subreddit
        color = ColorUtil.getColorForSub(sub: "")
        paginator = Paginator()
        content = []
    }
    
    var paginator: Paginator
    var content: [RedditObject]
    weak var delegate: ContentListingViewController?
    var paging = true
    
    func getData(reload: Bool) {
        if delegate != nil {
            do {
                if reload {
                    paginator = Paginator()
                }
                try delegate?.session?.getModLog(paginator, subreddit: Subreddit.init(subreddit: subreddit), completion: { (result) in
                    switch result {
                    case .failure(let error):
                        print(error)
                        self.delegate?.failed(error: error)
                    case.success(let listing):
                        let before = self.content.count

                        listing.children.forEach { (thing) in
                            if let thing = thing as? ModAction {
                                self.content.append(ModLogObject.modActionToModLogObject(thing: thing))
                            }
                        }
                        self.paginator = listing.paginator
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
