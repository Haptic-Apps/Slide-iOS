//
//  RelatedContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/20/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import XLPagerTabStrip

class RelatedContributionLoader: ContributionLoader {
    var thing: Thing
    var sub: String
    var color: UIColor
    
    init(thing: Thing, sub: String){
        self.thing = thing
        self.sub = sub
        color = ColorUtil.getColorForUser(name: sub)
        paginator = Paginator()
        content = []
        indicatorInfo = IndicatorInfo(title: "Related")
    }
    
    
    var paginator: Paginator
    var content: [Thing]
    var delegate: ContentListingViewController?
    var indicatorInfo: IndicatorInfo
    var paging = false
    var canGetMore = false
    
    func getData(reload: Bool) {
        if(delegate != nil){
            do {
                if(reload){
                    paginator = Paginator()
                }
                try delegate?.session?.getDuplicatedArticles(paginator, thing: thing, completion: { (result) in
                    switch result {
                    case .failure:
                        self.delegate?.failed(error: result.error!)
                    case .success(let listing):
                        
                        if(reload){
                            self.content = []
                        }
                        self.content += listing.1.children.flatMap({$0})
                        self.paginator = listing.1.paginator
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
