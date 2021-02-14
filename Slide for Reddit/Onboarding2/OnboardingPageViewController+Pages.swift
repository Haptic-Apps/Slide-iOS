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
 Describes a splash screen with animated background.
 */
class OnboardingSplashPageViewController: UIViewController {
    let text: String
    let subText: String
    let image: UIImage
    
    var textView = UILabel()
    var subTextView = UILabel()
    var imageView = UIImageView()
    var baseView = UIView()

    var shouldMove = true
    var gradientSet = false
    
    let bubbles = UIScreen.main.bounds.height / 30
    
    var lanes = [Int](repeating: 0, count: Int(UIScreen.main.bounds.height / 30))
    
    init(text: String, subText: String, image: UIImage) {
        self.text = text
        self.subText = subText
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupViews()
        self.setupConstriants()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setupMovingViews()
        self.baseView.alpha = 1
        shouldMove = true
        self.view.clipsToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.animate(withDuration: 1) {
            self.baseView.alpha = 0
        } completion: { (_) in
            self.stopMoving()
        }
    }
    
    func stopMoving() {
        shouldMove = false
    }
    
    func setupMovingViews() {
        gradientSet = false
        baseView.removeFromSuperview()
        baseView = UIView()
        view.addSubview(baseView)
        
        baseView.centerAnchors /==/ self.view.centerAnchors
        baseView.widthAnchor /==/ CGFloat(bubbles) * 30
        baseView.heightAnchor /==/ CGFloat(bubbles) * 30

        for i in 0..<Int(bubbles) {
            if i % 2 == 0 {
                self.lanes[i] = 2
                continue
            }
            let movingView = PreviewSubredditView(frame: CGRect.zero)
            baseView.addSubview(movingView)
            
            movingView.setFrame(getInitialFrame(for: movingView, in: i))
            movingView.alpha = 0
            movingView.tag = i
            
            self.lanes[i] += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(Int.random(in: 0...6))) {
                movingView.alpha = 1
                
                self.moveView(view: movingView, chosenLane: i)
            }
        }
        
        let radians = -30 / 180.0 * CGFloat.pi
        baseView.transform = CGAffineTransform(rotationAngle: radians)
        baseView.alpha = 0.4
        
        view.bringSubviewToFront(imageView)
        view.bringSubviewToFront(textView)
        view.bringSubviewToFront(subTextView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !gradientSet {
            gradientSet = true
            
            let gradientMaskLayer = CAGradientLayer()
            gradientMaskLayer.frame = self.view.bounds
            gradientMaskLayer.shadowRadius = 50
            gradientMaskLayer.shadowPath = CGPath(roundedRect: self.view.bounds.insetBy(dx: 0, dy: 0), cornerWidth: 0, cornerHeight: 0, transform: nil)

            gradientMaskLayer.shadowOpacity = 1
            
            gradientMaskLayer.shadowOffset = CGSize.zero
            gradientMaskLayer.shadowColor = UIColor.foregroundColor.cgColor

            view.layer.mask = gradientMaskLayer
        }
    }
    
    func getInitialFrame(for view: PreviewSubredditView, in lane: Int) -> CGRect {
        return CGRect(x: CGFloat(bubbles * 30), y: CGFloat(lane) * 30, width: 200, height: 30)
    }

    func getFinalFrame(for view: PreviewSubredditView, in lane: Int) -> CGRect {
        return CGRect(x: -1 * 200, y: CGFloat(lane) * 30, width: view.frame.size.width, height: 30)
    }

    func moveView(view: PreviewSubredditView, chosenLane: Int) {
        let time = Int.random(in: 5...10)
        UIView.animate(withDuration: Double(time), delay: 0, options: .curveLinear, animations: { () -> Void in
            view.frame = self.getFinalFrame(for: view, in: chosenLane)
        }, completion: { [weak self] (_) -> Void in
            guard let self = self else { return }
            if self.shouldMove {
                view.randomizeColors()
                self.lanes[chosenLane] -= 1
                var emptyIndexes = [Int]()
                for i in 0..<self.lanes.count {
                    if self.lanes[i] < 1 {
                        emptyIndexes.append(i)
                    }
                }
                
                let newLane = emptyIndexes.randomItem ?? 0
                self.lanes[newLane] += 1
                view.setFrame(self.getInitialFrame(for: view, in: newLane))

                self.moveView(view: view, chosenLane: newLane)
            } else {
                view.removeFromSuperview()
            }
        })
    }
    
