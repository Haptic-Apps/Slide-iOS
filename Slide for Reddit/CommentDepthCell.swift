//
//  CommentDepthCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/31/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import TTTAttributedLabel
import RealmSwift
import AudioToolbox
import XLActionController
import RLBAlertsPickers
import Anchorage

protocol TTTAttributedCellDelegate: class {
    func pushedSingleTap(_ cell: CommentDepthCell)
    func isMenuShown() -> Bool
    func getMenuShown() -> String
}

class CommentDepthCell: MarginedTableViewCell, UIViewControllerPreviewingDelegate {
    
    var sideView: UIView = UIView()
    var menu = UIStackView()
    var menuBack = UIView()
    var reply = UIStackView()
    
    var sideViewSpace: UIView = UIView()
    var topViewSpace: UIView = UIView()
    var title: TTTAttributedLabel = TTTAttributedLabel.init(frame: CGRect.zero)
    
    //Buttons for comment menu
    var upvoteButton = UIButton()
    var downvoteButton = UIButton()
    var replyButton = UIButton()
    var moreButton = UIButton()
    var editButton = UIButton()
    var deleteButton = UIButton()
    var modButton = UIButton()
    var editShown = false
    var archived = false
    var modShown = false
    
    //Buttons for reply
    var body: UITextView = UITextView()
    var sendB = UIButton()
    var discardB = UIButton()
    var edit = false


    var childrenCount: UIView = UIView()
    var childrenCountLabel: UILabel = UILabel()
    var comment: RComment?
    var depth: Int = 0
    
    var menuShown = false
    var replyShown = false

