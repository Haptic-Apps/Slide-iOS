//
//  ReplyViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/10/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Alamofire
import Anchorage
import CoreData
import MobileCoreServices
import Photos
import reddift
import SDCAlertView
import SwiftyJSON
import Then
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
        case CROSSPOST

        func isEdit() -> Bool {
            return self == ReplyType.EDIT_SELFTEXT
        }

        func isComment() -> Bool {
            return self == ReplyType.REPLY_SUBMISSION
        }

        func isSubmission() -> Bool {
            return self == ReplyType.SUBMIT_IMAGE || self == ReplyType.SUBMIT_LINK || self == ReplyType.SUBMIT_TEXT || self == ReplyType.EDIT_SELFTEXT || self == ReplyType.CROSSPOST
        }

        func isMessage() -> Bool {
            return self == ReplyType.NEW_MESSAGE || self == ReplyType.REPLY_MESSAGE
        }
    }
    
    var type = ReplyType.NEW_MESSAGE
    var text: [UITextView]?
    var extras: [UIView]?
    var toolbar: ToolbarTextView?
    var toReplyTo: RedditObject?
    var replyingView: UIView?
    var replyButtons: UIScrollView?
    var replies: UIStateButton?
    var account: UIStateButton?
    var distinguish: UIStateButton?
    var sticky: UIStateButton?
    var info: UIStateButton?
    var ruleLabel = UITextView()
    
    var chosenAccount: String?

    var subject: String?
    var message: String?

    var subreddit = ""
    var isMod = false
    var scrollView = UIScrollView()
    var username: String?

    // Callbacks
    var messageCallback: (Any?, Error?) -> Void = { (_, _) in
    }

    var submissionCallback: (Link?, Error?) -> Void = { (_, _) in
    }

    var commentReplyCallback: (Comment?, Error?) -> Void = { (_, _) in
    }

    // New message no reply
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

    // New message with sub colors
    convenience init(name: String, completion: @escaping(String?) -> Void) {
        self.init(completion: completion)
        self.username = name
        setBarColors(color: ColorUtil.getColorForUser(name: name))
    }
    
    // New message with sub colors
    convenience init(name: String, subject: String, message: String, completion: @escaping(String?) -> Void) {
        self.init(completion: completion)
        self.subject = subject.isEmpty ? nil : subject
        self.message = message.isEmpty ? nil : message
        self.username = name.isEmpty ? nil : name
        setBarColors(color: ColorUtil.getColorForUser(name: name))
    }

    // New message reply
    init(message: MessageObject?, completion: @escaping (String?) -> Void) {
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

    // Edit selftext
    init(submission: SubmissionObject, sub: String, completion: @escaping (Link?) -> Void) {
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
    
    // Crosspost
    init(submission: SubmissionObject, completion: @escaping (Link?) -> Void) {
        type = .CROSSPOST
        toReplyTo = submission
        super.init(nibName: nil, bundle: nil)
        subject = submission.title
        setBarColors(color: ColorUtil.getColorForSub(sub: submission.subreddit))
        self.submissionCallback = { (link, error) in
            DispatchQueue.main.async {
                if error == nil && link == nil {
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Reddit did not allow this post to be made.\nError message: \(self.errorText)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })
                    
                } else if error != nil {
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Reddit did not allow this post to be made.\n\nError message:\(error!.localizedDescription)", preferredStyle: .alert)
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

    // Reply to submission
    init(submission: SubmissionObject, sub: String, delegate: ReplyDelegate) {
        subreddit = sub
        type = .REPLY_SUBMISSION
        self.isMod = AccountController.modSubs.contains(sub)
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
    
    init(submission: SubmissionObject, sub: String, modMessage: String, completion: @escaping (Comment?) -> Void) {
        type = .REPLY_SUBMISSION
        toReplyTo = submission
        self.isMod = true
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
    
    var crosspostHeight = CGFloat(0)

    var lastLength = 0
    /* This is probably broken*/
    @objc func textViewDidChange(_ textView: UITextView) {
        textView.sizeToFitHeight()
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
        
        if #available(iOS 13, *), !textView.text.isEmpty {
            self.isModalInPresentation = true
        }
        
        redoHeights()
        lastLength = textView.text.length
    }
    
    func redoHeights() {
        var height = CGFloat(8)
        for view in extras! {
            height += CGFloat(8)
            height += view.frame.size.height
        }
        for textView in text! {
            height += CGFloat(8)
            height += textView.frame.size.height
        }
        
        if !(ruleLabel.attributedText?.length == 0) {
            height += CGFloat(8)
            height += ruleLabel.frame.size.height
        }

        height += CGFloat(8)
        height += crosspostHeight
        
        if replyButtons != nil {
            height += CGFloat(46)
        }
        
        height += 40 // Toolbar height
        
        scrollView.contentSize = CGSize.init(width: scrollView.frame.size.width, height: height)
    }

    // Create a new post
    convenience init(subreddit: String, type: ReplyType, completion: @escaping (Link?) -> Void) {
        self.init(type: type, completion: completion)
        self.subreddit = subreddit
        self.isMod = AccountController.modSubs.contains(subreddit)
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo!
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
        
        if replyButtons != nil {
            for view in replyButtons!.subviews {
                view.removeFromSuperview()
            }
        } else {
            replyButtons = TouchUIScrollView().then {
                $0.accessibilityIdentifier = "Reply Extra Buttons"
            }
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
        
        replies!.heightAnchor /==/ CGFloat(30)
        let width = replies!.currentTitle!.size(with: replies!.titleLabel!.font).width + CGFloat(45)
        replies!.widthAnchor /==/ width
        
        account = UIStateButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 30)).then {
            $0.layer.cornerRadius = 15
            $0.clipsToBounds = true
            $0.setTitle("Posting as u/\(self.chosenAccount ?? AccountController.currentName)", for: .selected)
            $0.setTitle("Posting as u/\(self.chosenAccount ?? AccountController.currentName)", for: .normal)
            $0.setTitleColor(GMColor.blue500Color(), for: .normal)
            $0.setTitleColor(.white, for: .selected)
            $0.titleLabel?.textAlignment = .center
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        }
        
        account!.color = GMColor.blue500Color()
        account!.isSelected = true
        account!.addTarget(self, action: #selector(self.chooseAccount), for: .touchUpInside)
        
        account!.heightAnchor /==/ CGFloat(30)
        let widthA = account!.currentTitle!.size(with: account!.titleLabel!.font).width + CGFloat(45)
        account!.widthAnchor /==/ width

        info = UIStateButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 30)).then {
            $0.layer.cornerRadius = 15
            $0.clipsToBounds = true
            $0.setTitle("Subreddit sidebar", for: .selected)
            $0.setTitle("Subreddit sidebar", for: .normal)
            $0.setTitleColor(GMColor.blue500Color(), for: .normal)
            $0.setTitleColor(.white, for: .selected)
            $0.titleLabel?.textAlignment = .center
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        }
        
        info!.color = GMColor.blue500Color()
        info!.isSelected = true
        info!.addTarget(self, action: #selector(self.info(_:)), for: .touchUpInside)
        
        info!.heightAnchor /==/ CGFloat(30)
        let widthI = info!.currentTitle!.size(with: replies!.titleLabel!.font).width + CGFloat(45)
        info!.widthAnchor /==/ widthI

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
        
        sticky!.heightAnchor /==/ CGFloat(30)
        let widthS = sticky!.currentTitle!.size(with: replies!.titleLabel!.font).width + CGFloat(45)
        sticky!.widthAnchor /==/ widthS
        
        let buttonBase = UIStackView().then {
            $0.accessibilityIdentifier = "Reply VC Buttons"
            $0.axis = .horizontal
            $0.spacing = 8
        }

        buttonBase.addArrangedSubviews(account!, info!, replies!, sticky!)
        
        var finalWidth = CGFloat(0)
        if type == .REPLY_SUBMISSION {
            info!.isHidden = true
            if isMod {
                finalWidth = CGFloat(8) + width + widthS
            } else {
                sticky!.isHidden = true
                finalWidth = width
            }
        } else {
            if isMod || (toReplyTo != nil && (toReplyTo as! SubmissionObject).isMod) {
                finalWidth = CGFloat(8 * 2) + width + widthI + widthS
            } else {
                sticky!.isHidden = true
                finalWidth = CGFloat(8) + width + widthI
            }
        }
        
        finalWidth += CGFloat(widthA + CGFloat(8))

        replyButtons!.addSubview(buttonBase)
        buttonBase.heightAnchor /==/ CGFloat(30)
        buttonBase.edgeAnchors /==/ replyButtons!.edgeAnchors
        buttonBase.centerYAnchor /==/ replyButtons!.centerYAnchor
        replyButtons?.contentSize = CGSize.init(width: finalWidth, height: CGFloat(30))
        replyButtons?.alwaysBounceHorizontal = true
        replyButtons?.showsHorizontalScrollIndicator = false

        if type == .SUBMIT_LINK || type == .SUBMIT_TEXT || type == .SUBMIT_IMAGE || type == .CROSSPOST {
            do {
                if let session = (UIApplication.shared.delegate as? AppDelegate)?.session, let token = session.token {
                    self.session = session
                    try session.ruleList(subreddit, completion: { (result) in
                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(let rules):
                            var ruleString = NSMutableAttributedString()
                            let newLine = NSAttributedString(string: "\n")
                            let titleAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.fontColor]
                            let bodyAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15), NSAttributedString.Key.foregroundColor: UIColor.fontColor]
                            var ruleNumber = 1
                            for rule in rules {
                                if rule.kind == "link" || rule.kind == "all" {
                                    ruleString.append(NSMutableAttributedString(string: "\(ruleNumber). \(rule.shortName)", attributes: titleAttributes))
                                    ruleString.append(newLine)
                                    ruleString.append(NSMutableAttributedString(string: rule.description, attributes: bodyAttributes))
                                    ruleString.append(newLine)
                                    ruleString.append(newLine)
                                    ruleNumber += 1
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.ruleLabel.attributedText = ruleString
                                self.ruleLabel.sizeToFit()
                                self.redoHeights()
                                self.ruleLabel.placeholder = "r/\(self.subreddit) rules"
                            }
                        }
                    })
                    
                    let requestString = "https://oauth.reddit.com/r/\(subreddit)/api/link_flair_v2.json"
                    AF.request(requestString, method: .get, headers: ["Authorization": "bearer \(token.accessToken)"]).responseString { [weak self] response in
                        guard let self = self else { return }
                        do {
                            guard let data = response.data else {
                                return
                            }
                            self.availableFlairs = []
                            
                            let json = try JSON(data: data)
                            if let flairs = json.array {
                                for item in flairs {
                                    if let richtext = item["richtext"].array?.first {
                                        let flair = FlairObject()
                                        
                                        flair.image = richtext["u"].stringValue
                                        flair.text = richtext["t"].stringValue
                                        flair.iconText = richtext["a"].stringValue
                                        flair.title = item["text"].stringValue
                                        flair.id = item["id"].stringValue
                                        flair.editable = item["text_editable"].boolValue
                                        
                                        self.availableFlairs.append(flair)
                                    } else {
                                        let flair = FlairObject()
                                        
                                        flair.image = ""
                                        flair.text = item["text"].stringValue
                                        flair.iconText = ""
                                        flair.title = item["text"].stringValue
                                        flair.id = item["id"].stringValue
                                        flair.editable = item["text_editable"].boolValue
                                        
                                        self.availableFlairs.append(flair)
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    if !self.availableFlairs.isEmpty {
                                        DispatchQueue.main.async {
                                            let flairs = UIStateButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 45)).then {
                                                $0.layer.cornerRadius = 15
                                                $0.clipsToBounds = true
                                                $0.setTitle("Submission flair", for: .selected)
                                                $0.setTitle("Submission flair", for: .normal)
                                                $0.setTitleColor(.white, for: .normal)
                                                $0.setTitleColor(.white, for: .selected)
                                                $0.titleLabel?.textAlignment = .center
                                                $0.backgroundColor = ColorUtil.getColorForSub(sub: self.subreddit)
                                                $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                                            }
                                            flairs.addTarget(self, action: #selector(self.flairs(_:)), for: .touchUpInside)
                                            let widthF = flairs.currentTitle!.size(with: flairs.titleLabel!.font).width + CGFloat(45)
                                            flairs.widthAnchor /==/ widthS
                                            buttonBase.widthAnchor /==/ finalWidth + CGFloat(8) + widthF
                                            buttonBase.addArrangedSubview(flairs)
                                            self.replyButtons?.contentSize = CGSize.init(width: finalWidth + CGFloat(8) + widthF, height: CGFloat(30))
                                        }
                                    }
                                }
                            }
                        } catch {
                        }
                    }
                }
            } catch let error {
                print(error)
                buttonBase.widthAnchor /==/ finalWidth
            }
        } else {
            buttonBase.widthAnchor /==/ finalWidth
        }
    }

    @objc func chooseAccount() {
        let optionMenu = DragDownAlertMenu(title: "Accounts", subtitle: "Choose an account to reply with", icon: nil)

        for accountName in AccountController.names.unique().sorted() {
            if accountName != self.chosenAccount {
                optionMenu.addAction(title: accountName, icon: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon()) { [weak self] in
                    self?.chosenAccount = accountName
                    self?.doButtons()
                }
            } else {
                optionMenu.addAction(title: "\(accountName) (current)", icon: UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon().getCopy(withColor: GMColor.green500Color())) {
                }
            }
        }
        
        optionMenu.show(self.parent)
    }
    
    @objc func flairs(_ sender: UIStateButton) {
        let alert = DragDownAlertMenu(title: "Available flairs", subtitle: "r/\(self.subreddit)", icon: nil)

        for flair in availableFlairs {
            if !(flair.image.isEmpty) {
                alert.addView(title: flair.title, icon_url: flair.image) { [weak self] in
                    guard let self = self else { return }
                    alert.dismiss(animated: true) {
                        if flair.editable {
                            self.editFlair(flairID: flair.id, flairText: flair.iconText, subName: self.subreddit, icon: flair.image, view: sender)
                        } else {
                            self.selectedFlairID = flair.id
                            self.selectedFlairDisplay = flair.iconText
                            sender.setTitle(self.selectedFlairDisplay, for: .normal)
                            sender.sizeToFit()
                        }
                    }
                }
            } else {
                alert.addAction(title: flair.title, icon: nil) { [weak self] in
                    guard let self = self else { return }
                    alert.dismiss(animated: true) {
                        if flair.editable {
                            self.editFlair(flairID: flair.id, flairText: flair.text, subName: self.subreddit, icon: flair.image, view: sender)
                        } else {
                            self.selectedFlairID = flair.id
                            self.selectedFlairDisplay = flair.text
                            sender.setTitle(self.selectedFlairDisplay, for: .normal)
                            sender.sizeToFit()
                        }
                    }
                }
            }
        }
        
        alert.show(self)
    }
    
    func editFlair(flairID: String, flairText: String, subName: String, icon: String?, view: UIStateButton) {
        let alert = DragDownAlertMenu(title: "Edit flair text", subtitle: "", icon: icon)
        
        alert.addTextInput(title: "Set flair", icon: UIImage(sfString: SFSymbol.flagFill, overrideString: "save-1")?.menuIcon(), action: {
            alert.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.selectedFlairText = alert.getText() ?? flairText
                self.selectedFlairID = flairID
                self.selectedFlairDisplay = alert.getText() ?? flairText
                view.setTitle(self.selectedFlairDisplay, for: .normal)
                view.sizeToFit()
            }
        }, inputPlaceholder: "Flair text...", inputValue: flairText, inputIcon: UIImage(sfString: SFSymbol.flagFill, overrideString: "flag")!.menuIcon(), textRequired: true, exitOnAction: true)
        
        alert.show(self)
    }
    
    var availableFlairs = [FlairObject]()
    var selectedFlairID: String?
    var selectedFlairText: String?
    var selectedFlairDisplay: String?

    class FlairObject {
        var image = ""
        var text = ""
        var iconText = ""
        var title = ""
        var editable = false
        var id = ""
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
        self.scrollView.backgroundColor = UIColor.backgroundColor
        self.scrollView.isUserInteractionEnabled = true
        self.scrollView.contentInset = UIEdgeInsets.init(top: 8, left: 0, bottom: 0, right: 0)
        self.scrollView.bottomAnchor /==/ self.view.bottomAnchor - 64
        self.scrollView.topAnchor /==/ self.view.topAnchor
        self.view.backgroundColor = UIColor.backgroundColor
        self.scrollView.horizontalAnchors /==/ self.view.horizontalAnchors

        let stack = UIStackView().then {
            $0.accessibilityIdentifier = "Reply Stack Vertical"
            $0.axis = .vertical
            $0.alignment = .center
            $0.distribution = .fill
            $0.spacing = 8
        }
        
        if type.isMessage() {
            if type == .REPLY_MESSAGE {
                // two
                let layout = BadgeLayoutManager()
                let storage = NSTextStorage()
                storage.addLayoutManager(layout)
                let initialSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
                let container = NSTextContainer(size: initialSize)
                container.widthTracksTextView = true
                layout.addTextContainer(container)

                let text1 = TitleUITextView(delegate: self, textContainer: container).then({
                    $0.doSetup()
                    $0.backgroundColor = UIColor.foregroundColor
                    $0.clipsToBounds = true
                    $0.layer.cornerRadius = 10
                })
                extras?.append(text1)
                let html = (toReplyTo as! MessageObject).htmlBody
                let content = TextDisplayStackView.createAttributedChunk(baseHTML: html, fontSize: 16, submission: false, accentColor: ColorUtil.baseAccent, fontColor: UIColor.fontColor, linksCallback: nil, indexCallback: nil)
                
                // TODO: - this
                /*
                let activeLinkAttributes = NSMutableDictionary(dictionary: text1.activeLinkAttributes)
                activeLinkAttributes[kCTForegroundColorAttributeName] = ColorUtil.baseAccent
                text1.activeLinkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
                text1.linkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
*/
                text1.attributedText = content
                text1.layoutTitleImageViews()
                text1.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

                let text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.placeholder = "Body"
                    $0.textColor = UIColor.fontColor
                    $0.backgroundColor = UIColor.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                    $0.delegate = self
                })
                
                stack.addArrangedSubviews(text1, text3)
                text1.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                text3.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                
                text3.heightAnchor />=/ CGFloat(70)

                scrollView.addSubview(stack)
                stack.widthAnchor /==/ scrollView.widthAnchor
                stack.verticalAnchors /==/ scrollView.verticalAnchors
                
                text = [text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self, replyText: (toReplyTo as! MessageObject).markdownBody)
            } else {
                // three
                let text1 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.textColor = UIColor.fontColor
                    $0.backgroundColor = UIColor.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.delegate = self
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                })
                if !UIColor.isLightTheme {
                    text1.keyboardAppearance = .dark
                }
                
                let text2 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.textColor = UIColor.fontColor
                    $0.backgroundColor = UIColor.foregroundColor
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
                    text1.text = "re: \((toReplyTo as! MessageObject).subject.escapeHTML)"
                    text1.isEditable = false
                    text2.text = ((toReplyTo as! MessageObject).author)
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
                    $0.textColor = UIColor.fontColor
                    $0.backgroundColor = UIColor.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                    $0.delegate = self
                })
                
                if subject != nil {
                    text1.text = subject!
                }
                
                if message != nil {
                    text3.text = message!
                }

                stack.addArrangedSubviews(text1, text2, text3)
                text1.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                text1.heightAnchor />=/ CGFloat(70)
                text2.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                text2.heightAnchor /==/ CGFloat(70)
                text3.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                
                scrollView.addSubview(stack)
                stack.widthAnchor /==/ scrollView.widthAnchor
                stack.verticalAnchors /==/ scrollView.verticalAnchors
                
                text = [text1, text2, text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self, replyText: nil)
            }
        } else if type.isSubmission() {
            // three
            let text1 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.textColor = UIColor.fontColor
                $0.backgroundColor = UIColor.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.delegate = self
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
            })

            let text2 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.textColor = UIColor.fontColor
                $0.backgroundColor = UIColor.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.textContainer.maximumNumberOfLines = 1
                $0.textContainer.lineBreakMode = .byTruncatingTail
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
            })
            
            ruleLabel = UITextView(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = false
                $0.textColor = UIColor.fontColor
                $0.placeholder = "r/\(subreddit) rules"
                $0.backgroundColor = UIColor.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.textContainer.maximumNumberOfLines = 0
                $0.delegate = self
                $0.textContainer.lineBreakMode = .byTruncatingTail
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
            })

            if toReplyTo != nil && type != .CROSSPOST {
                text1.text = "\((toReplyTo as! SubmissionObject).title)"
                text1.isEditable = false
                text2.text = ((toReplyTo as! SubmissionObject).subreddit)
                text2.isEditable = false
            }

            text1.placeholder = "Title"
            text2.placeholder = "Subreddit"
            
            if !subreddit.isEmpty() && subreddit != "all" && subreddit != "frontpage" && subreddit != "popular" && subreddit != "friends" && subreddit != "mod" && !subreddit.contains("m/") {
                text2.text = subreddit
            }
            text2.isEditable = false

            text2.addTapGestureRecognizer { (_) in
                let search = SubredditFindReturnViewController(includeSubscriptions: true, includeCollections: false, includeTrending: false, subscribe: false, callback: { (subreddit) in
                    text2.text = subreddit
                    self.subreddit = subreddit
                    self.doButtons()
                    self.setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
                })
                VCPresenter.presentModally(viewController: search, self, nil)
            }
            let text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.placeholder = "Body"
                $0.textColor = UIColor.fontColor
                $0.backgroundColor = UIColor.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                $0.delegate = self
            })
            
            if type != .SUBMIT_TEXT && type != .EDIT_SELFTEXT && type != .CROSSPOST {
                text3.placeholder = "Link"
                text3.textContainer.maximumNumberOfLines = 0
                
                if type == .SUBMIT_IMAGE {
                    text3.addTapGestureRecognizer { (_) in
                        self.toolbar?.uploadImage(UIButton())
                    }
                    text3.placeholder = "Tap to choose an image"
                }
            }

            if type != .EDIT_SELFTEXT {
                doButtons()
                if type == .CROSSPOST {
                    let link = toReplyTo as! SubmissionObject
                    let linkCV = link.isSelf ? TextLinkCellView(frame: CGRect.zero) : ThumbnailLinkCellView(frame: CGRect.zero)
                    linkCV.aspectWidth = self.view.frame.size.width - 16
                    linkCV.configure(submission: link, parent: self, nav: nil, baseSub: "all", embedded: true, parentWidth: self.view.frame.size.width - 16, np: false)
                    let linkView = linkCV.contentView
                    linkView.isUserInteractionEnabled = false
                    let height = linkCV.estimateHeight(false, true, np: false)
                    
                    stack.addArrangedSubviews(linkView, text1, text2, replyButtons!)
                    replyButtons!.heightAnchor /==/ CGFloat(30)
                    replyButtons!.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                    
                    linkView.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                    linkView.heightAnchor /==/ CGFloat(height)
                    self.crosspostHeight = CGFloat(height)

                    text1.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                    text1.heightAnchor />=/ CGFloat(70)
                    text2.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                    text2.heightAnchor /==/ CGFloat(70)
                    
                    scrollView.addSubview(stack)
                    stack.widthAnchor /==/ scrollView.widthAnchor
                    stack.verticalAnchors /==/ scrollView.verticalAnchors
                    
                    text = [text1, text2]
                    toolbar = ToolbarTextView.init(textView: text2, parent: self, replyText: nil)
                } else {
                    stack.addArrangedSubviews(text1, text2, replyButtons!, ruleLabel, text3)
                    replyButtons!.heightAnchor /==/ CGFloat(30)
                    replyButtons!.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                    text1.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                    text1.heightAnchor />=/ CGFloat(70)
                    text2.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                    text2.heightAnchor /==/ CGFloat(70)
                    text3.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)

                    text3.heightAnchor />=/ CGFloat(70)
                    
                    ruleLabel.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                    ruleLabel.heightAnchor />=/ CGFloat(10)

                    scrollView.addSubview(stack)
                    stack.widthAnchor /==/ scrollView.widthAnchor
                    stack.verticalAnchors /==/ scrollView.verticalAnchors
                    
                    text = [text1, text2, text3]
                    toolbar = ToolbarTextView.init(textView: text3, parent: self, replyText: nil)
                }
            } else {
                stack.addArrangedSubviews(text1, text3)
                text3.text = (toReplyTo as! SubmissionObject).markdownBody
                text1.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                text1.heightAnchor />=/ CGFloat(70)
                text3.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                
                text3.heightAnchor />=/ CGFloat(70)
                
                scrollView.addSubview(stack)
                stack.widthAnchor /==/ scrollView.widthAnchor
                stack.verticalAnchors /==/ scrollView.verticalAnchors
                
                text = [text1, text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self, replyText: nil)
            }

        } else if type.isComment() {
            if (toReplyTo as! SubmissionObject).type == .SELF && !((toReplyTo as! SubmissionObject).htmlBody ?? "").trimmed().isEmpty {
                // two
                let layout = BadgeLayoutManager()
                let storage = NSTextStorage()
                storage.addLayoutManager(layout)
                let initialSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
                let container = NSTextContainer(size: initialSize)
                container.widthTracksTextView = true
                layout.addTextContainer(container)

                let text1 = TitleUITextView(delegate: self, textContainer: container).then({
                    $0.doSetup()
                    $0.backgroundColor = UIColor.foregroundColor
                    $0.clipsToBounds = true
                    $0.layer.cornerRadius = 10
                })
                extras?.append(text1)
                let html = (toReplyTo as! SubmissionObject).htmlBody ?? ""
                let content = TextDisplayStackView.createAttributedChunk(baseHTML: html, fontSize: 16, submission: false, accentColor: ColorUtil.baseAccent, fontColor: UIColor.fontColor, linksCallback: nil, indexCallback: nil)
                
                // TODO: - this
                /*
                let activeLinkAttributes = NSMutableDictionary(dictionary: text1.activeLinkAttributes)
                activeLinkAttributes[kCTForegroundColorAttributeName] = ColorUtil.baseAccent
                text1.activeLinkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
                text1.linkAttributes = activeLinkAttributes as NSDictionary as? [AnyHashable: Any]
*/
                
                text1.attributedText = content
                text1.layoutTitleImageViews()

                text1.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

                let text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.placeholder = "Body"
                    $0.textColor = UIColor.fontColor
                    $0.backgroundColor = UIColor.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                    $0.delegate = self
                })
                
                if modText != nil {
                    text3.text = "Hi u/\((toReplyTo as! SubmissionObject).author),\n\nYour submission has been removed for the following reason:\n\n\(modText!.replacingOccurrences(of: "\n", with: "\n\n"))\n\n"
                }
                doButtons()
                stack.addArrangedSubviews(text1, replyButtons!, text3)
                replyButtons!.heightAnchor /==/ CGFloat(30)
                replyButtons!.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)

                stack.addArrangedSubviews(text1, text3)
                text1.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                text3.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                
                text3.heightAnchor />=/ CGFloat(70)
