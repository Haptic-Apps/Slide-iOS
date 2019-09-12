//
//  AnyModalViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/7/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import AVKit
import SubtleVolume
import Then
import UIKit

class AnyModalViewController: UIViewController {
    let volume = SubtleVolume(style: SubtleVolumeStyle.rounded)
    let volumeHeight: CGFloat = 3
    static var linkID = ""
    
    var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, tvOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets.zero
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var embeddedPlayer: AVPlayer?
    var videoView: VideoView!
    weak var toReturnTo: LinkCellView?
    var fullscreen = false
    var panGestureRecognizer: UIPanGestureRecognizer?
    public var background: UIView?
    public var blurView: UIVisualEffectView?
    
    var sliderBeingUsed: Bool = false
    var wasPlayingWhenPaused: Bool = false
    
    var baseURL: URL?
    var urlToLoad: URL?
    var spinnerIndicator = UIActivityIndicatorView()
    var setOnce = false

    var menuButton = UIButton()
    var downloadButton = UIButton()
    var muteButton = UIButton()
    var bottomButtons = UIStackView()
    var goToCommentsButton = UIButton()
    var upvoteButton = UIButton()

    var closeButton = UIButton().then {
        $0.accessibilityIdentifier = "Close Button"
        $0.accessibilityTraits = UIAccessibilityTraits.button
        $0.accessibilityLabel = "Close button"
        $0.accessibilityHint = "Closes the media view"
    }
    
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    var tap: UITapGestureRecognizer?
    var dTap: UITapGestureRecognizer?

    var timer: Timer?
    var cancelled = false
    
    var displayLink: CADisplayLink?
    
    var forcedFullscreen = false
    var oldOrientation: UIInterfaceOrientation?

    var fastForwardImageView = UIImageView()
    var rewindImageView = UIImageView()
    
    var scrubber = VideoScrubberView()
    
    var didStartPan : (_ panStart: Bool) -> Void = { result in }
    private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
    
    private var savedColor: UIColor?
    var commentCallback: (() -> Void)?
    var failureCallback: ((_ url: URL) -> Void)?
    var upvoteCallback: (() -> Void)?
    var isUpvoted = false

    init(cellView: LinkCellView, _ commentCallback: (() -> Void)?, upvoteCallback: (() -> Void)?, isUpvoted: Bool, failure: ((_ url: URL) -> Void)?) {
        super.init(nibName: nil, bundle: nil)
        self.commentCallback = commentCallback
        self.failureCallback = failure
        self.upvoteCallback = upvoteCallback
        self.isUpvoted = isUpvoted
        self.embeddedPlayer = cellView.videoView.player
        self.toReturnTo = cellView
        self.baseURL = cellView.videoURL ?? cellView.link?.url
        if VideoMediaViewController.VideoType.fromPath(self.baseURL!.absoluteString) == .REDDIT {
            self.baseURL = URL(string: cellView.link!.videoPreview)
        }
        AnyModalViewController.linkID = cellView.link!.getId()
    }
    
