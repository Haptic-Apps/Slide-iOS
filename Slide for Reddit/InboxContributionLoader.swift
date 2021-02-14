//
//  InboxContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/22/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation

import reddift

class InboxContributionLoader: ContributionLoader {
    func reset() {
        content = []
    }

    var color: UIColor = .black
    
    var messages: MessageWhere
    var canGetMore = true
    
    init(whereContent: MessageWhere) {
        paginator = Paginator()
        content = []
        color = ColorUtil.getColorForSub(sub: "")
        messages = whereContent
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
                try delegate?.session?.getMessage(paginator, messages, completion: { (result) in
                    switch result {
                    case .failure(let error):
                        print(error)
                        DispatchQueue.main.async {
                            self.delegate?.doneLoading(before: 0, filter: false)
                        }
                    case .success(let listing):
                        if reload {
                            self.content = []
                        }
                        let before = self.content.count
                        for message in listing.children.compactMap({ $0 }) {
                            self.content.append(MessageObject.messageToMessageObject(message: message as! Message))
                        }
                        self.paginator = listing.paginator
                        self.canGetMore = self.paginator.hasMore()
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
