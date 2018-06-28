//
//  LinkCellViewTableViewCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/26/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

//
//  LinkCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/24/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import UZTextView
import TTTAttributedLabel
import MaterialComponents
import AudioToolbox
import XLActionController
import reddift
import SafariServices
import RLBAlertsPickers
import Then
import Anchorage

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
}

enum CurrentType {
    case thumb, banner, text, none;
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


    var bannerImage = UIImageView()
    var thumbImageContainer = UIView()
    var thumbImage = UIImageView()
    var title = TTTAttributedLabel(frame: CGRect.zero)
    var score = UILabel()
    var box = UIStackView()
    var buttons = UIStackView()
    var comments = UILabel()
    var info = UILabel()
    var textView = TTTAttributedLabel(frame: CGRect.zero)
    var save = UIImageView()
    var upvote = UIImageView()
    var hide = UIImageView()
    var edit = UIImageView()
    var reply = UIImageView()
    var downvote = UIImageView()
    var mod = UIImageView()
    var commenticon = UIImageView()
    var submissionicon = UIImageView()
    var del: LinkCellViewDelegate? = nil
    var taglabel = UILabel()
    var tagbody = UIView()
    var crosspost = UITableViewCell()

    var loadedImage: URL?
    var lq = false

    var content: CellContent?
    var hasText = false

    var full = false
    var infoContainer = UIView()
    var estimatedHeight = CGFloat(0)

    var big = false
    var dtap : UIShortTapGestureRecognizer?

    var thumb = true
    var submissionHeight: Int = 0
    var addTouch = false

    var link: RSubmission?
    var aspectWidth = CGFloat(0.1)

