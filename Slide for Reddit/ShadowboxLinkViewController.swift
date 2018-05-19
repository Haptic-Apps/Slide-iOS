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

class ShadowboxLinkViewController: VideoDisplayer, UIScrollViewDelegate, UIGestureRecognizerDelegate, TTTAttributedLabelDelegate {

    var submission: RSubmission?
    var baseURL: URL?
    var type: ContentType.CType = ContentType.CType.UNKNOWN
    var body = TTTAttributedLabel.init(frame: CGRect.zero)
    var titleString = UILabel()

    var imageView = UIImageView()
    var textB = TTTAttributedLabel.init(frame: CGRect.zero)

    var menuB = UIBarButtonItem()
    var doUpvoteB = UIBarButtonItem()
    var doDownvoteB = UIBarButtonItem()
    var doSaveB = UIBarButtonItem()
    var upvoteB = UIBarButtonItem()
    var commentsB = UIBarButtonItem()

    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        doShow(url: url)
    }

    init(submission: RSubmission) {
        self.submission = submission
        self.baseURL = submission.url
        super.init(nibName: nil, bundle: nil)
        type = ContentType.getContentType(baseUrl: baseURL!)
        color = .black
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func displayImage(baseImage: UIImage?) {
        if (baseImage == nil) {

        }
        let image = baseImage!
        color = image.areaAverage()
        if (((parent as! ShadowboxViewController).currentVc as! ShadowboxLinkViewController).submission!.id == self.submission!.id) {
            UIView.animate(withDuration: 0.10) {
                (self.parent as! ShadowboxViewController).background!.backgroundColor = self.color
                (self.parent as! ShadowboxViewController).background!.layoutIfNeeded()
            }
        }

        if (image.size.width > image.size.height) {
            self.scrollView.contentSize = CGSize.init(width: self.view.frame.size.width, height: getHeightFromAspectRatio(imageHeight: image.size.height, imageWidth: image.size.width))
            imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: getHeightFromAspectRatio(imageHeight: image.size.height, imageWidth: image.size.width)))
        } else {
            self.scrollView.contentSize = CGSize.init(width: getWidthFromAspectRatio(imageHeight: image.size.height, imageWidth: image.size.width), height: self.view.frame.size.height * 0.60)
            imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: getWidthFromAspectRatio(imageHeight: image.size.height, imageWidth: image.size.width), height: self.view.frame.size.height))
        }

        imageView.center.x = scrollView.frame.width / 2
        imageView.center.y = scrollView.frame.height / 2

        self.scrollView.delegate = self
        self.scrollView.isScrollEnabled = false

        imageView.contentMode = .scaleAspectFit
        self.scrollView.addSubview(imageView)
        imageView.image = image
    }

    func loadImage(imageURLB: URL?) {
        if (imageURLB == nil) {
            return
        }
        let imageURL = imageURLB!
        if (SDWebImageManager.shared().cachedImageExists(for: imageURL)) {
            DispatchQueue.main.async {
                let image = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: imageURL.absoluteString)
                self.displayImage(baseImage: image)
            }

        } else {
            self.progressView?.setHidden(false, animated: true, completion: nil)
            SDWebImageDownloader.shared().downloadImage(with: imageURL, options: .allowInvalidSSLCertificates, progress: { (current: NSInteger, total: NSInteger) in
                self.progressView?.progress = Float(current / total)
            }, completed: { (image, _, error, _) in
                self.progressView?.setHidden(true, animated: true, completion: nil)
                SDWebImageManager.shared().saveImage(toCache: image, for: imageURL)
                DispatchQueue.main.async {
                    self.displayImage(baseImage: image)
                }
            })
        }
    }

    func getHeightFromAspectRatio(imageHeight: CGFloat, imageWidth: CGFloat) -> CGFloat {
        let ratio = Double(imageHeight) / Double(imageWidth)
        let width = Double(view.frame.size.width);
        return CGFloat(width * ratio)
    }

    func getWidthFromAspectRatio(imageHeight: CGFloat, imageWidth: CGFloat) -> CGFloat {
        let ratio = Double(imageWidth) / Double(imageHeight)
        let height = Double(view.frame.size.height * 0.60);
        return CGFloat(height * ratio)
    }

    var toolbar = UIToolbar()
    var baseView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        sharedPlayer = false

        self.scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 6.0
        self.scrollView.backgroundColor = .clear
        toolbar = UIToolbar.init(frame: CGRect.init(x: 0, y: self.view.frame.size.height - 40, width: self.view.frame.size.width, height: 40))
        scrollView.addTapGestureRecognizer(action: {
            if let u = self.submission!.url {
                self.doShow(url: u, lq: nil)
            }
        })

        progressView = MDCProgressView()
        progressView?.progress = 0
        let progressViewHeight = CGFloat(5)
        progressView?.frame = CGRect(x: 0, y: self.view.frame.size.height - 5, width: toolbar.bounds.width, height: progressViewHeight)
        view.addSubview(progressView!)
        progressView?.setHidden(true, animated: false, completion: nil)

        doButtons()
        self.view.addSubview(toolbar)
        self.view.addSubview(scrollView)

        var text = CachedTitle.getTitle(submission: submission!, full: true, false, true)
        estHeight = text.boundingRect(with: CGSize.init(width: self.view.frame.size.width - 20, height: 10000), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height
        textB = TTTAttributedLabel.init(frame: CGRect.init(x: 10, y: self.view.frame.size.height - estHeight - 50, width: self.view.frame.size.width - 20, height: estHeight + 20))
        textB.numberOfLines = 0
        textB.setText(text)

        textB.isUserInteractionEnabled = true
        textB.addTapGestureRecognizer {
            self.comments(self.textB)
        }
        startDisplay()
        view.addSubview(textB)

        view.layoutIfNeeded()

        let gradient = CAGradientLayer()
        var frame = view.bounds
        frame.size.height = view.bounds.size.height * 0.25
        frame.origin.y = view.bounds.size.height * 0.75
        gradient.frame = frame
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.65).cgColor]

        view.layer.insertSublayer(gradient, at: 0)

        let gradient2 = CAGradientLayer()
        frame.size.height = view.bounds.size.height * 0.25
        frame.origin.y = 0
        gradient2.frame = frame
        gradient2.colors = [UIColor.black.withAlphaComponent(0.65).cgColor, UIColor.clear.cgColor]

        view.layer.insertSublayer(gradient2, at: 0)
    }

    var estHeight = CGFloat(0)

    func doButtons() {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        var items: [UIBarButtonItem] = []
        var attrs: [String: Any] = [NSForegroundColorAttributeName: UIColor.white]
        let imageview = UIImageView(frame: CGRect.init(x: 0, y: 5, width: 20, height: 20))
        imageView.contentMode = .center

        switch (ActionStates.getVoteDirection(s: submission!)) {
        case .down:
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
        let subScore = NSMutableAttributedString(string: (submission!.score >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(submission!.score) / Double(1000))) : " \(submission!.score)", attributes: attrs)

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
        menuB = UIBarButtonItem(image: UIImage(named: "ic_more_vert_white")?.toolbarIcon(), style: .plain, target: self, action: #selector(ShadowboxLinkViewController.showMenu(_:)))
        items.append(menuB)
        doUpvoteB = UIBarButtonItem(image: UIImage(named: "upvote")?.toolbarIcon(), style: .plain, target: self, action: #selector(ShadowboxLinkViewController.showMenu(_:)))
        items.append(doUpvoteB)
        doDownvoteB = UIBarButtonItem(image: UIImage(named: "downvote")?.toolbarIcon(), style: .plain, target: self, action: #selector(ShadowboxLinkViewController.showMenu(_:)))
        items.append(doDownvoteB)
        doSaveB = UIBarButtonItem(image: UIImage(named: "star")?.toolbarIcon(), style: .plain, target: self, action: #selector(ShadowboxLinkViewController.showMenu(_:)))
        items.append(doSaveB)

        toolbar.items = items
        toolbar.setBackgroundImage(UIImage(),
                forToolbarPosition: .any,
                barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        toolbar.tintColor = UIColor.white
    }

    func vote() {

    }

    func comments(_ sender: AnyObject) {
        self.doShow(url: URL.init(string: submission!.permalink)!)
    }

    func showMenu(_ sender: AnyObject) {

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.baseView.backgroundColor = .clear
    }

    var first = true

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.player.play()
        var videoUrl = submission!.videoPreview
        if (videoUrl.isEmpty) {
            videoUrl = submission!.url!.absoluteString
        }
        if (first && !ContentType.displayImage(t: type) && ContentType.mediaType(t: type) || type == .VIDEO) {
            first = false
            if (type == .GIF || type == .STREAMABLE || type == .VID_ME) {
                getGif(urlS: videoUrl)
            } else if (type == .VIDEO) {
                let he = getYTHeight()
                ytPlayer = YTPlayerView.init(frame: CGRect.init(x: 0, y: (self.scrollView.frame.size.height - he) / 2, width: self.scrollView.frame.size.width, height: he))
                ytPlayer.isHidden = true
                self.scrollView.addSubview(ytPlayer)
                getYouTube(ytPlayer, urlS: baseURL!.absoluteString)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player.pause()
    }

    func startDisplay() {
        self.view.layoutMargins = UIEdgeInsetsMake(8, 8, 8, 8)
        let type = ContentType.getContentType(submission: submission!)
        if ((ContentType.displayImage(t: type) && type != .SELF) || type == .LINK || type == .EXTERNAL || type == .EMBEDDED) {
            loadImage(imageURLB: URL.init(string: submission!.bannerUrl))
        } else if (ContentType.mediaType(t: type)) {
            if let url = URL(string: submission!.thumbnailUrl) {
                if (SDWebImageManager.shared().cachedImageExists(for: url)) {
                    DispatchQueue.main.async {
                        if let image = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: self.submission!.thumbnailUrl) {
                            self.color = image.areaAverage()
                            if (((self.parent as! ShadowboxViewController).currentVc as! ShadowboxLinkViewController).submission!.id == self.submission!.id) {
                                UIView.animate(withDuration: 0.10) {
                                    (self.parent as! ShadowboxViewController).background!.backgroundColor = self.color
                                    (self.parent as! ShadowboxViewController).background!.layoutIfNeeded()
                                }
                            }
                        }
                    }
                } else {
                    SDWebImageDownloader.shared().downloadImage(with: url, options: .allowInvalidSSLCertificates, progress: { (current: NSInteger, total: NSInteger) in
                    }, completed: { (img, _, error, _) in
                        SDWebImageManager.shared().saveImage(toCache: img, for: url)
                        if let image = img {
                            DispatchQueue.main.async {
                                self.color = image.areaAverage()
                                if (((self.parent as! ShadowboxViewController).currentVc as! ShadowboxLinkViewController).submission!.id == self.submission!.id) {
                                    UIView.animate(withDuration: 0.5) {
                                        (self.parent as! ShadowboxViewController).background!.backgroundColor = self.color
                                    }
                                }
                            }
                        }
                    })
                }
            }

        } else {
            let color = ColorUtil.accentColorForSub(sub: (submission!.subreddit))
            if (!submission!.htmlBody.isEmpty) {
                let html = submission!.htmlBody.trimmed()
                do {
                    let attr = html.toAttributedString()!
                    let font = FontGenerator.fontOfSize(size: 16, submission: false)
                    let attr2 = attr.reconstruct(with: font, color: .white, linkColor: color)
                    var content = CellContent.init(string: LinkParser.parse(attr2, color), width: self.scrollView.frame.size.width - 10)
                    let activeLinkAttributes = NSMutableDictionary(dictionary: body.activeLinkAttributes)
                    activeLinkAttributes[NSForegroundColorAttributeName] = ColorUtil.accentColorForSub(sub: submission!.subreddit)
                    body = TTTAttributedLabel.init(frame: CGRect.init(x: 5, y: 5, width: self.scrollView.frame.size.width - 10, height: content.textHeight))
                    body.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
                    body.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
                    body.numberOfLines = 0
                    body.isUserInteractionEnabled = true
                    body.backgroundColor = .clear

                    body.delegate = self
                    body.setText(content.attributedString)
                    scrollView.addSubview(body)
                    self.scrollView.contentSize = body.frame.size
                    self.scrollView.frame = CGRect.init(x: 0, y: 56, width: self.view.frame.size.width, height: self.view.frame.size.height - 56 - estHeight - 50)
                } catch {
                }
            } else {

            }

        }
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
