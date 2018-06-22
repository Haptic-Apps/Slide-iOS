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
        if let delegate = self.del {
            delegate.upvote(self)
        }
    }

    func hide(sender: UITapGestureRecognizer? = nil) {
        if let delegate = self.del {
            delegate.hide(self)
        }
    }


    func reply(sender: UITapGestureRecognizer? = nil) {
        if let delegate = self.del {
            delegate.reply(self)
        }
    }

    func downvote(sender: UITapGestureRecognizer? = nil) {
        if let delegate = self.del {
            delegate.downvote(self)
        }
    }

    func more(sender: UITapGestureRecognizer? = nil) {
        if let delegate = self.del {
            delegate.more(self)
        }
    }

    func mod(sender: UITapGestureRecognizer? = nil) {
        if let delegate = self.del {
            delegate.mod(self)
        }
    }


    func save(sender: UITapGestureRecognizer? = nil) {
        if let delegate = self.del {
            delegate.save(self)
        }
    }


    var bannerImage = UIImageView()
    var thumbImage = UIImageView()
    var title = TTTAttributedLabel.init(frame: CGRect.zero)
    var score = UILabel()
    var box = UIStackView()
    var buttons = UIStackView()
    var comments = UILabel()
    var info = UILabel()
    var textView = TTTAttributedLabel.init(frame: CGRect.zero)
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
    var crosspost = UITableViewCell()

    var loadedImage: URL?
    var lq = false

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

    var content: CellContent?
    var hasText = false

    func showBody(width: CGFloat) {
        full = true
        let link = self.link!
        let color = ColorUtil.accentColorForSub(sub: ((link).subreddit))
        if (!link.htmlBody.isEmpty) {
            var html = link.htmlBody.trimmed()
            do {
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
            } catch {
            }
            parentViewController?.registerForPreviewing(with: self, sourceView: textView)
        }
    }

    var full = false
    var b = UIView()
    var estimatedHeight = CGFloat(0)
    var tagbody = UIView()

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.thumbImage = UIImageView(frame: CGRect(x: 0, y: 8, width: (SettingValues.largerThumbnail ? 75 : 50) - (SettingValues.postViewMode == .COMPACT ? 15 : 0), height: (SettingValues.largerThumbnail ? 75 : 50) - (SettingValues.postViewMode == .COMPACT ? 15 : 0)))
        thumbImage.layer.cornerRadius = 15;
        thumbImage.backgroundColor = UIColor.white
        thumbImage.clipsToBounds = true;
        thumbImage.contentMode = .scaleAspectFill
        thumbImage.elevate(elevation: 2.0)

        self.bannerImage = UIImageView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 0))
        bannerImage.contentMode = UIViewContentMode.scaleAspectFill
        bannerImage.layer.cornerRadius = 15;
        bannerImage.clipsToBounds = true
        bannerImage.backgroundColor = UIColor.white

        self.title = TTTAttributedLabel(frame: CGRect(x: 75, y: 8, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude));
        title.numberOfLines = 0
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.font = FontGenerator.fontOfSize(size: 18, submission: true)

        self.upvote = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 20))

        self.hide = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 20))
        hide.image = UIImage.init(named: "hide")?.menuIcon()

        self.reply = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 20))
        reply.image = UIImage.init(named: "reply")?.menuIcon()

        self.edit = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 20))
        edit.image = UIImage.init(named: "edit")?.menuIcon()

        self.save = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 20))

        self.downvote = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 20))

        self.mod = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 20))
        mod.image = UIImage.init(named: "mod")?.menuIcon().imageResize(sizeChange: CGSize.init(width: 20, height: 20))

        self.commenticon = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        commenticon.image = UIImage.init(named: "comments")?.menuIcon()

        self.submissionicon = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        submissionicon.image = UIImage.init(named: "upvote")?.menuIcon()

        submissionicon.contentMode = .scaleAspectFit
        commenticon.contentMode = .scaleAspectFit


        upvote.contentMode = .center
        downvote.contentMode = .center
        hide.contentMode = .center
        reply.contentMode = .center
        edit.contentMode = .center
        save.contentMode = .center
        mod.contentMode = .center

        self.textView = TTTAttributedLabel(frame: CGRect(x: 75, y: 8, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        self.textView.delegate = self
        self.textView.numberOfLines = 0
        self.textView.isUserInteractionEnabled = true
        self.textView.backgroundColor = .clear

        self.score = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        score.numberOfLines = 1
        score.font = FontGenerator.fontOfSize(size: 12, submission: true)
        score.textColor = ColorUtil.fontColor


        self.comments = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        comments.numberOfLines = 1
        comments.font = FontGenerator.fontOfSize(size: 12, submission: true)
        comments.textColor = ColorUtil.fontColor

        self.taglabel = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        taglabel.numberOfLines = 1
        taglabel.font = FontGenerator.boldFontOfSize(size: 12, submission: true)
        taglabel.textColor = UIColor.black

        tagbody = taglabel.withPadding(padding: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1))
        tagbody.backgroundColor = UIColor.white
        tagbody.clipsToBounds = true
        tagbody.layer.cornerRadius = 4


        self.info = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        info.numberOfLines = 2
        info.font = FontGenerator.fontOfSize(size: 12, submission: true)
        info.textColor = .white
        b = info.withPadding(padding: UIEdgeInsets.init(top: 4, left: 10, bottom: 4, right: 10))
        b.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        b.clipsToBounds = true
        b.layer.cornerRadius = 15

        self.box = UIStackView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        self.buttons = UIStackView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));

        bannerImage.translatesAutoresizingMaskIntoConstraints = false
        thumbImage.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        score.translatesAutoresizingMaskIntoConstraints = false
        comments.translatesAutoresizingMaskIntoConstraints = false
        box.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        upvote.translatesAutoresizingMaskIntoConstraints = false
        hide.translatesAutoresizingMaskIntoConstraints = false
        downvote.translatesAutoresizingMaskIntoConstraints = false
        mod.translatesAutoresizingMaskIntoConstraints = false
        edit.translatesAutoresizingMaskIntoConstraints = false
        save.translatesAutoresizingMaskIntoConstraints = false
        reply.translatesAutoresizingMaskIntoConstraints = false
        buttons.translatesAutoresizingMaskIntoConstraints = false
        b.translatesAutoresizingMaskIntoConstraints = false
        tagbody.translatesAutoresizingMaskIntoConstraints = false

        commenticon.translatesAutoresizingMaskIntoConstraints = false
        submissionicon.translatesAutoresizingMaskIntoConstraints = false

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

        self.contentView.addSubview(bannerImage)
        self.contentView.addSubview(thumbImage)
        self.contentView.addSubview(title)
        self.contentView.addSubview(textView)
        self.contentView.addSubview(b)
        self.contentView.addSubview(tagbody)
        box.addSubview(score)
        box.addSubview(comments)
        box.addSubview(commenticon)
        box.addSubview(submissionicon)

        buttons.addSubview(edit)
        buttons.addSubview(reply)
        buttons.addSubview(save)
        buttons.addSubview(hide)
        buttons.addSubview(upvote)
        buttons.addSubview(downvote)
        buttons.addSubview(mod)
        self.contentView.addSubview(box)
        self.contentView.addSubview(buttons)

        buttons.isUserInteractionEnabled = true
        bannerImage.contentMode = UIViewContentMode.scaleAspectFill
        bannerImage.layer.cornerRadius = 15;
        bannerImage.clipsToBounds = true
        bannerImage.backgroundColor = UIColor.white
        thumbImage.layer.cornerRadius = 10;
        thumbImage.backgroundColor = UIColor.white
        thumbImage.clipsToBounds = true;
        thumbImage.contentMode = .scaleAspectFill

    }

    func addTouch(view: UIView, action: Selector) {
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: action)
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    var thumb = true
    var submissionHeight: Int = 0
    var addTouch = false

    override func updateConstraints() {
        super.updateConstraints()
        var topmargin = 0
        var bottommargin = 2
        var leftmargin = 0
        var rightmargin = 0
        var innerpadding = 0
        var radius = 0

        if ((SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) && !full) {
            topmargin = 5
            bottommargin = 5
            leftmargin = 5
            rightmargin = 5
            innerpadding = 5
            radius = 15
        }

        self.contentView.layoutMargins = UIEdgeInsets.init(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin))

        let metrics = ["horizontalMargin": 75, "top": topmargin, "bottom": bottommargin, "separationBetweenLabels": 0, "labelMinHeight": 75, "bannerHeight": submissionHeight, "left": leftmargin, "padding": innerpadding, "ishidden": !full && SettingValues.hideButtonActionbar ? 0 : 24, "ishiddeni": !full && SettingValues.hideButtonActionbar ? 0 : 18] as [String: Int]
        let views = ["label": title, "body": textView, "image": thumbImage, "score": score, "comments": comments, "banner": bannerImage, "scorei": submissionicon, "commenti": commenticon, "box": box] as [String: Any]
        let views2 = ["buttons": buttons, "upvote": upvote, "downvote": downvote, "hide": hide, "mod": mod, "reply": reply, "edit": edit, "save": save] as [String: Any]

        box.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[scorei(12)]-2-[score(>=20)]-8-[commenti(12)]-2-[comments(>=20)]",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        box.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[score(ishidden)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        box.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[scorei(ishiddeni)]-4-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        box.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[commenti(ishiddeni)]-4-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[buttons(ishidden)]-12-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views2))

        box.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[comments(ishidden)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        self.contentView.layer.cornerRadius = CGFloat(radius)
        self.contentView.layer.masksToBounds = true

        if (full) {
            buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:\(AccountController.isLoggedIn && AccountController.currentName == link?.author ? "[edit(24)]-16-" : "")[mod(24)]-16-[reply(24)]-16-[save(24)]-16-[upvote(24)]-16-[downvote(24)]-8-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: metrics,
                    views: views2))
        } else {
            let hideString = SettingValues.hideButton ? "[hide(24)]-12-" : ""
            let saveString = SettingValues.saveButton ? "[save(24)]-12-" : ""
            buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[mod(24)]-16-\(hideString)\(saveString)[upvote(24)]-16-[downvote(24)]-8-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: metrics,
                    views: views2))
        }
        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[upvote(ishidden)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views2))

        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[downvote(ishidden)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views2))

        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[save(ishidden)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views2))
        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[hide(ishidden)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views2))
        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[mod(ishidden)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views2))

        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[reply(ishidden)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views2))
        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[edit(ishidden)]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views2))

    }

    func getHeightFromAspectRatio(imageHeight: Int, imageWidth: Int) -> Int {
        let ratio = Double(imageHeight) / Double(imageWidth)
        let width = Double(contentView.frame.size.width);
        return Int(width * ratio)

    }

    var big = false
    var bigConstraint: NSLayoutConstraint?
    var thumbConstraint: [NSLayoutConstraint] = []

    var dtap : UIShortTapGestureRecognizer?

    func refreshLink(_ submission: RSubmission) {
        self.link = submission

        title.setText(CachedTitle.getTitle(submission: submission, full: full, true, false))

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

        refresh()
        let more = History.commentsSince(s: submission)
        comments.text = " \(submission.commentCount)" + (more > 0 ? " (+\(more))" : "")
    }
    
    func doDTap(_ sender: AnyObject){
        switch(SettingValues.submissionActionDoubleTap){
        case .UPVOTE:
            self.upvote()
            break
        case .DOWNVOTE:
            self.downvote()
            break
        case .SAVE:
            self.save()
            break
        case .MENU:
            self.more()
            break
        default:
            break
        }
    }


    var link: RSubmission?
    var aspectWidth = CGFloat(0)

    func setLink(submission: RSubmission, parent: MediaViewController, nav: UIViewController?, baseSub: String, test : Bool = false) {
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

        title.setText(CachedTitle.getTitle(submission: submission, full: full, false
                , false))

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
                    mod.image = UIImage.init(named: "mod")?.withColor(tintColor: GMColor.red500Color()).imageResize(sizeChange: CGSize.init(width: 20, height: 20))
                } else {
                    mod.image = UIImage.init(named: "mod")?.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20))
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

        if (bigConstraint != nil) {
            self.contentView.removeConstraint(bigConstraint!)
        }

        submissionHeight = submission.height

        var type = test ? ContentType.CType.LINK : ContentType.getContentType(baseUrl: submission.url)
        if (submission.isSelf) {
            type = .SELF
        }

        if (SettingValues.bannerHidden && !full) {
            big = false
            thumb = true
        }

        let fullImage = ContentType.fullImage(t: type)

        if (!fullImage && submissionHeight < 50) {
            big = false
            thumb = true
        } else if (big && (SettingValues.bigPicCropped || full)) {
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
            let imageSize = CGSize.init(width: submission.width, height: (full || SettingValues.bigPicCropped) ? 200 : submission.height);
            var aspect = imageSize.width / imageSize.height
            if (aspect == 0 || aspect > 10000 || aspect.isNaN) {
                aspect = 1
            }
            if (full || SettingValues.bigPicCropped) {
                aspect = (full ? aspectWidth : self.contentView.frame.size.width) / (test ? 150 : 200)
                submissionHeight = test ? 150 : 200
                bigConstraint = NSLayoutConstraint(item: bannerImage, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: bannerImage, attribute: NSLayoutAttribute.height, multiplier: aspect, constant: 0.0)
            } else {
                bigConstraint = NSLayoutConstraint(item: bannerImage, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: bannerImage, attribute: NSLayoutAttribute.height, multiplier: aspect, constant: 0.0)
            }
            bannerImage.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openLink(sender:)))
            tap.delegate = self
            bannerImage.addGestureRecognizer(tap)

            let tap2 = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openLink(sender:)))
            tap2.delegate = self

            b.addGestureRecognizer(tap2)
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

        doConstraints()

        refresh()
        if (full) {
            self.setNeedsLayout()
        }

        if (type != .IMAGE && type != .SELF && !thumb) {
            b.isHidden = false
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
                b.isHidden = true
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

                    endString.append(by)
                    endString.append(authorString)

                    let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: colorF] as [String: Any]

                    let boldString = NSMutableAttributedString(string: "r/\(submission.crosspostSubreddit)", attributes: attrs)

                    let color = ColorUtil.getColorForSub(sub: submission.crosspostSubreddit)
                    if (color != ColorUtil.baseColor) {
                        boldString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: boldString.length))
                    }

                    endString.append(boldString)
                    finalText.append(endString)

                    b.addTapGestureRecognizer {
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
            b.isHidden = true
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

    //This function will update constraints if they need to be changed to change the display type
    func doConstraints() {
        var target = CurrentType.none

        if (thumb && !big) {
            target = .thumb
        } else if (big) {
            target = .banner
        } else {
            target = .text
        }

        print(currentType == target)

        if (currentType == target && target != .banner) {
            return //work is already done
        } else if (currentType == target && target == .banner && bigConstraint != nil) {
            self.contentView.addConstraint(bigConstraint!)
            return
        }

        let metrics = ["horizontalMargin": 75, "top": 0, "bottom": 0, "separationBetweenLabels": 0, "full": Int(contentView.frame.size.width),"ctwelve": SettingValues.postViewMode == .COMPACT ? 8 : 12,"ceight": SettingValues.postViewMode == .COMPACT ? 4 : 8, "bannerPadding": (full || SettingValues.postViewMode != .CARD) ? 5 : 0, "size": full ? 16 : 8, "labelMinHeight": 75, "thumb": (SettingValues.largerThumbnail ? 75 : 50) - (SettingValues.postViewMode == .COMPACT ? 15 : 0), "bannerHeight": submissionHeight] as [String: Int]
        let views = ["label": title, "body": textView, "image": thumbImage, "info": b, "tag": tagbody, "mod" : mod, "upvote": upvote, "downvote": downvote, "score": score, "comments": comments, "banner": bannerImage, "buttons": buttons, "box": box] as [String: Any]
        var bt = "[buttons]-(ceight)-"
        var bx = "[box]-(ceight)-"
        if (SettingValues.hideButtonActionbar && !full) {
            bt = "[buttons(0)]-4-"
            bx = "[box(0)]-4-"
        }

        self.contentView.removeConstraints(thumbConstraint)
        thumbConstraint = []

        if (target == .thumb) {
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[image(thumb)]",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            if(SettingValues.leftThumbnail){
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ceight)-[image(thumb)]-(ceight)-[label]-(ctwelve)-|",
                                                                                  options: NSLayoutFormatOptions(rawValue: 0),
                                                                                  metrics: metrics,
                                                                                  views: views))
            } else {
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[label]-(ceight)-[image(thumb)]-(ceight)-|",
                                                                                  options: NSLayoutFormatOptions(rawValue: 0),
                                                                                  metrics: metrics,
                                                                                  views: views))
            }
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[label]-\(bx)|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[label]-\(bt)|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        } else if (target == .banner) {
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-[image(0)]",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[label]-(ctwelve)-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            if(SettingValues.postViewMode == .CENTER || full){
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[label]-(ceight)-[banner]-(ctwelve)-\(bx)|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: metrics,
                    views: views))
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[info]-[banner]",
                                                                                  options: NSLayoutFormatOptions.alignAllLastBaseline,
                                                                                  metrics: metrics,
                                                                                  views: views))
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[banner]-[tag]",
                                                                                  options: NSLayoutFormatOptions.alignAllLastBaseline,
                                                                                  metrics: metrics,
                                                                                  views: views))
                
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[info(45)]-(ceight)-[buttons]",
                                                                                  options: NSLayoutFormatOptions(rawValue: 0),
                                                                                  metrics: metrics,
                                                                                  views: views))
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[tag]-(ctwelve)-[buttons]",
                                                                                  options: NSLayoutFormatOptions(rawValue: 0),
                                                                                  metrics: metrics,
                                                                                  views: views))
                
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[info]-(ceight)-[box]",
                                                                                  options: NSLayoutFormatOptions(rawValue: 0),
                                                                                  metrics: metrics,
                                                                                  views: views))
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[tag]-(ctwelve)-[box]",
                                                                                  options: NSLayoutFormatOptions(rawValue: 0),
                                                                                  metrics: metrics,
                                                                                  views: views))
                
                
            } else {
                
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(bannerPadding)-[banner]-(ceight)-[label]-(ctwelve)-\(bx)|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: metrics,
                    views: views))
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[info(45)]-(ceight)-[label]",
                                                                                  options: NSLayoutFormatOptions(rawValue: 0),
                                                                                  metrics: metrics,
                                                                                  views: views))
                
                thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[tag]-(ctwelve)-[label]",
                                                                                  options: NSLayoutFormatOptions(rawValue: 0),
                                                                                  metrics: metrics,
                                                                                  views: views))
                
            }
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:\(bt)|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:\(bx)|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(bannerPadding)-[banner]-(bannerPadding)-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(bannerPadding)-[info]-(bannerPadding)-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[tag]-(ctwelve)-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
        } else if (target == .text) {
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ceight)-[image(0)]",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[label]-(ctwelve)-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(ctwelve)-[body]-(ctwelve)-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(ctwelve)-[label]-5@1000-[body]-(ctwelve)-\(bx)|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:\(bt)|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        }
        self.contentView.addConstraints(thumbConstraint)
        if (target == .banner && bigConstraint != nil) {
            self.contentView.addConstraint(bigConstraint!)
            return
        }
        currentType = target
    }

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


    func setLinkForPreview(submission: RSubmission) {
        full = false
        lq = false
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        comments.textColor = ColorUtil.fontColor
        title.textColor = ColorUtil.fontColor

        self.link = submission

        title.setText(CachedTitle.getTitle(submission: submission, full: false, false))
        title.sizeToFit()

        reply.isHidden = true
        if (!SettingValues.hideButton) {
            hide.isHidden = true
        } else {
            hide.isHidden = false
        }
        if (!SettingValues.saveButton) {
            save.isHidden = true
        } else {
            save.isHidden = false
        }

        upvote.isHidden = false
        downvote.isHidden = false
        edit.isHidden = true

        thumb = submission.thumbnail
        big = submission.banner
        //todo test if big image
        //todo test if self and hideSelftextLeadImage, don't show anything
        //test if should be LQ, get LQ image instead of banner image
        if (bigConstraint != nil) {
            self.contentView.removeConstraint(bigConstraint!)
        }

        submissionHeight = submission.height

        var type = ContentType.getContentType(baseUrl: submission.url)
        if (submission.isSelf) {
            type = .SELF
        }

        if (SettingValues.bannerHidden && !full) {
            big = false
            thumb = true
        }


        let fullImage = ContentType.fullImage(t: type)

        if (!fullImage && submissionHeight < 50) {
            big = false
            thumb = true
        } else if (big && (SettingValues.bigPicCropped || full)) {
            submissionHeight = 200
        } else if (big) {
            let h = getHeightFromAspectRatio(imageHeight: submissionHeight, imageWidth: submission.width)
            if (h == 0) {
                submissionHeight = 200
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

        let shouldShowLq = false
        if (type == ContentType.CType.SELF && SettingValues.hideImageSelftext
                || SettingValues.noImages && submission.isSelf) {
            big = false
            thumb = false
        }

        if (big || !submission.thumbnail) {
            thumb = false
        }
        if (thumb && type == .SELF) {
            thumb = false
        }


        if (!big && !thumb && submission.type != .SELF && submission.type != .NONE) { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
            addTouch(view: thumbImage, action: #selector(LinkCellView.openLink(sender:)))
            thumbImage.image = UIImage.init(named: "web")
        }

        if (thumb && !big) {
            addTouch(view: thumbImage, action: #selector(LinkCellView.openLink(sender:)))
            if (submission.thumbnailUrl == "nsfw" || (submission.nsfw && !SettingValues.nsfwPreviews)) {
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
            let imageSize = CGSize.init(width: submission.width, height: full ? 200 : submission.height);
            var aspect = imageSize.width / imageSize.height
            if (aspect == 0 || aspect > 10000 || aspect.isNaN) {
                aspect = 1
            }
            if (!full) {
                bigConstraint = NSLayoutConstraint(item: bannerImage, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: bannerImage, attribute: NSLayoutAttribute.height, multiplier: aspect, constant: 0.0)
            } else {
                aspect = self.contentView.frame.size.width / 200
                submissionHeight = 200
                bigConstraint = NSLayoutConstraint(item: bannerImage, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: bannerImage, attribute: NSLayoutAttribute.height, multiplier: aspect, constant: 0.0)

            }
            bannerImage.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openLink(sender:)))
            tap.delegate = self
            bannerImage.addGestureRecognizer(tap)
            if (shouldShowLq) {
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

        comments.text = " \(submission.commentCount)"

        doConstraints()

        refresh()


        if (type != .IMAGE && type != .SELF && !thumb) {
            b.isHidden = false
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
                b.isHidden = true
                tagbody.isHidden = false
                taglabel.text = " \(text.uppercased()) "
            } else {
                tagbody.isHidden = true
                let finalText = NSMutableAttributedString.init(string: text, attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 14, submission: true)])
                finalText.append(NSAttributedString.init(string: "\n\(submission.domain)"))
                info.attributedText = finalText
            }

        } else {
            b.isHidden = true
        }
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
                        let message = MDCSnackbarMessage()
                        message.text = "No subreddit flairs found"
                        MDCSnackbarManager.show(message)
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
                        let message = MDCSnackbarMessage()
                        message.text = "Could not change flair"
                        MDCSnackbarManager.show(message)
                    }
                    break
                case .success(let success):
                    print(success)
                    DispatchQueue.main.async {
                        let message = MDCSnackbarMessage()
                        message.text = "Flair set successfully"
                        MDCSnackbarManager.show(message)
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
        upvote.image = UIImage.init(named: "upvote")?.menuIcon()
        save.image = UIImage.init(named: "save")?.menuIcon()
        downvote.image = UIImage.init(named: "downvote")?.menuIcon()
        var attrs: [String: Any] = [:]
        switch (ActionStates.getVoteDirection(s: link)) {
        case .down:
            downvote.image = UIImage.init(named: "downvote")?.withColor(tintColor: ColorUtil.downvoteColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20))
            attrs = ([NSForegroundColorAttributeName: ColorUtil.downvoteColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true)])
            break
        case .up:
            upvote.image = UIImage.init(named: "upvote")?.withColor(tintColor: ColorUtil.upvoteColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20))
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
            save.image = UIImage.init(named: "save")?.withColor(tintColor: GMColor.yellow500Color()).imageResize(sizeChange: CGSize.init(width: 20, height: 20))
        }
        if (History.getSeen(s: link) && !full) {
            self.title.alpha = 0.7
        } else {
            self.title.alpha = 1
        }
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
            let img = UIImage(named: imageName)?.imageResize(sizeChange: CGSize.init(width: self.font.pointSize, height: self.font.pointSize)).withColor(tintColor: ColorUtil.fontColor)
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

extension UIImage {
    func withColor(tintColor: UIColor) -> UIImage {
        var image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        tintColor.set()
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIView: MaterialView {
    func elevate(elevation: Double) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: elevation)
        self.layer.shadowRadius = CGFloat(elevation)
        self.layer.shadowOpacity = 0.24
    }
}

protocol MaterialView {
    func elevate(elevation: Double)
}

extension String {
    func toAttributedString() -> NSAttributedString? {
        guard let data = self.data(using: String.Encoding.utf8,
                allowLossyConversion: false) else {
            return nil
        }

        let htmlString = try? NSMutableAttributedString(data: data, options: [NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue, NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)

        return htmlString
    }
}
extension UIView{
    func blink(color: UIColor) {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveLinear], animations: {
            self.backgroundColor = color
        }, completion: {finished in
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveLinear], animations: {
                self.backgroundColor = ColorUtil.foregroundColor
            }, completion: nil)
        })
    }
}
