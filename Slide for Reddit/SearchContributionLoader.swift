//
//  SearchContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import XLPagerTabStrip

class SearchContributionLoader: ContributionLoader {
    var query: String
    var sub: String
    var color: UIColor
    
    init(query: String, sub: String){
        self.query = query
        self.sub = sub
        color = ColorUtil.getColorForUser(name: sub)
        paginator = Paginator()
        content = []
        indicatorInfo = IndicatorInfo(title: "Searching")
    }
    
    
    var paginator: Paginator
    var content: [Thing]
    var delegate: ContentListingViewController?
    var indicatorInfo: IndicatorInfo
    var paging = false
    
    func getData(reload: Bool) {
        if(delegate != nil){
            do {
                if(reload){
                    paginator = Paginator()
                }
                try delegate?.session?.getSearch(Subreddit.init(subreddit: sub), query: query, paginator: paginator, sort: .relevance, completion: { (result) in
                    switch result {
                    case .failure:
                        self.delegate?.failed(error: result.error!)
                    case .success(let listing):
                        
                        if(reload){
                            self.content = []
                        }
                        self.content += listing.children.flatMap({$0})
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