    var delegate: TTTAttributedCellDelegate? = nil
    var content: Object? = nil

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = ColorUtil.backgroundColor
        self.title = TTTAttributedLabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).then({
            $0.numberOfLines = 0
            $0.font = FontGenerator.fontOfSize(size: 16, submission: false)
            $0.isUserInteractionEnabled = true
            $0.accessibilityIdentifier = "Comment body"
            $0.delegate = self
            $0.textColor = ColorUtil.fontColor
        })

        self.childrenCountLabel = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 15)).then({
            $0.numberOfLines = 1
            $0.font = FontGenerator.boldFontOfSize(size: 12, submission: false)
            $0.textColor = UIColor.white
            $0.layer.shadowOffset = CGSize(width: 0, height: 0)
            $0.layer.shadowOpacity = 0.4
            $0.layer.shadowRadius = 4
        })
        
        let padding = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

        self.sideView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        self.sideViewSpace = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        self.topViewSpace = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 4))
        self.topViewSpace.accessibilityIdentifier = "Top view margin"

        self.childrenCount = childrenCountLabel.withPadding(padding: padding).then({
            $0.alpha = 0
            $0.backgroundColor = ColorUtil.accentColorForSub(sub: "")
            $0.layer.cornerRadius = 4
            $0.clipsToBounds = true
        })

        self.contentView.addSubviews(sideView, sideViewSpace, topViewSpace, title, childrenCount)
        
        if(dtap == nil && SettingValues.commentActionDoubleTap != .NONE){
            dtap = UIShortTapGestureRecognizer.init(target: self, action: #selector(self.doDTap(_:)))
            dtap!.numberOfTapsRequired = 2
            self.contentView.addGestureRecognizer(dtap!)
        }

        let tapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(self.handleShortPress(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        if(dtap != nil){
            tapGestureRecognizer.require(toFail: dtap!)
        }
        self.title.addGestureRecognizer(tapGestureRecognizer)

        long = UILongPressGestureRecognizer.init(target: self, action: #selector(self.handleLongPress(_:)))
        long.minimumPressDuration = 0.25
        long.delegate = self
        self.addGestureRecognizer(long)

        self.contentView.backgroundColor = ColorUtil.foregroundColor
        sideViewSpace.backgroundColor = ColorUtil.backgroundColor
        topViewSpace.backgroundColor = ColorUtil.backgroundColor

        self.clipsToBounds = true
        
        
        self.menu = UIStackView().then {
            $0.accessibilityIdentifier = "Comment menu"
            $0.axis = .horizontal
            $0.alignment = .center
            $0.isHidden = true
        }
        
        menuBack = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        menuBack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        menu.addSubview(menuBack)

        
        upvoteButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "upvote")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.upvote(_:)), for: UIControlEvents.touchUpInside)
            })
        downvoteButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "downvote")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.downvote(_:)), for: UIControlEvents.touchUpInside)
        })
        replyButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "reply")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.reply(_:)), for: UIControlEvents.touchUpInside)
        })
        moreButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "ic_more_vert_white")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.menu(_:)), for: UIControlEvents.touchUpInside)
        })
        editButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "edit")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.edit(_:)), for: UIControlEvents.touchUpInside)
        })
        deleteButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "delete")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.delete(_:)), for: UIControlEvents.touchUpInside)
        })
        modButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "mod")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.mod(_:)), for: UIControlEvents.touchUpInside)
        })

        menu.addArrangedSubviews(editButton, deleteButton, upvoteButton, downvoteButton, replyButton, moreButton, modButton)
        self.contentView.addSubview(menu)
        configureLayout()
    }

    func doLongClick() {
        timer!.invalidate()
        AudioServicesPlaySystemSound(1519)
        if (!self.cancelled) {
            if (SettingValues.swapLongPress) {
                //todo this is probably wrong
                if (self.delegate!.isMenuShown() && self.delegate!.getMenuShown() != comment!.getIdentifier()) {
                    self.showMenu(nil)
                } else {
                    self.pushedSingleTap(nil)
                }
            } else {
                self.showMenu(nil)
            }
        }
    }

    var timer: Timer?
    var cancelled = false

    func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.began) {
            cancelled = false
            timer = Timer.scheduledTimer(timeInterval: 0.25,
                    target: self,
                    selector: #selector(self.doLongClick),
                    userInfo: nil,
                    repeats: false)
        }
        if (sender.state == UIGestureRecognizerState.ended) {
            timer!.invalidate()
            cancelled = true
        }
    }

    func handleShortPress(_ sender: UIGestureRecognizer) {
        if (SettingValues.swapLongPress || (self.delegate!.isMenuShown() && delegate!.getMenuShown() == (content as! RComment).getId())) {
            self.showMenu(sender)
        } else {
            self.pushedSingleTap(sender)
        }
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (gestureRecognizer.view == self.title) {
            return self.title.link(at: touch.location(in: self.title)) == nil
        }
        return true
    }

    var long = UILongPressGestureRecognizer.init(target: self, action: nil)

    func showMenu(_ sender: AnyObject?) {
        if let del = self.delegate {
            if (del.isMenuShown() && del.getMenuShown() == (content as! RComment).getId()) {
                self.hideCommentMenu()
            } else {
                self.showCommentMenu()
            }
        }
    }
    
    func showCommentMenu(){
        oldDepth = depth
        if(!AccountController.isLoggedIn || comment!.archived || parent!.np){
            upvoteButton.isHidden = true
            downvoteButton.isHidden = true
            replyButton.isHidden = true
        }
        if(!comment!.canMod){
            modButton.isHidden = true
        }
        if(comment!.author != AccountController.currentName){
            editButton.isHidden = true
            deleteButton.isHidden = true
        }
        parent!.menuShown = true
        menuShown = true
        parent!.menuId = comment!.getIdentifier()
        menu.isHidden = false
        if (depth == 1) {
            depth = 1
        } else {
            depth = 2
        }
        updateDepth()
        self.contentView.backgroundColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.getColorForSub(sub: ((comment)!.subreddit)).withAlphaComponent(0.25))
        menuBack.backgroundColor = ColorUtil.getColorForSub(sub: comment!.subreddit)
        parent!.reloadHeights()
    }
    
    func hideCommentMenu(){
        menu.isHidden = true
        parent!.menuShown = false
        menuShown = false
        parent!.menuId = ""
        depth = oldDepth
        updateDepth()
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        parent!.reloadHeights()
    }

    var parent: CommentViewController?
    
    func upvote(_ s: AnyObject) {
        parent!.vote(comment: comment!, dir: .up)
        self.refresh(comment: comment!, submissionAuthor: (parent!.submission?.author)!, text: self.cellContent!)
    }
    
    func reply(_ s: AnyObject) {
        //todo show reply menu
    }

    func menu(_ s: AnyObject) {
        more(parent!)
    }
    
    func downvote(_ s: AnyObject) {
        parent!.vote(comment: comment!, dir: .down)
        self.refresh(comment: comment!, submissionAuthor: (parent!.submission?.author)!, text: self.cellContent!)
    }
    
    func save() {
        parent!.saveComment(self.comment!)
    }
    
    func edit(_ s: AnyObject) {
        self.parent!.editComment()
    }
    
    func doDelete(_ s: AnyObject) {
        self.parent!.deleteComment(cell: self)
    }
    
    func showModMenu(_ s: AnyObject) {
        parent!.modMenu(self)
    }
    
    func vote() {
        if (content is RComment) {
            let current = ActionStates.getVoteDirection(s: comment!)
            let dir = (current == VoteDirection.none) ? VoteDirection.up : VoteDirection.none
            var direction = dir
            switch (ActionStates.getVoteDirection(s: comment!)) {
            case .up:
                if (dir == .up) {
                    direction = .none
                }
                break
            case .down:
                if (dir == .down) {
                    direction = .none
                }
                break
            default:
                break
            }
            do {
                try parent?.session?.setVote(direction, name: (comment!.name), completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                    case .success(_): break
                    }
                })
            } catch {
                print(error)
            }
            ActionStates.setVoteDirection(s: comment!, direction: direction)
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modApprove() {
        if (content is RComment) {
            do {
                try parent?.session?.approve(comment!.id, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Approving comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    case .success(_):
                        self.parent!.approved.append(self.comment!.id)
                        if(self.parent!.removed.contains(self.comment!.id)){
                            self.parent!.removed.remove(at: self.parent!.removed.index(of: self.comment!.id)!)
                        }
                        DispatchQueue.main.async {
                            self.parent!.tableView.reloadData()
                            BannerUtil.makeBanner(text: "Comment approved!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func modDistinguish() {
        if (content is RComment) {
            do {
                try parent?.session?.distinguish(comment!.id, how: "yes", completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Distinguishing comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    case .success(_):
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Comment distinguished!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modSticky(sticky: Bool) {
        if (content is RComment) {
            do {
                try parent?.session?.distinguish(comment!.id, how: "yes", sticky: sticky, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Couldn't \(sticky ? "" : "un-")pin comment!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    case .success(_):
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Comment \(sticky ? "" : "un-")pinned!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func modRemove(_ spam: Bool = false) {
        if (content is RComment) {
            do {
                try parent?.session?.remove(comment!.id, spam: spam, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Removing comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    case .success(_):
                        self.parent!.removed.append(self.comment!.id)
                        if(self.parent!.approved.contains(self.comment!.id)){
                            self.parent!.approved.remove(at: self.parent!.approved.index(of: self.comment!.id)!)
                        }
                        DispatchQueue.main.async {
                            self.parent!.tableView.reloadData()
                            BannerUtil.makeBanner(text: "Comment removed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                }
            })
            
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modBan(why: String, duration: Int?) {
        if (content is RComment) {
            do {
                try parent?.session?.ban(comment!.author, banReason: why, duration: duration == nil ? 999 /*forever*/ : duration!, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Banning user failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    case .success(_):
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "u/\(self.comment!.author) banned!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    }

                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }


    func more(_ par: CommentViewController) {

        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Comment by u/\(comment!.author)"


        alertController.addAction(Action(ActionData(title: "\(AccountController.formatUsernamePosessive(input: comment!.author, small: false)) profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { action in

            let prof = ProfileViewController.init(name: self.comment!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: nil, parentViewController: par);
        }))
        alertController.addAction(Action(ActionData(title: "Share comment permalink", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { action in
            let activityViewController = UIActivityViewController(activityItems: [self.comment!.permalink], applicationActivities: nil)
            par.present(activityViewController, animated: true, completion: {})
        }))
        if (AccountController.isLoggedIn) {
            alertController.addAction(Action(ActionData(title: "Save", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { action in
                par.saveComment(self.comment!)
            }))
        }
        alertController.addAction(Action(ActionData(title: "Report", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
            PostActions.report(self.comment!, parent: par)
        }))
        
        alertController.addAction(Action(ActionData(title: "Tag user", image: UIImage(named: "subs")!.menuIcon()), style: .default, handler: { action in
            par.tagUser(name: self.comment!.author)
        }))

        alertController.addAction(Action(ActionData(title: "Copy text", image: UIImage(named: "copy")!.menuIcon()), style: .default, handler: { action in
            let alert = UIAlertController.init(title: "Copy text", message: "", preferredStyle: .alert)
            alert.addTextViewer(text: .text(self.comment!.body))
            alert.addAction(UIAlertAction.init(title: "Copy all", style: .default, handler: { (action) in
                UIPasteboard.general.string = self.comment!.body
            }))
            alert.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: { (action) in
                
            }))
            par.present(alert, animated: true)
        }))

        VCPresenter.presentAlert(alertController, parentVC: par.parent!)
    }

    func mod(_ par: CommentViewController) {
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Comment by u/\(comment!.author)"


        alertController.addAction(Action(ActionData(title: "\(comment!.reports.count) reports", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { action in
            var reports = ""
            for report in self.comment!.reports {
                reports = reports + report + "\n"
            }
            let alert = UIAlertController(title: "Reports",
                                          message: reports,
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let cancelAction = UIAlertAction(title: "OK",
                                             style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            self.parent?.present(alert, animated: true, completion: nil)

        }))
        alertController.addAction(Action(ActionData(title: "Approve", image: UIImage(named: "approve")!.menuIcon()), style: .default, handler: { action in
            self.modApprove()
        }))

        alertController.addAction(Action(ActionData(title: "Ban user", image: UIImage(named: "ban")!.menuIcon()), style: .default, handler: { action in
            //todo show dialog for this
        }))
        
        if(comment!.author == AccountController.currentName){
            alertController.addAction(Action(ActionData(title: "Distinguish", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { action in
                self.modDistinguish()
            }))
        }

        if(comment!.author == AccountController.currentName && comment!.depth == 1){
            if(comment!.sticky){
                alertController.addAction(Action(ActionData(title: "Un-pin", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
                    self.modSticky(sticky: false)
                }))
            } else {
                alertController.addAction(Action(ActionData(title: "Pin and distinguish", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
                    self.modSticky(sticky: true)
                }))
            }
        }

        alertController.addAction(Action(ActionData(title: "Remove", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: { action in
            self.modRemove()
        }))

        alertController.addAction(Action(ActionData(title: "Mark as spam", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
            self.modRemove(true)
        }))

        alertController.addAction(Action(ActionData(title: "User profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { action in
            let prof = ProfileViewController.init(name: self.comment!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: nil, parentViewController: par);
        }))

        VCPresenter.presentAlert(alertController, parentVC: par.parent!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var sideConstraints: [NSLayoutConstraint] = []

    func collapse(childNumber: Int) {
        if(childNumber != 0){
            childrenCountLabel.text = "+\(childNumber)"
            UIView.animate(withDuration: 0.4, delay: 0.0, options:
                UIViewAnimationOptions.curveEaseOut, animations: {
                    self.childrenCount.alpha = 1
            }, completion: { finished in
            })
        }
        isCollapsed = true
        if (SettingValues.collapseFully) {
            refresh(comment: comment!, submissionAuthor: parent!.submission!.author, text: cellContent!)
        }
    }

    func expandSingle() {
        isCollapsed = false
        refresh(comment: comment!, submissionAuthor: parent!.submission!.author, text: cellContent!)
    }

    func expand() {
        UIView.animate(withDuration: 0.4, delay: 0.0, options:
        UIViewAnimationOptions.curveEaseOut, animations: {
            self.childrenCount.alpha = 0
        }, completion: { finished in
        })
        isCollapsed = false
        if (SettingValues.collapseFully) {
            refresh(comment: comment!, submissionAuthor: parent!.submission!.author, text: cellContent!)
        }
    }

    var oldDepth = 0

    func configureLayout() {
        topViewSpace.horizontalAnchors == contentView.horizontalAnchors
        topViewSpace.topAnchor == contentView.topAnchor
        topViewSpace.heightAnchor == CGFloat(marginTop)
        title.topAnchor == topViewSpace.bottomAnchor + CGFloat(8)
        title.bottomAnchor == menu.topAnchor - CGFloat(8)
        menu.topAnchor == title.bottomAnchor + CGFloat(8)

        title.leftAnchor == sideView.rightAnchor + CGFloat(12)
        title.rightAnchor == contentView.rightAnchor - CGFloat(4)
        
        childrenCount.topAnchor == topViewSpace.bottomAnchor + CGFloat(4)
        childrenCount.rightAnchor == contentView.rightAnchor - CGFloat(4)
        sideView.verticalAnchors == contentView.verticalAnchors
        sideViewSpace.verticalAnchors == contentView.verticalAnchors
        
        menu.horizontalAnchors == contentView.horizontalAnchors
        menu.bottomAnchor == contentView.bottomAnchor
        updateDepth()
        menu.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        title.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
    }
    
    func updateDepth(){
        NSLayoutConstraint.deactivate(sideConstraints)
        sideConstraints = batch {
            sideViewSpace.leftAnchor == contentView.leftAnchor - CGFloat(8)
            sideViewSpace.widthAnchor == CGFloat((SettingValues.wideIndicators ? 8 : 4) * (depth))
            sideView.leftAnchor == sideViewSpace.rightAnchor
            sideView.widthAnchor == CGFloat(sideWidth)
        }
        NSLayoutConstraint.deactivate(menuHeight)
        if(menuShown){
            menuHeight = batch {
                menu.heightAnchor == CGFloat(45)
            }
        } else {
            menuHeight = batch {
                menu.heightAnchor == CGFloat(0)
            }
        }
    }

    var sideWidth: Int = 0
    var marginTop: Int = 0
    var menuHeight : [NSLayoutConstraint] = []

    func setMore(more: RMore, depth: Int) {
        self.depth = depth
        self.comment = nil
        loading = false
        childrenCount.alpha = 0
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        if (depth - 1 > 0) {
            sideWidth = (SettingValues.wideIndicators ? 8 : 4)
            marginTop = 1
            let i22 = depth - 2;
            if (SettingValues.disableColor) {
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.grey100Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.grey200Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.grey300Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.grey400Color()
                } else {
                    sideView.backgroundColor = GMColor.grey500Color()
                }
            } else {
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.blue500Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.green500Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.yellow500Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.orange500Color()
                } else {
                    sideView.backgroundColor = GMColor.red500Color()
                }
            }
        } else {
            marginTop = 8
            sideWidth = 0
        }
        
        if(depth == 1){
            marginTop = 8
        }
        let font = FontGenerator.fontOfSize(size: 14, submission: false)

        var attr = NSMutableAttributedString()
        if (more.children.isEmpty) {
            attr = NSMutableAttributedString(string: "Continue this thread", attributes: [NSFontAttributeName: font])
        } else {
            attr = NSMutableAttributedString(string: "Load \(more.count) more", attributes: [NSFontAttributeName: font])
        }
        let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: .white)
        
        title.setText(attr2)
        updateDepth()
    }

    var numberOfDots = 3
    var loading = false

    func animateMore() {
        loading = true
        let attr = NSMutableAttributedString(string: "Loading...")
        let font = FontGenerator.fontOfSize(size: 16, submission: false)
        let attr2 = NSMutableAttributedString(attributedString: attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: UIColor.blue))

        title.setText(attr2)
        //todo possibly animate?
    }

    public var isCollapsed = false
    var dtap : UIShortTapGestureRecognizer?

    func setComment(comment: RComment, depth: Int, parent: CommentViewController, hiddenCount: Int, date: Double, author: String?, text: NSAttributedString, isCollapsed: Bool, parentOP: String) {
        self.comment = comment
        self.cellContent = text
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        loading = false
        if (self.parent == nil) {
            self.parent = parent
        }

        self.isCollapsed = isCollapsed

        if (date != 0 && date < Double(comment.created.timeIntervalSince1970)) {
            setIsNew(sub: comment.subreddit)
        }
        
        if (hiddenCount > 0) {
            childrenCount.alpha = 1
            childrenCountLabel.text = "+\(hiddenCount)"
        } else {
            childrenCount.alpha = 0
        }

        self.depth = depth
        if (depth - 1 > 0) {
            sideWidth = SettingValues.wideIndicators ? 8 : 4 
            marginTop = 1
            let i22 = depth - 2;
            if (SettingValues.disableColor) {
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.grey100Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.grey200Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.grey300Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.grey400Color()
                } else {
                    sideView.backgroundColor = GMColor.grey500Color()
                }
            } else {
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.blue500Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.green500Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.yellow500Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.orange500Color()
                } else {
                    sideView.backgroundColor = GMColor.red500Color()
                }
            }
            if (SettingValues.highlightOp && parentOP == comment.author) {
                sideView.backgroundColor = GMColor.purple500Color()
            }
        } else {
            marginTop = 8
            sideWidth = 0
        }
        
        if(depth == 1){
            marginTop = 8
        }

        refresh(comment: comment, submissionAuthor: author, text: text)

        if (!registered) {
            parent.registerForPreviewing(with: self, sourceView: title)
            registered = true
        }
        updateDepth()
    }
    
    func doDTap(_ sender: AnyObject){
        switch(SettingValues.commentActionDoubleTap){
        case .UPVOTE:
            self.upvote(self)
            break
        case .DOWNVOTE:
            self.downvote(self)
            break
        case .SAVE:
            self.save()
            break
        case .MENU:
            self.menu(self)
            break
        default:
            break
        }
    }

    var cellContent: NSAttributedString?

    var savedAuthor: String = ""

    func refresh(comment: RComment, submissionAuthor: String?, text: NSAttributedString) {
        var color: UIColor

        savedAuthor = submissionAuthor!

        switch (ActionStates.getVoteDirection(s: comment)) {
        case .down:
            color = ColorUtil.downvoteColor
            break
        case .up:
            color = ColorUtil.upvoteColor
            break
        default:
            color = ColorUtil.fontColor
            break
        }

        let scoreString = NSMutableAttributedString(string: ((comment.scoreHidden ? "[score hidden]" : "\(getScoreText(comment: comment))") + (comment.controversiality > 0 ? "†" : "")), attributes: [NSForegroundColorAttributeName: color])

        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: comment.created, numericDates: true))" + (comment.isEdited ? ("(edit \(DateFormatter().timeSince(from: comment.edited, numericDates: true)))") : ""), attributes: [NSForegroundColorAttributeName: ColorUtil.fontColor])


        let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: comment.author, small: true))\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])
        let authorStringNoFlair = NSMutableAttributedString(string: "\(AccountController.formatUsername(input: comment.author, small: true))\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])

        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(comment.flair)\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(comment.gilded) ", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false)])

        let spacer = NSMutableAttributedString.init(string: "  ")
        let userColor = ColorUtil.getColorForUser(name: comment.author)
        var authorSmall = false
        if (comment.distinguished == "admin") {
          authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#E57373"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (comment.distinguished == "special") {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#F44336"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (comment.distinguished == "moderator") {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#81C784"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (AccountController.currentName == comment.author) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (submissionAuthor != nil && comment.author == submissionAuthor) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#64B5F6"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (userColor != ColorUtil.baseColor) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: userColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else {
            authorSmall = true
        }

        let infoString = NSMutableAttributedString(string: "")
        if(authorSmall){
            infoString.append(authorStringNoFlair)
        } else {
            infoString.append(authorString)
        }

        let tag = ColorUtil.getTagForUser(name: comment.author)
        if (!tag.isEmpty) {
            let tagString = NSMutableAttributedString(string: "\u{00A0}\(tag)\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])
            tagString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor(rgb: 0x2196f3), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: tagString.length))
            infoString.append(spacer)
            infoString.append(tagString)
        }

        infoString.append(NSAttributedString(string: "  •  ", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor]))
        infoString.append(scoreString)
        infoString.append(endString)

        if (!comment.flair.isEmpty) {
            infoString.append(spacer)
            infoString.append(flairTitle)
        }

        if (comment.sticky) {
            infoString.append(spacer)
            infoString.append(pinned)
        }
        if (comment.gilded > 0) {
            infoString.append(spacer)
            let gild = NSMutableAttributedString.init(string: "G", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.amber500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
            infoString.append(gild)
            if (comment.gilded > 1) {
                infoString.append(gilded)
            }
        }
        
        if(parent!.removed.contains(comment.id) || (!comment.removedBy.isEmpty() && !parent!.approved.contains(comment.id))){
            let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: GMColor.red500Color()] as [String: Any]
            infoString.append(spacer)
            if(comment.removedBy == "true"){
                infoString.append(NSMutableAttributedString.init(string: "Removed by Reddit\(!comment.removalReason.isEmpty() ? ":\(comment.removalReason)" : "")", attributes: attrs))
            } else {
                infoString.append(NSMutableAttributedString.init(string: "Removed\(!comment.removedBy.isEmpty() ? " by \(comment.removedBy)":"")\(!comment.removalReason.isEmpty() ? " for \(comment.removalReason)" : "")\(!comment.removalNote.isEmpty() ? " \(comment.removalNote)" : "")", attributes: attrs))
            }
        } else if(parent!.approved.contains(comment.id) || (!comment.approvedBy.isEmpty() && !parent!.removed.contains(comment.id))){
            let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: GMColor.green500Color()] as [String: Any]
            infoString.append(spacer)
            infoString.append(NSMutableAttributedString.init(string: "Approved\(!comment.approvedBy.isEmpty() ? " by \(comment.approvedBy)":"")", attributes: attrs))
        }


        infoString.append(NSAttributedString.init(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 5)]))
        if (!isCollapsed || !SettingValues.collapseFully) {
            infoString.append(text)
        }

        if (!setLinkAttrs) {
            let activeLinkAttributes = NSMutableDictionary(dictionary: title.activeLinkAttributes)
            activeLinkAttributes[NSForegroundColorAttributeName] = ColorUtil.accentColorForSub(sub: comment.subreddit)
            title.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            title.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            setLinkAttrs = true
        }
        title.setText(infoString)

    }

    var setLinkAttrs = false

    func setIsContext() {
        self.contentView.backgroundColor = GMColor.yellow500Color().withAlphaComponent(0.5)
    }

    func setIsNew(sub: String) {
        self.contentView.backgroundColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.getColorForSub(sub: sub).withAlphaComponent(0.25))
    }


    func getScoreText(comment: RComment) -> Int {
        var submissionScore = comment.score
        switch (ActionStates.getVoteDirection(s: comment)) {
        case .up:
            if (comment.likes != .up) {
                if (comment.likes == .down) {
                    submissionScore += 1
                }
                submissionScore += 1
            }
            break
        case .down:
            if (comment.likes != .down) {
                if (comment.likes == .up) {
                    submissionScore -= 1
                }
                submissionScore -= 1
            }
            break
        case .none:
            if (comment.likes == .up && comment.author == AccountController.currentName) {
                submissionScore -= 1
            }
        }
        return submissionScore
    }

    var registered: Bool = false

    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {

        let locationInTextView = title.convert(location, to: title)

        if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
            previewingContext.sourceRect = title.convert(rect, from: title)
            if let controller = parent?.getControllerForUrl(baseUrl: url) {
                return controller
            }
        }

        return nil
    }

    func getInfo(locationInTextView: CGPoint) -> (URL, CGRect)? {
        if let attr = title.link(at: locationInTextView) {
            if let url = attr.result.url {
                return (url, title.bounds)
            }

        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        parent?.show(viewControllerToCommit, sender: parent)
    }

    func longPressed(_ sender: AnyObject?) {
        if self.delegate != nil {
        }
    }

    func pushedSingleTap(_ sender: AnyObject?) {
        if let delegate = self.delegate {
            delegate.pushedSingleTap(self)
        }
    }

    class func margin() -> UIEdgeInsets {
        return UIEdgeInsetsMake(4, 0, 2, 0)
    }
}

extension CommentDepthCell : TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didLongPressLinkWith url: URL!, at point: CGPoint) {
        if parent != nil {
            let sheet = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
            sheet.addAction(
                UIAlertAction(title: "Close", style: .cancel) { (action) in
                    sheet.dismiss(animated: true, completion: nil)
                }
            )
            let open = OpenInChromeController.init()
            if (open.isChromeInstalled()) {
                sheet.addAction(
                    UIAlertAction(title: "Open in Chrome", style: .default) { (action) in
                        _ = open.openInChrome(url, callbackURL: nil, createNewTab: true)
                    }
                )
            }
            sheet.addAction(
                UIAlertAction(title: "Open in Safari", style: .default) { (action) in
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                    sheet.dismiss(animated: true, completion: nil)
                }
            )
            sheet.addAction(
                UIAlertAction(title: "Open", style: .default) { (action) in
                    /* let controller = WebViewController(nibName: nil, bundle: nil)
                     controller.url = url
                     let nav = UINavigationController(rootViewController: controller)
                     self.present(nav, animated: true, completion: nil)*/
                }
            )
            sheet.addAction(
                UIAlertAction(title: "Copy URL", style: .default) { (action) in
                    UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                    sheet.dismiss(animated: true, completion: nil)
                }
            )
            sheet.modalPresentationStyle = .popover
            if let presenter = sheet.popoverPresentationController {
                presenter.sourceView = label
                presenter.sourceRect = label.bounds
            }
            
            parent?.present(sheet, animated: true, completion: nil)
        }
    }
    
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith result: NSTextCheckingResult!) {
        var textClicked = label.attributedText.attributedSubstring(from: result.range).string
        if (textClicked.contains("[[s[")) {
            parent?.showSpoiler(textClicked)
        } else {
            var urlClicked = result.url!
            parent?.doShow(url: urlClicked)
        }
    }
}

extension UIColor {
    func add(overlay: UIColor) -> UIColor {
        var bgR: CGFloat = 0
        var bgG: CGFloat = 0
        var bgB: CGFloat = 0
        var bgA: CGFloat = 0

        var fgR: CGFloat = 0
        var fgG: CGFloat = 0
        var fgB: CGFloat = 0
        var fgA: CGFloat = 0

        self.getRed(&bgR, green: &bgG, blue: &bgB, alpha: &bgA)
        overlay.getRed(&fgR, green: &fgG, blue: &fgB, alpha: &fgA)

        let r = fgA * fgR + (1 - fgA) * bgR
        let g = fgA * fgG + (1 - fgA) * bgG
        let b = fgA * fgB + (1 - fgA) * bgB

        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

//from https://stackoverflow.com/a/48847585/3697225
class UIShortTapGestureRecognizer: UITapGestureRecognizer {
    let tapMaxDelay: Double = 0.3 //anything below 0.3 may cause doubleTap to be inaccessible by many users
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + tapMaxDelay) { [weak self] in
            if self?.state != UIGestureRecognizerState.recognized {
                self?.state = UIGestureRecognizerState.failed
            }
        }
    }
}
