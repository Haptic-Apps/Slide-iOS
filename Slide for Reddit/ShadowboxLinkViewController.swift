//
//  ShadowboxLinkViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/4/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialProgressView
import SDWebImage
import AVFoundation
import Alamofire
import AVKit
import TTTAttributedLabel

class ShadowboxLinkViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    var submission: RSubmission?
    var baseURL: URL?
    var type: ContentType.CType = ContentType.CType.UNKNOWN
    
    var scrollView = UIScrollView()
    var imageView = UIImageView()
    var textB = TTTAttributedLabel.init(frame: CGRect.zero)
    
    var menuB = UIBarButtonItem()
    var upvoteB = UIBarButtonItem()
    var commentsB = UIBarButtonItem()
    
    init(submission: RSubmission){
        self.submission = submission
        self.baseURL = submission.url
        super.init(nibName: nil, bundle: nil)
        type = ContentType.getContentType(baseUrl: baseURL!)
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
        self.scrollView.isScrollEnabled = false
        
        imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        imageView.contentMode = .scaleAspectFill
        self.scrollView.addSubview(imageView)
        imageView.image = image
        
        var gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = imageView.frame
        gradient.colors = [UIColor.black.withAlphaComponent(0.7).cgColor, UIColor.clear.cgColor]
        gradient.locations = [0.0, 0.1]
        imageView.layer.insertSublayer(gradient, at: 0)
         gradient = CAGradientLayer()
        gradient.frame = imageView.frame
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.7).cgColor]
        var percent = ((textB.frame.size.height + 30)/self.view.frame.size.height)
        print("Percent is \(percent)")
        gradient.locations = [NSNumber.init(value: Double(percent)), 1]
        imageView.layer.insertSublayer(gradient, at: 0)

    }
    
    func loadImage(imageURLB: URL?){
        if(imageURLB == nil){
            
            return
        }
        let imageURL = imageURLB!
                if(SDWebImageManager.shared().cachedImageExists(for: imageURL)){
            DispatchQueue.main.async {
                let image = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: imageURL.absoluteString)
                self.displayImage(baseImage: image)
            }
            
        } else {
            SDWebImageDownloader.shared().downloadImage(with: imageURL, options: .allowInvalidSSLCertificates, progress: { (current:NSInteger, total:NSInteger) in
            }, completed: { (image, _, error, _) in
                SDWebImageManager.shared().saveImage(toCache: image, for: imageURL)
                DispatchQueue.main.async {
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
        toolbar = UIToolbar.init(frame: CGRect.init(x: 0, y: self.view.frame.size.height - 35, width: self.view.frame.size.width, height:  30))
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(self.content))
        scrollView.addGestureRecognizer(tap)

        doButtons()
        self.view.addSubview(toolbar)
        
        var text = CachedTitle.getTitle(submission: submission!, full: true, false)
        var estHeight = text.boundingRect(with: CGSize.init(width: self.view.frame.size.width - 20, height:10000), options: [.usesLineFragmentOrigin , .usesFontLeading], context: nil).height
        textB = TTTAttributedLabel.init(frame: CGRect.init(x: 10, y: self.view.frame.size.height - estHeight - 60, width: self.view.frame.size.width - 20, height: estHeight + 20))
        textB.numberOfLines = 0
        textB.setText(text)
        
        let tapT = UITapGestureRecognizer.init(target: self, action: #selector(self.comments))
        textB.addGestureRecognizer(tapT)
        
        textB.isUserInteractionEnabled = true
        self.view.addSubview(textB)
        startDisplay()
    }
    
    func doButtons(){
        let space = UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target: nil, action: nil)
        var items: [UIBarButtonItem] = []
        var attrs: [String: Any] = [:]
        let imageview = UIImageView(frame: CGRect.init(x: 0, y: 5, width: 20, height: 20))
        imageView.contentMode = .center

        switch(ActionStates.getVoteDirection(s: submission!)){
        case .down :
            imageview.image = UIImage.init(named: "downvote")?.withColor(tintColor: ColorUtil.downvoteColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20))
            
            attrs = ([NSForegroundColorAttributeName: ColorUtil.downvoteColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 14, submission: true)])
            break
        case .up:
            imageview.image = UIImage.init(named: "upvote")?.withColor(tintColor: ColorUtil.upvoteColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20))
            attrs = ([NSForegroundColorAttributeName: ColorUtil.upvoteColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 14, submission: true)])
            break
        default:
            imageview.image = UIImage.init(named: "upvote")?.withColor(tintColor: .white).imageResize(sizeChange: CGSize.init(width: 20, height: 20))
            attrs = ([NSForegroundColorAttributeName: ColorUtil.fontColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 14, submission: true)])
            break
        }
        
        let voteView = UIView(frame: CGRect.init(x: -70, y: 0, width: 70, height: 30))
        let subScore = NSMutableAttributedString(string: (submission!.score>=10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(submission!.score)/Double(1000))) : " \(submission!.score)", attributes: attrs)
        
        var attrsNew: [String: Any] = [:]
        let labelV = UILabel(frame: CGRect.init(x: 20, y: 0, width: 40, height: 30))
        labelV.attributedText = subScore
        
        voteView.addSubview(labelV)
        voteView.addSubview(imageview)
        
        let commentimg = UIImageView(frame: CGRect.init(x: -10, y: 0, width: 30, height: 30))
        commentimg.image = UIImage.init(named: "comments")?.withColor(tintColor: .white).imageResize(sizeChange: CGSize.init(width: 20, height: 20))
        commentimg.contentMode = .center
        
        let commentView = UIView(frame: CGRect.init(x: 00, y: 0, width: 70, height: 30))
        attrs = ([NSForegroundColorAttributeName: ColorUtil.fontColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 14, submission: true)])
        
        let labelC = UILabel(frame: CGRect.init(x: 20, y: 0, width: 40, height: 30))
        var commentNumber = NSAttributedString.init(string: "\(submission!.commentCount)", attributes: attrs)
        labelC.attributedText = commentNumber
        
        commentView.addSubview(labelC)
        commentView.addSubview(commentimg)
        
        let cb = UIBarButtonItem.init(customView: commentView)
        let sb = UIBarButtonItem.init(customView: voteView)
        
        sb.imageInsets = UIEdgeInsets.init(top: 0, left: -30, bottom: 0, right: 0)
        cb.addTargetForAction(target: self, action: #selector(self.comments))
        sb.addTargetForAction(target: self, action: #selector(self.vote))
        
        toolbar.isUserInteractionEnabled = true
        
        items.append(cb)
        items.append(sb)
        items.append(space)
        menuB = UIBarButtonItem(image: UIImage(named: "ic_more_vert_white")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(ShadowboxLinkViewController.showMenu(_:)))
        items.append(menuB)
        toolbar.items = items
        toolbar.setBackgroundImage(UIImage(),
                                   forToolbarPosition: .any,
                                   barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        toolbar.tintColor = UIColor.white
    }
    
    func vote(){
        
    }
    
    func comments(){
        
    }
    
    public func shouldTruncate(url: URL) -> Bool {
        let path = url.path
        return !ContentType.isGif(uri: url) && !ContentType.isImage(uri: url) && path.contains(".");
    }
    
    func getControllerForUrl(baseUrl: URL) -> UIViewController? {
        var url = baseUrl.absoluteString
        var bUrl = baseUrl
        if(shouldTruncate(url: bUrl)){
            let content = bUrl.absoluteString
            bUrl = URL.init(string: (content.substring(to: (content.characters.index(of: "."))!)))!
        }
        let type = ContentType.getContentType(baseUrl: bUrl)
        
        if(type == ContentType.CType.ALBUM && SettingValues.internalAlbumView){
            return AlbumViewController.init(urlB: bUrl)
        } else if (bUrl != nil && ContentType.displayImage(t: type) && SettingValues.internalImageView || (type == .GIF && SettingValues.internalGifView) || type == .STREAMABLE || type == .VID_ME || (type == ContentType.CType.VIDEO && SettingValues.internalYouTube)) {
            return SingleContentViewController.init(url: bUrl, lq: nil)
        } else if(type == ContentType.CType.LINK || type == ContentType.CType.NONE){
            let web = WebsiteViewController(url: bUrl, subreddit: submission!.subreddit)
            let nav = UINavigationController.init(rootViewController: web)
            return nav
        } else if(type == ContentType.CType.REDDIT){
            return RedditLink.getViewControllerForURL(urlS: bUrl)
        }
        
        let web = WebsiteViewController(url: baseUrl, subreddit: submission!.subreddit)
        let nav = UINavigationController.init(rootViewController: web)
        return nav
    }
    

    func content(){
        var url = baseURL!
        let controller = getControllerForUrl(baseUrl: url)!
        if( controller is AlbumViewController){
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true, completion: nil)
        } else if(controller is SingleContentViewController){
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true, completion: nil)
        } else {
            if(controller is CommentViewController){
                if(UIScreen.main.traitCollection.userInterfaceIdiom == .pad && Int(round(view.bounds.width / CGFloat(320))) > 1){
                    let navigationController = UINavigationController(rootViewController: controller)
                    navigationController.modalPresentationStyle = .pageSheet
                    navigationController.modalTransitionStyle = .crossDissolve
                    present(navigationController, animated: true, completion: nil)
                } else {
                    show(controller, sender: self)
                }
                
            } else {
                show(controller, sender: self)
            }
        }
    }
    
    func showMenu(_ sender: AnyObject){
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = .clear
    }
    
    func startDisplay(){
        loadImage(imageURLB: URL.init(string: submission!.bannerUrl))
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
extension UIBarButtonItem {
    func addTargetForAction(target: AnyObject, action: Selector) {
        self.target = target
        self.action = action
    }
}
