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
    
    let bubbles = 15
    
    var lanes = [Int](repeating: 0, count: 15)
    
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
        baseView.removeFromSuperview()
        baseView = UIView()
        view.addSubview(baseView)
        
        baseView.centerAnchors == self.view.centerAnchors
        baseView.widthAnchor == CGFloat(bubbles) * 30
        baseView.heightAnchor == CGFloat(bubbles) * 30

        for i in 0..<10 {
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
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = baseView.bounds

        gradientMaskLayer.colors =  [UIColor.clear.cgColor, ColorUtil.theme.foregroundColor.cgColor, ColorUtil.theme.foregroundColor.cgColor, UIColor.clear.cgColor]
        gradientMaskLayer.locations = [0, 0.2, 0.8, 1]
        gradientMaskLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientMaskLayer.endPoint = CGPoint(x: 1, y: 0)

        baseView.layer.mask = gradientMaskLayer
    }
    
    func getInitialFrame(for view: PreviewSubredditView, in lane: Int) -> CGRect {
        print("Lane is \(CGRect(x: CGFloat(bubbles * 30), y: CGFloat(lane) * 30, width: 200, height: 30))")
        return CGRect(x: CGFloat(bubbles * 30), y: CGFloat(lane) * 30, width: 200, height: 30)
    }

    func getFinalFrame(for view: PreviewSubredditView, in lane: Int) -> CGRect {
        return CGRect(x: -1 * 200, y: CGFloat(lane) * 30, width: view.frame.size.width, height: 30)
    }

    func moveView(view: PreviewSubredditView, chosenLane: Int) {
        let time = Int.random(in: 5...10)
        UIView.animate(withDuration: Double(time), delay: 0, options: .curveLinear, animations: { () -> Void in
            view.frame = self.getFinalFrame(for: view, in: chosenLane)
        }, completion: { (Bool) -> Void in
            if self.shouldMove {
                view.randomizeColors()
                self.lanes[chosenLane] -= 1
                var emptyIndexes = [Int]()
                for i in 0..<self.lanes.count {
                    if self.lanes[i] < 1 {
                        emptyIndexes.append(i)
                    }
                }
                
                print("VIew frame is \(view.frame)")

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
        self.textView = UILabel().then {
            $0.font = UIFont.boldSystemFont(ofSize: 20)
            $0.textColor = ColorUtil.theme.fontColor
            $0.textAlignment = .center
            $0.text = text
        }
        
        self.subTextView = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 15)
            $0.textColor = ColorUtil.theme.fontColor
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
        textView.horizontalAnchors == self.view.horizontalAnchors + 16
        textView.topAnchor == self.view.safeTopAnchor + 8
        
        imageView.centerAnchors == self.view.centerAnchors
        imageView.widthAnchor == 100
        imageView.heightAnchor == 100
        
        subTextView.horizontalAnchors == self.view.horizontalAnchors + 16
        subTextView.bottomAnchor == self.view.safeBottomAnchor - 8
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.frame = toSetFrame
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
            self.bubble.backgroundColor = ColorUtil.theme.fontColor
            self.label.backgroundColor = ColorUtil.theme.fontColor
            self.label.alpha = 0.6
        } else if seed < 50 {
            self.bubble.backgroundColor = GMColor.green500Color()
            self.label.backgroundColor = GMColor.green500Color()
            self.label.alpha = 0.6
        } else if seed < 60 {
            self.bubble.backgroundColor = GMColor.red500Color()
            self.label.backgroundColor = GMColor.red500Color()
            self.label.alpha = 0.6
        } else if seed < 70 {
            self.bubble.backgroundColor = GMColor.orange500Color()
            self.label.backgroundColor = GMColor.orange500Color()
            self.label.alpha = 0.6
        } else if seed < 80 {
            self.bubble.backgroundColor = GMColor.yellow500Color()
            self.label.backgroundColor = GMColor.yellow500Color()
            self.label.alpha = 0.6
        } else if seed < 90 {
            self.bubble.backgroundColor = GMColor.purple500Color()
            self.label.backgroundColor = GMColor.purple500Color()
            self.label.alpha = 0.6
        } else {
            self.bubble.backgroundColor = GMColor.blue500Color()
            self.label.backgroundColor = GMColor.blue500Color()
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
        
        bubble.widthAnchor == 30 * scale
        bubble.heightAnchor == 30 * scale
        
        bubble.layer.cornerRadius = 15 * scale
        
        label.widthAnchor == CGFloat(Int.random(in: 40...150)) * scale
        label.heightAnchor == 25 * scale
        label.layer.cornerRadius = 5 * scale
        label.clipsToBounds = true
        
        label.leftAnchor == bubble.rightAnchor + 8 * scale
        label.centerYAnchor == bubble.centerYAnchor
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
            $0.textColor = ColorUtil.theme.fontColor
            $0.textAlignment = .center
            $0.text = text
        }
        
        self.subTextView = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 15)
            $0.textColor = ColorUtil.theme.fontColor
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
        textView.horizontalAnchors == self.view.horizontalAnchors + 16
        textView.topAnchor == self.view.safeTopAnchor + 8
        
        imageView.centerAnchors == self.view.centerAnchors
        imageView.widthAnchor == 100
        imageView.heightAnchor == 100
        
        subTextView.horizontalAnchors == self.view.horizontalAnchors + 16
        subTextView.bottomAnchor == self.view.safeBottomAnchor - 8
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
    let subText: String
    let video: String
    
    var textView = UILabel()
    var subTextView = UILabel()
    var videoPlayer = AVPlayer()
    let videoContainer = UIView()
    let aspectRatio: Float
    
    var layer: AVPlayerLayer?

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
            $0.textColor = ColorUtil.theme.fontColor
            $0.textAlignment = .center
            $0.text = text
            $0.numberOfLines = 0
        }
        self.view.addSubview(textView)
        self.view.addSubview(videoContainer)
        
        self.subTextView = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 15)
            $0.textColor = ColorUtil.theme.fontColor
            $0.textAlignment = .center
            $0.text = subText
            $0.numberOfLines = 0
        }
        
        self.view.addSubview(subTextView)
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        layer?.frame = videoContainer.bounds
    }

    func setupConstraints() {
        textView.horizontalAnchors == self.view.horizontalAnchors + 16
        textView.topAnchor == self.view.safeTopAnchor + 8
        
        videoContainer.topAnchor == textView.bottomAnchor + 8
        videoContainer.bottomAnchor == self.subTextView.topAnchor - 8
        videoContainer.widthAnchor == self.videoContainer.heightAnchor * aspectRatio
        videoContainer.centerXAnchor == self.view.centerXAnchor
        
        subTextView.bottomAnchor == self.view.safeBottomAnchor - 8
        subTextView.horizontalAnchors == self.view.horizontalAnchors + 16
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
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
}