    func setupViews() {
        let newTitle = NSMutableAttributedString(string: text.split("\n").first ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)])
        newTitle.append(NSAttributedString(string: "\n"))
        newTitle.append(NSMutableAttributedString(string: text.split("\n").last ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 30)]))

        self.textView = UILabel().then {
            $0.font = UIFont.boldSystemFont(ofSize: 30)
            $0.textColor = UIColor.white
            $0.textAlignment = .center
            $0.numberOfLines = 0
            $0.attributedText = newTitle
        }
        
        self.subTextView = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 15)
            $0.textColor = UIColor.white
            $0.textAlignment = .center
            $0.text = subText
        }

        self.imageView = UIImageView(image: image).then {
            $0.contentMode = .scaleAspectFill
            $0.layer.cornerRadius = 25
            $0.clipsToBounds = true
        }
        
        self.view.addSubviews(imageView, textView, subTextView)
    }
        
    func setupConstriants() {
        textView.horizontalAnchors /==/ self.view.horizontalAnchors + 32
        textView.bottomAnchor /==/ self.imageView.topAnchor - 40
        
        imageView.centerAnchors /==/ self.view.centerAnchors
        imageView.widthAnchor /==/ 100
        imageView.heightAnchor /==/ 100
        
        subTextView.horizontalAnchors /==/ self.view.horizontalAnchors + 32
        subTextView.bottomAnchor /==/ self.view.safeBottomAnchor - 8
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        self.text = ""
        self.subText = ""
        self.image = UIImage()
        super.init(coder: coder)
    }
}

class PreviewSubredditView: UIView {
    var bubble = UIView()
    var label = UIView()
    var toSetFrame = CGRect.zero
    
    var frameSet = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !frameSet {
            frameSet = true
            self.frame = toSetFrame
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        randomizeColors()
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func randomizeColors() {
        let seed = Int.random(in: 0...100)
        if seed < 30 {
            self.bubble.backgroundColor = UIColor(hexString: "#05d9e8")
            self.label.backgroundColor = UIColor(hexString: "#05d9e8")
            self.label.alpha = 0.6
        } else if seed < 50 {
            self.bubble.backgroundColor = UIColor(hexString: "#ff2a6d")
            self.label.backgroundColor = UIColor(hexString: "#ff2a6d")
            self.label.alpha = 0.6
        } else if seed < 60 {
            self.bubble.backgroundColor = UIColor(hexString: "#d1f7ff")
            self.label.backgroundColor = UIColor(hexString: "#d1f7ff")
            self.label.alpha = 0.6
        } else if seed < 70 {
            self.bubble.backgroundColor = UIColor(hexString: "#005678")
            self.label.backgroundColor = UIColor(hexString: "#005678")
            self.label.alpha = 0.6
        } else if seed < 80 {
            self.bubble.backgroundColor = UIColor(hexString: "#650D89")
            self.label.backgroundColor = UIColor(hexString: "#650D89")
            self.label.alpha = 0.6
        } else if seed < 90 {
            self.bubble.backgroundColor = UIColor(hexString: "#f9cb0e")
            self.label.backgroundColor = UIColor(hexString: "#f9cb0e")
            self.label.alpha = 0.6
        } else {
            self.bubble.backgroundColor = UIColor(hexString: "#ff3864")
            self.label.backgroundColor = UIColor(hexString: "#ff3864")
            self.label.alpha = 0.6
        }
    }
    
    func setFrame(_ frame: CGRect) {
        self.frame = frame
        self.toSetFrame = frame
    }

    func setupViews() {
        bubble = UIView().then {
            $0.clipsToBounds = true
        }
    }
    
    func setupConstraints() {
        self.addSubviews(bubble, label)
        
        let size = Int.random(in: 5...10)
        let scale = CGFloat(5) / CGFloat(size)
        
        bubble.widthAnchor /==/ 30 * scale
        bubble.heightAnchor /==/ 30 * scale
        
        bubble.layer.cornerRadius = 15 * scale
        
        label.widthAnchor /==/ CGFloat(Int.random(in: 40...150)) * scale
        label.heightAnchor /==/ 25 * scale
        label.layer.cornerRadius = 5 * scale
        label.clipsToBounds = true
        
        label.leftAnchor /==/ bubble.rightAnchor + 8 * scale
        label.centerYAnchor /==/ bubble.centerYAnchor
    }
}

/**
 ViewController for a single page in the OnboardingPageViewController.
 Describes a single feature with text and an image.
 */
class OnboardingFeaturePageViewController: UIViewController {
    let text: String
    let subText: String
    let image: UIImage
    
    var textView = UILabel()
    var subTextView = UILabel()
    var imageView = UIImageView()

    init(text: String, subText: String, image: UIImage) {
        self.text = text
        self.subText = subText
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupViews()
        self.setupConstriants()
    }
    
    func setupViews() {
        self.textView = UILabel().then {
            $0.font = UIFont.boldSystemFont(ofSize: 20)
            $0.textColor = UIColor.fontColor
            $0.textAlignment = .center
            $0.text = text
        }
        
        self.subTextView = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 15)
            $0.textColor = UIColor.fontColor
            $0.textAlignment = .center
            $0.text = subText
        }

