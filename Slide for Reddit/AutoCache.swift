//
// Created by Carlos Crane on 6/6/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import MaterialComponents.MDCProgressView

import reddift
import SDCAlertView
import SDWebImage
import SwiftEntryKit
import UIKit

public class AutoCache: NSObject {
    static var subs = [String]()
    static var progressBar: MDCProgressView?
    static var label: UILabel?
    static private var cancel = false

    init(baseController: UIViewController, subs: [String]) {
        super.init()
        if AutoCache.label != nil {
            let alert = AlertController.init(title: "", message: nil, preferredStyle: .alert)
            
            alert.setupTheme()
            alert.attributedTitle = NSAttributedString(string: "Another caching operation is active", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
            
            alert.attributedMessage = TextDisplayStackView.createAttributedChunk(baseHTML: "Please wait for it to complete before caching more subreddits!", fontSize: 14, submission: false, accentColor: ColorUtil.baseAccent, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
            
            alert.addCloseButton()
            alert.addBlurView()
            baseController.present(alert, animated: true, completion: nil)
            return
        }
        AutoCache.subs = subs
        if !AutoCache.subs.isEmpty {
            setupProgressView(baseController)
        }
    }

    static func doCache(subs: [String], progress: @escaping (String, Int, Int, Int) -> Void, completion: @escaping (Int, Int) -> Void) {
        cacheSub(0, progress: progress, completion: completion, total: 0, failed: 0)
    }

    static func cacheComments(_ index: Int, commentIndex: Int, currentLinks: [Submission], realmListing: RListing, done: Int, failed: Int, progress: @escaping (String, Int, Int, Int) -> Void, completion: @escaping (Int, Int) -> Void) {
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
                realmListing.comments = true
                realm.create(type(of: realmListing), value: realmListing, update: .all)
                try realm.commitWrite()
            } catch {
                print(error)
            }
            DispatchQueue.main.async {
                cacheSub(index + 1, progress: progress, completion: completion, total: currentLinks.count, failed: failed)
            }
            return
        }
        var done = done
        var failed = failed
        do {
            let link = currentLinks[commentIndex]
            try (UIApplication.shared.delegate as! AppDelegate).session?.getArticles(link.name, sort: SettingValues.defaultCommentSorting, depth: SettingValues.commentDepth, context: 3, completion: { (result) -> Void in
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
                            content[item.getId()] = item
                            comments.append(item.getId())
                        }
                    }

                    if !comments.isEmpty {
                        do {
                            if let realm = try? Realm() {
                                realm.beginWrite()
                                for comment in comments {
                                    realm.create(type(of: content[comment]!), value: content[comment]!, update: .all)
                                    if content[comment]! is CommentModel {
                                        link.comments.append(content[comment] as! CommentModel)
                                    }
                                }
                                realm.create(type(of: link), value: link, update: .all)
                                try realm.commitWrite()
                            }
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

    static func cacheSub(_ index: Int, progress: @escaping (String, Int, Int, Int) -> Void, completion: @escaping (Int, Int) -> Void, total: Int, failed: Int) {
        if cancel {
            return
        }

        if index >= subs.count {
            completion(total, failed)
            return
        }

        let sub = subs[index]
        print("Caching \(sub)")
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
                    DispatchQueue.main.async {
                        AutoCache.cacheSub(index + 1, progress: progress, completion: completion, total: total, failed: failed)
                    }
                case .success(let listing):
                    if cancel {
                        return
                    }
                    let realmListing = RListing()
                    realmListing.subreddit = sub
                    realmListing.updated = NSDate()

                    let newLinks = listing.children.compactMap({ $0 as? Link })
                    var converted: [Submission] = []
                    for link in newLinks {
                        let newRS = RealmDataWrapper.linkToSubmission(submission: link)
                        converted.append(newRS)
                    }
                    let values = PostFilter.filter(converted, previous: [], baseSubreddit: sub).map { $0 as! Submission }
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

    static func preloadImages(_ values: [Submission]) {
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
            } else if big && (SettingValues.postImageMode == .SHORT_IMAGE) {
                height = Int(UIScreen.main.bounds.height / 2)
            }

            if type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big || type == .SELF {
                big = false
                thumb = false
            }

            if height < 75 {
                thumb = true
                big = false
            }

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
                if let url = URL.init(string: submission.bannerUrl) {
                    urls.append(url)
                }
            }

        }
        SDWebImagePrefetcher.shared.prefetchURLs(urls, progress: { (a, b) in
            print("Caching \(a) of \(b)")
        }, completed: { (a, b) in
            print("Did \(a) of \(b)")
        })
    }

    func setupProgressView(_ base: UIViewController) {
        let popup = UILabel.init(frame: CGRect.zero)
        popup.textAlignment = .center
        popup.isUserInteractionEnabled = true
        
        let textParts = "Caching in progress\nPreparing..."
        popup.numberOfLines = 0
        popup.heightAnchor /==/ 70
        
        var attributes = EKAttributes.topNote
        attributes.name = "autocache"
        attributes.displayDuration = .infinity
        attributes.position = EKAttributes.Position.top
        attributes.screenInteraction = .forward
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .easeOut)
        attributes.entryBackground = EKAttributes.BackgroundStyle.color(color: .black)
        attributes.precedence = .enqueue(priority: .normal)
        attributes.roundCorners = EKAttributes.RoundCorners.bottom(radius: 15)
        AutoCache.label = popup
        AutoCache.setPopupText(textParts)

        SwiftEntryKit.display(entry: popup.withPadding(padding: UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)), using: attributes)

        AutoCache.progressBar = MDCProgressView()
        AutoCache.progressBar?.progressTintColor = ColorUtil.baseAccent
        AutoCache.progressBar?.trackTintColor = UIColor.white.withAlphaComponent(0.5)
        
        if let progressBar = AutoCache.progressBar {
            popup.addSubview(progressBar)
            progressBar.horizontalAnchors /==/ popup.horizontalAnchors + 4
            progressBar.bottomAnchor /==/ popup.bottomAnchor
            popup.clipsToBounds = true
            popup.layer.cornerRadius = 15
            progressBar.heightAnchor /==/ 4
            progressBar.progress = 0.0
        }
        
        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.setImage(UIImage(sfString: SFSymbol.xmark, overrideString: "close")!.navIcon().getCopy(withColor: .white), for: UIControl.State.normal)
        popup.addSubview(button)
        button.rightAnchor /==/ popup.rightAnchor - 4
        button.heightAnchor /==/ 25
        button.widthAnchor /==/ 25
        button.centerYAnchor /==/ popup.centerYAnchor
        button.addTapGestureRecognizer { (_) in
            AutoCache.cancelAutocache(completed: -1)
        }
        button.isUserInteractionEnabled = true

        AutoCache.cancel = false
        AutoCache.doCache(subs: AutoCache.subs, progress: { sub, post, total, failed in
            DispatchQueue.main.async {
                AutoCache.setPopupText("Caching in progress\nCaching post \(post)/\(total)\(failed > 0 ? " (\(failed) failed)" : "") in \(sub)")
                AutoCache.progressBar?.progress = Float(post) / Float(total)
            }
        }, completion: { (total, failed) in
            DispatchQueue.main.async {
                AutoCache.cancelAutocache(completed: total - failed)
            }
        })
    }
    
