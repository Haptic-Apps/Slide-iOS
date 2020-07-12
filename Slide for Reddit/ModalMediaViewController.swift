//
//  ModalMediaViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import AVKit
import SDCAlertView
import Then
import UIKit
import YYText

class ModalMediaViewController: UIViewController {

//    var loadedURL: URL?
    weak var previewImage: UIImage?
    var finalSize: CGSize?

    var embeddedVC: EmbeddableMediaViewController!
    var fullscreen = false
    var panGestureRecognizer: UIPanGestureRecognizer?
    public var background: UIView?
    public var blurView: UIVisualEffectView?

    var closeButton = UIButton().then {
        $0.accessibilityIdentifier = "Close Button"
        $0.accessibilityTraits = UIAccessibilityTraits.button
        $0.accessibilityLabel = "Close button"
        $0.accessibilityHint = "Closes the media view"
    }
    
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    var spinnerIndicator = UIActivityIndicatorView()
    var titleView = YYLabel()
    
    var didStartPan : (_ panStart: Bool) -> Void = { result in }

    private var savedColor: UIColor?
    var commentCallback: (() -> Void)?
    var failureCallback: ((_ url: URL) -> Void)?
    var upvoteCallback: (() -> Void)?
    var isUpvoted = false
    var gradientView = GradientView(gradientStartColor: UIColor.black.withAlphaComponent(0.9), gradientEndColor: UIColor.clear)

    init(url: URL, lq: URL?, _ commentCallback: (() -> Void)? = nil, upvoteCallback: (() -> Void)? = nil, isUpvoted: Bool = false, _ failureCallback: ((_ url: URL) -> Void)? = nil, link: RSubmission?) {
        super.init(nibName: nil, bundle: nil)

        self.failureCallback = failureCallback
        self.commentCallback = commentCallback
        self.upvoteCallback = upvoteCallback
        self.isUpvoted = isUpvoted
        
        let type = ContentType.getContentType(baseUrl: url)
        if link != nil {
            let title = CachedTitle.getTitleForMedia(submission: link!)
            let finalTitle = NSMutableAttributedString(attributedString: title.infoLine!)
            finalTitle.append(NSAttributedString(string: "\n"))
            finalTitle.append(title.mainTitle!)
            
            titleView.attributedText = finalTitle
            titleView.numberOfLines = 0
            
            if commentCallback != nil {
                titleView.addTapGestureRecognizer { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.dismiss(animated: false) {
                        strongSelf.commentCallback?()
                    }
                }
            }
        }
        if ContentType.isImgurLink(uri: url) || type == .DEVIANTART || type == .XKCD {
            spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
            spinnerIndicator.center = self.view.center
            spinnerIndicator.color = UIColor.white
            self.view.addSubview(spinnerIndicator)
            spinnerIndicator.startAnimating()

            self.loadTypeAsync(url, type)
        } else {
            self.setModel(model: EmbeddableMediaDataModel(baseURL: url, lqURL: lq, text: nil, inAlbum: false, buttons: true))
        }
    }
    
    func setModel(model: EmbeddableMediaDataModel) {
        spinnerIndicator.stopAnimating()
        let contentType = ContentType.getContentType(baseUrl: model.baseURL)
        embeddedVC = ModalMediaViewController.getVCForContent(ofType: contentType, withModel: model)
        
        if self.commentCallback != nil {
            embeddedVC.commentCallback = { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.commentCallback!()
            }
        }
        
        if self.upvoteCallback != nil {
            embeddedVC.upvoteCallback = { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.upvoteCallback!()
            }
            embeddedVC.isUpvoted = isUpvoted
        }

        embeddedVC.failureCallback = { [weak self] (url) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.failureCallback!(url)
        }
        if embeddedVC == nil {
            fatalError("embeddedVC should be populated!")
        }
        if shouldLoad {
            configureViews()
            configureLayout()
            connectGestures()
        }
    }
    
