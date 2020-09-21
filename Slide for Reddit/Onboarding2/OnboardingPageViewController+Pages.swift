//
//  OnboardingPageViewController+Pages.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 9/15/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import AVKit
import reddift
import Then
import UIKit

/**
 ViewController for a single page in the OnboardingPageViewController.
 Describes a single feature with text and an image.
 */
class OnboardingFeaturePageViewController: UIViewController {
    let text: String
    let image: UIImage

    init(text: String, image: UIImage) {
        self.text = text
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        self.text = ""
        self.image = UIImage()
        super.init(coder: coder)
    }
}

/**
 ViewController for a single page in the OnboardingPageViewController.
 Describes the app's latest changelog.
 */
class OnboardingChangelogPageViewController: UIViewController {
    let link: Link

    init(link: Link) {
        self.link = link
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        self.link = Link(id: "")
        super.init(coder: coder)
    }
}

/**
 ViewController for a single page in the OnboardingPageViewController.
 Shows a video with a given resource name.
 */
class OnboardingVideoPageViewController: UIViewController {
    let text: String
    let video: String
    
    var textView = UILabel()
    var videoPlayer = AVPlayer()
    let videoContainer = UIView()
    
    var layer: AVPlayerLayer?

    init(text: String, video: String) {
        self.text = text
        self.video = video
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        self.text = ""
        self.video = ""
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        
        startVideos()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupViews() {
        self.textView = UILabel().then {
            $0.font = UIFont.boldSystemFont(ofSize: 20)
            $0.textColor = ColorUtil.theme.fontColor
            $0.textAlignment = .center
            $0.text = text
        }
        self.view.addSubview(textView)
        self.view.addSubview(videoContainer)
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        layer?.frame = videoContainer.bounds
    }

    func setupConstraints() {
        textView.horizontalAnchors == self.view.horizontalAnchors
        textView.topAnchor == self.view.safeTopAnchor + 8
        
        videoContainer.topAnchor == textView.bottomAnchor + 8
        videoContainer.bottomAnchor == self.view.bottomAnchor + 8
        videoContainer.horizontalAnchors == self.view.horizontalAnchors
    }
    
    func startVideos() {
        let bundle = Bundle.main
        if let videoPath = bundle.path(forResource: video, ofType: "mp4") {
            videoPlayer = AVPlayer(url: URL(fileURLWithPath: videoPath))
            layer = AVPlayerLayer(player: videoPlayer)
            
            layer!.needsDisplayOnBoundsChange = true
            layer!.videoGravity = .resizeAspect
            
            videoContainer.layer.addSublayer(layer!)
            videoContainer.clipsToBounds = true
            videoContainer.layer.masksToBounds = true
            videoContainer.layer.cornerRadius = 20
            
            videoPlayer.play()
            videoPlayer.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem)
        }
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
}
