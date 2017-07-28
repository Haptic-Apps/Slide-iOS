//
//  YouTubeViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/18/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class YouTubeViewController: UIViewController, YTPlayerViewDelegate {
    var panGestureRecognizer: UIPanGestureRecognizer?
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    var url: URL?
    var parentVC: UIViewController?
    
    init(bUrl: URL, parent: UIViewController){
        self.url = bUrl
        super.init(nibName: nil, bundle: nil)
        self.parentVC = parent
        
        var url = bUrl.absoluteString
        if(url.contains("#t=")){
            url = url.replacingOccurrences(of: "#t=", with: url.contains("?") ? "&t=" : "?t=")
        }
        
        let i = URL.init(string: url)
        if let dictionary = i?.queryDictionary {
            if let t = dictionary["t"]{
                millis = getTimeFromString(t);
            } else if let start = dictionary["start"] {
                millis = getTimeFromString(start);
            }
            
            if let list = dictionary["list"]{
                playlist = list
            }
            
            if let v = dictionary["v"]{
                video = v
            } else if let w = dictionary["w"]{
                video = w
            } else if url.lowercased().contains("youtu.be"){
                video = getLastPathSegment(url)
            }
            
            if let u = dictionary["u"]{
                let param =  u
                video = param.substring(param.indexOf("=")! + 1, length: param.contains("&") ? param.indexOf("&")! : param.length);
            }
        } else {
            let w = WebsiteViewController.init(url: bUrl, subreddit: "")
            parentVC!.present(w, animated: true)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getLastPathSegment(_ path: String) -> String {
        var inv = path
        if(inv.endsWith("/")){
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
            for s in time.components(separatedBy: "s|m|h"){
                if(time.contains(s + "s")){
                    timeAdd += Int(s)!;
                } else if(time.contains(s + "m")){
                    timeAdd += 60 * Int(s)!;
                } else if(time.contains(s + "h")){
                    timeAdd += 3600 * Int(s)!;
                }
            }
            if(timeAdd == 0){
                timeAdd+=Int(time)!;
            }
            
            return timeAdd * 1000;
            
    }
    
    var player = YTPlayerView()
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        self.player.playVideo()
        
    }

    override func loadView() {
        self.view = YTPlayerView(frame: CGRect.zero)
        self.player = self.view as! YTPlayerView
        self.player.delegate = self
        if(!playlist.isEmpty){
            player.load(withPlaylistId: playlist)
        } else {
            player.load(withVideoId: video, playerVars: ["controls":1,"playsinline":1,"start":millis,"fs":0])
        }

    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        modalPresentationStyle = .currentContext
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.clear
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        player.addGestureRecognizer(panGestureRecognizer!)
    }
    
    func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)
        
        if panGesture.state == .began {
            originalPosition = view.center
            currentPositionTouched = panGesture.location(in: view)
        } else if panGesture.state == .changed {
            view.frame.origin = CGPoint(
                x: translation.x,
                y: translation.y
            )
        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: view)
            
            if velocity.y >= 1500 {
                UIView.animate(withDuration: 0.2
                    , animations: {
                        self.view.frame.origin = CGPoint(
                            x: self.view.frame.origin.x,
                            y: self.view.frame.size.height
                        )
                }, completion: { (isCompleted) in
                    if isCompleted {
                        self.dismiss(animated: false, completion: nil)
                    }
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.center = self.originalPosition!
                })
            }
        }
    }
}
