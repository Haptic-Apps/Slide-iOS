//
//  MediaViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/28/16.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import MaterialComponents.MaterialProgressView
import MaterialComponents.MDCBottomSheetController
import reddift
import SafariServices
import SDWebImage
import UIKit

class MediaViewController: UIViewController, MediaVCDelegate {

    var subChanged = false

    var link: RSubmission!
    var commentCallback: (() -> Void)?

    public func setLink(lnk: RSubmission, shownURL: URL?, lq: Bool, saveHistory: Bool) { //lq is should load lq and did load lq
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
                    doShow(url: URL.init(string: link!.videoPreview)!)
                } else {
                    doShow(url: url)
                }
            } else {
                if lq && shownURL != nil && !ContentType.isImgurLink(uri: url) {
                    doShow(url: url, lq: shownURL)
                } else if shownURL != nil && ContentType.imageType(t: type) && !ContentType.isImgurLink(uri: url) {
                    doShow(url: shownURL!)
                } else {
                    doShow(url: url)
                }
            }
        }
    }

    func getControllerForUrl(baseUrl: URL, lq: URL? = nil) -> UIViewController? {
        print(baseUrl)
        contentUrl = baseUrl
        if shouldTruncate(url: contentUrl!) {
            let content = contentUrl?.absoluteString
            contentUrl = URL.init(string: (content?.substring(to: content!.index(of: ".")!))!)
        }
        let type = ContentType.getContentType(baseUrl: contentUrl)

        if type == ContentType.CType.ALBUM && SettingValues.internalAlbumView {
            print("Showing album")
            return AlbumViewController.init(urlB: contentUrl!)
        } else if contentUrl != nil && ContentType.displayImage(t: type) && SettingValues.internalImageView || (type == .GIF && SettingValues.internalGifView) || type == .STREAMABLE || type == .VID_ME || (type == ContentType.CType.VIDEO && SettingValues.internalYouTube) {
            if !ContentType.isGifLoadInstantly(uri: baseUrl) && type == .GIF {
                if SettingValues.safariVC {
                    let safariVC = SFHideSafariViewController(url: baseUrl)
                    if #available(iOS 10.0, *) {
                        safariVC.preferredBarTintColor = ColorUtil.backgroundColor
                        safariVC.preferredControlTintColor = ColorUtil.fontColor
                    } else {
                        // Fallback on earlier versions
                    }
                    return safariVC
                }
                return WebsiteViewController(url: baseUrl, subreddit: link == nil ? "" : link.subreddit)
            }
            return SingleContentViewController.init(url: contentUrl!, lq: lq, commentCallback)
        } else if type == ContentType.CType.LINK || type == ContentType.CType.NONE {
            if SettingValues.safariVC {
                let safariVC = SFHideSafariViewController(url: baseUrl)
                if #available(iOS 10.0, *) {
                    safariVC.preferredBarTintColor = ColorUtil.backgroundColor
                    safariVC.preferredControlTintColor = ColorUtil.fontColor
                } else {
                    // Fallback on earlier versions
                }
                return safariVC
            }
            let web = WebsiteViewController(url: baseUrl, subreddit: link == nil ? "" : link.subreddit)
            return web
        } else if type == ContentType.CType.REDDIT {
            return RedditLink.getViewControllerForURL(urlS: contentUrl!)
        }
        if SettingValues.safariVC {
            let safariVC = SFHideSafariViewController(url: baseUrl)
            if #available(iOS 10.0, *) {
                safariVC.preferredBarTintColor = ColorUtil.backgroundColor
                safariVC.preferredControlTintColor = ColorUtil.fontColor
            } else {
                // Fallback on earlier versions
            }
            return safariVC
        }
        return WebsiteViewController(url: baseUrl, subreddit: link == nil ? "" : link.subreddit)
    }

    var contentUrl: URL?

    public func shouldTruncate(url: URL) -> Bool {
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

    func doShow(url: URL, lq: URL? = nil) {
        if ContentType.isExternal(url) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        } else {
            contentUrl = URL.init(string: String.init(htmlEncodedString: url.absoluteString))!
            if ContentType.isTable(uri: url) {
//                let controller = TableDisplayViewController.init(baseHtml: url.absoluteString, color: navigationController?.navigationBar.barTintColor ?? ColorUtil.getColorForSub(sub: ""))
//
//                let newParent = TapBehindModalViewController.init(rootViewController: controller)
//                newParent.navigationBar.shadowImage = UIImage()
//                newParent.navigationBar.isTranslucent = false
//
//                newParent.view.layer.cornerRadius = 15
//                newParent.view.clipsToBounds = true
//
//                present(MDCBottomSheetController.init(contentViewController: newParent), animated: true, completion: nil)

            } else if ContentType.isSpoiler(uri: url) {
                let controller = UIAlertController.init(title: "Spoiler", message: url.absoluteString, preferredStyle: .alert)
                present(controller, animated: true, completion: nil)
            } else {
                let controller = getControllerForUrl(baseUrl: url, lq: lq)!
                if controller is AlbumViewController {
                    controller.modalPresentationStyle = .overFullScreen
                    present(controller, animated: true, completion: nil)
                } else if controller is SingleContentViewController {
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
        setNavColors()
    }

    func setNavColors() {
        if navigationController != nil {
            self.navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.barTintColor = color
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.shadowImage = UIImage()
        setNavColors()
    }
}