    var tempConstraints: [NSLayoutConstraint] = []
    var constraintsForType: [NSLayoutConstraint] = []
    var constraintsForContent: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureView()
        configureLayout()
    }

    func attributedLabel(_ label: TTTAttributedLabel!, didLongPressLinkWith url: URL!, at point: CGPoint) {
        if (url) != nil {
            if parentViewController != nil {

                let alertController = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)

                let open = OpenInChromeController.init()
                if (open.isChromeInstalled()) {
                    alertController.addAction(image: UIImage.init(named: "web"), title: "Open in Chrome", color: ColorUtil.fontColor, style: .default, isEnabled: true) { (action) in
                        open.openInChrome(url, callbackURL: nil, createNewTab: true)
                    }
                }
                alertController.addAction(image: UIImage.init(named: "Open in Safari"), title: "nav", color: ColorUtil.fontColor, style: .default, isEnabled: true) { (action) in
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }

                VCPresenter.presentAlert(alertController, parentVC: parentViewController!)
            }
        }
    }

    func configureView() {

        self.accessibilityIdentifier = "Link Cell View"
        self.contentView.accessibilityIdentifier = "Link Cell Content View"
        
        self.thumbImageContainer = UIView().then {
            $0.accessibilityIdentifier = "Thumbnail Image Container"
            $0.frame = CGRect(x: 0, y: 8, width: (SettingValues.largerThumbnail ? 75 : 50) - (SettingValues.postViewMode == .COMPACT ? 15 : 0), height: (SettingValues.largerThumbnail ? 75 : 50) - (SettingValues.postViewMode == .COMPACT ? 15 : 0))
            $0.elevate(elevation: 2.0)
        }

        self.thumbImage = UIImageView().then {
            $0.accessibilityIdentifier = "Thumbnail Image"
            $0.backgroundColor = UIColor.white
            $0.layer.cornerRadius = 10
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
        }
        self.thumbImageContainer.addSubview(self.thumbImage)
        self.thumbImage.edgeAnchors == self.thumbImageContainer.edgeAnchors

        self.bannerImage = UIImageView().then {
            $0.accessibilityIdentifier = "Banner Image"
            $0.contentMode = .scaleAspectFill
            $0.layer.cornerRadius = 15
            $0.clipsToBounds = true
            $0.backgroundColor = UIColor.white
        }

        self.title = TTTAttributedLabel(frame: CGRect(x: 75, y: 8, width: 0, height: 0)).then {
            $0.accessibilityIdentifier = "Title"
            $0.numberOfLines = 0
            $0.lineBreakMode = .byWordWrapping
            $0.font = FontGenerator.fontOfSize(size: 18, submission: true)
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }

        self.hide = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24)).then {
            $0.accessibilityIdentifier = "Hide Button"
            $0.image = LinkCellImageCache.hide
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }

        self.reply = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24)).then {
            $0.accessibilityIdentifier = "Reply Button"
            $0.image = LinkCellImageCache.reply
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }

        self.edit = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24)).then {
            $0.accessibilityIdentifier = "Edit Button"
            $0.image = LinkCellImageCache.edit
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }

        self.save = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24)).then {
            $0.accessibilityIdentifier = "Save Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }

        self.upvote = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24)).then {
            $0.accessibilityIdentifier = "Upvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }

        self.downvote = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 20)).then {
            $0.accessibilityIdentifier = "Downvote Button"
            $0.contentMode = .center
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }

        self.mod = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24)).then {
            $0.accessibilityIdentifier = "Mod Button"
            $0.image = LinkCellImageCache.mod
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

        self.textView = TTTAttributedLabel(frame: CGRect(x: 75, y: 8, width: 0, height: 0)).then {
            $0.accessibilityIdentifier = "Self Text View"
            $0.numberOfLines = 0
            $0.isUserInteractionEnabled = true
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
        }
        self.textView.delegate = self

        self.score = UILabel().then {
            $0.accessibilityIdentifier = "Score Label"
            $0.numberOfLines = 1
            $0.font = FontGenerator.fontOfSize(size: 12, submission: true)
            $0.textColor = ColorUtil.fontColor
            $0.isOpaque = false
            $0.backgroundColor = ColorUtil.foregroundColor
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
            $0.layer.cornerRadius = 4
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
            $0.layer.cornerRadius = 15
        }

        if (!addTouch) {
            addTouch(view: save, action: #selector(LinkCellView.save(sender:)))
            addTouch(view: upvote, action: #selector(LinkCellView.upvote(sender:)))
            addTouch(view: reply, action: #selector(LinkCellView.reply(sender:)))
            addTouch(view: downvote, action: #selector(LinkCellView.downvote(sender:)))
            addTouch(view: mod, action: #selector(LinkCellView.mod(sender:)))
            addTouch(view: edit, action: #selector(LinkCellView.edit(sender:)))
            addTouch(view: hide, action: #selector(LinkCellView.hide(sender:)))
            addTouch = true
        }

        contentView.addSubviews(bannerImage, thumbImageContainer, title, textView, infoContainer, tagbody)
        contentView.layer.masksToBounds = true

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
        buttons.addArrangedSubviews(edit, reply, save, hide, upvote, downvote, mod)
        self.contentView.addSubview(buttons)

        buttons.isHidden = SettingValues.hideButtonActionbar
        buttons.isUserInteractionEnabled = !SettingValues.hideButtonActionbar
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
        // Remove all constraints previously applied by this method
        for constraint in tempConstraints {
            constraint.isActive = false
        }
        tempConstraints = []

        tempConstraints = batch {
            var topmargin = 0
            var bottommargin = 2
            var leftmargin = 0
            var rightmargin = 0
            var innerpadding = 0
            var radius = 0

            if (SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full {
                topmargin = 5
                bottommargin = 5
                leftmargin = 5
                rightmargin = 5
                innerpadding = 5
                radius = 15
            }

            self.contentView.layoutMargins = UIEdgeInsets.init(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin))

            self.contentView.layer.cornerRadius = CGFloat(radius)

            box.leftAnchor == contentView.leftAnchor + ctwelve
            box.bottomAnchor == contentView.bottomAnchor - ceight
            box.centerYAnchor == buttons.centerYAnchor // Align vertically with buttons
            box.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

            buttons.rightAnchor == contentView.rightAnchor - ctwelve
            buttons.bottomAnchor == contentView.bottomAnchor - ceight

            title.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        }

        layoutForType()
        layoutForContent()

    }

    internal func layoutForType() {

        thumbImageContainer.isHidden = true
        bannerImage.isHidden = true

        // Remove all constraints previously applied by this method
        for constraint in constraintsForType {
            constraint.isActive = false
        }
        constraintsForType = []

        // Deriving classes will populate constraintsForType in the override for this method.

    }

    internal func layoutForContent() {

        // Remove all constraints previously applied by this method
        for constraint in constraintsForContent {
            constraint.isActive = false
        }
        constraintsForContent = []

        // Deriving classes will populate constraintsForContent in the override for this method.
    }

    func configure(submission: RSubmission, parent: MediaViewController, nav: UIViewController?, baseSub: String, test : Bool = false) {
        self.link = submission
        self.setLink(submission: submission, parent: parent, nav: nav, baseSub: baseSub, test: test)
        layoutForContent()
    }

    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        print("Clicked \(url.absoluteString)")
        if ((parentViewController) != nil) {
            parentViewController?.doShow(url: url)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

       let pointForTargetViewmod: CGPoint = mod.convert(point, from: self)
        if mod.bounds.contains(pointForTargetViewmod) {
            return mod
        }
        let pointForTargetViewdownvote: CGPoint = downvote.convert(point, from: self)
        if downvote.bounds.contains(pointForTargetViewdownvote) {
            return downvote
        }

        let pointForTargetViewupvote: CGPoint = upvote.convert(point, from: self)
        if upvote.bounds.contains(pointForTargetViewupvote) {
            return upvote
        }
        let pointForTargetViewsave: CGPoint = save.convert(point, from: self)
        if save.bounds.contains(pointForTargetViewsave) {
            return save
        }
        let pointForTargetViewh: CGPoint = hide.convert(point, from: self)
        if hide.bounds.contains(pointForTargetViewh) {
            return hide
        }

        let pointForTargetViewreply: CGPoint = reply.convert(point, from: self)
        if reply.bounds.contains(pointForTargetViewreply) {
            return reply
        }
        let pointForTargetViewedit: CGPoint = edit.convert(point, from: self)
        if edit.bounds.contains(pointForTargetViewedit) {
            return edit
        }


        return super.hitTest(point, with: event)
    }

    func showBody(width: CGFloat) {
        full = true
        let link = self.link!
        let color = ColorUtil.accentColorForSub(sub: ((link).subreddit))
        if (!link.htmlBody.isEmpty) {
            var html = link.htmlBody.trimmed()

            html = WrapSpoilers.addSpoilers(html)
            html = WrapSpoilers.addTables(html)
            let attr = html.toAttributedString()!
            let font = FontGenerator.fontOfSize(size: 16, submission: false)
            let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: color)
            content = CellContent.init(string: LinkParser.parse(attr2, color), width: (width - 24 - (thumb ? 75 : 0)))
            let activeLinkAttributes = NSMutableDictionary(dictionary: title.activeLinkAttributes)
            activeLinkAttributes[NSForegroundColorAttributeName] = ColorUtil.accentColorForSub(sub: link.subreddit)
            textView.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            textView.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]

            textView.delegate = self
            textView.setText(content?.attributedString)
            hasText = true

            parentViewController?.registerForPreviewing(with: self, sourceView: textView)
        }
    }

//    func estimateHeight(_ full: Bool, _ reset: Bool = false) -> CGFloat {
//        estimatedHeight = frame.size.height
//        return estimatedHeight
//    }

    
    func addTouch(view: UIView, action: Selector) {
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: action)
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    func getHeightFromAspectRatio(imageHeight: Int, imageWidth: Int) -> Int {
        let ratio = Double(imageHeight) / Double(imageWidth)
        let width = Double(contentView.frame.size.width == 0 ? aspectWidth : contentView.frame.size.width)
        return Int(width * ratio)
    }

    func refreshLink(_ submission: RSubmission) {
        self.link = submission

        title.setText(CachedTitle.getTitle(submission: submission, full: full, true, false))

        if(dtap == nil && SettingValues.submissionActionDoubleTap != .NONE) {
            dtap = UIShortTapGestureRecognizer.init(target: self, action: #selector(self.doDTap(_:)))
            dtap!.numberOfTapsRequired = 2
            self.addGestureRecognizer(dtap!)
        }
        
        if (!full) {
            let comment = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openComment(sender:)))
            comment.delegate = self
            if(dtap != nil){
                comment.require(toFail: dtap!)
            }
            self.addGestureRecognizer(comment)
        }

        refresh()
        let more = History.commentsSince(s: submission)
        comments.text = " \(submission.commentCount)" + (more > 0 ? " (+\(more))" : "")
    }
    
    func doDTap(_ sender: AnyObject){
        switch(SettingValues.submissionActionDoubleTap){
        case .UPVOTE:
            self.upvote()
        case .DOWNVOTE:
            self.downvote()
        case .SAVE:
            self.save()
        case .MENU:
            self.more()
        default:
            break
        }
    }
    
    var aspect = CGFloat(1)

    private func setLink(submission: RSubmission, parent: MediaViewController, nav: UIViewController?, baseSub: String, test : Bool = false) {
        loadedImage = nil
        full = parent is CommentViewController
        lq = false
        if (true || full) { //todo logic for this
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
        if (navViewController == nil && nav != nil) {
            navViewController = nav
        }

        title.setText(CachedTitle.getTitle(submission: submission, full: full, false, false))

        let activeLinkAttributes = NSMutableDictionary(dictionary: title.activeLinkAttributes)
        activeLinkAttributes[NSForegroundColorAttributeName] = ColorUtil.accentColorForSub(sub: submission.subreddit)
        title.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
        title.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]

        reply.isHidden = true

        if (!SettingValues.hideButton) {
            hide.isHidden = true
        } else {
            if (!addTouch) {
                addTouch(view: hide, action: #selector(LinkCellView.hide(sender:)))
            }
            hide.isHidden = false
        }
        mod.isHidden = true
        if (!SettingValues.saveButton) {
            save.isHidden = true
        } else {
            if (!addTouch) {
                addTouch(view: save, action: #selector(LinkCellView.save(sender:)))
            }
            save.isHidden = false
        }
        if (submission.archived || !AccountController.isLoggedIn || !LinkCellView.checkInternet()) {
            upvote.isHidden = true
            downvote.isHidden = true
            save.isHidden = true
            reply.isHidden = true
            edit.isHidden = true
        } else {
            upvote.isHidden = false
            downvote.isHidden = false
            if (!addTouch) {
                addTouch(view: upvote, action: #selector(LinkCellView.upvote(sender:)))
                addTouch(view: downvote, action: #selector(LinkCellView.downvote(sender:)))
            }

            if(submission.canMod){
                mod.isHidden = false
                addTouch(view: mod, action: #selector(LinkCellView.mod(sender:)))
                if(!submission.reports.isEmpty){
                    mod.image = LinkCellImageCache.modTinted
                } else {
                    mod.image = LinkCellImageCache.mod
                }
            }

            if (full) {
                if (!addTouch) {
                    addTouch(view: reply, action: #selector(LinkCellView.reply(sender:)))
                }
                reply.isHidden = false
                hide.isHidden = true
            }
            if (link!.author == AccountController.currentName) {
                addTouch(view: edit, action: #selector(LinkCellView.edit(sender:)))
            }
            edit.isHidden = true
        }

        full = parent is CommentViewController

        if (!submission.archived && AccountController.isLoggedIn && AccountController.currentName == submission.author && full) {
            edit.isHidden = false
        }

        thumb = submission.thumbnail
        big = submission.banner

        submissionHeight = submission.height

        var type = test ? ContentType.CType.LINK : ContentType.getContentType(baseUrl: submission.url)
        if (submission.isSelf) {
            type = .SELF
        }

        if (SettingValues.postImageMode == .THUMBNAIL && !full) {
            big = false
            thumb = true
        }

        let fullImage = ContentType.fullImage(t: type)

        if (!fullImage && submissionHeight < 50) {
            big = false
            thumb = true
        } else if (big && ((!full && SettingValues.postImageMode == .CROPPED_IMAGE) || (full && !SettingValues.commentFullScreen))) {
            submissionHeight = test ? 150 : 200
        } else if (big) {
            let h = getHeightFromAspectRatio(imageHeight: submissionHeight, imageWidth: submission.width)
            if (h == 0) {
                submissionHeight = test ? 150 : 200
            } else {
                submissionHeight = h
            }
        }

        if (SettingValues.hideButtonActionbar && !full) {
            buttons.isHidden = true
            box.isHidden = true
        }

        if (type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big || type == .SELF && full) {
            big = false
            thumb = false
        }

        if (submissionHeight < 50) {
            thumb = true
            big = false
        }

        let shouldShowLq = SettingValues.dataSavingEnabled && submission.lQ && !(SettingValues.dataSavingDisableWiFi && LinkCellView.checkWiFi())
        if (type == ContentType.CType.SELF && SettingValues.hideImageSelftext
                || SettingValues.noImages && submission.isSelf) {
            big = false
            thumb = false
        }

        if (big || !submission.thumbnail) {
            thumb = false
        }

        if (submission.nsfw && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection && (baseSub == "all" || baseSub == "frontpage" || baseSub.contains("/m/") || baseSub.contains("+") || baseSub == "popular"))) {
            big = false
            thumb = true
        }

        if (SettingValues.noImages) {
            big = false
            thumb = false
        }

        if (thumb && type == .SELF) {
            thumb = false
        }

        if (!big && !thumb && submission.type != .SELF && submission.type != .NONE) { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
            addTouch(view: thumbImage, action: #selector(LinkCellView.openLink(sender:)))
            thumbImage.image = UIImage.init(named: "web")
        } else if (thumb && !big) {
            addTouch(view: thumbImage, action: #selector(LinkCellView.openLink(sender:)))
            if (submission.nsfw) {
                thumbImage.image = UIImage.init(named: "nsfw")
            } else if (submission.thumbnailUrl == "web" || submission.thumbnailUrl.isEmpty) {
                thumbImage.image = UIImage.init(named: "web")
            } else {
                thumbImage.sd_setImage(with: URL.init(string: submission.thumbnailUrl), placeholderImage: UIImage.init(named: "web"))
            }
        } else {
            thumbImage.sd_setImage(with: URL.init(string: ""))
            self.thumbImage.frame.size.width = 0
        }


        if (big) {
            bannerImage.alpha = 0
            let imageSize = CGSize.init(width: submission.width, height: ((full && !SettingValues.commentFullScreen) ||  (!full && SettingValues.postImageMode == .CROPPED_IMAGE)) ? 200 : submission.height)

            aspect = imageSize.width / imageSize.height
            if (aspect == 0 || aspect > 10000 || aspect.isNaN) {
                aspect = 1
            }
            if ((full && !SettingValues.commentFullScreen) || (!full && SettingValues.postImageMode == .CROPPED_IMAGE)) {
                aspect = (full ? aspectWidth : self.contentView.frame.size.width) / (test ? 150 : 200)
                if (aspect == 0 || aspect > 10000 || aspect.isNaN) {
                    aspect = 1
                }

                submissionHeight = test ? 150 : 200
            }
            bannerImage.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openLink(sender:)))
            tap.delegate = self
            bannerImage.addGestureRecognizer(tap)

            let tap2 = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openLink(sender:)))
            tap2.delegate = self

            infoContainer.addGestureRecognizer(tap2)
            if (shouldShowLq) {
                lq = true
                loadedImage = URL.init(string: submission.lqUrl)
                bannerImage.sd_setImage(with: URL.init(string: submission.lqUrl), completed: { (image, error, cache, url) in
                    self.bannerImage.contentMode = .scaleAspectFill
                    if (cache == .none) {
                        UIView.animate(withDuration: 0.3, animations: {
                            self.bannerImage.alpha = 1
                        })
                    } else {
                        self.bannerImage.alpha = 1
                    }
                })
            } else {
                loadedImage = URL.init(string: submission.bannerUrl)
                bannerImage.sd_setImage(with: URL.init(string: submission.bannerUrl), completed: { (image, error, cache, url) in
                    self.bannerImage.contentMode = .scaleAspectFill
                    if (cache == .none) {
                        UIView.animate(withDuration: 0.3, animations: {
                            self.bannerImage.alpha = 1
                        })
                    } else {
                        self.bannerImage.alpha = 1
                    }
                })
            }
        } else {
            bannerImage.sd_setImage(with: URL.init(string: ""))
        }

        if(!full && !test){
            aspectWidth = self.contentView.frame.size.width
        }

        if(dtap == nil && SettingValues.submissionActionDoubleTap != .NONE){
            dtap = UIShortTapGestureRecognizer.init(target: self, action: #selector(self.doDTap(_:)))
            dtap!.numberOfTapsRequired = 2
            self.addGestureRecognizer(dtap!)
        }
        
        if (!full) {
            let comment = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openComment(sender:)))
            comment.delegate = self
            if(dtap != nil){
                comment.require(toFail: dtap!)
            }
            self.addGestureRecognizer(comment)
        }
        
        let mo = History.commentsSince(s: submission)
        comments.text = " \(submission.commentCount)" + (mo > 0 ? "(+\(mo))" : "")

        if (!registered && !full) {
            parent.registerForPreviewing(with: self, sourceView: self.contentView)
            registered = true
        }

        // TODO:
//        doConstraints()

        refresh()
        if (full) {
            self.setNeedsLayout()
        }

        if (type != .IMAGE && type != .SELF && !thumb) {
            infoContainer.isHidden = false
            var text = ""
            switch (type) {
            case .ALBUM:
                text = ("Album")
                break
            case .EXTERNAL:
                text = "External Link"
                break
            case .LINK, .EMBEDDED, .NONE:
                text = "Link"
                break
            case .DEVIANTART:
                text = "Deviantart"
                break
            case .TUMBLR:
                text = "Tumblr"
                break
            case .XKCD:
                text = ("XKCD")
                break
            case .GIF:
                text = ("GIF")
                break
            case .IMGUR:
                text = ("Imgur")
                break
            case .VIDEO:
                text = "YouTube"
                break
            case .STREAMABLE:
                text = "Streamable"
                break
            case .VID_ME:
                text = ("Vid.me")
                break
            case .REDDIT:
                text = ("Reddit content")
                break
            default:
                text = "Link"
                break
            }

            if (SettingValues.smallerTag && !full) {
                infoContainer.isHidden = true
                tagbody.isHidden = false
                taglabel.text = " \(text.uppercased()) "
            } else {
                tagbody.isHidden = true
                if(submission.isCrosspost && full){
                    var colorF = UIColor.white

                    let finalText = NSMutableAttributedString.init(string: "Crosspost - " + submission.domain, attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 14, submission: true)])

                    let endString = NSMutableAttributedString(string: "\nOriginal submission by ", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])
                    let by = NSMutableAttributedString(string: " in ", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])

                    let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: submission.author, small: false))\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF])


                    let userColor = ColorUtil.getColorForUser(name: submission.crosspostAuthor)
                    if (AccountController.currentName == submission.author) {
                        authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
                    } else if (userColor != ColorUtil.baseColor) {
                        authorString.addAttributes([kTTTBackgroundFillColorAttributeName: userColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
                    }

                    endString.append(authorString)
                    endString.append(by)

                    let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF] as [String: Any]

                    let boldString = NSMutableAttributedString(string: "r/\(submission.crosspostSubreddit)", attributes: attrs)

                    let color = ColorUtil.getColorForSub(sub: submission.crosspostSubreddit)
                    if (color != ColorUtil.baseColor) {
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

        if (longPress == nil) {
            longPress = UILongPressGestureRecognizer(target: self, action: #selector(LinkCellView.handleLongPress(_:)))
            longPress?.minimumPressDuration = 0.25 // 1 second press
            longPress?.delegate = self
            self.contentView.addGestureRecognizer(longPress!)
        }
        
        //todo maybe? self.contentView.backgroundColor = ColorUtil.getColorForSub(sub: submission.subreddit)

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

    public static var cachedInternet: Bool?
    public static func checkInternet() -> Bool {
        if(LinkCellView.cachedInternet != nil){
            return LinkCellView.cachedInternet!
        }
        let networkStatus = Reachability().connectionStatus()
        switch networkStatus {
        case .Unknown, .Offline:
            LinkCellView.cachedInternet =  false
        case .Online(.WWAN):
            LinkCellView.cachedInternet =  true
        case .Online(.WiFi):
            LinkCellView.cachedInternet =  true
        }
        return LinkCellView.cachedInternet!
    }

    var longPress: UILongPressGestureRecognizer?
    var timer: Timer?
    var cancelled = false

    func showMore() {
        timer!.invalidate()
        AudioServicesPlaySystemSound(1519)
        if (!self.cancelled && LinkCellView.checkInternet()) {
            self.more()
        }
    }

    func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.began) {
            cancelled = false
            timer = Timer.scheduledTimer(timeInterval: 0.25,
                    target: self,
                    selector: #selector(self.showMore),
                    userInfo: nil,
                    repeats: false)


        }
        if (sender.state == UIGestureRecognizerState.ended) {
            timer!.invalidate()
            cancelled = true
        }
    }


    func edit(sender: AnyObject) {
        let link = self.link!

        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Edit your submission"


        if (link.isSelf) {
            alertController.addAction(Action(ActionData(title: "Edit selftext", image: UIImage(named: "edit")!.menuIcon()), style: .default, handler: { action in
                self.editSelftext()
            }))
        }

        alertController.addAction(Action(ActionData(title: "Flair submission", image: UIImage(named: "size")!.menuIcon()), style: .default, handler: { action in
            self.flairSelf()

        }))


        alertController.addAction(Action(ActionData(title: "Delete submission", image: UIImage(named: "delete")!.menuIcon()), style: .default, handler: { action in
            self.deleteSelf(self)
        }))

        VCPresenter.presentAlert(alertController, parentVC: parentViewController!)
    }

    func editSelftext() {
        let reply = ReplyViewController.init(submission: link!, sub: (self.link?.subreddit)!, editing: true) { (cr) in
            DispatchQueue.main.async(execute: { () -> Void in
                self.setLink(submission: RealmDataWrapper.linkToRSubmission(submission: cr!), parent: self.parentViewController!, nav: self.navViewController!, baseSub: (self.link?.subreddit)!)
                self.showBody(width: self.contentView.frame.size.width)
            })
        }

        let navEditorViewController: UINavigationController = UINavigationController(rootViewController: reply)
        parentViewController?.present(navEditorViewController, animated: true, completion: nil)
        //todo new implementation
    }

    func deleteSelf(_ cell: LinkCellView) {
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Really delete your submission?"

        alertController.addAction(Action(ActionData(title: "Yes", image: UIImage(named: "delete")!.menuIcon()), style: .default, handler: { action in
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
                    break
                case .success(let flairs):
                    list.append(contentsOf: flairs)
                    DispatchQueue.main.async {
                        let sheet = UIAlertController(title: "r/\(self.link!.subreddit) flairs", message: nil, preferredStyle: .actionSheet)
                        sheet.addAction(
                                UIAlertAction(title: "Close", style: .cancel) { (action) in
                                    sheet.dismiss(animated: true, completion: nil)
                                }
                        )

                        for flair in flairs {
                            let somethingAction = UIAlertAction(title: (flair.text.isEmpty) ?flair.name : flair.text, style: .default) { (action) in
                                sheet.dismiss(animated: true, completion: nil)
                                self.setFlair(flair)
                            }

                            sheet.addAction(somethingAction)
                        }

                        self.parentViewController?.present(sheet, animated: true)
                    }
                    break
                }
            })
        } catch {
        }
    }

    var flairText: String?

    func setFlair(_ flair: FlairTemplate){
        if(flair.editable){
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

            alert.addAction(UIAlertAction(title: "Set flair", style: .default, handler: { [weak alert] (_) in
                self.submitFlairChange(flair, text: self.flairText ?? "")
            }))

            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

            //todo make this work on ipad
            parentViewController?.present(alert, animated: true, completion: nil)

        } else {
            submitFlairChange(flair)
        }
    }


    func submitFlairChange(_ flair: FlairTemplate, text: String? = ""){
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.flairSubmission(link!.subreddit, flairId: flair.id, submissionFullname: link!.id, text: text ?? "") { result in
                switch result {
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Flair not set", color: GMColor.red500Color(), seconds: 3, context: self.parentViewController)
                    }
                    break
                case .success(let success):
                    print(success)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Flair set successfully!", seconds: 3, context: self.parentViewController)
                        self.link!.flair = (text != nil && !text!.isEmpty) ? text! : flair.text
                        CachedTitle.getTitle(submission: self.link!, full: true, true, false)
                        self.setLink(submission: self.link!, parent: self.parentViewController!, nav: self.navViewController!, baseSub: (self.link?.subreddit)!)
                        self.showBody(width: self.contentView.frame.size.width)

                    }
                break
            }}
        } catch {
        }
    }

    func refresh() {
        let link = self.link!
        upvote.image = LinkCellImageCache.upvote
        save.image = LinkCellImageCache.save
        downvote.image = LinkCellImageCache.downvote
        var attrs: [String: Any] = [:]
        switch (ActionStates.getVoteDirection(s: link)) {
        case .down:
            downvote.image = LinkCellImageCache.downvoteTinted
            attrs = ([NSForegroundColorAttributeName: ColorUtil.downvoteColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true)])
            break
        case .up:
            upvote.image = LinkCellImageCache.upvoteTinted
            attrs = ([NSForegroundColorAttributeName: ColorUtil.upvoteColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true)])
            break
        default:
            attrs = ([NSForegroundColorAttributeName: ColorUtil.fontColor, NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true)])
            break
        }


        if (full) {
            let subScore = NSMutableAttributedString(string: (link.score >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(link.score) / Double(1000))) : " \(link.score)", attributes: attrs)
            let scoreRatio =
                    NSMutableAttributedString(string: (SettingValues.upvotePercentage && full && link.upvoteRatio > 0) ?
                            " (\(Int(link.upvoteRatio * 100))%)" : "", attributes: [NSFontAttributeName: comments.font, NSForegroundColorAttributeName: comments.textColor])

            var attrsNew: [String: Any] = [:]
            if (scoreRatio.length > 0) {
                let numb = (link.upvoteRatio)
                if (numb <= 0.5) {
                    if (numb <= 0.1) {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.blue500Color()]
                    } else if (numb <= 0.3) {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.blue400Color()]
                    } else {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.blue300Color()]
                    }
                } else {
                    if (numb >= 0.9) {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.orange500Color()]
                    } else if (numb >= 0.7) {
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
            score.text = (link.score >= 10000 && SettingValues.abbreviateScores) ? String(format: " %0.1fk", (Double(link.score) / Double(1000))) : " \(link.score)"
        }


        if (ActionStates.isSaved(s: link)) {
            save.image = LinkCellImageCache.saveTinted
        }
        if (History.getSeen(s: link) && !full) {
            self.title.alpha = 0.7
        } else {
            self.title.alpha = 1
        }

