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
import YangMingShan
import Alamofire
import MobileCoreServices
import SwiftyJSON
import ActionSheetPicker_3_0
import RealmSwift
import MaterialComponents.MaterialSnackbar

class ReplyViewController: UITableViewController, UITextViewDelegate, YMSPhotoPickerViewControllerDelegate {

    public enum ReplyType {
        case NEW_MESSAGE
        case REPLY_MESSAGE
        case SUBMIT_IMAGE
        case SUBMIT_LINK
        case SUBMIT_TEXT
        case EDIT_SELFTEXT

        func isEdit() -> Bool {
            return self == ReplyType.EDIT_SELFTEXT
        }

        func isSubmission() -> Bool {
            return self == ReplyType.SUBMIT_IMAGE || self == ReplyType.SUBMIT_LINK || self == ReplyType.SUBMIT_TEXT || self == ReplyType.EDIT_SELFTEXT
        }

        func isMessage() -> Bool {
            return self == ReplyType.NEW_MESSAGE || self == ReplyType.REPLY_MESSAGE
        }
    }


    var type = ReplyType.NEW_MESSAGE
    var toReplyTo: Object?
    var subreddit: String = ""

    var text: UITextView?
    var subjectCell = InputCell()
    var recipientCell = InputCell()
    var linkCell = InputCell()

    var scrollView: UIScrollView?

    //Callbacks
    var messageCallback: (Any?) -> Void = { (comment) in
    }
    var submissionCallback: (Link?) -> Void = { (link) in
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1

    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
            case 0: return self.subjectCell
            case 1: return self.recipientCell
            case 2: return self.linkCell
            default: fatalError("Unknown row in section 0")
            }

        default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return type == .SUBMIT_IMAGE || type == .SUBMIT_LINK ? 3 : 2
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    init(completion: @escaping(String?) -> Void) {
        type = .NEW_MESSAGE
        self.subreddit = ""
        super.init(nibName: nil, bundle: nil)
        self.messageCallback = { (message) in
            DispatchQueue.main.async {
                //todo on error
                //todo string from message
                completion("")
                self.alertController?.dismiss(animated: false, completion: {
                    self.dismiss(animated: true, completion: nil)
                })
            }
        }
    }

    convenience init(name: String, completion: @escaping(String?) -> Void) {
        self.init(completion: completion)
        self.subreddit = name
    }

    init(message: RMessage?, completion: @escaping (String?) -> Void) {
        type = .REPLY_MESSAGE
        self.subreddit = (message as! RMessage).author
        self.toReplyTo = message
        super.init(nibName: nil, bundle: nil)
        self.messageCallback = { (message) in
            DispatchQueue.main.async {
                //todo on error
                //todo get message
                self.alertController?.dismiss(animated: false, completion: {
                    self.dismiss(animated: true, completion: {
                        completion("")
                    })
                })
            }
        }
    }

    var toolbar: ToolbarTextView?

    func photoPickerViewControllerDidReceivePhotoAlbumAccessDenied(_ picker: YMSPhotoPickerViewController!) {
        let alertController = UIAlertController(title: "Allow photo album access?", message: "Slide needs your permission to access photo albums", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
            } else {
                // Fallback on earlier versions
            }
        }
        alertController.addAction(dismissAction)
        alertController.addAction(settingsAction)

