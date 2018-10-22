//
//  LinkCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/24/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import AVKit
import MaterialComponents
import reddift
import RLBAlertsPickers
import SafariServices
import Then
import TTTAttributedLabel
import UIKit
import XLActionController

protocol LinkCellViewDelegate: class {
    func upvote(_ cell: LinkCellView)
    func downvote(_ cell: LinkCellView)
    func save(_ cell: LinkCellView)
    func more(_ cell: LinkCellView)
    func reply(_ cell: LinkCellView)
    func hide(_ cell: LinkCellView)
    func openComments(id: String, subreddit: String?)
    func deleteSelf(_ cell: LinkCellView)
    func mod(_ cell: LinkCellView)
    func readLater(_ cell: LinkCellView)
}

enum CurrentType {
    case thumb, banner, text, autoplay, none
}

class LinkCellView: UICollectionViewCell, UIViewControllerPreviewingDelegate, TTTAttributedLabelDelegate, UIGestureRecognizerDelegate {
    
    func upvote(sender: UITapGestureRecognizer? = nil) {
        //todo maybe? contentView.blink(color: GMColor.orange500Color())
        del?.upvote(self)
    }
    
    func hide(sender: UITapGestureRecognizer? = nil) {
        del?.hide(self)
    }
    
    func reply(sender: UITapGestureRecognizer? = nil) {
        del?.reply(self)
    }
    
    func downvote(sender: UITapGestureRecognizer? = nil) {
        del?.downvote(self)
    }
    
    func more(sender: UITapGestureRecognizer? = nil) {
        del?.more(self)
    }
    
    func mod(sender: UITapGestureRecognizer? = nil) {
        del?.mod(self)
    }
    
    func save(sender: UITapGestureRecognizer? = nil) {
        del?.save(self)
    }

    func readLater(sender: UITapGestureRecognizer? = nil) {
        del?.readLater(self)
    }
    
    var bannerImage: UIImageView!
    var thumbImageContainer: UIView!
    var thumbImage: UIImageView!
    var title: TTTAttributedLabel!
    var score: UILabel!
    var box: UIStackView!
    var sideButtons: UIStackView!
    var buttons: UIStackView!
    var comments: UILabel!
    var info: UILabel!
    var textView: TextDisplayStackView!
    var save: UIButton!
    var upvote: UIButton!
    var hide: UIButton!
    var edit: UIButton!
    var reply: UIButton!
    var downvote: UIButton!
    var mod: UIButton!
    var readLater: UIButton!
    var commenticon: UIImageView!
    var submissionicon: UIImageView!
    var del: LinkCellViewDelegate?
    var taglabel: UILabel!
    var tagbody: UIView!
    var crosspost: UITableViewCell!
    var sideUpvote: UIButton!
    var sideDownvote: UIButton!
    var sideScore: UILabel!
    
    var videoView: VideoView!
    var topVideoView: UIView!
    var progressDot: UIView!
    var sound: UIButton!
    var updater: CADisplayLink?
    var timeView: UILabel!
    var playView: UIImageView!
    
    var avPlayerItem: AVPlayerItem?
    
    var loadedImage: URL?
    var lq = false
    
    var hasText = false
    
    var full = false
    var infoContainer = UIView()
    var estimatedHeight = CGFloat(0)
    
    var big = false
    var dtap: UIShortTapGestureRecognizer?
    
    var thumb = true
    var submissionHeight: CGFloat = 0
    var addTouch = false
    
    var link: RSubmission?
    var aspectWidth = CGFloat(0.1)
    
