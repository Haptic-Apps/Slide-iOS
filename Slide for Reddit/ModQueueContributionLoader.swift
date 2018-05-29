//
//  ProfileContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/4/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import RealmSwift

class ModQueueContributionLoader: ContributionLoader {
    func reset() {
        content = []
    }
    
    var subreddit: String
    var color: UIColor
    var canGetMore = true

    init(subreddit: String){
        self.subreddit = subreddit
        color = ColorUtil.getColorForSub(sub: "")
        paginator = Paginator()
        content = []
    }
    
    
    var paginator: Paginator
    var content: [Object]
    var delegate: ContentListingViewController?
    var paging = true
    
    func getData(reload: Bool) {
        if(delegate != nil){
            do {
                if(reload){
                    paginator = Paginator()
                }
                try delegate?.session?.getModQueue(paginator, subreddit: Subreddit.init(subreddit: subreddit), completion: { (result) in
                    switch result {
                    case .failure:
                        self.delegate?.failed(error: result.error!)
                    case .success(let listing):

                        if(reload){
                            self.content = []
                        }
                        let baseContent = listing.children.flatMap({$0})
                        for item in baseContent {
                            if(item is Comment){
                                self.content.append(RealmDataWrapper.commentToRComment(comment: item as! Comment, depth: 0))
                            } else {
                                self.content.append(RealmDataWrapper.linkToRSubmission(submission: item as! Link))
                            }
                        }
                        self.paginator = listing.paginator
                        DispatchQueue.main.async{
                            self.delegate?.doneLoading()
                        }
                    }
                })
            } catch {
                print(error)
            }

        }
    }
}
