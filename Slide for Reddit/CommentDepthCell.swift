//
//  CommentDepthCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/31/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import RealmSwift
import reddift
import RLBAlertsPickers
import YYText
import UIKit
import SDWebImage
import SDCAlertView

protocol TTTAttributedCellDelegate: class {
    func pushedSingleTap(_ cell: CommentDepthCell)
    func isMenuShown() -> Bool
    func getMenuShown() -> String?
}

protocol ReplyDelegate: class {
    func replySent(comment: Comment?, cell: CommentDepthCell?)
    func updateHeight(textView: UITextView)
    func discard()
    func editSent(cr: Comment?, cell: CommentDepthCell)
}

class CommentDepthCell: MarginedTableViewCell, UIViewControllerPreviewingDelegate, UITextViewDelegate {
    
    var oldConstraints: [NSLayoutConstraint] = []
    var oldLocation: CGPoint = CGPoint.zero
    var oldHeight: CGFloat = -1
    
    /* probably an issue here */
    @objc func textViewDidChange(_ textView: UITextView) {
        let split = textView.text.split("\n").suffix(1)
        if split.first != nil && split.first!.startsWith("* ") && textView.text.endsWith("\n") {
            if split.first == "* " {
                textView.text = textView.text.substring(0, length: textView.text.length - 3) + "\n"
            } else {
                textView.text += "* "
                textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
            }
        } else if split.first != nil && split.first!.startsWith("- ") && textView.text.endsWith("\n") {
            if split.first == "- " {
                textView.text = textView.text.substring(0, length: textView.text.length - 3) + "\n"
            } else {
                textView.text += "- "
                textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
            }
        } else if split.first != nil && split.first!.length > 1 && split.first!.substring(0, length: 1).isNumeric() && split.first!.substring(1, length: 1) == "." && textView.text.endsWith("\n") {
            let num = (Int(split.first!.substring(0, length: 1)) ?? 0) + 1
            if split.first?.length ?? 0 < 4 {
                textView.text = textView.text.substring(0, length: textView.text.length - 4) + "\n"
            } else {
                textView.text += "\(num). "
                textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
            }
        }
        let prevSize = textView.frame.size.height
        let size = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        if oldHeight == size.height {
            return
        }
        oldHeight = size.height
        textView.removeConstraints(oldConstraints)
        oldConstraints = batch {
            if size.height < 40 {
                textView.heightAnchor == 40
            } else {
                textView.heightAnchor == size.height
            }
        }
        
        parent!.reloadHeightsNone()
        if oldLocation != CGPoint.zero {
            var newLocation = oldLocation
            newLocation.y += (size.height - prevSize)
            UIView.performWithoutAnimation {
                parent!.tableView.contentOffset = newLocation
            }
        }
        oldLocation = parent!.tableView.contentOffset
    }
    
    var sideView: UIView!
    var menu: UIStackView!
    var menuBack: UIView!
    var reply: UIView!
    var islink = false
    
    var sideViewSpace: UIView!
    var topViewSpace: UIView!
    var title: YYLabel!
    var commentBody: TextDisplayStackView!

    var currentPath = IndexPath(row: 0, section: 0)
    var longBlocking = false

    var depthColors = [UIColor]()
    
    //Buttons for comment menu
    var upvoteButton: UIButton!
    var downvoteButton: UIButton!
    var replyButton: UIButton!
    var moreButton: UIButton!
    var editButton: UIButton!
    var deleteButton: UIButton!
    var modButton: UIButton!
    var editShown = false
    var archived = false
    var modShown = false
    
    //Buttons for reply
    var body: UITextView?
    var sendB: UIButton!
    var discardB: UIButton!
    var edit = false
    var toolbar: ToolbarTextView?

    var childrenCount: UIView!
    var childrenCountLabel: UILabel!
    var comment: RComment?
    var depth: Int = 0
    
