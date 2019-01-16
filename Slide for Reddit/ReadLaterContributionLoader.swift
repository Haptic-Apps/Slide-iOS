//
//  ReadLaterContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/29/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation
import RealmSwift
import reddift

class ReadLaterContributionLoader: ContributionLoader {
    func reset() {
        content = []
    }
    
    var color: UIColor
    var canGetMore = true
    var sub: String
    
    init(sub: String) {
        color = ColorUtil.getColorForSub(sub: sub, true)
        paginator = Paginator()
        content = []
        self.sub = sub
    }
    
    var paginator: Paginator
    var content: [Object]
    var delegate: ContentListingViewController?
    var paging = true
    var ids = [Link]()
    
    func getData(reload: Bool) {
        if delegate != nil {
            do {
                if reload || ids.isEmpty {
                    paginator = Paginator()
                    ids = ReadLater.getReadLaterIDs(sub: sub)
                }
                
                try delegate?.session?.getLinksById(ids, completion: {(result) in
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
                            if item is Link {
                                self.content.append(RealmDataWrapper.linkToRSubmission(submission: item as! Link))
                            }
                        }
                        self.canGetMore = listing.paginator.hasMore()
                        self.paginator = listing.paginator
                        DispatchQueue.main.async {
                            self.delegate?.doneLoading(before: before)
                        }
                    }
                })
            } catch {
                print(error)
            }
            
        }
    }
}
