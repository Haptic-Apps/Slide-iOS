//
//  CollectionsContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/15/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Foundation
import RealmSwift
import reddift

class CollectionsContributionLoader: ContributionLoader {
    var color: UIColor = .black
    
    func reset() {
        content = []
    }
    
    var canGetMore = true
    var collectionTitle: String
    
    init(collectionTitle: String) {
        paginator = Paginator()
        content = []
        self.collectionTitle = collectionTitle
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
                    ids = Collections.getCollectionIDs(title: collectionTitle)
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
                                self.content.append(RealmDataWrapper.linkToRSubmission(submission: item as! Link))
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
