//
//  CommentDepthCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/31/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import CoreData
import reddift
import RLBAlertsPickers
import SDCAlertView
import SDWebImage
import UIKit

protocol TTTAttributedCellDelegate: class {
    func pushedSingleTap(_ cell: CommentDepthCell)
    func isMenuShown() -> Bool
    func getMenuShown() -> String?
}

protocol ReplyDelegate: class {
    func replySent(comment: Comment?, cell: CommentDepthCell?)
    func updateHeight(textView: UITextView)
    func discard()
    func textChanged(_ string: String)
    func editSent(cr: Comment?, cell: CommentDepthCell)
}

class CommentDepthCell: MarginedTableViewCell, UIViewControllerPreviewingDelegate, UITextViewDelegate {
    
    var oldConstraints: [NSLayoutConstraint] = []
    var oldLocation: CGPoint = CGPoint.zero
    var oldHeight: CGFloat = -1
    weak var previewedVC: UIViewController?
    var previewedURL: URL?
    var lastLength = 0
    var loader: UIActivityIndicatorView?
    weak var profilePresentationManager: ProfileInfoPresentationManager?
    var chosenAccount: String?

    @objc func textViewDidChange(_ textView: UITextView) {
        replyDelegate?.textChanged(textView.text)
        let split = textView.text.split("\n").suffix(1)
        if split.first != nil && split.first!.startsWith("* ") && textView.text.endsWith("\n") {
            if split.first == "* " {
                textView.text = textView.text.substring(0, length: textView.text.length - 3) + "\n"
            } else if lastLength < textView.text.length {
                textView.text += "* "
                textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
            }
        } else if split.first != nil && split.first!.startsWith("- ") && textView.text.endsWith("\n") {
            if split.first == "- " {
                textView.text = textView.text.substring(0, length: textView.text.length - 3) + "\n"
            } else if lastLength < textView.text.length {
                textView.text += "- "
                textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
            }
        } else if split.first != nil && split.first!.length > 1 && split.first!.substring(0, length: 1).isNumeric() && split.first!.substring(1, length: 1) == "." && textView.text.endsWith("\n") {
            let num = (Int(split.first!.substring(0, length: 1)) ?? 0) + 1
            if split.first?.length ?? 0 < 4 {
                textView.text = textView.text.substring(0, length: textView.text.length - 4) + "\n"
            } else if lastLength < textView.text.length {
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
                textView.heightAnchor /==/ 40
            } else {
                textView.heightAnchor /==/ size.height
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
        lastLength = textView.text.length
    }
    
    var sideView: UIView!
    var menu: UIStackView!
    var menuBack: UIView!
    var reply: UIView!
    var islink = false
    
    var sideViewSpace: UIView!
    var topViewSpace: UIView!
    var title: TitleUITextView!
    var commentBody: TextDisplayStackView!

    var currentPath = IndexPath(row: 0, section: 0)
    var longBlocking = false

    var depthColors = [UIColor]()
    var force: ForceTouchGestureRecognizer?

    //Buttons for comment menu
    var upvoteButton: UIButton!
    var downvoteButton: UIButton!
    var replyButton: UIButton!
    var moreButton: UIButton!
    var editButton: UIButton!
    var deleteButton: UIButton!
    var modButton: UIButton!
    var specialButton: UIImageView!
    var editShown = false
    var archived = false
    var modShown = false
    
    //Buttons for reply
    var body: UITextView?
    var sendB: UIButton!
    var usernameB: UIButton?
    var discardB: UIButton!
    var edit = false
    var toolbar: ToolbarTextView?

    var childrenCount: UIView!
    var childrenCountLabel: UILabel!
    var comment: CommentObject?
    var depth: Int = 0
    
    var content: RedditObject?
    
    //Can't have parameters that target an iOS version :/
    private var _savedPreview: Any?
    @available(iOS 13.0, *)
    fileprivate var savedPreview: UITargetedPreview? {
        get {
            return _savedPreview as? UITargetedPreview
        }
        set {
            self._savedPreview = newValue
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureInit()
    }
    
    func configureInit() {
        self.isAccessibilityElement = true
        self.backgroundColor = UIColor.backgroundColor
        self.commentBody = TextDisplayStackView(fontSize: 16, submission: false, color: .blue, width: contentView.frame.size.width, delegate: self).then({
            $0.isUserInteractionEnabled = true
            $0.accessibilityIdentifier = "Comment body"
            $0.ignoreHeight = true
            $0.firstTextView.textContainerInset = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
        })
        
        let layout = BadgeLayoutManager()
        let storage = NSTextStorage()
        storage.addLayoutManager(layout)
        let initialSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        let container = NSTextContainer(size: initialSize)
        container.widthTracksTextView = true
        layout.addTextContainer(container)

        self.title = TitleUITextView(delegate: self, textContainer: container).then({
            $0.accessibilityIdentifier = "Comment title"
            $0.doSetup()
        })
        
        self.childrenCountLabel = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 15)).then({
            $0.numberOfLines = 1
            $0.font = FontGenerator.boldFontOfSize(size: 12, submission: false)
            $0.textColor = UIColor.white
            $0.layer.shadowOffset = CGSize(width: 0, height: 0)
            $0.layer.shadowOpacity = 0.4
            $0.layer.shadowRadius = 4
        })
        
        self.specialButton = UIImageView.init().then({
            $0.isUserInteractionEnabled = true
            $0.alpha = 0.5
            $0.isHidden = true
            $0.image = UIImage(sfString: SFSymbol.circleFill, overrideString: "circle")?.getCopy(withSize: CGSize(width: 20, height: 20), withColor: UIColor.fontColor).addImagePadding(x: 15, y: 15)
            //$0.addTarget(self, action: #selector(self.specialAction(_:)), for: UIControl.Event.touchUpInside)
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
        
        self.contentView.addSubviews(sideView, sideViewSpace, topViewSpace, title, commentBody, childrenCount, specialButton)
        
        self.contentView.backgroundColor = UIColor.foregroundColor

        sideViewSpace.backgroundColor = UIColor.backgroundColor
        topViewSpace.backgroundColor = UIColor.backgroundColor
        
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
        usernameB = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 60))
        discardB = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 60))
        
        sendB.setTitleColor(UIColor.fontColor, for: .normal)
        usernameB?.setTitleColor(UIColor.fontColor, for: .normal)
        discardB.setTitleColor(UIColor.fontColor, for: .normal)

        self.sendB.setTitle("Send", for: .normal)
        self.usernameB?.setTitle("Replying as u/\(AccountController.currentName)", for: .normal)
        self.discardB.setTitle("Cancel", for: .normal)
        
