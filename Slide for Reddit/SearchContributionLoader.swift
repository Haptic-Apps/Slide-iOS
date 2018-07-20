//
//  SearchContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import RealmSwift
import reddift

class SearchContributionLoader: ContributionLoader {
    func reset() {
        content = []
    }

    var query: String
    var sub: String
    var color: UIColor
    var canGetMore = true
    var sorting: SearchSortBy = .relevance
    var time: SearchTimePeriod = .all

    init(query: String, sub: String) {
        self.query = query
        self.sub = sub
        color = ColorUtil.getColorForUser(name: sub)
        paginator = Paginator()
        content = []
    }
    
    var paginator: Paginator
    var content: [Object]
    var delegate: ContentListingViewController?
    var paging = false
    
    func getData(reload: Bool) {
        if delegate != nil && canGetMore {
            do {
                if reload {
                    paginator = Paginator()
                }
                try delegate?.session?.getSearch(Subreddit.init(subreddit: sub), query: query, paginator: paginator, sort: sorting, time: time, completion: { (result) in
                    switch result {
                    case .failure:
                        print(result.error!)
                        self.delegate?.failed(error: result.error!)
                    case .success(let listing):
                        if reload {
                            self.content = []
                        }
                        for item in listing.children.flatMap({ $0 }) {
                            if item is Comment {
                                self.content.append(RealmDataWrapper.commentToRComment(comment: item as! Comment, depth: 0))
                            }
                            else {
                                self.content.append(RealmDataWrapper.linkToRSubmission(submission: item as! Link))
                            }
                        }
                        self.paginator = listing.paginator
                        self.canGetMore = listing.paginator.hasMore()
                        DispatchQueue.main.async {
                            self.delegate?.doneLoading()
                        }
                    }
                })
            }
            catch {
                print(error)
            }
            
        }
    }
}
