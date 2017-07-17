//
//  MediaViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/28/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import ImageViewer
import MaterialComponents.MaterialProgressView

class MediaViewController: UIViewController, GalleryItemsDataSource {
    
    var subChanged = false
    
    func itemCount() -> Int {
        return photos.count
    }
        
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        return photos[index]
    }
    
    var link:RSubmission!
    var paging = false
    var images:[URL] = []
    var photos:[GalleryItem] = []
    
    public func setLink(lnk: RSubmission, shownURL: URL?, lq : Bool){ //lq is should load lq and did load lq
        History.addSeen(s: lnk)
        self.link = lnk
        images = []
        if(ContentType.imageType(t: lnk.type) && !lq && shownURL != nil){
            doShow(url: shownURL!)
        } else if(ContentType.imageType(t: lnk.type) && lq && !SettingValues.loadContentHQ){
            doShow(url: shownURL!)
        } else {
            doShow(url: link.url!)
        }
    }
    
    func galleryConfiguration() -> GalleryConfiguration {
        
        return [
            
            GalleryConfigurationItem.closeButtonMode(.none),
            
            GalleryConfigurationItem.pagingMode(.standard),
            GalleryConfigurationItem.presentationStyle(.fade),
            GalleryConfigurationItem.hideDecorationViewsOnLaunch(false),
            
            GalleryConfigurationItem.swipeToDismissMode(.always),
            GalleryConfigurationItem.toggleDecorationViewsBySingleTap(true),
            
            GalleryConfigurationItem.overlayColor(UIColor(white: 0.035, alpha: 1)),
            GalleryConfigurationItem.overlayColorOpacity(0.75),
            GalleryConfigurationItem.overlayBlurOpacity(0.75),
            GalleryConfigurationItem.overlayBlurStyle(UIBlurEffectStyle.dark),
            
            GalleryConfigurationItem.maximumZoomScale(8),
            GalleryConfigurationItem.swipeToDismissThresholdVelocity(500),
            
            GalleryConfigurationItem.doubleTapToZoomDuration(0.15),
            GalleryConfigurationItem.footerViewLayout(FooterLayout.pinRight(8, 0)),
            
            GalleryConfigurationItem.blurPresentDuration(0.5),
            GalleryConfigurationItem.blurPresentDelay(0),
            GalleryConfigurationItem.colorPresentDuration(0.25),
            GalleryConfigurationItem.colorPresentDelay(0),
            
            GalleryConfigurationItem.blurDismissDuration(0.1),
            GalleryConfigurationItem.blurDismissDelay(0.4),
            GalleryConfigurationItem.colorDismissDuration(0.45),
            GalleryConfigurationItem.colorDismissDelay(0),
            
            GalleryConfigurationItem.itemFadeDuration(0.3),
            GalleryConfigurationItem.decorationViewsFadeDuration(0.15),
            GalleryConfigurationItem.rotationDuration(0.15),
            
            GalleryConfigurationItem.displacementDuration(0.55),
            GalleryConfigurationItem.reverseDisplacementDuration(0.25),
            GalleryConfigurationItem.displacementTransitionStyle(.springBounce(0.7)),
            GalleryConfigurationItem.displacementTimingCurve(.linear),
            
            GalleryConfigurationItem.statusBarHidden(false),
            
            GalleryConfigurationItem.deleteButtonMode(.none),
            GalleryConfigurationItem.thumbnailsButtonMode(.none)
        ]
    }
    
    var image: UIImage?

    func getControllerForUrl(baseUrl: URL) -> UIViewController? {
        images = []
        photos = []
        print(baseUrl )
        contentUrl = baseUrl
        var url = contentUrl?.absoluteString
        if(shouldTruncate(url: contentUrl!)){
            let content = contentUrl?.absoluteString
            contentUrl = URL.init(string: (content?.substring(to: (content?.characters.index(of: "."))!))!)
        }
        let type = ContentType.getContentType(baseUrl: contentUrl!)
        
        if(type == ContentType.CType.ALBUM && SettingValues.internalAlbumView){
            print("Showing album")
            if(url?.contains("/layout/"))!{
                url = url?.substring(0, length: (url?.indexOf("/layout")!)!);
            }
            var rawDat = cutEnds(s: url!);
            
            if (rawDat.endsWith("/")) {
                rawDat = rawDat.substring(0, length: rawDat.length - 1);
            }
            print(rawDat)
            print("\(rawDat.lastIndexOf("/")!) and \(rawDat.length)")
            if (rawDat.contains("/") && (rawDat.length - (rawDat.lastIndexOf("/")!+1)) < 4) {
                rawDat = rawDat.replacingOccurrences(of: rawDat.substring(rawDat.lastIndexOf("/")!, length: rawDat.length - (rawDat.lastIndexOf("/")!+1)), with: "");
            }
            if (rawDat.contains("?")) {
                rawDat = rawDat.substring(0, length: rawDat.length - rawDat.indexOf("?")!);
            }
            
            let hash = getHash(sS: rawDat);
            print("Hash is \(hash)")
            let ctrl = AlbumTableViewController()
            ctrl.getAlbum(hash: hash)
            return ctrl
        } else if (contentUrl != nil && ContentType.displayImage(t: type) && SettingValues.internalImageView) {
            print("Showing photo")
            
            if (ContentType.isImgurHash(uri: contentUrl!)) {
                images.append(URL.init(string: (contentUrl?.absoluteString)! + ".png")!)
                
            } else if(ContentType.isImage(uri: contentUrl!) || ContentType.isImgurImage(uri: contentUrl!)){
                images.append(URL.init(string: (contentUrl?.absoluteString)!)!)
                
            }
            for link in images {
                if(ContentType.isGif(uri: link)){
                    var link = link.absoluteString.replacingOccurrences(of: ".gifv", with: ".mp4")
                    link = link.replacingOccurrences(of: ".gif", with: ".mp4")
                    _ = GalleryItem.video(fetchPreviewImageBlock: { (completion) in
                        
                    }, videoURL: URL.init(string: link)!)
                } else {
                    let photo = GalleryItem.image(fetchImageBlock: { (completion) in
                        if(SDWebImageManager.shared().cachedImageExists(for: link)){
                            DispatchQueue.main.async {
                                var image = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: link.absoluteString)
                                self.image = image
                                self.progressView?.setHidden(true, animated: true)
                                self.size?.isHidden = true
                                completion(image)
                            }

                        } else {
                        SDWebImageDownloader.shared().downloadImage(with: link, options: .allowInvalidSSLCertificates, progress: { (current:NSInteger, total:NSInteger) in
                            var average: Float = 0
                            average = (Float (current) / Float(total))
                            let countBytes = ByteCountFormatter()
                            countBytes.allowedUnits = [.useMB]
                            countBytes.countStyle = .file
                            let fileSize = countBytes.string(fromByteCount: Int64(total))
                            self.size!.text = fileSize
                            self.progressView!.progress = average
                        }, completed: { (image, _, error, _) in
                            SDWebImageManager.shared().saveImage(toCache: image, for: link)
                            DispatchQueue.main.async {
                                self.image = image
                                self.progressView?.setHidden(true, animated: true)
                                self.size?.isHidden = true
                                completion(image)
                            }
                        })
                        }
                    })
                    photos.append(photo)
                }
            }
            
            let browser = GalleryViewController.init(startIndex: 0, itemsDataSource: self, itemsDelegate: nil, displacedViewsDataSource: nil, configuration: galleryConfiguration())
            var toolbar = UIToolbar()
            let space = UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target: nil, action: nil)
            var items: [UIBarButtonItem] = []
            
                items.append(space)
                items.append(UIBarButtonItem(image: UIImage(named: "download")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaViewController.download(_:))))
                items.append(UIBarButtonItem(image: UIImage(named: "ic_more_vert_white")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaViewController.showImageMenu(_:))))
                        toolbar.items = items
            toolbar.setBackgroundImage(UIImage(),
                                            forToolbarPosition: .any,
                                            barMetrics: .default)
            toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
            toolbar.tintColor = UIColor.white
            
            size = UILabel(frame: CGRect(x:5,y: toolbar.bounds.height,width: 250,height: 50))
            size?.textAlignment = .left
            size?.textColor = .white
            size?.text="mb"
            size?.font = UIFont.boldSystemFont(ofSize: 12)
            toolbar.addSubview(size!)

            progressView = MDCProgressView()
            progressView?.progress = 0

            let progressViewHeight = CGFloat(5)
            progressView?.frame = CGRect(x: 0, y: toolbar.bounds.height, width: toolbar.bounds.width, height: progressViewHeight)
            toolbar.addSubview(progressView!)

            browser.footerView?.backgroundColor = UIColor.clear
            browser.footerView = toolbar
            return browser
            
        } else if((type == .GIF && SettingValues.internalGifView) || type == .STREAMABLE || type == .VID_ME){
            print("Showing video")
            return GifMWPhotoBrowser().create(url: (contentUrl?.absoluteString)!)
        } else if(type == ContentType.CType.LINK || type == ContentType.CType.NONE){
            let web = WebsiteViewController(url: baseUrl, subreddit: link == nil ? "" : link.subreddit)
            return web
        } else if(type == ContentType.CType.REDDIT){
            return RedditLink.getViewControllerForURL(urlS: contentUrl!)
        } else if(type == ContentType.CType.VIDEO && SettingValues.internalYouTube){
            return YouTubeViewController.init(bUrl: contentUrl!, parent: self)
        }
        return WebsiteViewController(url: baseUrl, subreddit: link == nil ? "" : link.subreddit)
    }
    
    var size: UILabel?
    var progressView: MDCProgressView?
    
    func download(_ sender: AnyObject){
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
    }
    
    func showImageMenu(_ sender: AnyObject){
        let alert = UIAlertController.init(title: contentUrl?.absoluteString, message: "", preferredStyle: .actionSheet)
        let open = OpenInChromeController.init()
        if(open.isChromeInstalled()){
            alert.addAction(
                UIAlertAction(title: "Open in Chrome", style: .default) { (action) in
                    open.openInChrome(self.contentUrl!, callbackURL: nil, createNewTab: true)
                }
            )
        }
        alert.addAction(
            UIAlertAction(title: "Open in Safari", style: .default) { (action) in
                UIApplication.shared.open(self.contentUrl!, options: [:], completionHandler: nil)
            }
        )
        alert.addAction(
            UIAlertAction(title: "Share URL", style: .default) { (action) in
                let shareItems:Array = [self.contentUrl!]
                let activityViewController:UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                let window = UIApplication.shared.keyWindow!
                if let modalVC = window.rootViewController?.presentedViewController {
                    modalVC.present(activityViewController, animated: true, completion: nil)
                } else {
                    window.rootViewController!.present(activityViewController, animated: true, completion: nil)
                }
            }
        )
        alert.addAction(
            UIAlertAction(title: "Share Image", style: .default) { (action) in
                let shareItems:Array = [self.image!]
                let activityViewController:UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                let window = UIApplication.shared.keyWindow!
                if let modalVC = window.rootViewController?.presentedViewController {
                    modalVC.present(activityViewController, animated: true, completion: nil)
                } else {
                    window.rootViewController!.present(activityViewController, animated: true, completion: nil)
                }
            }
        )
        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            }
        )
        let window = UIApplication.shared.keyWindow!
        if let modalVC = window.rootViewController?.presentedViewController {
            modalVC.present(alert, animated: true, completion: nil)
        } else {
            window.rootViewController!.present(alert, animated: true, completion: nil)
        }
    }
    
    let overlayTransitioningDelegate = OverlayTransitioningDelegate()

    public func prepareOverlayVC(overlayVC: UIViewController) {
        overlayVC.transitioningDelegate = overlayTransitioningDelegate
        overlayVC.modalPresentationStyle = .custom
        overlayVC.view.layer.cornerRadius = 5
        overlayVC.view.layer.masksToBounds = true

    }
    
    var millis: Double = 0
    var playlist: String = ""
    
    func getYouTubeHash(urlS: URL)-> String{
        var  url = urlS.absoluteString
        if(url.contains("#t=")){
            url = url.replacingOccurrences(of: "#t=", with: url.contains("?") ? "&t=" : "?t=");
        }
        let queryItems = urlS.queryDictionary
        if(queryItems["list"] != nil){
            playlist = queryItems["list"]!
        }
        var video = ""
        if(url.endsWith("/")){
            url = url.substring(0, length: url.length - 1)
        }
        if(queryItems["v"] != nil){
            video = queryItems["v"]!
        } else if(queryItems["w"] != nil){
            video = queryItems["w"]!
        } else if(queryItems["v"] != nil){
            video = queryItems["v"]!
        } else if(url.lowercased().contains("youtu.be")){
            video = url.substring(url.lastIndexOf("/")!, length: url.length - url.lastIndexOf("/")!)
        } else if(queryItems["u"] != nil){
            let param = queryItems["u"]!
            video = param.substring(param.indexOf("=")! + 1, length: (param.contains("&") ? param.indexOf("&") : param.length - (param.indexOf("=")! + 1))!)
        }
        return video.hasPrefix("/") ? video.substring(1, length: video.length - 1) : video
    }
    
    
    // Do any additional setup after loading the view.
    
    
    var contentUrl:URL?

    public func shouldTruncate(url: URL) -> Bool {
        let path = url.path
        return !ContentType.isGif(uri: url) && !ContentType.isImage(uri: url) && path.contains(".");
    }
    
    func doShow(url: URL){
        print(url)
        contentUrl = url
        images = []
        let controller = getControllerForUrl(baseUrl: url)!
        if(controller is GalleryViewController){
            presentImageGallery(controller as! GalleryViewController)
        } else if( controller is YouTubeViewController){
            present(controller, animated: false, completion: nil)
        } else {
        show(controller, sender: self)
        }
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    var color: UIColor?
    
    func setBarColors(color: UIColor){
        self.color = color
        setNavColors()
    }
    
    func setNavColors(){
        if(navigationController != nil){
            navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.barTintColor = color
            navigationController?.navigationBar.tintColor = .white
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(!paging){
        navigationController?.navigationBar.shadowImage = UIImage()
        setNavColors()
        }
        navigationController?.isToolbarHidden = true
    }
    
    func getHash(sS:String) -> String {
        var s = sS
        if(s.contains("/comment/")){
            s = s.substring(0, length: s.indexOf("/comment")!);
        }
        var next = s.substring(s.lastIndexOf("/")!, length: s.length - s.lastIndexOf("/")!);
        if (next.contains(".")) {
            next = next.substring(0, length: next.indexOf(".")!);
        }
        if (next.startsWith("/")) {
            next = next.substring(1, length: next.length - 1);
        }
        if (next.length < 5) {
            return getHash(sS: s.replacingOccurrences(of: next, with: ""));
        } else {
            return next;
        }
        
    }
    
    func cutEnds(s:String) -> String {
        if (s.endsWith("/")) {
            return s.substring(0, length: s.length - 1);
        } else {
            return s;
        }
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    // Some external custom UIImageView we want to show in the gallery
    class FLSomeAnimatedImage: UIImageView {
    }
    
}

extension URL {
    
    var queryDictionary: [String: String] {
        var queryDictionary = [String: String]()
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else { return queryDictionary }
        queryItems.forEach { queryDictionary[$0.name] = $0.value }
        return queryDictionary
    }
    
}