        self.usernameB?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        
        sendB.addTarget(self, action: #selector(self.send(_:)), for: UIControl.Event.touchUpInside)
        usernameB?.addTarget(self, action: #selector(self.changeUser(_:)), for: UIControl.Event.touchUpInside)
        discardB.addTarget(self, action: #selector(self.discard(_:)), for: UIControl.Event.touchUpInside)
        
        sendB.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        usernameB?.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        discardB.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        
        reply.addSubviews(sendB, discardB, usernameB!)
        
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
               // TODO: - this is probably wrong
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
    
    @objc func specialAction(_ sender: AnyObject) {
       print("Test")
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
        
        if !(parent?.isSearching ?? true ) && ((SettingValues.swapLongPress && !isMore) || (self.parent!.isMenuShown() && self.parent!.getMenuShown() == (content as! CommentObject).id)) {
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
            originalLocation = sender.location(in: self).x
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
            sender.cancel()
            return
        }
        let xVelocity = sender.velocity(in: self).x
        if sender.state != .ended && sender.state != .began && sender.state != .cancelled {
            guard previousProgress != 1 else { return }
            let posx = sender.location(in: self).x
            if direction == -1 && self.contentView.frame.origin.x > originalPos {
                if SettingValues.commentGesturesMode == .HALF || SettingValues.commentGesturesMode == .HALF_FULL {
                    return
                }
                if getFirstAction(left: false) != .NONE {
                    direction = 0
                    diff = self.contentView.frame.width - originalLocation
                    NSLayoutConstraint.deactivate(tiConstraints)
                    tiConstraints = batch {
                        typeImage.leftAnchor /==/ self.leftAnchor + 4
                    }
                }
            } else if direction == 1 && self.contentView.frame.origin.x < originalPos {
                if getFirstAction(left: true) != .NONE {
                    direction = 0
                    diff = self.contentView.frame.width - originalLocation
                    NSLayoutConstraint.deactivate(tiConstraints)
                    tiConstraints = batch {
                        typeImage.rightAnchor /==/ self.rightAnchor - 4
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
                        self.backgroundColor = UIColor.fontColor.withAlphaComponent(0.5)
                    }
                } else {
                    direction = -1
                    action = getFirstAction(left: false)
                    diff = self.contentView.frame.width - originalLocation

                    if action == .NONE {
                        sender.cancel()
                        return
                    }
                    typeImage.image = UIImage(named: action.getPhoto())?.getCopy(withSize: CGSize.square(size: 30), withColor: .white)
                    typeImage.isHidden = true
                    UIView.animate(withDuration: 0.1) {
                        self.backgroundColor = UIColor.fontColor.withAlphaComponent(0.5)
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
                        typeImage.leftAnchor /==/ self.leftAnchor + 4
                    } else {
                        typeImage.rightAnchor /==/ self.rightAnchor - 4
                    }
                }
                typeImage.centerYAnchor /==/ self.centerYAnchor
                typeImage.heightAnchor /==/ 45
                typeImage.widthAnchor /==/ 45
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
                    self.backgroundColor = UIColor.fontColor.withAlphaComponent(0.5)
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
            if (isTwoForDirection(left: direction == 1) && ((currentProgress >= 0.1 && previousProgress < 0.1) || (currentProgress <= 0.1 && previousProgress > 0.1))) || (!isTwoForDirection(left: direction == 1) && currentProgress >= 0.25 && previousProgress < 0.25) || sender.state == .ended {
                if #available(iOS 10.0, *) {
                    HapticUtility.hapticActionWeak()
                }
            }
            previousTranslation = currentTranslation
            previousProgress = currentProgress
        } else if sender.state == .ended && ((currentProgress >= (isTwoForDirection(left: direction == 1) ? 0.1 : 0.25) && !((xVelocity > 300 && direction == -1) || (xVelocity < -300 && direction == 1))) || (((xVelocity > 0 && direction == 1) || (xVelocity < 0 && direction == -1)) && abs(xVelocity) > 1000)) {
            doAction(item: self.action)
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.typeImage.alpha = 0
                self.backgroundColor = UIColor.backgroundColor
                self.typeImage.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                self.contentView.frame.origin.x = self.originalPos
            }, completion: { (_) in
                self.typeImage.removeFromSuperview()
                self.typeImage = nil
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
                self.backgroundColor = UIColor.backgroundColor
            }, completion: { (_) in
                self.typeImage.removeFromSuperview()
                self.typeImage = nil
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

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isKind(of: UIButton.classForCoder()) ?? false {
            return false
        }
        return true
    }

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
            if del.isMenuShown() && del.getMenuShown() == (content as! CommentObject).id {
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
            self.contentView.backgroundColor = UIColor.foregroundColor
        }, completion: { (_) in
            self.contentView.removeConstraints(self.tempConstraints)
            self.tempConstraints = []
            self.menuHeight.append(self.menu.heightAnchor /==/ CGFloat(0))
            self.menuHeight.append(self.commentBody.bottomAnchor /==/ self.contentView.bottomAnchor - CGFloat(8))
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
        if comment != nil {
            self.showCommentMenu(false)
        }
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
            if let subreddit = self.comment?.subreddit {
                self.contentView.backgroundColor = UIColor.foregroundColorOverlaid(with: ColorUtil.getColorForSub(sub: subreddit), 0.25)
            }
        }, completion: { (_) in
        })
        parent!.menuId = comment!.id
    }
    
    func showCommentMenu(_ animate: Bool = true) {
        upvoteButton = UIButton.init(type: .custom).then({
            if ActionStates.getVoteDirection(s: comment!) == .up {
                $0.setImage(UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")?.getCopy(withSize: CGSize(width: 20, height: 20), withColor: ColorUtil.upvoteColor).addImagePadding(x: 15, y: 15), for: .normal)
            } else {
                $0.setImage(UIImage(sfString: SFSymbol.arrowUp, overrideString: "upvote")?.getCopy(withSize: CGSize(width: 20, height: 20), withColor: UIColor.fontColor).addImagePadding(x: 15, y: 15), for: .normal)
            }
            $0.addTarget(self, action: #selector(self.upvote(_:)), for: UIControl.Event.touchUpInside)
        })
        downvoteButton = UIButton.init(type: .custom).then({
            if ActionStates.getVoteDirection(s: comment!) == .down {
                $0.setImage(UIImage(sfString: SFSymbol.arrowDown, overrideString: "downvote")?.getCopy(withSize: CGSize(width: 20, height: 20), withColor: ColorUtil.downvoteColor).addImagePadding(x: 15, y: 15), for: .normal)
            } else {
                $0.setImage(UIImage(sfString: SFSymbol.arrowDown, overrideString: "downvote")?.getCopy(withSize: CGSize(width: 20, height: 20), withColor: UIColor.fontColor).addImagePadding(x: 15, y: 15), for: .normal)
            }
            $0.addTarget(self, action: #selector(self.downvote(_:)), for: UIControl.Event.touchUpInside)
        })
        replyButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage(sfString: SFSymbol.arrowshapeTurnUpLeftFill, overrideString: "reply")?.getCopy(withSize: CGSize(width: 20, height: 20), withColor: UIColor.fontColor).addImagePadding(x: 15, y: 15), for: .normal)
            $0.addTarget(self, action: #selector(self.reply(_:)), for: UIControl.Event.touchUpInside)
        })
        moreButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage(sfString: SFSymbol.ellipsis, overrideString: "ic_more_vert_white")?.getCopy(withSize: CGSize(width: 20, height: 20), withColor: UIColor.fontColor).addImagePadding(x: 15, y: 15), for: .normal)
            $0.addTarget(self, action: #selector(self.menu(_:)), for: UIControl.Event.touchUpInside)
        })
        editButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage(sfString: SFSymbol.pencil, overrideString: "edit")?.getCopy(withSize: CGSize(width: 20, height: 20), withColor: UIColor.fontColor).addImagePadding(x: 15, y: 15), for: .normal)
            $0.addTarget(self, action: #selector(self.edit(_:)), for: UIControl.Event.touchUpInside)
        })
        deleteButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage(sfString: SFSymbol.trashFill, overrideString: "delete")?.getCopy(withSize: CGSize(width: 20, height: 20), withColor: UIColor.fontColor).addImagePadding(x: 15, y: 15), for: .normal)
            $0.addTarget(self, action: #selector(self.doDelete(_:)), for: UIControl.Event.touchUpInside)
        })
        modButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage(sfString: SFSymbol.shieldLefthalfFill, overrideString: "mod")?.getCopy(withSize: CGSize(width: 20, height: 20), withColor: UIColor.fontColor).addImagePadding(x: 15, y: 15), for: .normal)
            $0.addTarget(self, action: #selector(self.showModMenu(_:)), for: UIControl.Event.touchUpInside)
        })
        
        let removedSubviews = menu.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            menu.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        removedSubviews.forEach({ $0.removeFromSuperview() })
        
        if UIDevice.current.userInterfaceIdiom == .pad && (!UIApplication.shared.isSplitOrSlideOver || UIApplication.shared.isMac()) {
            menu.addArrangedSubviews(flexSpace(), flexSpace(), flexSpace(), editButton, deleteButton, upvoteButton, downvoteButton, replyButton, moreButton, modButton)
        } else {
            menu.addArrangedSubviews(editButton, deleteButton, upvoteButton, downvoteButton, replyButton, moreButton, modButton)
        }
        
        if comment == nil {
            return
        }
        
        if !AccountController.isLoggedIn || comment!.isArchived || parent!.np || (parent?.offline ?? false) {
            upvoteButton.isHidden = true
            downvoteButton.isHidden = true
            replyButton.isHidden = true
        }
        if !comment!.isMod || (parent?.offline ?? false) {
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
            self.menu.heightAnchor /<=/ CGFloat(45)
            self.menu.horizontalAnchors /==/ self.contentView.horizontalAnchors
            self.menu.bottomAnchor /==/ self.contentView.bottomAnchor
            self.menu.topAnchor /==/ self.commentBody.bottomAnchor + CGFloat(8)
            if self.body != nil {
                self.body!.heightAnchor /==/ CGFloat(0)
            }
            self.reply.heightAnchor /==/ CGFloat(0)
        }
        
        if let subreddit = self.comment?.subreddit, animate {
            self.contentView.backgroundColor = UIColor.foregroundColorOverlaid(with: ColorUtil.getColorForSub(sub: subreddit), 0.25)
        }
        menuBack.backgroundColor = UIColor.clear
        //menuBack.backgroundColor = ColorUtil.getColorForSub(sub: comment!.subreddit)
        //menuBack.roundCorners([UIRectCorner.bottomLeft, UIRectCorner.bottomRight], radius: 5)
    }
    
    func hideCommentMenu(_ doBody: Bool = true) {
        depth = oldDepth
        reply.isHidden = true
        NSLayoutConstraint.deactivate(menuHeight)
        NSLayoutConstraint.deactivate(oldConstraints)
        menu.isHidden = doBody
        if !doBody {
            tempConstraints = batch {
                self.menu.heightAnchor /<=/ CGFloat(45)
                self.menu.horizontalAnchors /==/ self.contentView.horizontalAnchors
                self.menu.topAnchor /==/ self.commentBody.bottomAnchor + CGFloat(8)
            }
        }
        
        oldConstraints = []
        menuHeight = batch {
            if doBody {
                commentBody.bottomAnchor /==/ contentView.bottomAnchor - CGFloat(8)
                menu.heightAnchor /==/ CGFloat(0)
            }
            if body != nil {
                body!.heightAnchor /==/ CGFloat(0)
            }
            reply.heightAnchor /==/ CGFloat(0)
        }
        updateDepth()
        if doBody {
            self.contentView.backgroundColor = UIColor.foregroundColor
        }
    }

    weak var parent: CommentViewController?
    
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
                self.parent?.savedText = nil
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
        spinnerIndicator.color = UIColor.fontColor
        spinnerIndicator.startAnimating()
        
        alertController?.view.addSubview(spinnerIndicator)
        parent!.present(alertController!, animated: true, completion: nil)
        
        let session = (UIApplication.shared.delegate as! AppDelegate).session
        
        do {
            let name = comment!.id
            try session?.editCommentOrLink(name, newBody: body!.text!, completion: { (_) in
                self.getCommentEdited(name)
            })
        } catch {
            print((error as NSError).description)
        }
    }
    
    @objc func send(_ sender: AnyObject) {
        self.endEditing(true)
        self.parent?.savedText = nil
        if edit {
            doEdit(sender)
            return
        }
        
        var session = (UIApplication.shared.delegate as! AppDelegate).session
        
        if let name = self.chosenAccount {
            let token: OAuth2Token
            do {
                if AccountController.isMigrated(name) {
                    token = try LocalKeystore.token(of: name)
                } else {
                    token = try OAuth2TokenRepository.token(of: name)
                }
                session = Session(token: token)
            } catch {
                let alert = UIAlertController(title: "Something went wrong", message: "There was an error loading this account. Please try again later.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (_) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                parent?.present(alert, animated: true, completion: nil)
                return
            }
        }
        alertController = UIAlertController(title: "Sending reply\(chosenAccount != nil ? " as u/" + chosenAccount! : "")...\n\n\n", message: nil, preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.fontColor
        spinnerIndicator.startAnimating()
        
        alertController?.view.addSubview(spinnerIndicator)
        parent?.present(alertController!, animated: true, completion: nil)
        
        do {
            let name = comment!.id
            try session?.postComment(body!.text!, parentName: name, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        self.toolbar?.saveDraft(self)
                        self.alertController?.dismiss(animated: false, completion: {
                            let alert = UIAlertController(title: "Something went wrong", message: "Your comment has not been sent (but has been saved as a draft), please try again.\n\nError: \(error.localizedDescription)", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self.parent?.present(alert, animated: true, completion: nil)
                        })
                        self.replyDelegate?.replySent(comment: nil, cell: self)
                    }
                case .success(let postedComment):
                    DispatchQueue.main.async {
                        self.alertController?.dismiss(animated: false, completion: {
                        })
                        self.replyDelegate?.replySent(comment: postedComment, cell: self)
                        self.parent?.isReply = false
                        self.replyDelegate!.discard()
                    }
                }
            })
        } catch {
            DispatchQueue.main.async {
                self.toolbar?.saveDraft(self)
                self.alertController?.dismiss(animated: false, completion: {
                    let alert = UIAlertController(title: "Something went wrong", message: "Your comment has not been sent (but has been saved as a draft), please try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.parent?.present(alert, animated: true, completion: nil)
                })
                self.replyDelegate?.replySent(comment: nil, cell: self)
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
                    del.isReply = false
                    self.body?.text = ""
                    completion(true)
                }))
                alert.addAction(UIAlertAction(title: "Delete draft", style: .destructive, handler: { (_) in
                    del.isReply = false
                    self.body?.text = ""
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
    override func layoutSubviews() {
        if typeImage != nil {
            return
        }
        super.layoutSubviews()
    }
    
    weak var replyDelegate: ReplyDelegate?
    @objc func reply(_ s: AnyObject) {
        oldLocation = parent!.tableView.contentOffset
        if menu.isHidden {
            showMenu(s)
        }
        if body == nil {
            self.body = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0)).then({
                $0.isEditable = true
                $0.textColor = UIColor.fontColor
                $0.backgroundColor = UIColor.foregroundColor.withAlphaComponent(0.6)
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.delegate = self
            })
            
            self.reply.addSubview(body!)
        }
        
        menu.isHidden = true
        reply.isHidden = false
        parent?.isReply = true

        NSLayoutConstraint.deactivate(menuHeight)
        menuHeight = batch {
            reply.topAnchor /==/ commentBody.bottomAnchor + CGFloat(8)
            reply.bottomAnchor /==/ contentView.bottomAnchor
            reply.horizontalAnchors /==/ contentView.horizontalAnchors
            usernameB!.leftAnchor /==/ reply.leftAnchor + CGFloat(8)
            usernameB!.topAnchor /==/ reply.topAnchor + CGFloat(8)
            body!.horizontalAnchors /==/ reply.horizontalAnchors + CGFloat(8)
            body!.topAnchor /==/ usernameB!.bottomAnchor + CGFloat(4)
            discardB.leftAnchor /==/ reply.leftAnchor + CGFloat(8)
            sendB.rightAnchor /==/ reply.rightAnchor - CGFloat(8)
            discardB.topAnchor /==/ body!.bottomAnchor + CGFloat(8)
            sendB.topAnchor /==/ body!.bottomAnchor + CGFloat(8)
            discardB.bottomAnchor /==/ reply.bottomAnchor - CGFloat(8)
            sendB.bottomAnchor /==/ reply.bottomAnchor - CGFloat(8)
            sendB.heightAnchor /==/ CGFloat(45)
            discardB.heightAnchor /==/ CGFloat(45)
        }
        
        updateDepth()
        
        body!.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        reply.backgroundColor = menuBack.backgroundColor
        
        body!.text = ""
        body!.delegate = self
        self.replyDelegate = parent!

        if edit {
            body!.text = comment!.markdownBody.decodeHTML()
        }

        toolbar = ToolbarTextView.init(textView: body!, parent: parent!)
        oldConstraints = batch {
            body!.heightAnchor />=/ 40
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
        if let parent = self.parent {
            more(parent)
        }
    }

    @objc func menu(_ s: AnyObject) {
        doMenu()
    }
    
    @objc func changeUser(_ s: AnyObject) {
        let optionMenu = DragDownAlertMenu(title: "Accounts", subtitle: "Choose an account to reply with", icon: nil)

        for accountName in AccountController.names.unique().sorted() {
            if accountName != self.chosenAccount {
                optionMenu.addAction(title: accountName, icon: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon()) { [weak self] in
                    self?.chosenAccount = accountName
                    self?.usernameB?.setTitle("Replying as u/\(accountName)", for: .normal)
                }
            } else {
                optionMenu.addAction(title: "\(accountName) (current)", icon: UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon().getCopy(withColor: GMColor.green500Color())) {
                }
            }
        }
        
        optionMenu.show(self.parent)
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
        if content is CommentObject {
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
            refresh(comment: content as! CommentObject, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modApprove() {
        if content is CommentObject {
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
                            self.parent!.removed.remove(at: self.parent!.removed.firstIndex(of: self.comment!.id)!)
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
            refresh(comment: content as! CommentObject, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func modDistinguish() {
        if content is CommentObject {
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
            refresh(comment: content as! CommentObject, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modSticky(sticky: Bool) {
        if content is CommentObject {
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
            refresh(comment: content as! CommentObject, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func modRemove(_ spam: Bool = false) {
        if content is CommentObject {
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
                            self.parent!.approved.remove(at: self.parent!.approved.firstIndex(of: self.comment!.id)!)
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
            refresh(comment: content as! CommentObject, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modBan(why: String, duration: Int?) {
        if content is CommentObject {
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
            refresh(comment: content as! CommentObject, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func getActions(_ par: CommentViewController) -> [AlertMenuAction] {
        var actions = [AlertMenuAction]()
        
        actions.append(AlertMenuAction(title: "\(AccountController.formatUsernamePosessive(input: comment!.author, small: false)) profile", icon: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon(), action: {
            let prof = ProfileViewController.init(name: self.comment!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: par.navigationController, parentViewController: par)
        }))

        actions.append(AlertMenuAction(title: "Share comment permalink", icon: UIImage(sfString: SFSymbol.link, overrideString: "link")!.menuIcon(), action: {
            let activityViewController = UIActivityViewController(activityItems: [URL(string: "\(self.comment!.permalink)?context=5") ?? URL(string: "about://blank")], applicationActivities: nil)
            if let presenter = activityViewController.popoverPresentationController {
                presenter.sourceView = self.moreButton
                presenter.sourceRect = self.moreButton.bounds
            }
            par.present(activityViewController, animated: true, completion: {})
        }))
        
        if AccountController.isLoggedIn {
            actions.append(AlertMenuAction(title: ActionStates.isSaved(s: comment!) ? "Unsave" : "Save", icon: UIImage(sfString: SFSymbol.starFill, overrideString: "save")!.menuIcon(), action: {
                par.saveComment(self.comment!)
            }))
        }
        
        actions.append(AlertMenuAction(title: "Report comment", icon: UIImage(sfString: SFSymbol.flagFill, overrideString: "flag")!.menuIcon(), action: {
            PostActions.report(self.comment!, parent: par, index: -1, delegate: nil)
        }))

        actions.append(AlertMenuAction(title: "Tag u/\(comment!.author)", icon: UIImage(sfString: SFSymbol.tagFill, overrideString: "subs")!.menuIcon(), action: {
            par.tagUser(name: self.comment!.author)
        }))
        
        actions.append(AlertMenuAction(title: "Block u/\(comment!.author)", icon: UIImage(sfString: SFSymbol.xmark, overrideString: "hide")!.menuIcon(), action: {
            par.blockUser(name: self.comment!.author)
        }))
        
        actions.append(AlertMenuAction(title: "Copy text", icon: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon(), action: {
            let alert = AlertController.init(title: "Copy text", message: nil, preferredStyle: .alert)
            
            alert.setupTheme()
            
            alert.attributedTitle = NSAttributedString(string: "Copy text", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
            
            let text = UITextView().then {
                $0.font = FontGenerator.fontOfSize(size: 14, submission: false)
                $0.textColor = UIColor.fontColor
                $0.backgroundColor = .clear
                $0.isEditable = false
                $0.text = self.comment!.markdownBody.decodeHTML()
            }
            
            alert.contentView.addSubview(text)
            text.edgeAnchors /==/ alert.contentView.edgeAnchors
            
            let height = text.sizeThatFits(CGSize(width: 238, height: CGFloat.greatestFiniteMagnitude)).height
            text.heightAnchor /==/ height
            
            alert.addCloseButton()
            alert.addAction(AlertAction(title: "Copy all", style: AlertAction.Style.normal, handler: { (_) in
                UIPasteboard.general.string = self.comment!.markdownBody.decodeHTML()
            }))
            
            alert.addBlurView()
            par.present(alert, animated: true)
        }))
        
        actions.append(AlertMenuAction(title: "Open comment permalink", icon: UIImage(named: "crosspost")!.menuIcon(), action: {
            VCPresenter.openRedditLink(self.comment!.permalink + "?context=5", par.navigationController, par)
        }))
        
        return actions
    }

    func more(_ par: CommentViewController) {
        if comment == nil {
            return
        }

        let alertController = DragDownAlertMenu(title: "Comment by u/\(comment!.author)", subtitle: comment!.markdownBody, icon: nil)

        alertController.actions = getActions(par)
        
        alertController.show(par.parent)
    }

    @available(iOS 13, *)
    func getMoreMenu(_ par: CommentViewController) -> UIMenu? {
        if comment == nil {
            return nil
        }

        var actions = [UIAction]()
        for action in getActions(par) {
            actions.append(UIAction(title: action.title, image: action.icon, handler: { (_) in
                action.action()
            }))
        }
        
        return UIMenu(title: "Comment by \(AccountController.formatUsername(input: self.comment?.author ?? "", small: true))", image: nil, identifier: nil, children: actions)
    }

    func mod(_ par: CommentViewController) {
        let alertController = DragDownAlertMenu(title: "Moderation", subtitle: "Comment by u/\(comment!.author)", icon: nil, themeColor: GMColor.lightGreen500Color())
        
        if let reportsDictionary = comment?.reportsDictionary {
            alertController.addAction(title: "\(reportsDictionary.keys.count > 0) reports", icon: UIImage(sfString: SFSymbol.exclamationmarkCircleFill, overrideString: "reports")!.menuIcon()) {
                var reports = ""
                for reporter in reportsDictionary.keys {
                    reports += "\(reporter): \(reportsDictionary[reporter] as? String ?? "")\n"
                }
                let alert = UIAlertController(title: "Reports",
                                              message: reports,
                                              preferredStyle: UIAlertController.Style.alert)
                
                let cancelAction = UIAlertAction(title: "OK",
                                                 style: .cancel, handler: nil)
                
                alert.addAction(cancelAction)
                par.present(alert, animated: true, completion: nil)
            }
        }

        alertController.addAction(title: "Approve", icon: UIImage(sfString: SFSymbol.handThumbsupFill, overrideString: "approve")!.menuIcon()) {
            self.modApprove()
        }

        alertController.addAction(title: "Ban u/\(comment!.author)", icon: UIImage(sfString: SFSymbol.hammerFill, overrideString: "ban")!.menuIcon()) {
           // TODO: - add ban!!!
        }

        if comment!.author == AccountController.currentName {
            alertController.addAction(title: "Distinguish your comment", icon: UIImage(sfString: SFSymbol.starFill, overrideString: "save")!.menuIcon()) {
                self.modDistinguish()
            }
        }

        if comment!.author == AccountController.currentName && comment!.depth == 1 {
            if comment!.isStickied {
                alertController.addAction(title: "Un-pin comment", icon: UIImage(sfString: SFSymbol.pinSlashFill, overrideString: "flag")!.menuIcon()) {
                    self.modSticky(sticky: false)
                }
            } else {
                alertController.addAction(title: "Pin and Distinguish comment", icon: UIImage(sfString: SFSymbol.pinFill, overrideString: "flag")!.menuIcon()) {
                    self.modSticky(sticky: true)
                }
            }
        }

        alertController.addAction(title: "Remove comment", icon: UIImage(sfString: SFSymbol.minusCircleFill, overrideString: "close")!.menuIcon()) {
            self.modRemove()
        }
        
        alertController.addAction(title: "Remove as Spam", icon: UIImage(sfString: SFSymbol.exclamationmarkBubbleFill, overrideString: "flag")!.menuIcon()) {
            self.modRemove(true)
        }
        
        alertController.addAction(title: "u/\(comment!.author)'s profile", icon: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon()) {
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
        
        topViewSpace.horizontalAnchors /==/ contentView.horizontalAnchors
        topViewSpace.topAnchor /==/ contentView.topAnchor
        title.topAnchor /==/ topViewSpace.bottomAnchor + CGFloat(8)

        title.leftAnchor /==/ sideView.rightAnchor + CGFloat(12)
        title.rightAnchor /==/ contentView.rightAnchor - CGFloat(4)
        commentBody.topAnchor /==/ title.bottomAnchor
        commentBody.leftAnchor /==/ sideView.rightAnchor + CGFloat(12)
        commentBody.rightAnchor /==/ contentView.rightAnchor - CGFloat(4)

        childrenCount.topAnchor /==/ topViewSpace.bottomAnchor + CGFloat(4)
        childrenCount.rightAnchor /==/ contentView.rightAnchor - CGFloat(4)
        sideView.verticalAnchors /==/ contentView.verticalAnchors
        sideViewSpace.verticalAnchors /==/ contentView.verticalAnchors
        
        specialButton.widthAnchor /==/ 25
        specialButton.heightAnchor /==/ 25
        specialButton.bottomAnchor /==/ contentView.bottomAnchor
        specialButton.rightAnchor /==/ contentView.rightAnchor
        updateDepth()
        menu.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        title.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        commentBody.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        reply.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
    }
    
    func updateDepth() {
        NSLayoutConstraint.deactivate(sideConstraints)
        sideConstraints = batch {
            sideViewSpace.leftAnchor /==/ contentView.leftAnchor - CGFloat(8)
            sideViewSpace.widthAnchor /==/ CGFloat((SettingValues.wideIndicators ? 8 : 4) * (depth))
            sideView.leftAnchor /==/ sideViewSpace.rightAnchor
            sideView.widthAnchor /==/ CGFloat(sideWidth)
        }
    }

    var sideWidth: Int = 0
    var marginTop: Int = 0
    var menuHeight: [NSLayoutConstraint] = []
    var topMargin: [NSLayoutConstraint] = []
    var isMore = false

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
            self.contentView.addGestureRecognizer(tapGestureRecognizer)
            
            if #available(iOS 13, *) {
                let previewing = UIContextMenuInteraction(delegate: self)
                self.contentView.addInteraction(previewing)
            }
            long = UILongPressGestureRecognizer.init(target: self, action: #selector(self.handleLongPress(_:)))
            long.minimumPressDuration = 0.36
            long.delegate = self
            long.cancelsTouchesInView = false
            self.contentView.addGestureRecognizer(long)
            
            if SettingValues.commentActionForceTouch != .PARENT_PREVIEW && SettingValues.commentActionForceTouch != .NONE && force == nil {
                force = ForceTouchGestureRecognizer()
                force?.addTarget(self, action: #selector(self.do3dTouch(_:)))
                force?.cancelsTouchesInView = false
                self.contentView.addGestureRecognizer(force!)
            }
        }
    }

    func setMore(more: MoreObject, depth: Int, depthColors: [UIColor], parent: CommentViewController) {
        if loader != nil {
            loader?.stopAnimating()
            loader?.removeFromSuperview()
            loader = nil
        }

        if title == nil {
            configureInit()
        }
        self.specialButton.isHidden = true
        self.depth = depth
        self.comment = nil
        self.isMore = true
        self.depthColors = depthColors
        
        if self.parent == nil {
            self.parent = parent
        }
        
        loading = false
        childrenCount.alpha = 0
        self.contentView.backgroundColor = UIColor.foregroundColor

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
        if more.childrenString.isEmpty {
            attr = TextDisplayStackView.createAttributedChunk(baseHTML: "<p>Continue thread</p>", fontSize: 16, submission: false, accentColor: .white, fontColor: UIColor.fontColor, linksCallback: nil, indexCallback: nil)
        } else {
            attr = TextDisplayStackView.createAttributedChunk(baseHTML: "<p>Load \(more.count) more</p>", fontSize: 16, submission: false, accentColor: .white, fontColor: UIColor.fontColor, linksCallback: nil, indexCallback: nil)
        }
        
        title.attributedText = attr
        title.layoutTitleImageViews()
        
        commentBody.clearOverflow()
        commentBody.firstTextView.isHidden = true
        NSLayoutConstraint.deactivate(menuHeight)
        NSLayoutConstraint.deactivate(oldConstraints)
        oldConstraints = []
        menuHeight = batch {
            commentBody.bottomAnchor /==/ contentView.bottomAnchor - CGFloat(8)
            menu.heightAnchor /==/ CGFloat(0)
            if body != nil {
                body!.heightAnchor /==/ CGFloat(0)
            }
            reply.heightAnchor /==/ CGFloat(0)
        }
        updateDepth()
        NSLayoutConstraint.deactivate(topMargin)
        topMargin = batch {
            topViewSpace.heightAnchor /==/ CGFloat(marginTop)
        }
        
        connectGestures()
    }

    var numberOfDots = 3
    var loading = false

    public var isCollapsed = false
    var dtap: UIShortTapGestureRecognizer?

    func setComment(comment: CommentObject, depth: Int, parent: CommentViewController, hiddenCount: Int, date: Double, author: String?, text: NSAttributedString, isCollapsed: Bool, parentOP: String, depthColors: [UIColor], indexPath: IndexPath, width: CGFloat) {
        if loader != nil {
            loader?.stopAnimating()
            loader?.removeFromSuperview()
            loader = nil
        }
        if title == nil {
            configureInit()
        }
        if SettingValues.commentActionForceTouch == .NONE {// TODO: - change this
        }
        self.specialButton.isHidden = true
        self.accessibilityValue = """
        Depth \(comment.depth).
        "\(text.string)"
        Comment by user \(comment.author). Score is \(comment.scoreHidden ? "hidden" : "\(comment.score)")
        """

        self.comment = comment
        self.cellContent = text
        self.isMore = false
        
        self.currentPath = indexPath
        self.contentView.backgroundColor = UIColor.foregroundColor

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
            commentBody.estimatedWidth = width - CGFloat(12) - CGFloat(sideWidth) - CGFloat((SettingValues.wideIndicators ? 8 : 4) * (depth - 1)) - CGFloat(SettingValues.wideIndicators ? 4 : 0)
        }

        if depth == 1 {
            marginTop = 8
        }
        
        if !commentBody.ignoreHeight {
            marginTop = 0
            self.depth = 0
            sideWidth = 8
            sideView.backgroundColor = UIColor.foregroundColor
        }

        refresh(comment: comment, submissionAuthor: author, text: text, date)

        if !registered {
            parent.registerForPreviewing(with: self, sourceView: title)
            registered = true
        }
        if parent.getMenuShown() ?? "" == comment.id {
            showCommentMenu()
            if parent.savedText != nil {
                reply(self)
                body?.text = parent.savedText
                body?.becomeFirstResponder()
            }
        } else {
            hideCommentMenu()
        }

        NSLayoutConstraint.deactivate(topMargin)
        topMargin = batch {
            topViewSpace.heightAnchor /==/ CGFloat(marginTop)
        }
    }
    
    var cellContent: NSAttributedString?

    var savedAuthor: String = ""

    func refresh(comment: CommentObject, submissionAuthor: String?, text: NSAttributedString, _ date: Double = 0) {
        var color: UIColor
        
        savedAuthor = submissionAuthor!

        switch ActionStates.getVoteDirection(s: comment) {
        case .down:
            color = ColorUtil.downvoteColor
        case .up:
            color = ColorUtil.upvoteColor
        default:
            color = UIColor.fontColor
        }
        
        let boldFont = FontGenerator.boldFontOfSize(size: 14, submission: false)

        let scoreString = NSMutableAttributedString(string: (comment.scoreHidden ? "[score hidden]" : "\(Int(getScoreText(comment: comment)))"), attributes: [NSAttributedString.Key.foregroundColor: color, NSAttributedString.Key.font: boldFont])
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2.75
        
        let spacerString = NSMutableAttributedString(string: (comment.controversality > 0 ? "†  •  " : "  •  "), attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.font: boldFont])
        let new = date != 0 && date < Double(comment.created.timeIntervalSince1970)
        let endString = NSMutableAttributedString(string: "\(new ? " " : "")\(DateFormatter().timeSince(from: comment.created as NSDate, numericDates: true))" + (comment.isEdited ? ("(edit \(DateFormatter().timeSince(from: (comment.edited ?? Date()) as NSDate, numericDates: true)))\(new ? " " : "")") : "\(new ? " " : "")"), attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.font: boldFont])
        
        if new {
            endString.addAttributes([.badgeColor: ColorUtil.accentColorForSub(sub: comment.subreddit), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange(location: 0, length: endString.length))
        }

        let authorString = NSMutableAttributedString(string: "\u{00A0}\u{00A0}\(AccountController.formatUsername(input: comment.author + (comment.isCakeday ? " 🎂" : ""), small: true))\u{00A0}", attributes: [NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        if comment.author != "[deleted]" && comment.author != "[removed]" {
            authorString.addAttributes([NSAttributedString.Key.textHighlight: TextHighlight(["url": URL(string: "/u/\(comment.author)") ?? URL(string: "about://blank")!, "profile": comment.author])], range: NSRange(location: 0, length: authorString.length))
        }
        let authorStringNoFlair = NSMutableAttributedString(string: "\(AccountController.formatUsername(input: comment.author, small: true))\u{00A0}", attributes: [NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: parent?.authorColor ?? UIColor.fontColor, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        
        if comment.author != "[deleted]" && comment.author != "[removed]" {
            authorString.addAttributes([NSAttributedString.Key.textHighlight: TextHighlight(["url": URL(string: "/u/\(comment.author)") ?? URL(string: "about://blank")!, "profile": comment.author])], range: NSRange(location: 0, length: authorString.length))
            authorStringNoFlair.addAttributes([NSAttributedString.Key.textHighlight: TextHighlight(["url": URL(string: "/u/\(comment.author)") ?? URL(string: "about://blank")!, "profile": comment.author])], range: NSRange(location: 0, length: authorStringNoFlair.length))
        }

        var flairString: NSMutableAttributedString?
        if SettingValues.showFlairs {
            let flairsDict = comment.flairDictionary
            let flairTitle = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
            if !flairsDict.keys.isEmpty {
                for key in flairsDict.keys {
                    let flair = flairsDict[key] as? NSDictionary
                    if let url = flair?["url"] as? String, SettingValues.imageFlairs {
                        if let urlAsURL = URL(string: url) {
                            let attachment = AsyncTextAttachmentNoLoad(imageURL: urlAsURL, delegate: nil, rounded: false, backgroundColor: UIColor.foregroundColor)
                            attachment.bounds = CGRect(x: 0, y: -2 + (15 * -0.5) / 2, width: 15, height: 15)
                            flairTitle.append(NSAttributedString(attachment: attachment))
                        }
                    } else {
                        let flair = flairsDict[key] as? NSDictionary
                        if let color = flair?["color"] as? String, SettingValues.coloredFlairs {
                            let singleFlair = NSMutableAttributedString(string: "\u{00A0}\(key)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: UIColor(hexString: color), NSAttributedString.Key.foregroundColor: UIColor.white])
                            flairTitle.append(singleFlair)
                        } else {
                            let singleFlair = NSMutableAttributedString(string: "\u{00A0}\(key)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key.badgeColor: UIColor.backgroundColor, NSAttributedString.Key.foregroundColor: UIColor.fontColor])
                            flairTitle.append(singleFlair)
                        }
                    }
                }
                flairString = flairTitle
            }
        }

        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), .badgeColor: GMColor.green500Color(), NSAttributedString.Key.foregroundColor: UIColor.white])

        let spacer = NSMutableAttributedString.init(string: "  ")
        let userColor = ColorUtil.getColorForUser(name: comment.author)
        var authorSmall = false
        if comment.distinguished == "admin" {
            authorString.addAttributes([.badgeColor: UIColor.init(hexString: "#E57373"), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if comment.distinguished == "special" {
            authorString.addAttributes([.badgeColor: UIColor.init(hexString: "#F44336"), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if comment.distinguished == "moderator" {
            authorString.addAttributes([.badgeColor: UIColor.init(hexString: "#81C784"), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if AccountController.currentName == comment.author {
            authorString.addAttributes([.badgeColor: UIColor.init(hexString: "#FFB74D"), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if userColor != ColorUtil.baseColor {
            authorString.addAttributes([.badgeColor: userColor, NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
        } else if submissionAuthor != nil && comment.author == submissionAuthor {
            authorString.addAttributes([.badgeColor: UIColor.init(hexString: "#64B5F6"), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 0, length: authorString.length))
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
        
        if let flairs = flairString {
            infoString.append(flairs)
        }

        let tag = ColorUtil.getTagForUser(name: comment.author)
        if tag != nil {
            let tagString = NSMutableAttributedString.init(string: "\u{00A0}\(tag!)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), .badgeColor: UIColor(rgb: 0x2196f3), NSAttributedString.Key.foregroundColor: UIColor.white])
            infoString.append(spacer)
            infoString.append(tagString)
        }

        infoString.append(NSAttributedString(string: "  •  ", attributes: [NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: UIColor.fontColor]))
        infoString.append(scoreString)
        infoString.append(spacerString)
        infoString.append(endString)

        if comment.isStickied {
            infoString.append(spacer)
            infoString.append(pinned)
        }
        
        //TODO flairs and awards
        /*if comment.isCakeday {
            infoString.append(spacer)
            let gild = NSMutableAttributedString.yy_attachmentString(withEmojiImage: UIImage(named: "cakeday")!, fontSize: boldFont.pointSize)!
            infoString.append(gild)
        }*/

        if parent!.removed.contains(comment.id) || (!(comment.removedBy ?? "").isEmpty() && !parent!.approved.contains(comment.id)) {
            let attrs = [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: GMColor.red500Color()]
            infoString.append(spacer)
            if comment.removedBy == "true" {
                infoString.append(NSMutableAttributedString.init(string: "Removed by Reddit\(!(comment.removalReason ?? "").isEmpty() ? ":\(comment.removalReason!)" : "")", attributes: attrs))
            } else {
                infoString.append(NSMutableAttributedString.init(string: "Removed\(!(comment.removedBy ?? "").isEmpty() ? " by \(comment.removedBy!)":"")\(!(comment.removalReason ?? "").isEmpty() ? " for \(comment.removalReason!)" : "")\(!(comment.removalNote ?? "").isEmpty() ? " \(comment.removalNote!)" : "")", attributes: attrs))
            }
        } else if parent!.approved.contains(comment.id) || (!(comment.approvedBy ?? "").isEmpty() && !parent!.removed.contains(comment.id)) {
            let attrs = [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: GMColor.green500Color()]
            infoString.append(spacer)
            infoString.append(NSMutableAttributedString.init(string: "Approved\(!(comment.approvedBy ?? "").isEmpty() ? " by \(comment.approvedBy!)":"")", attributes: attrs))
        }
        
        paragraphStyle.lineSpacing = 1.5
        //infoString.setAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: infoString.length))

        commentBody.tColor = ColorUtil.accentColorForSub(sub: comment.subreddit)
        if !isCollapsed || !SettingValues.collapseFully {
            title.linkTextAttributes = [NSAttributedString.Key.foregroundColor: ColorUtil.accentColorForSub(sub: comment.subreddit)]
            title.attributedText = infoString
            title.layoutTitleImageViews()
            commentBody.firstTextView.isHidden = false
            commentBody.clearOverflow()
            commentBody.setTextWithTitleHTML(NSMutableAttributedString(), text, htmlString: comment.htmlBody)
        } else {
            title.linkTextAttributes = [NSAttributedString.Key.foregroundColor: ColorUtil.accentColorForSub(sub: comment.subreddit)]
            title.attributedText = infoString
            title.layoutTitleImageViews()
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
        if let subreddit = self.comment?.subreddit {
            self.contentView.backgroundColor = UIColor.foregroundColorOverlaid(with: ColorUtil.getColorForSub(sub: subreddit), 0.25)
        }
    }

    func getScoreText(comment: CommentObject) -> Double {
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
        return Double(submissionScore)
    }

    var registered: Bool = false

    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {

        let locationInTextView = title.convert(location, to: title)

        if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
            previewingContext.sourceRect = title.convert(rect, from: title)
            if let controller = parent?.getControllerForUrl(baseUrl: url, link: SubmissionObject()) {
                return controller
            }
        }

        return nil
    }

    func getInfo(locationInTextView: CGPoint) -> (URL, CGRect)? {
        return nil
        // TODO: - this
        /*
        if let attr = title.firstTextView.link(at: locationInTextView) {
            if let url = attr.result.url {
                return (url, title.bounds)
            }

        }
        return nil
        */
    }
    
    func animateMore() {
        loading = true
        if loader == nil {
            loader = UIActivityIndicatorView().then {
                $0.color = UIColor.fontColor
                $0.hidesWhenStopped = true
            }
            
            self.contentView.addSubview(loader!)
            loader!.centerYAnchor /==/ self.contentView.centerYAnchor
            loader!.rightAnchor /==/ self.contentView.rightAnchor - 12
        }
        loader?.isHidden = false
        loader?.startAnimating()
        title.attributedText = TextDisplayStackView.createAttributedChunk(baseHTML: "Loading...", fontSize: 16, submission: false, accentColor: .white, fontColor: UIColor.fontColor, linksCallback: nil, indexCallback: nil)
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
            self.parent?.doShow(url: url, heroView: nil, finalSize: nil, heroVC: nil, link: SubmissionObject())
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
        
        alertController.addAction(title: "Copy URL", icon: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()) {
            UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
            BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self.parent)
        }
        
        alertController.addAction(title: "Open in default app", icon: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alertController.addAction(title: "Open in Chrome", icon: UIImage(named: "world")!.menuIcon()) {
                open.openInChrome(url, callbackURL: nil, createNewTab: true)
            }
        }
        
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionStrong()
        } else if SettingValues.hapticFeedback {
            AudioServicesPlaySystemSound(1519)
        }
        
        alertController.show(parent)
    }
    
    func previewProfile(profile: String) {
        if let parent = self.parent {
            let vc = ProfileInfoViewController(accountNamed: profile)
            vc.modalPresentationStyle = .custom
            let presentation = ProfileInfoPresentationManager()
            self.profilePresentationManager = presentation
            vc.transitioningDelegate = presentation
            parent.present(vc, animated: true)
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
            if self?.state != UIGestureRecognizer.State.recognized {
                self?.state = UIGestureRecognizer.State.failed
            }
        }
    }
}

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
    var submission: SubmissionObject
    var comment: CommentObject

    private lazy var networkActionsArePossible: Bool = {
        return AccountController.isLoggedIn && LinkCellView.checkInternet()
    }()

    var isOwnComment: Bool {
        return AccountController.currentName == comment.author
    }

    var isVotingPossible: Bool {
        return networkActionsArePossible && !submission.isArchived
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
        return networkActionsArePossible && !submission.isArchived
    }

    var isModPossible: Bool {
        return networkActionsArePossible && submission.isMod
    }

    init(comment: CommentObject, submission: SubmissionObject) {
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

@available(iOS 13.0, *)
extension CommentDepthCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            if let vc = self.previewedVC {
                if let vc = vc as? ProfilePreviewViewController {
                    VCPresenter.openRedditLink("/u/\(vc.account)", self.parent?.navigationController, self.parent)
                    return
                }
                if vc is WebsiteViewController || vc is SFHideSafariViewController {
                    self.previewedVC = nil
                    if let url = self.previewedURL {
                        self.parent?.doShow(url: url, heroView: nil, finalSize: nil, heroVC: nil, link: SubmissionObject())
                    }
                } else if vc is ParentCommentViewController && self.parent != nil {
                    let context = (vc as! ParentCommentViewController).parentContext
                    var index = 0
                    for c in self.parent!.dataArray {
                        let comment = self.parent!.content[c]
                        if comment is CommentObject && (comment as! CommentObject).id.contains(context) {
                            self.parent!.menuId = comment!.getId()
                            self.parent!.tableView.reloadData()
                            if !SettingValues.dontHideTopBar && self.parent!.navigationController != nil && !self.parent!.isHiding && !self.parent!.isToolbarHidden {
                                self.parent!.hideUI(inHeader: true)
                            }

                            self.parent!.goToCell(i: index)
                            break
                        } else {
                            index += 1
                        }
                    }
                } else {
                    if self.parent != nil && (vc is AlbumViewController || vc is ModalMediaViewController) {
                        vc.modalPresentationStyle = .overFullScreen
                        self.parent?.present(vc, animated: true)
                    } else {
                        VCPresenter.showVC(viewController: vc, popupIfPossible: true, parentNavigationController: nil, parentViewController: self.parent)
                    }
                }
            }
        }
    }
    
    func createRectsTargetedPreview(textView: TitleUITextView, location: CGPoint, snapshot: UIView) -> UITargetedPreview? {
        let rects = self.getLocationForPreviewedText(textView, textView.convert(location, from: self.contentView), self.previewedURL?.absoluteString)
        var convertedRects = [CGRect]()
        
        var minX = CGFloat.greatestFiniteMagnitude, maxX = -CGFloat.greatestFiniteMagnitude,
            minY = CGFloat.greatestFiniteMagnitude, maxY = -CGFloat.greatestFiniteMagnitude

        for rect in rects {
            convertedRects.append(self.contentView.convert(rect, from: textView))
        }
        
        if convertedRects.isEmpty {
            return nil
        }
        
        for rect in convertedRects {
            minX = min(rect.minX, minX)
            maxX = max(rect.maxX, maxX)
            minY = min(rect.minY, minY)
            maxY = max(rect.maxY, maxY)
        }
        
        let weightedCenterpoint = CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)

        let target = UIPreviewTarget(container: self.contentView, center: weightedCenterpoint)
        let parameters = UIPreviewParameters(textLineRects: convertedRects as [NSValue])
        parameters.backgroundColor = UIColor.foregroundColor
        
        let path = UIBezierPath(wrappingAround: convertedRects)
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        
        let snapshotContainer = UIView(frame: snapshot.bounds)
        snapshotContainer.addSubview(snapshot)
        snapshot.layer.mask = maskLayer

        return UITargetedPreview(view: snapshotContainer, parameters: parameters, target: target)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        self.savedPreview = createPreview(interaction, configuration: configuration)
        return self.savedPreview
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.savedPreview
    }
    
    func createPreview(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        guard let snapshot = self.snapshotView(afterScreenUpdates: false) else {
              return nil
        }
        let location = interaction.location(in: self.contentView)
        if self.contentView.convert(self.sideViewSpace.frame, to: self.contentView).contains(location) {
            return UITargetedPreview(view: snapshot, parameters: parameters, target: UIPreviewTarget(container: self.sideViewSpace, center: self.sideViewSpace.center))
        } else if self.contentView.convert(self.sideView.frame, to: self.contentView).contains(location) {
            return UITargetedPreview(view: snapshot, parameters: parameters, target: UIPreviewTarget(container: self.sideView, center: self.sideView.center))
        } else if self.contentView.convert(self.title.frame, to: self.contentView).contains(location) {
            return createRectsTargetedPreview(textView: self.title, location: location, snapshot: snapshot)
        } else if self.commentBody.convert(self.commentBody.firstTextView.frame, to: self.contentView).contains(location) {
            return createRectsTargetedPreview(textView: self.commentBody.firstTextView, location: location, snapshot: snapshot)
        } else if self.commentBody.convert(self.commentBody.frame, to: self.contentView).contains(location) {
            let innerLocation = self.commentBody.convert(self.contentView.convert(location, to: self.commentBody), to: self.commentBody.overflow)
            for view in self.commentBody.overflow.subviews {
                if let view = view as? TitleUITextView, view.frame.contains(innerLocation) {
                    return createRectsTargetedPreview(textView: view, location: location, snapshot: snapshot)
                }
            }
        } else {
            
        }
        return nil
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let location = interaction.location(in: self.contentView)

        if self.contentView.convert(self.sideViewSpace.frame, to: self.contentView).contains(location) {
            return getConfigurationParentComment()
        } else if self.contentView.convert(self.sideView.frame, to: self.contentView).contains(location) {
            return getConfigurationParentComment()
        } else if self.contentView.convert(self.title.frame, to: self.contentView).contains(location) {
            if let config = getConfigurationForTextView(self.title, location) {
                return config
            }
        } else if self.commentBody.convert(self.commentBody.firstTextView.frame, to: self.contentView).contains(location) {
            if let config = getConfigurationForTextView(self.commentBody.firstTextView, location) {
                return config
            }
        } else if self.commentBody.convert(self.commentBody.frame, to: self.contentView).contains(location) {
            let innerLocation = self.commentBody.convert(self.contentView.convert(location, to: self.commentBody), to: self.commentBody.overflow)
            for view in self.commentBody.overflow.subviews {
                if view.frame.contains(innerLocation) && view is TitleUITextView {
                    if let config = getConfigurationForTextView(view as! TitleUITextView, location) {
                        return config
                    }
                }
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad || UIApplication.shared.isMac() {
            if self.parent?.menuCell == self {
                if let parent = self.parent {
                    let menu = self.getMoreMenu(parent)
                    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in
                        return menu
                    })
                }
            } else {
                self.showMenuAnimated()
            }
        }
        return nil
    }
    
    func contextMenuInteractionDidEnd(_ interaction: UIContextMenuInteraction) {
        self.previewedVC = nil
    }
    
    func getLocationForPreviewedText(_ label: TitleUITextView, _ location: CGPoint, _ inputURL: String?, _ changeRectTo: UIView? = nil) -> [CGRect] {
        if inputURL == nil {
            return [CGRect]()
        }
        
        let point = location

        var rects = [CGRect]()
        if let attributedText = label.attributedText, let layoutManager = label.layoutManager as? BadgeLayoutManager, let textStorage = layoutManager.textStorage {
            let index = layoutManager.characterIndex(for: point, in: label.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            
            if index < textStorage.length {
                var range = NSRange.zero

                if (attributedText.attribute(NSAttributedString.Key.urlAction, at: index, effectiveRange: &range) as? URL) != nil {
                    layoutManager.enumerateEnclosingRects(forGlyphRange: range, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: label.textContainer) { (rect, _) in
                        rects.append(rect)
                    }
                } else if let highlight = attributedText.attribute(NSAttributedString.Key.textHighlight, at: index, effectiveRange: &range) as? TextHighlight {
                    if (highlight.userInfo["url"] as? URL) != nil {
                        layoutManager.enumerateEnclosingRects(forGlyphRange: range, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: label.textContainer) { (rect, _) in
                            rects.append(rect)
                        }
                    }
                }
            }
        }
        return rects
    }

    func getConfigurationForTextView(_ label: TitleUITextView, _ location: CGPoint) -> UIContextMenuConfiguration? {
        let point = label.convert(location, from: self.contentView)

        var configuration: UIContextMenuConfiguration?
        var found = false
        if let attributedText = label.attributedText, let layoutManager = label.layoutManager as? BadgeLayoutManager, let textStorage = layoutManager.textStorage, !found {
            let characterRange = layoutManager.characterRange(forGlyphRange: NSRange(location: 0, length: attributedText.length), actualGlyphRange: nil)
            textStorage.enumerateAttributes(in: characterRange, options: .longestEffectiveRangeNotRequired) { (attrs, bgStyleRange, _) in
                for attr in attrs {
                    if let url = attr.value as? URL ?? (attr.value as? TextHighlight)?.userInfo["url"] as? URL {
                        let bgStyleGlyphRange = layoutManager.glyphRange(forCharacterRange: bgStyleRange, actualCharacterRange: nil)
                        layoutManager.enumerateLineFragments(forGlyphRange: bgStyleGlyphRange) { _, usedRect, textContainer, lineRange, _ in
                            let rangeIntersection = NSIntersectionRange(bgStyleGlyphRange, lineRange)
                            var rect = layoutManager.boundingRect(forGlyphRange: rangeIntersection, in: textContainer)
                            var baseline = 0
                            baseline = Int(truncating: textStorage.attribute(.baselineOffset, at: layoutManager.characterIndexForGlyph(at: bgStyleGlyphRange.location), effectiveRange: nil) as? NSNumber ?? 0)
                            
                            rect.origin.y = usedRect.origin.y + CGFloat(baseline / 2)
                            rect.size.height = usedRect.height - CGFloat(baseline) * 1.5
                            let insetTop = CGFloat.zero
                            
                            let offsetRect = rect.offsetBy(dx: 0, dy: insetTop)
                            if offsetRect.contains(point) {
                                configuration = self.getConfigurationFor(url: url)
                                found = true
                            }
                        }
                    }
                }
            }
        }
        
        return configuration
    }
    
    func getConfigurationFor(url: URL) -> UIContextMenuConfiguration {
        self.previewedURL = url
        return UIContextMenuConfiguration(identifier: nil, previewProvider: { [weak self] () -> UIViewController? in
            guard let self = self else { return nil }
            if url.absoluteString.starts(with: "/u/") {
                let vc = ProfilePreviewViewController(accountNamed: url.absoluteString.replacingOccurrences(of: "/u/", with: ""))
                self.previewedVC = vc
                
                return vc
            }
            if let vc = self.parent?.getControllerForUrl(baseUrl: url, link: SubmissionObject()) {
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
            if url.absoluteString.starts(with: "/u/") {
                let username = url.absoluteString.replacingOccurrences(of: "/u/", with: "")

                children.append(UIAction(title: "Visit profile", image: UIImage(sfString: SFSymbol.personFill, overrideString: "copy")!.menuIcon()) { _ in
                    VCPresenter.openRedditLink(url.absoluteString, self.parent?.navigationController, self.parent)
                })

                children.append(UIAction(title: "Send Message", image: UIImage(sfString: SFSymbol.personFill, overrideString: "copy")!.menuIcon()) { _ in
                    VCPresenter.openRedditLink("https://www.reddit.com/message/compose?to=\(username)", self.parent?.navigationController, self.parent)
                })

                children.append(UIAction(title: "Block user", image: UIImage(sfString: SFSymbol.personCropCircleBadgeXmark, overrideString: "copy")!.menuIcon(), attributes: UIMenuElement.Attributes.destructive, handler: { [weak self] (_) in
                    guard let self = self else { return }
                    if let parent = self.parent {
                        PostActions.block(username, parent: parent) {
                            
                        }
                    }
                }))

                return UIMenu(title: "u/\(username)", image: nil, identifier: nil, children: children)
            } else {
                children.append(UIAction(title: "Share URL", image: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")!.menuIcon()) { _ in
                    let shareItems: Array = [url]
                    let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.contentView
                    self.parent?.present(activityViewController, animated: true, completion: nil)
                })
                children.append(UIAction(title: "Copy URL", image: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()) { _ in
                    UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                    BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self.parent)
                })

                children.append(UIAction(title: "Open in default app", image: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) { _ in
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                })
                
                let open = OpenInChromeController.init()
                if open.isChromeInstalled() {
                    children.append(UIAction(title: "Open in Chrome", image: UIImage(named: "world")!.menuIcon()) { _ in
                        open.openInChrome(url, callbackURL: nil, createNewTab: true)
                    })
                }

                return UIMenu(title: "Link Options", image: nil, identifier: nil, children: children)
            }
        })
    }
    
    func getConfigurationParentComment() -> UIContextMenuConfiguration {
        
        guard let commentParent = parent else {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: nil)
        }
        
        if self.depth == 1 {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: nil)
        }
        
        commentParent.setAlphaOfBackgroundViews(alpha: 0.5)
        guard let indexPath = commentParent.tableView.indexPath(for: self) else {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: nil)
        }
        var topCell = (indexPath as NSIndexPath).row
        
        var contents = commentParent.content[commentParent.dataArray[topCell]]
        
        while (contents is CommentObject ? (contents as! CommentObject).depth >= self.depth : true) && commentParent.dataArray.count > topCell && topCell - 1 >= 0 {
            topCell -= 1
            contents = commentParent.content[commentParent.dataArray[topCell]]
        }

        let parentCell = CommentDepthCell(style: .default, reuseIdentifier: "test")
        
        if let comment = contents as? CommentObject {
            parentCell.contentView.layer.cornerRadius = 10
            parentCell.contentView.clipsToBounds = true
            parentCell.commentBody.ignoreHeight = false
            parentCell.commentBody.estimatedWidth = UIScreen.main.bounds.size.width * 0.85 - 36
            if contents is CommentObject {
                var count = 0
                let hiddenP = commentParent.hiddenPersons.contains(comment.id)
                if hiddenP {
                    count = commentParent.getChildNumber(n: comment.id)
                }
                var t = commentParent.text[comment.id]!
                if commentParent.isSearching {
                    t = commentParent.highlight(t)
                }
                
                parentCell.setComment(comment: contents as! CommentObject, depth: 0, parent: commentParent, hiddenCount: count, date: commentParent.lastSeen, author: commentParent.submission?.author, text: t, isCollapsed: hiddenP, parentOP: "", depthColors: commentParent.commentDepthColors, indexPath: indexPath, width: UIScreen.main.bounds.size.width * 0.85)
            } else {
                parentCell.setMore(more: (contents as! MoreObject), depth: commentParent.cDepth[comment.id]!, depthColors: commentParent.commentDepthColors, parent: commentParent)
            }
            parentCell.content = comment
            parentCell.contentView.isUserInteractionEnabled = false

            var size: CGSize!
            if let height = parentCell.title.attributedText?.height(containerWidth: UIScreen.main.bounds.size.width * 0.85) {
                size = CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: parentCell.commentBody.estimatedHeight + 24 + height)
            } else {
                size = CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: parentCell.commentBody.estimatedHeight + 24)
            }

            let detailViewController = ParentCommentViewController(view: parentCell.contentView, size: size)
            detailViewController.preferredContentSize = CGSize(width: size.width, height: min(size.height, 300))

            detailViewController.dismissHandler = {() in
                commentParent.setAlphaOfBackgroundViews(alpha: 1)
            }
            detailViewController.parentContext = comment.id
            self.previewedVC = detailViewController

            return UIContextMenuConfiguration(identifier: nil, previewProvider: { () -> UIViewController? in
                return detailViewController
            }, actionProvider: { (_) -> UIMenu? in
                
                return UIMenu(title: "Link Options", image: nil, identifier: nil, children: [])
            })

        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: nil)
    }
}
