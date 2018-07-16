//
//  VideoMediaViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/9/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import Anchorage
import Then
import Alamofire
import SDWebImage

import AVFoundation

class VideoMediaViewController: EmbeddableMediaViewController {

    var videoView = VideoView()
    var youtubeView = YTPlayerView()
    var downloadedOnce = false
    var observer: Any?
    
    var size = UILabel()
    var videoType: VideoType!
    
    var menuButton = UIButton()
    var downloadButton = UIButton()
    var request: DownloadRequest?

    var goToCommentsButton = UIButton()
    var showTitleButton = UIButton()

    var scrubber = VideoScrubberView()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let timeObserver = observer {
            videoView.player?.removeTimeObserver(timeObserver)
        }
        timer?.invalidate()
        request?.cancel()
        NotificationCenter.default.removeObserver(self)
        videoView.player?.pause()
    }

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

    override func viewDidDisappear(_ animated: Bool) {
        // Re-enable screen dimming due to inactivity
        UIApplication.shared.isIdleTimerDisabled = false
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

    func configureViews() {
        view.addSubview(videoView)

        youtubeView.delegate = self
        youtubeView.isHidden = true
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

        bottomButtons.addArrangedSubviews(showTitleButton, goToCommentsButton, size, UIView.flexSpace(), downloadButton, menuButton)
        
    }
    
    func connectActions() {
        menuButton.addTarget(self, action: #selector(showContextMenu(_:)), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(downloadImageToLibrary(_:)), for: .touchUpInside)
        goToCommentsButton.addTarget(self, action: #selector(openComments(_:)), for: .touchUpInside)
        showTitleButton.addTarget(self, action: #selector(showTitle(_:)), for: .touchUpInside)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(handleTap(_:)))
        self.view.addGestureRecognizer(tap)
    }

    
    func configureLayout() {
        videoView.edgeAnchors == view.edgeAnchors
        youtubeView.edgeAnchors == view.edgeAnchors
        bottomButtons.horizontalAnchors == view.safeHorizontalAnchors + CGFloat(8)
        bottomButtons.bottomAnchor == view.safeBottomAnchor - CGFloat(8)

        scrubber.horizontalAnchors == view.safeHorizontalAnchors
        scrubber.bottomAnchor == bottomButtons.topAnchor - 16

    }

    func makeControls(){
    }
    
    var tap: UITapGestureRecognizer?
    var timer: Timer?
    var cancelled = false
    
    func handleTap(_ sender: UITapGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.ended) {
            if(scrubber.alpha == 0){
                self.handleShowUI()
                self.startTimerToHide()
            } else {
                self.handleHideUI()
            }
        }
    }
    
    func startTimerToHide(){
        cancelled = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2,
                                     target: self,
                                     selector: #selector(self.handleHideUI),
                                     userInfo: nil,
                                     repeats: false)
    }
    
    func handleHideUI(){
        if(!self.scrubber.isHidden){
            UIView.animate(withDuration: 0.2, animations: {
                self.scrubber.alpha = 0
            }, completion: { (isDone) in
                self.scrubber.isHidden = true
            })
        }
    }
    
    func handleShowUI(){
        timer?.invalidate()
        if(self.scrubber.isHidden){
            self.scrubber.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.scrubber.alpha = 1
            })
        }
    }
    
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
        if contentType == ContentType.CType.VIDEO {
            youtubeView.isHidden = false
            loadYoutube(url: data.baseURL!.absoluteString)
            youtubeView.addTapGestureRecognizer {
                if(self.scrubber.alpha == 0){
                    self.handleShowUI()
                    self.startTimerToHide()
                } else {
                    self.handleHideUI()
                }
            }
            return
        } else {
            youtubeView.isHidden = true
        }

        // Otherwise load AVPlayer
        let url = formatUrl(sS: data.baseURL!.absoluteString)
        videoType = VideoType.fromPath(url)

        videoType.getSourceObject().load(url: url) { [weak self] (urlString) in
            self?.getVideo(urlString)
        }
    }
    
    func getVideo(_ toLoad: String) {
        if (FileManager.default.fileExists(atPath: getKeyFromURL())) {
            playVideo()
        } else {
            request = Alamofire.download(toLoad, method: .get, to: { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                return (URL(fileURLWithPath: self.getKeyFromURL()), [.createIntermediateDirectories])
                
            }).downloadProgress() { progress in
                DispatchQueue.main.async {
                    self.progressView.progress = Float(progress.fractionCompleted)
                    let countBytes = ByteCountFormatter()
                    countBytes.allowedUnits = [.useMB]
                    countBytes.countStyle = .file
                    let fileSize = countBytes.string(fromByteCount: Int64(progress.totalUnitCount))
                    self.size.text = fileSize
                }
                }.responseData { response in
                    if let error = response.error {
                        print(error)
                    } else { //no errors
                        DispatchQueue.main.async {
                            self.playVideo()
                        }
                        print("File downloaded successfully")
                    }
            }
        }
    }
    
    func playVideo(){
        self.progressView.alpha = 0
        self.progressView.progress = 1
        self.size.isHidden = true
        let playerItem = AVPlayerItem.init(url: URL(fileURLWithPath: getKeyFromURL()))
        videoView.player = AVPlayer(playerItem: playerItem)
        videoView.player?.play()
        
        scrubber.totalDuration = videoView.player!.currentItem!.asset.duration
        observer = self.videoView.player!.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self] (time) in
            self?.scrubber.updateWithTime(elapsedTime: time)
        }
        
        makeControls()
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidreachEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    func playerItemDidreachEnd(){
        self.videoView.player!.seek(to: kCMTimeZero)
    }
    
    func formatUrl(sS: String) -> String {
        var s = sS
        if (s.hasSuffix("v") && !s.contains("streamable.com")) {
            s = s.substring(0, length: s.length - 1);
        } else if (s.contains("gfycat") && (!s.contains("mp4") && !s.contains("webm"))) {
            if (s.contains("-size_restricted")) {
                s = s.replacingOccurrences(of: "-size_restricted", with: "")
            }
        }
        if ((s.contains(".webm") || s.contains(".gif")) && !s.contains(".gifv") && s.contains(
            "imgur.com")) {
            s = s.replacingOccurrences(of: ".gifv", with: ".mp4");
            s = s.replacingOccurrences(of: ".gif", with: ".mp4");
            s = s.replacingOccurrences(of: ".webm", with: ".mp4");
        }
        if (s.endsWith("/")) {
            s = s.substring(0, length: s.length - 1)
        }
        if (s.contains("v.redd.it") && !s.contains("DASH")) {
            if (s.endsWith("/")) {
                s = s.substring(0, length: s.length - 2)
            }
            s = s + "/DASH_9_6_M";
        }
        return s;
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
            if (url.contains(".mp4") || url.contains("webm") || url.contains("redditmedia.com")) {
                return VideoType.DIRECT
            }
            if (url.contains("gfycat") && !url.contains("mp4")) {
                return VideoType.GFYCAT
            }
            if (url.contains("v.redd.it")) {
                return VideoType.REDDIT
            }
            if (url.contains("imgur.com")) {
                return VideoType.IMGUR
            }
            if (url.contains("vid.me")) {
                return VideoType.VID_ME
            }
            if (url.contains("streamable.com")) {
                return VideoType.STREAMABLE
            }
            return VideoType.OTHER
        }

        func getSourceObject() -> VideoSource {
            switch (self) {
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
        var millis = 0
        var video = ""
        var playlist = ""
        
        var url = urlS
        if (url.contains("#t=")) {
            url = url.replacingOccurrences(of: "#t=", with: url.contains("?") ? "&t=" : "?t=")
        }

        let i = URL.init(string: url)
        if let dictionary = i?.queryDictionary {
            if let t = dictionary["t"] {
                millis = getTimeFromString(t);
            } else if let start = dictionary["start"] {
                millis = getTimeFromString(start);
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
                video = param.substring(param.indexOf("=")! + 1, length: param.contains("&") ? param.indexOf("&")! : param.length);
            }
        }

        if (!playlist.isEmpty) {
            youtubeView.load(withPlaylistId: playlist)
        } else {
            youtubeView.load(withVideoId: video, playerVars: ["controls": 0, "playsinline": 1, "start": millis, "fs": 0])
        }
    }

}

