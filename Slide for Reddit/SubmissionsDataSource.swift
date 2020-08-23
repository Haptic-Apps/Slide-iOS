//
//  SubmissionsDataSource.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/23/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import RealmSwift
import reddift

protocol SubmissionDataSouceDelegate {
    func showIndicator()
    func generalError(title: String, message: String)
    func loadSuccess(before: Int, count: Int)
    func preLoadItems()
    func doPreloadImages(values: [RSubmission])
    func loadOffline()
    
    func emptyState(_ listing: Listing)
    
    func vcIsGallery() -> Bool
}

class SubmissionsDataSource {
    func reset() {
        content = []
    }
    
    var subreddit: String
    var color: UIColor
    var canGetMore = true
    var sorting: LinkSortType
    var time: TimeFilterWithin
    var isReset = false
    var realmListing: RListing?
    var updated = NSDate()

    init(subreddit: String, sorting: LinkSortType, time: TimeFilterWithin) {
        self.subreddit = subreddit
        color = ColorUtil.getColorForSub(sub: subreddit)
        paginator = Paginator()
        content = []
        self.sorting = sorting
        self.time = time
    }
    
    var paginator: Paginator
    var content: [RSubmission]
    var delegate: SubmissionDataSouceDelegate?
    
    var loading = false
    var loaded = false
    var nomore = false
    var offline = false
    
    var page = 0
    var tries = 0
    var numberFiltered = 0
    var lastTopItem = 0
    var startTime = Date()
    
    func hasContent() -> Bool {
        return !content.isEmpty
    }
    
    func hideReadPosts(callback: @escaping (_ indexPaths: [IndexPath]) -> Void) {
        var indexPaths: [IndexPath] = []

        var index = 0
        var count = 0
        self.lastTopItem = 0
        for submission in content {
            if History.getSeen(s: submission) {
                indexPaths.append(IndexPath(row: count, section: 0))
                content.remove(at: index)
            } else {
                index += 1
            }
            count += 1
        }

        callback(indexPaths)
    }

    func removeData() {
        self.content = []
    }
    func hideReadPostsPermanently(callback: @escaping (_ indexPaths: [IndexPath]) -> Void) {
        var indexPaths: [IndexPath] = []
        var toRemove: [RSubmission] = []
        
        var index = 0
        var count = 0
        for submission in content {
            if History.getSeen(s: submission) {
                indexPaths.append(IndexPath(row: count, section: 0))
                toRemove.append(submission)
                content.remove(at: index)
            } else {
                index += 1
            }
            count += 1
        }
        
       // TODO: - save realm
        callback(indexPaths)
        
        if let session = (UIApplication.shared.delegate as? AppDelegate)?.session {
            if !indexPaths.isEmpty {
                var hideString = ""
                for item in toRemove {
                    hideString.append(item.getId() + ",")
                }
                hideString = hideString.substring(0, length: hideString.length - 1)
                do {
                    try session.setHide(true, name: hideString) { (result) in
                        print(result)
                    }
                } catch {
                }
            }
        }
    }
    
    func handleTries(_ callback: @escaping (_ isEmpty: Bool) -> Void) {
        if tries < 1 {
            self.tries += 1
            
            self.getData(reload: true)
        } else {
            callback(content.isEmpty)
        }
    }

