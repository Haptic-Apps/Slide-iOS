//
//  SearchContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import RealmSwift
import PagingMenuController

class SearchContributionLoader: ContributionLoader {
    var displayMode: MenuItemDisplayMode

    var query: String
    var sub: String
    var color: UIColor
    var canGetMore = true
    
    init(query: String, sub: String){
        self.query = query
        self.sub = sub
        color = ColorUtil.getColorForUser(name: sub)
        paginator = Paginator()
        content = []
        displayMode = MenuItemDisplayMode.text(title: MenuItemText.init(text: "Searching", color: UIColor.white, selectedColor: UIColor.white, font: UIFont.systemFont(ofSize: 12), selectedFont: UIFont.systemFont(ofSize: 12)))
    }
    
    
    var paginator: Paginator
    var content: [Object]
    var delegate: ContentListingViewController?
    var paging = false
    
    func getData(reload: Bool) {
        if(delegate != nil){
            do {
                if(reload){
                    paginator = Paginator()
                }
                print("Subreddit is \(sub)")
                try delegate?.session?.getSearch(Subreddit.init(subreddit: sub), query: query, paginator: paginator, sort: .relevance, completion: { (result) in
                    switch result {
                    case .failure:
                        print(result.error!)
                        self.delegate?.failed(error: result.error!)
                    case .success(let listing):
                        if(reload){
                            self.content = []
                        }
                        for item in listing.children.flatMap({$0}) {
                            print("Item")
                            if(item is Comment){
                                self.content.append(RealmDataWrapper.commentToRComment(comment: item as! Comment, depth: 0))
                            } else {
                                self.content.append(RealmDataWrapper.linkToRSubmission(submission: item as! Link))
                            }
                        }
                        print("Done")
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
