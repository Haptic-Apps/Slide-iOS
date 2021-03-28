//
//  SubmissionsDataSource.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/23/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation
import reddift

protocol SubmissionDataSouceDelegate: class {
    func showIndicator()
    func generalError(title: String, message: String)
    func loadSuccess(before: Int, count: Int)
    func preLoadItems()
    func doPreloadImages(values: [SubmissionObject])
    func loadOffline()
    
    func emptyState(_ listing: Listing)
    
    func vcIsGallery() -> Bool
}

class SubmissionsDataSource {
    func reset() {
        content = []
        contentIDs = []
    }
    
    var subreddit: String
    var color: UIColor
    var canGetMore = true
    var sorting: LinkSortType
    var time: TimeFilterWithin
    var isReset = false
    var updated = Date()
    var contentIDs = [String]()
    
    weak var currentSession: URLSessionDataTask?

    init(subreddit: String, sorting: LinkSortType, time: TimeFilterWithin) {
        self.subreddit = subreddit
        color = ColorUtil.getColorForSub(sub: subreddit)
        paginator = Paginator()
        content = []
        contentIDs = []
        self.sorting = sorting
        self.time = time
    }
    
    var paginator: Paginator
    var content: [SubmissionObject]
    weak var delegate: SubmissionDataSouceDelegate?
    
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
        self.contentIDs = []
    }
    func hideReadPostsPermanently(callback: @escaping (_ indexPaths: [IndexPath]) -> Void) {
        var indexPaths: [IndexPath] = []
        var toRemove: [SubmissionObject] = []
        
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

    func getData(reload: Bool, force: Bool = false) {
        
        self.isReset = reload
        if let delegate = delegate {
            delegate.preLoadItems()
        }
        if subreddit.lowercased() == "randnsfw" && !SettingValues.nsfwEnabled {
            if let delegate = delegate {
                delegate.generalError(title: "\(self.subreddit.getSubredditFormatted()) is NSFW", message: "You must log into Reddit and enable NSFW content at Reddit.com to view this subreddit")
            }
            return
        } else if subreddit.lowercased() == "myrandom" && !AccountController.isGold {
            if let delegate = delegate {
                delegate.generalError(title: "\(self.subreddit.getSubredditFormatted()) requires a Reddit Premium subscription", message: "See reddit.com/gold/about for more details")
            }
            return
        }
        if (!loading || force) && (!offline || content.count == 0) {
            if !loaded {
                if let delegate = delegate {
                    delegate.showIndicator()
                }
            }
            
            currentSession?.cancel()
            currentSession = nil

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
                
                try currentSession = (UIApplication.shared.delegate as? AppDelegate)?.session?.getList(paginator, subreddit: subItem, sort: sorting, timeFilterWithin: time, limit: SettingValues.submissionLimit, completion: { (result) in
                    self.loaded = true
                    self.isReset = false
                    switch result {
                    case .failure:
                        self.loadOffline()
                    case .success(let listing):
                        self.loading = false
                        self.tries = 0
                        if self.isReset {
                            self.content = []
                            self.contentIDs = []
                            self.page = 0
                            self.numberFiltered = 0
                        }
                        
                        self.offline = false
                        let before = self.content.count

                        let newLinks = listing.children.compactMap({ $0 as? Link })
                        var converted: [SubmissionObject] = []
                        var ids = [String]()
                        for link in newLinks {
                            let newRS = SubmissionObject.linkToSubmissionObject(submission: link)
                            ids.append(newRS.getId())
                            converted.append(newRS)
                            CachedTitle.addTitle(s: newRS)
                        }
                        
                        self.delegate?.doPreloadImages(values: converted)
                        var values = PostFilter.filter(converted, previous: self.contentIDs, baseSubreddit: self.subreddit, gallery: self.delegate?.vcIsGallery() ?? false).map { $0 as! SubmissionObject }
                        self.numberFiltered += (converted.count - values.count)
                        if self.page > 0 && !values.isEmpty && SettingValues.showPages {
                            let uuid = UUID().uuidString
                            
                            let pageItem = SubmissionObject(id: uuid, title: "Page \(self.page + 1)\n\(self.content.count + values.count - self.page) posts", postsSince: DateFormatter().timeSince(from: self.startTime as NSDate, numericDates: true))
                            values.insert(pageItem, at: 0)
                        }
                        self.page += 1
                        
                        self.content += values
                        self.contentIDs += ids
                        
                        self.paginator = listing.paginator
                        self.nomore = !listing.paginator.hasMore() || (values.isEmpty && self.content.isEmpty)
                        
                        SlideCoreData.sharedInstance.saveContext()

                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }

                            if self.content.isEmpty && !SettingValues.hideSeen {
                                self.delegate?.emptyState(listing)
                            } else if self.content.isEmpty && newLinks.count != 0 && self.paginator.hasMore() {
                                self.loadMore()
                            } else {
                                self.delegate?.loadSuccess(before: before, count: self.content.count)
                            }
                        }
                    }
                })
            } catch {
                loading = false
                print(error)
            }
        }
    }
    
    func loadMore() {
        getData(reload: false)
    }
    
}

