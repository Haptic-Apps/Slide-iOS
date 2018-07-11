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

class VideoMediaViewController: EmbeddableMediaViewController {

    var videoContainer: UIView = UIView()

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
        videoContainer = UIView()
        view.addSubview(videoContainer)
    }

    func configureLayout() {
        videoContainer.centerAnchors == view.safeCenterAnchors
        /*
        videoContainer.horizontalAnchors == view.safeHorizontalAnchors
        videoContainer.topAnchor == view.safeTopAnchor
        videoContainer.bottomAnchor == view.safeBottomAnchor
        */
    }

    func connectActions() {
        
    }

    func loadContent() {
        /*
         Make sure to set videoGravity, then just make the video container fill the screen.
         */

    }

    func getTransformedPath(fromURL: URL) -> String? {
        let url = formatUrl(sS: fromURL.absoluteString)
        let videoType =  VideoType.fromPath(url)

        switch (videoType) {
        case .GFYCAT:
            let name = url.substring(url.lastIndexOf("/")!, length: url.length - url.lastIndexOf("/")!)
            return "https://gfycat.com/cajax/get" + name
        case .REDDIT:
            return url
        case .DIRECT, .IMGUR:
            return url
        case .STREAMABLE:
            let hash = url.substring(url.lastIndexOf("/")! + 1, length: url.length - (url.lastIndexOf("/")! + 1))
            let streamableUrl = "https://api.streamable.com/videos/" + hash
            return streamableUrl
        case .VID_ME:
            return "https://api.vid.me/videoByUrl?url=" + url
        case .OTHER:
            //we should never get here
            return nil
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
