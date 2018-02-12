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

    var color: UIColor = UIColor.black;
    
    func displayImage(baseImage: UIImage?){
        if(baseImage == nil){
            
        }
        let image = baseImage!
        color = image.areaAverage()
        if(((parent as! ShadowboxViewController).currentVc as! ShadowboxLinkViewController).submission!.id == self.submission!.id){
            UIView.animate(withDuration: 0.10) {
                (self.parent as! ShadowboxViewController).background!.backgroundColor = self.color
                (self.parent as! ShadowboxViewController).background!.layoutIfNeeded()
            }
        }
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
        let percent = ((textB.frame.size.height + 30)/self.view.frame.size.height)
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
    var baseView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let inner = UIView.init(frame: self.view.frame)

        self.scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 72, width: self.view.frame.size.width - 48, height: self.view.frame.size.height - 106))
        self.scrollView.layer.cornerRadius = 10
        self.scrollView.minimumZoomScale=1
        self.scrollView.maximumZoomScale=6.0
        self.scrollView.backgroundColor = .clear
        toolbar = UIToolbar.init(frame: CGRect.init(x: 0, y: self.view.frame.size.height - 89, width: self.view.frame.size.width - 48, height:  40))
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(self.content(_:)))
        scrollView.addGestureRecognizer(tap)
        scrollView.isUserInteractionEnabled = true
        let tap2 = UITapGestureRecognizer.init(target: self, action: #selector(self.comments(_:)))
        toolbar.addGestureRecognizer(tap2)
        toolbar.isUserInteractionEnabled = true

        doButtons()
        inner.addSubview(toolbar)
        inner.addSubview(scrollView)

        var text = CachedTitle.getTitle(submission: submission!, full: true, false, true)
        var estHeight = text.boundingRect(with: CGSize.init(width: self.view.frame.size.width - 20, height:10000), options: [.usesLineFragmentOrigin , .usesFontLeading], context: nil).height
        textB = TTTAttributedLabel.init(frame: CGRect.init(x: 10, y: self.view.frame.size.height - estHeight - 60, width: self.view.frame.size.width - 68, height: estHeight + 20))
        textB.numberOfLines = 0
        textB.setText(text)
        
        textB.isUserInteractionEnabled = true
        inner.addSubview(textB)
        startDisplay()
        baseView = inner.withPadding(padding: UIEdgeInsetsMake(48, 24, 0, 24))
        
        view.addSubview(baseView)
        
        view.layoutIfNeeded()

    }
    
    func doButtons(){
        let space = UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target: nil, action: nil)
        var items: [UIBarButtonItem] = []
        var attrs: [String: Any] = [NSForegroundColorAttributeName : UIColor.white]
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
            attrs = ([NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 14, submission: true)])
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
        attrs = ([NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 14, submission: true)])
        
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
    
    func comments(_ sender: AnyObject){
        
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
    

    func content(_ sender: AnyObject){
        print("Doing content")
        var url = baseURL!
        let controller = getControllerForUrl(baseUrl: url)!
        if( controller is AlbumViewController){
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true, completion: nil)
        } else if(controller is SingleContentViewController){
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true, completion: nil)
        } else {
                VCPresenter.showVC(viewController: controller, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }
    }
    
    func showMenu(_ sender: AnyObject){
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.baseView.backgroundColor = .clear
    }
    
    func startDisplay(){
        self.view.layoutMargins = UIEdgeInsetsMake(16, 16, 16, 16)
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
extension UIImage {
    func areaAverage() -> UIColor {
        var bitmap = [UInt8](repeating: 0, count: 4)

        if #available(iOS 9.0, *) {
            // Get average color.
            let context = CIContext()
            let inputImage: CIImage = ciImage ?? CoreImage.CIImage(cgImage: cgImage!)
            let extent = inputImage.extent
            let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
            let filter = CIFilter(name: "CIAreaAverage", withInputParameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
            let outputImage = filter.outputImage!
            let outputExtent = outputImage.extent
            assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)

            // Render to bitmap.
            context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: kCIFormatRGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        } else {
            // Create 1x1 context that interpolates pixels when drawing to it.
            let context = CGContext(data: &bitmap, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            let inputImage = cgImage ?? CIContext().createCGImage(ciImage!, from: ciImage!.extent)

            // Render to bitmap.
            context.draw(inputImage!, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }

        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: CGFloat(bitmap[3]) / 255.0)
        return result
    }

}