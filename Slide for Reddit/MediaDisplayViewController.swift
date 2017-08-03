//
//  MediaDisplayViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/2/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialProgressView
import SDWebImage
import AVFoundation
import Alamofire

class MediaDisplayViewController: UIViewController, UIScrollViewDelegate {
    
    var baseURL: URL?
    var loadedURL: URL?
    var type: ContentType.CType = ContentType.CType.UNKNOWN
    
    var size: UILabel?
    var progressView: MDCProgressView?
    var scrollView = UIScrollView()
    var imageView = UIImageView()
    var videoPlayer = AVPlayer()
    var videoView = AVPlayerLayer()
    var menuB : UIBarButtonItem?
    
    init(url: URL){
        super.init(nibName: nil, bundle: nil)
        self.baseURL = url
        type = ContentType.getContentType(baseUrl: url)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func displayImage(baseImage: UIImage?){
        if(baseImage == nil){
            
        }
        let image = baseImage!
        self.scrollView.contentSize = CGSize.init(width: image.size.width, height: image.size.height)
        self.scrollView.delegate = self
        imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        imageView.contentMode = .scaleAspectFit
        self.scrollView.addSubview(imageView)
        imageView.image = image
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func loadImage(imageURL: URL){
        loadedURL = imageURL
        print("Found \(size!.text)")
        if(SDWebImageManager.shared().cachedImageExists(for: imageURL)){
            DispatchQueue.main.async {
                let image = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: imageURL.absoluteString)
                self.progressView?.setHidden(true, animated: true)
                self.size?.isHidden = true
                self.displayImage(baseImage: image)
            }
            
        } else {
            SDWebImageDownloader.shared().downloadImage(with: imageURL, options: .allowInvalidSSLCertificates, progress: { (current:NSInteger, total:NSInteger) in
                var average: Float = 0
                average = (Float (current) / Float(total))
                let countBytes = ByteCountFormatter()
                countBytes.allowedUnits = [.useMB]
                countBytes.countStyle = .file
                let fileSize = countBytes.string(fromByteCount: Int64(total))
                self.size!.text = fileSize
                self.progressView!.progress = average
            }, completed: { (image, _, error, _) in
                SDWebImageManager.shared().saveImage(toCache: image, for: imageURL)
                DispatchQueue.main.async {
                    self.progressView?.setHidden(true, animated: true)
                    self.size?.isHidden = true
                    self.displayImage(baseImage: image)
                }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        self.scrollView.minimumZoomScale=1
        self.scrollView.maximumZoomScale=6.0
        self.scrollView.backgroundColor = .clear
        self.view.addSubview(scrollView)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        let toolbar = UIToolbar.init(frame: CGRect.init(x: 0, y: self.view.frame.size.height - 30, width: self.view.frame.size.width, height:  30))
        let space = UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target: nil, action: nil)
        var items: [UIBarButtonItem] = []
        
        items.append(space)
        items.append(UIBarButtonItem(image: UIImage(named: "download")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaViewController.download(_:))))
        menuB = UIBarButtonItem(image: UIImage(named: "ic_more_vert_white")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaViewController.showImageMenu(_:)))
        items.append(menuB!)
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

        self.view.addSubview(toolbar)

        startDisplay()
    }
    
    func startDisplay(){
        if(type == .IMAGE ){
            loadImage(imageURL: baseURL!)
        } else if(type == .GIF || type == .VIDEO || type == .STREAMABLE || type == .VID_ME){
            getGif(urlS: baseURL!.absoluteString)
        }
    }
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
        refresh(urlString)
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
    
    func refresh(_ toLoad:String){
            let disallowedChars = CharacterSet.urlPathAllowed.inverted
            var key = toLoad.components(separatedBy: disallowedChars).joined(separator: "_")
            key = key.replacingOccurrences(of: ":", with: "")
            key = key.replacingOccurrences(of: "/", with: "")
            key = key.replacingOccurrences(of: ".", with: "")
            key = key + ".mp4"
            print(key)
            if(key.length > 200){
                key = key.substring(0, length: 200)
            }
            if(FileManager.default.fileExists(atPath: SDImageCache.shared().makeDiskCachePath(key)) ){
                display(URL.init(fileURLWithPath:SDImageCache.shared().makeDiskCachePath(key)))
            } else {
                let localUrl =   URL.init(fileURLWithPath:SDImageCache.shared().makeDiskCachePath(key))
                print(localUrl)
                request = Alamofire.download(toLoad, method: .get, to: { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                    return (localUrl, [.createIntermediateDirectories])
                    
                }).downloadProgress() { progress in
                    DispatchQueue.main.async {
                        self.progressView!.progress = Float(progress.fractionCompleted)
                        let countBytes = ByteCountFormatter()
                        countBytes.allowedUnits = [.useMB]
                        countBytes.countStyle = .file
                        let fileSize = countBytes.string(fromByteCount: Int64(progress.totalUnitCount))
                        self.size!.text = fileSize
                        print("Progress is \(progress.fractionCompleted)")
                    }
                    
                    }
                    .responseData { response in
                        if let error = response.error {
                            print(error)
                        } else { //no errors
                            self.display(localUrl)
                            print("File downloaded successfully: \(localUrl)")
                        }
                }
                
            }
        }
    
    
    var request: DownloadRequest?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        request?.cancel()
    }
    
    func playerItemDidReachEnd(notification: NSNotification) {
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: kCMTimeZero)
        }
    }

    func display(_ file: URL){
            print("Displaying \(file)")
        self.scrollView.contentSize = CGSize.init(width: self.view.frame.width, height: self.view.frame.height)
        self.scrollView.delegate = self
        self.videoPlayer = AVPlayer.init(playerItem: AVPlayerItem.init(url: file))
        videoView = AVPlayerLayer(player: videoPlayer)
        videoView.videoGravity = AVLayerVideoGravityResizeAspect
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MediaDisplayViewController.playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: videoPlayer.currentItem)
        videoPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        videoView.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.scrollView.layer.insertSublayer(videoView, at: 0)
        videoPlayer.play()
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
