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
import SDWebImage
import SubtleVolume
import Then
import UIKit
import XLActionController

class VideoMediaViewController: EmbeddableMediaViewController, UIGestureRecognizerDelegate, SubtleVolumeDelegate {

    var isYoutubeView: Bool {
        return contentType == ContentType.CType.VIDEO
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
        if !self.muteButton.isHidden {
            self.unmute()
        }
    }
    
    var youtubeResolution = CGSize(width: 16, height: 9)
    var videoView = VideoView()
    var youtubeView = YTPlayerView()
    var downloadedOnce = false
    
    var size = UILabel()
    var videoType: VideoType!
    
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

        loadContent()
        handleHideUI()
        
        volume.barTintColor = .white
        volume.barBackgroundColor = UIColor.white.withAlphaComponent(0.3)
        volume.animation = .slideDown
        view.addSubview(volume)
        volume.delegate = self

        if !((parent?.parent) is ShadowboxLinkViewController) {
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
        if loaded {
            displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidUpdate))
            displayLink?.add(to: .current, forMode: RunLoop.Mode.default)
            displayLink?.isPaused = false
            videoView.player?.play()
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
    }
    
    func endVideos() {
        self.displayLink?.invalidate()
        self.displayLink = nil
        self.videoView.player?.replaceCurrentItem(with: nil)
        self.videoView.player = nil
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(false, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch {
            NSLog(error.localizedDescription)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Recalculate youtube frame size
        self.youtubeView.frame = AVMakeRect(aspectRatio: youtubeResolution, insideRect: self.view.bounds)

        // Recalculate player size
        var size = videoView.player?.currentItem?.presentationSize ?? self.view.bounds.size
        if size == CGSize.zero {
            size = self.view.bounds.size
        }

        self.videoView.frame = AVMakeRect(aspectRatio: size, insideRect: self.view.bounds) // CALayer position contains NaN: [nan nan]
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

        rewindImageView = UIImageView(image: UIImage(named: "rewind")?.getCopy(withSize: .square(size: 40), withColor: .white)).then {
            $0.alpha = 0
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            $0.layer.cornerRadius = 20
            $0.clipsToBounds = true
        }
        view.addSubview(rewindImageView)

        fastForwardImageView = UIImageView(image: UIImage(named: "fast_forward")?.getCopy(withSize: .square(size: 40), withColor: .white)).then {
            $0.alpha = 0
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            $0.layer.cornerRadius = 20
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
            $0.setImage(UIImage(named: "download")?.navIcon(true), for: [])
            $0.isHidden = true // The button will be unhidden once the content has loaded.
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }

        muteButton = UIButton().then {
            $0.accessibilityIdentifier = "Un-mute video"
            $0.setImage(UIImage(named: "mute")?.navIcon(true), for: [])
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
            $0.setImage(UIImage(named: "comments")?.navIcon(true), for: [])
            $0.isHidden = commentCallback == nil
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
                
        showTitleButton = UIButton().then {
            $0.accessibilityIdentifier = "Show Title Button"
            $0.setImage(UIImage(named: "size")?.navIcon(true), for: [])
            $0.isHidden = !(data.text != nil && !(data.text!.isEmpty))
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        
        size = UILabel().then {
            $0.accessibilityIdentifier = "File size"
            $0.font = UIFont.boldSystemFont(ofSize: 12)
            $0.textAlignment = .center
            $0.textColor = .white
        }

        bottomButtons.addArrangedSubviews(showTitleButton, goToCommentsButton, size, UIView.flexSpace(), ytButton, muteButton, downloadButton, menuButton)
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
        self.videoView.player?.isMuted = false

        if SettingValues.modalVideosRespectHardwareMuteSwitch {
            try? AVAudioSession.sharedInstance().setCategory(.soloAmbient, options: [])
        } else {
            try? AVAudioSession.sharedInstance().setCategory(.playback, options: [])
        }

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
    
    @objc func handleHideUI() {
        if !self.scrubber.isHidden {
            if let parent = parent as? ModalMediaViewController {
                parent.fullscreen(self)
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
    
    var spinnerIndicator = UIActivityIndicatorView()
    
    func loadContent() {

        //Prevent video from stopping system background audio
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print(error)
        }

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
        let url = formatUrl(sS: data.baseURL!.absoluteString, SettingValues.shouldAutoPlay())
        videoType = VideoType.fromPath(url)
        
        if videoType != .DIRECT && videoType != .REDDIT && videoType != .IMGUR {
            showSpinner()
        }

        videoType.getSourceObject().load(url: url, completion: { [weak self] (urlString) in
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
    
    func getVideo(_ toLoad: String) {
        self.hideSpinner()

        if FileManager.default.fileExists(atPath: getKeyFromURL()) || SettingValues.shouldAutoPlay() {
            playVideo(toLoad)
        } else {
            request = Alamofire.download(toLoad, method: .get, to: { (_, _) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                return (URL(fileURLWithPath: self.videoType == .REDDIT ? self.getKeyFromURL().replacingOccurrences(of: ".mp4", with: "video.mp4") : self.getKeyFromURL()), [.createIntermediateDirectories])
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
                    switch response.result {
                    case .failure(let error):
                        print(error)
                        self.parent?.dismiss(animated: true, completion: {
                            self.failureCallback?(URL.init(string: toLoad)!)
                        })
                    case .success:
                        if self.videoType == .REDDIT {
                            self.downloadRedditAudio()
                        } else {
                            DispatchQueue.main.async {
                                self.playVideo()
                            }
                        }
                    }
            }
        }
    }
    
    func downloadRedditAudio() {
        let key = getKeyFromURL()
        var toLoadAudio = self.data.baseURL!.absoluteString
        toLoadAudio = toLoadAudio.substring(0, length: toLoadAudio.lastIndexOf("/DASH_") ?? toLoadAudio.length)
        toLoadAudio += "/audio"
        let finalUrl = URL.init(fileURLWithPath: key)
        let localUrlV = URL.init(fileURLWithPath: key.replacingOccurrences(of: ".mp4", with: "video.mp4"))
        let localUrlAudio = URL.init(fileURLWithPath: key.replacingOccurrences(of: ".mp4", with: "audio.mp4"))

        self.request = Alamofire.download(toLoadAudio, method: .get, to: { (_, _) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
            return (localUrlAudio, [.removePreviousFile, .createIntermediateDirectories])
        }).downloadProgress() { progress in
            DispatchQueue.main.async {
                self.updateProgress(CGFloat(progress.fractionCompleted), "")
            }
            }
            .responseData { response2 in
                if (response2.error as NSError?)?.code == NSURLErrorCancelled {
                    return
                }
                if response2.response!.statusCode != 200 {
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
                } else { //no errors
                    self.mergeFilesWithUrl(videoUrl: localUrlV, audioUrl: localUrlAudio, savePathUrl: finalUrl) {
                        DispatchQueue.main.async {
                            self.playVideo()
                        }
                    }
                }
        }
    }

    func playVideo(_ url: String = "") {
        self.setProgressViewVisible(false)
        self.size.isHidden = true
//        self.downloadButton.isHidden = true //todo maybe download videos in the future?
        let playerItem = AVPlayerItem(url: SettingValues.shouldAutoPlay() ? URL(string: url)! : URL(fileURLWithPath: getKeyFromURL()))
        videoView.player = AVPlayer(playerItem: playerItem)
        videoView.player?.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        self.videoView.player?.isMuted = SettingValues.muteVideosInModal
        videoView.player?.play()
        
        scrubber.totalDuration = videoView.player!.currentItem!.asset.duration
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
        if s.contains("v.redd.it") && !s.contains("DASH") {
            if s.endsWith("/") {
                s = s.substring(0, length: s.length - 2)
            }
            s += "/DASH_9_6_M"
        }
        if hls {
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
                s += "/HLSPlaylist.m3u8"
            }
        }
        return s
    }
    
    func formatUrl(sS: String, _ vreddit: Bool = false) -> String {
        return VideoMediaViewController.format(sS: sS, SettingValues.shouldAutoPlay())
    }

    public enum VideoType {
        case DIRECT
        case IMGUR
        case VID_ME
        case STREAMABLE
        case GFYCAT
        case REDDIT
        case OTHER

        static func fromPath(_ url: String) -> VideoType {
            if url.contains(".mp4") || url.contains("webm") || url.contains("redditmedia.com") {
                return VideoType.DIRECT
            }
            if url.contains("gfycat") && !url.contains("mp4") {
                return VideoType.GFYCAT
            }
            if url.contains("v.redd.it") {
                return VideoType.REDDIT
            }
            if url.contains("imgur.com") {
                return VideoType.IMGUR
            }
            if url.contains("vid.me") {
                return VideoType.VID_ME
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
            case .VID_ME:
                return VidMeVideoSource()
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
            youtubeView.seek(toSeconds: newTime, allowSeekAhead: true)
            youtubeView.playVideo()
        } else {
            let tolerance: CMTime = CMTimeMakeWithSeconds(0.001, preferredTimescale: 1000) // 1 ms with a resolution of 1 ms
            let newCMTime = CMTimeMakeWithSeconds(Float64(newTime), preferredTimescale: 1000)
            self.videoView.player?.seek(to: newCMTime, toleranceBefore: tolerance, toleranceAfter: tolerance) { _ in
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
                let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary,
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
        var key = self.data.baseURL!.absoluteString.components(separatedBy: disallowedChars).joined(separator: "_")
        key = key.replacingOccurrences(of: ":", with: "")
        key = key.replacingOccurrences(of: "/", with: "")
        key = key.replacingOccurrences(of: ".gifv", with: ".mp4")
        key = key.replacingOccurrences(of: ".gif", with: ".mp4")
        key = key.replacingOccurrences(of: ".", with: "")
        if key.length > 200 {
            key = key.substring(0, length: 200)
        }
        
        return (SDImageCache.shared().makeDiskCachePath(key) ?? "") + ".mp4"
    }
}

extension VideoMediaViewController {
    @objc func displayLinkDidUpdate(displaylink: CADisplayLink) {
        if isYoutubeView {
            if !sliderBeingUsed {
                self.scrubber.updateWithTime(elapsedTime: CMTime(seconds: Double(youtubeView.currentTime()), preferredTimescale: 1000))
            }
        }

        guard let player = videoView.player else {
            return
        }
        let hasAudioTracks = (player.currentItem?.tracks.count ?? 1) > 1

        if hasAudioTracks {
            if player.isMuted && muteButton.isHidden && SettingValues.muteVideosInModal {
                muteButton.isHidden = false
            }
        }

        if !setOnce {
            setOnce = true

            if hasAudioTracks {
                if !SettingValues.muteVideosInModal {
                    if SettingValues.modalVideosRespectHardwareMuteSwitch {
                        try? AVAudioSession.sharedInstance().setCategory(.soloAmbient, options: [])
                    } else {
                        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [])
                    }
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
            self.loaded = true
        }

        if !sliderBeingUsed {
            scrubber.updateWithTime(elapsedTime: player.currentTime())
            let duration = Float(CMTimeGetSeconds(player.currentItem!.duration))
            let time = Float(CMTimeGetSeconds(player.currentTime()))
            if !handlingPlayerItemDidreachEnd && (time / duration) >= 0.99 {
                handlingPlayerItemDidreachEnd = true
                self.playerItemDidreachEnd()
            }
        }
    }

}

extension VideoMediaViewController: YTPlayerViewDelegate {
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        youtubeView.playVideo()
        scrubber.totalDuration = CMTime(seconds: playerView.duration(), preferredTimescale: 1000)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            NSLog(error.localizedDescription)
        }
        hideSpinner()
    }
    
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
//        if !sliderBeingUsed {
//            self.scrubber.updateWithTime(elapsedTime: CMTime(seconds: Double(playTime), preferredTimescale: 1000))
//        }
    }

    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        switch state {
        case .buffering:
            break
        case .ended:
            // "Seek" scrubber to end (scrubber doesn't get all the way there)
//            self.scrubber.updateWithTime(elapsedTime: scrubber.totalDuration)
            scrubber.setPlayButton()
        case .paused:
            break
        case .playing:
            break
        case .queued:
            break
        case .unstarted:
            break
        case .unknown:
            break
        }
    }

    func playerView(_ playerView: YTPlayerView, didChangeTo quality: YTPlaybackQuality) {

    }

    func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
        switch error {
        case .html5Error:
            break
        case .invalidParam:
            break
        case .notEmbeddable:
            // TODO: Redirect user to YouTube app or web view
            print("Video is not embeddable!")
        case .videoNotFound:
            break
        case .unknown:
            break
        }
    }

    func playerViewPreferredWebViewBackgroundColor(_ playerView: YTPlayerView) -> UIColor {
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
        let alertController = UIAlertController(title: "Caption", message: nil, preferredStyle: .alert)
        alertController.addTextViewer(text: .text(data.text!))
        alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func showContextMenu(_ sender: UIButton) {
        guard let baseURL = self.data.baseURL else {
            return
        }
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = baseURL.absoluteString
        
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alertController.addAction(Action(ActionData(title: "Open in Chrome", image: UIImage(named: "nav")!.menuIcon()), style: .default, handler: { _ in
                open.openInChrome(baseURL, callbackURL: nil, createNewTab: true)
            }))
        }
        alertController.addAction(Action(ActionData(title: "Open in Safari", image: UIImage(named: "nav")!.menuIcon()), style: .default, handler: { _ in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(baseURL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(baseURL)
            }
        }))
        alertController.addAction(Action(ActionData(title: "Share URL", image: UIImage(named: "reply")!.menuIcon()), style: .default, handler: { _ in
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
        }))
        
        //todo share video
        
        let window = UIApplication.shared.keyWindow!
        
        if let modalVC = window.rootViewController?.presentedViewController {
            modalVC.present(alertController, animated: true, completion: nil)
        } else {
            window.rootViewController!.present(alertController, animated: true, completion: nil)
        }
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
            self.videoView.player?.seek(to: targetTime, toleranceBefore: tolerance, toleranceAfter: tolerance)
        }
    }

    func sliderDidBeginDragging() {
        if isYoutubeView {
            wasPlayingWhenPaused = youtubeView.playerState() == .playing
            youtubeView.pauseVideo()
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

        if isYoutubeView {
            if youtubeView.playerState() == .playing {
                youtubeView.pauseVideo()
                return false
            } else {
                youtubeView.playVideo()
                self.startTimerToHide()
                return true
            }
        }
        return false
    }
    
    //From https://stackoverflow.com/a/39100999/3697225
    func mergeFilesWithUrl(videoUrl: URL, audioUrl: URL, savePathUrl: URL, completion: @escaping () -> Void) {
        let mixComposition: AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack: [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack: [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
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
