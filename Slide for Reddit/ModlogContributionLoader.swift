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
    var content: [NSManagedObject]
    var delegate: ContentListingViewController?
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
                                let item = ModlogModel()
                                item.action = thing.action
                                item.created = Date(timeIntervalSince1970: thing.createdUtc)
                                item.details = thing.details
                                item.id = thing.id
                                item.mod = thing.mod
                                item.permalink = thing.targetPermalink
                                item.subreddit = thing.subreddit
                                item.targetAuthor = thing.targetAuthor
                                item.targetBody = thing.targetBody
                                item.targetTitle = thing.targetTitle
                                self.content.append(item)
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