    static func setPopupText(_ text: String) {
        let finalText: NSMutableAttributedString!
        let textParts = text.split("\n")
        if textParts.count > 1 {
            let firstPart = NSMutableAttributedString.init(string: textParts[0], attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)])
            let secondPart = NSMutableAttributedString.init(string: "\n" + textParts[1], attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)])
            firstPart.append(secondPart)
            finalText = firstPart
        } else {
            finalText = NSMutableAttributedString.init(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)])
        }
        label?.attributedText = finalText
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
                    buf.append(contentsOf: extendForMore(parentId: comment.id, comments: comments, current: depth + relativeDepth + 1))
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

    static func cancelAutocache(completed: Int) {
        print("Cancelling")
        cancel = true
        if SwiftEntryKit.isCurrentlyDisplaying {
            SwiftEntryKit.dismiss(.displayed) {
                AutoCache.label?.removeFromSuperview()
                AutoCache.progressBar = nil
                AutoCache.label = nil
                if completed > 0 {
                    BannerUtil.makeBanner(text: "\(completed) posts cached successfully", color: .black, seconds: 3, context: nil, top: true, callback: nil)
                }
            }
        } else {
            if completed > 0 {
                BannerUtil.makeBanner(text: "\(completed) posts cached successfully", color: .black, seconds: 3, context: nil, top: true, callback: nil)
            }
        }
    }

}
