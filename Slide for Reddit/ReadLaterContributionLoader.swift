//
//  ReadLaterContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/29/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation

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
    var content: [NSManagedObject]
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
                if reload {
                    self.content = []
                }
                try delegate?.session?.getLinksById(Array(ids[self.content.count..<min(self.content.count + 20, ids.count)]), completion: {(result) in
                    switch result {
                    case .failure:
                        self.delegate?.failed(error: result.error!)
                    case .success(let listing):
                        
                        let before = self.content.count
                        let baseContent = listing.children.compactMap({ $0 })
                        for item in baseContent {
                            if item is Link {
                                self.content.append(Submission.linkToSubmission(submission: item as! Link))
                            }
                        }
                        self.canGetMore = self.content.count < self.ids.count
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
