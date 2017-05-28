//
//  RelatedContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/20/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import RealmSwift
import PagingMenuController

class RelatedContributionLoader: ContributionLoader {
    var thing: RSubmission
    var sub: String
    var color: UIColor
    var displayMode: MenuItemDisplayMode
    
    init(thing: RSubmission, sub: String){
        self.thing = thing
        self.sub = sub
        color = ColorUtil.getColorForUser(name: sub)
        paginator = Paginator()
        content = []
        displayMode = MenuItemDisplayMode.text(title: MenuItemText.init(text: "Related", color: UIColor.white, selectedColor: UIColor.white, font: UIFont.systemFont(ofSize: 12), selectedFont: UIFont.systemFont(ofSize: 12)))
    }
    
    
    var paginator: Paginator
    var content: [Object]
    var delegate: ContentListingViewController?
    var paging = false
    var canGetMore = false
    
    func getData(reload: Bool) {
        if(delegate != nil){
            do {
                if(reload){
                    paginator = Paginator()
                }
                let id = thing.name
                try delegate?.session?.getDuplicatedArticles(paginator, name: id, completion: { (result) in
                    switch result {
                    case .failure:
                        self.delegate?.failed(error: result.error!)
                    case .success(let listing):
                        
                        if(reload){
                            self.content = []
                        }
                        var baseContent = listing.1.children.flatMap({$0})
                        for item in baseContent {
                            if(item is Comment){
                                self.content.append(RealmDataWrapper.commentToRComment(comment: item as! Comment, depth: 0))
                            } else {
                                self.content.append(RealmDataWrapper.linkToRSubmission(submission: item as! Link))
                            }
                        }

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
