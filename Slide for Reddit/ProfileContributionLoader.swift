//
//  ProfileContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/4/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation

import reddift

class ProfileContributionLoader: ContributionLoader {
    func reset() {
        content = []
    }
    
    var name: String
    var userContent: UserContent
    var color: UIColor
    var canGetMore = true

    init(name: String, whereContent: UserContent) {
        self.name = name
        color = ColorUtil.getColorForUser(name: name)
        paginator = Paginator()
        content = []
        userContent = whereContent
    }
    
    var paginator: Paginator
    var content: [RedditObject]
    var delegate: ContentListingViewController?
    var paging = true
    
    func getData(reload: Bool) {
        if delegate != nil {
            do {
                if reload {
                    paginator = Paginator()
                }
                try delegate?.session?.getUserContent(name, content: userContent, sort: (delegate?.userSort)!, timeFilterWithin: (delegate?.time)!, paginator: paginator, completion: { (result) in
                    switch result {
                    case .failure:
                        self.delegate?.failed(error: result.error!)
                    case .success(let listing):

                        if reload {
                            self.content = []
                        }
                        let before = self.content.count
                        let baseContent = listing.children.compactMap({ $0 })
                        for item in baseContent {
                            if item is Comment {
                                self.content.append(CommentObject.commentToCommentObject(comment: item as! Comment, depth: 0))
                            } else {
                                self.content.append(SubmissionObject.linkToSubmissionObject(submission: item as! Link))
                            }
                        }
                        self.canGetMore = listing.paginator.hasMore()
                        self.paginator = listing.paginator
                        DispatchQueue.main.async {
                            self.delegate?.doneLoading(before: before, filter: AccountController.currentName.lowercased() != self.name.lowercased())
                        }
                    }
                })
            } catch {
                print(error)
            }

        }
    }
}
