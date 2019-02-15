//
//  ReplyViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/10/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import MobileCoreServices
import Photos
import RealmSwift
import reddift
import SwiftyJSON
import Then
import YYText
import UIKit

class ReplyViewController: MediaViewController, UITextViewDelegate {

    public enum ReplyType {
        case NEW_MESSAGE
        case REPLY_MESSAGE
        case SUBMIT_IMAGE
        case SUBMIT_LINK
        case SUBMIT_TEXT
        case EDIT_SELFTEXT
        case REPLY_SUBMISSION

        func isEdit() -> Bool {
            return self == ReplyType.EDIT_SELFTEXT
        }

        func isComment() -> Bool {
            return self == ReplyType.REPLY_SUBMISSION
        }

        func isSubmission() -> Bool {
            return self == ReplyType.SUBMIT_IMAGE || self == ReplyType.SUBMIT_LINK || self == ReplyType.SUBMIT_TEXT || self == ReplyType.EDIT_SELFTEXT
        }

        func isMessage() -> Bool {
            return self == ReplyType.NEW_MESSAGE || self == ReplyType.REPLY_MESSAGE
        }
    }
    
    var type = ReplyType.NEW_MESSAGE
    var text: [UITextView]?
    var extras: [UIView]?
    var toolbar: ToolbarTextView?
    var toReplyTo: Object?
    var replyingView: UIView?
    var replyButtons: UIScrollView?
    var replies: UIStateButton?
    var distinguish: UIStateButton?
    var sticky: UIStateButton?
    var info: UIStateButton?

    var subreddit = ""
    var canMod = false
    var scrollView = UIScrollView()
    var username: String?

    //Callbacks
    var messageCallback: (Any?, Error?) -> Void = { (comment, error) in
    }

    var submissionCallback: (Link?, Error?) -> Void = { (link, error) in
    }

    var commentReplyCallback: (Comment?, Error?) -> Void = { (comment, error) in
    }

