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
import AVKit

class MediaDisplayViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, YTPlayerViewDelegate {
    
    var baseURL: URL?
    var loadedURL: URL?
    var type: ContentType.CType = ContentType.CType.UNKNOWN
    var lqURL: URL?
    var text: String?
    
    var size: UILabel?
    var progressView: MDCProgressView?
    var scrollView = UIScrollView()
    var imageView = UIImageView()
    static var videoPlayer : AVPlayer? = nil
    var videoView = UIView()
    var ytPlayer = YTPlayerView()
    var playerVC = AVPlayerViewController()
    var menuB : UIBarButtonItem?
    var inAlbum = false
    
    init(url: URL, text: String?, lqURL: URL?, inAlbum : Bool = false){
        super.init(nibName: nil, bundle: nil)
        self.baseURL = url
        self.lqURL = lqURL
        self.text = text
        self.inAlbum = inAlbum
        type = ContentType.getContentType(baseUrl: url)
    }
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func displayImage(baseImage: UIImage?){
        if(baseImage == nil){
            
        }
        let image = baseImage!
        self.scrollView.contentSize = CGSize.init(width: self.view.frame.size.width, height: getHeightFromAspectRatio(imageHeight: image.size.height, imageWidth: image.size.width))
        self.scrollView.delegate = self
        
        let dtap = UITapGestureRecognizer.init(target: self, action: #selector (handleDoubleTapScrollView(recognizer:)))
        dtap.numberOfTapsRequired = 2
        self.scrollView.addGestureRecognizer(dtap)
        
        if(!inAlbum){
        let tap = UITapGestureRecognizer.init(target: self, action: #selector (close(recognizer:)))
            tap.require(toFail: dtap)
        self.scrollView.addGestureRecognizer(tap)
        }

        imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        imageView.contentMode = .scaleAspectFit
        self.scrollView.addSubview(imageView)
        imageView.image = image
        
        if(showHQ){
            var items: [UIBarButtonItem] = []
            if(text != nil && !(text!.isEmpty)){
                let textB = UIBarButtonItem(image: UIImage(named: "size")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaDisplayViewController.showTitle(_:)))
                items.append(textB)
            }
            let space = UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target: nil, action: nil)
            let hdB = UIBarButtonItem(image: UIImage(named: "hd")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaDisplayViewController.hd(_:)))
            items.append(hdB)
            items.append(space)
            items.append(UIBarButtonItem(image: UIImage(named: "download")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaDisplayViewController.download(_:))))
            menuB = UIBarButtonItem(image: UIImage(named: "ic_more_vert_white")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaDisplayViewController.showImageMenu(_:)))
            items.append(menuB!)
            toolbar.items = items

        }
    }
    
    func close(recognizer: UITapGestureRecognizer){
        self.parent?.dismiss(animated: true, completion: nil)
    }
    
    func hd(_ sender: AnyObject){
        size?.isHidden = false
        var items: [UIBarButtonItem] = []
        if(text != nil && !(text!.isEmpty)){
            let textB = UIBarButtonItem(image: UIImage(named: "size")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaDisplayViewController.showTitle(_:)))
            items.append(textB)
        }
        let space = UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target: nil, action: nil)
        items.append(space)
        items.append(UIBarButtonItem(image: UIImage(named: "download")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaDisplayViewController.download(_:))))
        menuB = UIBarButtonItem(image: UIImage(named: "ic_more_vert_white")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaDisplayViewController.showImageMenu(_:)))
        items.append(menuB!)
        toolbar.items = items

        progressView?.setHidden(false, animated: true, completion: nil)
        showHQ = false
        loadImage(imageURL: baseURL!)
    }
    
    @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    

    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func loadImage(imageURL: URL){
        loadedURL = imageURL
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
    
    func getHeightFromAspectRatio(imageHeight:CGFloat, imageWidth: CGFloat) -> CGFloat {
        let ratio = Double(imageHeight)/Double(imageWidth)
        let width = Double(view.frame.size.width);
        return CGFloat(width * ratio)
        
    }
    
    var toolbar = UIToolbar()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        self.scrollView.minimumZoomScale=1
        self.scrollView.maximumZoomScale=6.0
        self.scrollView.backgroundColor = .clear
        self.view.addSubview(scrollView)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toolbar = UIToolbar.init(frame: CGRect.init(x: 0, y: self.view.frame.size.height - 35, width: self.view.frame.size.width, height:  30))
        let space = UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target: nil, action: nil)
        var items: [UIBarButtonItem] = []
        if(text != nil && !(text!.isEmpty)){
            var textB = UIBarButtonItem(image: UIImage(named: "size")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaDisplayViewController.showTitle(_:)))
            items.append(textB)
        }

        items.append(space)
        items.append(UIBarButtonItem(image: UIImage(named: "download")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaDisplayViewController.download(_:))))
        menuB = UIBarButtonItem(image: UIImage(named: "ic_more_vert_white")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(MediaDisplayViewController.showImageMenu(_:)))
        items.append(menuB!)
        toolbar.items = items
        toolbar.setBackgroundImage(UIImage(),
                                   forToolbarPosition: .any,
                                   barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        toolbar.tintColor = UIColor.white
        
        size = UILabel(frame: CGRect(x:5,y: toolbar.bounds.height - 40,width: 250,height: 50))
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
    
    func showTitle(_ sender: AnyObject){
        let alertController = MDCAlertController(title: nil, message: text!)
        let action = MDCAlertAction(title:"DONE") { (action) in print("OK") }
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
    
    func download(_ sender: AnyObject){
        UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil)
    }
    
    func showImageMenu(_ sender: AnyObject){
        let alert = UIAlertController.init(title: baseURL?.absoluteString, message: "", preferredStyle: .actionSheet)
        let open = OpenInChromeController.init()
        if(open.isChromeInstalled()){
            alert.addAction(
                UIAlertAction(title: "Open in Chrome", style: .default) { (action) in
                    open.openInChrome(self.baseURL!, callbackURL: nil, createNewTab: true)
                }
            )
        }
        alert.addAction(
            UIAlertAction(title: "Open in Safari", style: .default) { (action) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(self.baseURL!, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(self.baseURL!)
                }
            }
        )
        alert.addAction(
            UIAlertAction(title: "Share URL", style: .default) { (action) in
                let shareItems:Array = [self.baseURL!]
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
                let shareItems:Array = [self.imageView.image!]
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
        alert.modalPresentationStyle = .popover
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = (menuB!.value(forKey: "view") as! UIView)
            presenter.sourceRect = (menuB!.value(forKey: "view") as! UIView).bounds
        }
        
        
        if let modalVC = window.rootViewController?.presentedViewController {
            modalVC.present(alert, animated: true, completion: nil)
        } else {
            window.rootViewController!.present(alert, animated: true, completion: nil)
        }
    }
    
    var showHQ = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func startDisplay(){
        if(type == .IMAGE ){
            let shouldShowLq = SettingValues.dataSavingEnabled && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi())
            if(lqURL != nil && !SettingValues.loadContentHQ && shouldShowLq){
                loadImage(imageURL: lqURL!)
                showHQ = true
            } else {
                loadImage(imageURL: baseURL!)
            }
        } else if(type == .GIF || type == .STREAMABLE || type == .VID_ME){
            getGif(urlS: baseURL!.absoluteString)
        } else if(type == .IMGUR){
            loadImage(imageURL: URL.init(string: baseURL!.absoluteString + ".png")!)
        } else if(type == .VIDEO){
            toolbar.isHidden = true
            let he = getYTHeight()
            ytPlayer = YTPlayerView.init(frame: CGRect.init(x: 0, y: (self.view.frame.size.height - he)/2, width: self.view.frame.size.width, height: he))
            ytPlayer.isHidden = true
            self.view.addSubview(ytPlayer)
            getYouTube(urlS: baseURL!.absoluteString)
        }
    }
    
    func getYTHeight() -> CGFloat {
        let height = ((self.view.frame.size.width / 16)*9)
        return height
    }
    
    func getYouTube(urlS: String){
        var url = urlS
        if(url.contains("#t=")){
            url = url.replacingOccurrences(of: "#t=", with: url.contains("?") ? "&t=" : "?t=")
        }
        
        let i = URL.init(string: url)
        if let dictionary = i?.queryDictionary {
            if let t = dictionary["t"]{
                millis = getTimeFromString(t);
            } else if let start = dictionary["start"] {
                millis = getTimeFromString(start);
            }
            
            if let list = dictionary["list"]{
                playlist = list
            }
            
            if let v = dictionary["v"]{
                video = v
            } else if let w = dictionary["w"]{
                video = w
            } else if url.lowercased().contains("youtu.be"){
                video = getLastPathSegment(url)
            }
            
            if let u = dictionary["u"]{
                let param =  u
                video = param.substring(param.indexOf("=")! + 1, length: param.contains("&") ? param.indexOf("&")! : param.length);
            }
        }
        self.ytPlayer.delegate = self
        if(!playlist.isEmpty){
            ytPlayer.load(withPlaylistId: playlist)
        } else {
            ytPlayer.load(withVideoId: video, playerVars: ["controls":1,"playsinline":1,"start":millis,"fs":0])
        }

    }
    
    func getLastPathSegment(_ path: String) -> String {
        var inv = path
        if(inv.endsWith("/")){
            inv = inv.substring(0, length: inv.length - 1)
        }
        let slashindex = inv.lastIndexOf("/")!
        print("Index is \(slashindex)")
        inv = inv.substring(slashindex + 1, length: inv.length - slashindex - 1)
        return inv
    }
    var millis = 0
    var video = ""
    var playlist = ""
    
    func getTimeFromString(_ time: String) -> Int {
        var timeAdd = 0;
        for s in time.components(separatedBy: CharacterSet.init(charactersIn: "hms")){
            print(s)
            if(!s.isEmpty){
            if(time.contains(s + "s")){
                timeAdd += Int(s)!;
            } else if(time.contains(s + "m")){
                timeAdd += 60 * Int(s)!;
            } else if(time.contains(s + "h")){
                timeAdd += 3600 * Int(s)!;
            }
            }
        }
        if(timeAdd == 0 && Int(time) != nil){
            timeAdd+=Int(time)!;
        }
        
        return timeAdd * 1000;
        
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
        if(MediaDisplayViewController.videoPlayer != nil){
            MediaDisplayViewController.videoPlayer!.pause()
        }
    }
    
    func playerItemDidReachEnd(notification: NSNotification) {
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: kCMTimeZero)
        }
    }
    
    func display(_ file: URL){
        self.progressView?.setHidden(true, animated: true)
        self.size?.isHidden = true
        self.scrollView.contentSize = CGSize.init(width: self.view.frame.width, height: self.view.frame.height)
        self.scrollView.delegate = self
        if(MediaDisplayViewController.videoPlayer == nil){
        MediaDisplayViewController.videoPlayer = AVPlayer.init(playerItem: AVPlayerItem.init(url: file))
        } else {
            MediaDisplayViewController.videoPlayer!.replaceCurrentItem(with: AVPlayerItem.init(url: file))
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MediaDisplayViewController.playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: MediaDisplayViewController.videoPlayer!.currentItem)
        MediaDisplayViewController.videoPlayer!.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        
        playerVC = AVControlsPlayer()
        playerVC.player = MediaDisplayViewController.videoPlayer!
        playerVC.videoGravity = AVLayerVideoGravityResizeAspect
        playerVC.showsPlaybackControls = false
        
        videoView = playerVC.view
        addChildViewController(playerVC)
        scrollView.addSubview(videoView)
        videoView.frame = CGRect.init(x: 0, y: 50, width: self.view.frame.width, height: self.view.frame.height - 80)
        playerVC.didMove(toParentViewController: self)
        
        self.scrollView.isUserInteractionEnabled = true
        MediaDisplayViewController.videoPlayer!.play()
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
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        playerView.isHidden = false
        self.ytPlayer.playVideo()
    }

    
    /// Prevents delivery of touch gestures to AVPlayerViewController's gesture recognizer,
    /// which would cause controls to hide immediately after being shown.
    ///
    /// `-[AVPlayerViewController _handleSingleTapGesture] goes like this:
    ///
    ///     if self._showsPlaybackControlsView() {
    ///         _hidePlaybackControlsViewIfPossibleUntilFurtherUserInteraction()
    ///     } else {
    ///         _showPlaybackControlsViewIfNeededAndHideIfPossibleAfterDelayIfPlaying()
    ///     }
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if !playerVC.showsPlaybackControls {
            // print("\nshouldBeRequiredToFailByGestureRecognizer? \(otherGestureRecognizer)")
            if let tapGesture = otherGestureRecognizer as? UITapGestureRecognizer {
                if tapGesture.numberOfTouchesRequired == 1 {
                    return true
                }
            }
        }
        return false
    }
    
}