    init(baseUrl: URL, _ commentCallback: (() -> Void)?, upvoteCallback: (() -> Void)?, isUpvoted: Bool, failure: ((_ url: URL) -> Void)?) {
        super.init(nibName: nil, bundle: nil)
        self.commentCallback = commentCallback
        self.failureCallback = failure
        self.upvoteCallback = upvoteCallback
        self.isUpvoted = isUpvoted
        self.urlToLoad = baseUrl
        AnyModalViewController.linkID = ""
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var shouldLoad = false
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Re-enable screen dimming due to inactivity
        UIApplication.shared.isIdleTimerDisabled = false
        displayLink?.isPaused = true
        setOnce = false
        
        // Turn off forced fullscreen
        if forcedFullscreen {
            disableForcedFullscreen()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        
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
        blurEffect.setValue(5, forKeyPath: "blurRadius")
        blurView!.effect = blurEffect
        view.insertSubview(blurView!, at: 0)
        
        configureViews()
        configureLayout()
        connectGestures()
        connectActions()
        
        handleHideUI()
        volume.barTintColor = .white
        volume.barBackgroundColor = UIColor.white.withAlphaComponent(0.3)
        volume.animation = .slideDown
        view.addSubview(volume)
        
        NotificationCenter.default.addObserver(volume, selector: #selector(SubtleVolume.resume), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if urlToLoad != nil && self.embeddedPlayer == nil {
            let url = VideoMediaViewController.format(sS: urlToLoad!.absoluteString, true)
            let videoType = VideoMediaViewController.VideoType.fromPath(url)
            
            if videoType != .DIRECT && videoType != .REDDIT && videoType != .IMGUR {
                showSpinner()
            }
            
            DispatchQueue.global(qos: .background).async {
                //Prevent video from stopping system background audio
                do {
                    try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch let error as NSError {
                    print(error)
                }
            }

            DispatchQueue.global(qos: .userInteractive).async {
                _ = videoType.getSourceObject().load(url: url, completion: { [weak self] (urlString) in
                    guard let strongSelf = self else { return }
                    strongSelf.baseURL = URL(string: urlString)!
                    DispatchQueue.main.async {
                        if urlString.endsWith(".m3u8") {
                            strongSelf.downloadButton.isHidden = true
                        }
                        let avPlayerItem = AVPlayerItem(url: strongSelf.baseURL!)
                        strongSelf.videoView?.player = AVPlayer(playerItem: avPlayerItem)
                        strongSelf.embeddedPlayer = strongSelf.videoView!.player
                        strongSelf.videoView?.player?.isMuted = SettingValues.muteVideosInModal
                        strongSelf.videoView?.player?.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
                        strongSelf.scrubber.totalDuration = strongSelf.videoView.player!.currentItem!.asset.duration
                        strongSelf.hideSpinner()
                        strongSelf.videoView?.player?.play()
                    }
                    }, failure: {
                        self.dismiss(animated: true, completion: {
                            self.failureCallback?(URL.init(string: url)!)
                        })
                })
            }
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Recalculate video frame size
        var size = videoView.player?.currentItem?.presentationSize ?? self.view.bounds.size
        if size == CGSize.zero {
            size = self.view.bounds.size
        }

        self.videoView.frame = AVMakeRect(aspectRatio: size, insideRect: self.view.bounds)
    }
    
    override func viewDidLayoutSubviews() {
        layoutVolume()
    }
    
    func layoutVolume() {
        let volumeYPadding: CGFloat = 10
        let volumeXPadding = UIScreen.main.bounds.width * 0.4 / 2
        volume.superview?.bringSubviewToFront(volume)
        volume.frame = CGRect(x: safeAreaInsets.left + volumeXPadding, y: safeAreaInsets.top + volumeYPadding, width: UIScreen.main.bounds.width - (volumeXPadding * 2) - safeAreaInsets.left - safeAreaInsets.right, height: volumeHeight)
    }

    func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        setOnce = false
    }
    
    @objc func unmute() {
        self.videoView.player?.isMuted = false

        //SettingValues.autoplayAudioMode.activate()
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [])

        UIView.animate(withDuration: 0.5, animations: {
            self.muteButton.alpha = 0
        }, completion: { (_) in
            self.muteButton.isHidden = true
            self.muteButton.alpha = 1
        })
    }

    func connectActions() {
        menuButton.addTarget(self, action: #selector(showContextMenu(_:)), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(downloadVideoToLibrary(_:)), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(unmute), for: .touchUpInside)
        upvoteButton.addTarget(self, action: #selector(upvote(_:)), for: .touchUpInside)
        goToCommentsButton.addTarget(self, action: #selector(openComments(_:)), for: .touchUpInside)

        dTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        dTap?.numberOfTapsRequired = 2
        dTap?.delegate = self
        self.view.addGestureRecognizer(dTap!)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap?.require(toFail: dTap!)
        self.view.addGestureRecognizer(tap!)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(toggleForcedLandscapeFullscreen))
        self.view.addGestureRecognizer(longPress)
    }
    
    @objc func showContextMenu(_ sender: UIButton) {
        guard let baseURL = self.baseURL else {
            return
        }
        let alertController = DragDownAlertMenu(title: "Video options", subtitle: baseURL.absoluteString, icon: nil)
        
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alertController.addAction(title: "Open in Chrome", icon: UIImage(named: "nav")!.menuIcon()) {
                open.openInChrome(baseURL, callbackURL: nil, createNewTab: true)
            }
        }
        
        alertController.addAction(title: "Open in default app", icon: UIImage(named: "nav")!.menuIcon()) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(baseURL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(baseURL)
            }
        }

        alertController.addAction(title: "Share video URL", icon: UIImage(sfString: SFSymbol.arrowshapeTurnUpLeftFill, overrideString: "reply")!.menuIcon()) {
            let shareItems: Array = [baseURL]
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = sender
                presenter.sourceRect = sender.bounds
            }
            let window = UIApplication.shared.keyWindow!
            if let modalVC = window.rootViewController?.presentedViewController {
                modalVC.present(activityViewController, animated: true, completion: nil)
            } else {
                window.rootViewController!.present(activityViewController, animated: true, completion: nil)
            }
        }

        alertController.addAction(title: "Share Video", icon: UIImage(named: "play")!.menuIcon()) {
            self.shareVideo(baseURL, sender: sender)
        }

        let window = UIApplication.shared.keyWindow!
        
        if let modalVC = window.rootViewController?.presentedViewController {
            alertController.show(modalVC)
        } else {
            alertController.show(window.rootViewController)
        }
    }
    
