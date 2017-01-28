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
import AMScrollingNavbar
import ImageViewer

class MediaViewController: UIViewController, GalleryItemsDataSource {
    
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
    
    public func setLink(lnk: RSubmission){
        History.addSeen(s: lnk)
        self.link = lnk
        images = []
        print(link.url ?? "Null link")
        doShow(url: link.url!);
    }
    
    func galleryConfiguration() -> GalleryConfiguration {
        
        return [
            
            GalleryConfigurationItem.closeButtonMode(.builtIn),
            
            GalleryConfigurationItem.pagingMode(.standard),
            GalleryConfigurationItem.presentationStyle(.fade),
            GalleryConfigurationItem.hideDecorationViewsOnLaunch(true),
            
            GalleryConfigurationItem.swipeToDismissMode(.vertical),
            GalleryConfigurationItem.toggleDecorationViewsBySingleTap(true),
            
            GalleryConfigurationItem.overlayColor(UIColor(white: 0.035, alpha: 1)),
            GalleryConfigurationItem.overlayColorOpacity(1),
            GalleryConfigurationItem.overlayBlurOpacity(1),
            GalleryConfigurationItem.overlayBlurStyle(UIBlurEffectStyle.dark),
            
            GalleryConfigurationItem.maximumZoomScale(8),
            GalleryConfigurationItem.swipeToDismissThresholdVelocity(500),
            
            GalleryConfigurationItem.doubleTapToZoomDuration(0.15),
            
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
            
            GalleryConfigurationItem.statusBarHidden(true),
            GalleryConfigurationItem.displacementKeepOriginalInPlace(false),
            GalleryConfigurationItem.displacementInsetMargin(50),
            
            GalleryConfigurationItem.deleteButtonMode(.none),
            GalleryConfigurationItem.thumbnailsButtonMode(.none)
        ]
    }
    

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
        
        if(type == ContentType.CType.ALBUM){
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
            return AlbumMWPhotoBrowser().create(hash:hash)
            
        } else if (contentUrl != nil && ContentType.displayImage(t: type)) {
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
                        SDWebImageDownloader.shared().downloadImage(with: link, options: .allowInvalidSSLCertificates, progress: { (current, total) in
                            
                        }, completed: { (image, _, error, _) in
                            DispatchQueue.main.async {
                                completion(image)
                            }
                        })
                    })
                    photos.append(photo)
                }
            }
            let browser = GalleryViewController.init(startIndex: 0, itemsDataSource: self, itemsDelegate: nil, displacedViewsDataSource: nil, configuration: galleryConfiguration())
            return browser
            
        } else if(type == .GIF || type == .STREAMABLE || type == .VID_ME){
            print("Showing video")
            return GifMWPhotoBrowser().create(url: (contentUrl?.absoluteString)!)
        } else if(type == ContentType.CType.LINK || type == ContentType.CType.NONE){
            let web = WebsiteViewController(url: baseUrl, subreddit: link == nil ? "" : link.subreddit)
            return web
        } else if(type == ContentType.CType.REDDIT){
            return RedditLink.getViewControllerForURL(urlS: contentUrl!)
        } else if(type == ContentType.CType.VIDEO){
            print("Showing youtube")
            
            let hash = getYouTubeHash(urlS: contentUrl!)
            //todo
        }
        return WebsiteViewController(url: baseUrl, subreddit: link == nil ? "" : link.subreddit)
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
    
    var progress: UIProgressView = UIProgressView()
    
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
        } else {
        show(controller, sender: self)
        }
        (navigationController as? ScrollingNavigationController)?.showNavbar(animated: true)
    }
    
    var color: UIColor?
    
    func setBarColors(color: UIColor){
        self.color = color
        setNavColors()
    }
    
    func setNavColors(){
        if(navigationController != nil){
            (navigationController as? ScrollingNavigationController)?.showNavbar(animated: true)
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
