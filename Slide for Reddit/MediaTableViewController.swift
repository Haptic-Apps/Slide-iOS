//
//  MediaTableViewController.swift
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

class MediaTableViewController: UITableViewController, MediaVCDelegate, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behavior
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        setAlphaOfBackgroundViews(alpha: 1)
    }
    
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        setAlphaOfBackgroundViews(alpha: 0.25)
    }
    
    func setAlphaOfBackgroundViews(alpha: CGFloat) {
        /*let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow
        UIView.animate(withDuration: 0.2) {
            statusBarWindow?.alpha = alpha
            self.navigationController?.view.alpha = alpha
        }*/
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
            if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }
        } else {
            return .lightContent
        }
    }

    var subChanged = false

    var commentCallback: (() -> Void)?
    var upvoteCallback: (() -> Void)?
    var isUpvoted = false
    var failureCallback: ((_ url: URL) -> Void)?

    public func setLink(link: Submission, shownURL: URL?, lq: Bool, saveHistory: Bool, heroView: UIView?, finalSize: CGSize?, heroVC: UIViewController?, upvoteCallbackIn: (() -> Void)? = nil) { //lq is should load lq and did load lq
        if saveHistory {
            History.addSeen(s: link, skipDuplicates: true)
        }
        
        let url = link.url!
        let type = ContentType.getContentType(submission: link)

        commentCallback = { () in
            let comment = CommentViewController.init(submission: link, single: true)
            VCPresenter.showVC(viewController: comment, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }
        isUpvoted = ActionStates.getVoteDirection(s: link) == VoteDirection.up
        upvoteCallback = { () in
            do {
                try (UIApplication.shared.delegate as? AppDelegate)?.session?.setVote(ActionStates.getVoteDirection(s: link) == .up ? .none : .up, name: (link.id), completion: { (_) in
                    
                })
                ActionStates.setVoteDirection(s: link, direction: ActionStates.getVoteDirection(s: link) == .up ? .none : .up)
                History.addSeen(s: link)
            } catch {
                
            }
        }
        if link.isArchived || !AccountController.isLoggedIn {
            upvoteCallback = nil
        }
        if self is CommentViewController {
            commentCallback = nil
            upvoteCallback = nil
        }
        failureCallback = { (url: URL) in
            let vc: UIViewController
            if SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL || SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY {
                let safariVC = SFHideSafariViewController(url: url, entersReaderIfAvailable: SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY)
                if #available(iOS 10.0, *) {
                    safariVC.preferredBarTintColor = ColorUtil.theme.foregroundColor
                    safariVC.preferredControlTintColor = ColorUtil.theme.fontColor
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
        
        if type == .EXTERNAL {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(link.url!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(link.url!)
            }
        } else {
            if ContentType.isGif(uri: url) {
                if !link.videoPreview.isEmpty() && !ContentType.isGfycat(uri: url) {
                    doShow(url: URL.init(string: link.videoPreview)!, heroView: heroView, finalSize: finalSize, heroVC: heroVC, link: link)
                } else {
                    doShow(url: url, heroView: heroView, finalSize: finalSize, heroVC: heroVC, link: link)
                }
            } else {
                if lq && shownURL != nil && !ContentType.isImgurLink(uri: url) {
                    doShow(url: url, lq: shownURL, heroView: heroView, finalSize: finalSize, heroVC: heroVC, link: link)
                } else if shownURL != nil && ContentType.imageType(t: type) && !ContentType.isImgurLink(uri: url) {
                    doShow(url: shownURL!, heroView: heroView, finalSize: finalSize, heroVC: heroVC, link: link)
                } else {
                    doShow(url: url, heroView: heroView, finalSize: finalSize, heroVC: heroVC, link: link)
                }
            }
        }
    }
    
    func getControllerForUrl(baseUrl: URL, lq: URL? = nil, link: Submission) -> UIViewController? {
        contentUrl = baseUrl.absoluteString.startsWith("//") ? URL(string: "https:\(baseUrl.absoluteString)") ?? baseUrl : baseUrl

        if shouldTruncate(url: contentUrl!) {
            let content = contentUrl?.absoluteString
            contentUrl = URL.init(string: (String(content?[..<content!.firstIndex(of: ".")!] ?? "")))
        }

        let type = ContentType.getContentType(baseUrl: contentUrl)
        
        if type == ContentType.CType.ALBUM && SettingValues.internalAlbumView {
            return AlbumViewController(urlB: contentUrl!)
        } else if type == ContentType.CType.REDDIT_GALLERY {
            return AlbumViewController(galleryItems: link.gallery)
        } else if contentUrl != nil && ContentType.displayImage(t: type) && SettingValues.internalImageView || (type == ContentType.CType.VIDEO && SettingValues.internalYouTube) {
            return ModalMediaViewController.init(url: contentUrl!, lq: lq, commentCallback, upvoteCallback: upvoteCallback, isUpvoted: isUpvoted, failureCallback, link: link)
        } else if type == .GIF && SettingValues.internalGifView || type == .STREAMABLE || type == .VID_ME {
            if !ContentType.isGifLoadInstantly(uri: contentUrl!) && type == .GIF {
                if SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL || SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY {
                    let safariVC = SFHideSafariViewController(url: contentUrl!, entersReaderIfAvailable: SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY)
                    if #available(iOS 10.0, *) {
                        safariVC.preferredBarTintColor = ColorUtil.theme.foregroundColor
                        safariVC.preferredControlTintColor = ColorUtil.theme.fontColor
                    } else {
                        // Fallback on earlier versions
                    }
                    return safariVC
                }
                return WebsiteViewController(url: contentUrl!, subreddit: link == nil ? "" : link.subreddit)
            }
            return ModalMediaViewController.init(url: contentUrl!, lq: lq, commentCallback, upvoteCallback: upvoteCallback, isUpvoted: isUpvoted, failureCallback, link: link)
        } else if type == ContentType.CType.LINK || type == ContentType.CType.NONE {
            if SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL || SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY {
                let safariVC = SFHideSafariViewController(url: contentUrl!, entersReaderIfAvailable: SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY)
                if #available(iOS 10.0, *) {
                    safariVC.preferredBarTintColor = ColorUtil.theme.foregroundColor
                    safariVC.preferredControlTintColor = ColorUtil.theme.fontColor
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
                safariVC.preferredBarTintColor = ColorUtil.theme.foregroundColor
                safariVC.preferredControlTintColor = ColorUtil.theme.fontColor
            } else {
                // Fallback on earlier versions
            }
            return safariVC
        }
        return WebsiteViewController(url: contentUrl!, subreddit: link == nil ? "" : link.subreddit)
    }

    var contentUrl: URL?

    public func shouldTruncate(url: URL) -> Bool {
        return false // TODO: - figure out what this does
        let path = url.path
        return !ContentType.isGif(uri: url) && !ContentType.isImage(uri: url) && path.contains(".")
    }

    func showSpoiler(_ string: String) {
        let controller = UIAlertController.init(title: "Spoiler", message: string, preferredStyle: .alert)
        controller.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: nil))
        present(controller, animated: true, completion: nil)
    }

    public static func handleCloseNav(controller: UIButtonWithContext) {
        controller.parentController!.dismiss(animated: true)
    }

    func doShow(url: URL, lq: URL? = nil, heroView: UIView?, finalSize: CGSize?, heroVC: UIViewController?, link: Submission) {
        failureCallback = {[weak self] (url: URL) in
            guard let strongSelf = self else { return }
            let vc: UIViewController
            if SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL || SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY {
                let safariVC = SFHideSafariViewController(url: url, entersReaderIfAvailable: SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY)
                if #available(iOS 10.0, *) {
                    safariVC.preferredBarTintColor = ColorUtil.theme.foregroundColor
                    safariVC.preferredControlTintColor = ColorUtil.theme.fontColor
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
            } else if browser == SettingValues.BROWSER_DDG {
                newUrl = URL(string: "ddgQuickLink://" + sanitized) ?? oldUrl
            } else if browser == SettingValues.BROWSER_BRAVE {
                newUrl = URL(string: "brave://open-url?url=" + (oldUrl.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? oldUrl.absoluteString)) ?? oldUrl
            } else if browser == SettingValues.BROWSER_OPERA {
                newUrl = URL(string: "opera-http://" + sanitized) ?? oldUrl
            } else if browser == SettingValues.BROWSER_FIREFOX {
                newUrl = URL(string: "firefox://open-url?url=" + oldUrl.absoluteString) ?? oldUrl
            } else if browser == SettingValues.BROWSER_FOCUS {
                newUrl = URL(string: "firefox-focus://open-url?url=" + oldUrl.absoluteString) ?? oldUrl
            } else if browser == SettingValues.BROWSER_FOCUS_KLAR {
                newUrl = URL(string: "firefox-klar://open-url?url=" + oldUrl.absoluteString) ?? oldUrl
            }

            // If it's a youtube video, always use safari so the app will open
            let type = ContentType.getContentType(baseUrl: url)
            if type == ContentType.CType.VIDEO && !SettingValues.internalYouTube {
                let youtubeURL = URL(string: oldUrl.absoluteString.replacingOccurrences(of: "https://", with: "youtube://").replacingOccurrences(of: "http://", with: "youtube://"))!
                if UIApplication.shared.canOpenURL(youtubeURL) {
                    newUrl = youtubeURL
                } else {
                    newUrl = oldUrl
                }
            }

            if #available(iOS 10.0, *) {
                UIApplication.shared.open(newUrl, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(newUrl)
            }
        } else if url.scheme == "slide" {
            UIApplication.shared.openURL(url)
        } else {
            var urlString = url.absoluteString
            if urlString.startsWith("//") {
                urlString = "https:" + urlString
            }
            contentUrl = URL.init(string: urlString)!
            
            if ContentType.isSpoiler(uri: url) {
                let controller = UIAlertController.init(title: "Spoiler", message: url.absoluteString, preferredStyle: .alert)
                controller.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: nil))
                present(controller, animated: true, completion: nil)
            } else {
                let controller = getControllerForUrl(baseUrl: contentUrl!, lq: lq, link: link)!
                if controller is AlbumViewController {
                    controller.modalPresentationStyle = .overFullScreen
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
            self.color = self is CommentViewController ? ColorUtil.theme.foregroundColor : ColorUtil.theme.foregroundColor
        }
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

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return SmallerPresentationController(presentedViewController: presented,
                                             presenting: presenting)
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}
