//
// Created by Carlos Crane on 6/6/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

import MaterialComponents.MDCProgressView
import RealmSwift
import reddift
import SDWebImage
import UIKit

public class AutoCache: NSObject {
    static var progressView: UILabel?
    static var progressBar: MDCProgressView?
    static var subs = [String]()
    static private var cancel = false

    init(baseController: MainViewController) {
        AutoCache.progressView = UILabel()
        super.init()
        AutoCache.subs.append(contentsOf: Subscriptions.offline)
        if !AutoCache.subs.isEmpty {
            setupProgressView(baseController)
        }
    }

    static func doCache(subs: [String], progress: @escaping (String, Int, Int, Int) -> Void, completion: @escaping () -> Void) {
        cacheSub(0, progress: progress, completion: completion)
    }

    static func cacheComments(_ index: Int, commentIndex: Int, currentLinks: [RSubmission], realmListing: RListing, done: Int, failed: Int, progress: @escaping (String, Int, Int, Int) -> Void, completion: @escaping () -> Void) {
        if cancel {
            return
        }

        if commentIndex >= currentLinks.count {
            do {
                let realm = try! Realm()
                realm.beginWrite()
                for submission in currentLinks {
                    realmListing.links.append(submission)
                }
                realm.create(type(of: realmListing), value: realmListing, update: true)
                try realm.commitWrite()
            } catch {
                print(error)
            }
            DispatchQueue.main.async {
                cacheSub(index + 1, progress: progress, completion: completion)
            }
            return
        }
        var done = done
        var failed = failed
        do {
            let link = currentLinks[commentIndex]
            try (UIApplication.shared.delegate as! AppDelegate).session?.getArticles(link.name, sort: SettingValues.defaultCommentSorting, comments: nil, context: 3, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    done += 1
                    failed += 1
                    print(error)
                    progress(subs[index], done, currentLinks.count, failed)
                case .success(let tuple):
                    done += 1
                    progress(subs[index], done, currentLinks.count, failed)
                    let startDepth = 1
                    var allIncoming: [(Thing, Int)] = []
                    var comments = [String]()
                    var content: Dictionary = [String: Object]()

                    for child in tuple.1.children {
                        let incoming = AutoCache.extendKeepMore(in: child, current: startDepth)
                        allIncoming.append(contentsOf: incoming)
                        for i in incoming {
                            let item = RealmDataWrapper.commentToRealm(comment: i.0, depth: i.1)
                            content[item.getIdentifier()] = item
                            comments.append(item.getIdentifier())
                        }
                    }

                    if !comments.isEmpty {
                        do {
                            let realm = try! Realm()
                            realm.beginWrite()
                            for comment in comments {
                                realm.create(type(of: content[comment]!), value: content[comment]!, update: true)
                                if content[comment]! is RComment {
                                    link.comments.append(content[comment] as! RComment)
                                }
                            }
                            realm.create(type(of: link), value: link, update: true)
                            try realm.commitWrite()
                        } catch {

                        }
                    }
                    var newCurrent = currentLinks
                    newCurrent.remove(at: commentIndex)
                    newCurrent.insert(link, at: commentIndex)
                    DispatchQueue.main.async {
                        cacheComments(index, commentIndex: commentIndex + 1, currentLinks: newCurrent, realmListing: realmListing, done: done, failed: failed, progress: progress, completion: completion)
                    }
                }
            })
        } catch {
            done += 1
            failed += 1
            progress(subs[index], done, currentLinks.count, failed)
        }

    }

    static func cacheSub(_ index: Int, progress: @escaping (String, Int, Int, Int) -> Void, completion: @escaping () -> Void) {
        if cancel {
            return
        }

        if index >= subs.count {
            completion()
            return
        }

        let sub = subs[index]
        print("Caching \(sub)")
        do {
            var subreddit: SubredditURLPath = Subreddit.init(subreddit: sub)
            if sub.hasPrefix("/m/") {
                subreddit = Multireddit.init(name: sub.substring(3, length: sub.length - 3), user: AccountController.currentName)
            }
            try (UIApplication.shared.delegate as! AppDelegate).session?.getList(Paginator.init(), subreddit: subreddit, sort: SettingValues.defaultSorting, timeFilterWithin: SettingValues.defaultTimePeriod, completion: { (result) in
                switch result {
                case .failure(let error):
                    //todo error reporting?
                    print(error)
                    DispatchQueue.main.async {
                        AutoCache.cacheSub(index + 1, progress: progress, completion: completion)
                    }
                case .success(let listing):
                    if cancel {
                        return
                    }
                    let realmListing = RListing()
                    realmListing.subreddit = sub
                    realmListing.updated = NSDate()

                    let newLinks = listing.children.compactMap({ $0 as? Link })
                    var converted: [RSubmission] = []
                    for link in newLinks {
                        let newRS = RealmDataWrapper.linkToRSubmission(submission: link)
                        converted.append(newRS)
                    }
                    let values = PostFilter.filter(converted, previous: [], baseSubreddit: sub).map { $0 as! RSubmission }
                    AutoCache.preloadImages(values)
                    DispatchQueue.main.async {
                        cacheComments(index, commentIndex: 0, currentLinks: values, realmListing: realmListing, done: 0, failed: 0, progress: progress, completion: completion)
                    }
                }
            })
        } catch {
            print(error)
        }
    }

    static func preloadImages(_ values: [RSubmission]) {
        var urls: [URL] = []
        for submission in values {
            if cancel {
                return
            }
            var thumb = submission.thumbnail
            var big = submission.banner
            var height = submission.height
            var type = ContentType.getContentType(baseUrl: submission.url)
            if submission.isSelf {
                type = .SELF
            }

            if thumb && type == .SELF {
                thumb = false
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

            let shouldShowLq = SettingValues.dataSavingEnabled && submission.lQ && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi())
            if type == ContentType.CType.SELF && SettingValues.hideImageSelftext
                    || SettingValues.noImages && submission.isSelf {
                big = false
                thumb = false
            }

            if big || !submission.thumbnail {
                thumb = false
            }

            if !big && !thumb && submission.type != .SELF && submission.type != .NONE {
                thumb = true
            }

            if thumb && !big {
                if submission.thumbnailUrl == "nsfw" {
                } else if submission.thumbnailUrl == "web" || submission.thumbnailUrl.isEmpty {
                } else {
                    if let url = URL.init(string: submission.thumbnailUrl) {
                        urls.append(url)
                    }
                }
            }

            if big {
                if shouldShowLq {
                    if let url = URL.init(string: submission.lqUrl) {
                        urls.append(url)
                    }

                } else {
                    if let url = URL.init(string: submission.bannerUrl) {
                        urls.append(url)
                    }
                }
            }

        }
        SDWebImagePrefetcher.init().prefetchURLs(urls)
    }

    func setupProgressView(_ base: MainViewController) {
        AutoCache.progressView = UILabel.init(frame: CGRect.init(x: 12, y: base.view.frame.size.height - 120, width: base.view.frame.size.width - 24, height: 48))
        AutoCache.progressView!.backgroundColor = ColorUtil.baseAccent
        AutoCache.progressView!.textAlignment = .left
        AutoCache.progressView!.isUserInteractionEnabled = true
        AutoCache.progressView!.text = "\tStarting cache..."
        AutoCache.progressView!.font = UIFont.systemFont(ofSize: 15)
        AutoCache.progressView!.textColor = .white

        AutoCache.progressBar = MDCProgressView()
        AutoCache.progressBar!.progressTintColor = ColorUtil.baseAccent
        AutoCache.progressBar!.trackTintColor = UIColor.white.withAlphaComponent(0.5)
        AutoCache.progressBar!.frame = CGRect(x: 0, y: 0, width: AutoCache.progressView!.frame.size.width, height: 5)
        AutoCache.progressBar!.progress = 0.0
        AutoCache.progressView!.elevate(elevation: 2)

        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.setImage(UIImage.init(named: "close")!.navIcon(), for: UIControl.State.normal)
        button.frame = CGRect.init(x: AutoCache.progressView!.frame.size.width - 40, y: 11.5, width: 25, height: 25)
        button.addTapGestureRecognizer {
            AutoCache.cancelAutocache()
        }
        button.isUserInteractionEnabled = true

        AutoCache.progressView!.addSubview(button)

        AutoCache.progressView!.addSubview(AutoCache.progressBar!)
        AutoCache.progressView!.layer.cornerRadius = 5
        AutoCache.progressView!.clipsToBounds = true
        AutoCache.progressView!.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        base.view.addSubview(AutoCache.progressView!)
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            AutoCache.progressView!.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }, completion: nil)

        AutoCache.cancel = false
        AutoCache.doCache(subs: AutoCache.subs, progress: { sub, post, total, failed in
            DispatchQueue.main.async {
                AutoCache.progressView?.text = "\tCaching post \(post)/\(total)\(failed > 0 ? " (\(failed) failed)" : "") in r/\(sub)"
                AutoCache.progressBar?.progress = Float(post) / Float(total)
            }
        }, completion: {
            DispatchQueue.main.async {
                AutoCache.cancelAutocache()
            }
        })
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

    static func extendForMore(parentId: String, comments: [Thing], current depth: Int) -> ([(Thing, Int)]) {
        var buf: [(Thing, Int)] = []

        for thing in comments {
            let pId = thing is Comment ? (thing as! Comment).parentId : (thing as! More).parentId
            if pId == parentId {
                if let comment = thing as? Comment {
                    var relativeDepth = 0
                    for parent in buf {
                        if comment.parentId == parentId {
                            relativeDepth = parent.1 - depth
                            break
                        }
                    }
                    buf.append((comment, depth + relativeDepth))
                    buf.append(contentsOf: extendForMore(parentId: comment.getId(), comments: comments, current: depth + relativeDepth + 1))
                } else if let more = thing as? More {
                    var relativeDepth = 0
                    for parent in buf {
                        let parentId = parent.0 is Comment ? (parent.0 as! Comment).parentId : (parent.0 as! More).parentId
                        if more.parentId == parentId {
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

    static func cancelAutocache() {
        print("Cancelling")
        cancel = true
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            AutoCache.progressView!.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
        }, completion: { _ in
            AutoCache.progressView!.removeFromSuperview()
            AutoCache.progressView = nil
        })
    }

}
