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
import ImagePickerSheetController
import Alamofire
import MobileCoreServices
import SwiftyJSON
import ActionSheetPicker_3_0
import RealmSwift

class ReplyViewController: UITableViewController, UITextViewDelegate {
    
    var toReplyTo: Object?
    var text: UITextView?
    var subjectCell = InputCell()
    var recipientCell = InputCell()
    var message = false
    var sub: String
    var scrollView: UIScrollView?
    var reply: (Comment?) -> Void = {(comment) in }
    var edit = false
    var header: UIView?
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return message ? 1 : 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            switch(indexPath.section) {
            case 0:
                switch(indexPath.row) {
                case 0: return self.subjectCell
                case 1: return self.recipientCell
                default: fatalError("Unknown row in section 0")
                }

            default: fatalError("Unknown section")
            }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(message){
            return 2
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    init(message: RMessage?, completion: @escaping (Message?) -> Void){
        self.toReplyTo = message
        self.message = true
        self.sub = ""
        super.init(nibName: nil, bundle: nil)
        self.reply = {(comment) in
            DispatchQueue.main.async {
                //todo check failed
                    completion(nil)
                    self.alertController?.dismiss(animated: false, completion: {
                        self.dismiss(animated: true, completion: nil)
                    })
            }
        }
    }
    
    
    init(thing: Object, sub: String, editing: Bool, completion: @escaping (Comment?) -> Void){
        self.toReplyTo = thing
        self.edit = true
        self.sub = sub
        super.init(nibName: nil, bundle: nil)
        self.reply = {(comment) in
            DispatchQueue.main.async {
                if(comment == nil){
                    self.saveDraft(self)
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your message has not been edited (but has been saved as a draft), please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })
                } else {
                    completion(comment)
                    self.alertController?.dismiss(animated: false, completion: {
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            }
        }
    }
    
    init(thing: Object, sub: String, view: UIView?, completion: @escaping (Comment?) -> Void){
        self.toReplyTo = thing
        self.sub = sub
        self.header = view
        super.init(nibName: nil, bundle: nil)
        self.reply = {(comment) in
            DispatchQueue.main.async {
                if(comment == nil){
                    self.alertController?.dismiss(animated: false, completion: {
                        let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your message has not been sent (but has been saved as a draft), please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    })
                } else {
                    completion(comment)
                    self.alertController?.dismiss(animated: false, completion: {
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            }
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
        text?.becomeFirstResponder()
        addToolbarToTextView()
    }
    
    func addToolbarToTextView(){
        let scrollView = TouchUIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: text!.frame.size.width, height: 50))
        scrollView.contentSize = CGSize.init(width: 50 * 11, height: 50)
        scrollView.autoresizingMask = .flexibleWidth
        scrollView.backgroundColor = ColorUtil.backgroundColor
        var i = 0
        for button in ([
            generateButtons(image: "save", action: #selector(ReplyViewController.saveDraft(_:))),
            generateButtons(image: "folder", action: #selector(ReplyViewController.openDrafts(_:))),
            generateButtons(image: "image", action: #selector(ReplyViewController.uploadImage(_:))),
            generateButtons(image: "draw", action: #selector(ReplyViewController.draw(_:))),
            generateButtons(image: "link", action: #selector(ReplyViewController.link(_:))),
            generateButtons(image: "bold", action: #selector(ReplyViewController.bold(_:))),
            generateButtons(image: "italic", action: #selector(ReplyViewController.italics(_:))),
            generateButtons(image: "list", action: #selector(ReplyViewController.list(_:))),
            generateButtons(image: "list_number", action: #selector(ReplyViewController.numberedList(_:))),
            generateButtons(image: "size", action: #selector(ReplyViewController.size(_:))),
            generateButtons(image: "strikethrough", action: #selector(ReplyViewController.strike(_:)))]) {
                button.0.frame = CGRect.init(x: i * 50, y: 0, width: 50, height: 50)
                button.0.isUserInteractionEnabled = true
                button.0.addTarget(self, action: button.1, for: UIControlEvents.touchUpInside)
                scrollView.addSubview(button.0)
                i += 1
        }
        scrollView.delaysContentTouches = false
        text!.inputAccessoryView = scrollView
    }
    
    func generateButtons(image: String, action: Selector) -> (UIButton, Selector) {
        let more = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        more.setImage(UIImage.init(named: image)?.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        return (more, action)
    }
    
    func wrapIn(_ value: String){
        text!.replace(text!.selectedTextRange!, withText: value + text!.text(in: text!.selectedTextRange!)! + value)
    }
    
    func replaceIn(_ value: String, with: String){
        text!.replace(text!.selectedTextRange!, withText: with + text!.text(in: text!.selectedTextRange!)!.replacingOccurrences(of: value, with: with))
    }
    
    
    func saveDraft(_ sender: AnyObject){
        if let toSave = text!.text {
            if(!toSave.isEmpty()){
                Drafts.addDraft(s: text!.text)
                self.view.makeToast("Draft saved", duration: 4, position: .top)
            }
        }
    }
    
    var picker: ActionSheetStringPicker?
    
    func openDrafts(_ sender: AnyObject){
        print("Opening drafts")
        if(Drafts.drafts.isEmpty){
            self.view.makeToast("No drafts found", duration: 4, position: .top)
        } else {
            picker = ActionSheetStringPicker(title: "Choose a draft", rows: Drafts.drafts, initialSelection: 0, doneBlock: { (picker, index, value) in
                self.text!.insertText(Drafts.drafts[index] as String)
            }, cancel: { (picker) in
                return
            }, origin: text!)
            
            let doneButton = UIBarButtonItem.init(title: "Insert", style: .done, target: nil, action: nil)
            picker?.setDoneButton(doneButton)
            //todo  picker?.addCustomButton(withTitle: "Delete", target: self, selector: #selector(ReplyViewController.doDelete(_:)))
            picker?.show()
            
        }
    }
    
    func doDelete(_ sender: AnyObject){
        Drafts.deleteDraft(s: Drafts.drafts[(picker?.selectedIndex)!] as String)
        self.openDrafts(sender)
    }
    
    func uploadImage(_ sender: UIButton!){
        let presentImagePickerController: (UIImagePickerControllerSourceType) -> () = { source in
            let controller = UIImagePickerController()
            controller.delegate = self
            var sourceType = source
            if (!UIImagePickerController.isSourceTypeAvailable(sourceType)) {
                sourceType = .photoLibrary
                print("Fallback to camera roll as a source since the simulator doesn't support taking pictures")
            }
            controller.sourceType = sourceType
            
            self.present(controller, animated: true, completion: nil)
        }
        
        let controller = ImagePickerSheetController(mediaType: .imageAndVideo)
        controller.delegate = self
        
        controller.addAction(ImagePickerAction(title: NSLocalizedString("Photo Library", comment: "Action Title"), secondaryTitle: { NSString.localizedStringWithFormat(NSLocalizedString("Upload", comment: "Action Title") as NSString, $0) as String}, handler: { _ in
            presentImagePickerController(.photoLibrary)
        }, secondaryHandler: { _, numberOfPhotos in
            self.uploadAsync(controller.selectedAssets)
        }))
        controller.addAction(ImagePickerAction(cancelTitle: NSLocalizedString("Cancel", comment: "Action Title")))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            controller.modalPresentationStyle = .popover
            controller.popoverPresentationController?.sourceView = view
            controller.popoverPresentationController?.sourceRect = CGRect(origin: view.center, size: CGSize())
        }
        
        present(controller, animated: true, completion: nil)
        
    }
    var progressBar = UIProgressView()
    var alertView: UIAlertController?
    
    func uploadAsync(_ assets: [PHAsset]){
        alertView = UIAlertController(title: "Uploading...", message: "Your images are uploading to Imgur", preferredStyle: .alert)
        alertView!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertView!, animated: true, completion: {
            //  Add your progressbar after alert is shown (and measured)
            let margin:CGFloat = 8.0
            let rect = CGRect.init(x: margin, y: 72.0, width: (self.alertView?.view.frame.width)! - margin * 2.0 , height: 2.0)
            self.progressBar = UIProgressView(frame: rect)
            self.progressBar.progress = 0.5
            self.progressBar.tintColor = ColorUtil.accentColorForSub(sub: self.sub)
            self.alertView?.view.addSubview(self.progressBar)
        })
        
        if assets.count > 1 {
            Alamofire.request("https://api.imgur.com/3/album",  method: .post, parameters: nil,  encoding: JSONEncoding.default, headers: ["Authorization": "Client-ID bef87913eb202e9"])
                .responseJSON { response in
                    print(response)
                    if let status = response.response?.statusCode {
                        switch(status){
                        case 201:
                            print("example success")
                        default:
                            print("error with response status: \(status)")
                        }
                    }
                    
                    if let result = response.value {
                        let json = JSON(result)
                        print(json)
                        let album = json["data"]["deletehash"].stringValue
                        let url = "https://imgur.com/a/" + json["data"]["id"].stringValue
                        self.uploadImages(assets, album: album, completion: { (last) in
                            DispatchQueue.main.async {
                                self.alertView!.dismiss(animated: true, completion: {
                                    if last != "Failure" {
                                        
                                        let alert = UIAlertController(title: "Link text", message: url, preferredStyle: .alert)
                                        
                                        alert.addTextField { (textField) in
                                            textField.text = ""
                                        }
                                        alert.addAction(UIAlertAction(title: "Insert", style: .default, handler: { (action) in
                                            let textField = alert.textFields![0] // Force unwrapping because we know it exists.
                                            self.text!.insertText("[\(textField.text!)](\(url))")
                                            
                                        }))
                                        
                                        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
                                        self.present(alert, animated: true, completion: nil)
                                    } else {
                                        let alert = UIAlertController(title: "Uploading failed", message: "Uh oh, something went wrong while uploading to Imgur. Please try again in a few minutes", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
                                        self.present(alert, animated: true, completion: nil)
                                    }
                                })
                            }
                        })
                    }
                    
            }
            
        } else {
            uploadImages(assets, album: "", completion: { (link) in
                DispatchQueue.main.async {
                    self.alertView!.dismiss(animated: true, completion: {
                        if link != "Failure" {
                            let alert = UIAlertController(title: "Link text", message: link, preferredStyle: .alert)
                            
                            alert.addTextField { (textField) in
                                textField.text = ""
                            }
                            alert.addAction(UIAlertAction(title: "Insert", style: .default, handler: { (action) in
                                let textField = alert.textFields![0] // Force unwrapping because we know it exists.
                                self.text!.insertText("[\(textField.text!)](\(link))")
                                
                            }))
                            
                            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            let alert = UIAlertController(title: "Uploading failed", message: "Uh oh, something went wrong while uploading to Imgur. Please try again in a few minutes", preferredStyle: .alert)
                            alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                        
                    })
                }
            })
        }
    }
    
    func uploadImages(_ assets: [PHAsset], album: String, completion: @escaping (String) -> Void ){
        var count = 0
        for image in assets {
            count += 1
            let parameters = [:] as [String: String]//todo albums
            var name = UUID.init().uuidString
            PHImageManager.default().requestImageData(for: image, options: nil, resultHandler: { (data, uti, _, info) in
                if let fileName = (info?["PHImageFileURLKey"] as? NSURL)?.lastPathComponent {
                    name = fileName
                }
                let mime = UTTypeCopyPreferredTagWithClass(uti as! CFString, kUTTagClassMIMEType)?.takeRetainedValue()
                
                Alamofire.upload(multipartFormData: { (multipartFormData) in
                    multipartFormData.append(data!, withName: "image", fileName: name, mimeType: mime as! String)
                    for (key, value) in parameters {
                        multipartFormData.append((value.data(using: .utf8))!, withName: key)
                    }
                    if(!album.isEmpty){
                        multipartFormData.append(album.data(using: .utf8)!, withName: "album")
                    }
                }, to: "https://api.imgur.com/3/image", method: .post, headers: ["Authorization": "Client-ID bef87913eb202e9"], encodingCompletion: { (encodingResult) in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        print("Success")
                        upload.uploadProgress { progress in
                            DispatchQueue.main.async {
                                self.progressBar.setProgress(Float(progress.fractionCompleted), animated: true)
                            }
                        }
                        upload.responseJSON { response in
                            debugPrint(response)
                            let link = JSON(response.value!)["data"]["link"].stringValue
                            print("Link is \(link)")
                            if(count == assets.count){
                                completion(link)
                            }
                        }
                        
                    case .failure:
                        completion("Failure")
                    }
                })
            })
        }
        
    }
    
    
    func draw(_ sender: UIButton!){
        
    }
    
    func link(_ sender: UIButton!){
        
    }
    
    func bold(_ sender: UIButton!){
        wrapIn("*")
    }
    
    func italics(_ sender: UIButton!){
        wrapIn("**")
    }
    
    func list(_ sender: UIButton!){
        replaceIn("\n", with: "\n* ")
    }
    
    func numberedList(_ sender: UIButton!){
        replaceIn("\n", with: "\n1. ")
        
    }
    
    func size(_ sender: UIButton!){
        replaceIn("\n", with: "\n#")
    }
    
    func strike(_ sender: UIButton!){
        wrapIn("~~")
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
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: sub)
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        if(message){
            title = "New message"
        } else {
            let author = (toReplyTo is Comment) ? ((toReplyTo as! Comment).author) : ((toReplyTo as! Link).author)
            if(edit){
                title = "Editing"
            } else {
                title = "Reply to \(author)"
            }
        }
        
        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close"), for: UIControlState.normal)
        close.addTarget(self, action: #selector(self.close(_:)), for: UIControlEvents.touchUpInside)
        close.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let closeB = UIBarButtonItem.init(customView: close)
        
        navigationItem.leftBarButtonItems = [closeB]
        
        
        let send = UIButton.init(type: .custom)
        send.setImage(UIImage.init(named: "send"), for: UIControlState.normal)
        send.addTarget(self, action: #selector(self.send(_:)), for: UIControlEvents.touchUpInside)
        send.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let sendB = UIBarButtonItem.init(customView: send)
        navigationItem.rightBarButtonItem = sendB
        registerKeyboardNotifications()
        
    }
    
    func close(_ sender: AnyObject){
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    var alertController: UIAlertController?
    var session: Session?
    var comment: Comment?
    
    func getCommentEdited(_ name: String){
        do {
            try self.session?.getInfo([name], completion: { (res) in
                switch res {
                case .failure:
                    print(res.error ?? "Error?")
                case .success(let listing):
                    if listing.children.count == 1 {
                        if let comment = listing.children[0] as? Comment {
                            self.comment = comment
                            self.reply(self.comment)
                        }
                    }
                }
                
            })
        } catch {
            
        }
        
    }
    
    func send(_ sender: AnyObject){
        if(message){
            alertController = UIAlertController(title: nil, message: "Sending message...\n\n", preferredStyle: .alert)
            let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.black
            spinnerIndicator.startAnimating()
            
            alertController?.view.addSubview(spinnerIndicator)
            self.present(alertController!,animated: true, completion: nil)
            
            session = (UIApplication.shared.delegate as! AppDelegate).session

            if(toReplyTo == nil){
                do {
                    try self.session?.composeMessage(recipientCell.cellLabel.text!, subject: subjectCell.cellLabel.text!, text: text!.text, completion: { (result) in
                        switch result {
                        case .failure(let error):
                            print(error.description)
                            self.reply(nil)
                        case .success(let postedComment):
                            self.reply(self.comment)
                        }

                    })
                } catch { print((error as NSError).description) }
            } else {
            
                do {
                    let name = toReplyTo?.getId()
                    try self.session?.replyMessage(text!.text, parentName:name!, completion: { (result) -> Void in
                        switch result {
                        case .failure(let error):
                            print(error.description)
                            self.reply(nil)
                        case .success(let postedComment):
                            self.reply(self.comment)
                        }
                    })
                } catch { print((error as NSError).description) }
            }
        } else if(edit){
            alertController = UIAlertController(title: nil, message: "Editing comment...\n\n", preferredStyle: .alert)
            
            let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.black
            spinnerIndicator.startAnimating()
            
            alertController?.view.addSubview(spinnerIndicator)
            self.present(alertController!,animated: true, completion: nil)
            
            session = (UIApplication.shared.delegate as! AppDelegate).session
            
            do {
                let name = toReplyTo?.getId()
                try self.session?.editCommentOrLink(name!, newBody: text!.text, completion: { (result) in
                    self.getCommentEdited(name!)
                })
            } catch { print((error as NSError).description) }
            
        } else {
            alertController = UIAlertController(title: nil, message: "Sending reply...\n\n", preferredStyle: .alert)
            
            let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.black
            spinnerIndicator.startAnimating()
            
            alertController?.view.addSubview(spinnerIndicator)
            self.present(alertController!,animated: true, completion: nil)
            
            session = (UIApplication.shared.delegate as! AppDelegate).session
            
            do {
                let name = toReplyTo?.getId()
                try self.session?.postComment(text!.text, parentName:name!, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        self.reply(nil)
                    case .success(let postedComment):
                        self.comment = postedComment
                        self.reply(self.comment)
                    }
                })
            } catch { print((error as NSError).description) }
        }
        
    }
    
    override func loadView() {
        super.loadView()

        self.tableView.backgroundColor = ColorUtil.backgroundColor
        
        text = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 500))
        text?.isEditable = true
        text?.backgroundColor = ColorUtil.foregroundColor
        text?.textColor = ColorUtil.fontColor
        text?.delegate = self
        text?.font = UIFont.systemFont(ofSize: 18)
        if(edit){
            text!.text = (toReplyTo as! Comment).body
        }
        
        let lineView = UIView(frame: CGRect.init(x: 0, y: 0, width: (text?.frame.size.width)!, height: 1))
        lineView.backgroundColor = ColorUtil.backgroundColor
        text?.addSubview(lineView)

        
        subjectCell = InputCell.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 70), input: "[menu]Subject")
        recipientCell = InputCell.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 70), input: "[profile]Recipient")
        if(toReplyTo != nil && message){
            subjectCell.cellLabel.text = "re: " + (toReplyTo as! Message).subject
            subjectCell.cellLabel.isEditable = false
            recipientCell.cellLabel.text = (toReplyTo as! Message).author
            recipientCell.cellLabel.isEditable = false
        }

        tableView.tableFooterView = text
        if(header != nil){
            tableView.tableHeaderView = header
        }

    }
    
    func dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
extension UIView {
    
    func embedInScrollView()->UIView{
        let cont=UIScrollView()
        
        self.translatesAutoresizingMaskIntoConstraints = false;
        cont.translatesAutoresizingMaskIntoConstraints = false;
        cont.addSubview(self)
        cont.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[innerView]|", options: NSLayoutFormatOptions(rawValue:0),metrics: nil, views: ["innerView":self]))
        cont.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[innerView]|", options: NSLayoutFormatOptions(rawValue:0),metrics: nil, views: ["innerView":self]))
        cont.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: cont, attribute: .width, multiplier: 1.0, constant: 0))
        return cont
    }
}
extension ReplyViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ReplyViewController: ImagePickerSheetControllerDelegate {
    
    func controllerWillEnlargePreview(_ controller: ImagePickerSheetController) {
        print("Will enlarge the preview")
    }
    
    func controllerDidEnlargePreview(_ controller: ImagePickerSheetController) {
        print("Did enlarge the preview")
    }
    
    func controller(_ controller: ImagePickerSheetController, willSelectAsset asset: PHAsset) {
        print("Will select an asset")
    }
    
    func controller(_ controller: ImagePickerSheetController, didSelectAsset asset: PHAsset) {
        print("Did select an asset")
    }
    
    func controller(_ controller: ImagePickerSheetController, willDeselectAsset asset: PHAsset) {
        print("Will deselect an asset")
    }
    
    func controller(_ controller: ImagePickerSheetController, didDeselectAsset asset: PHAsset) {
        print("Did deselect an asset")
    }
    
}


class InputCell: UITableViewCell {
    var cellLabel: UITextView!
    
    init(frame: CGRect, input: String) {
        super.init(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
        
        cellLabel = UITextView(frame: CGRect.init(x: 0, y: 0, width: self.frame.size.width, height: 70))
        cellLabel.textColor = ColorUtil.fontColor
        cellLabel.font = UIFont.boldSystemFont(ofSize: 16)
        cellLabel.placeholder = input
        
        cellLabel.textContainerInset = UIEdgeInsets.init(top: 30, left: 10, bottom: 0, right: 0)
        backgroundColor = ColorUtil.foregroundColor
        
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
            }
            else {
                placeHolderLabel?.text = newValue
                placeHolderLabel?.sizeToFit()
            }
        }
    }
    
    // Hide the placeholder label if there is no text
    // in the text viewotherwise, show the label
    public func textViewDidChange(textView: UITextView) {
        
        let placeHolderLabel = self.viewWithTag(100)
        
        if !self.hasText {
            // Get the placeholder label
            placeHolderLabel?.isHidden = false
        }
        else {
            placeHolderLabel?.isHidden = true
        }
    }
    
    // Add a placeholder label to the text view
    func addPlaceholderLabel(placeholderText: String) {
        
        // Create the label and set its properties
        let placeholderLabel = UILabel()
        let placeholderImage = placeholderText.startsWith("[") ? placeholderText.substring(1, length: placeholderText.indexOf("]")! - 1) : ""
        var text = placeholderText
        if(!placeholderImage.isEmpty){
            text = text.substring(placeholderText.indexOf("]")! + 1, length: text.length - placeholderText.indexOf("]")! - 1)
        }
        
        placeholderLabel.text = " " + text
        placeholderLabel.frame.origin.x = 10
        placeholderLabel.frame.origin.y = 5
        placeholderLabel.font = UIFont.systemFont(ofSize: 14)
        placeholderLabel.textColor = ColorUtil.fontColor.withAlphaComponent(0.8)
        placeholderLabel.tag = 100
        if(!placeholderImage.isEmpty){
            placeholderLabel.addImage(imageName: placeholderImage)
        }
        placeholderLabel.sizeToFit()

        
        // Hide the label if there is text in the text view
        placeholderLabel.isHidden = ((self.text.length) > 0)
        
        self.addSubview(placeholderLabel)
        self.delegate = self;
    }
    
}
