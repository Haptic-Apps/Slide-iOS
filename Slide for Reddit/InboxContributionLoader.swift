//
//  InboxContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/22/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import XLPagerTabStrip

class InboxContributionLoader: ContributionLoader {
    var color: UIColor
    
    var messages: MessageWhere
    var canGetMore = true
    
    init(whereContent: MessageWhere){
        paginator = Paginator()
        content = []
        color = ColorUtil.getColorForSub(sub: "")
        messages = whereContent
        indicatorInfo = IndicatorInfo(title: whereContent.description)
    }
    
    
    var paginator: Paginator
    var content: [Thing]
    var delegate: ContentListingViewController?
    var indicatorInfo: IndicatorInfo
    var paging = true
    
    func getData(reload: Bool) {
        if(delegate != nil){
            do {
                if(reload){
                    paginator = Paginator()
                }
                try delegate?.session?.getMessage(messages, completion: { (result) in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let listing):
                        if(reload){
                            self.content = []
                        }
                        for message in listing.children.flatMap({$0}){
                            self.content.append(message)
                            if((message as! Message).baseJson["replies"] != nil) {
                                let json = (message as! Message).baseJson as JSONDictionary
                                if let j = json["replies"] as? JSONDictionary, let data = j["data"] as? JSONDictionary, let things = data["children"] as? JSONArray {
                                    for thing in things {
                                        self.content.append(Message.init(json: (thing as! JSONDictionary)["data"] as! JSONDictionary))
                                    }
                                }
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