    func shareVideo(_ baseURL: URL, sender: UIView) {
        VideoMediaDownloader.init(urlToLoad: baseURL).getVideoWithCompletion(completion: { (fileURL) in
            DispatchQueue.main.async {
                if fileURL != nil {
                    let shareItems: [Any] = [fileURL!]
                    let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                    if let presenter = activityViewController.popoverPresentationController {
                        presenter.sourceView = sender
                        presenter.sourceRect = sender.bounds
                    }
                    let window = UIApplication.shared.keyWindow!
                    if let modalVC = window.rootViewController?.presentedViewController {
                        modalVC.present(activityViewController, animated: true, completion: nil)
                    } else {
                        window.rootViewController!.present(activityViewController, animated: true, completion: nil)
                    }
                }
            }
        }, parent: self)
    }
    
    @objc func openComments(_ sender: AnyObject) {
        if commentCallback != nil {
            self.dismiss(animated: true) {
                self.commentCallback!()
            }
        }
    }
    
    @objc func downloadVideoToLibrary(_ sender: AnyObject) {
        VideoMediaDownloader(urlToLoad: baseURL!).getVideoWithCompletion(completion: { (fileURL) in
            if fileURL != nil {
                CustomAlbum.shared.saveMovieToLibrary(movieURL: fileURL!, parent: self)
            } else {
                BannerUtil.makeBanner(text: "Error downloading video", color: GMColor.red500Color(), seconds: 5, context: self, top: false, callback: nil)
            }
        }, parent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        savedColor = UIApplication.shared.statusBarUIView?.backgroundColor
        UIApplication.shared.statusBarUIView?.backgroundColor = .clear
        super.viewWillAppear(animated)
        if self.videoView.player == nil {
            if self.embeddedPlayer != nil {
                videoView.player = self.embeddedPlayer
            }
        }

        setOnce = false
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidUpdate))
        displayLink?.add(to: .current, forMode: RunLoop.Mode.default)
        displayLink?.isPaused = false

        videoView.player?.play()
        self.videoView.player?.isMuted = SettingValues.muteInlineVideos

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
        timer?.invalidate()
        
