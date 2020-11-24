//
//  VideoMediaViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Alamofire
import Anchorage
import AVFoundation
import SDCAlertView
import SDWebImage
import SubtleVolume
import Then
import UIKit

class VideoMediaViewController: EmbeddableMediaViewController, UIGestureRecognizerDelegate, SubtleVolumeDelegate {

    var isYoutubeView: Bool {
        return contentType == ContentType.CType.VIDEO
    }
    
    var youtubeMute = false {
        didSet(fromValue) {
            let changeImage = youtubeMute ? UIImage(sfString: SFSymbol.speakerSlashFill, overrideString: "mute")?.navIcon(true).getCopy(withColor: GMColor.red500Color()) : UIImage(sfString: SFSymbol.speaker2Fill, overrideString: "audio")?.navIcon(true)
            
            UIView.animate(withDuration: 0.5, animations: {
                self.muteButton.setImage(changeImage, for: UIControl.State.normal)
            }, completion: nil)
        }
    }
    let volume = SubtleVolume(style: SubtleVolumeStyle.rounded)
    let volumeHeight: CGFloat = 3
    var setOnce = false

    var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, tvOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets.zero
        }
    }
    
    func subtleVolume(_ subtleVolume: SubtleVolume, willChange value: Double) {
        if !self.muteButton.isHidden && !SettingValues.modalVideosRespectHardwareMuteSwitch {
       //disable for now     self.unmute()
        }
    }
    
    var youtubeResolution = CGSize(width: 16, height: 9)
    var videoView = VideoView()
    var youtubeView = WKYTPlayerView()
    var downloadedOnce = false
    
    var size = UILabel()
    var videoType: VideoType!
    
    var lastTime = Float(0)
    
    var menuButton = UIButton()
    var muteButton = UIButton()
    var downloadButton = UIButton()
    var ytButton = UIButton()
    var request: DownloadRequest?
    var youtubeURL: URL?

    var goToCommentsButton = UIButton()
    var showTitleButton = UIButton()

    var scrubber = VideoScrubberView()

    var sliderBeingUsed: Bool = false
    var wasPlayingWhenPaused: Bool = false

    var tap: UITapGestureRecognizer?
    var dTap: UITapGestureRecognizer?
    
    var timer: Timer?
    var cancelled = false

    var displayLink: CADisplayLink?

    var forcedFullscreen = false
    var oldOrientation: UIInterfaceOrientation?

    var fastForwardImageView = UIImageView()
    var rewindImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Disable screen dimming due to inactivity
        UIApplication.shared.isIdleTimerDisabled = true
        loaded = false
        configureViews()
        configureLayout()
        connectActions()

        handleHideUI(hideTitle: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.handleHideUI(hideTitle: true)
        })
        
        volume.barTintColor = .white
        volume.barBackgroundColor = UIColor.white.withAlphaComponent(0.3)
        volume.animation = .slideDown
        
        var is13 = false
        if #available(iOS 13, *) {
            is13 = true
        }
        if !((parent?.parent) is ShadowboxLinkViewController) && !is13 {
            view.addSubview(volume)
            volume.delegate = self
            NotificationCenter.default.addObserver(volume, selector: #selector(SubtleVolume.resume), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
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
    }

    var loaded = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if loaded && ((parent is ShadowboxLinkViewController) || (parent is AlbumViewController)) {
            displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidUpdate))
            displayLink?.add(to: .current, forMode: RunLoop.Mode.default)
            displayLink?.isPaused = false
            videoView.player?.play()
        } else {
            loadContent()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        timer?.invalidate()
        request?.cancel()
        stopDisplayLink()
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        self.endVideos()
        // Turn off forced fullscreen
        if forcedFullscreen {
            disableForcedFullscreen()
        }
    }

    deinit {
        self.endVideos()
        self.videoView.player?.replaceCurrentItem(with: nil)
        self.videoView.player = nil
    }
    
    func endVideos() {
        self.displayLink?.invalidate()
        self.displayLink = nil
        
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

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        resetFrame(withSize: self.view.frame.size)
    }
    
    func resetFrame(withSize: CGSize) {
        // Recalculate youtube frame size
        self.youtubeView.frame = AVMakeRect(aspectRatio: youtubeResolution, insideRect: self.view.bounds)

        // Recalculate player size
        var size = videoView.player?.currentItem?.presentationSize ?? self.view.bounds.size
        if size == CGSize.zero {
            size = withSize
        }

        self.videoView.frame = AVMakeRect(aspectRatio: size, insideRect: self.view.bounds) // CALayer position contains NaN: [nan nan]
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        resetFrame(withSize: size)
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

    func configureViews() {
        view.addSubview(videoView)

        youtubeView.delegate = self
        youtubeView.isHidden = true
        youtubeView.isUserInteractionEnabled = false
        view.addSubview(youtubeView)

        view.addSubview(scrubber)
        scrubber.delegate = self

        rewindImageView = UIImageView(image: UIImage(sfString: SFSymbol.backwardEndFill, overrideString: "rewind")?.getCopy(withSize: .square(size: 30), withColor: .white)).then {
            $0.alpha = 0
            $0.contentMode = .scaleAspectFit
        }
        view.addSubview(rewindImageView)

        fastForwardImageView = UIImageView(image: UIImage(sfString: SFSymbol.forwardEndFill, overrideString: "fast_forward")?.getCopy(withSize: .square(size: 30), withColor: .white)).then {
            $0.alpha = 0
            $0.contentMode = .scaleAspectFit
        }
        view.addSubview(fastForwardImageView)

        bottomButtons = UIStackView().then {
            $0.accessibilityIdentifier = "Bottom Buttons"
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 8
        }
        gradientView.addSubview(bottomButtons)
        view.addSubview(gradientView)
        
        if data.buttons {
            menuButton = UIButton().then {
                $0.accessibilityIdentifier = "More Button"
                $0.setImage(UIImage(sfString: SFSymbol.ellipsis, overrideString: "moreh")?.navIcon(true), for: [])
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            
            downloadButton = UIButton().then {
                $0.accessibilityIdentifier = "Download Button"
                $0.setImage(UIImage(sfString: SFSymbol.squareAndArrowDownFill, overrideString: "download")?.navIcon(true), for: [])
                $0.isHidden = true // The button will be unhidden once the content has loaded.
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            
            upvoteButton = UIButton().then {
                $0.accessibilityIdentifier = "Upvote Button"
                $0.setImage(UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")?.navIcon(true).getCopy(withColor: isUpvoted ? ColorUtil.upvoteColor : UIColor.white), for: [])
                $0.isHidden = upvoteCallback == nil // The button will be unhidden once the content has loaded.
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }

            muteButton = UIButton().then {
                $0.accessibilityIdentifier = "Un-mute video"
                $0.setImage(UIImage(sfString: SFSymbol.speakerSlashFill, overrideString: "mute")?.navIcon(true).getCopy(withColor: GMColor.red500Color()), for: [])
                $0.isHidden = true // The button will be unhidden once the content has loaded.
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            
            ytButton = UIButton().then {
                $0.accessibilityIdentifier = "Open in YouTube"
                $0.setImage(UIImage(named: "youtube")?.navIcon(true), for: [])
                $0.isHidden = true // The button will be unhidden once the content has loaded.
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            
            goToCommentsButton = UIButton().then {
                $0.accessibilityIdentifier = "Go to Comments Button"
                $0.setImage(UIImage(sfString: SFSymbol.bubbleLeftAndBubbleRightFill, overrideString: "comments")?.navIcon(true), for: [])
                $0.isHidden = commentCallback == nil
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            
            showTitleButton = UIButton().then {
                $0.accessibilityIdentifier = "Show Title Button"
                $0.setImage(UIImage(sfString: SFSymbol.textbox, overrideString: "size")?.navIcon(true), for: [])
                $0.isHidden = !(data.text != nil && !(data.text!.isEmpty))
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            
            size = UILabel().then {
                $0.accessibilityIdentifier = "File size"
                $0.font = UIFont.boldSystemFont(ofSize: 12)
                $0.textAlignment = .center
                $0.textColor = .white
            }
            
            bottomButtons.addArrangedSubviews(showTitleButton, goToCommentsButton, upvoteButton, size, UIView.flexSpace(), muteButton, ytButton, downloadButton, menuButton)
        }
    }
    
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
    
    @objc func unmute() {
        if isYoutubeView {
            if youtubeMute {
                // TODO: - An error is thrown when this is evaluated. Resolve why to allow error handling
                youtubeView.webView?.evaluateJavaScript("player.unMute()") { [weak self] (_, _) in
                    if let strongSelf = self {
                        strongSelf.youtubeMute = false
                        strongSelf.videoView.player?.isMuted = false
                        
                        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [])
                    }
                }
            } else {
                youtubeView.webView?.evaluateJavaScript("player.mute()") { [weak self] (_, _) in
                    if let strongSelf = self {
                        strongSelf.youtubeMute = true
                        strongSelf.videoView.player?.isMuted = true
                        
                        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
                    }
                }
            }
        } else {
            if youtubeMute {
                self.youtubeMute = false
                self.videoView.player?.isMuted = false
                
                try? AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            } else {
                self.youtubeMute = true
                self.videoView.player?.isMuted = true
                
                try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            }
        }
    }
    
    func connectActions() {
        menuButton.addTarget(self, action: #selector(showContextMenu(_:)), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(downloadVideoToLibrary(_:)), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(unmute), for: .touchUpInside)
        upvoteButton.addTarget(self, action: #selector(upvote(_:)), for: .touchUpInside)
        goToCommentsButton.addTarget(self, action: #selector(openComments(_:)), for: .touchUpInside)
        showTitleButton.addTarget(self, action: #selector(showTitle(_:)), for: .touchUpInside)
        ytButton.addTarget(self, action: #selector(openInYoutube(_:)), for: .touchUpInside)

        dTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        dTap?.numberOfTapsRequired = 2
        dTap?.delegate = self
        self.view.addGestureRecognizer(dTap!)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap?.require(toFail: dTap!)
        self.view.addGestureRecognizer(tap!)
        
        let dTap2 = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        dTap2.numberOfTapsRequired = 2
        self.youtubeView.addGestureRecognizer(dTap2)

        let tap2 = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap2.require(toFail: dTap2)
        self.youtubeView.addGestureRecognizer(tap2)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(toggleForcedLandscapeFullscreen))
        self.view.addGestureRecognizer(longPress)
    }
    
    func configureLayout() {
        
        bottomButtons.horizontalAnchors /==/ gradientView.safeHorizontalAnchors + CGFloat(8)
        bottomButtons.topAnchor /==/ gradientView.topAnchor + 20
        bottomButtons.bottomAnchor /==/ gradientView.safeBottomAnchor - 8
        gradientView.horizontalAnchors /==/ view.horizontalAnchors
        gradientView.bottomAnchor /==/ view.bottomAnchor

        scrubber.horizontalAnchors /==/ view.safeHorizontalAnchors + 8
        scrubber.topAnchor /==/ view.safeTopAnchor + 8
        scrubber.bottomAnchor /==/ gradientView.topAnchor - 4
        
        scrubber.playButton.centerAnchors /==/ self.videoView.centerAnchors

        rewindImageView.centerYAnchor /==/ view.centerYAnchor
        fastForwardImageView.centerYAnchor /==/ view.centerYAnchor
        rewindImageView.leadingAnchor /==/ view.safeLeadingAnchor + 30
        fastForwardImageView.trailingAnchor /==/ view.safeTrailingAnchor - 30
        
        fastForwardImageView.sizeAnchors == CGSize.square(size: 30)
        rewindImageView.sizeAnchors == CGSize.square(size: 30)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.ended {
            if scrubber.alpha == 0 {
                self.handleShowUI()
                self.startTimerToHide()
            } else {
                self.handleHideUI(hideTitle: true)
            }
        }
    }
    
    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.ended {
            
            let maxTime = scrubber.slider.maximumValue
            let x = sender.location(in: self.view).x
            let baseIncrement = isYoutubeView ? 10 : min(maxTime / 5, 10)
            
            if x > UIScreen.main.bounds.size.width / 2 {
                seekAhead(bySeconds: baseIncrement)
            } else {
                seekAhead(bySeconds: -baseIncrement)
            }
        }
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
    
    @objc func handleHideUI(hideTitle: Bool) {
        if !self.scrubber.isHidden || hideTitle {
            if let parent = parent as? ModalMediaViewController {
                parent.fullscreen(self, hideTitle)
            }

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
            if let parent = parent as? ModalMediaViewController {
                parent.unFullscreen(self)
            }
            self.scrubber.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.scrubber.alpha = 1
            })
        }
    }

    // TODO: - Also fade background to black?
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
    
    var spinnerIndicator = UIActivityIndicatorView()
    
    func loadContent() {

        // Load Youtube View
        if isYoutubeView {
            showSpinner()
            
            youtubeView.isHidden = false
            progressView.isHidden = true
            loadYoutube(url: data.baseURL!.absoluteString)
            return
        } else {
            youtubeView.isHidden = true
        }

        // Otherwise load AVPlayer
        let url = formatUrl(sS: data.baseURL!.absoluteString, SettingValues.streamVideos)
        videoType = VideoType.fromPath(url)
        
        if videoType != .DIRECT && videoType != .REDDIT && videoType != .IMGUR {
            showSpinner()
        }

        _ = videoType.getSourceObject().load(url: url, completion: { [weak self] (urlString) in
            self?.getVideo(urlString)
        }, failure: {
            self.parent?.dismiss(animated: true, completion: {
                self.failureCallback?(URL.init(string: url)!)
            })
        })
    }
    
    func showSpinner() {
        spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = self.view.center
        spinnerIndicator.color = UIColor.white
        self.view.addSubview(spinnerIndicator)
        spinnerIndicator.startAnimating()
        self.progressView.isHidden = true
    }
    
    func hideSpinner() {
        self.progressView.isHidden = false
        self.spinnerIndicator.stopAnimating()
        self.spinnerIndicator.isHidden = true
    }
    
    var lastTracks = false
    
    func getQualityURL(urlToLoad: String, qualityList: [String],  callback: @escaping (_ realURL: String) -> Void) {
        if qualityList.isEmpty {
            BannerUtil.makeBanner(text: "Error finding video URL", color: GMColor.red500Color(), seconds: 5, context: self.parent ?? nil, top: false, callback: nil)
        } else {
            testQuality(urlToLoad: urlToLoad, quality: qualityList.first ?? "") { (success, url) in
                if success {
                    callback(url)
                } else {
                    var newList = qualityList
                    newList.remove(at: 0)
                    self.getQualityURL(urlToLoad: urlToLoad, qualityList: newList, callback: callback)
                }
            }
        }
    }
    
    func testQuality(urlToLoad: String, quality: String, completion: @escaping(_ success: Bool, _ url: String) -> Void) {
        Alamofire.request(urlToLoad.replacingOccurrences(of: "HLSPlaylist.m3u8", with: "DASH_\(quality)"), method: .get).responseString { response in
            if response.response?.statusCode == 200 {
                completion(response.response?.statusCode ?? 0 == 200, urlToLoad.replacingOccurrences(of: "HLSPlaylist.m3u8", with: "DASH_\(quality)"))
            } else {
                Alamofire.request(urlToLoad.replacingOccurrences(of: "HLSPlaylist.m3u8", with: "DASH_\(quality).mp4"), method: .get).responseString { response in
                    completion(response.response?.statusCode ?? 0 == 200, urlToLoad.replacingOccurrences(of: "HLSPlaylist.m3u8", with: "DASH_\(quality).mp4"))
                }
            }
        }
    }

    func getVideo(_ toLoad: String) {
        self.hideSpinner()

        if FileManager.default.fileExists(atPath: getKeyFromURL()) || SettingValues.streamVideos {
            playVideo(toLoad)
        } else {
            print(toLoad)
            if toLoad.contains("HLSPlaylist.m3u8") {
                let qualityList = ["1080", "720", "480", "360", "240", "96"]
                getQualityURL(urlToLoad: toLoad, qualityList: qualityList) { url in
                    self.data.baseURL = URL(string: url)
                    self.videoType = VideoType.DIRECT
                    if FileManager.default.fileExists(atPath: self.getKeyFromURL()) {
                        self.playVideo(url)
                    } else {
                        self.doDownload(url)
                    }
                }
            } else {
                doDownload(toLoad)
            }
        }
    }
    
    func doDownload(_ toLoad: String) {
        
        print("Downloading " + toLoad)
        let fileURLPath = self.videoType == .REDDIT ? self.getKeyFromURL().replacingOccurrences(of: ".mp4", with: "video.mp4") : self.getKeyFromURL()
        request = Alamofire.download(toLoad, method: .get, to: { (_, _) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
            return (URL(fileURLWithPath: fileURLPath), [.createIntermediateDirectories])
        }).downloadProgress() { progress in
        DispatchQueue.main.async {
            let countBytes = ByteCountFormatter()
            countBytes.allowedUnits = [.useMB]
            countBytes.countStyle = .file
            let fileSize = countBytes.string(fromByteCount: Int64(progress.totalUnitCount))
            self.updateProgress(CGFloat(progress.fractionCompleted), fileSize)
            self.size.text = fileSize
        }
        }.responseData { response in
            if response.error == nil {
                if self.videoType == .REDDIT {
                    self.downloadRedditAudio(fileURLPath)
                } else {
                    DispatchQueue.main.async {
                        self.playVideo()
                    }
                }
            } else {
                print(response.error)
                self.parent?.dismiss(animated: true, completion: {
                    self.failureCallback?(URL.init(string: toLoad)!)
                })
            }
        }
    }
    
    func downloadRedditAudio(_ videoLocation: String) {
        let key = getKeyFromURL()
        var toLoadAudioBase = self.data.baseURL!.absoluteString
        toLoadAudioBase = toLoadAudioBase.substring(0, length: toLoadAudioBase.lastIndexOf("/") ?? toLoadAudioBase.length)
        
        let toLoadAudio = "\(toLoadAudioBase)/DASH_audio.mp4"
        let finalUrl = URL.init(fileURLWithPath: key)
        let localUrlV = URL.init(fileURLWithPath: videoLocation)
        let localUrlAudio = URL.init(fileURLWithPath: key.replacingOccurrences(of: ".mp4", with: "audio.mp4"))

        Alamofire.request(toLoadAudio).responseString { (response) in
            if response.response?.statusCode == 200 { //Audio exists, let's get it
                self.requestWithProgress(url: finalUrl, localUrlAudio: localUrlAudio) { (response) in
                    if (response.error as NSError?)?.code == NSURLErrorCancelled { //Cancelled, exit
                        return
                    }
                    if response.response!.statusCode != 200 { //Shouldn't be here
                        self.doCopyAndPlay(localUrlV, to: finalUrl)
                    } else { //no errors, merge audio and video
                        self.mergeFilesWithUrl(videoUrl: localUrlV, audioUrl: localUrlAudio, savePathUrl: finalUrl) {
                            DispatchQueue.main.async {
                                self.playVideo()
                            }
                        }
                    }

                }
            } else if response.response?.statusCode ?? 0 > 400 { //Might exist elsewhere
                Alamofire.request("\(toLoadAudioBase)/audio").responseString { (response) in
                    if response.response?.statusCode == 200 { //Audio exists, let's get it
                        self.requestWithProgress(url: finalUrl, localUrlAudio: localUrlAudio) { (response) in
                            if (response.error as NSError?)?.code == NSURLErrorCancelled { //Cancelled, exit
                                return
                            }
                            if response.response!.statusCode != 200 { //Shouldn't be here
                                self.doCopyAndPlay(localUrlV, to: finalUrl)
                            } else { //no errors, merge audio and video
                                self.mergeFilesWithUrl(videoUrl: localUrlV, audioUrl: localUrlAudio, savePathUrl: finalUrl) {
                                    DispatchQueue.main.async {
                                        self.playVideo()
                                    }
                                }
                            }
                        }
                    } else {
                        self.doCopyAndPlay(localUrlV, to: finalUrl)
                    }
                }
            } else {
                self.doCopyAndPlay(localUrlV, to: finalUrl)
            }
        }
    }
    
    func doCopyAndPlay(_ localUrlV: URL, to finalUrl: URL) {
        do {
            try FileManager.init().copyItem(at: localUrlV, to: finalUrl)
            DispatchQueue.main.async {
                self.playVideo()
            }
        } catch {
            DispatchQueue.main.async {
                self.playVideo()
            }
        }
    }
    
    func requestWithProgress(url: URL, localUrlAudio: URL, callback: @escaping (DownloadResponse<Data>) -> Void) {
        self.request = Alamofire.download(url, method: .get, to: { (_, _) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
            return (localUrlAudio, [.removePreviousFile, .createIntermediateDirectories])
        }).downloadProgress() { progress in
            DispatchQueue.main.async {
                self.updateProgress(CGFloat(progress.fractionCompleted), "")
            }
        }
        .responseData { response in
            callback(response)
        }
    }
    
    func playVideo(_ url: String = "") {
        //Prevent video from stopping system background audio
        DispatchQueue.global(qos: .background).async {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError {
                print(error)
            }
        }
        
        self.setProgressViewVisible(false)
        self.size.isHidden = true
//        self.downloadButton.isHidden = true// TODO: - maybe download videos in the future?
        print("Wanting to play " +  getKeyFromURL())
        if let videoUrl = SettingValues.streamVideos ? URL(string: url) : URL(fileURLWithPath: getKeyFromURL()) {
            let playerItem = AVPlayerItem(url: videoUrl)
            videoView.player = AVPlayer(playerItem: playerItem)
            videoView.player?.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
            self.videoView.player?.isMuted = SettingValues.muteVideosInModal
            
            scrubber.totalDuration = videoView.player!.currentItem!.asset.duration
            self.loaded = true
            displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidUpdate))
            displayLink?.add(to: .current, forMode: RunLoop.Mode.default)
            displayLink?.isPaused = false
            videoView.player?.play()
        } else {
            self.parent?.dismiss(animated: true, completion: {
                self.failureCallback?(URL.init(string: url)!)
            })
        }
    }
    
    var handlingPlayerItemDidreachEnd = false
    
    func playerItemDidreachEnd() {
        self.videoView.player!.seek(to: CMTimeMake(value: 1, timescale: 1000), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            // NOTE: the following is not needed since `strongSelf.videoView.player?.actionAtItemEnd` is set to `AVPlayerActionAtItemEnd.none`
//            if finished {
//                strongSelf.videoView?.player?.play()
//            }
            strongSelf.handlingPlayerItemDidreachEnd = false
        })
    }
    
    static func format(sS: String, _ hls: Bool = false) -> String {
        var s = sS
        if s.hasSuffix("v") && !s.contains("streamable.com") {
            s = s.substring(0, length: s.length - 1)
        } else if s.contains("gfycat") && (!s.contains("mp4") && !s.contains("webm")) {
            if s.contains("-size_restricted") {
                s = s.replacingOccurrences(of: "-size_restricted", with: "")
            }
        }
        if (s.contains(".webm") || s.contains(".gif")) && !s.contains(".gifv") && s.contains(
            "imgur.com") {
            s = s.replacingOccurrences(of: ".gifv", with: ".mp4")
            s = s.replacingOccurrences(of: ".gif", with: ".mp4")
            s = s.replacingOccurrences(of: ".webm", with: ".mp4")
        }
        if s.endsWith("/") {
            s = s.substring(0, length: s.length - 1)
        }
        if s.contains("v.redd.it") && !s.contains("DASH") && !s.contains("HLSPlaylist.m3u8") {
            if s.endsWith("/") {
                s = s.substring(0, length: s.length - 2)
            }
            s += "/DASH_9_6_M"
        }
        if hls && !s.contains("HLSPlaylist.m3u8") {
            if s.contains("v.redd.it") && s.contains("DASH") {
                if s.endsWith("/") {
                    s = s.substring(0, length: s.length - 2)
                }
                s = s.substring(0, length: s.lastIndexOf("/")!)
                s += "/HLSPlaylist.m3u8"
            } else if s.contains("v.redd.it") {
                if s.endsWith("/") {
                    s = s.substring(0, length: s.length - 2)
                }
                if !s.contains("HLSPlaylist") {
                    s += "/HLSPlaylist.m3u8"
                }
            }
        }
        return s
    }
    
    func formatUrl(sS: String, _ vreddit: Bool = false) -> String {
        return VideoMediaViewController.format(sS: sS, SettingValues.streamVideos)
    }

    public enum VideoType {
        case DIRECT
        case IMGUR
        case STREAMABLE
        case GFYCAT
        case REDDIT
        case OTHER

        static func fromPath(_ url: String) -> VideoType {
            if url.contains(".mp4") || url.contains("webm") || url.contains("redditmedia.com") || (url.contains("preview.redd.it") && url.contains("format=mp4")) {
                return VideoType.DIRECT
            }
            if url.contains("gfycat") && !url.contains("mp4") {
                return VideoType.GFYCAT
            }
            if url.contains("redgifs") && !url.contains("mp4") {
                return VideoType.GFYCAT
            }
            if url.contains("v.redd.it") {
                return VideoType.REDDIT
            }
            if url.contains("imgur.com") {
                return VideoType.IMGUR
            }
            if url.contains("streamable.com") {
                return VideoType.STREAMABLE
            }
            return VideoType.OTHER
        }

        func getSourceObject() -> VideoSource {
            switch self {
            case .GFYCAT:
                return GfycatVideoSource()
            case .REDDIT:
                return RedditVideoSource()
            case .DIRECT, .IMGUR:
                return DirectVideoSource()
            case .STREAMABLE:
                return StreamableVideoSource()
            case .OTHER:
                return DirectVideoSource()
            }
        }
    }

}

extension VideoMediaViewController {

    func loadYoutube(url urlS: String) {
        var seconds = 0
        var video = ""
        var playlist = ""
        
        var url = urlS
        if let unencoded = url.removingPercentEncoding {
            url = unencoded
        }
        url = url.decodeHTML()

        if url.contains("#t=") {
            url = url.replacingOccurrences(of: "#t=", with: url.contains("?") ? "&t=" : "?t=")
        }

        let i = URL(string: url)
        if let dictionary = i?.queryDictionary {
            print(dictionary)
            if let t = dictionary["t"] {
                seconds = getTimeFromString(t)
            } else if let start = dictionary["start"] {
                seconds = getTimeFromString(start)
            }

            if let list = dictionary["list"] {
                playlist = list
            }

            if let v = dictionary["v"] {
                video = v
            } else if let w = dictionary["w"] {
                video = w
            } else if url.lowercased().contains("youtu.be") {
                video = getLastPathSegment(url)
            }

            if let u = dictionary["u"] {
                let startIndex = u.indexOf("=")! + 1
                let param = u.substring(startIndex, length: u.length - startIndex)
                let paramStart = param.contains("&") ? param.indexOf("&")! : 0
                video = param.substring(paramStart, length: param.length - paramStart)
            }
        }
        
        if video.contains("?") {
            video = video.substring(0, length: video.indexOf("?")!)
        }

        getYoutubeVideoResolution(videoId: video) { [weak self] (resolution) in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.youtubeResolution = resolution
            strongSelf.view.setNeedsLayout()
            // https://developers.google.com/youtube/player_parameters
            let vars: [String: Any] = [
                "controls": 0, // Disable controls
                "playsinline": 1,
                "autoplay": 0,
                "start": seconds,
                "fs": 0, // Turn off fullscreen button
                "rel": 0, // Turn off suggested content at end (restricts to same channel as video)
                "loop": 1,
                "iv_load_policy": 3, // Hide annotations
                "modestbranding": 0, // Remove youtube logo on bottom right
                "origin": "https://ccrama.me",
                "hl": Locale.current.languageCode ?? "en",
                ]
            
            strongSelf.youtubeURL = URL(string: "youtube://\(playlist.isEmpty() ? video : playlist)")!
            if strongSelf.youtubeURL != nil && UIApplication.shared.canOpenURL(strongSelf.youtubeURL!) {
                strongSelf.ytButton.isHidden = false
            }
            
            if !playlist.isEmpty {
                strongSelf.youtubeView.load(withPlaylistId: playlist, playerVars: vars)
            } else {
                // https://developers.google.com/youtube/player_parameters
                strongSelf.youtubeView.load(withVideoId: video, playerVars: vars)
            }
        }
    }

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
        
        if isYoutubeView {
            displayLink?.isPaused = true
            youtubeView.seek(toSeconds: newTime, allowSeekAhead: true)
            youtubeView.playVideo()
        } else {
            let tolerance: CMTime = CMTimeMakeWithSeconds(0.001, preferredTimescale: 1000) // 1 ms with a resolution of 1 ms
            let newCMTime = CMTimeMakeWithSeconds(Float64(newTime), preferredTimescale: 1000)
            self.videoView.player?.seek(to: newCMTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { _ in
                self.videoView.player?.play()
            }
        }
    }

    /*
     Retrieves the resolution of the given YouTube video from their oembed API. Unfortunately, this
     information is rarely correct for nonstandard video sizes, but if YouTube ever gets around to
     fixing it then this will work.
     */
    func getYoutubeVideoResolution(videoId: String, completion: @escaping (CGSize) -> Void) {
        let metaURL = URL(string: "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(videoId)&format=json")!

        print(metaURL)
        func failureBlock() {
            OperationQueue.main.addOperation({
                completion(CGSize(width: 16, height: 9))
            })
        }
        
        //fetching the data from the url
        URLSession.shared.dataTask(with: metaURL, completionHandler: { (data, _, error) -> Void in
            if error != nil {
                failureBlock()
                return
            }
            guard let data = data,
                let jsonObj = ((try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary) as NSDictionary??),
                let dict = jsonObj else {
                failureBlock()
                return
            }

            let height = dict.value(forKey: "height") as! CGFloat
            let width = dict.value(forKey: "width") as! CGFloat

            OperationQueue.main.addOperation({
                print("Youtube video is \(width)x\(height)")
                completion(CGSize(width: width, height: height))
            })

        }).resume()
    }
    
    func getKeyFromURL() -> String {
        let disallowedChars = CharacterSet.urlPathAllowed.inverted
        var key = ""
        
        if let strongURL = self.data.baseURL, var components = URLComponents(string: strongURL.absoluteString) {
            components.query = nil
            key = components.url?.absoluteString.components(separatedBy: disallowedChars).joined(separator: "_") ?? strongURL.absoluteString.components(separatedBy: disallowedChars).joined(separator: "_") //Get rid of params, and all non-filename characters
        } else if let strongURL = self.data.baseURL {
            key = strongURL.absoluteString.components(separatedBy: disallowedChars).joined(separator: "_")
        } else {
            key = "temporaryvideo.mp4"
        }

        key = key.replacingOccurrences(of: ":", with: "")
        key = key.replacingOccurrences(of: "/", with: "")
        key = key.replacingOccurrences(of: ".gifv", with: ".mp4")
        key = key.replacingOccurrences(of: ".gif", with: ".mp4")
        key = key.replacingOccurrences(of: ".", with: "")
        if key.length > 200 {
            key = key.substring(0, length: 200)
        }
        return SDImageCache.shared.diskCachePath + "/" + key + ".mp4"
    }
}

extension VideoMediaViewController {
    @objc func displayLinkDidUpdate(displaylink: CADisplayLink) {
        if isYoutubeView {
            if youtubeMute && muteButton.isHidden && SettingValues.muteYouTube {
                muteButton.isHidden = false
            }
            if !sliderBeingUsed {
                youtubeView.getCurrentTime { [weak self] (currentTime: Float, error: Error?) in
                    if error == nil {
                        self?.scrubber.updateWithTime(elapsedTime: CMTime(seconds: Double(currentTime), preferredTimescale: 1000))
                    }
                }
            }
        }

        let hasAudioTracks = isYoutubeView || (videoView.player?.currentItem?.tracks.count ?? 1) > 1
        
        if hasAudioTracks {
            if (videoView.player?.isMuted ?? youtubeMute) && muteButton.isHidden && (isYoutubeView ? SettingValues.muteYouTube : SettingValues.muteVideosInModal) {
                muteButton.isHidden = false
            }
        }

        if !setOnce || lastTracks != hasAudioTracks {
            setOnce = true
            lastTracks = hasAudioTracks
            
            if hasAudioTracks {
                if isYoutubeView ? !SettingValues.muteYouTube : !SettingValues.muteVideosInModal {
                    youtubeMute = false
                    if SettingValues.modalVideosRespectHardwareMuteSwitch {
                        try? AVAudioSession.sharedInstance().setCategory(.soloAmbient, options: [])
                    } else {
                        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [])
                    }
                } else {
                    youtubeMute = true
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
        
        guard let player = videoView.player else {
            return
        }

        if !sliderBeingUsed {
            scrubber.updateWithTime(elapsedTime: player.currentTime())
            if let pDuration = player.currentItem?.duration {
                let duration = Float(CMTimeGetSeconds(pDuration))
                let time = Float(CMTimeGetSeconds(player.currentTime()))
                if !handlingPlayerItemDidreachEnd && ((time / duration) >= 0.999 || ((time / duration) >= 0.94 && lastTime == time)) {
                    handlingPlayerItemDidreachEnd = true
                    self.playerItemDidreachEnd()
                }
                lastTime = time
            }
        }
    }
}

extension VideoMediaViewController: WKYTPlayerViewDelegate {
    
    func playerViewDidBecomeReady(_ playerView: WKYTPlayerView) {
        playerView.getDuration { [weak self] (duration: TimeInterval, error: Error?) in
            if error == nil {
                self?.scrubber.totalDuration = CMTime(seconds: duration, preferredTimescale: 1000)
            }
        }
        DispatchQueue.global(qos: .background).async {
            do {
                if !SettingValues.muteYouTube {
                    if SettingValues.modalVideosRespectHardwareMuteSwitch {
                        try? AVAudioSession.sharedInstance().setCategory(.soloAmbient, options: [])
                    } else {
                        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [])
                    }
                }

                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError {
                print(error)
            }
        }
        
        self.setProgressViewVisible(false)
        //        self.downloadButton.isHidden = true// TODO: - maybe download videos in the future?
        if isYoutubeView && SettingValues.muteYouTube {
            // TODO: - An error is thrown when this is evaluated. Resolve why to allow error handling
            playerView.webView?.evaluateJavaScript("player.mute()", completionHandler: { [weak self] (_, _) in
                if let strongSelf = self {
                    strongSelf.youtubeMute = true
                }
            })
        }
        
        self.loaded = true
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidUpdate))
        displayLink?.add(to: .current, forMode: RunLoop.Mode.default)
        displayLink?.isPaused = false
        
        youtubeView.playVideo()
        hideSpinner()
    }
    
    func playerView(_ playerView: WKYTPlayerView, didPlayTime playTime: Float) {
//        if !sliderBeingUsed {
//            self.scrubber.updateWithTime(elapsedTime: CMTime(seconds: Double(playTime), preferredTimescale: 1000))
//        }
    }

    func playerView(_ playerView: WKYTPlayerView, didChangeTo state: WKYTPlayerState) {
        switch state {
        case .buffering:
            break
        case .ended:
            // "Seek" scrubber to end (scrubber doesn't get all the way there)
//            self.scrubber.updateWithTime(elapsedTime: scrubber.totalDuration)
            scrubber.setPlayButton()
        case .paused:
            scrubber.setPlayButton()
        case .playing:
            displayLink?.isPaused = false
            self.startTimerToHide(1)
            scrubber.setPauseButton()
        case .queued:
            break
        case .unstarted:
            break
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    func playerView(_ playerView: WKYTPlayerView, didChangeTo quality: WKYTPlaybackQuality) {

    }

    func playerView(_ playerView: WKYTPlayerView, receivedError error: WKYTPlayerError) {
        switch error {
        case .html5Error:
            break
        case .invalidParam:
            break
        case .notEmbeddable:
            // TODO: - Redirect user to YouTube app or web view
            print("Video is not embeddable!")
        case .videoNotFound:
            break
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    func playerViewPreferredWebViewBackgroundColor(_ playerView: WKYTPlayerView) -> UIColor {
        return .clear
    }

//    func playerViewPreferredInitialLoading(_ playerView: YTPlayerView) -> UIView? {
//
//    }

}

extension VideoMediaViewController {
    func getLastPathSegment(_ path: String) -> String {
        var inv = path
        if inv.endsWith("/") {
            inv = inv.substring(0, length: inv.length - 1)
        }
        let slashindex = inv.lastIndexOf("/")!
        print("Index is \(slashindex)")
        inv = inv.substring(slashindex + 1, length: inv.length - slashindex - 1)
        return inv
    }

    func getTimeFromString(_ time: String) -> Int {
        var timeAdd = 0
        for s in time.components(separatedBy: CharacterSet(charactersIn: "hms")) {
            print(s)
            if !s.isEmpty {
                if time.contains(s + "s") {
                    timeAdd += Int(s)!
                } else if time.contains(s + "m") {
                    timeAdd += 60 * Int(s)!
                } else if time.contains(s + "h") {
                    timeAdd += 3600 * Int(s)!
                }
            }
        }
        if timeAdd == 0 && Int(time) != nil {
            timeAdd += Int(time)!
        }

        return timeAdd

    }
    @objc func showTitle(_ sender: AnyObject) {
        let alert = AlertController.init(title: "Caption", message: nil, preferredStyle: .alert)
        
        alert.setupTheme()
        alert.attributedTitle = NSAttributedString(string: "Caption", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        alert.attributedMessage = TextDisplayStackView.createAttributedChunk(baseHTML: data.text!.trimmed(), fontSize: 14, submission: false, accentColor: ColorUtil.baseAccent, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
        
        alert.addCloseButton()
        alert.addBlurView()
        present(alert, animated: true, completion: nil)
    }
    
    @objc func showContextMenu(_ sender: UIButton) {
        guard let baseURL = self.data.baseURL else {
            return
        }
        let alertController = DragDownAlertMenu(title: "Video options", subtitle: baseURL.absoluteString, icon: nil)
        
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alertController.addAction(title: "Open in Chrome", icon: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) {
                open.openInChrome(baseURL, callbackURL: nil, createNewTab: true)
            }
        }
        
        alertController.addAction(title: "Open in default app", icon: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) {
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
        
        if !isYoutubeView {
            alertController.addAction(title: "Share Video", icon: UIImage(sfString: SFSymbol.playFill, overrideString: "play")!.menuIcon()) {
                self.shareVideo(baseURL, sender: sender)
            }
        }
        
        if let topController = UIApplication.topViewController(base: self) {
            alertController.show(topController)
        } else {
            alertController.show(self)
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

    @objc func downloadVideoToLibrary(_ sender: AnyObject) {
        CustomAlbum.shared.saveMovieToLibrary(movieURL: URL(fileURLWithPath: getKeyFromURL()), parent: self)
    }
    
    @objc func openInYoutube(_ sender: AnyObject) {
        if let url = youtubeURL {
            UIApplication.shared.openURL(url)
        }
    }
}

extension VideoMediaViewController: VideoScrubberViewDelegate {
    func sliderValueChanged(toSeconds: Float) {
        self.handleShowUI()
//        self.videoView.player?.pause()

        let targetTime = CMTime(seconds: Double(toSeconds), preferredTimescale: 1000)

        if isYoutubeView {
            self.youtubeView.seek(toSeconds: toSeconds, allowSeekAhead: true) // Disable seekahead until the user lets go
        } else {
            let tolerance: CMTime = CMTimeMakeWithSeconds(0.001, preferredTimescale: 1000) // 1 ms with a resolution of 1 ms
            self.videoView.player?.seek(to: targetTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }

    func sliderDidBeginDragging() {
        if isYoutubeView {
            youtubeView.getPlayerState { [weak self] (state: WKYTPlayerState, error: Error?) in
                if error == nil {
                    if let strongSelf = self {
                        strongSelf.wasPlayingWhenPaused = state == .playing
                        strongSelf.youtubeView.pauseVideo()
                    }
                }
            }
        } else {
            if let player = videoView.player {
                wasPlayingWhenPaused = player.rate != 0
                player.pause()
            }
        }
        sliderBeingUsed = true
    }

    func sliderDidEndDragging() {
        // Start playing the video again if it was playing when the slider started being dragged
        if wasPlayingWhenPaused {
            if isYoutubeView {
                youtubeView.playVideo()
            } else {
                self.videoView.player?.play()
            }
        }
        self.startTimerToHide(1)
        sliderBeingUsed = false
    }
    
    func togglePlaying() {
        self.handleShowUI()
        if let player = videoView.player {
            if player.rate != 0 {
                player.pause()
            } else {
                player.play()
            }
        }

        if isYoutubeView {
            youtubeView.getPlayerState { [weak self] (state: WKYTPlayerState, error: Error?) in
                if error == nil {
                    if state == .playing {
                        self?.youtubeView.pauseVideo()
                    } else {
                        self?.youtubeView.playVideo()
                    }
                }
            }
        }
    }
    
    //From https://stackoverflow.com/a/39100999/3697225
    func mergeFilesWithUrl(videoUrl: URL, audioUrl: URL, savePathUrl: URL, completion: @escaping () -> Void) {
        let mixComposition: AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack: [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack: [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        print("Loading from " + videoUrl.absoluteString)
        //start merge
        let aVideoAsset: AVAsset = AVAsset(url: videoUrl)
        let aAudioAsset: AVAsset = AVAsset(url: audioUrl)
        
        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        
        let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        do {
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: CMTime.zero)
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)
            
            //Use this instead above line if your audiofile and video file's playing durations are same
            //            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), ofTrack: aAudioAssetTrack, atTime: kCMTimeZero)
        } catch {
            print(error.localizedDescription)
        }
        
        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration)
        
        let mutableVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        mutableVideoComposition.renderSize = aVideoAssetTrack.naturalSize
        
        //        playerItem = AVPlayerItem(asset: mixComposition)
        //        player = AVPlayer(playerItem: playerItem!)
        //
        //
        //        AVPlayerVC.player = player
        do {
            try  FileManager.default.removeItem(at: savePathUrl)
        } catch {
            print(error.localizedDescription)
        }
        
        //find your video on this URl
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePathUrl
        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
                
            case AVAssetExportSession.Status.completed:
                completion()
                print("success")
            case AVAssetExportSession.Status.failed:
                print("failed \(assetExport.error?.localizedDescription ?? "")")
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(assetExport.error?.localizedDescription ?? "")")
            default:
                print("complete")
            }
        }
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