    var content: Object?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureInit()
        
    }
    
    func configureInit() {
        self.isAccessibilityElement = true
        self.backgroundColor = ColorUtil.theme.backgroundColor
        self.commentBody = TextDisplayStackView(fontSize: 16, submission: false, color: .blue,  width: contentView.frame.size.width, delegate: self).then( {
            $0.isUserInteractionEnabled = true
            $0.accessibilityIdentifier = "Comment body"
            $0.ignoreHeight = true
            $0.firstTextView.textContainerInset = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
        })
        
        self.title = YYLabel().then({
            $0.isUserInteractionEnabled = true
            $0.accessibilityIdentifier = "Comment title"
            $0.numberOfLines = 0
            $0.highlightTapAction = self.commentBody.touchLinkAction //todo this!!!
            $0.textContainerInset = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
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
        
        self.contentView.addSubviews(sideView, sideViewSpace, topViewSpace, title, commentBody, childrenCount)
        
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        sideViewSpace.backgroundColor = ColorUtil.theme.backgroundColor
        topViewSpace.backgroundColor = ColorUtil.theme.backgroundColor
        
        self.clipsToBounds = true
        
        self.menu = UIStackView().then {
            $0.accessibilityIdentifier = "Comment menu"
            $0.axis = .horizontal
            $0.alignment = .center
            $0.distribution = .fillEqually
            $0.isHidden = true
        }
        
        menuBack = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        menuBack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        menu.addSubview(menuBack)
        
        self.contentView.addSubview(menu)
        
        self.reply = UIView().then {
            $0.accessibilityIdentifier = "Reply menu"
            $0.isHidden = true
        }
        
        sendB = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 60))
        discardB = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 60))
        
        self.sendB.setTitle("Send", for: .normal)
        self.discardB.setTitle("Cancel", for: .normal)
        
        sendB.addTarget(self, action: #selector(self.send(_:)), for: UIControl.Event.touchUpInside)
        discardB.addTarget(self, action: #selector(self.discard(_:)), for: UIControl.Event.touchUpInside)
        
        sendB.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        discardB.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        
        reply.addSubviews(sendB, discardB)
        
        contentView.addSubview(reply)
        setNeedsLayout()
        layoutIfNeeded()
        configureLayout()

    }
    
    var gesturesAdded = false

    @objc func doLongClick() {
        if parent?.isReply ?? false {
            return
        }
        if longBlocking {
            self.longBlocking = false
            return
        }
        timer!.invalidate()
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionStrong()
        } else if SettingValues.hapticFeedback {
            AudioServicesPlaySystemSound(1519)
        }
        if !self.cancelled {
            if SettingValues.swapLongPress || self.isCollapsed {
                //todo this is probably wrong
                self.pushedSingleTap(nil)
            } else {
                if comment != nil {
                    self.showMenu(nil)
                } else {
                    self.pushedSingleTap(nil)
                }
            }
        }
    }

    var timer: Timer?
    var timerS: Timer?

    var cancelled = false

    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            cancelled = false
            timer = Timer.scheduledTimer(timeInterval: 0.36,
                    target: self,
                    selector: #selector(self.doLongClick),
                    userInfo: nil,
                    repeats: false)
        }
        if sender.state == UIGestureRecognizer.State.ended {
            timer!.invalidate()
            cancelled = true
            longBlocking = false
        }
    }
    
    @objc func doShortClick() {
        timerS?.invalidate()
        if islink {
            islink = false
            return
        }
        if isMore {
            self.pushedSingleTap(nil)
            return
        }
        
        if parent == nil || content == nil {
            return
        }
        
        if !(parent?.isSearching ?? true ) && ((SettingValues.swapLongPress && !isMore) || (self.parent!.isMenuShown() && self.parent!.getMenuShown() == (content as! RComment).getId())) {
            self.showMenu(nil)
        } else {
            self.pushedSingleTap(nil)
        }
    }

    @objc func handleShortPress(_ sender: UIGestureRecognizer) {
        timerS = Timer.scheduledTimer(timeInterval: 0.05,
                                     target: self,
                                     selector: #selector(self.doShortClick),
                                     userInfo: nil,
                                     repeats: false)
    }
    
    var typeImage: UIImageView!
    var previousTranslation: CGFloat = 0
    var previousProgress: Float!
    var dragCancelled = false
    var direction = 0
    
    func isTwoForDirection(left: Bool) -> Bool {
        return !left ? (SettingValues.commentActionLeftLeft != .NONE && SettingValues.commentActionLeftRight != .NONE) : (SettingValues.commentActionRightLeft != .NONE && SettingValues.commentActionRightRight != .NONE)
    }
    
    func getFirstAction(left: Bool) -> SettingValues.CommentAction {
        return !left ? (SettingValues.commentActionLeftLeft != .NONE ? SettingValues.commentActionLeftLeft : SettingValues.commentActionLeftRight) : (SettingValues.commentActionRightRight != .NONE ? SettingValues.commentActionRightRight : SettingValues.commentActionRightLeft) //Setting is for right swipe, left here is right side. So needs to be flipped (!left)
    }
    
    func getSecondAction(left: Bool) -> SettingValues.CommentAction {
        return !left ? (SettingValues.commentActionLeftRight != .NONE ? SettingValues.commentActionLeftRight : SettingValues.commentActionLeftLeft) : (SettingValues.commentActionRightLeft != .NONE ? SettingValues.commentActionRightLeft : SettingValues.commentActionRightRight) //Setting is for right swipe, left here is right side. So needs to be flipped (!left)
    }
    
    var originalPos = CGFloat.zero
    var originalLocation = CGFloat.zero
    var currentProgress = Float(0)
    var diff = CGFloat.zero
    var action = SettingValues.CommentAction.EXIT
    var tiConstraints = [NSLayoutConstraint]()
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began || typeImage == nil {
            dragCancelled = false
            direction = 0
            originalLocation = sender.location(in: contentView).x
            originalPos = self.contentView.frame.origin.x
            diff = self.contentView.frame.width - originalLocation
            typeImage = UIImageView().then {
                $0.accessibilityIdentifier = "Action type"
                $0.layer.cornerRadius = 22.5
                $0.clipsToBounds = true
                $0.contentMode = .center
            }
            previousTranslation = 0
            previousProgress = 0
        }
        
        if self.isMore {
            sender.cancel()
            dragCancelled = true
            return
        }

        if dragCancelled {
            return
        }
        let xVelocity = sender.velocity(in: self).x
        if sender.state != .ended && sender.state != .began && sender.state != .cancelled {
            guard previousProgress != 1 else { return }
            let posx = sender.location(in: self).x
            if direction == -1 && self.contentView.frame.origin.x > originalPos {
                if getFirstAction(left: false) != .NONE {
                    direction = 0
                    diff = self.contentView.frame.width - diff
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
                    diff = self.contentView.frame.width - diff
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
            
            let currentTranslation = direction == -1 ? 0 - (self.contentView.bounds.size.width - posx - diff) : posx - diff
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
    
    @objc func doDTap(_ sender: AnyObject) {
        if isMore {
            return
        }
        parent?.doAction(cell: self, action: SettingValues.commentActionDoubleTap, indexPath: currentPath)
    }
    
    @objc func do3dTouch(_ sender: AnyObject) {
        if isMore {
            return
        }
        parent?.doAction(cell: self, action: SettingValues.commentActionForceTouch, indexPath: currentPath)
    }

    func doAction(item: SettingValues.CommentAction) {
        parent?.doAction(cell: self, action: item, indexPath: currentPath)
    }

    /* ignored
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.view == self.title {
            let link = self.title.link(at: touch.location(in: self.title), withTouch: touch)
            return link == nil
        }
        return true
    }*/

    var long = UILongPressGestureRecognizer.init(target: self, action: nil)

    @objc func showMenu(_ sender: AnyObject?) {
        self.oldLocation = CGPoint.zero
        checkReply { (completed) in
            self.contentView.endEditing(true)
            if completed {
                self.doShowMenu()
            }
        }
    }
    
    func doShowMenu() {
        if let del = self.parent {
            if del.isMenuShown() && del.getMenuShown() == (content as! RComment).getId() {
                hideMenuAnimated()
            } else {
                showMenuAnimated()
            }
        }
    }
    
    var tempConstraints = [NSLayoutConstraint]()
    func hideMenuAnimated() {
        parent!.menuCell = nil
        let oldLocation = parent!.tableView.contentOffset
        parent!.menuId = nil
        self.hideCommentMenu(false)
        var newFrame = self.menu.frame
        newFrame.size.height = 0
        UIView.animate(withDuration: 0.12, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.menu.frame = newFrame
            self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        }, completion: { (_) in
            self.contentView.removeConstraints(self.tempConstraints)
            self.tempConstraints = []
            self.menuHeight.append(self.menu.heightAnchor == CGFloat(0))
            self.menuHeight.append(self.commentBody.bottomAnchor == self.contentView.bottomAnchor - CGFloat(8))
            self.parent!.reloadHeightsNone()
            if oldLocation != CGPoint.zero {
                UIView.performWithoutAnimation {
                    self.parent!.tableView.contentOffset = oldLocation
                }
            }
        })
    }
    
    func showMenuAnimated() {
        if parent == nil {
            return
        }
        if parent!.menuCell != nil {
            parent!.menuCell?.checkReply { (finished) in
                self.contentView.endEditing(true)
                if finished {
                    self.parent!.menuCell!.hideCommentMenu()
                    self.doAnimatedMenu()
                }
            }
        } else {
            doAnimatedMenu()
        }
    }
    
    func doAnimatedMenu() {
        let oldLocation = parent!.tableView.contentOffset
        self.showCommentMenu(false)
        self.parent!.reloadHeightsNone()
        if oldLocation != CGPoint.zero {
            UIView.performWithoutAnimation {
                self.parent!.tableView.contentOffset = oldLocation
            }
        }
        var newFrame = self.menu.frame
        newFrame.size.height = 0
        self.menu.frame = newFrame
        newFrame.size.height += 40
        UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.menu.frame = newFrame
            self.contentView.backgroundColor = ColorUtil.theme.foregroundColor.add(overlay: ColorUtil.getColorForSub(sub: ((self.comment)!.subreddit)).withAlphaComponent(0.25))
        }, completion: { (_) in
        })
        parent!.menuId = comment!.getIdentifier()
    }
    
    func showCommentMenu(_ animate: Bool = true) {
        upvoteButton = UIButton.init(type: .custom).then({
            if ActionStates.getVoteDirection(s: comment!) == .up {
                $0.setImage(UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")?.navIcon(true).getCopy(withColor: ColorUtil.upvoteColor).addImagePadding(x: 15, y: 15), for: .normal)
            } else {
                $0.setImage(UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")?.navIcon(true).addImagePadding(x: 15, y: 15), for: .normal)
            }
            $0.addTarget(self, action: #selector(self.upvote(_:)), for: UIControl.Event.touchUpInside)
        })
        downvoteButton = UIButton.init(type: .custom).then({
            if ActionStates.getVoteDirection(s: comment!) == .down {
                $0.setImage(UIImage(sfString: SFSymbol.arrowDown, overrideString: "downvote")?.navIcon(true).getCopy(withColor: ColorUtil.downvoteColor).addImagePadding(x: 15, y: 15), for: .normal)
            } else {
                $0.setImage(UIImage(sfString: SFSymbol.arrowDown, overrideString: "downvote")?.navIcon(true).addImagePadding(x: 15, y: 15), for: .normal)
            }
            $0.addTarget(self, action: #selector(self.downvote(_:)), for: UIControl.Event.touchUpInside)
        })
        replyButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage(sfString: SFSymbol.arrowshapeTurnUpLeftFill, overrideString: "reply")?.navIcon(true).addImagePadding(x: 15, y: 15), for: .normal)
            $0.addTarget(self, action: #selector(self.reply(_:)), for: UIControl.Event.touchUpInside)
        })
        moreButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage(named: "ic_more_vert_white")?.navIcon(true).addImagePadding(x: 15, y: 15), for: .normal)
            $0.addTarget(self, action: #selector(self.menu(_:)), for: UIControl.Event.touchUpInside)
        })
        editButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage(named: "edit")?.navIcon(true).addImagePadding(x: 15, y: 15), for: .normal)
            $0.addTarget(self, action: #selector(self.edit(_:)), for: UIControl.Event.touchUpInside)
        })
        deleteButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage(named: "delete")?.navIcon(true).addImagePadding(x: 15, y: 15), for: .normal)
            $0.addTarget(self, action: #selector(self.doDelete(_:)), for: UIControl.Event.touchUpInside)
        })
        modButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage(named: "mod")?.navIcon(true).addImagePadding(x: 15, y: 15), for: .normal)
            $0.addTarget(self, action: #selector(self.showModMenu(_:)), for: UIControl.Event.touchUpInside)
        })
        
        let removedSubviews = menu.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            menu.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        removedSubviews.forEach({ $0.removeFromSuperview() })
        
        if UIDevice.current.userInterfaceIdiom == .pad && !UIApplication.shared.isSplitOrSlideOver {
            menu.addArrangedSubviews(flexSpace(), flexSpace(), flexSpace(), editButton, deleteButton, upvoteButton, downvoteButton, replyButton, moreButton, modButton)
        } else {
            menu.addArrangedSubviews(editButton, deleteButton, upvoteButton, downvoteButton, replyButton, moreButton, modButton)
        }
        
        if comment == nil {
            return
        }
        
        if !AccountController.isLoggedIn || comment!.archived || parent!.np || (parent?.offline ?? false) {
            upvoteButton.isHidden = true
            downvoteButton.isHidden = true
            replyButton.isHidden = true
        }
        if !comment!.canMod || (parent?.offline ?? false) {
            modButton.isHidden = true
        }
        if comment!.author != AccountController.currentName || (parent?.offline ?? false) {
            editButton.isHidden = true
            deleteButton.isHidden = true
        }
        parent!.menuCell = self
        menu.isHidden = false
        reply.isHidden = true
        
        if depth != 1 {
            depth = 2
            updateDepth()
        }
        
        NSLayoutConstraint.deactivate(self.menuHeight)
        NSLayoutConstraint.deactivate(self.oldConstraints)
        oldConstraints = []
        self.menuHeight = batch {
            self.menu.heightAnchor <= CGFloat(45)
            self.menu.horizontalAnchors == self.contentView.horizontalAnchors
            self.menu.bottomAnchor == self.contentView.bottomAnchor
            self.menu.topAnchor == self.commentBody.bottomAnchor + CGFloat(8)
            if self.body != nil {
                self.body!.heightAnchor == CGFloat(0)
            }
            self.reply.heightAnchor == CGFloat(0)
        }
        
        if animate {
            self.contentView.backgroundColor = ColorUtil.theme.foregroundColor.add(overlay: ColorUtil.getColorForSub(sub: ((comment)!.subreddit)).withAlphaComponent(0.25))
        }
        menuBack.backgroundColor = ColorUtil.getColorForSub(sub: comment!.subreddit)
    }
    
    func hideCommentMenu(_ doBody: Bool = true) {
        depth = oldDepth
        reply.isHidden = true
        NSLayoutConstraint.deactivate(menuHeight)
        NSLayoutConstraint.deactivate(oldConstraints)
        menu.isHidden = doBody
        if !doBody {
            tempConstraints = batch {
                self.menu.heightAnchor <= CGFloat(45)
                self.menu.horizontalAnchors == self.contentView.horizontalAnchors
                self.menu.topAnchor == self.commentBody.bottomAnchor + CGFloat(8)
            }
        }
        
        oldConstraints = []
        menuHeight = batch {
            if doBody {
                commentBody.bottomAnchor == contentView.bottomAnchor - CGFloat(8)
                menu.heightAnchor == CGFloat(0)
            }
            if body != nil {
                body!.heightAnchor == CGFloat(0)
            }
            reply.heightAnchor == CGFloat(0)
        }
        updateDepth()
        if doBody {
            self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        }
    }

    var parent: CommentViewController?
    
    @objc func upvote(_ s: AnyObject) {
        parent!.vote(comment: comment!, dir: .up)
        self.refresh(comment: comment!, submissionAuthor: (parent!.submission?.author)!, text: self.cellContent!)
        if !menu.isHidden {
            self.hideMenuAnimated()
        }
    }
    
    @objc func discard(_ sender: AnyObject) {
        checkReply { (completed) in
            self.endEditing(true)
            if completed {
                self.parent?.isReply = false
                self.replyDelegate!.discard()
                self.showMenuAnimated()
            }
        }
    }
    
    var alertController: UIAlertController?
    
    func getCommentEdited(_ name: String) {
        DispatchQueue.main.async {
            let session = (UIApplication.shared.delegate as! AppDelegate).session
            do {
                try session?.getInfo([name], completion: { (res) in
                    switch res {
                    case .failure:
                        DispatchQueue.main.async {
                            self.toolbar?.saveDraft(self)
                            self.alertController?.dismiss(animated: false, completion: {
                                let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your message has not been edited (but has been saved as a draft), please try again", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                                self.parent!.present(alert, animated: true, completion: nil)
                            })
                            self.replyDelegate!.editSent(cr: nil, cell: self)
                        }
                    case .success(let listing):
                        if listing.children.count == 1 {
                            if let comment = listing.children[0] as? Comment {
                                DispatchQueue.main.async {
                                    self.alertController?.dismiss(animated: false, completion: {
                                        self.replyDelegate!.editSent(cr: comment, cell: self)
                                    })
                                }
                            }
                        }
                    }
                    
                })
            } catch {
                DispatchQueue.main.async {
                    self.toolbar?.saveDraft(self)
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your message has not been edited (but has been saved as a draft), please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.parent!.present(alert, animated: true, completion: nil)
                    })
                    self.replyDelegate!.editSent(cr: nil, cell: self)
                }
            }

        }
    }
    
    @objc func doEdit(_ sender: AnyObject) {
        alertController = UIAlertController(title: "Editing comment...\n\n\n", message: nil, preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = ColorUtil.theme.fontColor
        spinnerIndicator.startAnimating()
        
        alertController?.view.addSubview(spinnerIndicator)
        parent!.present(alertController!, animated: true, completion: nil)
        
        let session = (UIApplication.shared.delegate as! AppDelegate).session
        
        do {
            let name = comment!.getIdentifier()
            try session?.editCommentOrLink(name, newBody: body!.text!, completion: { (_) in
                self.getCommentEdited(name)
            })
        } catch {
            print((error as NSError).description)
        }
    }
    
    @objc func send(_ sender: AnyObject) {
        self.endEditing(true)
        
        if edit {
            doEdit(sender)
            return
        }
        
        let session = (UIApplication.shared.delegate as! AppDelegate).session
        alertController = UIAlertController(title: "Sending reply...\n\n\n", message: nil, preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = ColorUtil.theme.fontColor
        spinnerIndicator.startAnimating()
        
        alertController?.view.addSubview(spinnerIndicator)
        parent!.present(alertController!, animated: true, completion: nil)
        
        do {
            let name = comment!.getIdentifier()
            try session?.postComment(body!.text!, parentName: name, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        self.toolbar?.saveDraft(self)
                        self.alertController?.dismiss(animated: false, completion: {
                            let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your comment has not been sent (but has been saved as a draft), please try again.\n\nError: \(error.localizedDescription)", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self.parent!.present(alert, animated: true, completion: nil)
                        })
                        self.replyDelegate!.replySent(comment: nil, cell: self)
                    }
                case .success(let postedComment):
                    DispatchQueue.main.async {
                        self.alertController?.dismiss(animated: false, completion: {
                        })
                        self.replyDelegate!.replySent(comment: postedComment, cell: self)
                        self.parent?.isReply = false
                        self.replyDelegate!.discard()
                    }
                }
            })
        } catch {
            DispatchQueue.main.async {
                self.toolbar?.saveDraft(self)
                self.alertController?.dismiss(animated: false, completion: {
                    let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your comment has not been sent (but has been saved as a draft), please try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.parent!.present(alert, animated: true, completion: nil)
                })
                self.replyDelegate!.replySent(comment: nil, cell: self)
            }
        }
    }

    @objc func edit(_ sender: AnyObject) {
        edit = true
        self.reply(sender)
    }
    
    func checkReply(completion: @escaping (Bool) -> Void) {
        if let del = self.parent {
            if del.isReply && !(body?.text.isEmpty() ?? true) {
                let alert = UIAlertController(title: "Discard your comment?", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Save draft", style: .default, handler: { (_) in
                    self.toolbar?.saveDraft(nil)
                    completion(true)
                }))
                alert.addAction(UIAlertAction(title: "Delete draft", style: .destructive, handler: { (_) in
                    completion(true)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    completion(false)
                }))
                del.present(alert, animated: true)
            } else {
                completion(true)
            }
        }
    }
    
    var replyDelegate: ReplyDelegate?
    @objc func reply(_ s: AnyObject) {
        oldLocation = parent!.tableView.contentOffset
        if menu.isHidden {
            showMenu(s)
        }
        if body == nil {
            self.body = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0)).then({
                $0.isEditable = true
                $0.textColor = .white
                $0.backgroundColor = UIColor.white.withAlphaComponent(0.3)
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
            })
            
            self.reply.addSubview(body!)
        }
        
        menu.isHidden = true
        reply.isHidden = false
        parent?.isReply = true

        NSLayoutConstraint.deactivate(menuHeight)
        menuHeight = batch {
            reply.topAnchor == commentBody.bottomAnchor + CGFloat(8)
            reply.bottomAnchor == contentView.bottomAnchor
            reply.horizontalAnchors == contentView.horizontalAnchors
            body!.horizontalAnchors == reply.horizontalAnchors + CGFloat(8)
            body!.topAnchor == reply.topAnchor + CGFloat(8)
            discardB.leftAnchor == reply.leftAnchor + CGFloat(8)
            sendB.rightAnchor == reply.rightAnchor - CGFloat(8)
            discardB.topAnchor == body!.bottomAnchor + CGFloat(8)
            sendB.topAnchor == body!.bottomAnchor + CGFloat(8)
            discardB.bottomAnchor == reply.bottomAnchor - CGFloat(8)
            sendB.bottomAnchor == reply.bottomAnchor - CGFloat(8)
            sendB.heightAnchor == CGFloat(45)
            discardB.heightAnchor == CGFloat(45)
        }
        
        updateDepth()
        
        body!.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        reply.backgroundColor = menuBack.backgroundColor
        
        body!.text = ""
        body!.delegate = self
        self.replyDelegate = parent!

        if edit {
            body!.text = comment!.body.decodeHTML()
        }

        toolbar = ToolbarTextView.init(textView: body!, parent: parent!)
        oldConstraints = batch {
            body!.heightAnchor >= 40
        }
        
        body!.sizeToFitHeight()

        parent!.reloadHeightsNone()
        if oldLocation != CGPoint.zero {
            var newLocation = oldLocation
            newLocation.y += 40
            UIView.performWithoutAnimation {
                body!.becomeFirstResponder()
                parent!.tableView.contentOffset = newLocation
            }
        } else {
            body!.becomeFirstResponder()
        }
    }

    func doMenu() {
        more(parent!)
    }

    @objc func menu(_ s: AnyObject) {
        doMenu()
    }
    
    @objc func downvote(_ s: AnyObject) {
        parent!.vote(comment: comment!, dir: .down)
        self.refresh(comment: comment!, submissionAuthor: (parent!.submission?.author)!, text: self.cellContent!)
        if !menu.isHidden {
            self.hideMenuAnimated()
        }
    }
    
    @objc func save(_ s: AnyObject) {
        parent!.saveComment(self.comment!)
    }
    
    @objc func doDelete(_ s: AnyObject) {
        self.parent!.deleteComment(cell: self)
    }
    
    @objc func showModMenu(_ s: AnyObject) {
        parent!.modMenu(self)
    }
    
    func vote() {
        if content is RComment {
            let current = ActionStates.getVoteDirection(s: comment!)
            let dir = (current == VoteDirection.none) ? VoteDirection.up : VoteDirection.none
            var direction = dir
            switch ActionStates.getVoteDirection(s: comment!) {
            case .up:
                if dir == .up {
                    direction = .none
                }
            case .down:
                if dir == .down {
                    direction = .none
                }
            default:
                break
            }
            do {
                try parent?.session?.setVote(direction, name: (comment!.name), completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                    case .success: break
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
        if content is RComment {
            do {
                try parent?.session?.approve(comment!.id, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Approving comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    case .success:
                        self.parent!.approved.append(self.comment!.id)
                        if self.parent!.removed.contains(self.comment!.id) {
                            self.parent!.removed.remove(at: self.parent!.removed.index(of: self.comment!.id)!)
                        }
                        DispatchQueue.main.async {
                            self.parent!.tableView.reloadData()
                            BannerUtil.makeBanner(text: "Comment approved!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func modDistinguish() {
        if content is RComment {
            do {
                try parent?.session?.distinguish(comment!.id, how: "yes", completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Distinguishing comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    case .success:
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Comment distinguished!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modSticky(sticky: Bool) {
        if content is RComment {
            do {
                try parent?.session?.distinguish(comment!.id, how: "yes", sticky: sticky, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Couldn't \(sticky ? "" : "un-")pin comment!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    case .success:
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Comment \(sticky ? "" : "un-")pinned!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func modRemove(_ spam: Bool = false) {
        if content is RComment {
            do {
                try parent?.session?.remove(comment!.id, spam: spam, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Removing comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    case .success:
                        self.parent!.removed.append(self.comment!.id)
                        if self.parent!.approved.contains(self.comment!.id) {
                            self.parent!.approved.remove(at: self.parent!.approved.index(of: self.comment!.id)!)
                        }
                        DispatchQueue.main.async {
                            self.parent!.tableView.reloadData()
                            BannerUtil.makeBanner(text: "Comment removed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                }
            })
            
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modBan(why: String, duration: Int?) {
        if content is RComment {
            do {
                try parent?.session?.ban(comment!.author, banReason: why, duration: duration == nil ? 999 /*forever*/ : duration!, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Banning user failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    case .success:
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "u/\(self.comment!.author) banned!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    }

                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func more(_ par: CommentViewController) {
        if comment == nil {
            return
        }

        let alertController = DragDownAlertMenu(title: "Comment by u/\(comment!.author)", subtitle: comment!.body, icon: nil)

        alertController.addAction(title: "\(AccountController.formatUsernamePosessive(input: comment!.author, small: false)) profile", icon: UIImage(named: "profile")!.menuIcon()) {
            let prof = ProfileViewController.init(name: self.comment!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: par.navigationController, parentViewController: par)
        }

        alertController.addAction(title: "Share comment permalink", icon: UIImage(named: "link")!.menuIcon()) {
            let activityViewController = UIActivityViewController(activityItems: [URL(string: self.comment!.permalink + "?context=5")], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = self.moreButton
                presenter.sourceRect = self.moreButton.bounds
            }
            par.present(activityViewController, animated: true, completion: {})
        }
        
        if AccountController.isLoggedIn {
            alertController.addAction(title: ActionStates.isSaved(s: comment!) ? "Unsave" : "Save", icon: UIImage(named: "save")!.menuIcon()) {
                par.saveComment(self.comment!)
            }
        }
        
        alertController.addAction(title: "Report comment", icon: UIImage(named: "flag")!.menuIcon()) {
            PostActions.report(self.comment!, parent: par, index: -1, delegate: nil)
        }

        alertController.addAction(title: "Tag u/\(comment!.author)", icon: UIImage(named: "subs")!.menuIcon()) {
            par.tagUser(name: self.comment!.author)
        }
        
        alertController.addAction(title: "Block u/\(comment!.author)", icon: UIImage(named: "hide")!.menuIcon()) {
            par.blockUser(name: self.comment!.author)
        }
        
        alertController.addAction(title: "Copy text", icon: UIImage(named: "copy")!.menuIcon()) {
            let alert = AlertController.init(title: "Copy text", message: nil, preferredStyle: .alert)
            
            alert.setupTheme()
            
            alert.attributedTitle = NSAttributedString(string: "Copy text", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
            
            let text = UITextView().then {
                $0.font = FontGenerator.fontOfSize(size: 14, submission: false)
                $0.textColor = ColorUtil.theme.fontColor
                $0.backgroundColor = .clear
                $0.isEditable = false
                $0.text = self.comment!.body.decodeHTML()
            }
            
            alert.contentView.addSubview(text)
            text.edgeAnchors == alert.contentView.edgeAnchors
            
            let height = text.sizeThatFits(CGSize(width: 238, height: CGFloat.greatestFiniteMagnitude)).height
            text.heightAnchor == height
            
            alert.addCloseButton()
            alert.addAction(AlertAction(title: "Copy all", style: AlertAction.Style.normal, handler: { (_) in
                UIPasteboard.general.string = self.comment!.body.decodeHTML()
            }))
            
            alert.addBlurView()
            par.present(alert, animated: true)
        }
        
        alertController.addAction(title: "Open comment permalink", icon: UIImage(named: "crosspost")!.menuIcon()) {
            VCPresenter.openRedditLink(self.comment!.permalink + "?context=5", par.navigationController, par)
        }
        
        alertController.show(par.parent)
    }

    func mod(_ par: CommentViewController) {
        let alertController = DragDownAlertMenu(title: "Moderation", subtitle: "Comment by u/\(comment!.author)", icon: nil, themeColor: GMColor.lightGreen500Color())

        alertController.addAction(title: "\(comment!.reports.count) reports", icon: UIImage(named: "reports")!.menuIcon()) {
            var reports = ""
            for report in self.comment!.reports {
                reports += report + "\n"
            }
            let alert = UIAlertController(title: "Reports",
                                          message: reports,
                                          preferredStyle: UIAlertController.Style.alert)
            
            let cancelAction = UIAlertAction(title: "OK",
                                             style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            self.parent?.present(alert, animated: true, completion: nil)
        }

        alertController.addAction(title: "Approve", icon: UIImage(named: "approve")!.menuIcon()) {
            self.modApprove()
        }

        alertController.addAction(title: "Ban u/\(comment!.author)", icon: UIImage(named: "ban")!.menuIcon()) {
            //todo add ban!!!
        }

        if comment!.author == AccountController.currentName {
            alertController.addAction(title: "Distinguish your comment", icon: UIImage(named: "save")!.menuIcon()) {
                self.modDistinguish()
            }
        }

        if comment!.author == AccountController.currentName && comment!.depth == 1 {
            if comment!.sticky {
                alertController.addAction(title: "Un-pin comment", icon: UIImage(named: "flag")!.menuIcon()) {
                    self.modSticky(sticky: false)
                }
            } else {
                alertController.addAction(title: "Pin and Distinguish comment", icon: UIImage(named: "flag")!.menuIcon()) {
                    self.modSticky(sticky: true)
                }
            }
        }

        alertController.addAction(title: "Remove comment", icon: UIImage(named: "close")!.menuIcon()) {
            self.modRemove()
        }
        
        alertController.addAction(title: "Remove as Spam", icon: UIImage(named: "flag")!.menuIcon()) {
            self.modRemove(true)
        }
        
        alertController.addAction(title: "u/\(comment!.author)'s profile", icon: UIImage(named: "profile")!.menuIcon()) {
            let prof = ProfileViewController.init(name: self.comment!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: nil, parentViewController: par)
        }

        alertController.show(par.parent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var sideConstraints: [NSLayoutConstraint] = []

    func collapse(childNumber: Int) {
        if childNumber != 0 {
            childrenCountLabel.text = "+\(childNumber)"
            UIView.animate(withDuration: 0.4, delay: 0.0, options:
                UIView.AnimationOptions.curveEaseOut, animations: {
                    self.childrenCount.alpha = 1
            }, completion: { _ in
            })
        }
        isCollapsed = true
        if SettingValues.collapseFully {
            refresh(comment: comment!, submissionAuthor: parent!.submission!.author, text: cellContent!)
        }
    }

    func expandSingle() {
        isCollapsed = false
        refresh(comment: comment!, submissionAuthor: parent!.submission!.author, text: cellContent!)
    }

    func expand() {
        UIView.animate(withDuration: 0.4, delay: 0.0, options:
        UIView.AnimationOptions.curveEaseOut, animations: {
            self.childrenCount.alpha = 0
        }, completion: { _ in
        })
        isCollapsed = false
        if SettingValues.collapseFully {
            refresh(comment: comment!, submissionAuthor: parent!.submission!.author, text: cellContent!)
        }
    }

    var oldDepth = 0

    func configureLayout() {
        
        topViewSpace.horizontalAnchors == contentView.horizontalAnchors
        topViewSpace.topAnchor == contentView.topAnchor
        title.topAnchor == topViewSpace.bottomAnchor + CGFloat(8)

        title.leftAnchor == sideView.rightAnchor + CGFloat(12)
        title.rightAnchor == contentView.rightAnchor - CGFloat(4)
        commentBody.topAnchor == title.bottomAnchor
        commentBody.leftAnchor == sideView.rightAnchor + CGFloat(12)
        commentBody.rightAnchor == contentView.rightAnchor - CGFloat(4)

        childrenCount.topAnchor == topViewSpace.bottomAnchor + CGFloat(4)
        childrenCount.rightAnchor == contentView.rightAnchor - CGFloat(4)
        sideView.verticalAnchors == contentView.verticalAnchors
        sideViewSpace.verticalAnchors == contentView.verticalAnchors
        
        updateDepth()
        menu.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        title.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        commentBody.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        reply.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
    }
    
    func updateDepth() {
        NSLayoutConstraint.deactivate(sideConstraints)
        sideConstraints = batch {
            sideViewSpace.leftAnchor == contentView.leftAnchor - CGFloat(8)
            sideViewSpace.widthAnchor == CGFloat((SettingValues.wideIndicators ? 8 : 4) * (depth))
            sideView.leftAnchor == sideViewSpace.rightAnchor
            sideView.widthAnchor == CGFloat(sideWidth)
        }
    }

    var sideWidth: Int = 0
    var marginTop: Int = 0
    var menuHeight: [NSLayoutConstraint] = []
    var topMargin: [NSLayoutConstraint] = []
    var isMore = false
    let force = ForceTouchGestureRecognizer()

    func connectGestures() {
        if !gesturesAdded {
            gesturesAdded = true
            if dtap == nil && SettingValues.commentActionDoubleTap != .NONE {
                dtap = UIShortTapGestureRecognizer.init(target: self, action: #selector(self.doDTap(_:)))
                dtap!.numberOfTapsRequired = 2
                self.contentView.addGestureRecognizer(dtap!)
            }
            
            let tapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(self.handleShortPress(_:)))
            tapGestureRecognizer.cancelsTouchesInView = false
            tapGestureRecognizer.delegate = self
            if dtap != nil {
                tapGestureRecognizer.require(toFail: dtap!)
            }
            self.title.addGestureRecognizer(tapGestureRecognizer)
            
            let tapGestureRecognizer2 = UITapGestureRecognizer.init(target: self, action: #selector(self.handleShortPress(_:)))
            tapGestureRecognizer2.cancelsTouchesInView = false
            tapGestureRecognizer2.delegate = self
            if dtap != nil {
                tapGestureRecognizer2.require(toFail: dtap!)
            }
            self.commentBody.addGestureRecognizer(tapGestureRecognizer2)

            long = UILongPressGestureRecognizer.init(target: self, action: #selector(self.handleLongPress(_:)))
            long.minimumPressDuration = 0.36
            long.delegate = self
            long.cancelsTouchesInView = false
            commentBody.parentLongPress = long
            self.addGestureRecognizer(long)
            
            if SettingValues.commentActionForceTouch != .PARENT_PREVIEW && SettingValues.commentActionForceTouch != .NONE {
                force.addTarget(self, action: #selector(self.do3dTouch(_:)))
                force.cancelsTouchesInView = false
                self.contentView.addGestureRecognizer(force)
            }
        }
    }

    func setMore(more: RMore, depth: Int, depthColors: [UIColor], parent: CommentViewController) {
        if title == nil {
            configureInit()
        }
        self.depth = depth
        self.comment = nil
        self.isMore = true
        self.depthColors = depthColors
        
        if self.parent == nil {
            self.parent = parent
        }
        
        loading = false
        childrenCount.alpha = 0
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        if depth - 1 > 0 {
            sideWidth = (SettingValues.wideIndicators ? 8 : 4)
            marginTop = 1
            let i22 = depth - 2
            if i22 % 5 == 0 {
                sideView.backgroundColor = depthColors.safeGet(0) ?? GMColor.blue500Color()
            } else if i22 % 4 == 0 {
                sideView.backgroundColor = depthColors.safeGet(1) ?? GMColor.green500Color()
            } else if i22 % 3 == 0 {
                sideView.backgroundColor = depthColors.safeGet(2) ?? GMColor.yellow500Color()
            } else if i22 % 2 == 0 {
                sideView.backgroundColor = depthColors.safeGet(3) ?? GMColor.orange500Color()
            } else {
                sideView.backgroundColor = depthColors.safeGet(4) ?? GMColor.red500Color()
            }
        } else {
            marginTop = 8
            sideWidth = 0
        }
        
        if depth == 1 {
            marginTop = 8
        }
        
        if !commentBody.ignoreHeight {
            marginTop = 0
        }
        
        var attr = NSAttributedString()
        if more.children.isEmpty {
            attr = TextDisplayStackView.createAttributedChunk(baseHTML: "<p>Continue thread</p>", fontSize: 16, submission: false, accentColor: .white, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
        } else {
            attr = TextDisplayStackView.createAttributedChunk(baseHTML: "<p>Load \(more.count) more</p>", fontSize: 16, submission: false, accentColor: .white, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
        }
        
        title.attributedText = attr
        commentBody.clearOverflow()
        commentBody.firstTextView.isHidden = true
        NSLayoutConstraint.deactivate(menuHeight)
        NSLayoutConstraint.deactivate(oldConstraints)
        oldConstraints = []
        menuHeight = batch {
            commentBody.bottomAnchor == contentView.bottomAnchor - CGFloat(8)
            menu.heightAnchor == CGFloat(0)
            if body != nil {
                body!.heightAnchor == CGFloat(0)
            }
            reply.heightAnchor == CGFloat(0)
        }
        updateDepth()
        NSLayoutConstraint.deactivate(topMargin)
        topMargin = batch {
            topViewSpace.heightAnchor == CGFloat(marginTop)
        }
        
        connectGestures()
    }

    var numberOfDots = 3
    var loading = false

    func animateMore() {
        loading = true
        
        title.attributedText = TextDisplayStackView.createAttributedChunk(baseHTML: "Loading...", fontSize: 16, submission: false, accentColor: .white, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
        //todo possibly animate?
    }

    public var isCollapsed = false
    var dtap: UIShortTapGestureRecognizer?

    func setComment(comment: RComment, depth: Int, parent: CommentViewController, hiddenCount: Int, date: Double, author: String?, text: NSAttributedString, isCollapsed: Bool, parentOP: String, depthColors: [UIColor], indexPath: IndexPath, width: CGFloat) {
        if title == nil {
            configureInit()
        }
        if SettingValues.commentActionForceTouch == .NONE { //todo change this
        }
        self.accessibilityValue = """
        Depth \(comment.depth).
        "\(text.string)"
        Comment by user \(comment.author). Score is \(comment.scoreHidden ? "hidden" : "\(comment.score)")
        """

        self.comment = comment
        self.cellContent = text
        self.isMore = false
        
        self.currentPath = indexPath
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        loading = false
        if self.parent == nil {
            self.parent = parent
        }

        connectGestures()
        
        self.isCollapsed = isCollapsed
        self.depthColors = depthColors

        if hiddenCount > 0 {
            childrenCount.alpha = 1
            childrenCountLabel.text = "+\(hiddenCount)"
        } else {
            childrenCount.alpha = 0
        }

        self.depth = depth
        self.oldDepth = depth
        if depth - 1 > 0 {
            sideWidth = SettingValues.wideIndicators ? 8 : 4 
            marginTop = 1
            let i22 = depth - 2
            if i22 % 5 == 0 {
                sideView.backgroundColor = depthColors.safeGet(0) ?? GMColor.blue500Color()
            } else if i22 % 4 == 0 {
                sideView.backgroundColor = depthColors.safeGet(1) ?? GMColor.green500Color()
            } else if i22 % 3 == 0 {
                sideView.backgroundColor = depthColors.safeGet(2) ?? GMColor.yellow500Color()
            } else if i22 % 2 == 0 {
                sideView.backgroundColor = depthColors.safeGet(3) ?? GMColor.orange500Color()
            } else {
                sideView.backgroundColor = depthColors.safeGet(4) ?? GMColor.red500Color()
            }
            if SettingValues.highlightOp && parentOP == comment.author {
                sideView.backgroundColor = GMColor.purple500Color()
            }
        } else {
            marginTop = 8
            sideWidth = 0
        }
        
        if commentBody.ignoreHeight {            
            commentBody.estimatedWidth = width - CGFloat(12) - CGFloat(sideWidth) - CGFloat((SettingValues.wideIndicators ? 8 : 4) * (depth - 1))
            title.preferredMaxLayoutWidth = commentBody.estimatedWidth
        }

        if depth == 1 {
            marginTop = 8
        }
        
        if !commentBody.ignoreHeight {
            marginTop = 0
            self.depth = 0
            sideWidth = 8
            sideView.backgroundColor = ColorUtil.theme.foregroundColor
        }

        refresh(comment: comment, submissionAuthor: author, text: text, date)

        if !registered {
            parent.registerForPreviewing(with: self, sourceView: title)
            registered = true
        }
        if parent.getMenuShown() ?? "" == comment.getIdentifier() {
            showCommentMenu()
        } else {
            hideCommentMenu()
        }

        NSLayoutConstraint.deactivate(topMargin)
        topMargin = batch {
            topViewSpace.heightAnchor == CGFloat(marginTop)
        }
    }
    
    var cellContent: NSAttributedString?

    var savedAuthor: String = ""

    func refresh(comment: RComment, submissionAuthor: String?, text: NSAttributedString, _ date: Double = 0) {
        var color: UIColor
        
        savedAuthor = submissionAuthor!

        switch ActionStates.getVoteDirection(s: comment) {
        case .down:
            color = ColorUtil.downvoteColor
        case .up:
            color = ColorUtil.upvoteColor
        default:
            color = ColorUtil.theme.fontColor
        }
        
        let boldFont = FontGenerator.boldFontOfSize(size: 14, submission: false)

        let scoreString = NSMutableAttributedString(string: (comment.scoreHidden ? "[score hidden]" : "\(getScoreText(comment: comment))"), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): color, convertFromNSAttributedStringKey(NSAttributedString.Key.font): boldFont]))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2.75
        
        let spacerString = NSMutableAttributedString(string: (comment.controversiality > 0 ? "†  •  " : "  •  "), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): boldFont]))
        let new = date != 0 && date < Double(comment.created.timeIntervalSince1970)
        let endString = NSMutableAttributedString(string: "\(new ? " " : "")\(DateFormatter().timeSince(from: comment.created, numericDates: true))" + (comment.isEdited ? ("(edit \(DateFormatter().timeSince(from: comment.edited, numericDates: true)))") : ""), attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): boldFont]))
        
        if new {
            endString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: ColorUtil.accentColorForSub(sub: comment.subreddit), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange(location: 0, length: endString.length))
        }

        let authorString = NSMutableAttributedString(string: "\u{00A0}\u{00A0}\(AccountController.formatUsername(input: comment.author, small: true))\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): boldFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor, convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyle]))
        authorString.yy_setTextHighlight(NSRange(location: 0, length: authorString.length), color: nil, backgroundColor: nil, userInfo: ["url": URL(string: "/u/\(comment.author)")])
        let authorStringNoFlair = NSMutableAttributedString(string: "\(AccountController.formatUsername(input: comment.author, small: true))\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): boldFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): parent?.authorColor ?? ColorUtil.theme.fontColor, convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyle]))
        authorStringNoFlair.yy_setTextHighlight(NSRange(location: 0, length: authorStringNoFlair.length), color: nil, backgroundColor: nil, userInfo: ["url": URL(string: "/u/\(comment.author)")])

        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(comment.flair)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: ColorUtil.theme.backgroundColor, cornerRadius: 3), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: GMColor.green500Color(), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white])

        let spacer = NSMutableAttributedString.init(string: "  ")
        let userColor = ColorUtil.getColorForUser(name: comment.author)
        var authorSmall = false
        if comment.distinguished == "admin" {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: UIColor.init(hexString: "#E57373"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if comment.distinguished == "special" {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: UIColor.init(hexString: "#F44336"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if comment.distinguished == "moderator" {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: UIColor.init(hexString: "#81C784"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if AccountController.currentName == comment.author {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: UIColor.init(hexString: "#FFB74D"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if userColor != ColorUtil.baseColor {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: userColor, cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if submissionAuthor != nil && comment.author == submissionAuthor {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: UIColor.init(hexString: "#64B5F6"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else {
            authorSmall = true
        }

        paragraphStyle.lineSpacing = 0.5
        let infoString = NSMutableAttributedString(string: "")
        if authorSmall {
            infoString.append(authorStringNoFlair)
        } else {
            infoString.append(authorString)
        }

        let tag = ColorUtil.getTagForUser(name: comment.author)
        if tag != nil {
            let tagString = NSMutableAttributedString.init(string: "\u{00A0}\(tag!)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: UIColor(rgb: 0x2196f3), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white])
            infoString.append(spacer)
            infoString.append(tagString)
        }

        infoString.append(NSAttributedString(string: "  •  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): boldFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor])))
        infoString.append(scoreString)
        infoString.append(spacerString)
        infoString.append(endString)

        if !comment.urlFlair.isEmpty {
            infoString.append(spacer)
            let flairView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            flairView.sd_setImage(with: URL(string: comment.urlFlair), completed: nil)
            let flairImage = NSMutableAttributedString.yy_attachmentString(withContent: flairView, contentMode: UIView.ContentMode.center, attachmentSize: CGSize.square(size: 20), alignTo: boldFont, alignment: YYTextVerticalAlignment.center)

            infoString.append(flairImage)
        }
        
        if !comment.flair.isEmpty {
            infoString.append(spacer)
            infoString.append(flairTitle)
        }

        if comment.sticky {
            infoString.append(spacer)
            infoString.append(pinned)
        }
        
        if comment.gilded {
            infoString.append(spacer)
            if comment.platinum > 0 {
                infoString.append(spacer)
                let gild = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: "platinum")!, fontSize: boldFont.pointSize)!
                infoString.append(gild)
                if comment.platinum > 1 {
                    let platinumed = NSMutableAttributedString.init(string: "\u{00A0}x\(comment.platinum) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor]))
                    infoString.append(platinumed)
                }
            }
            if comment.gold > 0 {
                infoString.append(spacer)
                let gild = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: "gold")!, fontSize: boldFont.pointSize)!
                infoString.append(gild)
                if comment.gold > 1 {
                    let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(comment.gold) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor]))
                    infoString.append(gilded)
                }
            }
            if comment.silver > 0 {
                infoString.append(spacer)
                let gild = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: "silver")!, fontSize: boldFont.pointSize)!
                infoString.append(gild)
                if comment.silver > 1 {
                    let silvered = NSMutableAttributedString.init(string: "\u{00A0}x\(comment.silver) ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor]))
                    infoString.append(silvered)
                }
            }
        }

        if comment.cakeday {
            infoString.append(spacer)
            let gild = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: "cakeday")!, fontSize: boldFont.pointSize)!
            infoString.append(gild)
        }

        if parent!.removed.contains(comment.id) || (!comment.removedBy.isEmpty() && !parent!.approved.contains(comment.id)) {
            let attrs = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): GMColor.red500Color()] as [String: Any]
            infoString.append(spacer)
            if comment.removedBy == "true" {
                infoString.append(NSMutableAttributedString.init(string: "Removed by Reddit\(!comment.removalReason.isEmpty() ? ":\(comment.removalReason)" : "")", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs)))
            } else {
                infoString.append(NSMutableAttributedString.init(string: "Removed\(!comment.removedBy.isEmpty() ? " by \(comment.removedBy)":"")\(!comment.removalReason.isEmpty() ? " for \(comment.removalReason)" : "")\(!comment.removalNote.isEmpty() ? " \(comment.removalNote)" : "")", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs)))
            }
        } else if parent!.approved.contains(comment.id) || (!comment.approvedBy.isEmpty() && !parent!.removed.contains(comment.id)) {
            let attrs = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): GMColor.green500Color()] as [String: Any]
            infoString.append(spacer)
            infoString.append(NSMutableAttributedString.init(string: "Approved\(!comment.approvedBy.isEmpty() ? " by \(comment.approvedBy)":"")", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs)))
        }
        
        paragraphStyle.lineSpacing = 1.5
        infoString.yy_paragraphStyle = paragraphStyle

        commentBody.tColor = ColorUtil.accentColorForSub(sub: comment.subreddit)
        if !isCollapsed || !SettingValues.collapseFully {
            title.attributedText = infoString
            commentBody.firstTextView.isHidden = false
            commentBody.clearOverflow()
            commentBody.setTextWithTitleHTML(NSMutableAttributedString(), text, htmlString: comment.htmlText)
        } else {
            title.attributedText = infoString
            commentBody.clearOverflow()
            commentBody.firstTextView.isHidden = true
        }

        refreshAccessibility()
    }

    var setLinkAttrs = false

    func setIsContext() {
        self.contentView.backgroundColor = GMColor.yellow500Color().withAlphaComponent(0.5)
    }

    func setIsNew(sub: String) {
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor.add(overlay: ColorUtil.getColorForSub(sub: sub).withAlphaComponent(0.25))
    }

    func getScoreText(comment: RComment) -> Int {
        var submissionScore = comment.score
        switch ActionStates.getVoteDirection(s: comment) {
        case .up:
            if comment.likes != .up {
                if comment.likes == .down {
                    submissionScore += 1
                }
                submissionScore += 1
            }
        case .down:
            if comment.likes != .down {
                if comment.likes == .up {
                    submissionScore -= 1
                }
                submissionScore -= 1
            }
        case .none:
            if comment.likes == .up && comment.author == AccountController.currentName {
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
        return nil
        /* todo this
        if let attr = title.firstTextView.link(at: locationInTextView) {
            if let url = attr.result.url {
                return (url, title.bounds)
            }

        }
        return nil*/
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if viewControllerToCommit is AlbumViewController {
            viewControllerToCommit.modalPresentationStyle = .overFullScreen
            parent?.present(viewControllerToCommit, animated: true, completion: nil)
        } else if viewControllerToCommit is ModalMediaViewController || viewControllerToCommit is AnyModalViewController {
            viewControllerToCommit.modalPresentationStyle = .overFullScreen
            parent?.present(viewControllerToCommit, animated: true, completion: nil)
        } else {
            VCPresenter.showVC(viewController: viewControllerToCommit, popupIfPossible: true, parentNavigationController: parent?.navigationController, parentViewController: parent)
        }
    }

    func longPressed(_ sender: AnyObject?) {
        if self.parent != nil {
        }
    }

    @objc func pushedSingleTap(_ sender: AnyObject?) {
        checkReply { (completed) in
            self.contentView.endEditing(true)
            if completed {
                self.parent?.pushedSingleTap(self)
            }
        }
    }

    class func margin() -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 0, bottom: 2, right: 0)
    }
}

extension CommentDepthCell: TextDisplayStackViewDelegate {
    func linkTapped(url: URL, text: String) {
        islink = true
        if !text.isEmpty {
            self.parent?.showSpoiler(text)
        } else {
            self.parent?.doShow(url: url, heroView: nil, heroVC: nil)
        }
    }

    func linkLongTapped(url: URL) {
        longBlocking = true
        
        let alertController = DragDownAlertMenu(title: "Link options", subtitle: url.absoluteString, icon: url.absoluteString)
        
        alertController.addAction(title: "Share URL", icon: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")!.menuIcon()) {
            let shareItems: Array = [url]
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.contentView
            self.parent?.present(activityViewController, animated: true, completion: nil)
        }
        
        alertController.addAction(title: "Copy URL", icon: UIImage(named: "copy")!.menuIcon()) {
            UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
            BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self.parent)
        }
        
        alertController.addAction(title: "Open in default app", icon: UIImage(named: "nav")!.menuIcon()) {
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
        
        alertController.show(parent)
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
            if self?.state != UIGestureRecognizer.State.recognized {
                self?.state = UIGestureRecognizer.State.failed
            }
        }
    }
}

/*class ForceNavView: TapBehindModalViewController, ForceTouchGestureDelegate {
    func touchStarted() {
        
    }
    
    func touchCancelled() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func pop() {
        
    }
}

extension CommentDepthCell: ForceTouchGestureDelegate {
    func touchStarted() {
        parentPresentedTextView = TextDisplayStackView(fontSize: 12, submission: false, color: ColorUtil.theme.fontColor, delegate: self, width: UIScreen.main.bounds.size.width * 0.8)
        parentPresentedTextView?.setTextWithTitleHTML(NSAttributedString(string: "asdfasdf"), htmlString: "<b>ASDFSDF</b> not bold")
        let alert = UIViewController()
        alert.view.addSubview(parentPresentedTextView!)
        alert.view.backgroundColor = ColorUtil.theme.foregroundColor
        alert.view.roundCorners(UIRectCorner.allCorners, radius: 20)
        alert.view.addGestureRecognizer(force)
        alert.preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width * 0.8, height: UIScreen.main.bounds.size.height * 0.8)
        let nav = ForceNavView.init(rootViewController: alert)
        nav.setNavigationBarHidden(true, animated: false)
        nav.modalPresentationStyle = UIModalPresentationStyle.popover
        force.forceDelegate = nav
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = parent!.view
        popover?.sourceRect = CGRect(x: parent!.view.center.x, y: parent!.view.center.y, width: 0, height: 0)
        popover?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        presentedVC = nav
        parent?.present(nav, animated: true, completion: nil)
    }
    
    func touchCancelled() {
        presentedVC?.dismiss(animated: true, completion: nil)
    }
    
    func pop() {
        print("Popped")
    }
}
*/

// MARK: - Accessibility
extension CommentDepthCell {
    override func accessibilityActivate() -> Bool {
        doMenu()
        return true
    }

    private func refreshAccessibility() {
        guard let comment = comment, let parent = parent, let submission = parent.submission else {
            print("Could not refresh accessibility for this cell!")
            return
        }

        let actionManager = CommentActionsManager(comment: comment, submission: submission)

        var actions: [UIAccessibilityCustomAction] = []

        if actionManager.isVotingPossible {
            var downvoteActionString = "Downvote"
            var upvoteActionString = "Upvote"

            switch ActionStates.getVoteDirection(s: comment) {
            case .up:
                upvoteActionString = "Remove Upvote"
            case .down:
                downvoteActionString = "Remove Downvote"
            case .none:
                break
            }

            actions.append(UIAccessibilityCustomAction(
                name: upvoteActionString,
                target: self,
                selector: #selector(upvote))
            )

            actions.append(UIAccessibilityCustomAction(
                name: downvoteActionString,
                target: self,
                selector: #selector(downvote))
            )
        }

        if actionManager.isSavePossible {
            let isSaved = ActionStates.isSaved(s: comment)
            actions.append(UIAccessibilityCustomAction(
                name: isSaved ? "Unsave" : "Save",
                target: self, selector:
                #selector(self.save(_:)))
            )
        }

        if actionManager.isReplyPossible {
            actions.append(UIAccessibilityCustomAction(
                name: "Reply",
                target: self,
                selector: #selector(self.reply(_:)))
            )
        }

        if actionManager.isEditPossible {
            actions.append(UIAccessibilityCustomAction(
                name: "Edit",
                target: self,
                selector: #selector(self.edit(_:)))
            )
        }

        if actionManager.isDeletePossible {
            actions.append(UIAccessibilityCustomAction(
                name: "Delete",
                target: self,
                selector: #selector(self.doDelete(_:)))
            )
        }

        if actionManager.isModPossible {
            actions.append(UIAccessibilityCustomAction(
                name: "Moderate",
                target: self,
                selector: #selector(self.showModMenu(_:)))
            )
        }

        actions.append(UIAccessibilityCustomAction(
            name: "Additional options",
            target: self,
            selector: #selector(menu(_:)))
        )

        self.accessibilityCustomActions = actions

    }
}

extension CommentDepthCell: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection)
        -> UIModalPresentationStyle {
            return .none
    }
}

class CommentActionsManager {
    var submission: RSubmission
    var comment: RComment

    private lazy var networkActionsArePossible: Bool = {
        return AccountController.isLoggedIn && LinkCellView.checkInternet()
    }()

    var isOwnComment: Bool {
        return AccountController.currentName == comment.author
    }

    var isVotingPossible: Bool {
        return networkActionsArePossible && !submission.archived
    }

    var isSavePossible: Bool {
        return networkActionsArePossible
    }

    var isEditPossible: Bool {
        return networkActionsArePossible && isOwnComment
    }

    var isDeletePossible: Bool {
        return networkActionsArePossible && isOwnComment
    }

    var isReplyPossible: Bool {
        return networkActionsArePossible && !submission.archived
    }

    var isModPossible: Bool {
        return networkActionsArePossible && submission.canMod
    }

    init(comment: RComment, submission: RSubmission) {
        self.comment = comment
        self.submission = submission
    }
}

extension UITextView {
    func sizeToFitHeight() {
        let size: CGSize = self.sizeThatFits(CGSize.init(width: self.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        var frame: CGRect = self.frame
        frame.size.height = size.height
        self.frame = frame
    }
}

extension Array {
    public func safeGet(_ index: Int) -> Element? {
        if index >= self.count {
            return nil
        }
        return self[index]
    }
    
    public func backwards() -> [Element] {
        var newArray = [Element]()
        for i in 0...self.count - 1 {
            newArray.append(self[self.count - i - 1])
        }
        return newArray
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}
