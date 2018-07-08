//
//  ReplyViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/10/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import Photos
import MobileCoreServices
import SwiftyJSON
import Anchorage
import Then
import RealmSwift

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
    var toolbar: ToolbarTextView?
    var toReplyTo: Object?
    var replyingView: UIView?

    var scrollView = UIScrollView()

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
        self.messageCallback = { (message, error) in
            DispatchQueue.main.async {
                if (error != nil) {
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
                if (error != nil) {
                    if (error!.localizedDescription.contains("25")) {
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

    //Edit selftext
    init(submission: RSubmission, sub: String, completion: @escaping (Link?) -> Void) {
        type = .EDIT_SELFTEXT
        toReplyTo = submission
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: sub))
        self.submissionCallback = { (link, error) in
            DispatchQueue.main.async {
                if (error != nil) {
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
        type = .REPLY_SUBMISSION
        toReplyTo = submission
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: sub))
        self.commentReplyCallback = { (comment, error) in
            DispatchQueue.main.async {
                if (error != nil) {
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


    init(type: ReplyType, completion: @escaping (Link?) -> Void) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
        self.submissionCallback = { (link, error) in
            DispatchQueue.main.async {
                if (error != nil) {
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

    func textViewDidChange(_ textView: UITextView) {
        textView.sizeToFitHeight()
        var height = CGFloat(8)
        for textView in text! {
            height += CGFloat(8)
            height += textView.frame.size.height
        }
        print("Height is \(height)")
        scrollView.contentSize = CGSize.init(width: scrollView.frame.size.width, height: height)
    }

        //Create a new post
    convenience init(subreddit: String, type: ReplyType, completion: @escaping (Link?) -> Void) {
        self.init(type: type, completion: completion)
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        layoutForType()
    }

    @objc func keyboardWillShow(notification:NSNotification){
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)

        var contentInset:UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height + CGFloat(60)
        scrollView.contentInset = contentInset
    }

    @objc func keyboardWillHide(notification:NSNotification){

        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }


    func layoutForType() {
        self.scrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        self.scrollView.backgroundColor = .clear
        self.view.addSubview(scrollView)
        self.scrollView.backgroundColor = ColorUtil.backgroundColor
        self.scrollView.isUserInteractionEnabled = true

        let stack = UIStackView().then {
            $0.accessibilityIdentifier = "Reply Stack Vertical"
            $0.axis = .vertical
            $0.alignment = .center
            $0.distribution = .fill
            $0.spacing = 1
        }

        if (type.isMessage()) {
            if(type == .REPLY_MESSAGE){
                //two
                var text1 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 0, right: 8)
                    $0.isEditable = false
                })
                
                
                let html = (toReplyTo as! RMessage).htmlBody
                do {
                    let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                    let font = FontGenerator.fontOfSize(size: 16, submission: false)
                    let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: ColorUtil.baseAccent)
                    let content = LinkParser.parse(attr2, ColorUtil.accentColorForSub(sub: ""))
                    text1.attributedText = content
                } catch {
                    
                }

                var text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
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
                
                text1.topAnchor == stack.topAnchor + CGFloat(8)
                text1.bottomAnchor == text3.topAnchor - CGFloat(8)
                
                text3.heightAnchor >= CGFloat(70)
                text1.sizeToFitHeight()

                scrollView.addSubview(stack)
                stack.widthAnchor == scrollView.widthAnchor
                stack.verticalAnchors == scrollView.verticalAnchors
                
                text = [text1, text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self)
            } else {
                //three
                var text1 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                })
                
                var text2 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                })
                
                if (toReplyTo != nil) {
                    text1.text = "re: \((toReplyTo as! RMessage).subject)"
                    text1.isEditable = false
                    text2.text = ((toReplyTo as! RMessage).author)
                    text2.isEditable = false
                }
                
                text1.placeholder = "Subject"
                text2.placeholder = "User"
                
                
                var text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
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
                text1.heightAnchor == CGFloat(70)
                text2.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                text2.heightAnchor == CGFloat(70)
                text3.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                
                text1.topAnchor == stack.topAnchor + CGFloat(8)
                text1.bottomAnchor == text2.topAnchor - CGFloat(8)
                
                text2.bottomAnchor == text3.topAnchor - CGFloat(8)
                text3.heightAnchor >= CGFloat(70)
                
                scrollView.addSubview(stack)
                stack.widthAnchor == scrollView.widthAnchor
                stack.verticalAnchors == scrollView.verticalAnchors
                
                text = [text1, text2, text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self)
            }
        } else if (type.isSubmission()) {
            //three
            var text1 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.textColor = ColorUtil.fontColor
                $0.backgroundColor = ColorUtil.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
            })

            var text2 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.textColor = ColorUtil.fontColor
                $0.backgroundColor = ColorUtil.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
            })

            if (toReplyTo != nil) {
                text1.text = "\((toReplyTo as! RSubmission).title)"
                text1.isEditable = false
                text2.text = ((toReplyTo as! RSubmission).subreddit)
                text2.isEditable = false
            }

            text1.placeholder = "Title"
            text2.placeholder = "Subreddit"

            var text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
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
            text1.heightAnchor == CGFloat(70)
            text2.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
            text2.heightAnchor == CGFloat(70)
            text3.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)

            text1.topAnchor == stack.topAnchor + CGFloat(8)
            text1.bottomAnchor == text2.topAnchor - CGFloat(8)

            text2.bottomAnchor == text3.topAnchor - CGFloat(8)
            text3.heightAnchor >= CGFloat(70)

            scrollView.addSubview(stack)
            stack.widthAnchor == scrollView.widthAnchor
            stack.verticalAnchors == scrollView.verticalAnchors

            text = [text1, text2, text3]
            toolbar = ToolbarTextView.init(textView: text3, parent: self)
        } else if (type.isComment()) {
            if((toReplyTo as! RSubmission).type == .SELF){
                //two
                var text1 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.textColor = ColorUtil.fontColor
                    $0.backgroundColor = ColorUtil.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 0, right: 8)
                    $0.isEditable = false
                })
                
                
                let html = (toReplyTo as! RSubmission).htmlBody
                do {
                    let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                    let font = FontGenerator.fontOfSize(size: 16, submission: false)
                    let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: ColorUtil.baseAccent)
                    let content = LinkParser.parse(attr2, ColorUtil.accentColorForSub(sub: ""))
                    text1.attributedText = content
                } catch {
                    
                }
                
                var text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
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
                
                text1.topAnchor == stack.topAnchor + CGFloat(8)
                text1.bottomAnchor == text3.topAnchor - CGFloat(8)
                
                text3.heightAnchor >= CGFloat(70)
                text1.sizeToFitHeight()
                
                scrollView.addSubview(stack)
                stack.widthAnchor == scrollView.widthAnchor
                stack.verticalAnchors == scrollView.verticalAnchors
                
                text = [text1, text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self)
            } else {
                //one
                var text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
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
                
                stack.addArrangedSubviews(text3)
                text3.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)
                
                text3.topAnchor == stack.topAnchor + CGFloat(8)
                text3.heightAnchor >= CGFloat(70)
                
                scrollView.addSubview(stack)
                stack.widthAnchor == scrollView.widthAnchor
                stack.verticalAnchors == scrollView.verticalAnchors
                
                text = [text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self)
            }
    
        } else if (type.isEdit()) {
            //two
            var text1 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.textColor = ColorUtil.fontColor
                $0.backgroundColor = ColorUtil.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                $0.delegate = self
            })


            if (toReplyTo != nil) {
                text1.text = "\((toReplyTo as! RSubmission).title)"
                text1.isEditable = false
            }

            text1.placeholder = "Title"

            var text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
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
            text1.heightAnchor == CGFloat(70)
            text3.horizontalAnchors == stack.horizontalAnchors + CGFloat(8)

            text1.topAnchor == stack.topAnchor + CGFloat(8)
            text1.bottomAnchor == text3.topAnchor - CGFloat(8)

            text3.heightAnchor >= CGFloat(70)

            scrollView.addSubview(stack)
            stack.widthAnchor == scrollView.widthAnchor
            stack.verticalAnchors == scrollView.verticalAnchors

            text = [text1, text3]
            toolbar = ToolbarTextView.init(textView: text3, parent: self)
        }
        text!.last!.becomeFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (type.isMessage()) {
            title = "New message"
            if (type == ReplyType.REPLY_MESSAGE) {
                let author = (toReplyTo is RMessage) ? ((toReplyTo as! RMessage).author) : ((toReplyTo as! RSubmission).author)
                title = "Reply to \(author)"
            }
        } else {
            if (type == .EDIT_SELFTEXT) {
                title = "Editing"
            } else if (type.isComment()) {
                title = "Replying to \((toReplyTo as! RSubmission).author)"
            } else {
                title = "New submission"
            }
        }

        let send = UIButton.init(type: .custom)
        send.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        send.setImage(UIImage.init(named: "send")!.navIcon(), for: UIControlState.normal)
        send.addTarget(self, action: #selector(self.send(_:)), for: UIControlEvents.touchUpInside)
        send.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let sendB = UIBarButtonItem.init(customView: send)
        navigationItem.rightBarButtonItem = sendB

        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        button.setImage(UIImage.init(named: "close")!.navIcon(), for: UIControlState.normal)
        button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        button.addTarget(self, action: #selector(self.close(_:)), for: .touchUpInside)

        let barButton = UIBarButtonItem.init(customView: button)
        navigationItem.leftBarButtonItem = barButton
    }

    func close(_ sender: AnyObject) {
        let alert = UIAlertController.init(title: "Discard this \(type.isMessage() ? "message" : (type.isComment()) ? "comment" : "submission")?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .destructive, handler: { (action) in
            self.navigationController?.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel))
        present(alert, animated: true)
    }

    var alertController: UIAlertController?
    var session: Session?

    func getSubmissionEdited(_ name: String) {
        do {
            try self.session?.getInfo([name.contains("t3") ? name : "t3_\(name)"], completion: { (res) in
                switch res {
                case .failure:
                    print(res.error ?? "Error?")
                    self.submissionCallback(nil, res.error)
                    break
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

        if (title.text.isEmpty()) {
            BannerUtil.makeBanner(text: "Title cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }

        if (subreddit.text.isEmpty()) {
            BannerUtil.makeBanner(text: "Subreddit cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }

        if (body.text.isEmpty()) {
            BannerUtil.makeBanner(text: (type == .SUBMIT_LINK || type == .SUBMIT_IMAGE) ? "Link cannot be empty" : "Body cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }


        if (type == .EDIT_SELFTEXT) {
            alertController = UIAlertController(title: nil, message: "Editing submission...\n\n", preferredStyle: .alert)

            let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.black
            spinnerIndicator.startAnimating()

            alertController?.view.addSubview(spinnerIndicator)
            self.present(alertController!, animated: true, completion: nil)

            session = (UIApplication.shared.delegate as! AppDelegate).session

            do {
                let name = toReplyTo is RMessage ? (toReplyTo as! RMessage).getId() : toReplyTo is RComment ? (toReplyTo as! RComment).getId() : (toReplyTo as! RSubmission).getId()
                try self.session?.editCommentOrLink(name, newBody: body.text, completion: { (result) in
                    self.getSubmissionEdited(name)
                })
            } catch {
                print((error as NSError).description)
            }

        } else {
            alertController = UIAlertController(title: nil, message: "Posting submission...\n\n", preferredStyle: .alert)

            let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.black
            spinnerIndicator.startAnimating()

            alertController?.view.addSubview(spinnerIndicator)
            self.present(alertController!, animated: true, completion: nil)

            session = (UIApplication.shared.delegate as! AppDelegate).session

            do {
                if (type == .SUBMIT_TEXT) {
                    try self.session?.submitText(Subreddit.init(subreddit: subreddit.text), title: title.text, text: body.text, captcha: "", captchaIden: "", completion: { (result) -> Void in
                        switch result {
                        case .failure(let error):
                            print(error.description)
                            self.submissionCallback(nil, error)
                            break
                        case .success(let submission):
                            let string = self.getIDString(submission).value!
                            print("Got \(string)")
                            self.getSubmissionEdited(string)
                        }
                    })

                } else {
                    try self.session?.submitLink(Subreddit.init(subreddit: subreddit.text), title: title.text, URL: body.text, captcha: "", captchaIden: "", completion: { (result) -> Void in
                        switch result {
                        case .failure(let error):
                            print(error.description)
                            self.submissionCallback(nil, error)
                            break
                        case .success(let submission):
                            let string = self.getIDString(submission).value!
                            print("Got \(string)")
                            self.getSubmissionEdited(string)
                        }
                    })

                }
            } catch {
                print((error as NSError).description)
            }
        }
    }

    func submitMessage() {
        let title = text![0]
        let user = text![1]
        let body = text![2]

        if (title.text.isEmpty()) {
            BannerUtil.makeBanner(text: "Title cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }

        if (user.text.isEmpty()) {
            BannerUtil.makeBanner(text: "Recipient cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }

        if (body.text.isEmpty()) {
            BannerUtil.makeBanner(text: "Body cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }

        alertController = UIAlertController(title: nil, message: "Sending message...\n\n", preferredStyle: .alert)
        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()

        alertController?.view.addSubview(spinnerIndicator)
        self.present(alertController!, animated: true, completion: nil)

        session = (UIApplication.shared.delegate as! AppDelegate).session

        if (type == .NEW_MESSAGE) {
            do {
                try self.session?.composeMessage(user.text, subject: title.text, text: body.text, completion: { (result) in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        self.messageCallback(nil, error)
                        break
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
                try self.session?.replyMessage(body.text, parentName: name, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        self.messageCallback(nil, error)
                        break
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

        if (body.text.isEmpty()) {
            BannerUtil.makeBanner(text: "Body cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }

        alertController = UIAlertController(title: nil, message: "Posting comment...\n\n", preferredStyle: .alert)
        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
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
                    break
                case .success(let comment):
                    self.commentReplyCallback(comment, nil)
                }
            })
        } catch {
            print((error as NSError).description)
        }

    }

    func send(_ sender: AnyObject) {
        switch (type) {
        case .SUBMIT_IMAGE:
            fallthrough
        case .SUBMIT_LINK:
            fallthrough
        case .SUBMIT_TEXT:
            fallthrough
        case .EDIT_SELFTEXT:
            submitLink()
            break
        case .REPLY_SUBMISSION:
            submitComment()
            break
        case .NEW_MESSAGE:
            fallthrough
        case .REPLY_MESSAGE:
            submitMessage()
            break
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

    func dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

}

extension UIView {

    func embedInScrollView() -> UIView {
        let cont = UIScrollView()

        self.translatesAutoresizingMaskIntoConstraints = false;
        cont.translatesAutoresizingMaskIntoConstraints = false;
        cont.addSubview(self)
        cont.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[innerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["innerView": self]))
        cont.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[innerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["innerView": self]))
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
        let placeHolderLabel = self.viewWithTag(100)

        /* maybe...
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
        if (!placeholderImage.isEmpty) {
            text = text.substring(placeholderText.indexOf("]")! + 1, length: text.length - placeholderText.indexOf("]")! - 1)
        }

        placeholderLabel.text = " " + text
        placeholderLabel.font = UIFont.systemFont(ofSize: 14)
        placeholderLabel.textColor = ColorUtil.accentColorForSub(sub: "").withAlphaComponent(0.8)
        placeholderLabel.tag = 100
        if (!placeholderImage.isEmpty) {
            placeholderLabel.addImage(imageName: placeholderImage)
        }
        placeholderLabel.sizeToFit()
        placeholderLabel.frame.origin.x += 10
        placeholderLabel.frame.origin.y += 4

        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = ColorUtil.fontColor.cgColor

        border.frame = CGRect(x: 12, y: frame.size.height - width,
                width: frame.size.width - 24, height: frame.size.height)

        border.borderWidth = width

        layer.masksToBounds = true

        layer.addSublayer(border)


        // Hide the label if there is text in the text view
        placeholderLabel.isHidden = ((self.text.length) > 0)

        self.addSubview(placeholderLabel)
        self.delegate = self;
    }

}
