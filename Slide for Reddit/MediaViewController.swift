//
//  MediaViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/28/16.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import MaterialComponents.MaterialProgressView
import reddift
import SafariServices
import SDWebImage
import UIKit

class MediaViewController: UIViewController, MediaVCDelegate {

    lazy var slideInTransitioningDelegate = SlideInPresentationManager()
    lazy var postContentTransitioningDelegate = PostContentPresentationManager()

    var subChanged = false

    var link: RSubmission!
    var commentCallback: (() -> Void)?
    var failureCallback: ((_ url: URL) -> Void)?
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }

    public func setLink(lnk: RSubmission, shownURL: URL?, lq: Bool, saveHistory: Bool, heroView: UIView?, heroVC: UIViewController?) { //lq is should load lq and did load lq
        if saveHistory {
            History.addSeen(s: lnk)
        }
        self.link = lnk
        let url = link.url!
        
        print("Setting comment callback")
        commentCallback = { () in
            let comment = CommentViewController.init(submission: self.link, single: true)
                VCPresenter.showVC(viewController: comment, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }

        failureCallback = { (url: URL) in
            let vc: UIViewController
            if SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL || SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY {
                let safariVC = SFHideSafariViewController(url: url, entersReaderIfAvailable: SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY)
                if #available(iOS 10.0, *) {
                    safariVC.preferredBarTintColor = ColorUtil.backgroundColor
                    safariVC.preferredControlTintColor = ColorUtil.fontColor
                    vc = safariVC
                } else {
                    let web = WebsiteViewController(url: url, subreddit: "")
                    vc = web
                }
            } else {
                let web = WebsiteViewController(url: url, subreddit: "")
                vc = web
            }
            VCPresenter.showVC(viewController: vc, popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
        }

        let type = ContentType.getContentType(submission: lnk)

        if type == .EXTERNAL {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(lnk.url!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(lnk.url!)
            }
        } else {
            if ContentType.isGif(uri: url) {
                if !link!.videoPreview.isEmpty() && !ContentType.isGfycat(uri: url) {
                    doShow(url: URL.init(string: link!.videoPreview)!, heroView: heroView, heroVC: heroVC)
                } else {
                    doShow(url: url, heroView: heroView, heroVC: heroVC)
                }
            } else {
                if lq && shownURL != nil && !ContentType.isImgurLink(uri: url) {
                    doShow(url: url, lq: shownURL, heroView: heroView, heroVC: heroVC)
                } else if shownURL != nil && ContentType.imageType(t: type) && !ContentType.isImgurLink(uri: url) {
                    doShow(url: shownURL!, heroView: heroView, heroVC: heroVC)
                } else {
                    doShow(url: url, heroView: heroView, heroVC: heroVC)
                }
            }
        }
    }

    func getControllerForUrl(baseUrl: URL, lq: URL? = nil) -> UIViewController? {
        contentUrl = baseUrl.absoluteString.startsWith("//") ? URL(string: "https:\(baseUrl.absoluteString)") ?? baseUrl : baseUrl
        if shouldTruncate(url: contentUrl!) {
            let content = contentUrl?.absoluteString
            contentUrl = URL.init(string: (content?.substring(to: content!.index(of: ".")!))!)
        }
        let type = ContentType.getContentType(baseUrl: contentUrl)

        if type == ContentType.CType.ALBUM && SettingValues.internalAlbumView {
            print("Showing album")
            return AlbumViewController.init(urlB: contentUrl!)
        } else if contentUrl != nil && ContentType.displayImage(t: type) && SettingValues.internalImageView || (type == ContentType.CType.VIDEO && SettingValues.internalYouTube) {
            return ModalMediaViewController.init(url: contentUrl!, lq: lq, commentCallback, failureCallback)
        } else if contentUrl != nil && type == .GIF && SettingValues.internalGifView || type == .STREAMABLE || type == .VID_ME {
            if !ContentType.isGifLoadInstantly(uri: contentUrl!) && type == .GIF {
                if SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL || SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY {
                    let safariVC = SFHideSafariViewController(url: contentUrl!, entersReaderIfAvailable: SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY)
                    if #available(iOS 10.0, *) {
                        safariVC.preferredBarTintColor = ColorUtil.backgroundColor
                        safariVC.preferredControlTintColor = ColorUtil.fontColor
                    } else {
                        // Fallback on earlier versions
                    }
                    return safariVC
                }
                return WebsiteViewController(url: contentUrl!, subreddit: link == nil ? "" : link.subreddit)
            }
            return AnyModalViewController(baseUrl: contentUrl!, commentCallback, failure: failureCallback)
        } else if type == ContentType.CType.LINK || type == ContentType.CType.NONE {
            if SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL || SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY {
                let safariVC = SFHideSafariViewController(url: contentUrl!, entersReaderIfAvailable: SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY)
                if #available(iOS 10.0, *) {
                    safariVC.preferredBarTintColor = ColorUtil.backgroundColor
                    safariVC.preferredControlTintColor = ColorUtil.fontColor
                } else {
                    // Fallback on earlier versions
                }
                return safariVC
            }
            let web = WebsiteViewController(url: contentUrl!, subreddit: link == nil ? "" : link.subreddit)
            return web
        } else if type == ContentType.CType.REDDIT {
            return RedditLink.getViewControllerForURL(urlS: contentUrl!)
        }
        if SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL || SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY {
            let safariVC = SFHideSafariViewController(url: contentUrl!, entersReaderIfAvailable: SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY)
            if #available(iOS 10.0, *) {
                safariVC.preferredBarTintColor = ColorUtil.backgroundColor
                safariVC.preferredControlTintColor = ColorUtil.fontColor
            } else {
                // Fallback on earlier versions
            }
            return safariVC
        }
        return WebsiteViewController(url: contentUrl!, subreddit: link == nil ? "" : link.subreddit)
    }

    var contentUrl: URL?

    public func shouldTruncate(url: URL) -> Bool {
        return false //Todo: figure out what this does
        let path = url.path
        return !ContentType.isGif(uri: url) && !ContentType.isImage(uri: url) && path.contains(".")
    }

    func showSpoiler(_ string: String) {
        let m = string.capturedGroups(withRegex: "\\[\\[s\\[(.*?)\\]s\\]\\]")
        let controller = UIAlertController.init(title: "Spoiler", message: m[0][1], preferredStyle: .alert)
        controller.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: nil))
        present(controller, animated: true, completion: nil)
    }

    public static func handleCloseNav(controller: UIButtonWithContext) {
        controller.parentController!.dismiss(animated: true)
    }

    func doShow(url: URL, lq: URL? = nil, heroView: UIView?, heroVC: UIViewController?) {
        failureCallback = {[weak self] (url: URL) in
            guard let strongSelf = self else { return }
            let vc: UIViewController
            if SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL || SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY {
                let safariVC = SFHideSafariViewController(url: url, entersReaderIfAvailable: SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY)
                if #available(iOS 10.0, *) {
                    safariVC.preferredBarTintColor = ColorUtil.backgroundColor
                    safariVC.preferredControlTintColor = ColorUtil.fontColor
                    vc = safariVC
                } else {
                    let web = WebsiteViewController(url: url, subreddit: "")
                    vc = web
                }
            } else {
                let web = WebsiteViewController(url: url, subreddit: "")
                vc = web
            }
            VCPresenter.showVC(viewController: vc, popupIfPossible: false, parentNavigationController: strongSelf.navigationController, parentViewController: strongSelf)
        }
        if ContentType.isExternal(url) || ContentType.shouldOpenExternally(url) || ContentType.shouldOpenBrowser(url) {
            let oldUrl = url
            var newUrl = oldUrl
            
            let browser = SettingValues.browser
            let sanitized = oldUrl.absoluteString.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
            if browser == SettingValues.BROWSER_SAFARI {
            } else if browser == SettingValues.BROWSER_CHROME {
                newUrl = URL(string: "googlechrome://" + sanitized) ?? oldUrl
            } else if browser == SettingValues.BROWSER_OPERA {
                newUrl = URL(string: "opera-http://" + sanitized) ?? oldUrl
            } else if browser == SettingValues.BROWSER_FIREFOX {
                newUrl = URL(string: "firefox://open-url?url=" + oldUrl.absoluteString) ?? oldUrl
            } else if browser == SettingValues.BROWSER_FOCUS {
                newUrl = URL(string: "firefox-focus://open-url?url=" + oldUrl.absoluteString) ?? oldUrl
            }

            if #available(iOS 10.0, *) {
                print("Opening externally")
                UIApplication.shared.open(newUrl, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(newUrl)
            }
        } else {
            var urlString = url.absoluteString
            if urlString.startsWith("//") {
                urlString = "https:" + urlString
            }
            
            contentUrl = URL.init(string: urlString)!
            if ContentType.isSpoiler(uri: url) {
                let controller = UIAlertController.init(title: "Spoiler", message: url.absoluteString, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                present(controller, animated: true, completion: nil)
            } else {
                let controller = getControllerForUrl(baseUrl: contentUrl!, lq: lq)!
                if let sourceView = heroView,
                    let modalController = controller as? ModalMediaViewController {

//                    slideInTransitioningDelegate.direction = .bottom
//                    slideInTransitioningDelegate.coverageRatio = 0.6
//                    modalController.transitioningDelegate = slideInTransitioningDelegate
//                    modalController.modalPresentationStyle = .custom

                    postContentTransitioningDelegate.sourceImageView = sourceView
                    modalController.transitioningDelegate = postContentTransitioningDelegate
                    modalController.modalPresentationStyle = .custom

                    present(modalController, animated: true, completion: nil)
                } else if controller is AlbumViewController {
                    controller.modalPresentationStyle = .overFullScreen
                    (controller as! AlbumViewController).failureCallback = self.failureCallback
                    present(controller, animated: true, completion: nil)
                } else if controller is ModalMediaViewController || controller is AnyModalViewController {
                    controller.modalPresentationStyle = .overFullScreen
                    present(controller, animated: true, completion: nil)
                } else {
                    VCPresenter.showVC(viewController: controller, popupIfPossible: true, parentNavigationController: navigationController, parentViewController: self)
                }
            }
        }
    }

    var color: UIColor?

    func setBarColors(color: UIColor) {
        self.color = color
        if SettingValues.reduceColor {
            self.color = ColorUtil.backgroundColor
        }
        setNavColors()
    }

    func setNavColors() {
        if let navigationController = navigationController {
            navigationController.navigationBar.shadowImage = UIImage()
            navigationController.navigationBar.barTintColor = color
            navigationController.navigationBar.titleTextAttributes = [
                NSForegroundColorAttributeName: SettingValues.reduceColor ? ColorUtil.fontColor : UIColor.white as Any,
            ]
            // If no color was specified but the color muxer is doing its thing,
            // grab the "from" color so that we don't get a white flash.
            if color == nil,
                let muxer = navigationController.delegate as? ColorMuxPagingViewController {
                    navigationController.navigationBar.barTintColor = muxer.color1
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.shadowImage = UIImage()
        setNavColors()
    }
}