    func getData(reload: Bool) {
        self.isReset = reload
        if let delegate = delegate {
            delegate.preLoadItems()
        }
        if subreddit.lowercased() == "randnsfw" && !SettingValues.nsfwEnabled {
            if let delegate = delegate {
                delegate.generalError(title: "r/\(self.subreddit) is NSFW", message: "You must log into Reddit and enable NSFW content at Reddit.com to view this subreddit")
            }
            return
        } else if subreddit.lowercased() == "myrandom" && !AccountController.isGold {
            if let delegate = delegate {
                delegate.generalError(title: "r/\(self.subreddit) requires gold", message: "See reddit.com/gold/about for more details")
            }
            return
        }
        if !loading {
            if !loaded {
                if let delegate = delegate {
                    delegate.showIndicator()
                }
            }

            do {
                loading = true
                if isReset {
                    paginator = Paginator()
                    self.page = 0
                    self.lastTopItem = 0
                }
                if isReset || !loaded {
                    self.startTime = Date()
                }
                var subItem: SubredditURLPath = Subreddit.init(subreddit: subreddit)

                if subreddit.hasPrefix("/m/") {
                    subItem = Multireddit.init(name: subreddit.substring(3, length: subreddit.length - 3), user: AccountController.currentName)
                }
                if subreddit.contains("/u/") {
                    subItem = Multireddit.init(name: subreddit.split("/")[3], user: subreddit.split("/")[1])
                }
                
                try (UIApplication.shared.delegate as? AppDelegate)?.session?.getList(paginator, subreddit: subItem, sort: sorting, timeFilterWithin: time, limit: SettingValues.submissionLimit, completion: { (result) in
                    self.loaded = true
                    self.isReset = false
                    switch result {
                    case .failure:
                        print(result.error!)
                        //test if realm exists and show that
                        DispatchQueue.main.async {
                            do {
                                let realm = try Realm()
                                self.updated = NSDate()
                                if let listing = realm.objects(RListing.self).filter({ (item) -> Bool in
                                    return item.subreddit == self.subreddit
                                }).first {
                                    self.content = []
                                    for i in listing.links {
                                        self.content.append(i)
                                    }
                                    self.updated = listing.updated
                                }
                                var paths = [IndexPath]()
                                for i in 0..<self.content.count {
                                    paths.append(IndexPath.init(item: i, section: 0))
                                }
                                
                                self.loading = false
                                self.loading = false
                                self.nomore = true
                                self.offline = true
                                
                                if let delegate = self.delegate {
                                    delegate.loadOffline()
                                }
                            } catch {
                                
                            }

                        }
                    case .success(let listing):
                        self.tries = 0
                        if self.isReset {
                            self.content = []
                            self.page = 0
                            self.numberFiltered = 0
                        }
                        
                        self.offline = false
                        let before = self.content.count
                        if self.realmListing == nil {
                            self.realmListing = RListing()
                            self.realmListing!.subreddit = self.subreddit
                            self.realmListing!.updated = NSDate()
                        }
                        if self.isReset && self.realmListing!.links.count > 0 {
                            self.realmListing!.links.removeAll()
                        }

                        let newLinks = listing.children.compactMap({ $0 as? Link })
                        var converted: [RSubmission] = []
                        for link in newLinks {
                            let newRS = RealmDataWrapper.linkToRSubmission(submission: link)
                            converted.append(newRS)
                            CachedTitle.addTitle(s: newRS)
                        }
                        
                        var values = PostFilter.filter(converted, previous: self.content, baseSubreddit: self.subreddit, gallery: self.delegate?.vcIsGallery() ?? false).map { $0 as! RSubmission }
                        self.numberFiltered += (converted.count - values.count)
                        if self.page > 0 && !values.isEmpty && SettingValues.showPages {
                            let pageItem = RSubmission()
                            pageItem.subreddit = DateFormatter().timeSince(from: self.startTime as NSDate, numericDates: true)
                            pageItem.author = "PAGE_SEPARATOR"
                            pageItem.title = "Page \(self.page + 1)\n\(self.content.count + values.count - self.page) posts"
                            values.insert(pageItem, at: 0)
                        }
                        self.page += 1
                        
                        self.content += values
                        self.paginator = listing.paginator
                        self.nomore = !listing.paginator.hasMore() || values.isEmpty
                        do {
                            let realm = try Realm()
                           // TODO: - insert
                            realm.beginWrite()
                            for submission in self.content {
                                if submission.author != "PAGE_SEPARATOR" {
                                    realm.create(type(of: submission), value: submission, update: .all)
                                    if let listing = self.realmListing {
                                        listing.links.append(submission)
                                    }
                                }
                            }
                            
                            try realm.create(type(of: self.realmListing!), value: self.realmListing!, update: .all)
                            try realm.commitWrite()
                        } catch {

                        }
                        
                        self.delegate?.doPreloadImages(values: values)
                        
                        DispatchQueue.main.async { [weak self] in
                            guard let strongSelf = self else { return }
                            if strongSelf.content.isEmpty && !SettingValues.hideSeen {
                                strongSelf.loading = false
                                strongSelf.delegate?.emptyState(listing)
                            } else if strongSelf.content.isEmpty && newLinks.count != 0 && strongSelf.paginator.hasMore() {
                                strongSelf.loading = false
                                strongSelf.loadMore()
                            } else {
                                strongSelf.loading = false
                                strongSelf.delegate?.loadSuccess(before: before, count: strongSelf.content.count)
                            }
                        }
                    }
                })
            } catch {
                print(error)
            }
        }
    }
    
    func loadMore() {
        getData(reload: false)
    }

}