        self.imageView = UIImageView(image: image).then {
            $0.contentMode = .scaleAspectFill
            $0.layer.cornerRadius = 25
            $0.clipsToBounds = true
        }
        
        self.view.addSubviews(imageView, textView, subTextView)
    }
    
    func setupConstriants() {
        textView.horizontalAnchors /==/ self.view.horizontalAnchors + 16
        textView.topAnchor /==/ self.view.safeTopAnchor + 8
        
        imageView.centerAnchors /==/ self.view.centerAnchors
        imageView.widthAnchor /==/ 100
        imageView.heightAnchor /==/ 100
        
        subTextView.horizontalAnchors /==/ self.view.horizontalAnchors + 16
        subTextView.bottomAnchor /==/ self.view.safeBottomAnchor - 8
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        self.text = ""
        self.subText = ""
        self.image = UIImage()
        super.init(coder: coder)
    }
}

/**
 ViewController for a single page in the OnboardingPageViewController.
 Shows a message about TestFlight and the TF subreddit.
 */
class OnboardingTFViewController: UIViewController {
    var textView = UILabel()
    var subTextView = UILabel()
    var imageView = UIImageView()
    var subButton = UIButton().then {
        $0.backgroundColor = UIColor(hexString: "#F95200")
        $0.titleLabel?.textColor = .white
        $0.tintColor = .white
        $0.addTarget(self, action: #selector(subTapped), for: UIControl.Event.touchUpInside)
        $0.isEnabled = true
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        $0.layer.cornerRadius = 25
        $0.setImage(Subscriptions.subreddits.contains("slide_ios_beta") ? UIImage(sfString: SFSymbol.checkmark, overrideString: "selected") : UIImage(sfString: SFSymbol.plus, overrideString: "ad"), for: .normal)
        $0.setTitle(Subscriptions.subreddits.contains("slide_ios_beta") ? "   You're subscribed!" : "   Subscribe", for: .normal)
        $0.isUserInteractionEnabled = true
    }
    
    @objc func subTapped() {
        if let session = (UIApplication.shared.delegate as? AppDelegate)?.session {
            Subscriptions.subscribe("slide_ios_beta", true, session: session)
            BannerUtil.makeBanner(text: "Subscribed to\nr/slide_ios_beta", color: ColorUtil.baseAccent, seconds: 3, context: self, top: true)
            subButton.setImage(Subscriptions.subreddits.contains("slide_ios_beta") ? UIImage(sfString: SFSymbol.checkmark, overrideString: "selected") : UIImage(sfString: SFSymbol.plus, overrideString: "ad"), for: .normal)
            subButton.setTitle(Subscriptions.subreddits.contains("slide_ios_beta") ? "You're already subscribed!" : "Subscribe", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupViews()
        self.setupConstriants()
    }
    
    func setupViews() {
        self.textView = UILabel().then {
            $0.font = UIFont.boldSystemFont(ofSize: 20)
            $0.textColor = UIColor.fontColor
            $0.numberOfLines = 0
            $0.textAlignment = .center
            $0.text = "TestFlight Beta Testing"
        }
        
        self.subTextView = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 15)
            $0.textColor = UIColor.fontColor
            $0.numberOfLines = 0
            $0.textAlignment = .center
            $0.text = "Subscribe to r/slide_ios_beta for information and discussion about v7 beta testing! Please post your feedback and bug reports to r/slide_ios_beta"
        }

        self.imageView = UIImageView(image: UIImage(named: "roundicon")).then {
            $0.contentMode = .scaleAspectFill
            $0.layer.cornerRadius = 50
            $0.clipsToBounds = true
        }
        
        self.view.addSubviews(imageView, textView, subTextView, subButton)
    }
    
    func setupConstriants() {
        textView.horizontalAnchors /==/ self.view.horizontalAnchors + 16
        textView.topAnchor /==/ self.view.safeTopAnchor + 8
        
        imageView.centerAnchors /==/ self.view.centerAnchors
        imageView.widthAnchor /==/ 100
        imageView.heightAnchor /==/ 100
        
        subButton.centerXAnchor /==/ self.view.centerXAnchor
        subButton.topAnchor /==/ imageView.bottomAnchor + 20
        subButton.heightAnchor /==/ 50
    
        subTextView.horizontalAnchors /==/ self.view.horizontalAnchors + 16
        subTextView.bottomAnchor /==/ self.view.safeBottomAnchor - 8
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
 Describes the app's latest changelog as Strings.
 */
class OnboardingHardcodedChangelogPageViewController: UIViewController {
    let paragraphs: [String: String]
    let order: [String]
    let subButton = UILabel()
    let body = UIScrollView()
    let content = UILabel()
    
    var sizeSet = false

    init(order: [String], paragraphs: [String: String]) {
        self.paragraphs = paragraphs
        self.order = order
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        self.paragraphs = [:]
        self.order = []
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !sizeSet {
            sizeSet = true
            self.content.preferredMaxLayoutWidth = self.body.frame.size.width - 16
            self.content.sizeToFit()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupViews() {
        let attributedChangelog = NSMutableAttributedString()
        for paragraph in order {
            attributedChangelog.append(NSAttributedString(string: paragraph, attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]))
            attributedChangelog.append(NSAttributedString(string: "\n"))
            attributedChangelog.append(NSAttributedString(string: "\n"))
            attributedChangelog.append(NSAttributedString(string: paragraphs[paragraph]!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]))
            attributedChangelog.append(NSAttributedString(string: "\n"))
            attributedChangelog.append(NSAttributedString(string: "\n"))
        }
        
        content.numberOfLines = 0
        content.attributedText = attributedChangelog
        body.addSubview(content)
            
        self.view.addSubviews(body, subButton)
        
        subButton.backgroundColor = GMColor.orange500Color()
        subButton.textColor = .white
        subButton.layer.cornerRadius = 20
        subButton.clipsToBounds = true
        subButton.textAlignment = .center
        subButton.font = UIFont.boldSystemFont(ofSize: 20)
        subButton.text = "Awesome!"
    }
    
    func setupConstraints() {
        body.horizontalAnchors /==/ self.view.horizontalAnchors + 32
        body.bottomAnchor /==/ self.subButton.topAnchor - 4
        body.topAnchor /==/ self.view.topAnchor + 4
        content.edgeAnchors /==/ body.edgeAnchors
        
        self.subButton.bottomAnchor /==/ self.view.bottomAnchor - 8
        self.subButton.horizontalAnchors /==/ self.view.horizontalAnchors + 8
        
        self.subButton.alpha = 0 // Hide for now
        self.subButton.heightAnchor /==/ 0
    }
}

/**
 ViewController for a single page in the OnboardingPageViewController.
 Shows a video with a given resource name.
 */
class OnboardingVideoPageViewController: UIViewController {
    let text: String
    let subText: String
    let video: String
    
    var textView = UILabel()
    var subTextView = UILabel()
    var videoPlayer = AVPlayer()
    let videoContainer = UIView()
    let aspectRatio: Float
    
    var layer: AVPlayerLayer?
    
    var frameSet = false

    init(text: String, subText: String, video: String, aspectRatio: Float) {
        self.text = text
        self.subText = subText
        self.video = video
        self.aspectRatio = aspectRatio
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        self.text = ""
        self.subText = ""
        self.video = ""
        self.aspectRatio = 1
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
            $0.textColor = UIColor.fontColor
            $0.textAlignment = .center
            $0.text = text
            $0.numberOfLines = 0
        }
        self.view.addSubview(textView)
        self.view.addSubview(videoContainer)
        
        self.subTextView = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 15)
            $0.textColor = UIColor.fontColor
            $0.textAlignment = .center
            $0.text = subText
            $0.numberOfLines = 0
        }
        
        self.view.addSubview(subTextView)
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !frameSet {
            frameSet = true
            layer?.frame = videoContainer.bounds
        }
    }

