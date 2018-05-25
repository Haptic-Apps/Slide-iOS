//
// Created by Carlos Crane on 2/16/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import AVKit
import SDWebImage
import MaterialComponents.MaterialProgressView

class VideoDisplayer: MediaViewController, YTPlayerViewDelegate {
    var videoView = UIView()
    var ytPlayer = YTPlayerView()
    var playerVC = AVPlayerViewController()
    static var videoPlayer: AVPlayer? = nil
    var progressView: MDCProgressView?
    var size: UILabel?
    var scrollView = UIScrollView()
    var sharedPlayer = true

    public func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        playerView.isHidden = false
        self.ytPlayer.playVideo()
    }

    func getYouTube(_ ytPlayer: YTPlayerView, urlS: String) {
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
        self.ytPlayer.delegate = self
        if (!playlist.isEmpty) {
            ytPlayer.load(withPlaylistId: playlist)
        } else {
            ytPlayer.load(withVideoId: video, playerVars: ["controls": 1, "playsinline": 1, "start": millis, "fs": 0])
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        request?.cancel()
    }

    func getGif(urlS: String) {

        let url = formatUrl(sS: urlS)
        let videoType = getVideoType(url: url)


        switch (videoType) {
        case .GFYCAT:
            let name = url.substring(url.lastIndexOf("/")!, length: url.length - url.lastIndexOf("/")!)
            let gfycatUrl = "https://gfycat.com/cajax/get" + name;
            loadGfycat(urlString: gfycatUrl)
            break
        case .REDDIT:
            self.loadVReddit(toLoad: url)
            break
        case .DIRECT:
            fallthrough
        case .IMGUR:
            self.loadVideo(urlString: url)
            break
        case .STREAMABLE:
            let hash = url.substring(url.lastIndexOf("/")! + 1, length: url.length - (url.lastIndexOf("/")! + 1));
            let streamableUrl = "https://api.streamable.com/videos/" + hash;
            getStreamableObject(urlString: streamableUrl)
            break
        case .VID_ME:
            let vidmeUrl = "https://api.vid.me/videoByUrl?url=" + url;
            getVidMeObject(urlString: vidmeUrl)
            break
        case .OTHER:
            //we should never get here
            break
        }
    }

    func loadVReddit(toLoad: String) {
        let disallowedChars = CharacterSet.urlPathAllowed.inverted
        var key = toLoad.components(separatedBy: disallowedChars).joined(separator: "_")
        key = key.replacingOccurrences(of: ":", with: "")
        key = key.replacingOccurrences(of: "/", with: "")
        key = key.replacingOccurrences(of: ".", with: "")
        print(key)
        if (key.length > 200) {
            key = key.substring(0, length: 200)
        }
        var toLoadAudio = toLoad
        toLoadAudio = toLoad.substring(0, length: toLoad.lastIndexOf("DASH_")!)
        toLoadAudio = toLoadAudio + "audio"

        if (FileManager.default.fileExists(atPath:SDImageCache.shared().makeDiskCachePath(key) + ".mp4")) {
            display(URL.init(fileURLWithPath:SDImageCache.shared().makeDiskCachePath(key) + ".mp4"))
        } else {
            let finalUrl = URL.init(fileURLWithPath:SDImageCache.shared().makeDiskCachePath(key) + ".mp4")
            let localUrlV = URL.init(fileURLWithPath:SDImageCache.shared().makeDiskCachePath(key + "video.mp4"))
            let localUrlAudio = URL.init(fileURLWithPath:SDImageCache.shared().makeDiskCachePath(key + "audio.mp4"))
            progressView?.setHidden(false, animated: true, completion: nil)

            request = Alamofire.download(toLoad, method: .get, to: { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                        return (localUrlV, [.removePreviousFile, .createIntermediateDirectories])
                    }).downloadProgress() { progress in
                        DispatchQueue.main.async {
                            self.progressView?.progress = Float(progress.fractionCompleted)
                            let countBytes = ByteCountFormatter()
                            countBytes.allowedUnits = [.useMB]
                            countBytes.countStyle = .file
                            let fileSize = countBytes.string(fromByteCount: Int64(progress.totalUnitCount))
                            self.size?.text = fileSize
                        }

                    }
                    .responseData { response in
                        if let error = response.error {
                            print(error)
                        } else { //no errors
                            print("Downloaded")
                            self.request = Alamofire.download(toLoadAudio, method: .get, to: { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                                        return (localUrlAudio, [.removePreviousFile, .createIntermediateDirectories])
                                    }).downloadProgress() { progress in
                                        DispatchQueue.main.async {
                                            self.progressView?.progress = Float(progress.fractionCompleted)
                                        }
                                    }
                                    .responseData { response2 in
                                        print(response2.response!.statusCode)
                                        if (response2.response!.statusCode != 200) {
                                            do {
                                                try FileManager.init().copyItem(at: localUrlV, to: finalUrl)
                                                self.display(finalUrl)
                                            } catch {
                                                self.display(localUrlV)
                                            }
                                        } else { //no errors
                                            print(response2.request!.url!.absoluteString)
                                            self.mergeFilesWithUrl(videoUrl: localUrlV, audioUrl: localUrlAudio, savePathUrl: finalUrl) {
                                                self.display(finalUrl)
                                            }
                                        }
                                    }
                        }
                    }
        }
    }

    func loadVideo(urlString: String) {
        refresh(urlString)
    }

    func refresh(_ toLoad: String) {
        let disallowedChars = CharacterSet.urlPathAllowed.inverted
        var key = toLoad.components(separatedBy: disallowedChars).joined(separator: "_")
        key = key.replacingOccurrences(of: ":", with: "")
        key = key.replacingOccurrences(of: "/", with: "")
        key = key.replacingOccurrences(of: ".", with: "")
        key = key + ".mp4"
        print(key)
        if (key.length > 200) {
            key = key.substring(0, length: 200)
        }
        if (FileManager.default.fileExists(atPath:SDImageCache.shared().makeDiskCachePath(key))) {
            display(URL.init(fileURLWithPath:SDImageCache.shared().makeDiskCachePath(key)))
        } else {
            let localUrl = URL.init(fileURLWithPath:SDImageCache.shared().makeDiskCachePath(key))
            print(localUrl)
            progressView?.setHidden(false, animated: true, completion: nil)
            request = Alamofire.download(toLoad, method: .get, to: { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                        return (localUrl, [.createIntermediateDirectories])

                    }).downloadProgress() { progress in
                        DispatchQueue.main.async {
                            self.progressView?.progress = Float(progress.fractionCompleted)
                            let countBytes = ByteCountFormatter()
                            countBytes.allowedUnits = [.useMB]
                            countBytes.countStyle = .file
                            let fileSize = countBytes.string(fromByteCount: Int64(progress.totalUnitCount))
                            self.size?.text = fileSize
                        }

                    }
                    .responseData { response in
                        if let error = response.error {
                            print(error)
                        } else { //no errors
                            self.display(localUrl)
                            print("File downloaded successfully: \(localUrl)")
                        }
                    }

        }
    }


    var request: DownloadRequest?

    func getYTHeight() -> CGFloat {
        let height = ((self.view.frame.size.width / 16) * 9)
        return height
    }


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

    var millis = 0
    var video = ""
    var playlist = ""

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

    func loadGfycat(urlString: String) {
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }

                    let gif = GfycatJSONBase.init(dictionary: json)

                    DispatchQueue.main.async {
                        self.loadVideo(urlString: (gif?.gfyItem?.mp4Url)!)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }

        }.resume()
    }

    func getStreamableObject(urlString: String) {
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }

                    let gif = StreamableJSONBase.init(dictionary: json)

                    DispatchQueue.main.async {
                        var video = ""
                        if let url = gif?.files?.mp4mobile?.url {
                            video = url
                        } else {
                            video = (gif?.files?.mp4?.url!)!
                        }
                        if (video.hasPrefix("//")) {
                            video = "https:" + video
                        }
                        self.loadVideo(urlString: video)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }

        }.resume()
    }

    func getVidMeObject(urlString: String) {
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }

                    let gif = VidMeJSONBase.init(dictionary: json)

                    DispatchQueue.main.async {
                        self.loadVideo(urlString: (gif?.video?.complete_url)!)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }

        }.resume()
    }

    func getSmallerGfy(gfy: String) -> String {
        var gfyUrl = gfy
        gfyUrl = gfyUrl.replacingOccurrences(of: "fat", with: "thumbs")
        gfyUrl = gfyUrl.replacingOccurrences(of: "giant", with: "thumbs")
        gfyUrl = gfyUrl.replacingOccurrences(of: "zippy", with: "thumbs")

        if (!gfyUrl.endsWith("-mobile.mp4")) {
            gfyUrl = gfyUrl.replacingOccurrences(of: "\\.mp4", with: "-mobile.mp4")
        }
        return gfyUrl;
    }

    var player = AVPlayer()
    var displayedVideo: URL? = nil

    func display(_ file: URL) {
        DispatchQueue.main.async {
            self.displayedVideo = file
            print("Displayed \(file.absoluteString)")
            self.progressView?.setHidden(true, animated: true)
            self.size?.isHidden = true
            if (self.sharedPlayer && MediaDisplayViewController.videoPlayer == nil) {
                MediaDisplayViewController.videoPlayer = AVPlayer.init(playerItem: AVPlayerItem.init(url: file))
                self.player = MediaDisplayViewController.videoPlayer!
            } else {
                if (self.sharedPlayer) {
                    MediaDisplayViewController.videoPlayer!.replaceCurrentItem(with: AVPlayerItem.init(url: file))
                    self.player = MediaDisplayViewController.videoPlayer!
                } else {
                    self.player = AVPlayer.init(playerItem: AVPlayerItem.init(url: file))
                }
            }

            NotificationCenter.default.addObserver(self,
                    selector: #selector(MediaDisplayViewController.playerItemDidReachEnd),
                    name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                    object: self.player.currentItem)

            self.player.actionAtItemEnd = AVPlayerActionAtItemEnd.none

            self.playerVC = AVControlsPlayer()
            self.playerVC.player = self.player
            self.playerVC.videoGravity = AVLayerVideoGravityResizeAspect
            self.playerVC.showsPlaybackControls = false

            self.videoView = (self.playerVC.view)
            self.addChildViewController(self.playerVC)
            self.scrollView.addSubview(self.videoView)
            self.videoView.frame = CGRect.init(x: 0, y: 50, width: self.view.frame.width, height: self.view.frame.height - 80)
            self.playerVC.didMove(toParentViewController: self)

            self.scrollView.isUserInteractionEnabled = true
            self.player.play()
        }
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

    func getVideoType(url: String) -> VideoType {
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
        return VideoType.OTHER;
    }

    enum VideoType {
        case IMGUR
        case VID_ME
        case STREAMABLE
        case GFYCAT
        case DIRECT
        case REDDIT
        case OTHER
    }

    func playerItemDidReachEnd(notification: NSNotification) {
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: kCMTimeZero)
        }
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
                print("failed \(assetExport.error)")
            case AVAssetExportSessionStatus.cancelled:
                print("cancelled \(assetExport.error)")
            default:
                print("complete")
            }
        }
    }

}