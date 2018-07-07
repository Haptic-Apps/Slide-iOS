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
import AVKit
import TTTAttributedLabel

class ShadowboxLinkViewController: VideoDisplayer, UIScrollViewDelegate, UIGestureRecognizerDelegate, TTTAttributedLabelDelegate {

    var submission: RSubmission
    var baseURL: URL?
    var type: ContentType.CType = ContentType.CType.UNKNOWN
    var body = TTTAttributedLabel.init(frame: CGRect.zero)
    var titleString = UILabel()

    var imageView = UIImageView()
    var textB = TTTAttributedLabel.init(frame: CGRect.zero)

    var comment = UIImageView()
    var upvote = UIImageView()
    var downvote = UIImageView()
    
    var parentVC: ShadowboxViewController

    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        doShow(url: url)
    }

    init(submission: RSubmission, parent: ShadowboxViewController) {
        self.parentVC = parent
        self.submission = submission
        self.baseURL = submission.url
        super.init(nibName: nil, bundle: nil)
        type = ContentType.getContentType(baseUrl: baseURL)
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
        if (((parent as! ShadowboxViewController).currentVc as! ShadowboxLinkViewController).submission.id == self.submission.id) {
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
        let width = Double(view.frame.size.width)
        return CGFloat(width * ratio)
    }

    func getWidthFromAspectRatio(imageHeight: CGFloat, imageWidth: CGFloat) -> CGFloat {
        let ratio = Double(imageWidth) / Double(imageHeight)
        let height = Double(view.frame.size.height * 0.60)
        return CGFloat(height * ratio)
    }

    var toolbar = UIView()
    var baseView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        sharedPlayer = false

        self.scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height - 50))
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 1
        self.scrollView.backgroundColor = .clear
        toolbar = UIView.init(frame: CGRect.init(x: 0, y: self.view.frame.size.height - 55, width: self.view.frame.size.width, height: 24))
        scrollView.addTapGestureRecognizer(action: {
            if let u = self.submission.url {
                self.doShow(url: u, lq: nil)
            }
        })

        progressView = MDCProgressView()
        progressView?.progress = 0
        let progressViewHeight = CGFloat(5)
        progressView?.frame = CGRect(x: 0, y: 5 + (UIApplication.shared.statusBarView?.frame.size.height ?? 20), width: toolbar.bounds.width, height: progressViewHeight)
        view.addSubview(progressView!)
        progressView?.setHidden(true, animated: false, completion: nil)

        doButtons()
        self.view.addSubview(toolbar)
        self.view.addSubview(scrollView)

        var text = CachedTitle.getTitle(submission: submission, full: true, false, true)
        
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize.init(width: self.view.frame.size.width - 48, height: CGFloat.greatestFiniteMagnitude), nil)

        estHeight = textSize.height
        textB = TTTAttributedLabel.init(frame: CGRect.init(x: 24, y: self.view.frame.size.height - estHeight - 64, width: self.view.frame.size.width - 48, height: estHeight + 20))
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
        let attrs: [String: Any] = [NSForegroundColorAttributeName: UIColor.white]

        let subScore = NSMutableAttributedString(string: (submission.score >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(submission.score) / Double(1000))) : " \(submission.score)", attributes: attrs)

        var _: [String: Any] = [:]
        
        let votes = UILabel(frame: CGRect.init(x: 20, y: 0, width: 40, height: 30))
        votes.attributedText = subScore
        votes.font = UIFont.boldSystemFont(ofSize: 12)
        votes.addImage(imageName: "upvote")

        let comments = UILabel(frame: CGRect.init(x: 20, y: 0, width: 40, height: 24))
        let commentNumber = NSAttributedString.init(string: " \(submission.commentCount)", attributes: attrs)
        comments.attributedText = commentNumber
        comments.font = UIFont.boldSystemFont(ofSize: 12)
        comments.addImage(imageName: "comments")
        
        toolbar.isUserInteractionEnabled = true
    
        self.comment = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 20))
        comment.image = UIImage.init(named: "comments")?.menuIcon().getCopy(withColor: .white)

        self.upvote = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 20))
        upvote.image = UIImage.init(named: "upvote")?.menuIcon().getCopy(withColor: .white)

        self.downvote = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 20))
        downvote.image = UIImage.init(named: "downvote")?.menuIcon().getCopy(withColor: .white)

        doVoteImages()
        
        votes.translatesAutoresizingMaskIntoConstraints = false
        comments.translatesAutoresizingMaskIntoConstraints = false
        comment.translatesAutoresizingMaskIntoConstraints = false
        upvote.translatesAutoresizingMaskIntoConstraints = false
        downvote.translatesAutoresizingMaskIntoConstraints = false
        
        comment.addTapGestureRecognizer {
            self.comments(self.comment)
        }
        downvote.addTapGestureRecognizer {
            self.downvote(self.downvote)
        }
        upvote.addTapGestureRecognizer {
            self.upvote(self.upvote)
        }

        toolbar.addSubview(votes)
        toolbar.addSubview(comments)
        toolbar.addSubview(comment)
        toolbar.addSubview(upvote)
        toolbar.addSubview(downvote)

        toolbar.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-24-[commentView]-12-[voteView]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["commentView": comments, "voteView": votes, "upvote":upvote, "downvote":downvote, "menu":comment]))
        toolbar.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[menu(24)]-16-[upvote(24)]-16-[downvote(24)]-24-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["commentView": comments, "voteView": votes, "upvote":upvote, "downvote":downvote, "menu":comment]))
        
        toolbar.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[menu(24)]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["commentView": comments, "voteView": votes, "upvote":upvote, "downvote":downvote, "menu":comment]))
        toolbar.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[upvote(24)]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["commentView": comments, "voteView": votes, "upvote":upvote, "downvote":downvote, "menu":comment]))
        toolbar.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[downvote(24)]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["commentView": comments, "voteView": votes, "upvote":upvote, "downvote":downvote, "menu":comment]))
        toolbar.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[commentView(24)]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["commentView": comments, "voteView": votes, "upvote":upvote, "downvote":downvote, "menu":comment]))
        toolbar.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[voteView(24)]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["commentView": comments, "voteView": votes, "upvote":upvote, "downvote":downvote, "menu":comment]))

        toolbar.tintColor = UIColor.white
        toolbar.isUserInteractionEnabled = true
    }
    
    func doVoteImages(){
        upvote.image = UIImage.init(named: "upvote")?.menuIcon().getCopy(withColor: .white)
        downvote.image = UIImage.init(named: "downvote")?.menuIcon().getCopy(withColor: .white)
        switch (ActionStates.getVoteDirection(s: submission)) {
        case .down:
            downvote.image = UIImage.init(named: "downvote")?.getCopy(withSize: .square(size: 20), withColor: ColorUtil.downvoteColor)
        case .up:
            upvote.image = UIImage.init(named: "upvote")?.getCopy(withSize: .square(size: 20), withColor: ColorUtil.upvoteColor)
            break
        default:
            break
        }
    }

    func upvote(_ sender: AnyObject) {
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.setVote(ActionStates.getVoteDirection(s: submission) == .up ? .none : .up, name: submission.getId(), completion: { (result) in
                
            })
            ActionStates.setVoteDirection(s: submission, direction: ActionStates.getVoteDirection(s: submission) == .up ? .none : .up)
            History.addSeen(s: submission)
            doVoteImages()
        } catch {
            
        }
    }

    func downvote(_ sender: AnyObject) {
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.setVote(ActionStates.getVoteDirection(s: submission) == .down ? .none : .down, name: submission.getId(), completion: { (result) in
                
            })
            ActionStates.setVoteDirection(s: submission, direction: ActionStates.getVoteDirection(s: submission) == .down ? .none : .down)
            History.addSeen(s: submission)
            doVoteImages()
        } catch {
            
        }
    }

    func comments(_ sender: AnyObject) {
        self.doShow(url: URL.init(string: submission.permalink)!)
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
        var videoUrl = submission.videoPreview
        if (videoUrl.isEmpty) {
            videoUrl = submission.url!.absoluteString
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
        let type = ContentType.getContentType(submission: submission)
        if ((ContentType.displayImage(t: type) && type != .SELF) || type == .LINK || type == .EXTERNAL || type == .EMBEDDED) {
            loadImage(imageURLB: URL.init(string: submission.bannerUrl))
        } else if (ContentType.mediaType(t: type)) {
            if let url = URL(string: submission.thumbnailUrl) {
                if (SDWebImageManager.shared().cachedImageExists(for: url)) {
                    DispatchQueue.main.async {
                        if let image = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: self.submission.thumbnailUrl) {
                            self.color = image.areaAverage()
                            if (((self.parent as! ShadowboxViewController).currentVc as! ShadowboxLinkViewController).submission.id == self.submission.id) {
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
                                if (((self.parent as! ShadowboxViewController).currentVc as! ShadowboxLinkViewController).submission.id == self.submission.id) {
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
            let color = ColorUtil.accentColorForSub(sub: (submission.subreddit))
            if (!submission.htmlBody.isEmpty) {
                var html = submission.htmlBody.trimmed()
                do {
                    html = WrapSpoilers.addSpoilers(html)
                    html = WrapSpoilers.addTables(html)
                    let attr = html.toAttributedString()!
                    let font = FontGenerator.fontOfSize(size: 16, submission: false)
                    let attr2 = attr.reconstruct(with: font, color: .white, linkColor: color)
                    var content = LinkParser.parse(attr2, color)
                    let framesetterB = CTFramesetterCreateWithAttributedString(content)
                    let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: self.scrollView.frame.size.width - 10, height: CGFloat.greatestFiniteMagnitude), nil)
                    
                    let activeLinkAttributes = NSMutableDictionary(dictionary: body.activeLinkAttributes)
                    activeLinkAttributes[NSForegroundColorAttributeName] = ColorUtil.accentColorForSub(sub: submission.subreddit)
                    body = TTTAttributedLabel.init(frame: CGRect.init(x: 5, y: 5, width: self.scrollView.frame.size.width - 10, height: textSizeB.height))
                    body.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
                    body.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
                    body.numberOfLines = 0
                    body.isUserInteractionEnabled = true
                    body.backgroundColor = .clear

                    body.delegate = self
                    body.setText(content)
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