        UIApplication.shared.statusBarUIView?.isHidden = false
        if savedColor != nil {
            UIApplication.shared.statusBarUIView?.backgroundColor = savedColor
        }
        videoView.player?.play()
        
        self.embeddedPlayer?.isMuted = true
        if toReturnTo == nil || toReturnTo!.videoID != AnyModalViewController.linkID || AnyModalViewController.linkID.isEmpty {
            self.endVideos()
        } else {
            toReturnTo?.videoView.player = self.embeddedPlayer
            toReturnTo?.playView?.isHidden = true
            stopDisplayLink()
        }
        DispatchQueue.global(qos: .background).async {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            } catch {
                NSLog(error.localizedDescription)
            }
        }
        AnyModalViewController.linkID = ""
    }
    
    func endVideos() {
        self.displayLink?.invalidate()
        self.displayLink = nil
        self.videoView.player?.replaceCurrentItem(with: nil)
        self.videoView.player = nil
        if !(parent is ShadowboxLinkViewController) && !(parent is AlbumViewController) {
            DispatchQueue.global(qos: .background).async {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
                    try AVAudioSession.sharedInstance().setActive(false, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
                } catch {
                    NSLog(error.localizedDescription)
                }
            }
        }
    }
    
    deinit {
        stopDisplayLink()
        AnyModalViewController.linkID = ""
    }
    
    //    override func didReceiveMemoryWarning() {
    //        super.didReceiveMemoryWarning()
    //        // Dispose of any resources that can be recreated.
    //    }
    
    func configureViews() {
        videoView = VideoView()
        view.addSubview(videoView)
        videoView.player = self.embeddedPlayer
        
        if videoView.player?.currentItem != nil {
            scrubber.totalDuration = videoView.player!.currentItem!.asset.duration
        }
        DispatchQueue.global(qos: .background).async {
            // Prevent video from stopping system background audio
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print(error.localizedDescription)
                NSLog(error.localizedDescription)
            }
        }

        view.addSubview(scrubber)
        scrubber.delegate = self

        rewindImageView = UIImageView(image: UIImage(named: "rewind")?.getCopy(withSize: .square(size: 40), withColor: .white)).then {
            $0.alpha = 0
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            $0.layer.cornerRadius = 10
            $0.clipsToBounds = true
        }
        view.addSubview(rewindImageView)

        fastForwardImageView = UIImageView(image: UIImage(named: "fast_forward")?.getCopy(withSize: .square(size: 40), withColor: .white)).then {
            $0.alpha = 0
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            $0.layer.cornerRadius = 10
            $0.clipsToBounds = true
        }
        view.addSubview(fastForwardImageView)
        
        bottomButtons = UIStackView().then {
            $0.accessibilityIdentifier = "Bottom Buttons"
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 8
        }
        view.addSubview(bottomButtons)
        
        menuButton = UIButton().then {
            $0.accessibilityIdentifier = "More Button"
            $0.setImage(UIImage(named: "moreh")?.navIcon(true), for: [])
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        
        downloadButton = UIButton().then {
            $0.accessibilityIdentifier = "Download Button"
            $0.setImage(UIImage(sfString: SFSymbol.squareAndArrowDown, overrideString: "download")?.navIcon(true), for: [])
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        
        upvoteButton = UIButton().then {
            $0.accessibilityIdentifier = "Upvote Button"
            $0.setImage(UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")?.navIcon(true).getCopy(withColor: isUpvoted ? ColorUtil.upvoteColor : UIColor.white), for: [])
            $0.isHidden = upvoteCallback == nil // The button will be unhidden once the content has loaded.
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }

        muteButton = UIButton().then {
            $0.accessibilityIdentifier = "Un-Mute video"
            $0.isHidden = true
            $0.setImage(UIImage(named: "mute")?.navIcon(true).getCopy(withColor: GMColor.red500Color()), for: [])
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }

        goToCommentsButton = UIButton().then {
            $0.accessibilityIdentifier = "Go to Comments Button"
            $0.setImage(UIImage(named: "comments")?.navIcon(true), for: [])
            $0.isHidden = commentCallback == nil
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }

        closeButton.setImage(UIImage(named: "close")?.navIcon(true), for: .normal)
        closeButton.addTarget(self, action: #selector(self.exit), for: UIControl.Event.touchUpInside)
        self.view.addSubview(closeButton)

        bottomButtons.addArrangedSubviews(goToCommentsButton, upvoteButton, UIView.flexSpace(), muteButton, downloadButton, menuButton)
    }
    
    @objc func upvote(_ sender: AnyObject) {
        if upvoteCallback != nil {
            self.upvoteCallback!()
            self.isUpvoted = !self.isUpvoted
            self.upvoteButton.setImage(UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")?.navIcon(true).getCopy(withColor: isUpvoted ? ColorUtil.upvoteColor : UIColor.white), for: [])
        }
    }
    
    @objc func exit() {
        let viewToMove = videoView ?? self.view
        var newFrame = viewToMove!.frame
        newFrame.origin.y = -newFrame.size.height * 0.2
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            viewToMove!.frame = newFrame
            self.view.alpha = 0
            self.dismiss(animated: true)
        }) { (_) in
        }
    }
    
    func configureLayout() {
        bottomButtons.horizontalAnchors == view.safeHorizontalAnchors + CGFloat(8)
        bottomButtons.bottomAnchor == view.safeBottomAnchor - CGFloat(8)
        
        scrubber.horizontalAnchors == view.safeHorizontalAnchors + 8
        scrubber.topAnchor == view.safeTopAnchor + 8
        scrubber.bottomAnchor == bottomButtons.topAnchor - 4

        scrubber.playButton.centerAnchors == self.videoView.centerAnchors

        rewindImageView.centerYAnchor == view.centerYAnchor
        fastForwardImageView.centerYAnchor == view.centerYAnchor
        rewindImageView.leadingAnchor == view.safeLeadingAnchor + 30
        fastForwardImageView.trailingAnchor == view.safeTrailingAnchor - 30

        closeButton.sizeAnchors == .square(size: 26)
        closeButton.topAnchor == self.view.safeTopAnchor + 8
        closeButton.leftAnchor == self.view.safeLeftAnchor + 12

    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.ended {
            if scrubber.alpha == 0 {
                self.handleShowUI()
                self.startTimerToHide()
            } else {
                self.handleHideUI()
            }
        }
    }
    
    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.ended {
            
            let maxTime = scrubber.slider.maximumValue
            let x = sender.location(in: self.view).x
            let baseIncrement = min(maxTime / 5, 10)
            
            if x > UIScreen.main.bounds.size.width / 2 {
                seekAhead(bySeconds: baseIncrement)
            } else {
                seekAhead(bySeconds: -baseIncrement)
            }
        }
    }
    
    var lastTracks = false
    
    func showSpinner() {
        spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = self.view.center
        spinnerIndicator.color = UIColor.white
        self.view.addSubview(spinnerIndicator)
        spinnerIndicator.startAnimating()
    }
    
    func hideSpinner() {
        self.spinnerIndicator.stopAnimating()
        self.spinnerIndicator.isHidden = true
    }

    func startTimerToHide(_ duration: Double = 5) {
        cancelled = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: duration,
                                     target: self,
                                     selector: #selector(self.handleHideUI),
                                     userInfo: nil,
                                     repeats: false)
    }
    
    @objc func handleHideUI() {
        if !self.scrubber.isHidden {
            self.fullscreen(self)
            
            UIView.animate(withDuration: 0.2, animations: {
                self.scrubber.alpha = 0
            }, completion: { (_) in
                self.scrubber.isHidden = true
            })
        }
    }
    
    func handleShowUI() {
        timer?.invalidate()
        if self.scrubber.isHidden {
            self.unFullscreen(self)
            self.scrubber.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.scrubber.alpha = 1
            })
        }
    }
    
    func connectGestures() {
        didStartPan = { [weak self] result in
            if let strongSelf = self {
                strongSelf.unFullscreen(strongSelf.videoView)
            }
        }
    }
    
    var handlingPlayerItemDidreachEnd = false
    
    func playerItemDidreachEnd() {
        self.videoView?.player?.seek(to: CMTimeMake(value: 1, timescale: 1000), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            // NOTE: the following is not needed since `strongSelf.videoView.player?.actionAtItemEnd` is set to `AVPlayerActionAtItemEnd.none`
            //            if finished {
            //                strongSelf.videoView?.player?.play()
            //            }
            strongSelf.handlingPlayerItemDidreachEnd = false
        })
    }

    // TODO: Also fade background to black?
    @objc func toggleForcedLandscapeFullscreen(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        if !forcedFullscreen {
            enableForcedFullscreen()
        } else {
            disableForcedFullscreen()
        }
    }
    
    func enableForcedFullscreen() {
        // Turn on forced fullscreen
        
        let currentOrientation = UIApplication.shared.statusBarOrientation
        
        // Don't allow fullscreen to be forced if it's already landscape
        if currentOrientation != .landscapeLeft && currentOrientation != .landscapeRight {
            oldOrientation = currentOrientation
            AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight, andRotateTo: UIInterfaceOrientation.landscapeRight)
            forcedFullscreen = true
        } else {
            print("Can't force landscape when the app is already landscape!")
        }
    }
    
    func disableForcedFullscreen() {
        // Turn off forced fullscreen
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.allButUpsideDown, andRotateTo: oldOrientation ?? UIInterfaceOrientation.portrait)
        UIViewController.attemptRotationToDeviceOrientation()
        oldOrientation = nil
        forcedFullscreen = false
    }
    
}