//        layoutForType()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        var topmargin = 0
        var bottommargin = 2
        var leftmargin = 0
        var rightmargin = 0

        if ((SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full) {
            topmargin = 5
            bottommargin = 5
            leftmargin = 5
            rightmargin = 5
            self.contentView.elevate(elevation: 2)
        }

        let f = self.contentView.frame
        let fr = UIEdgeInsetsInsetRect(f, UIEdgeInsetsMake(CGFloat(topmargin), CGFloat(leftmargin), CGFloat(bottommargin), CGFloat(rightmargin)))
        self.contentView.frame = fr
    }


    var registered: Bool = false

    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        if (full) {
            let locationInTextView = textView.convert(location, to: textView)

            if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
                previewingContext.sourceRect = textView.convert(rect, from: textView)
                if let controller = parentViewController?.getControllerForUrl(baseUrl: url) {
                    return controller
                }
            }
        } else {
            if let controller = parentViewController?.getControllerForUrl(baseUrl: (link?.url)!) {
                return controller
            }
        }
        return nil
    }

    func estimateHeight(_ full: Bool, _ reset: Bool = false) -> CGFloat {
        if (estimatedHeight == 0 || reset) {
            var paddingTop = CGFloat(0)
            var paddingBottom = CGFloat(2)
            var paddingLeft = CGFloat(0)
            var paddingRight = CGFloat(0)
            var innerPadding = CGFloat(0)
            if((SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full){
                paddingTop = 5
                paddingBottom = 5
                paddingLeft = 5
                paddingRight = 5
            }

            let actionbar = CGFloat(!full && SettingValues.hideButtonActionbar ? 0 : 24)

            var imageHeight = big && !thumb ? CGFloat(submissionHeight) : CGFloat(0)
            let thumbheight = (SettingValues.largerThumbnail ? CGFloat(75) : CGFloat(50))  - (SettingValues.postViewMode == .COMPACT ? 15 : 0)
            let textHeight = (!hasText || !full) ? CGFloat(0) : CGFloat((content?.textHeight)!)

            if(thumb){
                imageHeight = thumbheight
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between top and thumbnail
                innerPadding += 18 - (SettingValues.postViewMode == .COMPACT ? 4 : 0) //between label and bottom box
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between box and end
            } else if(big){
                if (SettingValues.postViewMode == .CENTER || full) {
                    innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 16) //between label
                    innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between banner and box
                } else {
                    innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between banner and label
                    innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between label and box
                }

                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between box and end
            } else {
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8)
                innerPadding += 5 //between label and body
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between body and box
                innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between box and end
            }

            var estimatedUsableWidth = aspectWidth - paddingLeft - paddingRight
            if(thumb){
                estimatedUsableWidth -= thumbheight //is the same as the width
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 16 : 24) //between edge and thumb
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between thumb and label
            } else {
                estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 16 : 24) //12 padding on either side
            }

            let framesetter = CTFramesetterCreateWithAttributedString(title.attributedText)
            let textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize.init(width: estimatedUsableWidth, height: CGFloat.greatestFiniteMagnitude), nil)

            let totalHeight = paddingTop + paddingBottom + (thumb ? max(ceil(textSize.height), imageHeight): ceil(textSize.height) + imageHeight) + innerPadding + actionbar + textHeight + (full ? CGFloat(10) : CGFloat(0))
            estimatedHeight = totalHeight
        }
        return estimatedHeight
    }

    func getInfo(locationInTextView: CGPoint) -> (URL, CGRect)? {
        if let attr = textView.link(at: locationInTextView) {
            return (attr.result.url!, attr.accessibilityFrame)
        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if (viewControllerToCommit is WebsiteViewController || viewControllerToCommit is SFHideSafariViewController || viewControllerToCommit is SingleSubredditViewController || viewControllerToCommit is UINavigationController || viewControllerToCommit is CommentViewController) {
            parentViewController?.show(viewControllerToCommit, sender: nil)
        } else {
            parentViewController?.present(viewControllerToCommit, animated: true)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var parentViewController: MediaViewController?
    public var navViewController: UIViewController?


    func openLink(sender: UITapGestureRecognizer? = nil) {
        (parentViewController)?.setLink(lnk: link!, shownURL: loadedImage, lq: lq, saveHistory: true) //todo check this
    }

    func openComment(sender: UITapGestureRecognizer? = nil) {
        if (!full) {
            if let delegate = self.del {
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

        if (bolAfterLabel) {
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
        if (image != nil) {
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
