//
//  ModalMediaViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import Then
import UIKit

class ModalMediaViewController: UIViewController {

//    var loadedURL: URL?

    var embeddedVC: EmbeddableMediaViewController!
    var fullscreen = false
    var panGestureRecognizer: UIPanGestureRecognizer?
    public var background: UIView?
    public var blurView: UIVisualEffectView?

    var closeButton = UIButton().then {
        $0.accessibilityIdentifier = "Close Button"
        $0.accessibilityTraits = UIAccessibilityTraitButton
        $0.accessibilityLabel = "Close button"
        $0.accessibilityHint = "Closes the media view"
    }
    
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    var spinnerIndicator = UIActivityIndicatorView()

    var didStartPan : (_ panStart: Bool) -> Void = { result in }
    private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()

    private var savedColor: UIColor?
    var commentCallback: (() -> Void)?
    var failureCallback: ((_ url: URL) -> Void)?

    init(url: URL, lq: URL?, _ commentCallback: (() -> Void)?, _ failureCallback: ((_ url: URL) -> Void)? = nil) {
        super.init(nibName: nil, bundle: nil)

        self.failureCallback = failureCallback
        self.commentCallback = commentCallback
        
        let type = ContentType.getContentType(baseUrl: url)
        if ContentType.isImgurLink(uri: url) || type == .DEVIANTART || type == .XKCD {
            spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            spinnerIndicator.center = self.view.center
            spinnerIndicator.color = UIColor.white
            self.view.addSubview(spinnerIndicator)
            spinnerIndicator.startAnimating()

            self.loadTypeAsync(url, type)
        } else {
            self.setModel(model: EmbeddableMediaDataModel(baseURL: url, lqURL: lq, text: nil, inAlbum: false))
        }
    }
    
    func setModel(model: EmbeddableMediaDataModel) {
        spinnerIndicator.stopAnimating()
        let contentType = ContentType.getContentType(baseUrl: model.baseURL)
        embeddedVC = ModalMediaViewController.getVCForContent(ofType: contentType, withModel: model)
        embeddedVC.commentCallback = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.commentCallback!()
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
                            self.setModel(model: EmbeddableMediaDataModel(baseURL: URL(string: url!), lqURL: nil, text: nil, inAlbum: false))
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
                            self.setModel(model: EmbeddableMediaDataModel(baseURL: URL(string: url!), lqURL: nil, text: text, inAlbum: false))
                        }
                    }
                }
                
                }.resume()

        } else {
            let changedUrl = URL.init(string: baseUrl.absoluteString + ".png")!
            var request = URLRequest(url: changedUrl)
            request.httpMethod = "HEAD"
            let task = URLSession.shared.dataTask(with: request) { (_, response, _) -> Void in
                if response != nil {
                    if response!.mimeType ?? "" == "image/gif" {
                        let finalUrl = URL.init(string: baseUrl.absoluteString + ".mp4")!
                        DispatchQueue.main.async {
                            self.setModel(model: EmbeddableMediaDataModel(baseURL: finalUrl, lqURL: nil, text: nil, inAlbum: false))
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.setModel(model: EmbeddableMediaDataModel(baseURL: changedUrl, lqURL: nil, text: nil, inAlbum: false))
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.setModel(model: EmbeddableMediaDataModel(baseURL: baseUrl, lqURL: nil, text: nil, inAlbum: false))
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
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var shouldLoad = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            
            background!.alpha = 0.6
            
            self.view.insertSubview(background!, at: 0)
            blurView = UIVisualEffectView(frame: UIScreen.main.bounds)
            blurEffect.setValue(3, forKeyPath: "blurRadius")
            blurView!.effect = blurEffect
            view.insertSubview(blurView!, at: 0)
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
        savedColor = UIApplication.shared.statusBarView?.backgroundColor
        UIApplication.shared.statusBarView?.backgroundColor = .clear
        super.viewWillAppear(animated)
        
        if parent is AlbumViewController || parent is ShadowboxLinkViewController {
            self.closeButton.isHidden = true
        }
        UIApplication.shared.statusBarStyle = .lightContent

        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, closeButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            self.setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIApplication.shared.statusBarView?.isHidden = false
        if savedColor != nil {
            UIApplication.shared.statusBarView?.backgroundColor = savedColor
        }
        
        if SettingValues.reduceColor && ColorUtil.theme.isLight() {
            UIApplication.shared.statusBarStyle = .default
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
        }
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

    func configureViews() {
        self.addChildViewController(embeddedVC)
        embeddedVC.didMove(toParentViewController: self)
        self.view.addSubview(embeddedVC.view)

        closeButton.setImage(UIImage(named: "close")?.navIcon(true), for: .normal)
        closeButton.addTarget(self, action: #selector(self.exit), for: UIControlEvents.touchUpInside)
        self.view.addSubview(closeButton)
    }
    
    func exit() {
        self.dismiss(animated: true, completion: nil)
    }

    func configureLayout() {
        embeddedVC.view.edgeAnchors == self.view.edgeAnchors

        closeButton.sizeAnchors == .square(size: 26)
        closeButton.topAnchor == self.view.safeTopAnchor + 8
        closeButton.leftAnchor == self.view.safeLeftAnchor + 12
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
    func fullscreen(_ sender: AnyObject) {
        fullscreen = true
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
            statusBar.isHidden = true

            self.background?.alpha = 1
            self.closeButton.alpha = 0
            self.embeddedVC.bottomButtons.alpha = 0
        }, completion: {_ in
            self.embeddedVC.bottomButtons.isHidden = true
        })
    }

    func unFullscreen(_ sender: AnyObject) {
        fullscreen = false
        self.embeddedVC.bottomButtons.isHidden = false
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
            statusBar.isHidden = false
            self.closeButton.alpha = 1

            self.background?.alpha = 0.6
            self.embeddedVC.bottomButtons.alpha = 1
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

    func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)
        
        let viewToMove: UIView
        if embeddedVC is ImageMediaViewController {
            viewToMove = (embeddedVC as! ImageMediaViewController).imageView
        } else {
            viewToMove = (embeddedVC as! VideoMediaViewController).isYoutubeView ? (embeddedVC as! VideoMediaViewController).youtubeView : (embeddedVC as! VideoMediaViewController).videoView
        }
        
        if panGesture.state == .began {
            originalPosition = viewToMove.frame.origin
            currentPositionTouched = panGesture.location(in: view)
            didStartPan(true)
        } else if panGesture.state == .changed {
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
                    viewToMove.frame.origin = self.originalPosition!
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
        set {}
    }
}
