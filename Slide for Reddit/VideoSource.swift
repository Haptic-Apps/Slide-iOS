//
//  VideoSource.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/12/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

class VideoSourceSessionCache: NSObject {
    static var cache: [String: String] = [:]
    
    static func addVideo(urlString: String, videoString: String) {
        cache[urlString] = videoString
    }
    
    static func getURL(from: String) -> String? {
        return cache[from]
    }

    static func hasCached(_ video: String) -> Bool {
        return cache[video] != nil
    }
}
protocol VideoSource {
    func load(url: String, completion: @escaping (String) -> Void, failure: (() -> Void)?) -> URLSessionDataTask?
}

class DirectVideoSource: VideoSource {
    func load(url: String, completion: @escaping (String) -> Void, failure: (() -> Void)? = nil) -> URLSessionDataTask? {
        var finalURL = url
        if finalURL.contains("imgur.com") {
            finalURL = finalURL.replacingOccurrences(of: ".gifv", with: ".mp4")
            finalURL = finalURL.replacingOccurrences(of: ".gif", with: ".mp4")
        }
        completion(finalURL)
        return nil
    }
}

class GfycatVideoSource: VideoSource {
    func load(url: String, completion: @escaping (String) -> Void, failure: (() -> Void)? = nil) -> URLSessionDataTask? {
        var name = url.substring(url.lastIndexOf("/")!, length: url.length - url.lastIndexOf("/")!)
        if !(name.startsWith("/")) {
            name = "/" + name
        }
        if name.contains("-") {
            name = name.split("-")[0]
        }
        name = name.split(".")[0]
        let finalURL = URL(string: "https://api.\(url.contains("redgifs") ? "redgifs" : "gfycat").com/v1/gfycats\(name)")
        if finalURL == nil {
            failure?()
            return nil
        }
        if let videoUrl = VideoSourceSessionCache.getURL(from: finalURL!.absoluteString) {
            completion(videoUrl)
            return nil
        }
        let dataTask = URLSession.shared.dataTask(with: finalURL!) { (data, _, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
                DispatchQueue.main.async {
                    failure?()
                }
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }
                    
                    if json["errorMessage"] != nil {
                        DispatchQueue.main.async {
                            failure?()
                        }
                        return
                    }

                    let gif = GfycatJSONBase.init(dictionary: json)
                    if let mp4 = gif?.gfyItem?.mobileUrl {
                        VideoSourceSessionCache.addVideo(urlString: finalURL!.absoluteString, videoString: mp4)
                        DispatchQueue.main.async {
                            completion(mp4)
                        }
                    } else if let mp4 = gif?.gfyItem?.mp4Url {
                        VideoSourceSessionCache.addVideo(urlString: finalURL!.absoluteString, videoString: mp4)
                        DispatchQueue.main.async {
                            completion(mp4)
                        }
                    } else {
                        DispatchQueue.main.async {
                            failure?()
                        }
                    }
                } catch let error as NSError {
                    print(error)
                }
            }

        }
        dataTask.resume()
        return dataTask
    }
}

class RedditVideoSource: VideoSource {
    func load(url: String, completion: @escaping (String) -> Void, failure: (() -> Void)? = nil) -> URLSessionDataTask? {
        let muxedURL = url
        completion(muxedURL)
        return nil
    }
}

class StreamableVideoSource: VideoSource {
    func load(url: String, completion: @escaping (String) -> Void, failure: (() -> Void)? = nil) -> URLSessionDataTask? {
        let hash = url.substring(url.lastIndexOf("/")! + 1, length: url.length - (url.lastIndexOf("/")! + 1))

        let finalURL = URL(string: "https://api.streamable.com/videos/" + hash)
        if finalURL == nil {
            failure?()
            return nil
        }
        if let videoUrl = VideoSourceSessionCache.getURL(from: finalURL!.absoluteString) {
            completion(videoUrl)
            return nil
        }
        let dataTask = URLSession.shared.dataTask(with: finalURL!) { (data, _, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
                failure?()
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
                        }
                        
                        if video.isEmpty() {
                            video = (gif?.files?.mp4?.url) ?? ""
                        }
                        if video.isEmpty() {
                            failure?()
                            return
                        }
                        if video.hasPrefix("//") {
                            video = "https:" + video
                        }
                        VideoSourceSessionCache.addVideo(urlString: finalURL!.absoluteString, videoString: video)
                        completion(video)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
        }
        dataTask.resume()
        return dataTask
    }
}
