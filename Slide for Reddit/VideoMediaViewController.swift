//
//  VideoMediaViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Alamofire
import Anchorage
import SDWebImage
import Then
import UIKit

import AVFoundation

class VideoMediaViewController: EmbeddableMediaViewController {

    var isYoutubeView: Bool {
        return contentType == ContentType.CType.VIDEO
    }

    var videoView = VideoView()
    var youtubeView = YTPlayerView()
    var downloadedOnce = false
    
    var size = UILabel()
    var videoType: VideoType!
    
    var menuButton = UIButton()
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

    var youtubeHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Disable screen dimming due to inactivity
        UIApplication.shared.isIdleTimerDisabled = true

        configureViews()
        configureLayout()
        connectActions()

        loadContent()
        handleHideUI()
    }

    func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidUpdate))
        displayLink?.add(to: .current, forMode: .defaultRunLoopMode)
        displayLink?.isPaused = false
        videoView.player?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
        request?.cancel()
        stopDisplayLink()
        videoView.player?.pause()
        super.viewWillDisappear(animated)
    }

    deinit {
        stopDisplayLink()
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Re-enable screen dimming due to inactivity
        UIApplication.shared.isIdleTimerDisabled = false
        displayLink?.isPaused = true

        // Turn off forced fullscreen
        if forcedFullscreen {
            disableForcedFullscreen()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        youtubeView.heightAnchor == size.height //Fullscreen landscape
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

        bottomButtons = UIStackView().then {
            $0.accessibilityIdentifier = "Bottom Buttons"
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 8
        }
        view.addSubview(bottomButtons)
        
        menuButton = UIButton().then {
            $0.accessibilityIdentifier = "More Button"
            $0.setImage(UIImage(named: "moreh")?.navIcon(), for: [])
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        
        downloadButton = UIButton().then {
            $0.accessibilityIdentifier = "Download Button"
            $0.setImage(UIImage(named: "download")?.navIcon(), for: [])
            $0.isHidden = true // The button will be unhidden once the content has loaded.
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        
        ytButton = UIButton().then {
            $0.accessibilityIdentifier = "Open in YouTube"
            $0.setImage(UIImage(named: "youtube")?.navIcon(), for: [])
            $0.isHidden = true // The button will be unhidden once the content has loaded.
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        
        goToCommentsButton = UIButton().then {
            $0.accessibilityIdentifier = "Go to Comments Button"
            $0.setImage(UIImage(named: "comments")?.navIcon(), for: [])
            $0.isHidden = commentCallback == nil
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
                
        showTitleButton = UIButton().then {
            $0.accessibilityIdentifier = "Show Title Button"
            $0.setImage(UIImage(named: "size")?.navIcon(), for: [])
            $0.isHidden = !(data.text != nil && !(data.text!.isEmpty))
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        
        size = UILabel().then {
            $0.accessibilityIdentifier = "File size"
            $0.font = UIFont.boldSystemFont(ofSize: 12)
            $0.textAlignment = .center
            $0.textColor = .white
        }

        bottomButtons.addArrangedSubviews(showTitleButton, goToCommentsButton, size, UIView.flexSpace(), ytButton, downloadButton, menuButton)
    }
    
    func connectActions() {
        menuButton.addTarget(self, action: #selector(showContextMenu(_:)), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(downloadVideoToLibrary(_:)), for: .touchUpInside)
        goToCommentsButton.addTarget(self, action: #selector(openComments(_:)), for: .touchUpInside)
        showTitleButton.addTarget(self, action: #selector(showTitle(_:)), for: .touchUpInside)
        ytButton.addTarget(self, action: #selector(openInYoutube(_:)), for: .touchUpInside)

        dTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        dTap?.numberOfTapsRequired = 2
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
        videoView.edgeAnchors == view.edgeAnchors

        youtubeView.centerYAnchor == view.centerYAnchor
        youtubeView.leadingAnchor == view.safeLeadingAnchor
        youtubeView.trailingAnchor == view.safeTrailingAnchor

        bottomButtons.horizontalAnchors == view.safeHorizontalAnchors + CGFloat(8)
        bottomButtons.bottomAnchor == view.safeBottomAnchor - CGFloat(8)

        scrubber.horizontalAnchors == view.safeHorizontalAnchors + 8
        scrubber.bottomAnchor == bottomButtons.topAnchor - 16

    }
    
    func handleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.ended {
            if scrubber.alpha == 0 {
                self.handleShowUI()
                self.startTimerToHide()
            } else {
                self.handleHideUI()
            }
        }
    }
    
    func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.ended {
            let x = sender.location(in: self.view).x
            if x > UIScreen.main.bounds.size.width / 2 {
                //skip forward
                if isYoutubeView {
                    let playerCurrentTime = scrubber.slider.value
                    let maxTime = scrubber.slider.maximumValue
                    
                    let newTime = playerCurrentTime + 10
                    
                    if newTime < maxTime {
                        youtubeView.seek(toSeconds: newTime, allowSeekAhead: true)
                    } else {
                        youtubeView.seek(toSeconds: 0, allowSeekAhead: true)
                    }
                    youtubeView.playVideo()
                } else {
                    if let player = self.videoView.player {
                        let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
                        let maxTime = CMTimeGetSeconds(player.currentItem!.duration)
                        
                        let newTime = playerCurrentTime + (maxTime / 5)
                        
                        if newTime < maxTime {
                            let time2: CMTime = CMTimeMake(Int64(newTime * 1000 as Float64), 1000)
                            player.seek(to: time2)
                        } else {
                            player.seek(to: kCMTimeZero)
                        }
                        player.play()
                    }
                }
            } else {
                //skip back
                if isYoutubeView {
                    let playerCurrentTime = scrubber.slider.value
                    
                    let newTime = playerCurrentTime - 5
                    
                    if newTime > 0 {
                        youtubeView.seek(toSeconds: newTime, allowSeekAhead: true)
                    } else {
                        youtubeView.seek(toSeconds: 0, allowSeekAhead: true)
                    }
                    youtubeView.playVideo()
                } else {
                    if let player = self.videoView.player {
                        let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
                        let maxTime = CMTimeGetSeconds(player.currentItem!.duration)
                        
                        let newTime = playerCurrentTime - (maxTime / 7)
                        
                        if newTime > 0 {
                            let time2: CMTime = CMTimeMake(Int64(newTime * 1000 as Float64), 1000)
                            player.seek(to: time2)
                        } else {
                            player.seek(to: kCMTimeZero)
                        }
                        player.play()
                    }
                }
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
    
    func handleHideUI() {
        if !self.scrubber.isHidden {
            if parent is ModalMediaViewController {
                (parent as! ModalMediaViewController).fullscreen(self)
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
            if parent is ModalMediaViewController {
                (parent as! ModalMediaViewController).unFullscreen(self)
            }
            self.scrubber.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.scrubber.alpha = 1
            })
        }
    }

    // TODO: Also fade background to black?
    func toggleForcedLandscapeFullscreen(_ sender: UILongPressGestureRecognizer) {
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

        // Prevent video from stopping system background audio
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        } catch let error as NSError {
            print(error)
        }

        do {
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
        let url = formatUrl(sS: data.baseURL!.absoluteString)
        videoType = VideoType.fromPath(url)
        
        if videoType != .DIRECT && videoType != .REDDIT && videoType != .IMGUR {
            showSpinner()
        }

        videoType.getSourceObject().load(url: url) { [weak self] (urlString) in
            self?.getVideo(urlString)
        }
    }
    
    func showSpinner() {
        spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
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

        if FileManager.default.fileExists(atPath: getKeyFromURL()) {
            playVideo()
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
    weak var observer: NSObjectProtocol?
    func playVideo() {
        self.setProgressViewVisible(false)
        self.size.isHidden = true
        self.downloadButton.isHidden = false
        let playerItem = AVPlayerItem(url: URL(fileURLWithPath: getKeyFromURL()))
        videoView.player = AVPlayer(playerItem: playerItem)
        videoView.player?.play()
        
        scrubber.totalDuration = videoView.player!.currentItem!.asset.duration

        observer = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: OperationQueue.main) { [weak self] (_) in
            self?.playerItemDidreachEnd()
        }
    }
    
    func playerItemDidreachEnd() {
        self.videoView.player!.seek(to: kCMTimeZero)
        self.videoView.player!.play()
    }
    
    func formatUrl(sS: String) -> String {
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
        return s
    }

    enum VideoType {
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
                //we should never get here
                fatalError("Video type unrecognized and unimplemented!")
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
        if url.contains("#t=") {
            url = url.replacingOccurrences(of: "#t=", with: url.contains("?") ? "&t=" : "?t=")
        }

        let i = URL(string: url)
        if let dictionary = i?.queryDictionary {
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
                let param = u
                video = param.substring(param.indexOf("=")! + 1, length: param.contains("&") ? param.indexOf("&")! : param.length)
            }
        }
        
        if video.contains("?") {
            video = video.substring(0, length: video.indexOf("?")!)
        }

        getRemoteAspectRatio(videoId: video) { [weak self] (aspect) in
            guard let strongSelf = self else {
                return
            }
            
            print("Aspect is \(aspect)")
            strongSelf.youtubeHeightConstraint = strongSelf.youtubeView.heightAnchor == strongSelf.youtubeView.widthAnchor * aspect
            let vars = [
                "controls": 0, // Disable controls
                "playsinline": 1,
                "start": seconds,
                "fs": 0, // Turn off fullscreen button
                "rel": 0, // Turn off suggested content at end
                "showinfo": 0, // Hide video title uploader
                "loop": 1,
                "modestbranding": 1, // Remove youtube logo on bottom right
                "autohide": 1,
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

    func getRemoteAspectRatio(videoId: String, completion: @escaping (CGFloat) -> Void) {
        let metaURL = URL(string: "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(videoId)&format=json")!

        print(metaURL)
        func failureBlock() {
            OperationQueue.main.addOperation({
                completion(CGFloat(9 / 16))
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
                print("Is \(CGFloat(height / width)) with \(height) and \(width)")
                completion(CGFloat(height / width))
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
        
        return SDImageCache.shared().makeDiskCachePath(key) + ".mp4"
    }
}

/*extension VideoMediaViewController: CachingPlayerItemDelegate {

    func playerItemReadyToPlay(_ playerItem: CachingPlayerItem) {
        print("Player ready to play")
        videoView.player?.play()
        
        // Hook up the scrubber to the player
        scrubber.totalDuration = videoView.player!.currentItem!.asset.duration
    }

    func displayLinkDidUpdate(displaylink: CADisplayLink) {
        if let player = videoView.player {
            if !sliderBeingUsed {
                scrubber.updateWithTime(elapsedTime: player.currentTime())
            }
        }
    }
    
    
    func didReachEnd(_ playerItem: CachingPlayerItem) {
        self.videoView.player!.seek(to: kCMTimeZero)
        self.videoView.player!.play()
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        print("File is downloaded and ready for storing")
        DispatchQueue.main.async {
            self.progressView.alpha = 0
            self.size.alpha = 0
        }
        
        //@colejd we might use an already-created key value in the new delegate
        FileManager.default.createFile(atPath: getKeyFromURL(), contents: data, attributes: nil)
    }

    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
        DispatchQueue.main.async {
            self.progressView.progress = Float(bytesDownloaded) / Float(bytesExpected)
            let countBytes = ByteCountFormatter()
            countBytes.allowedUnits = [.useMB]
            countBytes.countStyle = .file
            let fileSizeString = countBytes.string(fromByteCount: Int64(bytesExpected))
            self.size.text = fileSizeString
        }
    }

    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
        print("Not enough data for playback. Probably because of the poor network. Wait a bit and try to play later.")
    }

    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
        print(error)
    }
    
}*/

extension VideoMediaViewController {
    
    func displayLinkDidUpdate(displaylink: CADisplayLink) {
        if !sliderBeingUsed {
            if isYoutubeView {
                if !sliderBeingUsed {
                    self.scrubber.updateWithTime(elapsedTime: CMTime(seconds: Double(youtubeView.currentTime()), preferredTimescale: 1000000))
                }
            } else {
                if let player = videoView.player {
                    scrubber.updateWithTime(elapsedTime: player.currentTime())
                }
            }
        }
    }

}

extension VideoMediaViewController: YTPlayerViewDelegate {
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        youtubeView.playVideo()
        scrubber.totalDuration = CMTime(seconds: playerView.duration(), preferredTimescale: 1000000)
        
        hideSpinner()
    }
    
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
//        if !sliderBeingUsed {
//            self.scrubber.updateWithTime(elapsedTime: CMTime(seconds: Double(playTime), preferredTimescale: 1000000))
//        }
    }

    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        if state == YTPlayerState.ended {
            // "Seek" scrubber to end (scrubber doesn't get all the way there)
//            self.scrubber.updateWithTime(elapsedTime: scrubber.totalDuration)
            scrubber.setPlayButton()
        }
    }

    func playerView(_ playerView: YTPlayerView, didChangeTo quality: YTPlaybackQuality) {

    }

    func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {

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
    func showTitle(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "Caption", message: nil, preferredStyle: .alert)
        alertController.addTextViewer(text: .text(data.text!))
        alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func showContextMenu(_ sender: UIButton) {
        guard let baseURL = self.data.baseURL else {
            return
        }
        let alert = UIAlertController(title: baseURL.absoluteString, message: "", preferredStyle: .actionSheet)
        let open = OpenInChromeController()
        if open.isChromeInstalled() {
            alert.addAction(
                UIAlertAction(title: "Open in Chrome", style: .default) { (_) in
                    open.openInChrome(baseURL, callbackURL: nil, createNewTab: true)
                }
            )
        }
        alert.addAction(
            UIAlertAction(title: "Open in Safari", style: .default) { (_) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(baseURL, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(baseURL)
                }
            }
        )
        alert.addAction(
            UIAlertAction(title: "Share URL", style: .default) { (_) in
                let shareItems: Array = [baseURL]
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                let window = UIApplication.shared.keyWindow!
                if let modalVC = window.rootViewController?.presentedViewController {
                    modalVC.present(activityViewController, animated: true, completion: nil)
                } else {
                    window.rootViewController!.present(activityViewController, animated: true, completion: nil)
                }
            }
        )
        alert.addAction(
            UIAlertAction(title: "Share Video", style: .default) { (_) in
                //TODO THIS
            }
        )
        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            }
        )
        let window = UIApplication.shared.keyWindow!
        alert.modalPresentationStyle = .popover
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        
        if let modalVC = window.rootViewController?.presentedViewController {
            modalVC.present(alert, animated: true, completion: nil)
        } else {
            window.rootViewController!.present(alert, animated: true, completion: nil)
        }
    }
    
    func downloadVideoToLibrary(_ sender: AnyObject) {
        CustomAlbum.shared.saveMovieToLibrary(movieURL: URL(fileURLWithPath: getKeyFromURL()), parent: self)
    }
    
    func openInYoutube(_ sender: AnyObject) {
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
            self.videoView.player?.seek(to: targetTime)
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
        
        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid))
        mutableCompositionAudioTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid))
        
        let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaTypeVideo)[0]
        let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaTypeAudio)[0]
        
        do {
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: kCMTimeZero)
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: kCMTimeZero)
            
            //Use this instead above line if your audiofile and video file's playing durations are same
            //            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), ofTrack: aAudioAssetTrack, atTime: kCMTimeZero)
        } catch {
            print(error.localizedDescription)
        }
        
        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration)
        
        let mutableVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        
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
        assetExport.outputFileType = AVFileTypeMPEG4
        assetExport.outputURL = savePathUrl
        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
                
            case AVAssetExportSessionStatus.completed:
                completion()
                print("success")
            case AVAssetExportSessionStatus.failed:
                print("failed \(assetExport.error?.localizedDescription ?? "")")
            case AVAssetExportSessionStatus.cancelled:
                print("cancelled \(assetExport.error?.localizedDescription ?? "")")
            default:
                print("complete")
            }
        }
    }
}