    //New message no reply
    init(completion: @escaping(String?) -> Void) {
        type = .NEW_MESSAGE
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: ""))
        self.messageCallback = { (message, error) in
            DispatchQueue.main.async {
                if error != nil {
                    self.toolbar?.saveDraft(self)
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your message has not been sent, please try again\n\nError:\(error!.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })
                } else {
                    self.alertController?.dismiss(animated: false, completion: {
                        self.dismiss(animated: true, completion: nil)
                        completion("")
                    })
                }
            }
        }
    }

    //New message with sub colors
    convenience init(name: String, completion: @escaping(String?) -> Void) {
        self.init(completion: completion)
        self.username = name
        setBarColors(color: ColorUtil.getColorForUser(name: name))
    }

    //New message reply
    init(message: RMessage?, completion: @escaping (String?) -> Void) {
        type = .REPLY_MESSAGE
        toReplyTo = message
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForUser(name: message!.author))
        self.messageCallback = { (message, error) in
            DispatchQueue.main.async {
                if error != nil {
                    if error!.localizedDescription.contains("25") {
                        self.alertController?.dismiss(animated: false, completion: {
                            self.dismiss(animated: true, completion: {
                                completion("")
                            })
                        })
                    } else {
                        self.toolbar?.saveDraft(self)
                        self.alertController?.dismiss(animated: false, completion: {
                            let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your message has not been sent, please try again\n\nError:\(error!.localizedDescription)", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        })
                    }
                } else {
                    self.alertController?.dismiss(animated: false, completion: {
                        self.dismiss(animated: true, completion: {
                            completion("")
                        })
                    })
                }
            }
        }
    }
    
    var errorText = ""

    //Edit selftext
    init(submission: RSubmission, sub: String, completion: @escaping (Link?) -> Void) {
        type = .EDIT_SELFTEXT
        toReplyTo = submission
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: sub))
        self.submissionCallback = { (link, error) in
            DispatchQueue.main.async {
                if error == nil && link == nil {
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Reddit did not allow this post to be made.\nError message: \(self.errorText)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })

                } else if error != nil {
                    self.toolbar?.saveDraft(self)
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your submission has not been edited (but has been saved as a draft), please try again\n\nError:\(error!.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })
                } else {
                    self.alertController?.dismiss(animated: false, completion: {
                        self.dismiss(animated: true, completion: {
                            completion(link)
                        })
                    })
                }
            }
        }
    }

    //Reply to submission
    init(submission: RSubmission, sub: String, delegate: ReplyDelegate) {
        subreddit = sub
        type = .REPLY_SUBMISSION
        self.canMod = AccountController.modSubs.contains(sub)
        toReplyTo = submission
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: sub))
        self.commentReplyCallback = { (comment, error) in
            DispatchQueue.main.async {
                if error != nil {
                    self.toolbar?.saveDraft(self)
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your comment has not been posted (but has been saved as a draft), please try again\n\nError:\(error!.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })
                } else {
                    self.alertController?.dismiss(animated: false, completion: {
                        self.dismiss(animated: true, completion: {
                            delegate.replySent(comment: comment, cell: nil)
                        })
                    })
                }
            }
        }
    }
    
    var modText: String?
    
    init(submission: RSubmission, sub: String, modMessage: String, completion: @escaping (Comment?) -> Void) {
        type = .REPLY_SUBMISSION
        toReplyTo = submission
        self.canMod = true
        super.init(nibName: nil, bundle: nil)
        self.modText = modMessage
        setBarColors(color: ColorUtil.getColorForSub(sub: sub))
        self.commentReplyCallback = { (comment, error) in
            DispatchQueue.main.async {
                if error == nil && comment == nil {
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Reddit did not allow this post to be made.\nError message: \(self.errorText)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })
                    
                } else if error != nil {
                    self.toolbar?.saveDraft(self)
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your submission has not been edited (but has been saved as a draft), please try again\n\nError:\(error!.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })
                } else {
                    self.alertController?.dismiss(animated: false, completion: {
                        self.dismiss(animated: true, completion: {
                            completion(comment)
                        })
                    })
                }
            }
        }
    }

    init(type: ReplyType, completion: @escaping (Link?) -> Void) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
        self.submissionCallback = { (link, error) in
            DispatchQueue.main.async {
                if error == nil && link == nil {
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Reddit did not allow this post to be made.\nError message: \(self.errorText)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })
                    
                } else if error != nil {
                    self.toolbar?.saveDraft(self)
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your post has not been created, please try again\n\nError:\(error!.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })
                } else {
                    self.alertController?.dismiss(animated: false, completion: {
                        self.dismiss(animated: true, completion: {
                            completion(link)
                        })
                    })
                }
            }
        }
    }

    /* This is probably broken*/
    @nonobjc func textViewDidChange(_ textView: UITextView) {
        textView.sizeToFitHeight()
        var height = CGFloat(8)
        for view in extras! {
            height += CGFloat(8)
            height += view.frame.size.height
        }
        for textView in text! {
            height += CGFloat(8)
            height += textView.frame.size.height
        }
        if replyButtons != nil {
            height += CGFloat(46)
        }
        scrollView.contentSize = CGSize.init(width: scrollView.frame.size.width, height: height)
    }

        //Create a new post
    convenience init(subreddit: String, type: ReplyType, completion: @escaping (Link?) -> Void) {
        self.init(type: type, completion: completion)
        self.subreddit = subreddit
        self.canMod = AccountController.modSubs.contains(subreddit)
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        layoutForType()
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        var userInfo = notification.userInfo!
        var keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)

        var contentInset: UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height + CGFloat(60)
        scrollView.contentInset = contentInset
    }

    @objc func keyboardWillHide(notification: NSNotification) {

        let contentInset: UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }
    
    func doButtons() {
        replyButtons = TouchUIScrollView().then {
            $0.accessibilityIdentifier = "Reply Extra Buttons"
        }
        
        replies = UIStateButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 30)).then {
            $0.layer.cornerRadius = 15
            $0.clipsToBounds = true
            $0.setTitle("Inbox replies on", for: .selected)
            $0.setTitle("Inbox replies off", for: .normal)
            $0.setTitleColor(GMColor.blue500Color(), for: .normal)
            $0.setTitleColor(.white, for: .selected)
            $0.titleLabel?.textAlignment = .center
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        }
        
        replies!.color = GMColor.blue500Color()
        replies!.isSelected = true
        replies!.addTarget(self, action: #selector(self.changeState(_:)), for: .touchUpInside)
        
        replies!.heightAnchor == CGFloat(30)
        let width = replies!.currentTitle!.size(with: replies!.titleLabel!.font).width + CGFloat(45)
        replies!.widthAnchor == width
        
        info = UIStateButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 30)).then {
            $0.layer.cornerRadius = 15
            $0.clipsToBounds = true
            $0.setTitle("Sidebar", for: .selected)
            $0.setTitle("Sidebar", for: .normal)
            $0.setTitleColor(GMColor.blue500Color(), for: .normal)
            $0.setTitleColor(.white, for: .selected)
            $0.titleLabel?.textAlignment = .center
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        }
        
        info!.color = GMColor.blue500Color()
        info!.isSelected = true
        info!.addTarget(self, action: #selector(self.info(_:)), for: .touchUpInside)
        
        info!.heightAnchor == CGFloat(30)
        let widthI = info!.currentTitle!.size(with: replies!.titleLabel!.font).width + CGFloat(45)
        info!.widthAnchor == widthI

         sticky = UIStateButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 45)).then {
            $0.layer.cornerRadius = 15
            $0.clipsToBounds = true
            $0.setTitle(type == .REPLY_SUBMISSION ? "Comment stickied": "Post stickied", for: .selected)
            $0.setTitle(type == .REPLY_SUBMISSION ? "Comment not stickied": "Post not stickied", for: .normal)
            $0.setTitleColor(GMColor.green500Color(), for: .normal)
            $0.setTitleColor(.white, for: .selected)
            $0.titleLabel?.textAlignment = .center
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        }
        
        sticky!.color = GMColor.green500Color()
        sticky!.isSelected = modText != nil
        sticky!.addTarget(self, action: #selector(self.changeState(_:)), for: .touchUpInside)
        
        sticky!.heightAnchor == CGFloat(30)
        let widthS = sticky!.currentTitle!.size(with: replies!.titleLabel!.font).width + CGFloat(45)
        sticky!.widthAnchor == widthS
        
        let buttonBase = UIStackView().then {
            $0.accessibilityIdentifier = "Reply VC Buttons"
            $0.axis = .horizontal
            $0.spacing = 8
        }

        buttonBase.addArrangedSubviews(info!, replies!, sticky!)
        
        var finalWidth = CGFloat(0)
        if type == .REPLY_SUBMISSION {
            info!.isHidden = true
            if canMod {
                finalWidth = CGFloat(8) + width + widthS
            } else {
                sticky!.isHidden = true
                finalWidth = width
            }
        } else {
            if canMod || (toReplyTo != nil && (toReplyTo as! RSubmission).canMod) {
                finalWidth = CGFloat(8 * 2) + width + widthI + widthS
            } else {
                sticky!.isHidden = true
                finalWidth = CGFloat(8) + width + widthI
            }
        }

        replyButtons!.addSubview(buttonBase)
        buttonBase.widthAnchor == finalWidth
        buttonBase.heightAnchor == CGFloat(30)
        buttonBase.leftAnchor == replyButtons!.leftAnchor
        buttonBase.verticalAnchors == replyButtons!.verticalAnchors
        replyButtons?.contentSize = CGSize.init(width: finalWidth, height: CGFloat(30))
    }
    
    @objc func changeState(_ sender: UIStateButton) {
        sender.isSelected = !sender.isSelected
    }

    @objc func info(_ sender: UIStateButton) {
        Sidebar.init(parent: self, subname: subreddit).displaySidebar()
    }

    func layoutForType() {
        self.scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        self.view.addSubview(scrollView)
        extras = [UIView]()
        self.scrollView.backgroundColor = ColorUtil.backgroundColor
        self.scrollView.isUserInteractionEnabled = true
        self.scrollView.contentInset = UIEdgeInsets.init(top: 8, left: 0, bottom: 0, right: 0)

        let stack = UIStackView().then {
            $0.accessibilityIdentifier = "Reply Stack Vertical"
            $0.axis = .vertical
            $0.alignment = .center
            $0.distribution = .fill
            $0.spacing = 8
        }
        
        if type.isMessage() {
            if type == .REPLY_MESSAGE {
                //two
                let text1 = YYLabel.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.clipsToBounds = true
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.numberOfLines = 0
                })
                extras?.append(text1)
                let html = (toReplyTo as! RMessage).htmlBody
                let content = TextDisplayStackView.createAttributedChunk(baseHTML: html, fontSize: 16, submission: false, accentColor: ColorUtil.baseAccent)
                
                /* todo this
                let activeLinkAttributes = NSMutableDictionary(dictionary: text1.activeLinkAttributes)
                activeLinkAttributes[kCTForegroundColorAttributeName] = ColorUtil.baseAccent
                text1.activeLinkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
                text1.linkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
*/
                text1.attributedText = content
                text1.highlightTapAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
                    text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, range, _) in
                        for attr in attrs {
                            if attr.value is YYTextHighlight {
                                if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                                    self.doShow(url: url, heroView: nil, heroVC: nil)
                                    return
                                }
                            }
                        }
                    })
                }
                text1.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
                text1.preferredMaxLayoutWidth = self.view.frame.size.width - 16

                let text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.placeholder = "Body"
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                    $0.delegate = self
                })
                
                stack.addArrangedSubviews(text1, text3)
                text1.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                text3.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                
                text3.heightAnchor >= CGFloat(70)

                scrollView.addSubview(stack)
                stack.widthAnchor == scrollView.widthAnchor
                stack.verticalAnchors == scrollView.verticalAnchors
                
                text = [text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self)
            } else {
                //three
                let text1 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.delegate = self
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                })
                
                let text2 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.textContainer.maximumNumberOfLines = 0
                    $0.delegate = self
                    $0.textContainer.lineBreakMode = .byTruncatingTail
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                })
                
                if toReplyTo != nil {
                    text1.text = "re: \((toReplyTo as! RMessage).subject.escapeHTML)"
                    text1.isEditable = false
                    text2.text = ((toReplyTo as! RMessage).author)
                    text2.isEditable = false
                }
                
                text1.placeholder = "Subject"
                text2.placeholder = "User"
                
                if username != nil {
                    text2.text = username!
                    text2.isEditable = false
                    if username!.contains("/r/") {
                        text2.placeholder = "Subreddit"
                    }
                }
                
                let text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.placeholder = "Body"
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                    $0.delegate = self
                })
                
                stack.addArrangedSubviews(text1, text2, text3)
                text1.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                text1.heightAnchor >= CGFloat(70)
                text2.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                text2.heightAnchor == CGFloat(70)
                text3.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                
                scrollView.addSubview(stack)
                stack.widthAnchor == scrollView.widthAnchor
                stack.verticalAnchors == scrollView.verticalAnchors
                
                text = [text1, text2, text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self)
            }
        } else if type.isSubmission() {
            //three
            let text1 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.textColor = ColorUtil.fontColor
                $0.backgroundColor = ColorUtil.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.delegate = self
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
            })

            let text2 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.textColor = ColorUtil.fontColor
                $0.backgroundColor = ColorUtil.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.textContainer.maximumNumberOfLines = 1
                $0.textContainer.lineBreakMode = .byTruncatingTail
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
            })

            if toReplyTo != nil {
                text1.text = "\((toReplyTo as! RSubmission).title)"
                text1.isEditable = false
                text2.text = ((toReplyTo as! RSubmission).subreddit)
                text2.isEditable = false
            }

            text1.placeholder = "Title"
            text2.placeholder = "Subreddit"
            
            if !subreddit.isEmpty() && subreddit != "all" && subreddit != "frontpage" && subreddit != "popular" && subreddit != "friends" && subreddit != "mod" && !subreddit.contains("m/") {
                text2.text = subreddit
                text2.isEditable = false
            }
            let text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.placeholder = "Body"
                $0.textColor = ColorUtil.fontColor
                $0.backgroundColor = ColorUtil.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                $0.delegate = self
            })
            
            if type != .SUBMIT_TEXT && type != .EDIT_SELFTEXT {
                text3.placeholder = "Link"
                text3.textContainer.maximumNumberOfLines = 1
                
                if type == .SUBMIT_IMAGE {
                    text3.addTapGestureRecognizer {
                        self.toolbar?.uploadImage(UIButton())
                    }
                    text3.placeholder = "Tap to choose an image"
                }
            }

            if type != .EDIT_SELFTEXT {
                doButtons()
                stack.addArrangedSubviews(text1, text2, replyButtons!, text3)
                replyButtons!.heightAnchor == CGFloat(30)
                replyButtons!.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
            } else {
                stack.addArrangedSubviews(text1, text2, text3)
                text3.text = (toReplyTo as! RSubmission).body
            }

            text1.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
            text1.heightAnchor >= CGFloat(70)
            text2.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
            text2.heightAnchor == CGFloat(70)
            text3.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)

            text3.heightAnchor >= CGFloat(70)

            scrollView.addSubview(stack)
            stack.widthAnchor == scrollView.widthAnchor
            stack.verticalAnchors == scrollView.verticalAnchors

            text = [text1, text2, text3]
            toolbar = ToolbarTextView.init(textView: text3, parent: self)
        } else if type.isComment() {
            if (toReplyTo as! RSubmission).type == .SELF {
                //two
                let text1 = YYLabel.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.clipsToBounds = true
                    $0.numberOfLines = 0
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                })
                extras?.append(text1)
                let html = (toReplyTo as! RSubmission).htmlBody
                let content = TextDisplayStackView.createAttributedChunk(baseHTML: html, fontSize: 16, submission: false, accentColor: ColorUtil.baseAccent)
                
                /* todo this
                let activeLinkAttributes = NSMutableDictionary(dictionary: text1.activeLinkAttributes)
                activeLinkAttributes[kCTForegroundColorAttributeName] = ColorUtil.baseAccent
                text1.activeLinkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
                text1.linkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
*/
                
                text1.attributedText = content
                text1.highlightTapAction = { (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
                    text.enumerateAttributes(in: range, options: .longestEffectiveRangeNotRequired, using: { (attrs, range, _) in
                        for attr in attrs {
                            if attr.value is YYTextHighlight {
                                if let url = (attr.value as! YYTextHighlight).userInfo?["url"] as? URL {
                                    self.doShow(url: url, heroView: nil, heroVC: nil)
                                    return
                                }
                            }
                        }
                    })
                }
                text1.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
                text1.preferredMaxLayoutWidth = self.view.frame.size.width - 16

                let text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.placeholder = "Body"
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                    $0.delegate = self
                })
                
                if modText != nil {
                    text3.text = "Hi u/\((toReplyTo as! RSubmission).author),\n\nYour submission has been removed for the following reason:\n\n\(modText!.replacingOccurrences(of: "\n", with: "\n\n"))\n\n"
                }
                doButtons()
                stack.addArrangedSubviews(text1, replyButtons!, text3)
                replyButtons!.heightAnchor == CGFloat(30)
                replyButtons!.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)

                stack.addArrangedSubviews(text1, text3)
                text1.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                text3.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                
                text3.heightAnchor >= CGFloat(70)
