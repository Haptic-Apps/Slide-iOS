//
//  InboxContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/22/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import RealmSwift
import reddift

class ModMailContributionLoader: ContributionLoader {
    func reset() {
        content = []
    }

    var color: UIColor
    
    var unread = false
    var canGetMore = true
    
    init(_ unread: Bool) {
        self.unread = unread
        paginator = Paginator()
        content = []
        color = ColorUtil.getColorForSub(sub: "")
    }
    
    var paginator: Paginator
    var content: [Object]
    var delegate: ContentListingViewController?
    var paging = true
    
    func getData(reload: Bool) {
        if delegate != nil {
            do {
                if reload {
                    paginator = Paginator()
                }
                try delegate?.session?.getModMail(unread, completion: { (result) in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let listing):
                        if reload {
                            self.content = []
                        }
                        for message in listing.children.flatMap({ $0 }) {
                            self.content.append(RealmDataWrapper.messageToRMessage(message: message as! Message))
                            if (message as! Message).baseJson["replies"] != nil {
                                let json = (message as! Message).baseJson as JSONDictionary
                                if let j = json["replies"] as? JSONDictionary, let data = j["data"] as? JSONDictionary, let things = data["children"] as? JSONArray {
                                    for thing in things {
                                        self.content.append(RealmDataWrapper.messageToRMessage(message: Message.init(json: (thing as! JSONDictionary)["data"] as! JSONDictionary)))

                                    }
                                }
                            }
                        }
                        
                        self.paginator = listing.paginator
                        self.canGetMore = !self.paginator.hasMore()
                        DispatchQueue.main.async {
                            self.delegate?.doneLoading()
                        }
                    }
                })
            }
            catch {
                print(error)
            }
            
        }
    }
}
