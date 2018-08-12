//
//  VideoSource.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/12/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

protocol VideoSource {
    func load(url: String, completion: @escaping (String) -> Void, failure: @escaping () -> Void)
}

class DirectVideoSource: VideoSource {
    func load(url: String, completion: @escaping (String) -> Void, failure: @escaping () -> Void) {

        var finalURL = url
        if finalURL.contains("imgur.com") {
            finalURL = finalURL.replacingOccurrences(of: ".gifv", with: ".mp4")
            finalURL = finalURL.replacingOccurrences(of: ".gif", with: ".mp4")
        }
        completion(finalURL)
    }
}

class GfycatVideoSource: VideoSource {
    func load(url: String, completion: @escaping (String) -> Void, failure: @escaping () -> Void) {
        let name = url.substring(url.lastIndexOf("/")!, length: url.length - url.lastIndexOf("/")!)

        let finalURL = URL(string: "https://gfycat.com/cajax/get" + name)!
        URLSession.shared.dataTask(with: finalURL) { (data, _, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
                failure()
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }

                    let gif = GfycatJSONBase.init(dictionary: json)

                    DispatchQueue.main.async {
                        completion((gif?.gfyItem?.mp4Url)!)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }

        }.resume()
        
    }
}

class RedditVideoSource: VideoSource {
    func load(url: String, completion: @escaping (String) -> Void, failure: @escaping () -> Void) {
        let muxedURL = url
        completion(muxedURL)
    }
}

class StreamableVideoSource: VideoSource {
    func load(url: String, completion: @escaping (String) -> Void, failure: @escaping () -> Void) {
        let hash = url.substring(url.lastIndexOf("/")! + 1, length: url.length - (url.lastIndexOf("/")! + 1))

        let finalURL = URL(string: "https://api.streamable.com/videos/" + hash)!
        URLSession.shared.dataTask(with: finalURL) { (data, _, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
                failure()
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
                        if video.hasPrefix("//") {
                            video = "https:" + video
                        }
                        completion(video)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }

        }.resume()
    }
}

class VidMeVideoSource: VideoSource {
    func load(url: String, completion: @escaping (String) -> Void, failure: @escaping () -> Void) {
        let finalURL = URL(string: "https://api.vid.me/videoByUrl?url=" + url)!
        URLSession.shared.dataTask(with: finalURL) { (data, _, error) in
            if error != nil {
                print(error ?? "Error loading gif...")
                failure()
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary else {
                        return
                    }

                    let gif = VidMeJSONBase.init(dictionary: json)

                    DispatchQueue.main.async {
                        completion((gif?.video?.complete_url)!)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }

        }.resume()
    }
}