extension VideoMediaViewController: CachingPlayerItemDelegate {

    func playerItemReadyToPlay(_ playerItem: CachingPlayerItem) {
        print("Player ready to play")
        videoView.player?.play()
        
        // Hook up the scrubber to the player
        scrubber.totalDuration = videoView.player!.currentItem!.asset.duration
        observer = self.videoView.player!.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self] (time) in
            self?.scrubber.updateWithTime(elapsedTime: time)
        }

        makeControls()
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
    
    func getKeyFromURL() -> String {
        let disallowedChars = CharacterSet.urlPathAllowed.inverted
        var key = self.data.baseURL!.absoluteString.components(separatedBy: disallowedChars).joined(separator: "_")
        key = key.replacingOccurrences(of: ":", with: "")
        key = key.replacingOccurrences(of: "/", with: "")
        key = key.replacingOccurrences(of: ".gifv", with: ".mp4")
        key = key.replacingOccurrences(of: ".gif", with: ".mp4")
        key = key.replacingOccurrences(of: ".", with: "")
        if (key.length > 200) {
            key = key.substring(0, length: 200)
        }
        
        return SDImageCache.shared().makeDiskCachePath(key) + ".mp4"
    }
}

extension VideoMediaViewController: YTPlayerViewDelegate {

    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        youtubeView.playVideo()
        makeControls()
        scrubber.totalDuration = CMTime.init(value: CMTimeValue(playerView.duration()), timescale: CMTimeScale(NSEC_PER_SEC))
    }

    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
        self.scrubber.updateWithTime(elapsedTime: CMTime.init(value: CMTimeValue(playTime), timescale: CMTimeScale(NSEC_PER_SEC)))

    }

    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {

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
        if (inv.endsWith("/")) {
            inv = inv.substring(0, length: inv.length - 1)
        }
        let slashindex = inv.lastIndexOf("/")!
        print("Index is \(slashindex)")
        inv = inv.substring(slashindex + 1, length: inv.length - slashindex - 1)
        return inv
    }

    func getTimeFromString(_ time: String) -> Int {
        var timeAdd = 0;
        for s in time.components(separatedBy: CharacterSet.init(charactersIn: "hms")) {
            print(s)
            if (!s.isEmpty) {
                if (time.contains(s + "s")) {
                    timeAdd += Int(s)!;
                } else if (time.contains(s + "m")) {
                    timeAdd += 60 * Int(s)!;
                } else if (time.contains(s + "h")) {
                    timeAdd += 3600 * Int(s)!;
                }
            }
        }
        if (timeAdd == 0 && Int(time) != nil) {
            timeAdd += Int(time)!;
        }

        return timeAdd * 1000;

    }
    func showTitle(_ sender: AnyObject) {
        let alertController = UIAlertController.init(title: "Caption", message: nil, preferredStyle: .alert)
        alertController.addTextViewer(text: .text(data.text!))
        alertController.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func showContextMenu(_ sender: UIButton) {
        guard let baseURL = self.data.baseURL else {
            return
        }
        let alert = UIAlertController.init(title: baseURL.absoluteString, message: "", preferredStyle: .actionSheet)
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alert.addAction(
                UIAlertAction(title: "Open in Chrome", style: .default) { (action) in
                    open.openInChrome(baseURL, callbackURL: nil, createNewTab: true)
                }
            )
        }
        alert.addAction(
            UIAlertAction(title: "Open in Safari", style: .default) { (action) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(baseURL, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(baseURL)
                }
            }
        )
        alert.addAction(
            UIAlertAction(title: "Share URL", style: .default) { (action) in
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
            UIAlertAction(title: "Share Video", style: .default) { (action) in
                //TODO THIS
            }
        )
        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { (action) in
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
    
    func downloadImageToLibrary(_ sender: AnyObject) {
        fatalError("Implement this")
    }
    
}

extension VideoMediaViewController: VideoScrubberViewDelegate {
    func sliderValueChanged(toSeconds: Float) {
        self.handleShowUI()
        self.videoView.player?.pause()

        let targetTime = CMTime(seconds: Double(toSeconds), preferredTimescale: 1000)
        self.videoView.player?.seek(to: targetTime)
    }

    func sliderDidBeginDragging() {
        videoView.player?.pause()
        
    }
    
    func toggleReturnPlaying() -> Bool {
        self.handleShowUI()
        if let player = videoView.player {
            if(player.rate != 0){
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

    func sliderDidEndDragging() {
        self.videoView.player?.play()
        self.startTimerToHide()
    }
}