// MARK: - Actions
extension AnyModalViewController {
    @objc func fullscreen(_ sender: AnyObject) {
        fullscreen = true
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            let statusBar: UIView = UIApplication.shared.statusBarUIView ?? UIView()
            statusBar.isHidden = true
            
            self.background?.alpha = 1
            self.bottomButtons.alpha = 0
            self.closeButton.alpha = 0
        }, completion: {_ in
            self.bottomButtons.isHidden = true
        })
    }
    
    @objc func unFullscreen(_ sender: AnyObject) {
        fullscreen = false
        self.bottomButtons.isHidden = false
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            let statusBar: UIView = UIApplication.shared.statusBarUIView ?? UIView()
            statusBar.isHidden = false
            self.closeButton.alpha = 1
            
            self.background?.alpha = 0.6
            self.bottomButtons.alpha = 1
            
        }, completion: {_ in
        })
    }
}

extension AnyModalViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == dTap && gestureRecognizer.view != nil {
            let location = gestureRecognizer.location(in: gestureRecognizer.view)
            let frame = gestureRecognizer.view!.frame
            if location.x < frame.size.width * 0.35 && location.x > frame.size.width * 0.65 {
                return false
            }
        }
        return true
    }
    
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
        
        let viewToMove = videoView!
        
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