    func setupConstraints() {
        textView.horizontalAnchors /==/ self.view.horizontalAnchors + 16
        textView.topAnchor /==/ self.view.safeTopAnchor + 8
        
        videoContainer.topAnchor /==/ textView.bottomAnchor + 32
        videoContainer.bottomAnchor /==/ self.subTextView.topAnchor - 32
        videoContainer.widthAnchor /==/ self.videoContainer.heightAnchor * aspectRatio
        videoContainer.centerXAnchor /==/ self.view.centerXAnchor
        
        subTextView.bottomAnchor /==/ self.view.safeBottomAnchor - 8
        subTextView.horizontalAnchors /==/ self.view.horizontalAnchors + 16
    }
    
    func startVideos() {
        let bundle = Bundle.main
        if let videoPath = bundle.path(forResource: video, ofType: "mp4") {
            videoPlayer = AVPlayer(url: URL(fileURLWithPath: videoPath))
            layer = AVPlayerLayer(player: videoPlayer)
            
            layer!.needsDisplayOnBoundsChange = true
            layer!.videoGravity = .resizeAspect
            layer!.cornerRadius = 20
            layer!.masksToBounds = true
            
            videoContainer.layer.addSublayer(layer!)
            videoContainer.clipsToBounds = true
            videoContainer.layer.masksToBounds = true
            videoContainer.layer.cornerRadius = 20
            
            videoPlayer.play()
            videoPlayer.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
}
