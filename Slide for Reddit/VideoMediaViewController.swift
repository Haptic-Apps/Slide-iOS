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

import AVFoundation

class VideoMediaViewController: EmbeddableMediaViewController {

    var videoView = VideoView()
    var youtubeView = YTPlayerView()

    var millis = 0
    var video = ""
    var playlist = ""

    // Key-value observing context
    private var playerItemContext = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        configureLayout()
        connectActions()

        loadContent()
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

    func configureViews() {
//        videoView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        view.addSubview(videoView)

        youtubeView.delegate = self
        youtubeView.isHidden = true
        view.addSubview(youtubeView)
    }

    func configureLayout() {
        videoView.edgeAnchors == view.edgeAnchors
//        videoView.horizontalAnchors == view.safeHorizontalAnchors
//        videoView.topAnchor == view.safeTopAnchor
//        videoView.bottomAnchor == view.safeBottomAnchor

        youtubeView.edgeAnchors == view.edgeAnchors
    }

    func connectActions() {
        
    }

    func loadContent() {

        if contentType == ContentType.CType.VIDEO {
            youtubeView.isHidden = false
            loadYoutube(url: data.baseURL!.absoluteString)
            return
        } else {
            youtubeView.isHidden = true
        }



        let url = formatUrl(sS: data.baseURL!.absoluteString)
        let videoType = VideoType.fromPath(url)

        switch (videoType) {
        case .GFYCAT:
            let name = url.substring(url.lastIndexOf("/")!, length: url.length - url.lastIndexOf("/")!)
            loadGfycat(url: "https://gfycat.com/cajax/get" + name)
        case .REDDIT:
//            return url
            loadVReddit(url: url)
        case .DIRECT, .IMGUR:
            var directURL = url
            if url.contains("redditmedia") {
                directURL = directURL.replacingOccurrences(of: ".gif", with: ".mp4")
            }
            getVideo(directURL)
        case .STREAMABLE:
            let hash = url.substring(url.lastIndexOf("/")! + 1, length: url.length - (url.lastIndexOf("/")! + 1))
            loadStreamable(url: "https://api.streamable.com/videos/" + hash)
        case .VID_ME:
            loadVidMe(url: "https://api.vid.me/videoByUrl?url=" + url)
        case .OTHER:
            //we should never get here
            fatalError("Video type unrecognized and unimplemented!")
        }
    }

    func getVideo(_ toLoad: String) {
        let playerItem = CachingPlayerItem(url: URL(string: toLoad)!)
        playerItem.delegate = self
        videoView.player = AVPlayer(playerItem: playerItem)
        if #available(iOS 10.0, *) {
            videoView.player?.automaticallyWaitsToMinimizeStalling = false
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
    }

}

extension VideoMediaViewController {
    func loadGfycat(url urlString: String) {
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
                        self.getVideo((gif?.gfyItem?.mp4Url)!)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }

        }.resume()
    }

    func loadStreamable(url urlString: String) {
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
                        self.getVideo(video)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }

        }.resume()
    }

    func loadVidMe(url urlString: String) {
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
                        self.getVideo((gif?.video?.complete_url)!)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }

        }.resume()
    }

    func loadVReddit(url urlString: String) {
        let videoURL = URL(string: urlString)

        var audioURLString = urlString.substring(0, length: urlString.lastIndexOf("DASH_")!) + "audio"
        let audioURL = URL(string: audioURLString)
        // The resource fetched by audioURL might not exist.

        let muxedURL = urlString.substring(0, length: urlString.lastIndexOf("DASH_")!) + "HLSPlaylist.m3u8"
        self.getVideo(muxedURL)

    }

    func loadYoutube(url urlS: String) {
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
            youtubeView.load(withVideoId: video, playerVars: ["controls": 1, "playsinline": 1, "start": millis, "fs": 0])
        }
    }
}

extension VideoMediaViewController: CachingPlayerItemDelegate {

    func playerItemReadyToPlay(_ playerItem: CachingPlayerItem) {
        print("Player ready to play")
        videoView.player?.play()
    }

    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        print("File is downloaded and ready for storing")
    }

    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
//        print("\(bytesDownloaded)/\(bytesExpected)")
        DispatchQueue.main.async {
            self.progressView.progress = Float(bytesDownloaded) / Float(bytesExpected)
        }
    }

    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
        print("Not enough data for playback. Probably because of the poor network. Wait a bit and try to play later.")
    }

    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
        print(error)
    }
}

extension VideoMediaViewController: YTPlayerViewDelegate {

    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        youtubeView.playVideo()
    }

    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {

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
}