extension AnyModalViewController {
    @objc func displayLinkDidUpdate(displaylink: CADisplayLink) {
        guard let player = videoView.player else {
            return
        }
        let hasAudioTracks = (player.currentItem?.tracks.count ?? 1) > 1

        if hasAudioTracks {
            if player.isMuted && muteButton.isHidden && SettingValues.muteVideosInModal {
                muteButton.isHidden = false
            }
        }
        
        if !setOnce || lastTracks != hasAudioTracks {
            setOnce = true
            lastTracks = hasAudioTracks

            if hasAudioTracks {
                if !SettingValues.muteVideosInModal {
                    if SettingValues.modalVideosRespectHardwareMuteSwitch {
                        try? AVAudioSession.sharedInstance().setCategory(.soloAmbient, options: [])
                    } else {
                        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [])
                    }
                    player.isMuted = false
                } else {
                    try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
                }
            } else {
                // If there's no audio track, set the category to ambient to prevent the player
                // from silencing background audio
                do {
                    try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
                } catch {
                    NSLog(error.localizedDescription)
                }
            }
        }

        if !sliderBeingUsed {
            if let player = videoView.player {
                scrubber.updateWithTime(elapsedTime: player.currentTime())
            }
            if toReturnTo == nil {
                guard let embeddedPlayer = embeddedPlayer else {
                    return
                }
                let elapsedTime = embeddedPlayer.currentTime()
                if CMTIME_IS_INVALID(elapsedTime) {
                    return
                }
                let duration = Float(CMTimeGetSeconds(embeddedPlayer.currentItem!.duration))
                let time = Float(CMTimeGetSeconds(elapsedTime))
                
                if !handlingPlayerItemDidreachEnd && (time / duration) >= 0.99 {
                    handlingPlayerItemDidreachEnd = true
                    self.playerItemDidreachEnd()
                }
            }
        }
    }
}

