//
//  GifMWPhotoBrowser.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/3/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import ImageViewer

class GifMWPhotoBrowser: NSObject, GalleryItemsDataSource {
    
    func itemCount() -> Int {
        return photos.count
    }
    
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        if(photos.isEmpty){
            return GalleryItem.image(fetchImageBlock: { (completion) in
                
            })
        } else {
        return photos[index]
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

    var browser: GalleryViewController?
    
    func create(url: String) -> GalleryViewController {
        photos = []
        browser = GalleryViewController.init(startIndex: 0, itemsDataSource: self, itemsDelegate: nil, displacedViewsDataSource: nil, configuration: galleryConfiguration())
        print("Loading gif \(url)")
        getGif(urlS: url)
        return browser!
    }
    
    var photos: [GalleryItem] = []
    
    
    func loadGfycat(urlString: String){
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }
                    
                    let gif = GfycatJSONBase.init(dictionary: json)
                    
                    DispatchQueue.main.async{
                        self.loadVideo(urlString: (gif?.gfyItem?.mp4Url)!)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
            
            }.resume()
    }
    
    func getStreamableObject(urlString: String){
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }
                    
                    let gif = StreamableJSONBase.init(dictionary: json)
                    
                    DispatchQueue.main.async{
                        var video = ""
                        if let url = gif?.files?.mp4mobile?.url {
                            video = url
                        } else {
                            video = (gif?.files?.mp4?.url!)!
                        }
                        if(video.hasPrefix("//")){
                            video = "https:" + video
                        }
                        self.loadVideo(urlString: video)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
            
            }.resume()
    }
    
    func getVidMeObject(urlString: String){
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }
                    
                    let gif = VidMeJSONBase.init(dictionary: json)
                    
                    DispatchQueue.main.async{
                        self.loadVideo(urlString: (gif?.video?.complete_url)!)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
            
            }.resume()
    }
    
    func getSmallerGfy(gfy: String) -> String {
        var gfyUrl = gfy
        gfyUrl = gfyUrl.replacingOccurrences(of: "fat", with: "thumbs")
        gfyUrl = gfyUrl.replacingOccurrences(of: "giant", with: "thumbs")
        gfyUrl = gfyUrl.replacingOccurrences(of: "zippy", with: "thumbs")
        
        if (!gfyUrl.endsWith("-mobile.mp4")){
            gfyUrl = gfyUrl.replacingOccurrences(of: "\\.mp4", with: "-mobile.mp4")
        }
        return gfyUrl;
    }
    
    func transcodeGfycat(toTranscode: String){
        let url = URL(string: "https://upload.gfycat.com/transcode?fetchUrl=" + toTranscode)
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }
                    
                    let gif = GfycatTranscoded.init(dictionary: json)
                    
                    if let url = (gif?.mobileUrl != nil ? gif?.mobileUrl : gif?.mp4Url) {
                        DispatchQueue.main.async{
                            self.loadVideo(urlString: self.getSmallerGfy(gfy: url))
                        }
                    } else{
                        self.loadGfycat(urlString: "https://gfycat.com/cajax/get/" + (gif?.gfyName)!)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
            
            }.resume()
    }
    
    func checkLoadGfycat(urlString: String){
        let url = URL(string: "https://gfycat.com/cajax/checkUrl/" + urlString)
        URLSession.shared.dataTask(with:url!) { (data, response, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }
                    
                    let gif = GfycatCheck.init(dictionary: json)
                    
                    if(gif?.urlKnown == "true"){
                        DispatchQueue.main.async{
                            self.loadVideo(urlString: self.getSmallerGfy(gfy: (gif?.mp4Url)!))
                        }
                    } else {
                        self.transcodeGfycat(toTranscode: urlString)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
            
            }.resume()
    }
    
    func loadVideo(urlString: String){
        print("Showing \(urlString)")
        let photo = GalleryItem.video(fetchPreviewImageBlock: { (completion) in
            
        }, videoURL: URL.init(string: urlString)!)
        self.photos.append(photo)
        refresh()
    }
    func getGif(urlS: String){
        
        let url = formatUrl(sS: urlS)
        let videoType = getVideoType(url: url)
        
        switch (videoType) {
        case .GFYCAT:
            let name = url.substring(url.lastIndexOf("/")!, length:url.length - url.lastIndexOf("/")!)
            let gfycatUrl = "https://gfycat.com/cajax/get" + name;
            loadGfycat(urlString: gfycatUrl)
            break
        case .DIRECT:
            fallthrough
        case .IMGUR:
                self.loadVideo(urlString: url)
            break
        case .STREAMABLE:
            let hash = url.substring(url.lastIndexOf("/")! + 1, length: url.length - (url.lastIndexOf("/")! + 1));
            let streamableUrl = "https://api.streamable.com/videos/" + hash;
            getStreamableObject(urlString: streamableUrl)
            break
        case .VID_ME:
            let vidmeUrl = "https://api.vid.me/videoByUrl?url=" + url;
            getVidMeObject(urlString: vidmeUrl)
            break
            
        case .OTHER:
            checkLoadGfycat(urlString: url)
            break
        }
    }
    
    func refresh(){
        
        let vc = browser!.pagingDataSource.createItemController(0)
        browser!.setViewControllers([vc], direction: UIPageViewControllerNavigationDirection.reverse, animated: true, completion: nil)
    }
    
    
    func formatUrl(sS: String) -> String {
        var s = sS
        if (s.hasSuffix("v") && !s.contains("streamable.com")) {
            s = s.substring(0, length: s.length - 1);
        } else if (s.contains("gfycat") && (!s.contains("mp4") && !s.contains("webm"))) {
            if (s.contains("-size_restricted")) {s = s.replacingOccurrences(of: "-size_restricted", with: "")}
        }
        if ((s.contains(".webm") || s.contains(".gif")) && !s.contains(".gifv") && s.contains(
            "imgur.com")) {
            s = s.replacingOccurrences(of: ".gif", with: ".mp4");
            s = s.replacingOccurrences(of: ".webm", with: ".mp4");
        }
        if (s.endsWith("/")) {s = s.substring(0, length: s.length - 1)}
        
        return s;
    }
    
    func getVideoType(url: String) -> VideoType {
        if (url.contains(".mp4") || url.contains("webm")) {
            return VideoType.DIRECT
        }
        if (url.contains("gfycat") && !url.contains("mp4")) {
            return VideoType.GFYCAT}
        if (url.contains("imgur.com")) {return VideoType.IMGUR
        }
        if (url.contains("vid.me")) {
            return VideoType.VID_ME
        }
        if (url.contains("streamable.com")) {
            return VideoType.STREAMABLE
        }
        return VideoType.OTHER;
    }
    enum VideoType {
        case IMGUR
        case VID_ME
        case STREAMABLE
        case GFYCAT
        case DIRECT
        case OTHER
    }
    
}