//                text1.sizeToFitHeight()
                
                scrollView.addSubview(stack)
                stack.widthAnchor /==/ scrollView.widthAnchor
                stack.verticalAnchors /==/ scrollView.verticalAnchors
                
                text = [text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self, replyText: (toReplyTo as! SubmissionObject).markdownBody)
            } else {
                // one
                let text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                    $0.isEditable = true
                    $0.placeholder = "Body"
                    $0.textColor = UIColor.fontColor
                    $0.backgroundColor = UIColor.foregroundColor
                    $0.layer.masksToBounds = false
                    $0.layer.cornerRadius = 10
                    $0.font = UIFont.systemFont(ofSize: 16)
                    $0.isScrollEnabled = false
                    $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                    $0.delegate = self
                })
                
                if modText != nil {
                    text3.text = "Hi u/\((toReplyTo as! SubmissionObject).author),\n\nYour submission has been removed for the following reason:\n\n\(modText!.replacingOccurrences(of: "\n", with: "\n\n"))\n\n"
                }

                doButtons()
                stack.addArrangedSubviews(replyButtons!, text3)
                replyButtons!.heightAnchor /==/ CGFloat(30)
                replyButtons!.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                text3.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
                
                text3.heightAnchor />=/ CGFloat(70)
                
                scrollView.addSubview(stack)
                stack.widthAnchor /==/ scrollView.widthAnchor
                stack.verticalAnchors /==/ scrollView.verticalAnchors
                
                text = [text3]
                toolbar = ToolbarTextView.init(textView: text3, parent: self, replyText: nil)
            }
    
        } else if type.isEdit() {
            // two
            let text1 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.textColor = UIColor.fontColor
                $0.backgroundColor = UIColor.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.delegate = self
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
            })

            if toReplyTo != nil {
                text1.text = "\((toReplyTo as! SubmissionObject).title)"
                text1.isEditable = false
            }

            text1.placeholder = "Title"

            let text3 = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
                $0.isEditable = true
                $0.placeholder = "Body"
                $0.textColor = UIColor.fontColor
                $0.backgroundColor = UIColor.foregroundColor
                $0.layer.masksToBounds = false
                $0.layer.cornerRadius = 10
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.isScrollEnabled = false
                $0.textContainerInset = UIEdgeInsets.init(top: 24, left: 8, bottom: 8, right: 8)
                $0.delegate = self
                $0.text = (toReplyTo as! SubmissionObject).markdownBody ?? ""
            })

            stack.addArrangedSubviews(text1, text3)
            text1.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)
            text1.heightAnchor />=/ CGFloat(70)
            text3.horizontalAnchors /==/ stack.horizontalAnchors + CGFloat(8)

            text3.heightAnchor />=/ CGFloat(70)

            scrollView.addSubview(stack)
            stack.widthAnchor /==/ scrollView.widthAnchor
            stack.verticalAnchors /==/ scrollView.verticalAnchors

            text = [text1, text3]
            toolbar = ToolbarTextView.init(textView: text3, parent: self, replyText: nil)
        }
    }
    
    var doneOnceLayout = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !doneOnceLayout {
            layoutForType()
            doneOnceLayout = true
            var first = false
            for textField in text! {
                if textField.isEditable && !first {
                    first = true
                    textField.becomeFirstResponder()
                }
                if !UIColor.isLightTheme {
                    textField.keyboardAppearance = .dark
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.navigationController?.setNavigationBarHidden(false, animated: true)

        if type.isMessage() {
            title = "New message"
            if type == ReplyType.REPLY_MESSAGE {
                let author = (toReplyTo is MessageObject) ? ((toReplyTo as! MessageObject).author) : ((toReplyTo as! SubmissionObject).author)
                title = "Reply to \(author)"
            }
        } else {
            if type == .EDIT_SELFTEXT {
                title = "Editing"
            } else if type.isComment() {
                title = "Replying to \((toReplyTo as! SubmissionObject).author)"
            } else if type == .CROSSPOST {
                title = "Crosspost submission"
            } else {
                title = "New submission"
            }
        }

        let send = UIButton(buttonImage: UIImage(sfString: SFSymbol.paperplaneFill, overrideString: "send"))
        send.addTarget(self, action: #selector(self.send(_:)), for: UIControl.Event.touchUpInside)
        send.accessibilityLabel = "Send"
        let sendB = UIBarButtonItem.init(customView: send)
        navigationItem.rightBarButtonItem = sendB

        let button = UIButtonWithContext(buttonImage: UIImage(sfString: SFSymbol.xmark, overrideString: "close"))
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
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
    var session: reddift.Session?

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
        var first = false
        for textField in text! {
            if textField.isEditable && !first {
                first = true
                textField.becomeFirstResponder()
                textViewDidChange(textField)
                UIView.animate(withDuration: 0.25) {
                    textField.insertText("")
                }
            }
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
           // TODO: - success but null child
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
            alertController = UIAlertController(title: "Editing submission...\n\n\n", message: nil, preferredStyle: .alert)

            let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.fontColor
            spinnerIndicator.startAnimating()

            alertController?.view.addSubview(spinnerIndicator)
            self.present(alertController!, animated: true, completion: nil)

            session = (UIApplication.shared.delegate as! AppDelegate).session

            do {
                let name = toReplyTo is MessageObject ? (toReplyTo as! MessageObject).id : toReplyTo is CommentObject ? (toReplyTo as! CommentObject).id : (toReplyTo as! SubmissionObject).id
                try self.session?.editCommentOrLink(name, newBody: body.text, completion: { (_) in
                    self.getSubmissionEdited(name)
                })
            } catch {
                print((error as NSError).description)
            }

        } else {
            self.session = (UIApplication.shared.delegate as! AppDelegate).session
            
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
                alertController = UIAlertController(title: "Posting\(chosenAccount != nil ? " as u/" + chosenAccount! : "")...\n\n\n", message: nil, preferredStyle: .alert)
            } else {
                alertController = UIAlertController(title: "Posting submission...\n\n\n", message: nil, preferredStyle: .alert)
            }

            let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.fontColor
            spinnerIndicator.startAnimating()

            alertController?.view.addSubview(spinnerIndicator)
            self.present(alertController!, animated: true, completion: nil)

            do {
                if type == .SUBMIT_TEXT {
                    try self.session?.submitText(Subreddit.init(subreddit: subreddit.text), title: title.text, text: body.text ?? "", sendReplies: replies!.isSelected, captcha: "", captchaIden: "", flairID: self.selectedFlairID, flairText: self.selectedFlairText, completion: { (result) -> Void in
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
                    try self.session?.submitLink(Subreddit.init(subreddit: subreddit.text), title: title.text, URL: body.text, sendReplies: replies!.isSelected, captcha: "", captchaIden: "", flairID: self.selectedFlairID, flairText: self.selectedFlairText, completion: { (result) -> Void in
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

    func crosspost() {
        let title = text![0]
        let subreddit = text![1]
        let cLink = toReplyTo as! SubmissionObject
        
        if title.text.isEmpty() {
            BannerUtil.makeBanner(text: "Title cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }
        
        if subreddit.text.isEmpty() {
            BannerUtil.makeBanner(text: "Subreddit cannot be empty", color: GMColor.red500Color(), seconds: 5, context: self, top: true)
            return
        }
        
        alertController = UIAlertController(title: "Crossposting...\n\n\n", message: nil, preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.fontColor
        spinnerIndicator.startAnimating()
        
        alertController?.view.addSubview(spinnerIndicator)
        self.present(alertController!, animated: true, completion: nil)
        
        session = (UIApplication.shared.delegate as! AppDelegate).session
            
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.crosspost(Link.init(id: cLink.id), subreddit: subreddit.text, newTitle: title.text) { result in
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
            }
        } catch {
            
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

        alertController = UIAlertController(title: "Sending message...\n\n\n", message: nil, preferredStyle: .alert)
        let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.fontColor
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
                let name = toReplyTo!.getId()
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

        self.session = (UIApplication.shared.delegate as! AppDelegate).session
        
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
            alertController = UIAlertController(title: "Commenting\(chosenAccount != nil ? " as u/" + chosenAccount! : "")...\n\n\n", message: nil, preferredStyle: .alert)
        } else {
            alertController = UIAlertController(title: "Sending comment...\n\n\n", message: nil, preferredStyle: .alert)
        }

        let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.fontColor
        spinnerIndicator.startAnimating()

        alertController?.view.addSubview(spinnerIndicator)
        self.present(alertController!, animated: true, completion: nil)

        do {
            let name = toReplyTo!.getId()
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
                    try self.session?.distinguish(comment.id, how: "yes", sticky: true, completion: { (_) -> Void in
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
                    try self.session?.setReplies(false, name: comment.id, completion: { (_) in
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
        case .CROSSPOST:
            crosspost()
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
            backgroundColor = isSelected ? color : UIColor.foregroundColor
            self.layer.borderColor = color .cgColor
            self.layer.borderWidth = isSelected ? CGFloat(0) : CGFloat(2)
        }
    }
}

extension ReplyViewController: TextDisplayStackViewDelegate {
    func linkTapped(url: URL, text: String) {
        self.doShow(url: url, heroView: nil, finalSize: nil, heroVC: nil, link: SubmissionObject())
    }
    
    func linkLongTapped(url: URL) {
        // TODO this
    }
    
    func previewProfile(profile: String) {
        let vc = ProfileInfoViewController(accountNamed: profile)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = ProfileInfoPresentationManager()
        self.present(vc, animated: true)
    }
}