    var tempConstraints: [NSLayoutConstraint] = []
    var constraintsForType: [NSLayoutConstraint] = []
    var constraintsForContent: [NSLayoutConstraint] = []
    var bannerHeightConstraint: [NSLayoutConstraint] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureView()
        configureLayout()
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didLongPressLinkWith url: URL!, at point: CGPoint) {
        if parentViewController != nil {
            let alertController: BottomSheetActionController = BottomSheetActionController()
            alertController.headerData = url.host
            
            alertController.addAction(Action(ActionData(title: "Copy URL", image: UIImage(named: "copy")!.menuIcon()), style: .default, handler: { _ in
                UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
            }))
            alertController.addAction(Action(ActionData(title: "Open externally", image: UIImage(named: "nav")!.menuIcon()), style: .default, handler: { _ in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }))
            let open = OpenInChromeController.init()
            if open.isChromeInstalled() {
                alertController.addAction(Action(ActionData(title: "Open in Chrome", image: UIImage(named: "world")!.menuIcon()), style: .default, handler: { _ in
                    _ = open.openInChrome(url, callbackURL: nil, createNewTab: true)
                }))
            }
            parentViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func configureView() {
        
        self.accessibilityIdentifier = "Link Cell View"
        self.contentView.accessibilityIdentifier = "Link Cell Content View"
        
        self.thumbImageContainer = UIView().then {
            $0.accessibilityIdentifier = "Thumbnail Image Container"
            $0.frame = CGRect(x: 0, y: 8, width: (SettingValues.largerThumbnail ? 75 : 50) - (SettingValues.postViewMode == .COMPACT ? 15 : 0), height: (SettingValues.largerThumbnail ? 75 : 50) - (SettingValues.postViewMode == .COMPACT ? 15 : 0))
            if !SettingValues.flatMode {
                $0.elevate(elevation: 2.0)
            }
        }
        
        self.thumbImage = UIImageView().then {
            $0.accessibilityIdentifier = "Thumbnail Image"
            $0.backgroundColor = UIColor.white
            if !SettingValues.flatMode {
                $0.layer.cornerRadius = 10
            }
            if #available(iOS 11.0, *) {
                $0.accessibilityIgnoresInvertColors = true
            }
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
        }
        self.thumbImageContainer.addSubview(self.thumbImage)
        self.thumbImage.edgeAnchors == self.thumbImageContainer.edgeAnchors
        
        self.bannerImage = UIImageView().then {
            $0.accessibilityIdentifier = "Banner Image"
            $0.contentMode = .scaleAspectFill
            if !SettingValues.flatMode {
                $0.layer.cornerRadius = 15
            }
            if #available(iOS 11.0, *) {
                $0.accessibilityIgnoresInvertColors = true
            }
            $0.clipsToBounds = true
            $0.backgroundColor = UIColor.white
        }
        
        self.title = TTTAttributedLabel(frame: CGRect(x: 75, y: 8, width: 0, height: 0)).then {
            $0.accessibilityIdentifier = "Title"
            $0.numberOfLines = 0
            $0.lineBreakMode = .byWordWrapping
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
            $0.verticalAlignment = .top
        }
        
        self.hide = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Hide Button"
            $0.setImage(LinkCellImageCache.hide, for: .normal)
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.reply = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Reply Button"
            $0.setImage(LinkCellImageCache.reply, for: .normal)
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.edit = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Edit Button"
            $0.setImage(LinkCellImageCache.edit, for: .normal)
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.save = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Save Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.upvote = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Upvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.downvote = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Downvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.sideUpvote = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Upvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.sideDownvote = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Downvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.mod = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Mod Button"
            $0.setImage(LinkCellImageCache.mod, for: .normal)
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }

        self.readLater = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Read Later Button"
            $0.setImage(LinkCellImageCache.readLater, for: .normal)
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.commenticon = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10)).then {
            $0.accessibilityIdentifier = "Comment Count Icon"
            $0.image = LinkCellImageCache.commentsIcon
            $0.contentMode = .scaleAspectFit
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.submissionicon = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10)).then {
            $0.accessibilityIdentifier = "Score Icon"
            $0.image = LinkCellImageCache.votesIcon
            $0.contentMode = .scaleAspectFit
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.score = UILabel().then {
            $0.accessibilityIdentifier = "Score Label"
            $0.numberOfLines = 1
            $0.textColor = ColorUtil.fontColor
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.sideScore = UILabel().then {
            $0.accessibilityIdentifier = "Score Label vertical"
            $0.numberOfLines = 1
            $0.textAlignment = .center
            $0.textColor = ColorUtil.fontColor
            $0.isOpaque = false
        }
        
        self.comments = UILabel().then {
            $0.accessibilityIdentifier = "Comment Count Label"
            $0.numberOfLines = 1
            $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
            $0.textColor = ColorUtil.fontColor
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        
        self.taglabel = UILabel().then {
            $0.accessibilityIdentifier = "Tag Label"
            $0.numberOfLines = 1
            $0.font = FontGenerator.boldFontOfSize(size: 12, submission: true)
            $0.textColor = UIColor.black
        }
        
        self.tagbody = taglabel.withPadding(padding: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1)).then {
            $0.accessibilityIdentifier = "Tag Body"
            $0.backgroundColor = UIColor.white
            $0.clipsToBounds = true
            if !SettingValues.flatMode {
                $0.layer.cornerRadius = 4
            }
        }
        
        self.info = UILabel().then {
            $0.accessibilityIdentifier = "Banner Info"
            $0.numberOfLines = 2
            $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
            $0.textColor = .white
        }
        
        self.infoContainer = info.withPadding(padding: UIEdgeInsets.init(top: 4, left: 10, bottom: 4, right: 10)).then {
            $0.accessibilityIdentifier = "Banner Info Container"
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            $0.clipsToBounds = true
            if !SettingValues.flatMode {
                $0.layer.cornerRadius = 15
            }
        }
        
        if self is FullLinkCellView {
            contentView.addSubviews(bannerImage, thumbImageContainer, title, textView, infoContainer, tagbody)
        } else {
            contentView.addSubviews(bannerImage, thumbImageContainer, title, infoContainer, tagbody)
        }
        
        if self is AutoplayBannerLinkCellView || self is FullLinkCellView {
            self.videoView = VideoView().then {
                $0.accessibilityIdentifier = "Video view"
                if !SettingValues.flatMode {
                    $0.layer.cornerRadius = 15
                }
                $0.backgroundColor = .clear
                $0.layer.masksToBounds = true
            }
            
            self.topVideoView = UIView()
            self.progressDot = UIView()
            progressDot.alpha = 0.7
            progressDot.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            sound = UIButton(type: .custom)
            sound.isUserInteractionEnabled = true
            sound.setImage(UIImage(named: "mute")?.getCopy(withSize: CGSize.square(size: 20), withColor: GMColor.red400Color()), for: .normal)
            
            timeView = UILabel().then {
                $0.textColor = .white
                $0.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: 5)
                $0.textAlignment = .center
                $0.alpha = 0.6
                $0.layer.cornerRadius = 5
                $0.clipsToBounds = true
                //$0.textContainerInset = UIEdgeInsetsMake(2, 2, 2, 2)
                $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            }
            
            topVideoView.addSubviews(progressDot, sound, timeView)
            
            contentView.addSubviews(videoView, topVideoView)
            contentView.bringSubview(toFront: videoView)
            contentView.bringSubview(toFront: topVideoView)
            
            playView = UIImageView().then {
                    $0.image = UIImage(named: "play")?.getCopy(withSize: CGSize.square(size: 60), withColor: .white)
                    $0.contentMode = .center
                    $0.isHidden = true
            }
            topVideoView.addSubview(playView)
        }
        
        contentView.layer.masksToBounds = true
        
        if SettingValues.actionBarMode == .FULL || full {
            self.box = UIStackView().then {
                $0.accessibilityIdentifier = "Count Info Stack Horizontal"
                $0.axis = .horizontal
                $0.alignment = .center
            }
            
            box.addArrangedSubviews(submissionicon, horizontalSpace(2), score, horizontalSpace(8), commenticon, horizontalSpace(2), comments)
            self.contentView.addSubview(box)
            
            self.buttons = UIStackView().then {
                $0.accessibilityIdentifier = "Button Stack Horizontal"
                $0.axis = .horizontal
                $0.alignment = .center
                $0.distribution = .fill
                $0.spacing = 16
            }
            buttons.addArrangedSubviews(edit, reply, readLater, save, hide, upvote, downvote, mod)
            self.contentView.addSubview(buttons)
        } else {
            buttons = UIStackView()
            box = UIStackView()
        }
        
        if SettingValues.actionBarMode.isSide() && !full {
            self.sideButtons = UIStackView().then {
                $0.accessibilityIdentifier = "Button Stack Vertical"
                $0.axis = .vertical
                $0.alignment = .center
                $0.distribution = .fill
                $0.spacing = 1
            }
            sideButtons.addArrangedSubviews(sideUpvote, sideScore, sideDownvote)
            sideScore.textAlignment = .center
            self.contentView.addSubview(sideButtons)
        } else {
            sideButtons = UIStackView()
        }
        
        if !addTouch {
            save.addTarget(self, action: #selector(LinkCellView.save(sender:)), for: .touchUpInside)
            upvote.addTarget(self, action: #selector(LinkCellView.upvote(sender:)), for: .touchUpInside)
            if SettingValues.actionBarMode.isSide() {
                sideUpvote.addTarget(self, action: #selector(LinkCellView.upvote(sender:)), for: .touchUpInside)
                sideDownvote.addTarget(self, action: #selector(LinkCellView.downvote(sender:)), for: .touchUpInside)
            }
            reply.addTarget(self, action: #selector(LinkCellView.reply(sender:)), for: .touchUpInside)
            downvote.addTarget(self, action: #selector(LinkCellView.downvote(sender:)), for: .touchUpInside)
            mod.addTarget(self, action: #selector(LinkCellView.mod(sender:)), for: .touchUpInside)
            readLater.addTarget(self, action: #selector(readLater(sender:)), for: .touchUpInside)
            edit.addTarget(self, action: #selector(LinkCellView.edit(sender:)), for: .touchUpInside)
            hide.addTarget(self, action: #selector(LinkCellView.hide(sender:)), for: .touchUpInside)
            sideUpvote.addTarget(self, action: #selector(LinkCellView.upvote(sender:)), for: .touchUpInside)
            
            addTouch(view: thumbImage, action: #selector(LinkCellView.openLink(sender:)))
            let tap = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openLink(sender:)))
            tap.delegate = self
            bannerImage.addGestureRecognizer(tap)
            
            let tap2 = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openLink(sender:)))
            tap2.delegate = self
            infoContainer.addGestureRecognizer(tap2)
            
            if videoView != nil {
                topVideoView.isUserInteractionEnabled = true
                videoView.isUserInteractionEnabled = false
                let tap3 = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openLinkVideo(sender:)))
                tap3.delegate = self
                topVideoView.addGestureRecognizer(tap3)
            }
            
            if dtap == nil && SettingValues.submissionActionDoubleTap != .NONE {
                dtap = UIShortTapGestureRecognizer.init(target: self, action: #selector(self.doDTap(_:)))
                dtap!.numberOfTapsRequired = 2
                self.contentView.addGestureRecognizer(dtap!)
            }
            
            if !full {
                let comment = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openComment(sender:)))
                comment.delegate = self
                if dtap != nil {
                    comment.require(toFail: dtap!)
                }
                self.addGestureRecognizer(comment)
            }
            if longPress == nil {
                longPress = UILongPressGestureRecognizer(target: self, action: #selector(LinkCellView.handleLongPress(_:)))
                longPress?.minimumPressDuration = 0.25
                longPress?.delegate = self
                if full {
                    textView.parentLongPress = longPress!
                }
                self.contentView.addGestureRecognizer(longPress!)
            }
            addTouch = true
        }
        
        sideButtons.isHidden = !SettingValues.actionBarMode.isSide() || full
        buttons.isHidden = SettingValues.actionBarMode != .FULL && !full
        buttons.isUserInteractionEnabled = SettingValues.actionBarMode != .FULL || full
    }
    
    var progressBar: ProgressBarView!
    var typeImage: UIImageView!
    var previousTranslation: CGFloat = 0
    var previousProgress: Float!
    var dragCancelled = false
    var direction = 0
    
    func handlePan(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began || progressBar == nil {
            dragCancelled = false
            direction = 0
            progressBar = ProgressBarView(frame: contentView.bounds).then {
                $0.accessibilityIdentifier = "Progress Bar"
                if !SettingValues.flatMode {
                    $0.layer.cornerRadius = 15
                    $0.clipsToBounds = true
                }
            }
            typeImage = UIImageView().then {
                $0.accessibilityIdentifier = "Action type"
                $0.layer.cornerRadius = 22.5
                $0.clipsToBounds = true
                $0.contentMode = .center
            }
            previousTranslation = 0
            previousProgress = 0
        }
        
        if dragCancelled {
            return
        }
        let xVelocity = sender.velocity(in: contentView).x
        if sender.state != .ended && sender.state != .began {
            guard previousProgress != 1 else { return }
            let posx = sender.location(in: contentView).x
            
            if direction == 0 {
                if xVelocity > 0 {
                    direction = 1
                    progressBar.setMode(type: SettingValues.submissionActionRight, flip: false)
                    typeImage.image = UIImage(named: SettingValues.submissionActionRight.getPhoto())?.getCopy(withSize: CGSize.square(size: 30), withColor: .white)
                    typeImage.backgroundColor = SettingValues.submissionActionRight.getColor()
                } else {
                    direction = -1
                    progressBar.setMode(type: SettingValues.submissionActionLeft, flip: true)
                    typeImage.image = UIImage(named: SettingValues.submissionActionLeft.getPhoto())?.getCopy(withSize: CGSize.square(size: 30), withColor: .white)
                    typeImage.backgroundColor = SettingValues.submissionActionLeft.getColor()
                }
            }
            
            if (direction == -1 && SettingValues.submissionActionLeft == .NONE) || (direction == 1 && SettingValues.submissionActionRight == .NONE) {
                dragCancelled = true
                sender.cancel()
                return
            } else if progressBar.superview == nil {
                contentView.addSubviews(typeImage, progressBar)
                contentView.bringSubview(toFront: typeImage)
                typeImage.centerAnchors == self.contentView.centerAnchors
                typeImage.heightAnchor == 45
                typeImage.widthAnchor == 45
            }
            
            let currentTranslation = direction == -1 ? 0 - (contentView.bounds.size.width - posx) : posx
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressBar.progress = Float(min(abs(currentTranslation) / (contentView.bounds.width), 1))
            CATransaction.commit()

            let currentProgress = progressBar.progress
            if currentProgress >= 0.5 && previousProgress < 0.5 || sender.state == .ended {
                if #available(iOS 10.0, *) {
                    HapticUtility.hapticActionStrong()
                }
            }
            typeImage.alpha = CGFloat(currentProgress)
            previousTranslation = currentTranslation
            previousProgress = currentProgress
        } else if sender.state == .ended && (progressBar.progress >= 0.5 || ((xVelocity > 0 && direction == 1 || xVelocity < 0 && direction == -1) && abs(xVelocity) > 1000)) {
            self.progressBar.progressLayer.strokeEnd = 1
            doAction(item: progressBar.progressType!)
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.typeImage.alpha = 0
                self.progressBar.alpha = 0
                self.typeImage.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }, completion: { (_) in
                self.progressBar.removeFromSuperview()
                self.typeImage.removeFromSuperview()
            })
        } else if sender.state != .began {
            if self.progressBar.superview == nil {
                return
            }
            self.progressBar.progressLayer.strokeEnd = 0
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.progressBar.alpha = 0
                self.typeImage.alpha = 0
            }, completion: { (_) in
                self.progressBar.removeFromSuperview()
                self.typeImage.removeFromSuperview()
            })
        }
    
        if dragCancelled {
            if self.progressBar.superview == nil {
                return
            }
            self.progressBar.progressLayer.strokeEnd = 0
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                self.typeImage.alpha = 0
                self.progressBar.alpha = 0
            }, completion: { (_) in
                self.progressBar.removeFromSuperview()
                self.typeImage.removeFromSuperview()
            })
        }
    }
    
    func updateProgress(_ oldPercent: CGFloat, _ total: String, buffering: Bool) {
        var percent = oldPercent
        if percent == -1 {
            percent = 1
        }
        let startAngle = -CGFloat.pi / 2
        
        let center = CGPoint (x: 20 / 2, y: 20 / 2)
        let radius = CGFloat(20 / 2)
        let arc = CGFloat.pi * CGFloat(2) * percent
        
        let cPath = UIBezierPath()
        cPath.move(to: center)
        cPath.addLine(to: CGPoint(x: center.x + radius * cos(startAngle), y: center.y + radius * sin(startAngle)))
        cPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: arc + startAngle, clockwise: true)
        cPath.addLine(to: CGPoint(x: center.x, y: center.y))
        
        let circleShape = CAShapeLayer()
        circleShape.path = cPath.cgPath
        circleShape.strokeColor = UIColor.white.cgColor
        circleShape.fillColor = UIColor.white.cgColor
        circleShape.lineWidth = 1.5
        // add sublayer
        for layer in progressDot.layer.sublayers ?? [CALayer]() {
            layer.removeFromSuperlayer()
        }

        if !buffering {
            progressDot.layer.removeAllAnimations()
            progressDot.layer.addSublayer(circleShape)
        }
        
        if timeView.isHidden {
            timeView.isHidden = false
        }
        timeView.text = "\(total)  "
        
        if oldPercent == -1 || (buffering && progressDot.layer.animation(forKey: "opacity") == nil) {
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.duration = 0.5
            pulseAnimation.toValue = 1.2
            pulseAnimation.fromValue = 0.2
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            pulseAnimation.autoreverses = false
            pulseAnimation.repeatCount = Float.greatestFiniteMagnitude
            
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.duration = 0.5
            fadeAnimation.toValue = 0
            fadeAnimation.fromValue = 2.5
            fadeAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            fadeAnimation.autoreverses = false
            fadeAnimation.repeatCount = Float.greatestFiniteMagnitude
            
            progressDot.layer.add(pulseAnimation, forKey: "scale")
            progressDot.layer.add(fadeAnimation, forKey: "fade")
        } else if !buffering {
            timeView.isHidden = false
        }
    }
    
    func doConstraints() {
        //        var target: CurrentType = .none
        //
        //        if (thumb && !big) {
        //            target = .thumb
        //        } else if (big) {
        //            target = .banner
        //        } else {
        //            target = .text
        //        }
        //
        //        configureForType(target)
    }
    
    // Reconfigures the layout of the cell.
    func configureLayout() {
        let ceight = SettingValues.postViewMode == .COMPACT ? CGFloat(4) : CGFloat(8)
        let ctwelve = SettingValues.postViewMode == .COMPACT ? CGFloat(8) : CGFloat(12)
        
        if videoView != nil {
            progressDot.widthAnchor == 20
            progressDot.heightAnchor == 20
            progressDot.leftAnchor == topVideoView.leftAnchor + 8
            progressDot.bottomAnchor == topVideoView.bottomAnchor - 8
            progressDot.layer.cornerRadius = 10
            progressDot.clipsToBounds = true
            
            timeView.leftAnchor == progressDot.rightAnchor + 8
            timeView.bottomAnchor == topVideoView.bottomAnchor - 8
            timeView.heightAnchor == 20
            timeView.isHidden = true
            
            sound.widthAnchor == 30
            sound.heightAnchor == 30
            sound.rightAnchor == topVideoView.rightAnchor
            sound.bottomAnchor == topVideoView.bottomAnchor
            
            playView.widthAnchor == 70
            playView.heightAnchor == 70
            playView.centerAnchors == topVideoView.centerAnchors
            playView.clipsToBounds = true
            playView.layer.cornerRadius = 35
            playView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
        
        // Remove all constraints previously applied by this method
        NSLayoutConstraint.deactivate(tempConstraints)
        tempConstraints = []
        
        tempConstraints = batch {
            var topmargin = 0
            var bottommargin = 2
            var leftmargin = 0
            var rightmargin = 0
            var radius = 0
            
            if (SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full {
                topmargin = 5
                bottommargin = 5
                leftmargin = 5
                rightmargin = 5
                radius = 15
            }
            
            self.contentView.layoutMargins = UIEdgeInsets.init(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin))
            
            if !SettingValues.flatMode {
                self.contentView.layer.cornerRadius = CGFloat(radius)
                self.contentView.clipsToBounds = false
            }
            
            if SettingValues.actionBarMode == .FULL || full {
                box.leftAnchor == contentView.leftAnchor + ctwelve
                box.bottomAnchor == contentView.bottomAnchor - ceight
                box.centerYAnchor == buttons.centerYAnchor // Align vertically with buttons
                box.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
                box.heightAnchor == CGFloat(24)
                buttons.heightAnchor == CGFloat(24)
                buttons.rightAnchor == contentView.rightAnchor - ctwelve
                buttons.bottomAnchor == contentView.bottomAnchor - ceight
                buttons.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
            } else if SettingValues.actionBarMode.isSide() {
                if SettingValues.actionBarMode == .SIDE_RIGHT {
                    sideButtons.rightAnchor == contentView.rightAnchor - ceight
                } else {
                    sideButtons.leftAnchor == contentView.leftAnchor + ceight
                }
                sideScore.widthAnchor == CGFloat(40)
                sideButtons.widthAnchor == CGFloat(40)
            }
            
            title.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        }
        
        if !full {
            layoutForType()
            layoutForContent()
        }
    }
    
    internal func layoutForType() {
        
        thumbImageContainer.isHidden = true
        bannerImage.isHidden = true
        
        // Remove all constraints previously applied by this method
        NSLayoutConstraint.deactivate(constraintsForType)
        constraintsForType = []
        
        // Deriving classes will populate constraintsForType in the override for this method.
        
    }
    
    internal func layoutForContent() {
        
        // Remove all constraints previously applied by this method
        NSLayoutConstraint.deactivate(constraintsForContent)
        constraintsForContent = []
        
        // Deriving classes will populate constraintsForContent in the override for this method.
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        let insets = CGSize(width: -10, height: -15)

        func didHit(_ view: UIView) -> Bool {
            let convertedPoint = view.convert(point, from: self)
            return view.bounds.insetBy(dx: insets.width, dy: insets.height).contains(convertedPoint)
        }

        var testedViews: [UIView] = [
            upvote,
            downvote,
            mod,
            readLater,
            save,
            hide,
            reply,
            edit,
        ]

        if SettingValues.actionBarMode.isSide() {
            testedViews += [
                sideUpvote,
                sideDownvote,
            ]
        }

        return testedViews.first(where: didHit) ?? super.hitTest(point, with: event)
    }
    
    deinit {
        if videoView != nil {
            videoView?.player?.currentItem?.asset.cancelLoading()
            videoView?.player?.currentItem?.cancelPendingSeeks()
            updater?.invalidate()
        }
    }
    
    func configure(submission: RSubmission, parent: UIViewController & MediaVCDelegate, nav: UIViewController?, baseSub: String, test: Bool = false, parentWidth: CGFloat = 0) {
        self.link = submission
        self.setLink(submission: submission, parent: parent, nav: nav, baseSub: baseSub, test: test, parentWidth: parentWidth)
        layoutForContent()
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if (parentViewController) != nil {
            parentViewController?.doShow(url: url, heroView: nil, heroVC: nil)
        }
    }
    
    func showBody(width: CGFloat) {
        full = true
        textView.isHidden = false
        let link = self.link!
        let color = ColorUtil.accentColorForSub(sub: ((link).subreddit))
        self.textView.setColor(color)
        hasText = true
        textView.estimatedWidth = width
        textView.estimatedHeight = 0
        textView.setTextWithTitleHTML(NSMutableAttributedString(), htmlString: link.htmlBody)
    }
    
    func addTouch(view: UIView, action: Selector) {
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: action)
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    func getHeightFromAspectRatio(imageHeight: CGFloat, imageWidth: CGFloat, viewWidth: CGFloat) -> CGFloat {
        let ratio = imageHeight / imageWidth
        return viewWidth * ratio
    }

    func refreshLink(_ submission: RSubmission) {
        self.link = submission
        
        title.setText(CachedTitle.getTitle(submission: submission, full: full, true, false))
        title.delegate = self
        
        if dtap == nil && SettingValues.submissionActionDoubleTap != .NONE {
            dtap = UIShortTapGestureRecognizer.init(target: self, action: #selector(self.doDTap(_:)))
            dtap!.numberOfTapsRequired = 2
            self.addGestureRecognizer(dtap!)
        }
        
        if !full {
            let comment = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openComment(sender:)))
            comment.delegate = self
            if dtap != nil {
                comment.require(toFail: dtap!)
            }
            self.addGestureRecognizer(comment)
        }
        
        refresh()
        let more = History.commentsSince(s: submission)
        comments.text = " \(submission.commentCount)\(more > 0 ? " (+\(more))" : "")"
    }
    
    func refreshTitle() {
        title.setText(CachedTitle.getTitle(submission: self.link!, full: full, true, false))
    }
    
    func doDTap(_ sender: AnyObject) {
        typeImage = UIImageView().then {
            $0.accessibilityIdentifier = "Action type"
            $0.layer.cornerRadius = 22.5
            $0.clipsToBounds = true
            $0.contentMode = .center
        }
        let overView = UIView()
        if !SettingValues.flatMode {
            overView.layer.cornerRadius = 15
            overView.clipsToBounds = true
        }
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionStrong()
        }
        typeImage.image = UIImage(named: SettingValues.submissionActionDoubleTap.getPhoto())?.getCopy(withSize: CGSize.square(size: 30), withColor: .white)
        typeImage.backgroundColor = SettingValues.submissionActionDoubleTap.getColor()
        contentView.addSubviews(typeImage, overView)
        contentView.bringSubview(toFront: overView)
        contentView.bringSubview(toFront: typeImage)
        overView.backgroundColor = SettingValues.submissionActionDoubleTap.getColor()
        overView.edgeAnchors == self.contentView.edgeAnchors
        typeImage.centerAnchors == self.contentView.centerAnchors
        typeImage.heightAnchor == 45
        typeImage.widthAnchor == 45
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.typeImage.alpha = 0
            overView.alpha = 0
            self.typeImage.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }, completion: { (_) in
            self.typeImage.removeFromSuperview()
            overView.removeFromSuperview()
        })
        doAction(item: SettingValues.submissionActionDoubleTap)
    }
    
    func doAction(item: SettingValues.SubmissionAction) {
        switch item {
        case .UPVOTE:
            self.upvote()
        case .DOWNVOTE:
            self.downvote()
        case .SAVE:
            self.save()
        case .MENU:
            self.more()
        case .HIDE:
            if !full {
                self.hide()
            }
        case .SUBREDDIT:
            let sub = SingleSubredditViewController.init(subName: self.link!.subreddit, single: true)
            VCPresenter.showVC(viewController: sub, popupIfPossible: false, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
        case .AUTHOR:
            let profile = ProfileViewController.init(name: self.link!.author)
            VCPresenter.showVC(viewController: profile, popupIfPossible: false, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
        case .READ_LATER:
            self.readLater()
        case .EXTERNAL:
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(self.link!.url ?? URL(string: self.link!.permalink)!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(self.link!.url ?? URL(string: self.link!.permalink)!)
            }
        case .SHARE:
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [self.link!.url ?? URL(string: self.link!.permalink)!], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = self.contentView
                presenter.sourceRect = self.contentView.bounds
            }
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil)
        default:
            break
        }
    }
    
    var aspect = CGFloat(1)
    var type: ContentType.CType = .NONE
    var activeSet = false
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UIButton)
    }
    
    private func setLink(submission: RSubmission, parent: UIViewController & MediaVCDelegate, nav: UIViewController?, baseSub: String, test: Bool = false, parentWidth: CGFloat = 0) {
        loadedImage = nil
        full = parent is CommentViewController
        lq = false
        if true || full { //todo logic for this
            self.contentView.backgroundColor = ColorUtil.foregroundColor
            comments.textColor = ColorUtil.fontColor
            title.textColor = ColorUtil.fontColor
        } else {
            self.contentView.backgroundColor = ColorUtil.getColorForSubBackground(sub: submission.subreddit)
            comments.textColor = .white
            title.textColor = .white
        }
        
        parentViewController = parent
        self.link = submission
        if navViewController == nil && nav != nil {
            navViewController = nav
        }
        
        let activeLinkAttributes = NSMutableDictionary(dictionary: title.activeLinkAttributes)
        activeLinkAttributes[kCTForegroundColorAttributeName] = ColorUtil.accentColorForSub(sub: submission.subreddit)
        title.activeLinkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
        title.linkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
        activeSet = true
        
        title.setText(CachedTitle.getTitle(submission: submission, full: full, false, false))
        
        reply.isHidden = true

        hide.isHidden = !SettingValues.hideButton
        mod.isHidden = true
        save.isHidden = !SettingValues.saveButton
        readLater.isHidden = !SettingValues.readLaterButton

        if submission.archived || !AccountController.isLoggedIn || !LinkCellView.checkInternet() {
            upvote.isHidden = true
            downvote.isHidden = true
            if submission.archived && AccountController.isLoggedIn && LinkCellView.checkInternet() {
                save.isHidden = false
            } else {
                save.isHidden = true
            }
            reply.isHidden = true
            edit.isHidden = true
            sideUpvote.isHidden = true
            sideDownvote.isHidden = true
        } else {
            upvote.isHidden = false
            downvote.isHidden = false
            sideUpvote.isHidden = false
            sideDownvote.isHidden = false
            
            if submission.canMod {
                mod.isHidden = false
                if !submission.reports.isEmpty {
                    mod.setImage(LinkCellImageCache.modTinted, for: .normal)
                } else {
                    mod.setImage(LinkCellImageCache.mod, for: .normal)
                }
            }
            
            if full {
                reply.isHidden = false
                hide.isHidden = true
            }
            edit.isHidden = true
        }
        
        full = parent is CommentViewController
        
        if !submission.archived && AccountController.isLoggedIn && AccountController.currentName == submission.author && full {
            edit.isHidden = false
        }
        
        thumb = submission.thumbnail
        big = submission.banner
        
        submissionHeight = CGFloat(submission.height)
        
        type = test && SettingValues.linkAlwaysThumbnail ? ContentType.CType.LINK : ContentType.getContentType(baseUrl: submission.url)
        if submission.isSelf {
            type = .SELF
        }
        
        if SettingValues.postImageMode == .THUMBNAIL && !full {
            big = false
            thumb = true
        }
        
        let fullImage = ContentType.fullImage(t: type)
        let shouldAutoplay = SettingValues.shouldAutoPlay()
        
        let overrideFull = ContentType.displayVideo(t: type) && type != .VIDEO && (self is AutoplayBannerLinkCellView || self is FullLinkCellView) && shouldAutoplay

        if !fullImage && submissionHeight < 50 {
            big = false
            thumb = true
        } else if big && ((!full && SettingValues.postImageMode == .CROPPED_IMAGE) || (full && !SettingValues.commentFullScreen)) && !overrideFull {
            submissionHeight = test ? 150 : 200
        } else if big {
            let h = getHeightFromAspectRatio(imageHeight: submissionHeight, imageWidth: CGFloat(submission.width), viewWidth: parentWidth == 0 ? (contentView.frame.size.width == 0 ? CGFloat(submission.width) : contentView.frame.size.width) : parentWidth)
            if h == 0 {
                submissionHeight = test ? 150 : 200
            } else {
                submissionHeight = h
            }
        }
        
        if SettingValues.actionBarMode != .FULL && !full {
            buttons.isHidden = true
            box.isHidden = true
        }
        
        if type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big || type == .SELF && full {
            big = false
            thumb = false
        }
        
        if submissionHeight < 50 {
            thumb = true
            big = false
        }
        let checkWifi = LinkCellView.checkWiFi()
        let shouldShowLq = SettingValues.dataSavingEnabled && submission.lQ && !(SettingValues.dataSavingDisableWiFi && checkWifi)
        if type == ContentType.CType.SELF && SettingValues.hideImageSelftext
            || SettingValues.noImages && submission.isSelf {
            big = false
            thumb = false
        }
        
        if big || !submission.thumbnail {
            thumb = false
        }
        
        if submission.nsfw && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection && Subscriptions.isCollection(baseSub)) {
            big = false
            thumb = true
        }
        
        if type == .LINK && SettingValues.linkAlwaysThumbnail {
            thumb = true
            big = false
        }
        
        if SettingValues.noImages {
            big = false
            thumb = false
        }
        
        if thumb && type == .SELF {
            thumb = false
        }
        
        if (thumb || big) && submission.spoiler {
            thumb = true
            big = false
        }
        
        if full && big {
            let bannerPadding = CGFloat(5)
            submissionHeight = getHeightFromAspectRatio(imageHeight: submissionHeight == 200 ? CGFloat(200) : CGFloat(submission.height), imageWidth: CGFloat(submission.width), viewWidth: (parentWidth == 0 ? (contentView.frame.size.width == 0 ? CGFloat(submission.width) : contentView.frame.size.width) : parentWidth) - (bannerPadding * 2))
        }
        
        if !big && !thumb && submission.type != .SELF && submission.type != .NONE { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
            if submission.nsfw {
                thumbImage.image = LinkCellImageCache.nsfw
            } else if submission.spoiler {
                thumbImage.image = LinkCellImageCache.spoiler
            } else if type == .REDDIT {
                thumbImage.image = LinkCellImageCache.reddit
            } else {
                thumbImage.image = LinkCellImageCache.web
            }
        } else if thumb && !big {
            if submission.nsfw && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection && Subscriptions.isCollection(baseSub)) {
                thumbImage.image = LinkCellImageCache.nsfw
            } else if submission.thumbnailUrl == "web" || submission.thumbnailUrl.isEmpty || submission.spoiler {
                if submission.spoiler {
                    thumbImage.image = LinkCellImageCache.spoiler
                } else if type == .REDDIT {
                    thumbImage.image = LinkCellImageCache.reddit
                } else {
                    thumbImage.image = LinkCellImageCache.web
                }
            } else {
                let thumbURL = submission.thumbnailUrl
                DispatchQueue.global(qos: .userInteractive).async {
                    self.thumbImage.sd_setImage(with: URL.init(string: thumbURL), placeholderImage: LinkCellImageCache.web, options: [.allowInvalidSSLCertificates, .scaleDownLargeImages])
                }
            }
        } else {
            thumbImage.sd_setImage(with: URL.init(string: ""))
            self.thumbImage.frame.size.width = 0
        }
        
        if big {
            bannerImage.isHidden = false
            updater?.invalidate()
            var videoOverride = false
            if ContentType.displayVideo(t: type) && type != .VIDEO && (self is AutoplayBannerLinkCellView || (self is FullLinkCellView && shouldAutoplay)) && (SettingValues.autoPlayMode == .ALWAYS || (SettingValues.autoPlayMode == .WIFI && shouldAutoplay)) {
                videoView?.player?.pause()
                videoView?.isHidden = false
                topVideoView?.isHidden = false
                sound.isHidden = true
                self.timeView.isHidden = true
                self.updateProgress(-1, "", buffering: false)
                self.contentView.bringSubview(toFront: topVideoView!)
                doLoadVideo()
                videoOverride = true
            } else if self is FullLinkCellView {
                self.videoView.isHidden = true
                self.topVideoView.isHidden = true
                self.timeView.isHidden = true
                self.progressDot.isHidden = true
            }
            
            if (self is AutoplayBannerLinkCellView || self is FullLinkCellView) && (ContentType.displayVideo(t: type) && type != .VIDEO) && (SettingValues.autoPlayMode == .TAP || (SettingValues.autoPlayMode == .WIFI && !shouldAutoplay)) {
                videoView?.player?.pause()
                videoView?.isHidden = false
                topVideoView?.isHidden = false
                sound.isHidden = true
                self.updateProgress(-1, "", buffering: false)
                self.contentView.bringSubview(toFront: topVideoView!)
                self.playView.isHidden = false
                self.progressDot.isHidden = true
                self.timeView.isHidden = true
                videoOverride = true
            }
            
            bannerImage.alpha = 0
            let imageSize = CGSize.init(width: submission.width, height: ((full && !SettingValues.commentFullScreen) || (!full && SettingValues.postImageMode == .CROPPED_IMAGE)) && !((self is AutoplayBannerLinkCellView || self is FullLinkCellView) && (ContentType.displayVideo(t: type) && type != .VIDEO) && (SettingValues.autoPlayMode == .TAP || (SettingValues.autoPlayMode == .WIFI && !shouldAutoplay))) ? 200 : submission.height)
            
            aspect = imageSize.width / imageSize.height
            if aspect == 0 || aspect > 10000 || aspect.isNaN {
                aspect = 1
            }
            if !videoOverride && ((full && !SettingValues.commentFullScreen) || (!full && SettingValues.postImageMode == .CROPPED_IMAGE)) {
                aspect = (full ? aspectWidth : self.contentView.frame.size.width) / (test ? 150 : 200)
                if aspect == 0 || aspect > 10000 || aspect.isNaN {
                    aspect = 1
                }
                
                submissionHeight = test ? 150 : 200
            }
            bannerImage.isUserInteractionEnabled = true
            if shouldShowLq {
                lq = true
                loadedImage = URL.init(string: submission.lqUrl)
                
                let lqURL = submission.lqUrl
                DispatchQueue.global(qos: .userInteractive).async {
                    self.bannerImage.sd_setImage(with: URL.init(string: lqURL), placeholderImage: nil, options: [.allowInvalidSSLCertificates, .scaleDownLargeImages], completed: { (_, _, cache, _) in
                        if cache == .none {
                            UIView.animate(withDuration: 0.3, animations: {
                                self.bannerImage.alpha = 1
                            })
                        } else {
                            self.bannerImage.alpha = 1
                        }
                    })
                }
            } else {
                loadedImage = URL.init(string: submission.bannerUrl)
                let bannerURL = submission.bannerUrl
                DispatchQueue.global(qos: .userInteractive).async {
                    self.bannerImage.sd_setImage(with: URL.init(string: bannerURL), placeholderImage: nil, options: [.allowInvalidSSLCertificates, .scaleDownLargeImages], completed: { (_, _, cache, _) in
                        if cache == .none {
                            UIView.animate(withDuration: 0.3, animations: {
                                self.bannerImage.alpha = 1
                            })
                        } else {
                            self.bannerImage.alpha = 1
                        }
                    })
                }
            }
            
            NSLayoutConstraint.deactivate(self.bannerHeightConstraint)
            self.bannerHeightConstraint = batch {
                self.bannerImage.heightAnchor == self.submissionHeight ~ .low
            }
        } else {
            bannerImage.sd_setImage(with: URL.init(string: ""))
            if self is FullLinkCellView {
                self.videoView.isHidden = true
                self.topVideoView.isHidden = true
                self.timeView.isHidden = true
                self.progressDot.isHidden = true
            }
        }
        
        if !full && !test {
            aspectWidth = self.contentView.frame.size.width
        }
        
        let mo = History.commentsSince(s: submission)
        comments.text = " \(submission.commentCount)" + (mo > 0 ? "(+\(mo))" : "")
        
        if !registered && !full {
            parent.registerForPreviewing(with: self, sourceView: self.contentView)
            registered = true
        }
        
        refresh()
        
        if (type != .IMAGE && type != .SELF && !thumb) || full {
            infoContainer.isHidden = false
            var text = ""
            switch type {
            case .ALBUM:
                text = ("Album")
            case .EXTERNAL:
                text = "External Link"
            case .LINK, .EMBEDDED, .NONE:
                text = "Link"
            case .DEVIANTART:
                text = "Deviantart"
            case .TUMBLR:
                text = "Tumblr"
            case .XKCD:
                text = ("XKCD")
            case .GIF:
                if submission.domain == "v.redd.it" {
                    text = "Reddit Video"
                } else {
                    text = ("GIF")
                }
            case .IMGUR:
                text = ("Imgur")
            case .VIDEO:
                text = "YouTube"
            case .STREAMABLE:
                text = "Streamable"
            case .VID_ME:
                text = ("Vid.me")
            case .REDDIT:
                text = ("Reddit content")
            default:
                text = "Link"
            }
            
            if SettingValues.smallerTag && !full {
                infoContainer.isHidden = true
                tagbody.isHidden = false
                taglabel.text = " \(text.uppercased()) "
            } else {
                tagbody.isHidden = true
                if submission.isCrosspost && full {
                    let colorF = UIColor.white
                    
                    let finalText = NSMutableAttributedString.init(string: "Crosspost - " + submission.domain, attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 14, submission: true)])
                    
                    let endString = NSMutableAttributedString(string: "\nOriginal submission by ", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])
                    let by = NSMutableAttributedString(string: " in ", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])
                    
                    let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: submission.author, small: false))\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])
                    
                    let userColor = ColorUtil.getColorForUser(name: submission.crosspostAuthor)
                    if AccountController.currentName == submission.author {
                        authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
                    } else if userColor != ColorUtil.baseColor {
                        authorString.addAttributes([kTTTBackgroundFillColorAttributeName: userColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
                    }
                    
                    endString.append(authorString)
                    endString.append(by)
                    
                    let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF] as [String: Any]
                    
                    let boldString = NSMutableAttributedString(string: "r/\(submission.crosspostSubreddit)", attributes: attrs)
                    
                    let color = ColorUtil.getColorForSub(sub: submission.crosspostSubreddit)
                    if color != ColorUtil.baseColor {
                        boldString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: boldString.length))
                    }
                    
                    endString.append(boldString)
                    finalText.append(endString)
                    
                    infoContainer.addTapGestureRecognizer {
                        VCPresenter.openRedditLink(submission.crosspostPermalink, self.parentViewController?.navigationController, self.parentViewController)
                    }
                    info.attributedText = finalText
                    
                } else {
                    let finalText = NSMutableAttributedString.init(string: text, attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 14, submission: true)])
                    finalText.append(NSAttributedString.init(string: "\n\(submission.domain)"))
                    info.attributedText = finalText
                }
            }
            
        } else {
            infoContainer.isHidden = true
            tagbody.isHidden = true
        }
        
        //todo maybe? self.contentView.backgroundColor = ColorUtil.getColorForSub(sub: submission.subreddit)
        if full {
            self.setNeedsLayout()
            self.layoutForType()
        }
    }
    
    var currentType: CurrentType = .none
    
    public static func checkWiFi() -> Bool {
        
        let networkStatus = Reachability().connectionStatus()
        switch networkStatus {
        case .Unknown, .Offline:
            return false
        case .Online(.WWAN):
            return false
        case .Online(.WiFi):
            return true
        }
    }
    
    func doLoadVideo() {
        let baseUrl: URL
        if !link!.videoPreview.isEmpty() && !ContentType.isGfycat(uri: link!.url!) {
            baseUrl = URL.init(string: link!.videoPreview)!
        } else {
            baseUrl = link!.url!
        }
        let url = VideoMediaViewController.format(sS: baseUrl.absoluteString, true)
        let videoType = VideoMediaViewController.VideoType.fromPath(url)
        videoType.getSourceObject().load(url: url, completion: { [weak self] (urlString) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.avPlayerItem = AVPlayerItem(url: URL(string: urlString)!)
                strongSelf.videoView?.player = AVPlayer(playerItem: strongSelf.avPlayerItem!)
                strongSelf.videoView?.player?.actionAtItemEnd = AVPlayerActionAtItemEnd.none
                do {
                    if SettingValues.matchSilence {
                        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
                    } else {
                        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    }
                } catch {
                    
                }
//                Is currently causing issues with not resuming after buffering
//                if #available(iOS 10.0, *) {
//                    strongSelf.videoView?.player?.automaticallyWaitsToMinimizeStalling = false
//                }
                strongSelf.videoView?.player?.play()
                strongSelf.videoView?.player?.isMuted = true
                strongSelf.sound.addTarget(strongSelf, action: #selector(strongSelf.unmute), for: .touchUpInside)
                strongSelf.updater = CADisplayLink(target: strongSelf, selector: #selector(strongSelf.displayLinkDidUpdate))
                strongSelf.updater?.add(to: .current, forMode: .defaultRunLoopMode)
                strongSelf.updater?.isPaused = false
                UIView.animate(withDuration: 0.3, animations: {
                    strongSelf.bannerImage.alpha = 0
                }, completion: { (_) in
                    strongSelf.bannerImage.isHidden = true
                    strongSelf.bannerImage.alpha = 1
                })
            }
            }, failure: {
                
        })
    }
    
    public static var cachedInternet: Bool?
    public static func checkInternet() -> Bool {
        if LinkCellView.cachedInternet != nil {
            return LinkCellView.cachedInternet!
        }
        let networkStatus = Reachability().connectionStatus()
        switch networkStatus {
        case .Unknown, .Offline:
            LinkCellView.cachedInternet = false
        case .Online(.WWAN):
            LinkCellView.cachedInternet = true
        case .Online(.WiFi):
            LinkCellView.cachedInternet = true
        }
        return LinkCellView.cachedInternet!
    }
    
    func showMore() {
        timer!.invalidate()
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionStrong()
        } else if SettingValues.hapticFeedback {
            AudioServicesPlaySystemSound(1519)
        }
        if !self.cancelled && LinkCellView.checkInternet() {
            self.more()
        }
    }
    
    var handlingPlayerItemDidreachEnd = false
    
    func playerItemDidreachEnd() {
        self.videoView?.player?.seek(to: CMTimeMake(1, 1000), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            // NOTE: the following is not needed since `strongSelf.videoView.player?.actionAtItemEnd` is set to `AVPlayerActionAtItemEnd.none`
//            if finished {
//                strongSelf.videoView?.player?.play()
//            }
            strongSelf.handlingPlayerItemDidreachEnd = false
        })
    }
    
    var longPress: UILongPressGestureRecognizer?
    var timer: Timer?
    var cancelled = false
    
    private func getTimeString(_ time: Int) -> String {
        let h = time / 3600
        let m = (time % 3600) / 60
        let s = (time % 3600) % 60
        return h > 0 ? String(format: "%1d:%02d:%02d", h, m, s) : String(format: "%1d:%02d", m, s)
    }
    
    func displayLinkDidUpdate(displaylink: CADisplayLink) {
        if sound.isHidden && (self.videoView.player?.isMuted ?? false) && (self.videoView.player?.currentItem?.tracks.count ?? 1) > 1 {
            sound.isHidden = false
        }
        if let player = videoView.player {
            let elapsedTime = player.currentTime()
            if CMTIME_IS_INVALID(elapsedTime) {
                return
            }
            let duration = Float(CMTimeGetSeconds(player.currentItem!.duration))
            let time = Float(CMTimeGetSeconds(elapsedTime))
            
            if duration.isFinite && duration > 0 {
                updateProgress(CGFloat(time / duration), "\(getTimeString(Int(floor(1 + duration - time))))", buffering: !(self.videoView.player?.currentItem?.isPlaybackLikelyToKeepUp ?? true))
            }
            if !handlingPlayerItemDidreachEnd && (time / duration) >= 0.99 {
                handlingPlayerItemDidreachEnd = true
                self.playerItemDidreachEnd()
            }
        }
    }
    
    func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            cancelled = false
            timer = Timer.scheduledTimer(timeInterval: 0.25,
                                         target: self,
                                         selector: #selector(self.showMore),
                                         userInfo: nil,
                                         repeats: false)
            
        }
        if sender.state == UIGestureRecognizerState.ended {
            timer!.invalidate()
            cancelled = true
        }
    }
    
    func edit(sender: AnyObject) {
        let link = self.link!
        
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Edit your submission"
        
        if link.isSelf {
            alertController.addAction(Action(ActionData(title: "Edit selftext", image: UIImage(named: "edit")!.menuIcon()), style: .default, handler: { _ in
                self.editSelftext()
            }))
        }
        
        alertController.addAction(Action(ActionData(title: "Flair submission", image: UIImage(named: "size")!.menuIcon()), style: .default, handler: { _ in
            self.flairSelf()
            
        }))
        
        alertController.addAction(Action(ActionData(title: "Delete submission", image: UIImage(named: "delete")!.menuIcon()), style: .default, handler: { _ in
            self.deleteSelf(self)
        }))
        
        VCPresenter.presentAlert(alertController, parentVC: parentViewController!)
    }
    
    func editSelftext() {
        let reply = ReplyViewController.init(submission: link!, sub: (self.link?.subreddit)!) { (cr) in
            DispatchQueue.main.async(execute: { () -> Void in
                self.setLink(submission: RealmDataWrapper.linkToRSubmission(submission: cr!), parent: self.parentViewController!, nav: self.navViewController!, baseSub: (self.link?.subreddit)!)
                self.showBody(width: self.contentView.frame.size.width - 24)
            })
        }
        
        let navEditorViewController: UINavigationController = UINavigationController(rootViewController: reply)
        parentViewController?.present(navEditorViewController, animated: true, completion: nil)
        //todo new implementation
    }
    
    func deleteSelf(_ cell: LinkCellView) {
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Really delete your submission?"
        
        alertController.addAction(Action(ActionData(title: "Yes", image: UIImage(named: "delete")!.menuIcon()), style: .default, handler: { _ in
            if let delegate = self.del {
                delegate.deleteSelf(self)
            }
        }))
        
        VCPresenter.presentAlert(alertController, parentVC: parentViewController!)
    }
    
    func flairSelf() {
        //todo this
        var list: [FlairTemplate] = []
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.flairList(link!.subreddit, link: link!.id, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "No subreddit flairs found", seconds: 3, context: self.parentViewController)
                    }
                case .success(let flairs):
                    list.append(contentsOf: flairs)
                    DispatchQueue.main.async {
                        let sheet = UIAlertController(title: "r/\(self.link!.subreddit) flairs", message: nil, preferredStyle: .actionSheet)
                        sheet.addAction(
                            UIAlertAction(title: "Close", style: .cancel) { (_) in
                                sheet.dismiss(animated: true, completion: nil)
                            }
                        )
                        
                        for flair in flairs {
                            let somethingAction = UIAlertAction(title: (flair.text.isEmpty) ?flair.name : flair.text, style: .default) { (_) in
                                sheet.dismiss(animated: true, completion: nil)
                                self.setFlair(flair)
                            }
                            
                            sheet.addAction(somethingAction)
                        }
                        
                        self.parentViewController?.present(sheet, animated: true)
                    }
                }
            })
        } catch {
        }
    }
    
    var flairText: String?
    
    func setFlair(_ flair: FlairTemplate) {
        if flair.editable {
            let alert = UIAlertController(title: "Edit flair text", message: "", preferredStyle: .alert)
            
            let config: TextField.Config = { textField in
                textField.becomeFirstResponder()
                textField.textColor = .black
                textField.placeholder = "Flair text"
                textField.left(image: UIImage.init(named: "flag"), color: .black)
                textField.leftViewPadding = 12
                textField.borderWidth = 1
                textField.cornerRadius = 8
                textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
                textField.backgroundColor = .white
                textField.keyboardAppearance = .default
                textField.keyboardType = .default
                textField.returnKeyType = .done
                textField.text = flair.text
                textField.action { textField in
                    self.flairText = textField.text
                }
            }
            
            alert.addOneTextField(configuration: config)
            
            alert.addAction(UIAlertAction(title: "Set flair", style: .default, handler: { (_) in
                self.submitFlairChange(flair, text: self.flairText ?? "")
            }))
            
            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            
            //todo make this work on ipad
            parentViewController?.present(alert, animated: true, completion: nil)
            
        } else {
            submitFlairChange(flair)
        }
    }
    
    func unmute() {
        self.videoView?.player?.isMuted = false
        UIView.animate(withDuration: 0.5, animations: {
            self.sound.alpha = 0
        }, completion: { (_) in
            self.sound.isHidden = true
        })
    }
    
    func submitFlairChange(_ flair: FlairTemplate, text: String? = "") {
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.flairSubmission(link!.subreddit, flairId: flair.id, submissionFullname: link!.id, text: text ?? "") { result in
                switch result {
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Flair not set", color: GMColor.red500Color(), seconds: 3, context: self.parentViewController)
                    }
                case .success(let success):
                    print(success)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Flair set successfully!", seconds: 3, context: self.parentViewController)
                        self.link!.flair = (text != nil && !text!.isEmpty) ? text! : flair.text
                        _ = CachedTitle.getTitle(submission: self.link!, full: true, true, false)
                        self.setLink(submission: self.link!, parent: self.parentViewController!, nav: self.navViewController!, baseSub: (self.link?.subreddit)!)
                        self.showBody(width: self.contentView.frame.size.width - 24)
                    }
                }}
        } catch {
        }
    }
    
    func refresh() {
        let link = self.link!
        upvote.setImage(LinkCellImageCache.upvote, for: .normal)
        save.setImage(LinkCellImageCache.save, for: .normal)
        readLater.setImage(LinkCellImageCache.readLater, for: .normal)
        downvote.setImage(LinkCellImageCache.downvote, for: .normal)
        sideUpvote.setImage(LinkCellImageCache.upvoteSmall, for: .normal)
        sideDownvote.setImage(LinkCellImageCache.downvoteSmall, for: .normal)
        
        var attrs: [String: Any] = [:]
        switch ActionStates.getVoteDirection(s: link) {
        case .down:
            downvote.setImage(LinkCellImageCache.downvoteTinted, for: .normal)
            sideDownvote.setImage(LinkCellImageCache.downvoteTintedSmall, for: .normal)
            attrs = ([NSForegroundColorAttributeName: ColorUtil.downvoteColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true)])
        case .up:
            upvote.setImage(LinkCellImageCache.upvoteTinted, for: .normal)
            sideUpvote.setImage(LinkCellImageCache.upvoteTintedSmall, for: .normal)
            attrs = ([NSForegroundColorAttributeName: ColorUtil.upvoteColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true)])
        default:
            attrs = ([NSForegroundColorAttributeName: ColorUtil.fontColor, NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true)])
        }
        
        if full {
            let subScore = NSMutableAttributedString(string: (link.score >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(link.score) / Double(1000))) : " \(link.score)", attributes: attrs)
            let scoreRatio =
                NSMutableAttributedString(string: (SettingValues.upvotePercentage && full && link.upvoteRatio > 0) ?
                    " (\(Int(link.upvoteRatio * 100))%)" : "", attributes: [NSFontAttributeName: comments.font, NSForegroundColorAttributeName: comments.textColor])
            
            var attrsNew: [String: Any] = [:]
            if scoreRatio.length > 0 {
                let numb = (link.upvoteRatio)
                if numb <= 0.5 {
                    if numb <= 0.1 {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.blue500Color()]
                    } else if numb <= 0.3 {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.blue400Color()]
                    } else {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.blue300Color()]
                    }
                } else {
                    if numb >= 0.9 {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.orange500Color()]
                    } else if numb >= 0.7 {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.orange400Color()]
                    } else {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.orange300Color()]
                    }
                }
            }
            
            scoreRatio.addAttributes(attrsNew, range: NSRange.init(location: 0, length: scoreRatio.length))
            
            subScore.append(scoreRatio)
            score.attributedText = subScore
        } else {
            let scoreString = NSAttributedString(string: (link.score >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(link.score) / Double(1000))) : " \(link.score)", attributes: attrs)
            
            if SettingValues.actionBarMode == .FULL {
                score.attributedText = scoreString
            } else if SettingValues.actionBarMode != .NONE {
                sideScore.attributedText = scoreString
            }
        }
        
        if ActionStates.isSaved(s: link) {
            save.setImage(LinkCellImageCache.saveTinted, for: .normal)
        }
        if History.getSeen(s: link) && !full {
            self.title.alpha = 0.7
        } else {
            self.title.alpha = 1
        }

        if ReadLater.isReadLater(link: link) {
            readLater.setImage(LinkCellImageCache.readLaterTinted, for: .normal)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var topmargin = 0
        var bottommargin = 2
        var leftmargin = 0
        var rightmargin = 0
        
        if (SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full {
            topmargin = 5
            bottommargin = 5
            leftmargin = 5
            rightmargin = 5
            if !SettingValues.flatMode {
                self.contentView.elevate(elevation: 2)
            }
        }
        
        let f = self.contentView.frame
        let fr = UIEdgeInsetsInsetRect(f, UIEdgeInsets(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin)))
        self.contentView.frame = fr
    }
    
    var registered: Bool = false
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        if full {
            let locationInTextView = textView.convert(location, to: textView)
            
            if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
                previewingContext.sourceRect = textView.convert(rect, from: textView)
                if let controller = parentViewController?.getControllerForUrl(baseUrl: url) {
                    return controller
                }
            }
        } else {
            History.addSeen(s: link!)
            if History.getSeen(s: link!) {
                self.title.alpha = 0.7
            } else {
                self.title.alpha = 1
            }
            if let controller = parentViewController?.getControllerForUrl(baseUrl: (link?.url)!) {
                return controller
            }
        }
        return nil
    }
    
    func estimateHeight(_ full: Bool, _ reset: Bool = false) -> CGFloat {
        if estimatedHeight == 0 || reset {
            var paddingTop = CGFloat(0)
            var paddingBottom = CGFloat(2)
            var paddingLeft = CGFloat(0)
            var paddingRight = CGFloat(0)
            var innerPadding = CGFloat(0)
            if (SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full {
                paddingTop = 5
                paddingBottom = 5
                paddingLeft = 5
                paddingRight = 5
            }
            
            let actionbar = CGFloat(!full && SettingValues.actionBarMode != .FULL ? 0 : 24)
            
            var imageHeight = big && !thumb ? CGFloat(submissionHeight) : CGFloat(0)
            let thumbheight = (full || SettingValues.largerThumbnail ? CGFloat(75) : CGFloat(50)) - (!full && SettingValues.postViewMode == .COMPACT ? 15 : 0)
            
            let textHeight = (!hasText || !full) ? CGFloat(0) : textView.estimatedHeight
            
            if thumb {
                imageHeight = thumbheight
                innerPadding += (SettingValues.postViewMode == .COMPACT && !full ? 4 : 8) //between top and thumbnail
                innerPadding += 18 - (SettingValues.postViewMode == .COMPACT && !full ? 4 : 0) //between label and bottom box
                innerPadding += (SettingValues.postViewMode == .COMPACT && !full ? 4 : 8) //between box and end
            } else if big {
                if SettingValues.postViewMode == .CENTER || full {
                    innerPadding += (SettingValues.postViewMode == .COMPACT && !full ? 8 : 16) //between label
                    innerPadding += (SettingValues.postViewMode == .COMPACT && !full ? 8 : 12) //between banner and box
                } else {
                    innerPadding += (SettingValues.postViewMode == .COMPACT && !full ? 4 : 8) //between banner and label
                    innerPadding += (SettingValues.postViewMode == .COMPACT && !full ? 8 : 12) //between label and box
                }
                
                innerPadding += (SettingValues.postViewMode == .COMPACT && !full ? 4 : 8) //between box and end
            } else {
                innerPadding += (SettingValues.postViewMode == .COMPACT && !full ? 4 : 8)
                innerPadding += 5 //between label and body
                innerPadding += (SettingValues.postViewMode == .COMPACT && !full ? 8 : 12) //between body and box
                innerPadding += (SettingValues.postViewMode == .COMPACT && !full ? 4 : 8) //between box and end
            }
            
            var estimatedUsableWidth = aspectWidth - paddingLeft - paddingRight
            var fullHeightExtras = CGFloat(0)
            
            if !full {
                if thumb {
                    estimatedUsableWidth -= thumbheight //is the same as the width
                    estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT && !full ? 16 : 24) //between edge and thumb
                    estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT && !full ? 4 : 8) //between thumb and label
                } else {
                    estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT && !full ? 16 : 24) //12 padding on either side
                }
            } else {
                fullHeightExtras += 12
                estimatedUsableWidth -= (24) //12 padding on either side
                if thumb {
                    fullHeightExtras += 45 + 12 + 12
                } else {
                    fullHeightExtras += imageHeight
                }
            }
            
            if SettingValues.actionBarMode.isSide() && !full {
                estimatedUsableWidth -= 36
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT && !full ? 16 : 24) //buttons horizontal margins
            }
            
            let framesetter = CTFramesetterCreateWithAttributedString(title.attributedText)
            let textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize.init(width: estimatedUsableWidth, height: CGFloat.greatestFiniteMagnitude), nil)
            
            let totalHeight = paddingTop + paddingBottom + (full ? ceil(textSize.height) : (thumb && !full ? max((!full && SettingValues.actionBarMode.isSide() ? max(ceil(textSize.height), 72) : ceil(textSize.height)), imageHeight) : (!full && SettingValues.actionBarMode.isSide() ? max(ceil(textSize.height), 72) : ceil(textSize.height)) + imageHeight)) + innerPadding + actionbar + textHeight + fullHeightExtras
            estimatedHeight = totalHeight
        }
        return estimatedHeight
    }
    
    func getInfo(locationInTextView: CGPoint) -> (URL, CGRect)? {
        if let attr = textView.firstTextView.link(at: locationInTextView) {
            return (attr.result.url!, attr.accessibilityFrame)
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if viewControllerToCommit is AlbumViewController {
            viewControllerToCommit.modalPresentationStyle = .overFullScreen
            parentViewController?.present(viewControllerToCommit, animated: true, completion: nil)
        } else if viewControllerToCommit is ModalMediaViewController {
            viewControllerToCommit.modalPresentationStyle = .overFullScreen
            parentViewController?.present(viewControllerToCommit, animated: true, completion: nil)
        } else {
            VCPresenter.showVC(viewController: viewControllerToCommit, popupIfPossible: true, parentNavigationController: parentViewController?.navigationController, parentViewController: parentViewController)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var parentViewController: (UIViewController & MediaVCDelegate)?
    public var navViewController: UIViewController?
    
    func openLink(sender: UITapGestureRecognizer? = nil) {
        if let link = link {
            (parentViewController)?.setLink(lnk: link, shownURL: loadedImage, lq: lq, saveHistory: true, heroView: big ? bannerImage : thumbImage, heroVC: parentViewController) //todo check this
            if History.getSeen(s: link) && !full {
                self.title.alpha = 0.7
            } else {
                self.title.alpha = 1
            }
        }
    }
    
    func openLinkVideo(sender: UITapGestureRecognizer? = nil) {
        if !playView.isHidden {
            doLoadVideo()
            playView.isHidden = true
            self.progressDot.isHidden = false
        } else if self.videoView.player != nil && self.videoView.player?.currentItem != nil && self.videoView.player!.currentItem!.presentationSize.width != 0 {
            let controller = AnyModalViewController(cellView: self)
            let postContentTransitioningDelegate = PostContentPresentationManager()
            postContentTransitioningDelegate.sourceImageView = self.videoView
            controller.transitioningDelegate = postContentTransitioningDelegate
            controller.modalPresentationStyle = .custom
            
            parentViewController?.present(controller, animated: true, completion: nil)
        }
    }
    
    func openComment(sender: UITapGestureRecognizer? = nil) {
        if !full {
            if let delegate = self.del {
                if videoView != nil {
                    videoView?.player?.pause()
                }
                delegate.openComments(id: link!.getId(), subreddit: link!.subreddit)
            }
        }
    }
    
    public static var imageDictionary: NSMutableDictionary = NSMutableDictionary.init()
    
}

extension UILabel {
    func addImage(imageName: String, afterLabel bolAfterLabel: Bool = false) {
        let attachment: NSTextAttachment = textAttachment(fontSize: self.font.pointSize, imageName: imageName)
        let attachmentString: NSAttributedString = NSAttributedString(attachment: attachment)
        
        if bolAfterLabel {
            let strLabelText: NSMutableAttributedString = NSMutableAttributedString.init(attributedString: self.attributedText!)
            strLabelText.append(attachmentString)
            
            self.attributedText = strLabelText
        } else {
            let strLabelText: NSMutableAttributedString = NSMutableAttributedString.init(attributedString: self.attributedText!)
            let mutableAttachmentString: NSMutableAttributedString = NSMutableAttributedString(attributedString: attachmentString)
            mutableAttachmentString.append(strLabelText)
            
            self.attributedText = mutableAttachmentString
        }
        self.baselineAdjustment = .alignCenters
    }
    
    func textAttachment(fontSize: CGFloat, imageName: String) -> NSTextAttachment {
        let font = FontGenerator.fontOfSize(size: fontSize, submission: true) //set accordingly to your font, you might pass it in the function
        let textAttachment = NSTextAttachment()
        let image = LinkCellView.imageDictionary.object(forKey: imageName)
        if image != nil {
            textAttachment.image = image as? UIImage
        } else {
            
            let img = UIImage(named: imageName)?.getCopy(withSize: .square(size: self.font.pointSize), withColor: ColorUtil.fontColor)
            textAttachment.image = img
            LinkCellView.imageDictionary.setObject(img!, forKey: imageName as NSCopying)
        }
        let mid = font.descender + font.capHeight
        textAttachment.bounds = CGRect(x: 0, y: font.descender - fontSize / 2 + mid + 2, width: fontSize, height: fontSize).integral
        return textAttachment
    }
    
    func removeImage() {
        let text = self.text
        self.attributedText = nil
        self.text = text
    }
}

protocol MaterialView {
    func elevate(elevation: Double)
}

// TODO: This function will be on every UIView, not just those that conform to MaterialView.
extension UIView: MaterialView {
    func elevate(elevation: Double) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: elevation)
        self.layer.shadowRadius = CGFloat(elevation)
        self.layer.shadowOpacity = 0.24
    }
}
extension UIGestureRecognizer {
    func cancel() {
        isEnabled = false
        isEnabled = true
    }
}