    func loadTypeAsync(_ baseUrl: URL, _ type: ContentType.CType) {
        if type == .DEVIANTART {
            let finalURL = URL(string: "http://backend.deviantart.com/oembed?url=" + baseUrl.absoluteString)!
            URLSession.shared.dataTask(with: finalURL) { (data, _, error) in
                var url: String?
                if error != nil {
                    print(error ?? "Error loading deviantart...")
                    self.dismiss(animated: true, completion: {
                        self.failureCallback?(baseUrl)
                    })
                } else {
                    do {
                        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                            return
                        }
                        
                        if let fullsize = json["fullsize_url"] as? String {
                            url = fullsize
                        } else if let normal = json["url"] as? String {
                            url = normal
                        }
                        
                    } catch let error as NSError {
                        print(error)
                        self.dismiss(animated: true, completion: {
                            self.failureCallback?(baseUrl)
                        })
                    }
                    DispatchQueue.main.async {
                        if url != nil {
                            self.setModel(model: EmbeddableMediaDataModel(baseURL: URL(string: url!), lqURL: nil, text: nil, inAlbum: false, buttons: true))
                        }
                    }
                }
                
                }.resume()
        } else if type == .XKCD {
            var urlString = baseUrl.absoluteString
            
            if !urlString.endsWith("/") {
                urlString += "/"
            }
            
            let apiUrl = urlString + "info.0.json"

            let finalURL = URL(string: apiUrl)!
            URLSession.shared.dataTask(with: finalURL) { (data, _, error) in
                var url: String?
                var text: String?
                if error != nil {
                    print(error ?? "Error loading xkcd...")
                    self.dismiss(animated: true, completion: {
                        self.failureCallback?(baseUrl)
                    })
                } else {
                    do {
                        guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                            return
                        }
                        
                        if let fullsize = json["img"] as? String {
                            url = fullsize
                        }
                        if let title = json["safe_title"] as? String, let alt = json["alt"] as? String {
                            text = title + "\n\n" + alt
                        }
                        
                    } catch let error as NSError {
                        print(error)
                        self.dismiss(animated: true, completion: {
                            self.failureCallback?(baseUrl)
                        })
                    }
                    DispatchQueue.main.async {
                        if url != nil {
                            self.setModel(model: EmbeddableMediaDataModel(baseURL: URL(string: url!), lqURL: nil, text: text, inAlbum: false, buttons: true))
                        }
                    }
                }
                
                }.resume()

        } else {
            var urlBase = baseUrl.absoluteString
            urlBase = urlBase.replacingOccurrences(of: "m.imgur.com", with: "i.imgur.com")
            let changedUrl = URL(string: "\(urlBase).png")!
            var request = URLRequest(url: changedUrl)
            request.httpMethod = "HEAD"
            let task = URLSession.shared.dataTask(with: request) { (_, response, _) -> Void in
                if response != nil {
                    if response!.mimeType ?? "" == "image/gif" {
                        let finalUrl = URL.init(string: baseUrl.absoluteString + ".mp4")!
                        DispatchQueue.main.async {
                            self.setModel(model: EmbeddableMediaDataModel(baseURL: finalUrl, lqURL: nil, text: nil, inAlbum: false, buttons: true))
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.setModel(model: EmbeddableMediaDataModel(baseURL: changedUrl, lqURL: nil, text: nil, inAlbum: false, buttons: true))
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.setModel(model: EmbeddableMediaDataModel(baseURL: baseUrl, lqURL: nil, text: nil, inAlbum: false, buttons: true))
                    }
                }
            }
            task.resume()
        }
    }

    init(model: EmbeddableMediaDataModel) {
        super.init(nibName: nil, bundle: nil)
        setModel(model: model)
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var shouldLoad = false

    override func viewDidLoad() {
        super.viewDidLoad()
        desiredStatusBarStyle = .lightContent
        if !(parent is AlbumViewController) {
            panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
            panGestureRecognizer!.delegate = self
            panGestureRecognizer!.direction = .vertical
            panGestureRecognizer!.cancelsTouchesInView = false
            
            view.addGestureRecognizer(panGestureRecognizer!)
            
            background = UIView()
            background!.frame = self.view.frame
            background!.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            background!.backgroundColor = .black
                                    
            self.view.insertSubview(background!, at: 0)
        }
        
        if embeddedVC != nil {
            configureViews()
            configureLayout()
            connectGestures()
        } else {
            shouldLoad = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        savedColor = UIApplication.shared.statusBarUIView?.backgroundColor
        UIApplication.shared.statusBarUIView?.backgroundColor = .clear
        super.viewWillAppear(animated)
        
        titleView.lineBreakMode = .byWordWrapping
        titleView.sizeToFit()
        titleView.layoutIfNeeded()

        if parent is AlbumViewController || parent is ShadowboxLinkViewController {
            self.closeButton.isHidden = true
        }

        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: closeButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            self.setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarUIView?.isHidden = false
        if savedColor != nil {
            UIApplication.shared.statusBarUIView?.backgroundColor = savedColor
        }

        if SettingValues.reduceColor && ColorUtil.theme.isLight {
            desiredStatusBarStyle = .default
        } else {
            desiredStatusBarStyle = .lightContent
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    var desiredStatusBarStyle: UIStatusBarStyle = .default {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return desiredStatusBarStyle
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

    var videoView: VideoView?
    var displayLink: CADisplayLink?
    func configureViews() {
        if let video = embeddedVC as? VideoMediaViewController {
            videoView = video.videoView
            displayLink = video.displayLink
        }
        self.addChild(embeddedVC)
        embeddedVC.didMove(toParent: self)
        self.view.addSubview(embeddedVC.view)

        closeButton.setImage(UIImage(sfString: SFSymbol.xmark, overrideString: "close")?.navIcon(true), for: .normal)
        closeButton.addTarget(self, action: #selector(self.exit), for: UIControl.Event.touchUpInside)
        
        self.view.addSubview(gradientView)
        gradientView.addSubview(closeButton)
        gradientView.addSubview(titleView)
    }
    
    @objc func exit() {
        var viewToMove: UIView
        if embeddedVC is ImageMediaViewController {
            viewToMove = (embeddedVC as! ImageMediaViewController).imageView
        } else if embeddedVC != nil {
            viewToMove = (embeddedVC as! VideoMediaViewController).isYoutubeView ? (embeddedVC as! VideoMediaViewController).youtubeView : (embeddedVC as! VideoMediaViewController).videoView
        } else {
            viewToMove = self.view
        }
        var newFrame = viewToMove.frame
        newFrame.origin.y = -newFrame.size.height * 0.2
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            viewToMove.frame = newFrame
            self.view.alpha = 0
            self.dismiss(animated: true)
        }, completion: { _ in
        })
    }

    func configureLayout() {
        embeddedVC.view.edgeAnchors == self.view.edgeAnchors

        gradientView.horizontalAnchors == self.view.horizontalAnchors
        gradientView.topAnchor == self.view.topAnchor

        closeButton.sizeAnchors == .square(size: 38)
        closeButton.topAnchor == gradientView.safeTopAnchor + 8
        closeButton.leftAnchor == gradientView.safeLeftAnchor + 12
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.masksToBounds = true
        closeButton.layer.cornerRadius = 18
        
        titleView.leftAnchor == closeButton.rightAnchor + 8
        titleView.topAnchor == gradientView.safeTopAnchor + 8
        titleView.rightAnchor == gradientView.safeRightAnchor - 8
        titleView.bottomAnchor == gradientView.bottomAnchor - 8
            
        gradientView.layoutIfNeeded()
        print("Setting width to \(self.titleView.frame.size.width)")
        titleView.preferredMaxLayoutWidth = self.titleView.frame.size.width
        titleView.sizeToFit()
    }

    func connectGestures() {
        didStartPan = { [weak self] result in
            if let strongSelf = self {
                strongSelf.unFullscreen(strongSelf.embeddedVC.view)
            }
        }
    }

    static func getVCForContent(ofType type: ContentType.CType, withModel model: EmbeddableMediaDataModel) -> EmbeddableMediaViewController? {
        switch type {
        case .IMAGE, .IMGUR:
            // Still image (possibly low quality)
            return ImageMediaViewController(model: model, type: type)
        case .GIF, .STREAMABLE, .VID_ME, .VIDEO:
            // Gif / video / youtube video
            return VideoMediaViewController(model: model, type: type)
        default:
            return nil
        }
    }

}

// MARK: - Actions
extension ModalMediaViewController {
    @objc func fullscreen(_ sender: AnyObject, _ hideTitle: Bool) {
        // Don't allow fullscreen if the user is a voiceover user.
        if UIAccessibility.isVoiceOverRunning {
            return
        }

        fullscreen = true
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            let statusBar: UIView = UIApplication.shared.statusBarUIView ?? UIView()
            statusBar.isHidden = true

            self.background?.alpha = 1
            if hideTitle {
                self.gradientView.alpha = 0
            }
            self.embeddedVC.gradientView.alpha = 0
        }, completion: {_ in
            self.embeddedVC.gradientView.isHidden = true
        })
    }

    @objc func unFullscreen(_ sender: AnyObject) {
        fullscreen = false
        self.embeddedVC.gradientView.isHidden = false
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            let statusBar: UIView = UIApplication.shared.statusBarUIView ?? UIView()
            statusBar.isHidden = false
            self.gradientView.alpha = 1

            self.background?.alpha = 1
            self.embeddedVC.gradientView.alpha = 1
            self.embeddedVC.progressView.alpha = 0.7

        }, completion: {_ in
        })
    }
}