extension SubmissionsDataSource: Cacheable {
    func insertSelf(into context: NSManagedObjectContext, andSave: Bool) -> NSManagedObject? {
        context.performAndWaitReturnable {
            var ids = [String]()
            for link in content {
                ids.append(link.getId())
                
                _ = link.insertSelf(into: context, andSave: false)
            }
            
            var subredditPosts: SubredditPosts! = nil
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SubredditPosts")
            let predicate = NSPredicate(format: "subreddit = %@", self.subreddit)
            fetchRequest.predicate = predicate
            do {
                let results = try context.fetch(fetchRequest) as! [SubredditPosts]
                subredditPosts = results.first
            } catch {
                
            }
            if subredditPosts == nil {
                subredditPosts = NSEntityDescription.insertNewObject(forEntityName: "SubredditPosts", into: context) as? SubredditPosts
            }

            subredditPosts.posts = ids.joined(separator: ",")
            subredditPosts.time = Date()
            subredditPosts.subreddit = subreddit
            
            if andSave {
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Failed to save managed context \(error): \(error.userInfo)")
                    return nil
                }
            }
            
            return subredditPosts
        }
    }
    
    func loadOffline() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SubredditPosts")
        let sort = NSSortDescriptor(key: #keyPath(SubredditPosts.time), ascending: false)
        let predicate = NSPredicate(format: "subreddit = %@", self.subreddit)
        fetchRequest.sortDescriptors = [sort]
        fetchRequest.predicate = predicate
        do {
            let results = try SlideCoreData.sharedInstance.persistentContainer.viewContext.fetch(fetchRequest) as! [SubredditPosts]
            self.content = []
            self.contentIDs = []

            if let first = results.first {
                let postsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SubmissionModel")
                let postPredicate = NSPredicate(format: "id in %@", first.posts?.split(",") ?? [])
                postsRequest.predicate = postPredicate
                let links = try SlideCoreData.sharedInstance.persistentContainer.viewContext.fetch(postsRequest) as! [SubmissionModel]

                var linksDict = [String: SubmissionObject]() // Use dictionary to sort values below
                for model in links {
                    let object = SubmissionObject.fromModel(model)
                    linksDict[object.getId()] = object
                }

                let order = first.posts?.split(",") ?? []
                
                for id in order {
                    if let link = linksDict[id] {
                        self.content.append(link)
                    }
                }

                self.updated = first.time ?? Date()
            }
            var paths = [IndexPath]()
            for i in 0..<self.content.count {
                paths.append(IndexPath.init(item: i, section: 0))
            }
            
            self.loading = false
            self.nomore = true
            self.offline = true
            
            if let delegate = self.delegate {
                DispatchQueue.main.async {
                    delegate.loadOffline()
                }
            }
        } catch {

        }

    }
}
