//
//  ShadowboxLinkViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/4/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import AVFoundation
import AVKit
import CoreData
import MaterialComponents.MaterialProgressView
import SDWebImage
import YYText

class ShadowboxLinkViewController: MediaViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, TextDisplayStackViewDelegate {
    func linkTapped(url: URL, text: String) {
        if !text.isEmpty {
            self.showSpoiler(text)
        } else {
            self.doShow(url: url, heroView: nil, finalSize: nil, heroVC: nil, link: submission)
        }
    }

    func linkLongTapped(url: URL) {
        
    }
    
    var type: ContentType.CType = ContentType.CType.UNKNOWN
    
    var textView: TextDisplayStackView!
    var bodyScrollView = UIScrollView()
    var embeddedVC: EmbeddableMediaViewController!
    
    var content: NSManagedObject?
    var baseURL: URL?
    
    var submission: Submission! {
        return content as? Submission
    }

    var titleLabel: YYLabel!
    var gradientView = GradientView(gradientStartColor: UIColor.black, gradientEndColor: UIColor.clear)

    var comment = UIImageView()
    var upvote = UIImageView()
    var downvote = UIImageView()
    var more = UIImageView()
    var baseBody = UIView()
    var thumbImageContainer = UIView()
    var thumbImage = UIImageView()
    var commenticon = UIImageView()
    var submissionicon = UIImageView()
    var score = UILabel()
    var box = UIStackView()
    var buttons = UIStackView()
    var comments = UILabel()
    var infoContainer = UIView()
    var info = UILabel()
    var topBody = UIView()
    var closeButton = UIButton().then {
        $0.accessibilityIdentifier = "Close Button"
        $0.accessibilityTraits = UIAccessibilityTraits.button
        $0.accessibilityLabel = "Close button"
        $0.accessibilityHint = "Closes the media view"
    }

    weak var parentVC: ShadowboxViewController?
    
