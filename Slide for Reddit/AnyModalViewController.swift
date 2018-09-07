//
//  AnyModalViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/7/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import Then
import UIKit

class AnyModalViewController: UIViewController {
    
    //    var loadedURL: URL?
    
    var embeddedView: VideoView!
    weak var toReturnTo: LinkCellView?
    var fullscreen = false
    var panGestureRecognizer: UIPanGestureRecognizer?
    public var background: UIView?
    public var blurView: UIVisualEffectView?
    
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    var spinnerIndicator = UIActivityIndicatorView()
    
    var didStartPan : (_ panStart: Bool) -> Void = { result in }
    private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
    
    private var savedColor: UIColor?
    var commentCallback: (() -> Void)?
    var failureCallback: ((_ url: URL) -> Void)?
    
    init(cellView: LinkCellView) {
        super.init(nibName: nil, bundle: nil)
        self.embeddedView = cellView.videoView
        self.toReturnTo = cellView
        configureViews()
        configureLayout()
        connectGestures()
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
        
        configureViews()
        configureLayout()
        connectGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        savedColor = UIApplication.shared.statusBarView?.backgroundColor
        UIApplication.shared.statusBarView?.backgroundColor = .clear
        super.viewWillAppear(animated)
        self.configureViews()
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
        
        toReturnTo?.contentView.addSubview(embeddedView)
        toReturnTo?.layoutForType()
    }
    
    //    override func didReceiveMemoryWarning() {
    //        super.didReceiveMemoryWarning()
    //        // Dispose of any resources that can be recreated.
    //    }
    
    func configureViews() {
        self.view.addSubview(embeddedView)
        
        /* todo this
        embeddedVC.navigationBar = UINavigationBar.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: 56))
        embeddedVC.navigationBar.setBackgroundImage(UIImage(), for: .default)
        embeddedVC.navigationBar.shadowImage = UIImage()
        embeddedVC.navigationBar.isTranslucent = true
        let navItem = UINavigationItem(title: "")
        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close")?.navIcon(), for: UIControlState.normal)
        close.addTarget(self, action: #selector(self.exit), for: UIControlEvents.touchUpInside)
        close.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let closeB = UIBarButtonItem.init(customView: close)
        navItem.leftBarButtonItem = closeB
        
        embeddedVC.navigationBar.setItems([navItem], animated: false)
        self.view.addSubview(embeddedVC.navigationBar)
        
        if #available(iOS 11, *) {
            embeddedVC.navigationBar.topAnchor == self.view.safeTopAnchor
        } else {
            embeddedVC.navigationBar.topAnchor == self.view.topAnchor + 20
        }
        embeddedVC.navigationBar.horizontalAnchors == self.view.horizontalAnchors*/
    }
    
    func exit() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func configureLayout() {
        embeddedView.edgeAnchors == self.view.edgeAnchors
    }
    
    func connectGestures() {
        didStartPan = { [weak self] result in
            if let strongSelf = self {
                strongSelf.unFullscreen(strongSelf.embeddedView)
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
extension AnyModalViewController {
    func fullscreen(_ sender: AnyObject) {
        fullscreen = true
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
            statusBar.isHidden = true
            
            self.background?.alpha = 1
//            self.embeddedVC.bottomButtons.alpha = 0
//            self.embeddedVC.navigationBar.alpha = 0.2
        }, completion: {_ in
//            self.embeddedVC.bottomButtons.isHidden = true
        })
    }
    
    func unFullscreen(_ sender: AnyObject) {
        fullscreen = false
//        self.embeddedVC.bottomButtons.isHidden = false
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
            statusBar.isHidden = false
//            self.embeddedVC.navigationBar.alpha = 1
            
            self.background?.alpha = 0.6
//            self.embeddedVC.bottomButtons.alpha = 1
//            self.embeddedVC.progressView.alpha = 0.7
            
        }, completion: {_ in
        })
    }
}

extension AnyModalViewController: UIGestureRecognizerDelegate {
    
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
        
        let viewToMove = embeddedView!
        
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
                    self.background?.alpha = 1
                })
            }
        }
    }
}