extension ModalMediaViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        // Reject the touch if it lands in a UIControl.
        if let view = touch.view {
            return !view.hasParentOfClass(UIControl.self)
        } else {
            return true
        }
    }

    @objc func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)
        
        let viewToMove: UIView
        if embeddedVC is ImageMediaViewController {
            viewToMove = (embeddedVC as! ImageMediaViewController).imageView
        } else if embeddedVC != nil {
            viewToMove = (embeddedVC as! VideoMediaViewController).isYoutubeView ? (embeddedVC as! VideoMediaViewController).youtubeView : (embeddedVC as! VideoMediaViewController).videoView
        } else {
            return
        }
        
        if panGesture.state == .began {
            originalPosition = viewToMove.frame.origin
            currentPositionTouched = panGesture.location(in: view)
            didStartPan(true)
        } else if panGesture.state == .changed {
            if originalPosition == nil {
                originalPosition = viewToMove.frame.origin
            }
            viewToMove.frame.origin = CGPoint(
                x: 0,
                y: originalPosition!.y + translation.y
            )
            let progress = translation.y / (self.view.frame.size.height / 2)
            self.view.alpha = 1 - (abs(progress) * 1.3)
            
        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: view)
            
            let down = panGesture.velocity(in: view).y > 0
            if abs(velocity.y) >= 1000 || abs(self.view.frame.origin.y) > self.view.frame.size.height / 2 {
                
                UIView.animate(withDuration: 0.2, animations: {
                    viewToMove.frame.origin = CGPoint(
                        x: viewToMove.frame.origin.x,
                        y: viewToMove.frame.size.height * (down ? 1 : -1) )
                    
                    self.view.alpha = 0.1
                    
                }, completion: { (isCompleted) in
                    if isCompleted {
                        self.dismiss(animated: false, completion: nil)
                    }
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    viewToMove.frame.origin = self.originalPosition ?? CGPoint.zero
                    self.view.alpha = 1
                    if self.embeddedVC is VideoMediaViewController {
                        self.background?.alpha = 1
                    }
                })
            }
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        exit()
        return true
    }

    override var accessibilityViewIsModal: Bool {
        get {
            return true
        }
        set { } // swiftlint:disable:this unused_setter_value
    }
}
extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return (presentedViewController is AlertController) ? .lightContent : (presentedViewController?.preferredStatusBarStyle ?? topViewController?.preferredStatusBarStyle ?? (SettingValues.reduceColor && ColorUtil.theme.isLight ? .default : .lightContent))
    }
}

class GradientView: UIView {

    private let gradient: CAGradientLayer = CAGradientLayer()
    private let gradientStartColor: UIColor
    private let gradientEndColor: UIColor

    init(gradientStartColor: UIColor, gradientEndColor: UIColor) {
        self.gradientStartColor = gradientStartColor
        self.gradientEndColor = gradientEndColor
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        gradient.frame = self.bounds
    }

    override public func draw(_ rect: CGRect) {
        gradient.frame = self.bounds
        gradient.colors = [gradientStartColor.cgColor, gradientEndColor.cgColor]
        gradient.locations = [0, 1]
        if gradient.superlayer == nil {
            layer.insertSublayer(gradient, at: 0)
        }
    }
}
