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
import Photos
import MaterialComponents
import reddift
import RLBAlertsPickers
import SafariServices
import SDCAlertView
import SDWebImage
import Then
import UIKit
import YYText

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

class LinkCellView: UICollectionViewCell, UIViewControllerPreviewingDelegate, UIGestureRecognizerDelegate, TextDisplayStackViewDelegate {
    
    func linkTapped(url: URL, text: String) {
        if !full {
            return
        }
        linkClicked = true
        if !text.isEmpty {
            self.parentViewController?.showSpoiler(text)
        } else {
            self.parentViewController?.doShow(url: url, heroView: nil, finalSize: nil, heroVC: nil, link: link!)
        }
    }

    func linkLongTapped(url: URL) {
        longBlocking = true
        
        let alertController = DragDownAlertMenu(title: "Link options", subtitle: url.absoluteString, icon: url.absoluteString)
        
        alertController.addAction(title: "Share URL", icon: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")!.menuIcon()) {
            let shareItems: Array = [url]
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.contentView
            self.parentViewController?.present(activityViewController, animated: true, completion: nil)
        }
        
        alertController.addAction(title: "Copy URL", icon: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()) {
            UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
            BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self.parentViewController)
        }

        alertController.addAction(title: "Open in default app", icon: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }

        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alertController.addAction(title: "Open in Chrome", icon: UIImage(named: "world")!.menuIcon()) {
                _ = open.openInChrome(url, callbackURL: nil, createNewTab: true)
            }
        }
        
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionStrong()
        } else if SettingValues.hapticFeedback {
            AudioServicesPlaySystemSound(1519)
        }
        
        if parentViewController != nil {
            alertController.show(parentViewController!)
        }
    }
    
    @objc func upvote(sender: UITapGestureRecognizer? = nil) {
       // TODO: - maybe? contentView.blink(color: GMColor.orange500Color())
        del?.upvote(self)
    }
    
    @objc func hide(sender: UITapGestureRecognizer? = nil) {
        del?.hide(self)
    }
    
    @objc func reply(sender: UITapGestureRecognizer? = nil) {
        del?.reply(self)
    }
    
    @objc func share(sender: UITapGestureRecognizer? = nil) {
        let url = self.link!.url ?? URL(string: self.link!.permalink)
        
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: self is BannerLinkCellView ? [bannerImage?.image] : [url], applicationActivities: nil)
        if let presenter = activityViewController.popoverPresentationController {
            presenter.sourceView = self.contentView
            presenter.sourceRect = self.contentView.bounds
        }
        self.parentViewController?.present(activityViewController, animated: true, completion: nil)
    }

    @objc func downvote(sender: UITapGestureRecognizer? = nil) {
        del?.downvote(self)
    }
    
    @objc func more(sender: UITapGestureRecognizer? = nil) {
        del?.more(self)
    }
    
    @objc func mod(sender: UITapGestureRecognizer? = nil) {
        del?.mod(self)
    }
    
    @objc func save(sender: UITapGestureRecognizer? = nil) {
        del?.save(self)
    }

    @objc func readLater(sender: UITapGestureRecognizer? = nil) {
        del?.readLater(self)
    }
    
    var bannerImage: UIImageView!
    var thumbImageContainer: UIView!
    var thumbImage: UIImageView!
    var thumbText: UILabel!
    var title: YYLabel!
    var score: UILabel!
    var box: UIStackView!
    var sideButtons: UIStackView!
    var buttons: UIStackView!
    var comments: UILabel!
    var info: UILabel!
    var subicon: UIImageView!
    var textView: TextDisplayStackView!
    var save: UIButton!
    var menu: UIButton!
    var upvote: UIButton!
    var hide: UIButton!
    var share: UIButton!
    var edit: UIButton!
    var reply: UIButton!
    var downvote: UIButton!
    var mod: UIButton!
    var readLater: UIButton!
    var commenticon: UIImageView!
    var submissionicon: UIImageView!
    weak var del: LinkCellViewDelegate?
    var taglabel: UILabel!
    var tagbody: UIView!
    var crosspost: UITableViewCell!
    var sideUpvote: UIButton!
    var sideDownvote: UIButton!
    var sideScore: UILabel!
    
    var infoBox: UIStackView!
    var force: ForceTouchGestureRecognizer?

    var videoView: VideoView!
    var topVideoView: UIView!
    var progressDot: UIView!
    var spinner: UIActivityIndicatorView!
    var sound: UIButton!
    var updater: CADisplayLink?
    var timeView: UILabel!
    var playView: UIImageView!
    
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
    
    var videoID: String = ""

    var accessibilityView: UIView {
        return full ? contentView : self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func configureView() {

        accessibilityView.accessibilityIdentifier = "Link Cell View"
        accessibilityView.accessibilityHint = "Opens the post view for this post"
        accessibilityView.isAccessibilityElement = true
        accessibilityView.accessibilityTraits = UIAccessibilityTraits.link
        
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
        self.subicon = UIImageView().then {
            $0.accessibilityIdentifier = "Subreddit Community Icon"
            $0.backgroundColor = UIColor.white
            $0.layer.cornerRadius = 12
            if #available(iOS 11.0, *) {
                $0.accessibilityIgnoresInvertColors = true
            }
            $0.isHidden = true //Disable this view, might do it with a view instead of in the AttributedString later
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
        }
        self.thumbText = UILabel().then {
            $0.accessibilityIdentifier = "Link Type Label"
            if !ColorUtil.shouldBeNight() {
                $0.backgroundColor = ColorUtil.theme.fontColor.withAlphaComponent(0.5)
                $0.textColor = ColorUtil.theme.foregroundColor
            } else {
                $0.backgroundColor = ColorUtil.theme.foregroundColor.withAlphaComponent(0.5)
                $0.textColor = ColorUtil.theme.fontColor
            }
            $0.textAlignment = .center
            $0.adjustsFontSizeToFitWidth = true
            $0.isHidden = false
            
            $0.font = UIFont.boldSystemFont(ofSize: 10)
            if #available(iOS 11.0, *) {
                $0.accessibilityIgnoresInvertColors = true
            }
            $0.clipsToBounds = true
        }
        self.thumbImageContainer.addSubview(self.thumbImage)
        self.thumbImage.addSubview(self.thumbText)
        
        self.thumbImage.edgeAnchors == self.thumbImageContainer.edgeAnchors
        self.thumbText.horizontalAnchors == self.thumbImage.horizontalAnchors - 2
        self.thumbText.heightAnchor == 20
        self.thumbText.bottomAnchor == self.thumbImage.bottomAnchor + 2
        
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
        
        self.title = YYLabel(frame: CGRect(x: 75, y: 8, width: 0, height: 0)).then {
            $0.accessibilityIdentifier = "Post Title"
            $0.isOpaque = false
            $0.numberOfLines = 0
            $0.lineBreakMode = .byWordWrapping
            $0.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
            $0.backgroundColor = ColorUtil.theme.foregroundColor
            $0.textContainerInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
            $0.highlightTapAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
                text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, range, _) in
                    for attr in attrs {
                        if attr.value is YYTextHighlight {
                            if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                                self.linkTapped(url: url, text: text.attributedSubstring(from: range).string)
                                return
                            }
                        }
                    }
                })
            }
            $0.isUserInteractionEnabled = true
        }
        
        self.infoBox = UIStackView().then {
            $0.accessibilityIdentifier = "Extra Info Stack Horizontal"
            $0.axis = .vertical
        }
        
        self.hide = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Hide Button"
            $0.setImage(LinkCellImageCache.hide, for: .normal)
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.reply = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Reply Button"
            $0.setImage(LinkCellImageCache.reply, for: .normal)
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.edit = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Edit Button"
            $0.setImage(LinkCellImageCache.edit, for: .normal)
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.save = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Save Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.menu = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Post menu"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.upvote = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Upvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.downvote = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Downvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.sideUpvote = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Upvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.sideDownvote = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Downvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.mod = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Mod Button"
            $0.setImage(LinkCellImageCache.mod, for: .normal)
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }

        self.share = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Share Button"
            $0.contentMode = .center
            $0.setImage(LinkCellImageCache.share, for: .normal)
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }

        self.readLater = UIButton(type: .custom).then {
            $0.accessibilityIdentifier = "Read Later Button"
            $0.setImage(LinkCellImageCache.readLater, for: .normal)
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.commenticon = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10)).then {
            $0.accessibilityIdentifier = "Comment Count Icon"
            $0.image = LinkCellImageCache.commentsIcon
            $0.contentMode = .scaleAspectFit
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.submissionicon = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10)).then {
            $0.accessibilityIdentifier = "Score Icon"
            $0.image = LinkCellImageCache.votesIcon
            $0.contentMode = .scaleAspectFit
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.score = UILabel().then {
            $0.accessibilityIdentifier = "Score Label"
            $0.numberOfLines = 1
            $0.textColor = ColorUtil.theme.fontColor
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
        }
        
        self.sideScore = UILabel().then {
            $0.accessibilityIdentifier = "Score Label vertical"
            $0.numberOfLines = 1
            $0.textAlignment = .center
            $0.textColor = ColorUtil.theme.fontColor
            $0.isOpaque = false
        }
        
        self.comments = UILabel().then {
            $0.accessibilityIdentifier = "Comment Count Label"
            $0.numberOfLines = 1
            $0.font = FontGenerator.boldFontOfSize(size: 12, submission: true)
            $0.textColor = ColorUtil.theme.fontColor
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.theme.foregroundColor
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
            contentView.addSubviews(bannerImage, thumbImageContainer, title, subicon, textView, infoContainer, tagbody)
        } else {
            contentView.addSubviews(bannerImage, thumbImageContainer, title, subicon, infoContainer, tagbody)
        }
        
        if self is AutoplayBannerLinkCellView || self is FullLinkCellView || self is GalleryLinkCellView {
            self.videoView = VideoView().then {
                $0.accessibilityIdentifier = "Video view"
                if !SettingValues.flatMode {
                    $0.layer.cornerRadius = 15
                }
                $0.tag = 42
                $0.backgroundColor = .clear
                $0.layer.masksToBounds = true
            }
            
            self.topVideoView = UIView()
            self.progressDot = UIView()
            self.spinner = UIActivityIndicatorView(style: .white)
            
            progressDot.alpha = 0.7
            progressDot.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            sound = UIButton(type: .custom)
            sound.isUserInteractionEnabled = true
            if SettingValues.muteInlineVideos {
                sound.setImage(UIImage(sfString: SFSymbol.volumeSlashFill, overrideString: "mute")?.getCopy(withSize: CGSize.square(size: 20), withColor: GMColor.red400Color()), for: .normal)
                sound.isHidden = true
            } else {
                sound.isHidden = true
            }

            timeView = UILabel().then {
                $0.textColor = .white
                $0.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: UIFont.Weight(rawValue: 5))
                $0.textAlignment = .center
                $0.alpha = 0.6
                $0.layer.cornerRadius = 5
                $0.clipsToBounds = true
                //$0.textContainerInset = UIEdgeInsetsMake(2, 2, 2, 2)
                $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            }
            
            topVideoView.addSubviews(progressDot, spinner, sound, timeView)
            
            contentView.addSubviews(videoView, topVideoView)
            contentView.bringSubviewToFront(videoView)
            contentView.bringSubviewToFront(topVideoView)
            
            playView = UIImageView().then {
                    $0.image = UIImage(sfString: SFSymbol.playFill, overrideString: "play")?.getCopy(withSize: CGSize.square(size: 30), withColor: .white)
                    $0.contentMode = .center
                    $0.isHidden = true
            }
            topVideoView.addSubview(playView)
        }
        
        contentView.layer.masksToBounds = true
        
        if SettingValues.actionBarMode.isFull() || full || self is GalleryLinkCellView {
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
            if SettingValues.actionBarMode == .FULL_LEFT {
                buttons.addArrangedSubviews(menu, share, upvote, downvote, edit, reply, readLater, save, hide, mod)
            } else {
                buttons.addArrangedSubviews(edit, reply, readLater, save, hide, upvote, downvote, mod, share, menu)
            }
            self.contentView.addSubview(buttons)
        } else {
            buttons = UIStackView()
            box = UIStackView()
        }
        
        if full {
            self.contentView.addSubview(infoBox)
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
            share.addTarget(self, action: #selector(LinkCellView.share(sender:)), for: .touchUpInside)
            sideUpvote.addTarget(self, action: #selector(LinkCellView.upvote(sender:)), for: .touchUpInside)
            menu.addTarget(self, action: #selector(LinkCellView.more(sender:)), for: .touchUpInside)

            addTouch(view: thumbImage, action: #selector(LinkCellView.openLink(sender:)))
            
            if !SettingValues.disableBanner || full {
                let tap = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openLink(sender:)))
                tap.delegate = self
                bannerImage.addGestureRecognizer(tap)
            }
            
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
                comment.cancelsTouchesInView = false
                if dtap != nil {
                    comment.require(toFail: dtap!)
                }
                self.addGestureRecognizer(comment)
            }
            
            if #available(iOS 13, *) {
                let interaction = UIContextMenuInteraction(delegate: self)
                self.contentView.addInteraction(interaction)
            }

            if longPress == nil {
                longPress = UILongPressGestureRecognizer(target: self, action: #selector(LinkCellView.handleLongPress(_:)))
                longPress?.minimumPressDuration = 0.36
                longPress?.delegate = self
                if full {
                    longPress?.cancelsTouchesInView = false
                    textView.parentLongPress = longPress!
                }
                
                let long2 = UILongPressGestureRecognizer(target: self, action: #selector(LinkCellView.linkMenu(sender:)))
                long2.delegate = self
                thumbImageContainer.addGestureRecognizer(long2)

                let long3 = UILongPressGestureRecognizer(target: self, action: #selector(LinkCellView.linkMenu(sender:)))
                long3.delegate = self
                topVideoView?.addGestureRecognizer(long3)

                let long4 = UILongPressGestureRecognizer(target: self, action: #selector(LinkCellView.linkMenu(sender:)))
                long4.delegate = self
                infoContainer.addGestureRecognizer(long4)

                if #available(iOS 13, *) {} else {
                    let long = UILongPressGestureRecognizer(target: self, action: #selector(LinkCellView.linkMenu(sender:)))
                    long.delegate = self
                    bannerImage.addGestureRecognizer(long)
                    longPress!.require(toFail: long)
                }

                longPress!.require(toFail: long2)
                longPress!.require(toFail: long3)
                longPress!.require(toFail: long4)
                self.contentView.addGestureRecognizer(longPress!)
            }
            addTouch = true
        }
        
        sideButtons.isHidden = !SettingValues.actionBarMode.isSide() || full
        buttons.isHidden = !SettingValues.actionBarMode.isFull() && !full
        buttons.isUserInteractionEnabled = !SettingValues.actionBarMode.isFull() || full || self is GalleryLinkCellView
    }
    
    var progressBar: ProgressBarView!
    var typeImage: UIImageView!
    var previousTranslation: CGFloat = 0
    var previousProgress: Float!
    var dragCancelled = false
    var direction = 0
    
    @objc func linkMenu(sender: AnyObject) {
        if parentViewController != nil && parentViewController?.presentedViewController == nil {
            let url = self.link!.url!
            let alertController = DragDownAlertMenu(title: ContentType.isImage(uri: url) && !bannerImage.isHidden ? "Image options" : "Submission link options", subtitle: url.absoluteString, icon: url.absoluteString)
            
            alertController.addAction(title: "Share\(ContentType.isImage(uri: url) && !bannerImage.isHidden ? " image" : "") URL", icon: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")!.menuIcon()) {
                let shareItems: Array = [url]
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                if let presenter = activityViewController.popoverPresentationController {
                    presenter.sourceView = self.bannerImage
                    presenter.sourceRect = self.bannerImage.bounds
                }
                self.parentViewController?.present(activityViewController, animated: true, completion: nil)
            }
            
            if ContentType.isImage(uri: url) && !bannerImage.isHidden {
                alertController.addAction(title: "Share image", icon: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "image")!.menuIcon(), action: {
                    let imageToShare = [self.bannerImage.image!]
                    let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
                    if let presenter = activityViewController.popoverPresentationController {
                        presenter.sourceView = self.bannerImage
                        presenter.sourceRect = self.bannerImage.bounds
                    }
                    self.parentViewController?.present(activityViewController, animated: true, completion: nil)
                })
            }

            alertController.addAction(title: "Copy URL", icon: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()) {
                UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self.parentViewController)
            }

            alertController.addAction(title: "Open in default app", icon: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }

            let open = OpenInChromeController.init()
            if open.isChromeInstalled() {
                alertController.addAction(title: "Open in Chrome", icon: UIImage(named: "world")!.menuIcon()) {
                    _ = open.openInChrome(url, callbackURL: nil, createNewTab: true)
                }
            }
            if #available(iOS 10.0, *) {
                HapticUtility.hapticActionStrong()
            } else if SettingValues.hapticFeedback {
                AudioServicesPlaySystemSound(1519)
            }
            alertController.show(parentViewController!)
        }
    }
    
    var originalPos = CGFloat.zero
    var originalLocation = CGFloat.zero
    var currentProgress = Float(0)
    var diff = CGFloat.zero
    var action = SettingValues.SubmissionAction.UPVOTE
    var tiConstraints = [NSLayoutConstraint]()
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began || typeImage == nil {
            dragCancelled = false
            direction = 0
            originalLocation = sender.location(in: self).x
            originalPos = self.contentView.frame.origin.x
            diff = self.frame.width - originalLocation
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
            sender.cancel()
            return
        }
        let xVelocity = sender.velocity(in: self).x
        if sender.state != .ended && sender.state != .began && sender.state != .cancelled {
            guard previousProgress != 1 else { return }
            let posx = sender.location(in: self).x
            if direction == -1 && self.contentView.frame.origin.x > originalPos {
                if getFirstAction(left: false) != .NONE {
                    direction = 0
                    diff = self.frame.width - diff
                    NSLayoutConstraint.deactivate(tiConstraints)
                    tiConstraints = batch {
                        typeImage.leftAnchor == self.leftAnchor + 4
                    }
                }
            } else if direction == 1 && self.contentView.frame.origin.x < originalPos {
                if getFirstAction(left: true) != .NONE {
                    direction = 0
                    NSLayoutConstraint.deactivate(tiConstraints)
                    tiConstraints = batch {
                        typeImage.rightAnchor == self.rightAnchor - 4
                    }
                }
            }
            
            if direction == 0 {
                if xVelocity > 0 {
                    direction = 1
                    diff = self.frame.width - diff
                    action = getFirstAction(left: true)
                    if action == .NONE {
                        sender.cancel()
                        return
                    }
                    typeImage.image = UIImage(named: action.getPhoto())?.getCopy(withSize: CGSize.square(size: 30), withColor: .white)
                    typeImage.isHidden = true
                    UIView.animate(withDuration: 0.1) {
                        self.backgroundColor = ColorUtil.theme.fontColor.withAlphaComponent(0.5)
                    }
                } else {
                    direction = -1
                    action = getFirstAction(left: false)
                    if action == .NONE {
                        sender.cancel()
                        return
                    }
                    typeImage.image = UIImage(named: action.getPhoto())?.getCopy(withSize: CGSize.square(size: 30), withColor: .white)
                    typeImage.isHidden = true
                    UIView.animate(withDuration: 0.1) {
                        self.backgroundColor = ColorUtil.theme.fontColor.withAlphaComponent(0.5)
                    }
                }
            }
            
            let currentTranslation = direction == -1 ? 0 - (self.bounds.size.width - posx - diff) : posx - diff
            self.contentView.frame.origin.x = posx - originalLocation

            if (direction == -1 && SettingValues.commentActionLeftLeft == .NONE && SettingValues.commentActionLeftRight == .NONE) || (direction == 1 && SettingValues.commentActionRightRight == .NONE && SettingValues.commentActionRightLeft == .NONE) {
                dragCancelled = true
                sender.cancel()
                return
            } else if typeImage.superview == nil {
                self.addSubviews(typeImage)
                self.bringSubviewToFront(typeImage)
                tiConstraints = batch {
                    if direction == 1 {
                        typeImage.leftAnchor == self.leftAnchor + 4
                    } else {
                        typeImage.rightAnchor == self.rightAnchor - 4
                    }
                }
                typeImage.centerYAnchor == self.centerYAnchor
                typeImage.heightAnchor == 45
                typeImage.widthAnchor == 45
            }
            
            let progress = Float(min(abs(currentTranslation) / (self.contentView.bounds.width), 1))
            
            if progress > 0.1 && previousProgress <= 0.1 {
                typeImage.alpha = 0
                UIView.animate(withDuration: 0.2) {
                    self.typeImage.alpha = 1
                }
                UIView.animate(withDuration: 0.2) {
                    self.backgroundColor = self.action.getColor()
                }
            } else if progress < 0.1  && previousProgress >= 0.1 {
                typeImage.alpha = 1
                UIView.animate(withDuration: 0.2, animations: {
                    self.typeImage.alpha = 0
                }, completion: { (_) in
                })
                UIView.animate(withDuration: 0.2) {
                    self.backgroundColor = ColorUtil.theme.fontColor.withAlphaComponent(0.5)
                }
            } else if progress > 0.35 && previousProgress <= 0.35 && isTwoForDirection(left: direction == 1) {
                action = getSecondAction(left: direction == 1)
                if #available(iOS 10.0, *) {
                    HapticUtility.hapticActionStrong()
                }
                self.typeImage.transform = CGAffineTransform.init(scaleX: CGFloat((0.1) / 0.25), y: CGFloat((0.1) / 0.25))
                UIView.animate(withDuration: 0.2) {
                    self.typeImage.transform = CGAffineTransform.init(scaleX: CGFloat(1), y: CGFloat(1))
                    self.typeImage.image = UIImage(named: self.action.getPhoto())?.getCopy(withSize: CGSize.square(size: 30), withColor: .white)
                    self.backgroundColor = self.action.getColor()
                }
            } else if progress < 0.35 && previousProgress >= 0.35 && isTwoForDirection(left: direction == 1) {
                action = getFirstAction(left: direction == 1)
                if #available(iOS 10.0, *) {
                    HapticUtility.hapticActionStrong()
                }
                self.typeImage.transform = CGAffineTransform.init(scaleX: CGFloat((0.1) / 0.25), y: CGFloat((0.1) / 0.25))
                UIView.animate(withDuration: 0.2) {
                    self.typeImage.transform = CGAffineTransform.init(scaleX: CGFloat(1), y: CGFloat(1))
                    self.typeImage.image = UIImage(named: self.action.getPhoto())?.getCopy(withSize: CGSize.square(size: 30), withColor: .white)
                    self.backgroundColor = self.action.getColor()
                }
            }
            if progress > 0.1 && progress <= 0.25 {
                typeImage.alpha = 1
                typeImage.isHidden = false
                var prog = (progress * 1.2) / 0.25
                if prog > 1 {
                    prog = 1
                }
                UIView.animate(withDuration: 0.1) {
                    self.typeImage.transform = CGAffineTransform.init(scaleX: CGFloat(prog), y: CGFloat(prog))
                }
            }
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            CATransaction.commit()
            currentProgress = progress
            if (isTwoForDirection(left: direction == 1) && ((currentProgress >= 0.1 && previousProgress < 0.1) || (currentProgress <= 0.1 && previousProgress > 0.1))) || (!isTwoForDirection(left: direction == 1) && currentProgress >= 0.35 && previousProgress < 0.35) || sender.state == .ended {
                if #available(iOS 10.0, *) {
                    HapticUtility.hapticActionWeak()
                }
            }
            previousTranslation = currentTranslation
            previousProgress = currentProgress
        } else if sender.state == .ended && ((currentProgress >= (isTwoForDirection(left: direction == 1) ? 0.1 : 0.35) && !((xVelocity > 300 && direction == -1) || (xVelocity < -300 && direction == 1))) || (((xVelocity > 0 && direction == 1) || (xVelocity < 0 && direction == -1)) && abs(xVelocity) > 1000)) {
            doAction(item: self.action)
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.typeImage.alpha = 0
                self.backgroundColor = ColorUtil.theme.backgroundColor
                self.typeImage.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                self.contentView.frame.origin.x = self.originalPos
            }, completion: { (_) in
                self.typeImage.removeFromSuperview()
            })
        } else if sender.state != .began {
            dragCancelled = true
        }
        print(self.contentView.frame.origin.x)

        if dragCancelled || sender.state == .cancelled {
            if self.typeImage.superview == nil {
                return
            }
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                self.typeImage.alpha = 0
                self.contentView.frame.origin.x = self.originalPos
                self.backgroundColor = ColorUtil.theme.backgroundColor
            }, completion: { (_) in
                self.typeImage.removeFromSuperview()
            })
        }
    }
    
    func isTwoForDirection(left: Bool) -> Bool {
        return SettingValues.submissionActionLeft != .NONE && SettingValues.submissionActionRight != .NONE
    }

    func getFirstAction(left: Bool) -> SettingValues.SubmissionAction {
        return SettingValues.submissionActionLeft == .NONE ? SettingValues.submissionActionRight : SettingValues.submissionActionLeft
    }
    
    func getSecondAction(left: Bool) -> SettingValues.SubmissionAction {
        return SettingValues.submissionActionRight == .NONE ? SettingValues.submissionActionLeft : SettingValues.submissionActionRight
    }

    func updateProgress(_ oldPercent: CGFloat, _ total: String, buffering: Bool) {
        var percent = oldPercent
        if percent == -1 {
            percent = 1
        }
        let startAngle = -CGFloat.pi / 2
        
        let center = CGPoint(x: 20 / 2, y: 20 / 2)
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
            spinner.isHidden = true
            spinner.stopAnimating()
        }
        
        if timeView.isHidden {
            timeView.isHidden = false
            progressDot.isHidden = false
            spinner.isHidden = false
            spinner.startAnimating()
        }
        timeView.text = "\(total)  "
        
        if oldPercent == -1 || (buffering && progressDot.layer.animation(forKey: "opacity") == nil) {
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.duration = 0.5
            fadeAnimation.toValue = 0
            fadeAnimation.fromValue = 0
            fadeAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            fadeAnimation.autoreverses = false
            fadeAnimation.repeatCount = Float.greatestFiniteMagnitude
            
            progressDot.layer.add(fadeAnimation, forKey: "fade")

            timeView.isHidden = true
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
        
        self.clipsToBounds = true
        if videoView != nil {
            progressDot.widthAnchor == 20
            progressDot.heightAnchor == 20
            progressDot.leftAnchor == topVideoView.leftAnchor + 8
            progressDot.bottomAnchor == topVideoView.bottomAnchor - 8
            progressDot.layer.cornerRadius = 10
            progressDot.clipsToBounds = true
            
            spinner.widthAnchor == 20
            spinner.heightAnchor == 20
            spinner.leftAnchor == topVideoView.leftAnchor + 8
            spinner.bottomAnchor == topVideoView.bottomAnchor - 8
            spinner.clipsToBounds = true

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
            
            if (SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full && !(self is GalleryLinkCellView) {
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
            
            if SettingValues.actionBarMode.isFull() || full || self is GalleryLinkCellView {
                
                if SettingValues.actionBarMode == .FULL_LEFT {
                    box.rightAnchor == contentView.rightAnchor - ctwelve
                    box.bottomAnchor == contentView.bottomAnchor - ceight
                    box.centerYAnchor == buttons.centerYAnchor // Align vertically with buttons
                    box.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
                    box.heightAnchor == CGFloat(24)
                    buttons.heightAnchor == CGFloat(24)
                    buttons.leftAnchor == contentView.leftAnchor + ctwelve
                    buttons.bottomAnchor == contentView.bottomAnchor - ceight
                } else {
                    box.leftAnchor == contentView.leftAnchor + ctwelve
                    box.bottomAnchor == contentView.bottomAnchor - ceight
                    box.centerYAnchor == buttons.centerYAnchor // Align vertically with buttons
                    box.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
                    box.heightAnchor == CGFloat(24)
                    buttons.heightAnchor == CGFloat(24)
                    buttons.rightAnchor == contentView.rightAnchor - ctwelve
                    buttons.bottomAnchor == contentView.bottomAnchor - ceight

                }
            buttons.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
            } else if SettingValues.actionBarMode.isSide() {
                if SettingValues.actionBarMode == .SIDE_RIGHT {
                    sideButtons.rightAnchor == contentView.rightAnchor - ceight
                } else {
                    sideButtons.leftAnchor == contentView.leftAnchor + ceight
                }
                sideScore.widthAnchor == CGFloat(40)
                sideButtons.widthAnchor == CGFloat(40)
            }
            
            title.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
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
            menu,
            share,
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
        endVideos()
    }
    
    func endVideos() {
        if !(self is AutoplayBannerLinkCellView || self is FullLinkCellView || self is GalleryLinkCellView) {
            return
        }
        videoPreloaded = false
        isLoadingVideo = false
        videoCompletion = nil
        if videoView != nil && (AnyModalViewController.linkID.isEmpty && (!full || videoLoaded) || full) && ContentType.displayVideo(t: type) && type != .VIDEO {
            let wasPlayingAudio = (self.videoView.player?.currentItem?.tracks.count ?? 1) > 1 && !self.videoView.player!.isMuted
            videoView?.player?.pause()
            
            self.videoView!.player?.replaceCurrentItem(with: nil)
            self.videoView!.player = nil

            self.updater?.invalidate()
            self.updater = nil
            self.bannerImage.isHidden = false
            self.playView.isHidden = self is GalleryLinkCellView || SettingValues.autoPlayMode != .TAP || full
            videoView?.isHidden = false
            topVideoView?.isHidden = false
            sound.isHidden = true
            self.updateProgress(-1, "", buffering: false)
            self.contentView.bringSubviewToFront(topVideoView!)
            self.progressDot.isHidden = true
            self.timeView.isHidden = true
            if wasPlayingAudio {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                     if (self.videoView?.player?.currentItem?.tracks.count ?? 1) > 1 {
                         do {
                            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
                             try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                         } catch {
                         }
                     }
                }
             }
        }
    }
    
    func configure(submission: RSubmission, parent: UIViewController & MediaVCDelegate, nav: UIViewController?, baseSub: String, test: Bool = false, embedded: Bool = false, parentWidth: CGFloat = 0, np: Bool) {
        if title == nil {
            configureView()
            configureLayout()
        }
        if videoTask != nil {
            videoTask!.cancel()
        }
        self.link = submission
        self.setLink(submission: submission, parent: parent, nav: nav, baseSub: baseSub, test: test, embedded: embedded, parentWidth: parentWidth, np: np)
        layoutForContent()
    }
    
    var linkClicked = false
    
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
    
    let currentAccountTransitioningDelegate = ProfileInfoPresentationManager()

    func refreshLink(_ submission: RSubmission, np: Bool) {
        self.link = submission
        
        guard self.link != nil else {
            return
        }

        if dtap == nil && SettingValues.submissionActionDoubleTap != .NONE {
            dtap = UIShortTapGestureRecognizer.init(target: self, action: #selector(self.doDTap(_:)))
            dtap!.numberOfTapsRequired = 2
            self.addGestureRecognizer(dtap!)
        }
        
        refreshTitle(np: np)

        if !full {
            let comment = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openComment(sender:)))
            comment.delegate = self
            if dtap != nil {
                comment.require(toFail: dtap!)
            }
            self.addGestureRecognizer(comment)
        }
        
        refresh(np: np)
        let more = History.commentsSince(s: submission)
        comments.text = " \(submission.commentCount)\(more > 0 ? " (+\(more))" : "")"
    }
    
   // var titleAttrs: [NSLayoutConstraint] = []
    var oldBounds = CGSize.zero
    
    func refreshTitle(np: Bool = false, force: Bool = false) {
        guard let link = self.link else {
            return
        }

        let finalTitle = CachedTitle.getTitleAttributedString(link, force: force, gallery: false, full: full)
        
        let bounds = self.estimateHeightSingle(full, np: np, attText: finalTitle)
        if oldBounds.width != bounds.textBoundingSize.width || oldBounds.height != bounds.textBoundingSize.height {
            oldBounds = bounds.textBoundingSize
            title.textLayout = bounds
            title.textContainerInset = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
            title.preferredMaxLayoutWidth = bounds.textBoundingSize.width
        }
        // TODO setting to turn off, check for link being valid
        //subicon.sd_setImage(with: URL(string: link.subreddit_icon), completed: nil)
        title.attributedText = finalTitle
        /*title.removeConstraints(titleAttrs)
        titleAttrs = batch {
            title.heightAnchor == bounds.textBoundingSize.height
        }*/
        //title.exclusionPaths = [UIBezierPath(rect: CGRect(x: 0, y: 0, width: 32, height: 5))]
        title.textVerticalAlignment = .top
        title.highlightTapAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
            text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, smallRange, _) in
                for attr in attrs {
                    if attr.value is YYTextHighlight {
                        if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                            self.linkTapped(url: url, text: "")
                            return
                        } else if (attr.value as! YYTextHighlight).userInfo?["spoiler"] as? Bool ?? false {
                            self.linkTapped(url: URL(string: "/s")!, text: text.attributedSubstring(from: smallRange).string)
                        }
                    }
                }
            })
        }
        title.highlightLongPressAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
            text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, _, _) in
                for attr in attrs {
                    if let value = attr.value as? YYTextHighlight {
                        if let profile = value.userInfo?["profile"] as? String {
                            if let parent = UIApplication.shared.keyWindow?.topViewController() {
                                let vc = ProfileInfoViewController(accountNamed: profile, parent: parent)
                                vc.modalPresentationStyle = .custom
                                vc.transitioningDelegate = self.currentAccountTransitioningDelegate
                                parent.present(vc, animated: true)
                                if #available(iOS 10.0, *) {
                                    HapticUtility.hapticActionStrong()
                                }
                            }
                            return
                        } else if let url = value.userInfo?["url"] as? URL {
                            self.linkLongTapped(url: url)
                            return
                        }
                    }
                }
            })
        }
    }
        
    @objc func doDTap(_ sender: AnyObject) {
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
        contentView.bringSubviewToFront(overView)
        contentView.bringSubviewToFront(typeImage)
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
                UIApplication.shared.open(self.link!.url ?? URL(string: self.link!.permalink)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(self.link!.url ?? URL(string: self.link!.permalink)!)
            }
        case .SHARE:
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [self.link!.url ?? URL(string: self.link!.permalink)!], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = self.contentView
                presenter.sourceRect = self.contentView.bounds
            }
            self.parentViewController?.present(activityViewController, animated: true, completion: nil)
        default:
            break
        }
    }
    
    @objc func do3dTouch(_ sender: AnyObject) {
        switch SettingValues.submissionActionForceTouch {
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
                UIApplication.shared.open(self.link!.url ?? URL(string: self.link!.permalink)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            } else {
                UIApplication.shared.openURL(self.link!.url ?? URL(string: self.link!.permalink)!)
            }
        case .SHARE:
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [self.link!.url ?? URL(string: self.link!.permalink)!], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = self.contentView
                presenter.sourceRect = self.contentView.bounds
            }
            self.parentViewController?.present(activityViewController, animated: true, completion: nil)
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
    
    var shouldLoadVideo = false
    
    private func setLink(submission: RSubmission, parent: UIViewController & MediaVCDelegate, nav: UIViewController?, baseSub: String, test: Bool = false, embedded: Bool = false, parentWidth: CGFloat = 0, np: Bool) {
        if self is AutoplayBannerLinkCellView || self is GalleryLinkCellView {
            self.endVideos()
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            } catch {
                NSLog(error.localizedDescription)
            }
        }
        
        self.linkClicked = false

        self.full = self is FullLinkCellView
        self.parentViewController = parent
        self.link = submission
        if navViewController == nil && nav != nil {
            navViewController = nav
        }

        self.shouldLoadVideo = false
        self.loadedImage = nil
        lq = false

        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        comments.textColor = ColorUtil.theme.navIconColor
        title.textColor = ColorUtil.theme.navIconColor

        activeSet = true

        defer {
            refreshAccessibility(submission: submission)
        }

        let actions = PostActionsManager(submission: submission)

        func setVisibility(_ view: UIView, _ visible: Bool) {
            view.isHidden = !visible
            view.isUserInteractionEnabled = visible
        }

        setVisibility(upvote, actions.isVotingPossible)
        setVisibility(downvote, actions.isVotingPossible)
        setVisibility(hide, actions.isHideEnabled && !full)
        setVisibility(readLater, actions.isReadLaterEnabled)
        setVisibility(save, actions.isSaveEnabled && actions.isSavePossible)
        setVisibility(reply, actions.isReplyPossible && full)
        setVisibility(menu, actions.isMenuEnabled)
        setVisibility(share, actions.isShareEnabled)
        setVisibility(edit, actions.isEditPossible && full)
        setVisibility(mod, actions.isModPossible)

        thumb = submission.thumbnail
        big = submission.banner
        
        submissionHeight = CGFloat(submission.height)
        
        type = test && SettingValues.linkAlwaysThumbnail && !(self is GalleryLinkCellView) ? ContentType.CType.LINK : ContentType.getContentType(baseUrl: submission.url)
        
        if embedded && !submission.isSelf {
            type = .LINK
        }
        
        if submission.isSelf {
            type = .SELF
        }
        
        if SettingValues.postImageMode == .THUMBNAIL && !full {
            big = false
            thumb = true
        }
        
        let fullImage = ContentType.fullImage(t: type)
        let shouldAutoplay = SettingValues.shouldAutoPlay()
        
        let overrideFull = ContentType.displayVideo(t: type) && type != .VIDEO && (self is AutoplayBannerLinkCellView || self is FullLinkCellView || self is GalleryLinkCellView) && shouldAutoplay

        if !fullImage && submissionHeight < 75 {
            big = false
            thumb = true
        } else if big && ((!full && SettingValues.postImageMode == .CROPPED_IMAGE) || (full && !SettingValues.commentFullScreen)) && !overrideFull {
            submissionHeight = test ? 150 : 200
        } else if big {
            let h = getHeightFromAspectRatio(imageHeight: submissionHeight, imageWidth: CGFloat(submission.width), viewWidth: (parentWidth == 0 ? (contentView.frame.size.width == 0 ? CGFloat(submission.width) : contentView.frame.size.width) : parentWidth) - (full ? 10 : 0))
            if h == 0 {
                submissionHeight = test ? 150 : 200
            } else {
                submissionHeight = h
            }
        }
        
        if !SettingValues.actionBarMode.isFull() && !full {
            buttons.isHidden = true
            box.isHidden = true
        }
        
        if (type == .SELF && SettingValues.hideImageSelftext) || type == .SELF && full {
            big = false
            thumb = false
        }
        
        if submissionHeight < 75 {
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
        
        if type == .LINK && SettingValues.linkAlwaysThumbnail && !test {
            thumb = true
            big = false
        }
        
        if embedded {
            thumb = true
            big = false
        }
        
        if SettingValues.noImages && SettingValues.dataSavingEnabled && !(SettingValues.dataSavingDisableWiFi && checkWifi) {
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
        
        if self is GalleryLinkCellView {
            big = true
            thumb = false
        }
        
        if !big && !thumb && submission.type != .SELF && submission.type != .NONE { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
            thumbText.isHidden = true
            if submission.nsfw {
                thumbImage.image = SettingValues.thumbTag ? LinkCellImageCache.nsfwUp : LinkCellImageCache.nsfw
                thumbText.isHidden = false
                thumbText.text = type.rawValue.uppercased()
            } else if submission.spoiler {
                thumbImage.image = LinkCellImageCache.spoiler
            } else if type == .REDDIT {
                thumbImage.image = LinkCellImageCache.reddit
            } else {
                thumbImage.image = LinkCellImageCache.web
            }
        } else if thumb && !big {
            thumbText.isHidden = true
            if submission.nsfw && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection && Subscriptions.isCollection(baseSub)) {
                thumbImage.image = SettingValues.thumbTag ? LinkCellImageCache.nsfwUp : LinkCellImageCache.nsfw
                thumbText.isHidden = false
                thumbText.text = type.rawValue.uppercased()
            } else if submission.thumbnailUrl == "web" || submission.thumbnailUrl.isEmpty || submission.spoiler {
                if submission.spoiler {
                    thumbImage.image = LinkCellImageCache.spoiler
                } else if type == .REDDIT {
                    thumbImage.image = LinkCellImageCache.reddit
                } else {
                    thumbImage.image = LinkCellImageCache.web
                }
            } else {
                thumbText.isHidden = false
                thumbText.text = type.rawValue.uppercased()
                print(submission.smallPreview)
                thumbImage.loadImageWithPulsingAnimation(atUrl: URL(string: submission.smallPreview == "" ? submission.thumbnailUrl : submission.smallPreview), withPlaceHolderImage: LinkCellImageCache.web)
            }
        } else {
            thumbImage.image = nil
            thumbText.isHidden = true
            self.thumbImage.frame.size.width = 0
        }
        
        if !SettingValues.thumbTag || full {
            thumbText.isHidden = true
        }
        
        if full {
            self.thumbText.isHidden = true
        }
        
        if big {
            bannerImage.isHidden = false
            self.endVideos()
            bannerImage.alpha = 1
            var videoOverride = false
            if ContentType.displayVideo(t: type) && type != .VIDEO && (self is AutoplayBannerLinkCellView || (self is FullLinkCellView && shouldAutoplay) || self is GalleryLinkCellView) && (SettingValues.autoPlayMode == .ALWAYS || (SettingValues.autoPlayMode == .WIFI && shouldAutoplay)) {
                videoView?.isHidden = false
                topVideoView?.isHidden = false
                sound.isHidden = true
                self.timeView.isHidden = true
                self.updateProgress(-1, "", buffering: false)
                self.contentView.bringSubviewToFront(topVideoView!)
                self.shouldLoadVideo = true
                if full {
                    self.videoCompletion = nil
                    doLoadVideo()
                } else {
                    self.videoCompletion = nil
                    if let url = (!link!.videoPreview.isEmpty() && !ContentType.isGfycat(uri: link!.url!)) ? URL.init(string: link!.videoPreview) : link!.url {
                            self.preloadVideo(url)
                    }
                }
                videoOverride = true
            } else if self is FullLinkCellView || self is GalleryLinkCellView {
                self.videoView.isHidden = true
                self.topVideoView.isHidden = true
                self.timeView.isHidden = true
                self.progressDot.isHidden = true
            }
            
            if (self is AutoplayBannerLinkCellView || self is FullLinkCellView || self is GalleryLinkCellView) && (ContentType.displayVideo(t: type) && type != .VIDEO) && (SettingValues.autoPlayMode == .TAP || (SettingValues.autoPlayMode == .WIFI && !shouldAutoplay)) {
                videoView?.isHidden = false
                topVideoView?.isHidden = false
                sound.isHidden = true
                self.updateProgress(-1, "", buffering: false)
                self.contentView.bringSubviewToFront(topVideoView!)
                self.playView.isHidden = false
                self.progressDot.isHidden = true
                self.timeView.isHidden = true
                self.spinner.isHidden = true
                videoOverride = true
            }
            
            let imageSize = CGSize.init(width: submission.width == 0 ? 400 : submission.width, height: ((full && !SettingValues.commentFullScreen) || (!full && SettingValues.postImageMode == .CROPPED_IMAGE)) && !((self is AutoplayBannerLinkCellView || self is FullLinkCellView || self is GalleryLinkCellView) && (ContentType.displayVideo(t: type) && type != .VIDEO) && (SettingValues.autoPlayMode == .TAP || (SettingValues.autoPlayMode == .WIFI && !shouldAutoplay))) ? 200 : (submission.height == 0 ? 275 : submission.height))
            
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

            // Pulse the background color of the banner image until it loads
            lq = shouldShowLq
            if submission.bannerUrl == "" || submission.width == 0 {
                bannerImage.image = LinkCellImageCache.webBig
            } else {
                let bannerImageUrl = URL(string: shouldShowLq ? submission.lqUrl : submission.bannerUrl)
                loadedImage = bannerImageUrl
                bannerImage.loadImageWithPulsingAnimation(atUrl: bannerImageUrl, withPlaceHolderImage: nil, overrideSize: CGSize(width: (parentWidth == 0 ? (contentView.frame.size.width == 0 ? CGFloat(submission.width) : contentView.frame.size.width) : parentWidth) - ((full && big ? CGFloat(5) : 0) * 2), height: submissionHeight))
            }
            NSLayoutConstraint.deactivate(self.bannerHeightConstraint)
            self.bannerHeightConstraint = batch {
                self.bannerImage.heightAnchor == self.submissionHeight ~ .low
            }
        } else {
            bannerImage.image = nil
            if self is FullLinkCellView {
                self.videoView.isHidden = true
                self.topVideoView.isHidden = true
                self.timeView.isHidden = true
                self.progressDot.isHidden = true
            }
        }
        
        if !full && !test && !embedded {
            aspectWidth = self.contentView.frame.size.width
        }
        
        let mo = History.commentsSince(s: submission)
        comments.text = " \(submission.commentCount)" + (mo > 0 ? "(+\(mo))" : "")
        
        if !registered && !full && SettingValues.submissionActionForceTouch == .NONE {
            parent.registerForPreviewing(with: self, sourceView: self.contentView)
            registered = true
        } else if SettingValues.submissionActionForceTouch != .NONE && force == nil {
            force = ForceTouchGestureRecognizer()
            force?.addTarget(self, action: #selector(self.do3dTouch(_:)))
            force?.cancelsTouchesInView = false
            self.contentView.addGestureRecognizer(force!)
        }
        
        refresh(np: np)
        refreshTitle(np: np)

        if (type != .IMAGE && type != .SELF && !thumb) || (full && (type == .LINK || type == .REDDIT)) || (full && thumb && type != .SELF) {
            infoContainer.isHidden = false
            var text = ""
            switch type {
            case .ALBUM:
                text = ("Album")
            case .REDDIT_GALLERY:
                text = ("Gallery")
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
                let finalText = NSMutableAttributedString.init(string: text, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 14, submission: true)]))
                finalText.append(NSAttributedString.init(string: "\n\(submission.domain)"))
                info.attributedText = finalText
            }
            
        } else {
            infoContainer.isHidden = true
            tagbody.isHidden = true
        }
        
        if submission.isCrosspost && full && !crosspostDone {
            crosspostDone = true
            let outer = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 48))
            let popup = UILabel()
            outer.backgroundColor = ColorUtil.theme.backgroundColor
            popup.textAlignment = .left
            popup.isUserInteractionEnabled = true
            
            popup.numberOfLines = 2
            
            outer.elevate(elevation: 2)
            outer.layer.cornerRadius = 5
            outer.clipsToBounds = true
            
            let icon = UIImageView(image: UIImage(named: "crosspost")!.getCopy(withSize: CGSize.square(size: 20), withColor: ColorUtil.theme.fontColor))
            outer.addSubviews(icon, popup)
            icon.leftAnchor == outer.leftAnchor + CGFloat(8)
            icon.centerYAnchor == outer.centerYAnchor
            icon.widthAnchor == 40
            icon.contentMode = .center

            popup.leftAnchor == icon.rightAnchor + CGFloat(8)
            popup.verticalAnchors == outer.verticalAnchors
            popup.rightAnchor == outer.rightAnchor - CGFloat(8)
            
            infoBox.spacing = 4
            
            let colorF = ColorUtil.theme.fontColor
            
            let attrs = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF] as [String: Any]
            
            let boldString = NSMutableAttributedString(string: "r/\(submission.crosspostSubreddit)", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs))
            let color = ColorUtil.getColorForSub(sub: submission.crosspostSubreddit)
            if color != ColorUtil.baseColor {
                boldString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange.init(location: 0, length: boldString.length))
            }
            
            let endString = NSMutableAttributedString(string: "\nCrossposted by", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))
            
            let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: submission.crosspostAuthor, small: false))\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): colorF]))
            
            /* Maybe enable this later
             let userColor = ColorUtil.getColorForUser(name: submission.crosspostAuthor)
             if AccountController.currentName == submission.author {
             authorString.addAttributes(convertToNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]), range: NSRange.init(location: 0, length: authorString.length))
             } else if userColor != ColorUtil.baseColor {
             authorString.addAttributes(convertToNSAttributedStringKeyDictionary([kTTTBackgroundFillColorAttributeName: userColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3]), range: NSRange.init(location: 0, length: authorString.length))
             }*/
            
            endString.append(authorString)
            boldString.append(endString)
            
            outer.addTapGestureRecognizer {
                VCPresenter.openRedditLink(submission.crosspostPermalink, self.parentViewController?.navigationController, self.parentViewController)
            }
            popup.attributedText = boldString
            
            popup.numberOfLines = 0
            
            infoBox.spacing = 4
            infoBox.addArrangedSubview(outer)
            
            outer.horizontalAnchors == infoBox.horizontalAnchors
            outer.heightAnchor == 48
        }

       // TODO: - maybe? self.contentView.backgroundColor = ColorUtil.getColorForSub(sub: submission.subreddit)
        if full {
            self.setNeedsLayout()
            self.layoutForType()
        }

    }

    private func refreshAccessibility(submission: RSubmission) {
        //let postTimeAgo = (submission.created as Date).timeAgoString Was causing lag
        accessibilityView.accessibilityValue = """
            \(submission.title).
            Post type is \(submission.type.rawValue).
            Posted in \(submission.subreddit) by \(submission.author).
            The score is \(submission.score) and there are \(submission.commentCount) comments.
            \(full ? "Post body: \(submission.body)" : "")
        """
        if full {
            switch submission.type {
            case .SELF:
                accessibilityView.accessibilityHint = nil
            case .LINK, .UNKNOWN:
                accessibilityView.accessibilityHint = "Opens the link for this post. Link goes to \(submission.domain)"
            default:
                accessibilityView.accessibilityHint = "Opens the media modal with this link. Link is from \(submission.domain)"
            }
        } else {
            accessibilityView.accessibilityHint = "Opens the post view for this post."
        }

        let actionManager = PostActionsManager(submission: submission)

        let isReadLater = ReadLater.isReadLater(id: submission.getId())
        let isSaved = ActionStates.isSaved(s: submission)

        var actions: [UIAccessibilityCustomAction] = [
            UIAccessibilityCustomAction(name: "Menu", target: self, selector: #selector(more(sender:))),
            UIAccessibilityCustomAction(name: isReadLater ? "Remove from Read Later list" : "Read Later", target: self, selector: #selector(readLater(sender:))),
            UIAccessibilityCustomAction(name: "Hide", target: self, selector: #selector(hide(sender:))),
            ]

        if actionManager.isSavePossible {
            actions.append(UIAccessibilityCustomAction(name: isSaved ? "Unsave" : "Save", target: self, selector: #selector(save(sender:))))
        }

        if actionManager.isVotingPossible {
            let downvoteActionString: String
            let upvoteActionString: String

            switch ActionStates.getVoteDirection(s: submission) {
            case .down:
                downvoteActionString = "Remove Downvote"
                upvoteActionString = "Upvote"
            case .up:
                downvoteActionString = "Downvote"
                upvoteActionString = "Remove Upvote"
            default:
                downvoteActionString = "Downvote"
                upvoteActionString = "Upvote"
            }
            
            actions.append(UIAccessibilityCustomAction(name: upvoteActionString, target: self, selector: #selector(upvote(sender:))))
            actions.append(UIAccessibilityCustomAction(name: downvoteActionString, target: self, selector: #selector(downvote(sender:))))
        }

        if actionManager.isEditPossible && full {
            actions.append(UIAccessibilityCustomAction(name: "Edit", target: self, selector: #selector(edit(sender:))))
        }

        if actionManager.isReplyPossible && full {
            actions.append(UIAccessibilityCustomAction(name: "Reply", target: self, selector: #selector(reply(sender:))))
        }

        if actionManager.isModPossible {
            actions.append(UIAccessibilityCustomAction(name: "Moderate", target: self, selector: #selector(mod(sender:))))
        }

        if actionManager.isShareEnabled {
            actions.append(UIAccessibilityCustomAction(name: "Share", target: self, selector: #selector(share(sender:))))
        }

        accessibilityView.accessibilityCustomActions = actions

    }

    override func accessibilityActivate() -> Bool {
        if full {
            openLink()
        } else {
            openComment()
        }
        return true
    }
    
    var currentType: CurrentType = .none
    static var checkedWifi = false
    static var cachedCheckWifi = false
    
    public static func checkWiFi() -> Bool {
        if !checkedWifi {
            checkedWifi = true
            let networkStatus = Reachability().connectionStatus()
            switch networkStatus {
            case .Unknown, .Offline:
                cachedCheckWifi = false
            case .Online(.WWAN):
                cachedCheckWifi = false
            case .Online(.WiFi):
                cachedCheckWifi = true
            }
        }
        return cachedCheckWifi
    }
    
    var videoURL: URL?
    weak var videoTask: URLSessionDataTask?
    var videoLoaded = false
    var videoPreloaded = false
    var isLoadingVideo = false
    var videoCompletion: (() -> Void)?
    var lastVideoTried = ""
    
    func preloadVideo(_ baseUrl: URL) {
        self.isLoadingVideo = true
        self.lastVideoTried = baseUrl.absoluteString
        
        self.videoPreloaded = false
        let url = VideoMediaViewController.format(sS: baseUrl.absoluteString, true)
        let videoType = VideoMediaViewController.VideoType.fromPath(url)
        self.videoTask = videoType.getSourceObject().load(url: url, completion: { [weak self] (urlString) in
            guard let strongSelf = self else { return }
            let videoURL = URL(string: urlString)
            if videoURL == nil {
                DispatchQueue.main.async {[weak self] in
                    if let strongSelf = self, let url = URL.init(string: strongSelf.link?.videoPreview ?? "") {
                        if url.absoluteString != strongSelf.lastVideoTried {
                            strongSelf.preloadVideo(url)
                        }
                    }
                }
                return
            }
            strongSelf.videoURL = videoURL!
            
            strongSelf.videoPreloaded = true
            strongSelf.isLoadingVideo = false
            DispatchQueue.main.async {
                strongSelf.videoCompletion?()
            }
            }, failure: nil)
    }

    func doLoadVideo() {
        if self is AutoplayBannerLinkCellView || self is GalleryLinkCellView || self is FullLinkCellView {
            if videoPreloaded {
                playVideo()
            } else if isLoadingVideo {
                videoCompletion = {
                    self.playVideo()
                }
            } else {
                videoCompletion = {
                    self.playVideo()
                }
                if let url = (!link!.videoPreview.isEmpty() && !ContentType.isGfycat(uri: link!.url!)) ? URL.init(string: link!.videoPreview) : link!.url {
                        self.preloadVideo(url)
                }
            }
        }
    }
    
    func playVideo() {
        if !shouldLoadVideo || !AnyModalViewController.linkID.isEmpty() {
            if self.playView != nil {
                self.playView.isHidden = false
                self.spinner.isHidden = true
                self.playView.alpha = 0
                UIView.animate(withDuration: 0.1) { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.playView.alpha = 1
                }
            }
            return
        }
        
        let strongSelf = self
        
        strongSelf.videoView?.player = AVPlayer(playerItem: AVPlayerItem(url: strongSelf.videoURL!))
        strongSelf.videoView?.player?.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
//                Is currently causing issues with not resuming after buffering
//                if #available(iOS 10.0, *) {
//                    strongSelf.videoView?.player?.automaticallyWaitsToMinimizeStalling = false
//                }
        strongSelf.setOnce = false
        if #available(iOS 10.0, *) {
            strongSelf.videoView?.player?.playImmediately(atRate: 1.0)
        } else {
            strongSelf.videoView?.player?.play()
        }
        strongSelf.videoID = strongSelf.link?.getId() ?? ""
        if SettingValues.muteInlineVideos {
            strongSelf.videoView?.player?.isMuted = true
        } else {
            strongSelf.videoView?.player?.isMuted = false
        }
        strongSelf.sound.addTarget(strongSelf, action: #selector(strongSelf.unmute), for: .touchUpInside)
        strongSelf.updater = CADisplayLink(target: strongSelf, selector: #selector(strongSelf.displayLinkDidUpdate))
        strongSelf.updater?.add(to: .current, forMode: RunLoop.Mode.default)
        strongSelf.updater?.isPaused = false
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
    
    @objc func showMore() {
        timer!.invalidate()
        if longBlocking {
            self.longBlocking = false
            return
        }
        if !self.cancelled && LinkCellView.checkInternet() && parentViewController?.presentedViewController == nil {
            if #available(iOS 10.0, *) {
                HapticUtility.hapticActionStrong()
            } else if SettingValues.hapticFeedback {
                AudioServicesPlaySystemSound(1519)
            }
            self.more()
        }
    }
    
    var handlingPlayerItemDidreachEnd = false
    
    func playerItemDidreachEnd() {
        self.videoView?.player?.seek(to: CMTimeMake(value: 1, timescale: 1000), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { [weak self] (_) in
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
    var lastTime = Float(0)
    
    private func getTimeString(_ time: Int) -> String {
        let h = time / 3600
        let m = (time % 3600) / 60
        let s = (time % 3600) % 60
        return h > 0 ? String(format: "%1d:%02d:%02d", h, m, s) : String(format: "%1d:%02d", m, s)
    }
    
    var setOnce = false
    // TODO: - This is problematic. We shouldn't be setting up a display link for individual cells.
    @objc func displayLinkDidUpdate(displaylink: CADisplayLink) {
        guard let player = videoView.player else {
            return
        }

        let hasAudioTracks = (player.currentItem?.tracks.count ?? 1) > 1
        
        if hasAudioTracks {
            if player.isMuted && sound.isHidden && SettingValues.muteInlineVideos {
                sound.isHidden = false
            }
        }

        if !setOnce {
            setOnce = true
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            } catch {
                NSLog(error.localizedDescription)
            }
        }

        if let currentItem = player.currentItem {
            let elapsedTime = player.currentTime()
            if CMTIME_IS_INVALID(elapsedTime) {
                return
            }
            let duration = Float(CMTimeGetSeconds(currentItem.duration))
            let time = Float(CMTimeGetSeconds(elapsedTime))

            if duration.isFinite && duration > 0 {
                updateProgress(CGFloat(time / duration), "\(getTimeString(Int(floor(1 + duration - time))))",
                    buffering: !currentItem.isPlaybackLikelyToKeepUp)
            }
            if !handlingPlayerItemDidreachEnd && ((time / duration) >= 0.999 || ((time / duration) >= 0.97 && lastTime == time)) {
                handlingPlayerItemDidreachEnd = true
                self.playerItemDidreachEnd()
            }
            lastTime = time
        }
    }
    
    var longBlocking = false
    
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            cancelled = false
            timer = Timer.scheduledTimer(timeInterval: 0.36,
                                         target: self,
                                         selector: #selector(self.showMore),
                                         userInfo: nil,
                                         repeats: false)
            
        }
        if sender.state == UIGestureRecognizer.State.ended {
            timer!.invalidate()
            cancelled = true
            longBlocking = false
        }
    }
    
    @objc func edit(sender: AnyObject) {
        let link = self.link!
        
        let alertController = DragDownAlertMenu(title: "Manage your submission", subtitle: link.title, icon: link.thumbnailUrl)
        
        if link.isSelf {
            alertController.addAction(title: "Edit selftext", icon: UIImage(sfString: SFSymbol.pencil, overrideString: "edit")!.menuIcon()) {
                self.editSelftext()
            }
        }
        alertController.addAction(title: "Set flair", icon: UIImage(sfString: SFSymbol.flagFill, overrideString: "flag")!.menuIcon()) {
            self.flairSelf()
        }
        
        alertController.addAction(title: "Delete submission", icon: UIImage(sfString: SFSymbol.trashFill, overrideString: "delete")!.menuIcon().getCopy(withColor: GMColor.red500Color())) {
            self.deleteSelf(self)
        }

        if parentViewController != nil {
            alertController.show(parentViewController)
        }
    }
    
    func editSelftext() {
        let reply = ReplyViewController.init(submission: link!, sub: (self.link?.subreddit)!) { (cr) in
            DispatchQueue.main.async(execute: { () -> Void in
                self.setLink(submission: RealmDataWrapper.linkToRSubmission(submission: cr!), parent: self.parentViewController!, nav: self.navViewController!, baseSub: (self.link?.subreddit)!, np: false)
                self.showBody(width: self.contentView.frame.size.width - 24)
            })
        }
        
        let navEditorViewController: UINavigationController = UINavigationController(rootViewController: reply)
        parentViewController?.present(navEditorViewController, animated: true, completion: nil)
       // TODO: - new implementation
    }
    
    func deleteSelf(_ cell: LinkCellView) {
        let alertController = DragDownAlertMenu(title: "Really delete your submission?", subtitle: "This cannot be undone", icon: link!.thumbnailUrl)
        
        alertController.addAction(title: "Delete", icon: UIImage(sfString: SFSymbol.trashFill, overrideString: "delete")!.menuIcon().getCopy(withColor: GMColor.red500Color())) {
            if let delegate = self.del {
                delegate.deleteSelf(self)
            }
        }
        
        alertController.addAction(title: "Cancel", icon: UIImage(sfString: SFSymbol.xmark, overrideString: "close")!.menuIcon()) {
            alertController.dismiss(animated: true, completion: nil)
        }

        alertController.show(parentViewController)
    }
    
    var lockDone = false
    var crosspostDone = false

    func flairSelf() {
       // TODO: - this
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
                        let sheet = DragDownAlertMenu(title: "r/\(self.link!.subreddit) flairs", subtitle: "", icon: nil, themeColor: ColorUtil.accentColorForSub(sub: self.link!.subreddit), full: true)

                        for flair in flairs {
                            sheet.addAction(title: (flair.text.isEmpty) ? flair.name : flair.text, icon: nil, action: {
                                self.setFlair(flair)
                            })
                        }
                        sheet.show(self.parentViewController)
                    }
                }
            })
        } catch {
        }
    }
    
    var flairText: String?
    
    func setFlair(_ flair: FlairTemplate) {
        if flair.editable {
            let alert = DragDownAlertMenu(title: "Edit flair text", subtitle: "\(flair.name)", icon: nil)
            
            alert.addTextInput(title: "Set flair", icon: UIImage(sfString: SFSymbol.flag, overrideString: "save-1")?.menuIcon(), action: {
                self.submitFlairChange(flair, text: alert.getText() ?? "")
            }, inputPlaceholder: "Flair text...", inputValue: flair.text, inputIcon: UIImage(sfString: SFSymbol.flagFill, overrideString: "flag")!.menuIcon(), textRequired: true, exitOnAction: true)
            
            alert.show(parentViewController)
        } else {
            submitFlairChange(flair)
        }
    }
    
    @objc func unmute() {
        if self.videoView?.player?.isMuted ?? true {
            try? AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            self.videoView?.player?.isMuted = false
            
            UIView.animate(withDuration: 0.5, animations: {
                self.sound.setImage(UIImage(sfString: SFSymbol.volume2Fill, overrideString: "audio")?.navIcon(), for: UIControl.State.normal)
            }, completion: nil)
        } else {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            self.videoView?.player?.isMuted = true
            
            UIView.animate(withDuration: 0.5, animations: {
                self.sound.setImage(UIImage(sfString: SFSymbol.volumeSlashFill, overrideString: "mute")?.getCopy(withSize: CGSize.square(size: 20), withColor: GMColor.red400Color()), for: .normal)
            }, completion: nil)
        }
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
                        _ = CachedTitle.getTitle(submission: self.link!, full: true, true, false, gallery: false)
                        self.setLink(submission: self.link!, parent: self.parentViewController!, nav: self.navViewController!, baseSub: (self.link?.subreddit)!, np: false)
                        if self.textView != nil {
                            self.showBody(width: self.contentView.frame.size.width - 24)
                        }
                    }
                }}
        } catch {
        }
    }
    
    func refresh(np: Bool = false) {
        let link = self.link!

        upvote.setImage(LinkCellImageCache.upvote, for: .normal)
        downvote.setImage(LinkCellImageCache.downvote, for: .normal)
        sideUpvote.setImage(LinkCellImageCache.upvoteSmall, for: .normal)
        sideDownvote.setImage(LinkCellImageCache.downvoteSmall, for: .normal)
        share.setImage(LinkCellImageCache.share, for: .normal)
        menu.setImage(LinkCellImageCache.menu, for: .normal)

        save.setImage(ActionStates.isSaved(s: link) ? LinkCellImageCache.saveTinted : LinkCellImageCache.save, for: .normal)
        mod.setImage(link.reports.isEmpty ? LinkCellImageCache.mod : LinkCellImageCache.modTinted, for: .normal)
        readLater.setImage(ReadLater.isReadLater(id: link.getId()) ? LinkCellImageCache.readLaterTinted : LinkCellImageCache.readLater, for: .normal)
        
        var attrs: [NSAttributedString.Key: Any] = [:]
        switch ActionStates.getVoteDirection(s: link) {
        case .down:
            downvote.setImage(LinkCellImageCache.downvoteTinted, for: .normal)
            sideDownvote.setImage(LinkCellImageCache.downvoteTintedSmall, for: .normal)
            attrs = ([NSAttributedString.Key.foregroundColor: ColorUtil.downvoteColor, NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true)])
        case .up:
            upvote.setImage(LinkCellImageCache.upvoteTinted, for: .normal)
            sideUpvote.setImage(LinkCellImageCache.upvoteTintedSmall, for: .normal)
            attrs = ([NSAttributedString.Key.foregroundColor: ColorUtil.upvoteColor, NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true)])
        default:
            attrs = ([NSAttributedString.Key.foregroundColor: ColorUtil.theme.navIconColor, NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true)])
        }
        
        var scoreInt = link.score
        switch ActionStates.getVoteDirection(s: link) {
        case .up:
            if link.likes != .up {
                if link.likes == .down {
                    scoreInt += 1
                }
                scoreInt += 1
            }
        case .down:
            if link.likes != .down {
                if link.likes == .up {
                    scoreInt -= 1
                }
                scoreInt -= 1
            }
        case .none:
            if link.likes == .up && link.author == AccountController.currentName {
                scoreInt -= 1
            }
        }
        if full {
            let subScore = NSMutableAttributedString(string: (scoreInt >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(scoreInt) / Double(1000))) : " \(scoreInt)", attributes: attrs)
            let scoreRatio =
                NSMutableAttributedString(string: (SettingValues.upvotePercentage && full && link.upvoteRatio > 0) ?
                    " (\(Int(link.upvoteRatio * 100))%)" : "", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): comments.font ?? UIFont.systemFont(ofSize: 14), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): comments.textColor ?? ColorUtil.theme.fontColor]))
            
            var attrsNew: [String: Any] = [:]
            if scoreRatio.length > 0 {
                let numb = (link.upvoteRatio)
                if numb <= 0.5 {
                    if numb <= 0.1 {
                        attrsNew = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): GMColor.blue500Color()]
                    } else if numb <= 0.3 {
                        attrsNew = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): GMColor.blue400Color()]
                    } else {
                        attrsNew = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): GMColor.blue300Color()]
                    }
                } else {
                    if numb >= 0.9 {
                        attrsNew = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): GMColor.orange500Color()]
                    } else if numb >= 0.7 {
                        attrsNew = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): GMColor.orange400Color()]
                    } else {
                        attrsNew = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): GMColor.orange300Color()]
                    }
                }
            }
            
            scoreRatio.addAttributes(convertToNSAttributedStringKeyDictionary(attrsNew), range: NSRange.init(location: 0, length: scoreRatio.length))
            
            subScore.append(scoreRatio)
            score.attributedText = subScore
        } else {
            let sideText = (scoreInt >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(scoreInt) / Double(1000))) : " \(scoreInt)"
            var attrsCopy = attrs
            if !SettingValues.actionBarMode.isFull() && sideText.length > 5 && !full {
                attrsCopy[NSAttributedString.Key.font] = FontGenerator.boldFontOfSize(size: 10, submission: true)
            }
            let scoreString = NSAttributedString(string: sideText, attributes: attrsCopy)
            
            if SettingValues.actionBarMode.isFull() {
                score.attributedText = scoreString
            } else if SettingValues.actionBarMode != .NONE {
                sideScore.attributedText = scoreString
            }
        }
        if full && !lockDone {
            lockDone = true
            
            var text = ""
            var icon = ""
            if np {
                text = "This is a no participation link.\nPlease don't vote or comment"
                icon = "close"
            }
            if link.archived {
                text = "This is an archived post.\nYou won't be able to vote or comment"
                icon = "multis"
            } else if link.locked {
                text = "This is a locked post.\nYou won't be able to comment"
                icon = "lock"
            }
            
            if type != .IMAGE && type != .SELF && type != .NONE && !thumb {
                let outer = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 48))
                let popup = UILabel()
                outer.backgroundColor = ColorUtil.theme.foregroundColor.add(overlay: ColorUtil.getColorForSub(sub: link.subreddit).withAlphaComponent(0.2))
                popup.textAlignment = .left
                popup.isUserInteractionEnabled = true
                
                let finalText: NSMutableAttributedString!
                let firstPart = NSMutableAttributedString.init(string: type.getTitle(link.url), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
                let secondPart = NSMutableAttributedString.init(string: "\n" + link.urlString, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12)]))
                firstPart.append(secondPart)
                finalText = firstPart
                popup.attributedText = finalText
                
                popup.numberOfLines = 2
                
                outer.elevate(elevation: 2)
                outer.layer.cornerRadius = 5
                outer.clipsToBounds = true
                
                let icon = UIImageView(image: UIImage(named: type.getImage())!.getCopy(withSize: CGSize.square(size: 20), withColor: ColorUtil.theme.fontColor))
                outer.addSubviews(icon, popup)
                icon.leftAnchor == outer.leftAnchor + CGFloat(8)
                icon.centerYAnchor == outer.centerYAnchor
                icon.widthAnchor == 40
                icon.contentMode = .center

                popup.leftAnchor == icon.rightAnchor + CGFloat(8)
                popup.verticalAnchors == outer.verticalAnchors
                popup.rightAnchor == outer.rightAnchor - CGFloat(8)
                
                infoBox.spacing = 4
                infoBox.addArrangedSubview(outer)
                
                outer.horizontalAnchors == infoBox.horizontalAnchors
                outer.heightAnchor == 48
                
                outer.addTapGestureRecognizer {
                    let shareItems: Array = [link.url]
                    let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems as [Any], applicationActivities: nil)
                    if let presenter = activityViewController.popoverPresentationController {
                        presenter.sourceView = outer
                        presenter.sourceRect = outer.bounds
                    }
                    self.parentViewController?.present(activityViewController, animated: true, completion: nil)
                }
            }
            
            if !text.isEmpty {
                let outer = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 48))
                let popup = UILabel()
                outer.backgroundColor = ColorUtil.getColorForSub(sub: link.subreddit)
                popup.textAlignment = .left
                popup.isUserInteractionEnabled = true

                let textParts = text.components(separatedBy: "\n")
                
                let finalText: NSMutableAttributedString!
                if textParts.count > 1 {
                    let firstPart = NSMutableAttributedString.init(string: textParts[0], attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
                    let secondPart = NSMutableAttributedString.init(string: "\n" + textParts[1], attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12)]))
                    firstPart.append(secondPart)
                    finalText = firstPart
                } else {
                    finalText = NSMutableAttributedString.init(string: text, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
                }
                popup.attributedText = finalText
                
                popup.numberOfLines = 2
                
                outer.elevate(elevation: 2)
                outer.layer.cornerRadius = 5
                outer.clipsToBounds = true
                
                let icon = UIImageView(image: UIImage(named: icon)!.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor.white))
                outer.addSubviews(icon, popup)
                icon.leftAnchor == outer.leftAnchor + CGFloat(8)
                icon.centerYAnchor == outer.centerYAnchor
                icon.widthAnchor == 40
                icon.contentMode = .center
                
                popup.leftAnchor == icon.rightAnchor + CGFloat(8)
                popup.verticalAnchors == outer.verticalAnchors
                popup.rightAnchor == outer.rightAnchor - CGFloat(8)
                
                infoBox.spacing = 4
                infoBox.addArrangedSubview(outer)
                
                outer.horizontalAnchors == infoBox.horizontalAnchors
                outer.heightAnchor == 48
            }
        }

        if History.getSeen(s: link) && !full && !SettingValues.newIndicator {
            self.title.alpha = 0.3
        } else {
            self.title.alpha = 1
        }

        refreshAccessibility(submission: link)
    }
    
    override func layoutSubviews() {
        if typeImage != nil {
            return
        }
        super.layoutSubviews()
        var topmargin = 0
        var bottommargin = 2
        var leftmargin = 0
        var rightmargin = 0
        
        if (SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full && !(self is GalleryLinkCellView){
            topmargin = 5
            bottommargin = 5
            leftmargin = 5
            rightmargin = 5
            if !SettingValues.flatMode {
                self.contentView.elevate(elevation: 2)
            }
        }
        
        let f = self.contentView.frame
        let fr = f.inset(by: UIEdgeInsets(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin)))
        self.contentView.frame = fr
    }
    
    var registered: Bool = false
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        // TODO: - this
        /* if full {
            let locationInTextView = textView.convert(location, to: textView)
            
            if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
                previewingContext.sourceRect = textView.convert(rect, from: textView)
                if let controller = parentViewController?.getControllerForUrl(baseUrl: url) {
                    return controller
                }
            }
        } else {*/
            History.addSeen(s: link!)
            if History.getSeen(s: link!) && !SettingValues.newIndicator {
                self.title.alpha = 0.3
            } else {
                self.title.alpha = 1
            }
        if let url = link?.url, let controller = parentViewController?.getControllerForUrl(baseUrl: url, link: link!) {
                return controller
            }
        //}
        return nil
    }
    
    func estimateHeight(_ full: Bool, _ reset: Bool = false, np: Bool) -> CGFloat {
        if estimatedHeight == 0 || reset {
            var paddingTop = CGFloat(0)
            var paddingBottom = CGFloat(2)
            var paddingLeft = CGFloat(0)
            var paddingRight = CGFloat(0)
            var innerPadding = CGFloat(0)
            if (SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full && !(self is GalleryLinkCellView) {
                paddingTop = 5
                paddingBottom = 5
                paddingLeft = 5
                paddingRight = 5
            }
            
            let actionbar = CGFloat(!full && !SettingValues.actionBarMode.isFull() ? 0 : 24)

            var imageHeight = big && !thumb ? CGFloat(submissionHeight) : CGFloat(0)
            let thumbheight = (full || SettingValues.largerThumbnail ? CGFloat(75) : CGFloat(50)) - (!full && SettingValues.postViewMode == .COMPACT ? 15 : 0)
            
            let textHeight = (!hasText || !full) ? CGFloat(0) : textView.estimatedHeight
            
            if thumb {
                imageHeight = thumbheight
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between top and thumbnail
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
                } else if SettingValues.actionBarMode.isFull() || SettingValues.actionBarMode == .NONE {
                    estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT && !full ? 16 : 24) //12 padding on either side
                }
            } else {
                estimatedUsableWidth -= (24) //12 padding on either side
                if thumb {
                    fullHeightExtras += 45 + 12 + 12
                } else {
                    fullHeightExtras += imageHeight
                }
                
                if link!.archived || link!.locked || np {
                    fullHeightExtras += 56
                }
                
                if type != .IMAGE && type != .SELF && type != .NONE && !thumb {
                    fullHeightExtras += 56
                }
        
                if link!.isCrosspost {
                    fullHeightExtras += 56
                    if link!.archived || link!.locked || np {
                        fullHeightExtras += 8
                    }
                }
            }
            
            if SettingValues.actionBarMode.isSide() && !full {
                estimatedUsableWidth -= 40
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT && !full ? 8 : 16) //buttons horizontal margins
            }
            
            //Temporary fix to iOS 14 crash
            //TODO fix
            if estimatedUsableWidth < 0 {
                estimatedUsableWidth = 100
            }
            
            let size = CGSize(width: estimatedUsableWidth, height: CGFloat.greatestFiniteMagnitude)
            let layout = YYTextLayout(containerSize: size, text: title.attributedText!)!
            title.textLayout = layout
            let textSize = layout.textBoundingSize
            
            let totalHeight = paddingTop + paddingBottom + (full ? ceil(textSize.height) : (thumb && !full ? max((!full && SettingValues.actionBarMode.isSide() ? max(ceil(textSize.height), 72) : ceil(textSize.height)), imageHeight) : (!full && SettingValues.actionBarMode.isSide() ? max(ceil(textSize.height), 72) : ceil(textSize.height)) + imageHeight)) + innerPadding + actionbar + textHeight + fullHeightExtras + CGFloat(5)
            estimatedHeight = totalHeight
        }
        return estimatedHeight
    }
    
    func estimateHeightSingle(_ full: Bool, np: Bool, attText: NSAttributedString) -> YYTextLayout {
        var paddingLeft = CGFloat(0)
        var paddingRight = CGFloat(0)
        var innerPadding = CGFloat(0)
        if (SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full && !(self is GalleryLinkCellView) {
            paddingLeft = 5
            paddingRight = 5
        }
        var imageHeight = big && !thumb ? CGFloat(submissionHeight) : CGFloat(0)
        let thumbheight = (full || SettingValues.largerThumbnail ? CGFloat(75) : CGFloat(50)) - (!full && SettingValues.postViewMode == .COMPACT ? 15 : 0)
        
        if thumb {
            imageHeight = thumbheight
            innerPadding += (SettingValues.postViewMode == .COMPACT && !full ? 8 : 12) //between top and thumbnail
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
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT && !full ? 8 : 12) //between thumb and label
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
            
            if link!.archived || link!.locked || np {
                fullHeightExtras += 56
            }
            
            fullHeightExtras += 8
            
            if link!.isCrosspost {
                fullHeightExtras += 56
            }
        }
        
        if SettingValues.actionBarMode.isSide() && !full {
            estimatedUsableWidth -= 40
            estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 8 : 16) //buttons horizontal margins
            if thumb {
                estimatedUsableWidth += (SettingValues.postViewMode == .COMPACT ? 16 : 24) //between edge and thumb no longer exists
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 4 : 8) //buttons buttons and thumb
            }
        }
        
        //Temporary fix to iOS 14 crash
        //TODO fix
        if estimatedUsableWidth < 0 {
            estimatedUsableWidth = 100
        }
        
        let size = CGSize(width: estimatedUsableWidth, height: CGFloat.greatestFiniteMagnitude)
        let layout = YYTextLayout(containerSize: size, text: attText)!
        return layout
    }
    
    // TODO: - this
    /*
    func getInfo(locationInTextView: CGPoint) -> (URL, CGRect)? {
        if let attr = textView.firstTextView.link(at: locationInTextView) {
            return (attr.result.url!, attr.accessibilityFrame)
        }
        return nil
    }
    */
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if viewControllerToCommit is AlbumViewController {
            viewControllerToCommit.modalPresentationStyle = .overFullScreen
            parentViewController?.present(viewControllerToCommit, animated: true, completion: nil)
        } else if viewControllerToCommit is ModalMediaViewController || viewControllerToCommit is AnyModalViewController {
            viewControllerToCommit.modalPresentationStyle = .overFullScreen
            parentViewController?.present(viewControllerToCommit, animated: true, completion: nil)
        } else {
            VCPresenter.showVC(viewController: viewControllerToCommit, popupIfPossible: true, parentNavigationController: parentViewController?.navigationController, parentViewController: parentViewController)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var parentViewController: (UIViewController & MediaVCDelegate)?
    weak var previewedVC: UIViewController?
    var previewedImage = false
    var previewedVideo = false
    var previewedURL: URL?
    weak var navViewController: UIViewController?
    
    @objc func openLink(sender: UITapGestureRecognizer? = nil) {
        if let link = link {
            (parentViewController)?.setLink(link: link, shownURL: loadedImage, lq: lq, saveHistory: true, heroView: big ? bannerImage : thumbImage, finalSize: CGSize(width: link.width, height: link.height), heroVC: parentViewController, upvoteCallbackIn: {[weak self] in
                if let strongSelf = self {
                    strongSelf.upvote()
                }
            })// TODO: - check this
            if History.getSeen(s: link) && !full && !SettingValues.newIndicator {
                self.title.alpha = 0.3
            } else {
                self.title.alpha = 1
            }
        }
    }
    
    @objc func openLinkVideo(sender: UITapGestureRecognizer? = nil) {
        if !playView.isHidden {
            shouldLoadVideo = true
            doLoadVideo()
            playView.isHidden = true
            self.spinner.isHidden = false
            self.progressDot.isHidden = false
        } else if self.videoView.player != nil && self.videoView.player?.currentItem != nil && self.videoView.player!.currentItem!.presentationSize.width != 0 {
            let upvoted = ActionStates.getVoteDirection(s: link!) == VoteDirection.up
            let controller = AnyModalViewController(cellView: self, full ? nil : {[weak self] in
                if let strongSelf = self {
                    strongSelf.doOpenComment()
                }
            }, upvoteCallback: {[weak self] in
                if let strongSelf = self {
                    strongSelf.upvote()
                }
            }, isUpvoted: upvoted, failure: nil)
            let postContentTransitioningDelegate = PostContentPresentationManager()
            postContentTransitioningDelegate.sourceImageView = self.videoView
            controller.transitioningDelegate = postContentTransitioningDelegate
            controller.modalPresentationStyle = .custom
            controller.forceStartUnmuted = !self.videoView.player!.isMuted
            
            parentViewController?.present(controller, animated: true, completion: nil)
        }
    }
    
    @objc func openComment(sender: UITapGestureRecognizer? = nil) {
        doOpenComment()
    }
    
    @objc public func doOpenComment() {
        if !full {
            if let delegate = self.del {
                if videoView != nil {
                    videoView?.player?.pause()
                }
                History.addSeen(s: link!, skipDuplicates: true)
                delegate.openComments(id: link!.getId(), subreddit: link!.subreddit)
                if History.getSeen(s: link!) && !SettingValues.newIndicator {
                    self.title.alpha = 0.3
                } else {
                    self.title.alpha = 1
                }
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
            
            let img = UIImage(named: imageName)?.getCopy(withSize: .square(size: self.font.pointSize), withColor: ColorUtil.theme.navIconColor)
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

// TODO: - This function will be on every UIView, not just those that conform to MaterialView.
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

private extension UIView {

    func startPulsingAnimation() {
        self.alpha = 0.025
        UIView.animateKeyframes(withDuration: 1.6, delay: 0, options: [.allowUserInteraction, .repeat, .calculationModeCubicPaced], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                self.alpha = 0.09
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self.alpha = 0.025
            }
        })
    }

}

public extension UIImageView {
    func loadImageWithPulsingAnimation(atUrl url: URL?, withPlaceHolderImage placeholderImage: UIImage?, overrideSize: CGSize?  = nil) {
        let oldBackgroundColor: UIColor? = self.backgroundColor
        self.backgroundColor = ColorUtil.theme.fontColor

        startPulsingAnimation()

        var frame = CGSize(width: self.frame.size.width * UIScreen.main.scale, height: self.frame.size.height * UIScreen.main.scale)
        if let newSize = overrideSize {
            frame = CGSize(width: newSize.width * UIScreen.main.scale, height: newSize.height * UIScreen.main.scale)
        }
        DispatchQueue.global(qos: .userInteractive).async {
            self.sd_setImage(with: url, placeholderImage: placeholderImage, options: [.decodeFirstFrameOnly, .allowInvalidSSLCertificates], context: [.imageThumbnailPixelSize: frame], progress: nil) { (_, _, cacheType, _) in
                self.layer.removeAllAnimations() // Stop the pulsing animation
                self.backgroundColor = oldBackgroundColor

                if cacheType == .none {
                    UIView.animate(withDuration: 0.3, delay: 0, options: .allowUserInteraction, animations: {
                        self.alpha = 1
                    })
                } else {
                    self.alpha = 1
                }
            }
        }
    }
}

class PostActionsManager {
    var submission: RSubmission

    private lazy var networkActionsArePossible: Bool = {
        return AccountController.isLoggedIn && LinkCellView.checkInternet()
    }()

    var isSaveEnabled: Bool {
        return SettingValues.saveButton
    }

    var isHideEnabled: Bool {
        return SettingValues.hideButton
    }
    
    var isMenuEnabled: Bool {
        return SettingValues.menuButton
    }
    
    var isShareEnabled: Bool {
        return SettingValues.shareButton
    }

    var isReadLaterEnabled: Bool {
        return SettingValues.readLaterButton
    }

    var isVotingPossible: Bool {
        return networkActionsArePossible && !submission.archived
    }

    var isSavePossible: Bool {
        return networkActionsArePossible
    }

    var isEditPossible: Bool {
        return networkActionsArePossible && !submission.archived && AccountController.currentName == submission.author
    }

    var isReplyPossible: Bool {
        return networkActionsArePossible && !submission.archived
    }

    var isModPossible: Bool {
        return networkActionsArePossible && submission.canMod
    }

    init(submission: RSubmission) {
        self.submission = submission
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

@available(iOS 13.0, *)
extension LinkCellView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            if let vc = self.previewedVC {
                if self.previewedVideo && vc is AnyModalViewController {
                    //TODO check for memory leaks here
                    let postContentTransitioningDelegate = PostContentPresentationManager()
                    postContentTransitioningDelegate.sourceImageView = self.videoView
                    vc.transitioningDelegate = postContentTransitioningDelegate
                    vc.modalPresentationStyle = .custom
                    (vc as! AnyModalViewController).forceStartUnmuted = !self.videoView.player!.isMuted
                    
                    self.parentViewController?.present(vc, animated: true, completion: nil)
                } else {
                    if vc is WebsiteViewController || vc is SFHideSafariViewController {
                        self.previewedVC = nil
                        if let url = self.previewedURL {
                            self.parentViewController?.doShow(url: url, heroView: nil, finalSize: nil, heroVC: nil, link: self.link!)
                        }
                    } else {
                        if self.parentViewController != nil && (vc is AlbumViewController || vc is ModalMediaViewController) {
                            vc.modalPresentationStyle = .overFullScreen
                            self.parentViewController?.present(vc, animated: true)
                        } else {
                            VCPresenter.showVC(viewController: vc, popupIfPossible: true, parentNavigationController: nil, parentViewController: self.parentViewController)
                        }
                    }
                }
            } else if self.previewedImage {
                self.openLink()
            } else if self.previewedVideo {
                self.openLinkVideo()
            }
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        
        if full && self.textView != nil && !self.textView.isHidden && self.textView.frame.contains(interaction.location(in: self.contentView)) {
            let location = interaction.location(in: self.textView)
            
            if self.textView.firstTextView.frame.contains(location) {
                return UITargetedPreview(view: self.textView, parameters: self.getLocationForPreviewedText(self.textView.firstTextView, location, self.previewedURL?.absoluteString) ?? parameters)
            } else if self.textView.overflow.frame.contains(location) {
                let innerLocation = self.textView.convert(location, to: self.textView.overflow)
                for view in self.textView.overflow.subviews {
                    if view.frame.contains(innerLocation) && view is YYLabel {
                        return UITargetedPreview(view: self.textView, parameters: self.getLocationForPreviewedText(view as! YYLabel, innerLocation, self.previewedURL?.absoluteString, self.textView) ?? parameters)
                    }
                }
            }
            return UITargetedPreview(view: self.textView, parameters: parameters)
        } else if videoView != nil && !videoView.isHidden && videoView.frame.contains(interaction.location(in: self.contentView)) {
            return UITargetedPreview(view: self.videoView, parameters: parameters)
        } else if bannerImage != nil && !bannerImage.isHidden && bannerImage.frame.contains(interaction.location(in: self.contentView)) {
            return UITargetedPreview(view: self.bannerImage, parameters: parameters)
        } else if thumbImageContainer != nil && thumbImageContainer.frame.contains(interaction.location(in: self.contentView)) {
            return UITargetedPreview(view: self.thumbImageContainer, parameters: parameters)
        } else {
            return UITargetedPreview(view: self.save, parameters: parameters)
        }
    }
    
    func getLocationForPreviewedText(_ label: YYLabel, _ location: CGPoint, _ inputURL: String?, _ changeRectTo: UIView? = nil) -> UIPreviewParameters? {
        if inputURL == nil {
            return nil
        }
        let point = label.superview?.convert(location, to: label) ?? location
        var params: UIPreviewParameters?
        if let attributedText = label.attributedText, let layoutManager = YYTextLayout(containerSize: label.frame.size, text: attributedText) {
            let locationFinal = layoutManager.textPosition(for: point, lineIndex: layoutManager.lineIndex(for: point))
            if locationFinal < 1000000 {
                attributedText.enumerateAttribute(
                    .link,
                    in: NSRange(location: 0, length: attributedText.length)
                ) { (value, range, _) in
                    if let url = value as? NSURL {
                        if url.absoluteString == inputURL! {
                            let baseRects = layoutManager.selectionRects(for: YYTextRange(range: range))
                            var cgs = [NSValue]()
                            for rect in baseRects {
                                if changeRectTo != nil {
                                    cgs.append(NSValue(cgRect: changeRectTo!.convert(rect.rect, from: label)))
                                } else {
                                    cgs.append(NSValue(cgRect: rect.rect))
                                }
                            }
                            params = UIPreviewParameters(textLineRects: cgs)
                            params?.backgroundColor = .clear
                        }
                    }
                }
            }
        }
        return params
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let saveArea = self.contentView.convert(location, to: self.buttons)
        if full && self.textView != nil && !self.textView.isHidden && self.textView.frame.contains(location) {
            let innerPoint = self.contentView.convert(location, to: self.textView)
            if self.textView.firstTextView.frame.contains(innerPoint) {
                return getConfigurationForTextView(self.textView.firstTextView, innerPoint)
            } else if self.textView.overflow.frame.contains(innerPoint) {
                let innerLocation = self.contentView.convert(innerPoint, to: self.textView.overflow)
                print(innerLocation)
                for view in self.textView.overflow.subviews {
                    if view.frame.contains(innerLocation) && view is YYLabel {
                        return getConfigurationForTextView(view as! YYLabel, innerLocation)
                    }
                }
            }
        } else if let url = self.link?.url, videoView != nil && !videoView.isHidden && videoView.frame.contains(location) {
            self.previewedVideo = true
            return getConfigurationForVideo(url: url)
        } else if let url = self.link?.url, bannerImage != nil && bannerImage.isHidden == false && bannerImage.image != nil && (videoView == nil || videoView.isHidden) && bannerImage.frame.contains(location) {
            self.previewedImage = true
            return getConfigurationForImage(url: url)
        } else if let url = self.link?.url, thumbImageContainer != nil && thumbImageContainer.frame.contains(location) {
            return getConfigurationFor(url: url)
        } else if save.frame.contains(saveArea) {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in
                return self.makeContextMenu()
            })
        }
        return nil
    }
    
    func getConfigurationForTextView(_ label: YYLabel, _ location: CGPoint) -> UIContextMenuConfiguration? {
        let point = label.superview?.convert(location, to: label) ?? location
                if let attributedText = label.attributedText, let layoutManager = YYTextLayout(containerSize: label.frame.size, text: attributedText) {
            let locationFinal = layoutManager.textPosition(for: point, lineIndex: layoutManager.lineIndex(for: point))
            if locationFinal < 1000000 {
                let attributes = attributedText.attributes(at: Int(locationFinal), effectiveRange: nil)
                for attribute in attributes {
                    if attribute.value is NSURL {
                        if let url = (attribute.value as! NSURL).absoluteURL {
                            return getConfigurationFor(url: url)
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func contextMenuInteractionDidEnd(_ interaction: UIContextMenuInteraction) {
        self.previewedVC = nil
        self.previewedImage = false
        self.previewedVideo = false
    }
    
    func getConfigurationFor(url: URL) -> UIContextMenuConfiguration {
        self.previewedURL = url
        return UIContextMenuConfiguration(identifier: nil, previewProvider: { () -> UIViewController? in
            if let vc = self.parentViewController?.getControllerForUrl(baseUrl: url, link: self.link!) {
                self.previewedVC = vc
                if vc is SingleSubredditViewController || vc is CommentViewController || vc is WebsiteViewController || vc is SFHideSafariViewController || vc is SearchViewController {
                    return SwipeForwardNavigationController(rootViewController: vc)
                } else {
                    return vc
                }
            }
            return nil
        }, actionProvider: { (_) -> UIMenu? in
            var children = [UIMenuElement]()
            
            children.append(UIAction(title: "Share URL", image: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")!.menuIcon()) { _ in
                let shareItems: Array = [url]
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.contentView
                if let presenter = activityViewController.popoverPresentationController {
                    presenter.sourceView = self.contentView
                    presenter.sourceRect = self.contentView.bounds
                }
                self.parentViewController?.present(activityViewController, animated: true, completion: nil)
            })
            children.append(UIAction(title: "Copy URL", image: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()) { _ in
                UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self.parentViewController)
            })

            children.append(UIAction(title: "Open in default app", image: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) { _ in
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            })
            
            let open = OpenInChromeController.init()
            if open.isChromeInstalled() {
                children.append(UIAction(title: "Open in Chrome", image: UIImage(named: "world")!.menuIcon()) { _ in
                    _ = open.openInChrome(url, callbackURL: nil, createNewTab: true)
                })
            }

            return UIMenu(title: "Link Options", image: nil, identifier: nil, children: children)
        })
    }

    func getConfigurationForImage(url: URL) -> UIContextMenuConfiguration {
        self.previewedURL = url
        return UIContextMenuConfiguration(identifier: nil, previewProvider: { () -> UIViewController? in
            let vc = UIViewController()
            let image = UIImageView()
            vc.view.addSubview(image)
            image.image = self.bannerImage.image
            if image.image != nil {
                let ratio = image.image!.size.width / image.image!.size.height
                if vc.view.frame.width > vc.view.frame.height {
                    let newHeight = vc.view.frame.width / ratio
                    image.frame.size = CGSize(width: vc.view.frame.width, height: newHeight)
                } else {
                    let newWidth = vc.view.frame.height * ratio
                    image.frame.size = CGSize(width: newWidth, height: vc.view.frame.height)
                }
            }
            vc.preferredContentSize = image.frame.size
            image.edgeAnchors == vc.view.edgeAnchors
            return vc
        }, actionProvider: { (_) -> UIMenu? in
            var children = [UIMenuElement]()
            
            if ContentType.isImage(uri: url) && !self.bannerImage.isHidden && self.bannerImage.image != nil {
                let imageToShare = [self.bannerImage.image!]
                let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
                children.append(UIAction(title: "Save Image", image: UIImage(sfString: SFSymbol.squareAndArrowDown, overrideString: "save")!.menuIcon()) { _ in
                    CustomAlbum.shared.save(image: imageToShare[0], parent: self.parentViewController)
                })
                children.append(UIAction(title: "Share Image", image: UIImage(sfString: SFSymbol.cameraFill, overrideString: "share")!.menuIcon()) { _ in
                    if let presenter = activityViewController.popoverPresentationController {
                        presenter.sourceView = self.bannerImage
                        presenter.sourceRect = self.bannerImage.bounds
                    }
                    self.parentViewController?.present(activityViewController, animated: true, completion: nil)
                })
            }

            children.append(UIAction(title: "Share Image URL", image: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")!.menuIcon()) { _ in
                let shareItems: Array = [url]
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                if let presenter = activityViewController.popoverPresentationController {
                    presenter.sourceView = self.bannerImage
                    presenter.sourceRect = self.bannerImage.bounds
                }
                self.parentViewController?.present(activityViewController, animated: true, completion: nil)
            })
            children.append(UIAction(title: "Copy URL", image: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()) { _ in
                UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self.parentViewController)
            })

            children.append(UIAction(title: "Open in default app", image: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) { _ in
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            })
            
            return UIMenu(title: "Image Options", image: nil, identifier: nil, children: children)
        })
    }

    func getConfigurationForVideo(url: URL) -> UIContextMenuConfiguration {
        self.previewedURL = url
        return UIContextMenuConfiguration(identifier: nil, previewProvider: { () -> UIViewController? in
            let upvoted = ActionStates.getVoteDirection(s: self.link!) == VoteDirection.up
            let controller = AnyModalViewController(cellView: self, self.full ? nil : {[weak self] in
                if let strongSelf = self {
                    strongSelf.doOpenComment()
                }
            }, upvoteCallback: {[weak self] in
                if let strongSelf = self {
                    strongSelf.upvote()
                }
            }, isUpvoted: upvoted, failure: nil)
            self.previewedVC = controller

            return controller
        }, actionProvider: { (_) -> UIMenu? in
            var children = [UIMenuElement]()
            
            if let baseUrl = self.videoURL ?? self.link?.url, let parent = self.parentViewController { //todo enable this
                var finalUrl = baseUrl
                if VideoMediaViewController.VideoType.fromPath(baseUrl.absoluteString) == .REDDIT {
                    finalUrl = URL(string: self.link!.videoMP4) ?? baseUrl
                }
                children.append(UIAction(title: "Save Video", image: UIImage(sfString: SFSymbol.squareAndArrowDown, overrideString: "save")!.menuIcon()) { _ in
                    VideoMediaDownloader(urlToLoad: finalUrl).getVideoWithCompletion(completion: { (fileURL) in
                        if fileURL != nil {
                            CustomAlbum.shared.saveMovieToLibrary(movieURL: fileURL!, parent: parent)
                        } else {
                            BannerUtil.makeBanner(text: "Error downloading video", color: GMColor.red500Color(), seconds: 5, context: parent, top: false, callback: nil)
                        }
                    }, parent: parent)
                })
                children.append(UIAction(title: "Share Video", image: UIImage(sfString: SFSymbol.cameraFill, overrideString: "share")!.menuIcon()) { _ in
                    VideoMediaDownloader.init(urlToLoad: finalUrl).getVideoWithCompletion(completion: { (fileURL) in
                        DispatchQueue.main.async {
                            if fileURL != nil {
                                let shareItems: [Any] = [fileURL!]
                                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                                if let presenter = activityViewController.popoverPresentationController {
                                    presenter.sourceView = self.videoView!
                                    presenter.sourceRect = self.videoView!.bounds
                                }
                                self.parentViewController?.present(activityViewController, animated: true, completion: nil)
                            }
                        }
                    }, parent: parent)
                })
            }

            children.append(UIAction(title: "Share Video URL", image: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")!.menuIcon()) { _ in
                let shareItems: Array = [url]
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                if let presenter = activityViewController.popoverPresentationController {
                    presenter.sourceView = self.videoView!
                    presenter.sourceRect = self.videoView!.bounds
                }
                self.parentViewController?.present(activityViewController, animated: true, completion: nil)
            })
            children.append(UIAction(title: "Copy URL", image: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()) { _ in
                UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self.parentViewController)
            })

            children.append(UIAction(title: "Open in default app", image: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) { _ in
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            })
            
            return UIMenu(title: "Video Options", image: nil, identifier: nil, children: children)
        })
    }

    func makeContextMenu() -> UIMenu {

        // Create a UIAction for sharing
        var buttons = [UIAction]()
        let create = UIAction(title: "Create a collection", image: UIImage(sfString: SFSymbol.folderBadgePlusFill, overrideString: "add")) { _ in
            let bottom = DragDownAlertMenu(title: "Create a collection", subtitle: "", icon: nil)
            bottom.addTextInput(title: "Save", icon: nil, action: {
                if let title = bottom.getText() {
                    Collections.addToCollectionCreate(id: self.link!.getId(), title: title)
                    BannerUtil.makeBanner(text: "Saved to \(title)", seconds: 3, context: self.parentViewController)
                }
            }, inputPlaceholder: "", inputIcon: UIImage(sfString: SFSymbol.textbox, overrideString: "size")!, textRequired: true, exitOnAction: true)
            bottom.show(self.parentViewController)
        }
        buttons.append(create)
        for item in Collections.getAllCollections() {
            buttons.append(UIAction(title: item, image: nil, handler: { (_) in
                Collections.addToCollection(link: self.link!, title: item)
                BannerUtil.makeBanner(text: "Saved to \(item)", seconds: 3, context: self.parentViewController)
            }))
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Save into a Collection", children: buttons)
    }
}