//                text1.sizeToFitHeight()
                
                scrollView.addSubview(stack)
                stack.widthAnchor == scrollView.widthAnchor
                stack.verticalAnchors == scrollView.verticalAnchors
                
                text = [text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self)
            } else {
                //one
                let text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.placeholder = "Body"
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                    $0.delegate = self
                })
                
                if modText != nil {
                    text3.text = "Hi u/\((toReplyTo as! RSubmission).author),\n\nYour submission has been removed for the following reason:\n\n\(modText!.replacingOccurrences(of: "\n", with: "\n\n"))\n\n"
                }

                doButtons()
                stack.addArrangedSubviews(replyButtons!, text3)
                replyButtons!.heightAnchor == CGFloat(30)
                replyButtons!.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                text3.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                
                text3.heightAnchor >= CGFloat(70)
                
                scrollView.addSubview(stack)
                stack.widthAnchor == scrollView.widthAnchor
                stack.verticalAnchors == scrollView.verticalAnchors
                
                text = [text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self)
            }
    
        } else if type.isEdit() {
            //two
            let text1 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.textColor = ColorUtil.fontColor
                $0.backgroundColor = ColorUtil.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.delegate = self
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
            })

            if toReplyTo != nil {
                text1.text = "\((toReplyTo as! RSubmission).title)"
                text1.isEditable = false
            }

            text1.placeholder = "Title"

            let text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.placeholder = "Body"
                $0.textColor = ColorUtil.fontColor
                $0.backgroundColor = ColorUtil.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                $0.delegate = self
                $0.text = (toReplyTo as! RSubmission).body
            })

            stack.addArrangedSubviews(text1, text3)
            text1.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
            text1.heightAnchor >= CGFloat(70)
            text3.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)

            text3.heightAnchor >= CGFloat(70)

            scrollView.addSubview(stack)
            stack.widthAnchor == scrollView.widthAnchor
            stack.verticalAnchors == scrollView.verticalAnchors

            text = [text1, text3]
            toolbar = ToolbarTextView.init(textView: text3, parent: self)
        }
        var first = false
        for textField in text! {
            if textField.isEditable && !first {
                first = true
                textField.becomeFirstResponder()
            }
            if ColorUtil.theme != .LIGHT {
                textField.keyboardAppearance = .dark
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if type.isMessage() {
            title = "New message"
            if type == ReplyType.REPLY_MESSAGE {
                let author = (toReplyTo is RMessage) ? ((toReplyTo as! RMessage).author) : ((toReplyTo as! RSubmission).author)
                title = "Reply to \(author)"
            }
        } else {
            if type == .EDIT_SELFTEXT {
                title = "Editing"
            } else if type.isComment() {
                title = "Replying to \((toReplyTo as! RSubmission).author)"
            } else {
                title = "New submission"
            }
        }

        let send = UIButton.init(type: .custom)
        send.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        send.setImage(UIImage.init(named: "send")!.navIcon(), for: UIControl.State.normal)
        send.addTarget(self, action: #selector(self.send(_:)), for: UIControl.Event.touchUpInside)
        send.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        send.accessibilityLabel = "Send"
        let sendB = UIBarButtonItem.init(customView: send)
        navigationItem.rightBarButtonItem = sendB

        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.setImage(UIImage.init(named: "close")!.navIcon(), for: UIControl.State.normal)
        button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        button.accessibilityLabel = "Close"
        button.addTarget(self, action: #selector(self.close(_:)), for: .touchUpInside)

        let barButton = UIBarButtonItem.init(customView: button)
        navigationItem.leftBarButtonItem = barButton
    }

    @objc func close(_ sender: AnyObject) {
        let alert = UIAlertController.init(title: "Discard this \(type.isMessage() ? "message" : (type.isComment()) ? "comment" : type.isEdit() ? "edit" : "submission")?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .destructive, handler: { (_) in
            if self.navigationController?.viewControllers.count ?? 1 == 1 {
                self.navigationController?.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel))
        present(alert, animated: true)
    }

    var alertController: UIAlertController?
    var session: Session?

    func getSubmissionEdited(_ name: String) {
        DispatchQueue.main.async {
            if (self.type == .SUBMIT_LINK || self.type == .SUBMIT_IMAGE || self.type == .SUBMIT_TEXT) && self.sticky != nil && self.sticky!.isSelected {
                do {
                    try self.session?.sticky("t3_\(name)", sticky: true, completion: { (_) in
                        self.completeGetSubmission(name)
                    })
                } catch {
                    self.completeGetSubmission(name)
                }
            } else {
                self.completeGetSubmission(name)
            }
        }
    }
    
    var doneOnce = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if type == .SUBMIT_IMAGE && !doneOnce {
            toolbar?.uploadImage(UIButton())
            doneOnce = true
        }
    }
    
    func completeGetSubmission(_ name: String) {
        do {
            try self.session?.getInfo([name.contains("t3") ? name : "t3_\(name)"], completion: { (res) in
                switch res {
                case .failure:
                    print(res.error ?? "Error?")
                    self.submissionCallback(nil, res.error)
                case .success(let listing):
                    if listing.children.count == 1 {
                        if let submission = listing.children[0] as? Link {
                            self.submissionCallback(submission, nil)
                        }
                    }
                }
                
            })
        } catch {
            //todo success but null child
            self.submissionCallback(nil, error)
        }
    }

    var triedOnce = false

    func submitLink() {
        let title = text![0]
        let subreddit = text![1]
        let body = text![2]

        if title.text.isEmpty() {
            BannerUtil.makeBanner(text: "Title cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }

        if subreddit.text.isEmpty() {
            BannerUtil.makeBanner(text: "Subreddit cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }

        if body.text.isEmpty() && (type == .SUBMIT_LINK || type == .SUBMIT_IMAGE) {
            BannerUtil.makeBanner(text: (type == .SUBMIT_LINK || type == .SUBMIT_IMAGE) ? "Link cannot be empty" : "Body cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }

        if type == .EDIT_SELFTEXT {
            alertController = UIAlertController(title: nil, message: "Editing submission...\n\n", preferredStyle: .alert)

            let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.black
            spinnerIndicator.startAnimating()

            alertController?.view.addSubview(spinnerIndicator)
            self.present(alertController!, animated: true, completion: nil)

            session = (UIApplication.shared.delegate as! AppDelegate).session

            do {
                let name = toReplyTo is RMessage ? (toReplyTo as! RMessage).getId() : toReplyTo is RComment ? (toReplyTo as! RComment).getId() : (toReplyTo as! RSubmission).getId()
                try self.session?.editCommentOrLink(name, newBody: body.text, completion: { (_) in
                    self.getSubmissionEdited(name)
                })
            } catch {
                print((error as NSError).description)
            }

        } else {
            alertController = UIAlertController(title: nil, message: "Posting submission...\n\n", preferredStyle: .alert)

            let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.black
            spinnerIndicator.startAnimating()

            alertController?.view.addSubview(spinnerIndicator)
            self.present(alertController!, animated: true, completion: nil)

            session = (UIApplication.shared.delegate as! AppDelegate).session

            do {
                if type == .SUBMIT_TEXT {
                    try self.session?.submitText(Subreddit.init(subreddit: subreddit.text), title: title.text, text: body.text, sendReplies: replies!.isSelected, captcha: "", captchaIden: "", completion: { (result) -> Void in
                        switch result {
                        case .failure(let error):
                            print(error.description)
                            self.submissionCallback(nil, error)
                        case .success(let submission):
                            if let string = self.getIDString(submission).value {
                                self.getSubmissionEdited(string)
                            } else {
                                self.errorText = self.getError(submission)
                                self.submissionCallback(nil, nil)
                            }
                        }
                    })

                } else {
                    try self.session?.submitLink(Subreddit.init(subreddit: subreddit.text), title: title.text, URL: body.text, sendReplies: replies!.isSelected, captcha: "", captchaIden: "", completion: { (result) -> Void in
                        switch result {
                        case .failure(let error):
                            print(error.description)
                            self.submissionCallback(nil, error)
                        case .success(let submission):
                            if let string = self.getIDString(submission).value {
                                self.getSubmissionEdited(string)
                            } else {
                                self.errorText = self.getError(submission)
                                self.submissionCallback(nil, nil)
                            }
                        }
                    })

                }
            } catch {
                print((error as NSError).description)
            }
        }
    }

    func submitMessage() {
        let body: String
        let user: String
        let title: String
        if self.type == .REPLY_MESSAGE {
            body = text![text!.count - 1].text
            title = ""
            user = ""
            
            if body.isEmpty() {
                BannerUtil.makeBanner(text: "Body cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
                return
            }
        } else {
            title = text![0].text
            user = text![1].text
            body = text![2].text
            
            if title.isEmpty() {
                BannerUtil.makeBanner(text: "Title cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
                return
            }
            
            if user.isEmpty() {
                BannerUtil.makeBanner(text: "Recipient cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
                return
            }
            
            if body.isEmpty() {
                BannerUtil.makeBanner(text: "Body cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
                return
            }
        }

        alertController = UIAlertController(title: nil, message: "Sending message...\n\n", preferredStyle: .alert)
        let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()

        alertController?.view.addSubview(spinnerIndicator)
        self.present(alertController!, animated: true, completion: nil)

        session = (UIApplication.shared.delegate as! AppDelegate).session

        if type == .NEW_MESSAGE {
            do {
                try self.session?.composeMessage(user, subject: title, text: body, completion: { (result) in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        self.messageCallback(nil, error)
                    case .success(let message):
                        self.messageCallback(message, nil)
                    }

                })
            } catch {
                print((error as NSError).description)
            }
        } else {
            do {
                let name = toReplyTo!.getIdentifier()
                try self.session?.replyMessage(body, parentName: name, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        self.messageCallback(nil, error)
                    case .success(let comment):
                        self.messageCallback(comment, nil)
                    }
                })
            } catch {
                print((error as NSError).description)
            }
        }
    }

    func submitComment() {
        let body = text!.last!

        alertController = UIAlertController(title: nil, message: "Posting comment...\n\n", preferredStyle: .alert)
        let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()

        alertController?.view.addSubview(spinnerIndicator)
        self.present(alertController!, animated: true, completion: nil)

        session = (UIApplication.shared.delegate as! AppDelegate).session

        do {
            let name = toReplyTo!.getIdentifier()
            try self.session?.postComment(body.text, parentName: name, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    self.commentReplyCallback(nil, error)
                case .success(let comment):
                    self.checkSticky(comment)
                }
            })
        } catch {
            print((error as NSError).description)
        }
    }
    
    func checkSticky(_ comment: Comment) {
        DispatchQueue.main.async {
            if self.sticky != nil && self.sticky!.isSelected {
                do {
                    try self.session?.distinguish(comment.getId(), how: "yes", sticky: true, completion: { (_) -> Void in
                        var newComment = comment
                        newComment.stickied = true
                        newComment.distinguished = .moderator
                        self.checkReplies(newComment)
                    })
                } catch {
                    self.checkReplies(comment)
                }
            } else {
                self.checkReplies(comment)
            }
        }
    }
    
    func checkReplies(_ comment: Comment) {
        DispatchQueue.main.async {
            if self.replies != nil && !self.replies!.isSelected {
                do {
                    try self.session?.setReplies(false, name: comment.getId(), completion: { (_) in
                        self.commentReplyCallback(comment, nil)
                    })
                } catch {
                    self.commentReplyCallback(comment, nil)
                }
            } else {
                self.commentReplyCallback(comment, nil)
            }
        }
    }

    @objc func send(_ sender: AnyObject) {
        switch type {
        case .SUBMIT_IMAGE:
            fallthrough
        case .SUBMIT_LINK:
            fallthrough
        case .SUBMIT_TEXT:
            fallthrough
        case .EDIT_SELFTEXT:
            submitLink()
        case .REPLY_SUBMISSION:
            submitComment()
        case .NEW_MESSAGE:
            fallthrough
        case .REPLY_MESSAGE:
            submitMessage()
        }
    }

    func getIDString(_ json: JSONAny) -> reddift.Result<String> {
        if let json = json as? JSONDictionary {
            if let j = json["json"] as? JSONDictionary {
                if let data = j["data"] as? JSONDictionary {
                    if let iden = data["id"] as? String {
                        return Result(value: iden)
                    }
                }
            }
        }
        return Result(error: ReddiftError.identifierOfCAPTCHAIsMalformed as NSError)
    }
    
    func getError(_ json: JSONAny) -> String {
        if let json = json as? JSONDictionary {
            if let j = json["json"] as? JSONDictionary {
                if let data = j["errors"] as? JSONArray {
                    if let iden = data[0] as? JSONArray {
                        if  iden.count >= 2 {
                            return "\(iden[0]): \(iden[1])"
                        } else {
                            return "\(iden[0])"
                        }
                    }
                }
            }
        }
        return ""
    }
    
    @objc func dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

}

extension UIView {

    func embedInScrollView() -> UIView {
        let cont = UIScrollView()

        self.translatesAutoresizingMaskIntoConstraints = false
        cont.translatesAutoresizingMaskIntoConstraints = false
        cont.addSubview(self)
        cont.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[innerView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["innerView": self]))
        cont.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[innerView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["innerView": self]))
        cont.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: cont, attribute: .width, multiplier: 1.0, constant: 0))
        return cont
    }
}

extension UITextView: UITextViewDelegate {

    // Placeholder text
    var placeholder: String? {

        get {
            // Get the placeholder text from the label
            var placeholderText: String?

            if let placeHolderLabel = self.viewWithTag(100) as? UILabel {
                placeholderText = placeHolderLabel.text
            }
            return placeholderText
        }

        set {
            // Store the placeholder text in the label
            let placeHolderLabel = self.viewWithTag(100) as! UILabel?
            if placeHolderLabel == nil {
                // Add placeholder label to text view
                self.addPlaceholderLabel(placeholderText: newValue!)
            } else {
                placeHolderLabel?.text = newValue
                placeHolderLabel?.sizeToFit()
            }
        }
    }

    // Hide the placeholder label if there is no text
    // in the text viewotherwise, show the label
    public func textViewDidChange(_ textView: UITextView) {
        /* maybe...
        let placeHolderLabel = self.viewWithTag(100)

        UIView.animate(withDuration: 0.15, delay: 0.0, options:
        UIViewAnimationOptions.curveEaseOut, animations: {
            if !self.hasText {
                // Get the placeholder label
                placeHolderLabel?.alpha = 1
            } else {
                placeHolderLabel?.alpha = 0
            }
        }, completion: { finished in
        })*/

    }

    // Add a placeholder label to the text view
    func addPlaceholderLabel(placeholderText: String) {

        // Create the label and set its properties
        let placeholderLabel = UILabel()
        let placeholderImage = placeholderText.startsWith("[") ? placeholderText.substring(1, length: placeholderText.indexOf("]")! - 1) : ""
        var text = placeholderText
        if !placeholderImage.isEmpty {
            text = text.substring(placeholderText.indexOf("]")! + 1, length: text.length - placeholderText.indexOf("]")! - 1)
        }

        placeholderLabel.text = " " + text
        placeholderLabel.font = UIFont.systemFont(ofSize: 14)
        placeholderLabel.textColor = ColorUtil.accentColorForSub(sub: "").withAlphaComponent(0.8)
        placeholderLabel.tag = 100
        if !placeholderImage.isEmpty {
            placeholderLabel.addImage(imageName: placeholderImage)
        }
        placeholderLabel.sizeToFit()
        placeholderLabel.frame.origin.x += 10
        placeholderLabel.frame.origin.y += 4

        // Hide the label if there is text in the text view
        placeholderLabel.isHidden = ((self.text.length) > 0)

        self.addSubview(placeholderLabel)
        self.delegate = self
    }

}

public class UIStateButton: UIButton {
    var color = UIColor.white
    override open var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? color : ColorUtil.foregroundColor
            self.layer.borderColor = color .cgColor
            self.layer.borderWidth = isSelected ? CGFloat(0) : CGFloat(2)
        }
    }
}
