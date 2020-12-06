//
//  RelatedContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/20/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import RealmSwift
import reddift

class RelatedContributionLoader: ContributionLoader {
    func reset() {
        content = []
    }
    
    var thing: Submission
    var sub: String
    var color: UIColor
    
    init(thing: Submission, sub: String) {
        self.thing = thing
        self.sub = sub
        color = ColorUtil.getColorForUser(name: sub)
        paginator = Paginator()
        content = []
    }
    
    var paginator: Paginator
    var content: [Object]
    var delegate: ContentListingViewController?
    var paging = false
    var canGetMore = false
    
    func getData(reload: Bool) {
        if delegate != nil {
            do {
                if reload {
                    paginator = Paginator()
                }
                let id = thing.name
                try delegate?.session?.getDuplicatedArticles(paginator, name: id, completion: { (result) in
                    switch result {
                    case .failure:
                        self.delegate?.failed(error: result.error!)
                    case .success(let listing):
                        
                        if reload {
                            self.content = []
                        }
                        let before = self.content.count
                        let baseContent = listing.1.children.compactMap({ $0 })
                        for item in baseContent {
                            if item is Comment {
                                self.content.append(RealmDataWrapper.commentToRComment(comment: item as! Comment, depth: 0))
                            } else {
                                self.content.append(RealmDataWrapper.linkToSubmission(submission: item as! Link))
                            }
                        }

                        self.paginator = listing.1.paginator
                        DispatchQueue.main.async {
                            self.delegate?.doneLoading(before: before, filter: true)
                        }
                    }
                })
            } catch {
                print(error)
            }
            
        }
    }
}
