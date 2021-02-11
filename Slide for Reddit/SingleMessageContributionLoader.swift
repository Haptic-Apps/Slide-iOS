//
//  SingleMessageContributionLoader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 2/10/21.
//  Copyright © 2021 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

protocol SingleMessageContributionLoaderDelegate: class {
    func doneLoading(before: Int)
    func failedLoading()
}
class SingleMessageContributionLoader {
    func reset() {
        content = []
    }
    
    var baseMessage: String
    weak var delegate: SingleMessageContributionLoaderDelegate?

    var color: UIColor = .black
        
    init(threadID: String, titleIfKnown: String = "") {
        self.baseMessage = threadID
        self.paginator = Paginator(after: baseMessage, before: baseMessage, modhash: "")
        
        content = []
        color = ColorUtil.getColorForSub(sub: "")
    }
    
    var paginator: Paginator
    var content: [MessageObject]
    
    var paging = true
    
    func getData(reload: Bool) {
        do {
            paginator = Paginator(after: baseMessage, before: baseMessage, modhash: "")
            
            if let session = (UIApplication.shared.delegate as? AppDelegate)?.session {
                try session.getMessage(self.paginator, .messages, limit: 1, completion: { result in
                    switch result {
                    case .failure(let error):
                        print(error)
                        DispatchQueue.main.async {
                            self.delegate?.failedLoading()
                        }
                    case .success(let listing):
                        if reload {
                            self.content = []
                        }
                        let before = self.content.count
                        for message in listing.children.compactMap({ $0 }) {
                            var contains = false
                            for present in self.content {
                                if present.name == message.name {
                                    contains = true
                                }
                            }
                            
                            if !contains {
                                self.content.append(MessageObject.messageToMessageObject(message: message as! Message))
                            }
                            
                            if (message as! Message).baseJson["replies"] != nil {
                                let json = (message as! Message).baseJson as JSONDictionary
                                if let j = json["replies"] as? JSONDictionary, let data = j["data"] as? JSONDictionary, let things = data["children"] as? JSONArray {
                                    for thing in things {
                                        contains = false
                                        for present in self.content {
                                            if present.name == message.name {
                                                contains = true
                                            }
                                        }
                                        
                                        if !contains {
                                            self.content.append(MessageObject.messageToMessageObject(message: Message.init(json: (thing as! JSONDictionary)["data"] as! JSONDictionary)))
                                        }
                                    }
                                }
                            }
                        }

                        DispatchQueue.main.async {
                            self.delegate?.doneLoading(before: before)
                        }
                    }
                })
            }
        } catch {
            print(error)
        }
    }
}