extension AnyModalViewController: VideoScrubberViewDelegate {
    func seekAhead(bySeconds seconds: Float) {
        let playerCurrentTime = scrubber.slider.value
        let maxTime = scrubber.slider.maximumValue

        // Animate the indicator for fast_forward or rewind
        let indicatorViewToAnimate = seconds > 0 ? fastForwardImageView : rewindImageView
        indicatorViewToAnimate.isHidden = false
        UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: [.calculationModeCubic], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
                indicatorViewToAnimate.alpha = 1.0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) {
                indicatorViewToAnimate.alpha = 0.0
            }
        }, completion: { _ in
            indicatorViewToAnimate.isHidden = true
        })
        
        var newTime = (playerCurrentTime + seconds)
        newTime = min(newTime, maxTime) // Prevent seeking beyond end
        newTime = max(newTime, 0) // Prevent seeking before beginning
        
        let tolerance: CMTime = CMTimeMakeWithSeconds(0.001, preferredTimescale: 1000) // 1 ms with a resolution of 1 ms
        let newCMTime = CMTimeMakeWithSeconds(Float64(newTime), preferredTimescale: 1000)
        self.videoView.player?.seek(to: newCMTime, toleranceBefore: tolerance, toleranceAfter: tolerance) { _ in
            self.videoView.player?.play()
        }
    }
    
    func sliderValueChanged(toSeconds: Float) {
        self.handleShowUI()
        //        self.videoView.player?.pause()
        
        let targetTime = CMTime(seconds: Double(toSeconds), preferredTimescale: 1000)
        
        let tolerance: CMTime = CMTimeMakeWithSeconds(0.001, preferredTimescale: 1000) // 1 ms with a resolution of 1 ms
        self.videoView.player?.seek(to: targetTime, toleranceBefore: tolerance, toleranceAfter: tolerance)
    }
    
    func sliderDidBeginDragging() {
        if let player = videoView.player {
            wasPlayingWhenPaused = player.rate != 0
            player.pause()
        }
        sliderBeingUsed = true
    }
    
    func sliderDidEndDragging() {
        // Start playing the video again if it was playing when the slider started being dragged
        if wasPlayingWhenPaused {
            self.videoView.player?.play()
        }
        self.startTimerToHide(1)
        sliderBeingUsed = false
    }
    
    func toggleReturnPlaying() -> Bool {
        self.handleShowUI()
        if let player = videoView.player {
            if player.rate != 0 {
                player.pause()
                return false
            } else {
                player.play()
                self.startTimerToHide()
                return true
            }
        }
        return false
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
extension AVAsset {
    var g_fileSize: Double {
        var estimatedSize: Double = 0
        for track in tracks {
            let rate = Double(track.estimatedDataRate / 8)
            let seconds = Double(CMTimeGetSeconds(track.timeRange.duration))
            estimatedSize += seconds * rate
        }
        return estimatedSize
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}
