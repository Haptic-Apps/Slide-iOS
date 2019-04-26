//
//  VideoMediaDownloader.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 11/7/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Alamofire
import AVFoundation
import SDWebImage
import UIKit

class VideoMediaDownloader {
    var request: DownloadRequest?
    var baseURL: String
    var videoType: VideoMediaViewController.VideoType
    var progressBar = UIProgressView()
    var alertView: UIAlertController?

    init(urlToLoad: URL) {
        self.baseURL = urlToLoad.absoluteString
        self.videoType = VideoMediaViewController.VideoType.fromPath(baseURL)
        print(baseURL)
    }
    
    func getVideoWithCompletion(completion: @escaping (_ fileURL: URL?) -> Void, parent: UIViewController) {
        alertView = UIAlertController(title: "Downloading...", message: "Your video is downloading", preferredStyle: .alert)
        alertView!.addCancelButton()
        
        parent.present(alertView!, animated: true, completion: {
            let margin: CGFloat = 8.0
            let rect = CGRect.init(x: margin, y: 72.0, width: (self.alertView?.view.frame.width)! - margin * 2.0, height: 2.0)
            self.progressBar = UIProgressView(frame: rect)
            self.progressBar.progress = 0
            self.progressBar.tintColor = ColorUtil.accentColorForSub(sub: "")
            self.alertView?.view.addSubview(self.progressBar)
        })
        
        if FileManager.default.fileExists(atPath: getKeyFromURL()) {
            alertView?.dismiss(animated: true, completion: {
                completion(URL(fileURLWithPath: self.getKeyFromURL()))
            })
        } else {
            request = Alamofire.download(URL(string: baseURL)!, method: .get, to: { (_, _) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                return (URL(fileURLWithPath: self.videoType == .REDDIT ? self.getKeyFromURL().replacingOccurrences(of: ".mp4", with: "video.mp4") : self.getKeyFromURL()), [.createIntermediateDirectories])
            }).downloadProgress() { progress in
                DispatchQueue.main.async {
                    let countBytes = ByteCountFormatter()
                    countBytes.allowedUnits = [.useMB]
                    countBytes.countStyle = .file
                    let fileSize = countBytes.string(fromByteCount: Int64(progress.totalUnitCount))
                    self.alertView?.title = "Downloading... (\(fileSize))"
                    self.progressBar.setProgress(Float(progress.fractionCompleted), animated: true)
                }
                }.responseData { response in
                    switch response.result {
                    case .failure(let error):
                        print(error)
                        self.alertView?.dismiss(animated: true, completion: {
                            BannerUtil.makeBanner(text: "Error downloading video", color: GMColor.red500Color(), seconds: 5, context: parent, top: false, callback: nil)
                        })
                    case .success:
                        
                        if self.videoType == .REDDIT {
                            self.downloadRedditAudio(completion: completion, parent: parent)
                        } else {
                            DispatchQueue.main.async {
                                self.alertView?.dismiss(animated: true, completion: {
                                    completion(URL(fileURLWithPath: self.getKeyFromURL()))
                                })
                            }
                        }
                    }
            }
        }
    }
    
    func getKeyFromURL() -> String {
        let disallowedChars = CharacterSet.urlPathAllowed.inverted
        var key = self.baseURL.components(separatedBy: disallowedChars).joined(separator: "_")
        key = key.replacingOccurrences(of: ":", with: "")
        key = key.replacingOccurrences(of: "/", with: "")
        key = key.replacingOccurrences(of: ".gifv", with: ".mp4")
        key = key.replacingOccurrences(of: ".gif", with: ".mp4")
        key = key.replacingOccurrences(of: ".", with: "")
        if key.length > 200 {
            key = key.substring(0, length: 200)
        }
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        return paths[0].appending(key + ".mp4")
    }
    
    func downloadRedditAudio(completion: @escaping (_ fileURL: URL?) -> Void, parent: UIViewController) {
        let key = getKeyFromURL()
        var toLoadAudio = self.baseURL
        toLoadAudio = toLoadAudio.substring(0, length: toLoadAudio.lastIndexOf("/DASH_") ?? toLoadAudio.length)
        toLoadAudio += "/audio"
        let finalUrl = URL.init(fileURLWithPath: key)
        let localUrlV = URL.init(fileURLWithPath: key.replacingOccurrences(of: ".mp4", with: "video.mp4"))
        let localUrlAudio = URL.init(fileURLWithPath: key.replacingOccurrences(of: ".mp4", with: "audio.mp4"))
        
        self.request = Alamofire.download(toLoadAudio, method: .get, to: { (_, _) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
            return (localUrlAudio, [.removePreviousFile, .createIntermediateDirectories])
        }).downloadProgress() { progress in
            DispatchQueue.main.async {
                let countBytes = ByteCountFormatter()
                countBytes.allowedUnits = [.useMB]
                countBytes.countStyle = .file
                let fileSize = countBytes.string(fromByteCount: Int64(progress.totalUnitCount))
                self.alertView?.title = "Downloading audio... (\(fileSize))"
                self.progressBar.setProgress(Float(progress.fractionCompleted), animated: true)
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
                            self.alertView?.dismiss(animated: true, completion: {
                                completion(URL(fileURLWithPath: self.getKeyFromURL()))
                            })
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.alertView?.dismiss(animated: true, completion: {
                                completion(URL(fileURLWithPath: self.getKeyFromURL()))
                            })
                        }
                    }
                } else { //no errors
                    self.mergeFilesWithUrl(videoUrl: localUrlV, audioUrl: localUrlAudio, savePathUrl: finalUrl) {
                        DispatchQueue.main.async {
                            self.alertView?.dismiss(animated: true, completion: {
                                completion(URL(fileURLWithPath: self.getKeyFromURL()))
                            })
                        }
                    }
                }
        }
    }
    
    func format(sS: String, _ hls: Bool = false) -> String {
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
        return format(sS: sS, false)
    }
    
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