        self.present(alertController, animated: true, completion: nil)
    }

    func photoPickerViewControllerDidReceiveCameraAccessDenied(_ picker: YMSPhotoPickerViewController!) {
        let alertController = UIAlertController(title: "Allow camera album access?", message: "Slide needs your permission to take a photo", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
            } else {
                // Fallback on earlier versions
            }
        }
        alertController.addAction(dismissAction)
        alertController.addAction(settingsAction)

        // The access denied of camera is always happened on picker, present alert on it to follow the view hierarchy
        self.present(alertController, animated: true, completion: nil)
    }

    func photoPickerViewController(picker: YMSPhotoPickerViewController!, didFinishPickingImages photoAssets: [PHAsset]!) {
        picker.dismiss(animated: true) {
            self.toolbar?.uploadAsync(photoAssets)
        }
    }

    func photoPickerViewControllerDidCancel(_ picker: YMSPhotoPickerViewController!) {
        if (type == .SUBMIT_IMAGE) {
            navigationController?.dismiss(animated: true)
        }
    }


    init(submission: RSubmission, sub: String, editing: Bool, completion: @escaping (Link?) -> Void) {
        type = .EDIT_SELFTEXT
        self.toReplyTo = submission
        super.init(nibName: nil, bundle: nil)
        self.subreddit = submission.subreddit
        self.submissionCallback = { (link) in
            DispatchQueue.main.async {
                if (link == nil) {
                    self.toolbar?.saveDraft(self)
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your submission has not been edited (but has been saved as a draft), please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })
                } else {
                    //todo get sub string
                    self.alertController?.dismiss(animated: false, completion: {
                        self.dismiss(animated: true, completion: {
                            completion(link)
                        })
                    })
                }
            }
        }
    }

    init(type: ReplyType, completion: @escaping (Link?) -> Void) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
        self.submissionCallback = { (link) in
            DispatchQueue.main.async {
                if (link == nil) {
                    //todo this
                } else {
                    //todo get sub string
                    self.alertController?.dismiss(animated: false, completion: {
                        self.dismiss(animated: true, completion: {
                            completion(link)
                        })
                    })
                }
            }
        }
    }


    convenience init(subreddit: String, type: ReplyType, completion: @escaping (Link?) -> Void) {
        self.init(type: type, completion: completion)
        self.subreddit = subreddit
        if (type == .SUBMIT_IMAGE) {
            let pickerViewController = YMSPhotoPickerViewController.init()
            pickerViewController.theme.titleLabelTextColor = ColorUtil.fontColor
            pickerViewController.theme.navigationBarBackgroundColor = ColorUtil.getColorForSub(sub: "")
            pickerViewController.theme.tintColor = ColorUtil.accentColorForSub(sub: "")
            pickerViewController.theme.cameraIconColor = ColorUtil.fontColor
            self.yms_presentCustomAlbumPhotoView(pickerViewController, delegate: self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        unregisterKeyboardNotifications()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if (subjectCell.cellLabel.text.isEmpty) {
            subjectCell.cellLabel.becomeFirstResponder()
            subjectCell.cellLabel.isEditable = false
        } else if (recipientCell.cellLabel.text.isEmpty) {
            recipientCell.cellLabel.becomeFirstResponder()
            recipientCell.cellLabel.isEditable = false
        } else {
            text?.becomeFirstResponder()
        }

        toolbar = ToolbarTextView.init(textView: text!, delegate: self, parent: self)
        self.view.layer.cornerRadius = 5
        self.view.layer.masksToBounds = true
    }

    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(ReplyViewController.keyboardDidShow(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ReplyViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }


    func keyboardDidShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardInfo = userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue
        let keyboardSize = keyboardInfo.cgRectValue.size

        // Get the existing contentInset for the scrollView and set the bottom property to be the height of the keyboard
        var contentInset = self.scrollView?.contentInset
        contentInset?.bottom = keyboardSize.height

        self.scrollView?.contentInset = contentInset!
        self.scrollView?.scrollIndicatorInsets = contentInset!
    }

    func keyboardWillHide(notification: NSNotification) {
        var contentInset = self.scrollView?.contentInset
        contentInset?.bottom = 0

        self.scrollView?.contentInset = contentInset!
        self.scrollView?.scrollIndicatorInsets = UIEdgeInsets.zero
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: subreddit)
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white

        if (type.isMessage()) {
            title = "New message"
            if (type == ReplyType.REPLY_MESSAGE) {
                let author = (toReplyTo is RMessage) ? ((toReplyTo as! RMessage).author) : ((toReplyTo as! RSubmission).author)
                title = "Reply to \(author)"
            }
        } else {
            if (type == .EDIT_SELFTEXT) {
                title = "Editing"
            } else {
                title = "New submission"
            }
        }

        let send = UIButton.init(type: .custom)
        send.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        send.setImage(UIImage.init(named: "send")!.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        send.addTarget(self, action: #selector(self.send(_:)), for: UIControlEvents.touchUpInside)
        send.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let sendB = UIBarButtonItem.init(customView: send)
        navigationItem.rightBarButtonItem = sendB

        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        button.setImage(UIImage.init(named: "close")!.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        button.addTarget(self, action: #selector(self.close(_:)), for: .touchUpInside)

        let barButton = UIBarButtonItem.init(customView: button)
        navigationItem.leftBarButtonItem = barButton

        registerKeyboardNotifications()

    }

    func close(_ sender: AnyObject) {
        //todo cancel message?
        let alert = UIAlertController.init(title: "Discard this \(type.isMessage() ? "message" : "submission")?", message: "", preferredStyle: .alert)
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
                case .success(let listing):
                    if listing.children.count == 1 {
                        if let submission = listing.children[0] as? Link {
                            self.submissionCallback(submission)
                        }
                    }
                }

            })
        } catch {
            //todo success but null child
            self.submissionCallback(nil)
        }

    }

    var triedOnce = false

    func send(_ sender: AnyObject) {
        if (subjectCell.cellLabel.text!.isEmpty()) {
            let message = MDCSnackbarMessage()
            message.text = type.isMessage() ? "Subject cannot be empty." : "Title cannot be empty."
            MDCSnackbarManager.show(message)
            return
        } else if (recipientCell.cellLabel.text!.isEmpty()) {
            let message = MDCSnackbarMessage()
            message.text = type.isMessage() ? "Recipient cannot be empty." : "Subreddit cannot be empty."
            MDCSnackbarManager.show(message)
        } else if ((type == .SUBMIT_LINK || type == .SUBMIT_IMAGE) && linkCell.cellLabel.text!.isEmpty()) {
            let message = MDCSnackbarMessage()
            message.text = "Link cannot be empty."
            MDCSnackbarManager.show(message)
        }
        if (type.isMessage()) {
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
                    try self.session?.composeMessage(recipientCell.cellLabel.text!, subject: subjectCell.cellLabel.text!, text: text!.text, completion: { (result) in
                        switch result {
                        case .failure(let error):
                            print(error.description)
                            self.messageCallback(nil)
                        case .success(let message):
                            self.messageCallback(message)
                        }

                    })
                } catch {
                    print((error as NSError).description)
                }
            } else {
                do {
                    let name = toReplyTo is RMessage ? (toReplyTo as! RMessage).getId() : toReplyTo is RComment ? (toReplyTo as! RComment).getId() : (toReplyTo as! RSubmission).getId()
                    try self.session?.replyMessage(text!.text, parentName: name, completion: { (result) -> Void in
                        switch result {
                        case .failure(let error):
                            print(error.description)
                            self.messageCallback(nil)
                        case .success(let comment):
                            self.messageCallback(comment)
                        }
                    })
                } catch {
                    print((error as NSError).description)
                }
            }
        } else if (type == .EDIT_SELFTEXT) {
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
                try self.session?.editCommentOrLink(name, newBody: text!.text, completion: { (result) in
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
                    try self.session?.submitText(Subreddit.init(subreddit: recipientCell.cellLabel.text), title: subjectCell.cellLabel.text, text: text!.text, captcha: "", captchaIden: "", completion: { (result) -> Void in
                        switch result {
                        case .failure(let error):
                            print(error.description)
                            self.submissionCallback(nil)
                            break
                        case .success(let submission):
                            let string = self.getIDString(submission).value!
                            print("Got \(string)")
                            self.getSubmissionEdited(string)
                        }
                    })

                } else {
                    try self.session?.submitLink(Subreddit.init(subreddit: recipientCell.cellLabel.text), title: subjectCell.cellLabel.text, URL: linkCell.cellLabel.text, captcha: "", captchaIden: "", completion: { (result) -> Void in
                        switch result {
                        case .failure(let error):
                            print(error.description)
                            self.submissionCallback(nil)
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

    override func loadView() {
        super.loadView()

        self.tableView.backgroundColor = ColorUtil.backgroundColor

        self.tableView.allowsSelection = false
        text = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 500))
        text?.isEditable = true
        text?.placeholder = type.isMessage() ? "message..." : "body..."
        text?.backgroundColor = ColorUtil.foregroundColor
        text?.textColor = ColorUtil.fontColor
        text?.font = UIFont.systemFont(ofSize: 18)
        text?.textContainerInset = UIEdgeInsets.init(top: 30, left: 10, bottom: 0, right: 0)

        if (type.isEdit()) {
            if (toReplyTo is RComment) {
                text!.text = (toReplyTo as! RComment).body
            } else {
                text!.text = (toReplyTo as! RSubmission).body
            }
        }

        let lineView = UIView(frame: CGRect.init(x: 0, y: 0, width: (text?.frame.size.width)!, height: 1))
        lineView.backgroundColor = ColorUtil.backgroundColor
        text?.addSubview(lineView)


        if (type.isMessage()) {
            subjectCell = InputCell.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 70), input: "subject:", width: self.tableView.frame.size.width)
            recipientCell = InputCell.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 70), input: "recipient:", width: self.tableView.frame.size.width)
        } else {
            subjectCell = InputCell.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 70), input: "title...", width: self.tableView.frame.size.width)
            recipientCell = InputCell.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 70), input: "subreddit:", width: self.tableView.frame.size.width)
        }

        linkCell = InputCell.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 70), input: "link:", width: self.tableView.frame.size.width)

        if (type == .REPLY_MESSAGE) {
            subjectCell.cellLabel.text = "re: " + (toReplyTo as! RMessage).subject
            subjectCell.cellLabel.isEditable = false
            recipientCell.cellLabel.text = (toReplyTo as! RMessage).author
            recipientCell.cellLabel.isEditable = false
        }

        if (type == .EDIT_SELFTEXT) {
            subjectCell.cellLabel.text = (toReplyTo as! RSubmission).title
            subjectCell.cellLabel.isEditable = false
            recipientCell.cellLabel.text = (toReplyTo as! RSubmission).subreddit
            recipientCell.cellLabel.isEditable = false
        }

        if (!subreddit.isEmpty) {
            recipientCell.cellLabel.text = subreddit
        }

        if (type != .SUBMIT_LINK && type != .SUBMIT_IMAGE) {
            tableView.tableFooterView = text
        }

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


class InputCell: UITableViewCell {
    var cellLabel: UITextView!

    init(frame: CGRect, input: String, width: CGFloat) {
        super.init(style: UITableViewCellStyle.default, reuseIdentifier: "cell")

        cellLabel = UITextView(frame: CGRect.init(x: 0, y: 0, width: width, height: 70))
        cellLabel.textColor = ColorUtil.fontColor
        cellLabel.font = FontGenerator.boldFontOfSize(size: 16, submission: true)
        cellLabel.placeholder = input

        cellLabel.textContainerInset = UIEdgeInsets.init(top: 30, left: 10, bottom: 0, right: 0)
        backgroundColor = ColorUtil.foregroundColor
        cellLabel.backgroundColor = ColorUtil.foregroundColor

        addSubview(cellLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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
