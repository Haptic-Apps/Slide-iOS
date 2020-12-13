//
// Created by Carlos Crane on 6/6/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import CoreData
import NotificationCenter
import reddift
import SDCAlertView
import SDWebImage
import SwiftEntryKit
import UIKit

extension Notification.Name {
    static let cancelAutoCache = Notification.Name("CancelAutoCache")
    static let autoCacheStarted = Notification.Name("AutoCacheStarted")
    static let autoCacheFinished = Notification.Name("AutoCacheFinished")
    static let autoCacheProgress = Notification.Name("AutoCacheProgress")
}

//TODO on cancel
protocol AutoCacheDelegate: class {
    func autoCacheStarted(_ notification: Notification)
    func autoCacheFinished(_ notification: Notification)
    func autoCacheProgress(_ notification: Notification)
}

public class AutoCache: NSObject {
    var subs = [String]()
    var cancel = false
    var currentSubreddit = ""
    var cacheProgress = Float(0)
    static var current: AutoCache?

    init(subs: [String]) {
        super.init()
        if AutoCache.current == nil {
            AutoCache.current = self
            self.subs = subs
            if !self.subs.isEmpty {
                doCache(subs: subs, progress: { sub, post, total, _ in
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .autoCacheProgress, object: nil, userInfo: ["subreddit": sub, "progress": Float(post) / Float(total)])
                        self.cacheProgress = Float(post) / Float(total)
                    }
                }, completion: { (total, failed) in
                    DispatchQueue.main.async {
                        AutoCache.current = nil
                        NotificationCenter.default.post(name: .autoCacheFinished, object: nil, userInfo: ["total": total, "failed": failed])
                    }
                })
            }
            NotificationCenter.default.addObserver(self, selector: #selector(cancelAutoCache), name: .cancelAutoCache, object: nil)
        }
    }
    
    @objc func cancelAutoCache() {
        cancel = true
    }

    func doCache(subs: [String], progress: @escaping (String, Int, Int, Int) -> Void, completion: @escaping (Int, Int) -> Void) {
        cacheSub(0, progress: progress, completion: completion, total: 0, failed: 0)
    }

    func cacheComments(_ index: Int, commentIndex: Int, currentLinks: [SubmissionObject], done: Int, failed: Int, progress: @escaping (String, Int, Int, Int) -> Void, completion: @escaping (Int, Int) -> Void) {
        if cancel {
            return
        }
        if commentIndex >= currentLinks.count {
            cacheSub(index + 1, progress: progress, completion: completion, total: currentLinks.count, failed: failed)
            return
        }

        var done = done
        var failed = failed
        DispatchQueue.main.async {
            do {
                let link = currentLinks[commentIndex]
                var name = link.getId()
                if name.contains("t3_") {
                    name = name.replacingOccurrences(of: "t3_", with: "")
                }

                try (UIApplication.shared.delegate as! AppDelegate).session?.getArticles(name, sort: SettingValues.defaultCommentSorting, depth: SettingValues.commentDepth, context: 3, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        done += 1
                        failed += 1
                        print(error)
                        progress(self.subs[index], done, currentLinks.count, failed)
                        self.cacheComments(index, commentIndex: commentIndex + 1, currentLinks: currentLinks, done: done, failed: failed, progress: progress, completion: completion)
                    case .success(let tuple):
                        done += 1
                        progress(self.subs[index], done, currentLinks.count, failed)
                        let startDepth = 1
                        var allIncoming: [(Thing, Int)] = []
                        var content = [CommentObject]()

                        for child in tuple.1.children {
                            let incoming = AutoCache.extendKeepMore(in: child, current: startDepth)
                            allIncoming.append(contentsOf: incoming)
                            for i in incoming {
                                if let item = CommentObject.thingToCommentOrMore(thing: i.0, depth: i.1), item is CommentObject {
                                    content.append(item as! CommentObject)
                                }
                            }
                        }
                        
                        self.saveCommentsCoreData(submission: link, commentData: content)
                        self.cacheComments(index, commentIndex: commentIndex + 1, currentLinks: currentLinks, done: done, failed: failed, progress: progress, completion: completion)
                    }
                })
            } catch {
                done += 1
                failed += 1
                progress(self.subs[index], done, currentLinks.count, failed)
            }
        }
    }

    func cacheSub(_ index: Int, progress: @escaping (String, Int, Int, Int) -> Void, completion: @escaping (Int, Int) -> Void, total: Int, failed: Int) {
        if cancel {
            return
        }
        
        if index >= subs.count {
            completion(total, failed)
            return
        }
        
        NotificationCenter.default.post(name: .autoCacheStarted, object: nil, userInfo: ["subreddit": self.subs[index]])
        self.currentSubreddit = self.subs[index]
        
        if index >= subs.count {
            completion(total, failed)
            return
        }

        let sub = subs[index]
        print("Caching \(sub)")
        DispatchQueue.main.async {
            do {
                var subreddit: SubredditURLPath = Subreddit.init(subreddit: sub)
                if sub.hasPrefix("/m/") {
                    subreddit = Multireddit.init(name: sub.substring(3, length: sub.length - 3), user: AccountController.currentName)
                }
                try (UIApplication.shared.delegate as! AppDelegate).session?.getList(Paginator.init(), subreddit: subreddit, sort: SettingValues.defaultSorting, timeFilterWithin: SettingValues.defaultTimePeriod, limit: SettingValues.cachedPostsCount, completion: { (result) in
                    switch result {
                    case .failure(let error):
                       // TODO: - error reporting?
                        print(error)
                        self.cacheSub(index + 1, progress: progress, completion: completion, total: total, failed: failed)
                    case .success(let listing):
                        if self.cancel {
                            return
                        }
                        let newLinks = listing.children.compactMap({ $0 as? Link })
                        var converted: [SubmissionObject] = []
                        for link in newLinks {
                            let newRS = SubmissionObject.linkToSubmissionObject(submission: link)
                            converted.append(newRS)
                        }
                        let values = PostFilter.filter(converted, previous: [], baseSubreddit: sub).map { $0 as! SubmissionObject }
                        
                        self.saveSubmissionsCoreData(subreddit: sub, links: values)
                        self.preloadImages(values)
                        self.cacheComments(index, commentIndex: 0, currentLinks: values, done: 0, failed: 0, progress: progress, completion: completion)
                    }
                })
            } catch {
                print(error)
            }
        }
    }
    
    var toBeExecuted: [() -> Void] = []

    func saveSubmissionsCoreData(subreddit: String, links: [SubmissionObject]) {
        let context = SlideCoreData.sharedInstance.backgroundContext
        context.performAndWait {
            var ids = [String]()
            for link in links {
                ids.append(link.getId())
                
                _ = link.insertSelf(into: context, andSave: false)
            }
            
            var subredditPosts: SubredditPosts! = nil
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SubredditPosts")
            let predicate = NSPredicate(format: "subreddit = %@", subreddit)
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
            
            do {
                try context.save()
            } catch let error as NSError {
                print("Failed to save managed context \(error): \(error.userInfo)")
            }
        }
    }
        
    func saveCommentsCoreData(submission: SubmissionObject, commentData: [CommentObject]) {
        let context = SlideCoreData.sharedInstance.backgroundContext
        context.performAndWait {
            var submissionComments: SubmissionComments! = nil
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SubmissionComments")
            let predicate = NSPredicate(format: "submissionId = %@", submission.getId())
            fetchRequest.predicate = predicate
            do {
                let results = try context.fetch(fetchRequest) as! [SubmissionComments]
                submissionComments = results.first
            } catch {
                
            }
            if submissionComments == nil {
                submissionComments = NSEntityDescription.insertNewObject(forEntityName: "SubmissionComments", into: context) as? SubmissionComments
            }

            submissionComments.submissionId = submission.getId()
            submissionComments.saveDate = Date()
            
            var validIDs = [String]()
            for comment in commentData {
                _ = comment.insertSelf(into: context, andSave: false)
                validIDs.append(comment.getId())
            }
                            
            submissionComments.commentsString = validIDs.joined(separator: ",")
            
            do {
                try context.save()
            } catch let error as NSError {
                print("Failed to save managed context \(error): \(error.userInfo)")
            }
        }
    }

    func preloadImages(_ values: [SubmissionObject]) {
        var urls: [URL] = []
        for submission in values {
            var thumb = submission.hasThumbnail
            var big = submission.hasBanner
            var height = submission.imageHeight
            var type = ContentType.getContentType(submission: submission)
            if submission.isSelf {
                type = .SELF
            }

            if thumb && type == .SELF {
                thumb = false
            } else if type == .SELF && !SettingValues.hideImageSelftext && submission.imageHeight > 0 && SettingValues.postImageMode != .THUMBNAIL {
                big = true
            }

            let fullImage = ContentType.fullImage(t: type)

            if !fullImage && height < 75 {
                big = false
                thumb = true
            } else if big && (SettingValues.postImageMode == .CROPPED_IMAGE) {
                height = 200
            }

            if type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big || type == .SELF {
                big = false
                thumb = false
            }

            if height < 75 {
                thumb = true
                big = false
            }

            let shouldShowLq = SettingValues.dataSavingEnabled && submission.isLQ //Wifi will be disabled here
            if type == ContentType.CType.SELF && SettingValues.hideImageSelftext || SettingValues.noImages && submission.isSelf {
                big = false
                thumb = false
            }

            if big || !submission.hasThumbnail {
                thumb = false
            }

            if !big && !thumb && submission.type != .SELF && submission.type != .NONE {
                thumb = true
            }

            if thumb && !big {
                if submission.thumbnailUrl == "nsfw" {
                } else if submission.thumbnailUrl == "web" || (submission.thumbnailUrl ?? "").isEmpty {
                } else {
                    if let url = URL.init(string: submission.thumbnailUrl ?? "") {
                        urls.append(url)
                    }
                }
            }

            if big {
                if shouldShowLq {
                    if let url = URL.init(string: submission.lqURL ?? "") {
                        urls.append(url)
                    }

                } else {
                    if let url = URL.init(string: submission.bannerUrl ?? "") {
                        urls.append(url)
                    }
                }
            }
        }
        for url in urls {
            SDWebImageDownloader.shared.downloadImage(with: url, options: [.allowInvalidSSLCertificates, .scaleDownLargeImages], progress: nil) { (_, data, _, _) in
                if let data = data {
                    SDImageCache.shared.storeImageData(toDisk: data, forKey: SDWebImageManager.shared.cacheKey(for: url))
                }
            }
        }
    }
    
    static func extendKeepMore(in comment: Thing, current depth: Int) -> ([(Thing, Int)]) {
        var buf: [(Thing, Int)] = []

        if let comment = comment as? Comment {
            buf.append((comment, depth))
            for obj in comment.replies.children {
                buf.append(contentsOf: extendKeepMore(in: obj, current: depth + 1))
            }
        } else if let more = comment as? More {
            buf.append((more, depth))
        }
        return buf
    }

    static func extendForMore(parentID: String, comments: [Thing], current depth: Int) -> ([(Thing, Int)]) {
        var buf: [(Thing, Int)] = []

        for thing in comments {
            let pId = thing is Comment ? (thing as! Comment).parentId : (thing as! More).parentId
            if pId == parentID {
                if let comment = thing as? Comment {
                    var relativeDepth = 0
                    for parent in buf {
                        if comment.parentId == parentID {
                            relativeDepth = parent.1 - depth
                            break
                        }
                    }
                    buf.append((comment, depth + relativeDepth))
                    buf.append(contentsOf: extendForMore(parentID: comment.id, comments: comments, current: depth + relativeDepth + 1))
                } else if let more = thing as? More {
                    var relativeDepth = 0
                    for parent in buf {
                        let parentID = parent.0 is Comment ? (parent.0 as! Comment).parentId : (parent.0 as! More).parentId
                        if more.parentId == parentID {
                            relativeDepth = parent.1 - depth
                            break
                        }
                    }
                    buf.append((more, depth + relativeDepth))
                }
            }
        }
        return buf
    }

    func cancelAutocache(completed: Int) {
        print("Cancelling")
    }

}
