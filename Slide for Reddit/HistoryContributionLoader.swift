//
//  HistoryContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/14/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import RealmSwift
import reddift

class HistoryContributionLoader: ContributionLoader {
    func reset() {
        content = []
    }
    
    var color: UIColor
    var canGetMore = true
    
    init() {
        color = ColorUtil.getColorForSub(sub: "", true)
        paginator = Paginator()
        content = []
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
                    let allKeys = History.seenTimes.keysSortedByValue {
                        if ($0 as? Double ?? 0) < ($1 as? Double ?? 0) {
                            return .orderedDescending
                        } else {
                            return .orderedAscending
                        }
                    }

                    ids = allKeys.map({ (link) -> Link in
                        var id = link as? String ?? ""
                        if id.contains("_") {
                            id = id.substring(3, length: id.length - 3)
                        }
                        print(id)
                        return Link(id: id)
                    })
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
                                if !(item as! Link).over18 || SettingValues.saveNSFWHistory {
                                    self.content.append(RealmDataWrapper.linkToRSubmission(submission: item as! Link))
                                }
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