    var backgroundColor: UIColor {
        didSet {
            if parent is SwipeDownModalVC && parentVC?.currentVc == self {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.25) {
                        (self.parent as! SwipeDownModalVC).background!.backgroundColor = self.backgroundColor
                    }
                }
            }
        }
    }
    
    init(url: URL?, content: NSManagedObject?, parent: ShadowboxViewController) {
        self.parentVC = parent
        self.baseURL = url
        self.content = content
        self.backgroundColor = .black
        super.init(nibName: nil, bundle: nil)
        if content is Submission {
            type = ContentType.getContentType(submission: content as? Submission)
        } else {
            type = ContentType.getContentType(baseUrl: baseURL)
        }
        
        if titleLabel == nil {
            configureView()
            configureLayout()
            
            populateData()
            doBackground()
            titleLabel.preferredMaxLayoutWidth = self.view.frame.size.width - 48
        }
        doBackground()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureView() {
        self.titleLabel = YYLabel(frame: CGRect(x: 75, y: 8, width: 0, height: 0)).then {
            $0.accessibilityIdentifier = "Title"
            $0.font = FontGenerator.fontOfSize(size: 18, submission: true)
            $0.isOpaque = false
            $0.numberOfLines = 0
        }
        
        self.upvote = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24)).then {
            $0.accessibilityIdentifier = "Upvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
        }
        
        self.bodyScrollView = UIScrollView().then {
            $0.accessibilityIdentifier = "Body scroll view"
        }
        
        self.downvote = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 20)).then {
            $0.accessibilityIdentifier = "Downvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
        }

        self.commenticon = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10)).then {
            $0.accessibilityIdentifier = "Comment Count Icon"
            $0.image = LinkCellImageCache.commentsIcon.getCopy(withColor: .white)
            $0.contentMode = .scaleAspectFit
            $0.isOpaque = false
        }
        
        self.submissionicon = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10)).then {
            $0.accessibilityIdentifier = "Score Icon"
            $0.image = LinkCellImageCache.votesIcon.getCopy(withColor: .white)
            $0.contentMode = .scaleAspectFit
            $0.isOpaque = false
        }
        self.score = UILabel().then {
            $0.accessibilityIdentifier = "Score Label"
            $0.numberOfLines = 1
            $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
            $0.textColor = .white
            $0.isOpaque = false
        }

        self.comments = UILabel().then {
            $0.accessibilityIdentifier = "Comment Count Label"
            $0.numberOfLines = 1
            $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
            $0.textColor = .white
            $0.isOpaque = false
        }

        self.thumbImageContainer = UIView().then {
            $0.accessibilityIdentifier = "Thumbnail Image Container"
            $0.frame = CGRect(x: 0, y: 0, width: 85, height: 85)
            $0.elevate(elevation: 2.0)
        }
        
        self.textView = TextDisplayStackView.init(fontSize: 16, submission: true, color: ColorUtil.baseAccent, width: 100, delegate: self).then {
            $0.accessibilityIdentifier = "Self Text View"
        }
        
        self.textView.baseFontColor = .white

        self.thumbImage = UIImageView().then {
            $0.accessibilityIdentifier = "Thumbnail Image"
            $0.backgroundColor = UIColor.white
            $0.layer.cornerRadius = 10
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
        }
        
        self.info = UILabel().then {
            $0.accessibilityIdentifier = "Banner Info"
            $0.numberOfLines = 2
            $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
            $0.textColor = .white
        }

        self.infoContainer = info.withPadding(padding: UIEdgeInsets.init(top: 4, left: 10, bottom: 4, right: 10)).then {
            $0.accessibilityIdentifier = "Banner Info Container"
            $0.clipsToBounds = true
        }

        self.box = UIStackView().then {
            $0.accessibilityIdentifier = "Count Info Stack Horizontal"
            $0.axis = .horizontal
            $0.alignment = .center
        }
        self.thumbImageContainer.addSubview(self.thumbImage)
        self.thumbImage.edgeAnchors /==/ self.thumbImageContainer.edgeAnchors
        closeButton.setImage(UIImage(sfString: SFSymbol.xmark, overrideString: "close")?.navIcon(true), for: .normal)
        closeButton.addTarget(self, action: #selector(self.exit), for: UIControl.Event.touchUpInside)

        self.view.addSubview(gradientView)
        gradientView.addSubview(closeButton)
        gradientView.addSubview(titleLabel)

        box.addArrangedSubviews(submissionicon, horizontalSpace(2), score, horizontalSpace(8), commenticon, horizontalSpace(2), comments)
        self.baseBody.addSubview(box)
        
        self.buttons = UIStackView().then {
            $0.accessibilityIdentifier = "Button Stack Horizontal"
            $0.axis = .horizontal
            $0.alignment = .center
            $0.distribution = .fill
            $0.spacing = 16
        }
        buttons.addArrangedSubviews( upvote, downvote)
        self.baseBody.addSubview(buttons)
        baseBody.topAnchor /==/ buttons.topAnchor
       // TODO: - add gestures here
        self.view.addSubview(baseBody)
        self.view.addSubview(topBody)
        baseBody.horizontalAnchors /==/ self.view.horizontalAnchors + 12
        baseBody.bottomAnchor /==/ self.view.bottomAnchor - 12
        topBody.horizontalAnchors /==/ self.view.horizontalAnchors
        topBody.bottomAnchor /==/ baseBody.topAnchor
        topBody.topAnchor /==/ self.view.topAnchor
        
        self.view.bringSubviewToFront(gradientView)
    }
    
    @objc func exit() {
        parentVC?.dismiss(animated: true, completion: nil)
    }
    
    func configureLayout() {
        baseBody.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
        box.leftAnchor /==/ baseBody.leftAnchor + 12
        box.bottomAnchor /==/ baseBody.bottomAnchor - 8
        box.centerYAnchor /==/ buttons.centerYAnchor // Align vertically with buttons
        box.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        box.heightAnchor /==/ CGFloat(24)
        buttons.heightAnchor /==/ CGFloat(24)
        buttons.rightAnchor /==/ baseBody.rightAnchor - 12
        buttons.bottomAnchor /==/ baseBody.bottomAnchor - 8
        buttons.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        
        gradientView.horizontalAnchors /==/ self.view.horizontalAnchors
        gradientView.topAnchor /==/ self.view.topAnchor

        closeButton.sizeAnchors /==/ .square(size: 38)
        closeButton.topAnchor /==/ gradientView.safeTopAnchor + 8
        closeButton.leftAnchor /==/ gradientView.safeLeftAnchor + 12
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.masksToBounds = true
        closeButton.layer.cornerRadius = 18
        
        titleLabel.leftAnchor /==/ closeButton.rightAnchor + 8
        titleLabel.topAnchor /==/ gradientView.safeTopAnchor + 8
        titleLabel.rightAnchor /==/ gradientView.safeRightAnchor - 8
        titleLabel.bottomAnchor /==/ gradientView.bottomAnchor - 8
            
        gradientView.layoutIfNeeded()
        titleLabel.preferredMaxLayoutWidth = self.titleLabel.frame.size.width
        titleLabel.sizeToFit()

    }

    func populateData() {
        var archived = false
        if let link = content as! Submission? {
            archived = link.isArchived
            upvote.image = LinkCellImageCache.upvote.getCopy(withColor: .white)
            downvote.image = LinkCellImageCache.downvote.getCopy(withColor: .white)
            var attrs: [String: Any] = [:]
            switch  ActionStates.getVoteDirection(s: link) {
            case .down:
                downvote.image = LinkCellImageCache.downvoteTinted
                attrs = ([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.downvoteColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true)])
            case .up:
                upvote.image = LinkCellImageCache.upvoteTinted
                attrs = ([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.upvoteColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true)])
            default:
                attrs = ([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: true)])
            }
            
            score.attributedText = NSAttributedString(string: (link.score >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(link.score) / Double(1000))) : " \(link.score)", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs))
            
            comments.text = "\(link.commentCount)"
            
            let title = CachedTitle.getTitleForMedia(submission: link)
            let finalTitle = NSMutableAttributedString(attributedString: title.infoLine!)
            finalTitle.append(NSAttributedString(string: "\n"))
            finalTitle.append(title.mainTitle!)
            
            titleLabel.attributedText = finalTitle

            let size = CGSize(width: self.view.frame.size.width - 48, height: CGFloat.greatestFiniteMagnitude)
            let layout = YYTextLayout(containerSize: size, text: titleLabel.attributedText!)!
            titleLabel.textLayout = layout
            titleLabel.heightAnchor /==/ layout.textBoundingSize.height
        } else if let link = content as! CommentModel? {
            archived = link.isArchived
            upvote.image = LinkCellImageCache.upvote
            downvote.image = LinkCellImageCache.downvote
            var attrs: [String: Any] = [:]
            switch ActionStates.getVoteDirection(s: link) {
            case .down:
                downvote.image = LinkCellImageCache.downvoteTinted
                attrs = ([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.downvoteColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true)])
            case .up:
                upvote.image = LinkCellImageCache.upvoteTinted
                attrs = ([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.upvoteColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: true)])
            default:
                attrs = ([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: true)])
            }
            
            score.attributedText = NSAttributedString.init(string: (link.score >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(link.score) / Double(1000))) : " \(link.score)", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs))
            
           // TODO: - what to do here titleLabel.setText(CachedTitle.getTitle(submission: link, full: false, false, true))
        }
        
        if archived || !AccountController.isLoggedIn {
            upvote.isHidden = true
            downvote.isHidden = true
        }
    }
    
    func doBackground() {
        if SettingValues.blackShadowbox || true { //Disable this setting completely
            self.backgroundColor = .black
        } else {
            if content is Submission {
                let thumbnail = (content as! Submission).thumbnailUrl ?? ""
                if let url = URL(string: thumbnail) {
                    SDWebImageDownloader.shared.downloadImage(with: url, options: [.allowInvalidSSLCertificates, .scaleDownLargeImages], progress: { (_, _, _) in
                    }, completed: { (image, _, _, _) in
                        if image != nil {
                            DispatchQueue.global(qos: .background).async {
                                let average = image!.areaAverage()
                                DispatchQueue.main.async {
                                    self.backgroundColor = average
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    func populateContent() {
        self.baseBody.addTapGestureRecognizer { (_) in
            self.comments(self.view)
        }
        self.topBody.addTapGestureRecognizer { (_) in
            self.content(self.view)
        }
        self.upvote.addTapGestureRecognizer { (_) in
            self.upvote(self.upvote)
        }
        self.downvote.addTapGestureRecognizer { (_) in
            self.downvote(self.downvote)
        }
        if type == .SELF {
            topBody.addSubview(bodyScrollView)
            bodyScrollView.horizontalAnchors /==/ topBody.horizontalAnchors + 12
            bodyScrollView.verticalAnchors /==/ topBody.verticalAnchors + 12
            textView.estimatedWidth = UIScreen.main.bounds.width - 24
            textView.setTextWithTitleHTML(NSMutableAttributedString(), htmlString: (content as! Submission).htmlBody ?? "")
            bodyScrollView.addSubview(textView)
            textView.leftAnchor /==/ bodyScrollView.leftAnchor
            textView.widthAnchor /==/ textView.estimatedWidth
            textView.topAnchor /==/ bodyScrollView.topAnchor + 58
            textView.heightAnchor /==/ textView.estimatedHeight + 50
            bodyScrollView.contentSize = CGSize(width: bodyScrollView.bounds.width, height: textView.estimatedHeight + 108)
            parentVC?.panGestureRecognizer?.require(toFail: bodyScrollView.panGestureRecognizer)
            parentVC?.panGestureRecognizer2?.require(toFail: bodyScrollView.panGestureRecognizer)
            self.populated = true
        } else if type != .ALBUM && type != .REDDIT_GALLERY && (ContentType.displayImage(t: type) || ContentType.displayVideo(t: type)) && ((content is Submission && !(content as! Submission).isNSFW) || SettingValues.nsfwPreviews) {
            if !ContentType.displayVideo(t: type) || !populated {
                self.populated = true
                let embed = ModalMediaViewController.getVCForContent(ofType: type, withModel: EmbeddableMediaDataModel(baseURL: baseURL, lqURL: nil, text: nil, inAlbum: false, buttons: false))
                if embed != nil {
                    self.embeddedVC = embed
                    self.addChild(embed!)
                    embed!.didMove(toParent: self)
                    self.topBody.addSubview(embed!.view)
                    embed!.view.horizontalAnchors /==/ topBody.horizontalAnchors
                    embed!.view.topAnchor /==/ topBody.safeTopAnchor
                    embed!.view.bottomAnchor /==/ topBody.bottomAnchor
                } else {
                    //Shouldn't be here
                }
            } else {
                populated = false
            }
        } else if type == .LINK || type == .NONE || type == .ALBUM || type == .REDDIT_GALLERY || ((content is Submission && (content as! Submission).isNSFW) && !SettingValues.nsfwPreviews) {
            self.populated = true
            topBody.addSubviews(thumbImageContainer, infoContainer)
            thumbImageContainer.centerAnchors /==/ topBody.centerAnchors
            infoContainer.horizontalAnchors /==/ topBody.horizontalAnchors
            infoContainer.topAnchor /==/ thumbImageContainer.bottomAnchor + 8
            let thumbSize: CGFloat = 85
            thumbImageContainer.widthAnchor /==/ thumbSize
            thumbImageContainer.heightAnchor /==/ thumbSize

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
                    text = ("GIF")
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
            let finalText = NSMutableAttributedString.init(string: text, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 16, submission: true)]))
            finalText.append(NSAttributedString.init(string: "\n\(baseURL?.host ?? baseURL?.absoluteString ?? "")"))
            info.textAlignment = .center
            info.attributedText = finalText
            if content is Submission {
                let submission = content as! Submission
                if submission.isNSFW {
                    thumbImage.image = LinkCellImageCache.nsfw
                } else if submission.thumbnailUrl == "web" || (submission.thumbnailUrl ?? "").isEmpty {
                    if type == .REDDIT {
                        thumbImage.image = LinkCellImageCache.reddit
                    } else {
                        thumbImage.image = LinkCellImageCache.web
                    }
                } else {
                    let thumbURL = submission.thumbnailUrl ?? ""
                    if let url = URL(string: thumbURL) {
                        DispatchQueue.global(qos: .userInteractive).async {
                            self.thumbImage.sd_setImage(with: url, placeholderImage: LinkCellImageCache.web)
                        }
                    } else {
                        thumbImage.image = LinkCellImageCache.web
                    }
                }
            } else {
                if type == .REDDIT {
                    thumbImage.image = LinkCellImageCache.reddit
                } else {
                    thumbImage.image = LinkCellImageCache.web
                }
            }
        } else if type == .ALBUM {
            //We captured it above. Possible implementation in the future?
        } else {
            //Nothing
        }
    }
    
      @objc func upvote(_ sender: AnyObject) {
        if content is Submission {
            let submission = content as! Submission
            do {
                try (UIApplication.shared.delegate as! AppDelegate).session?.setVote(ActionStates.getVoteDirection(s: submission) == .up ? .none : .up, name: submission.id, completion: { (_) in
                })
                ActionStates.setVoteDirection(s: submission, direction: ActionStates.getVoteDirection(s: submission) == .up ? .none : .up)
                History.addSeen(s: submission)
                populateData()
            } catch {
                
            }
        }
    }

    @objc func downvote(_ sender: AnyObject) {
        if content is Submission {
            let submission = content as! Submission
            do {
                try (UIApplication.shared.delegate as! AppDelegate).session?.setVote(ActionStates.getVoteDirection(s: submission) == .down ? .none : .down, name: submission.id, completion: { (_) in
                })
                ActionStates.setVoteDirection(s: submission, direction: ActionStates.getVoteDirection(s: submission) == .down ? .none : .down)
                History.addSeen(s: submission)
                populateData()
            } catch {
                
            }
        }
    }

    @objc func comments(_ sender: AnyObject) {
        if content is Submission {
            VCPresenter.openRedditLink((content as! Submission).permalink, nil, self)
        } else if content is CommentModel {
            VCPresenter.openRedditLink((content as! CommentModel).permalink, nil, self)
        }
    }

    @objc func content(_ sender: AnyObject) {
        doShow(url: baseURL!, heroView: thumbImageContainer.isHidden ? embeddedVC.view : thumbImage, finalSize: nil, heroVC: parentVC, link: submission)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if populated && embeddedVC is VideoMediaViewController {
            let video = embeddedVC as! VideoMediaViewController
            video.videoView.player?.play()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !populated {
            populateContent()
            populated = true
        }
    }

    var first = true
    var populated = false

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if embeddedVC is VideoMediaViewController {
            let video = embeddedVC as! VideoMediaViewController
            video.videoView.player?.pause()
        }
    }
    func horizontalSpace(_ space: CGFloat) -> UIView {
        return UIView().then {
            $0.widthAnchor /==/ space
        }
    }

}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
