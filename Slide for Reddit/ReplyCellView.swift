//
//  ReplyCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/15/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import Photos
import ImagePickerSheetController
import Alamofire
import MobileCoreServices
import SwiftyJSON
import ActionSheetPicker_3_0
import RealmSwift
import MaterialComponents.MaterialSnackbar

protocol ReplyDelegate {
    func replySent(comment: Comment?)
    func updateHeight(textView: UITextView)
    func discard()
    func editSent(cr: Comment?)
}

class ReplyCellView: UITableViewCell, UITextViewDelegate {
    var delegate: ReplyDelegate?
    var toReplyTo: Object?
    var body: UITextView = UITextView()
    var sendB = UIButton()
    var discardB = UIButton()
    var edit = false
    var parent : CommentViewController?
    var subreddit = ""
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        sendB = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 60))
        discardB = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 60))
        body = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60))
        
        self.sendB.setTitle("Send", for: .normal)
        self.discardB.setTitle("Discard", for: .normal)
        
        sendB.translatesAutoresizingMaskIntoConstraints = false
        discardB.translatesAutoresizingMaskIntoConstraints = false
        body.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(sendB)
        self.contentView.addSubview(discardB)
        self.contentView.addSubview(body)
        
        sendB.addTarget(self, action: #selector(ReplyCellView.send(_:)), for: UIControlEvents.touchUpInside)
        discardB.addTarget(self, action: #selector(ReplyCellView.discard(_:)), for: UIControlEvents.touchUpInside)

        updateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var alertController: UIAlertController?
    var session: Session?
    var comment: Comment?
    
    func edit(_ sender: AnyObject){
        alertController = UIAlertController(title: nil, message: "Editing comment...\n\n", preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()
        
        alertController?.view.addSubview(spinnerIndicator)
        parent!.present(alertController!,animated: true, completion: nil)
        
        session = (UIApplication.shared.delegate as! AppDelegate).session
        
        do {
            let name = toReplyTo is RMessage ? (toReplyTo as! RMessage).getId() : toReplyTo is RComment ? (toReplyTo as! RComment).getId() : (toReplyTo as! RSubmission).getId()
            try self.session?.editCommentOrLink(name, newBody: body.text!, completion: { (result) in
                self.getCommentEdited(name)
            })
        } catch { print((error as NSError).description) }
    }
    
    func getCommentEdited(_ name: String){
        do {
            try self.session?.getInfo([name], completion: { (res) in
                switch res {
                case .failure:
                    DispatchQueue.main.async {
                        self.saveDraft(self)
                        self.alertController?.dismiss(animated: false, completion: {
                            let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your message has not been edited (but has been saved as a draft), please try again", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self.parent!.present(alert, animated: true, completion: nil)
                        })
                        self.delegate!.editSent(cr: nil)
                    }
                case .success(let listing):
                    if listing.children.count == 1 {
                        if let comment = listing.children[0] as? Comment {
                            self.comment = comment
                            DispatchQueue.main.async {
                                self.alertController?.dismiss(animated: false, completion: {
                                    self.parent!.dismiss(animated: true, completion: nil)
                                })
                                print("Editing done")
                                self.delegate!.editSent(cr: self.comment)
                            }

                        }
                    }
                }
                
            })
        } catch {
            DispatchQueue.main.async {
                self.saveDraft(self)
                self.alertController?.dismiss(animated: false, completion: {
                    let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your message has not been edited (but has been saved as a draft), please try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.parent!.present(alert, animated: true, completion: nil)
                })
                self.delegate!.editSent(cr: nil)
            }
        }
        
    }


    func send(_ sender: AnyObject){
        if(edit){
            edit(sender)
            return
        }
        session = (UIApplication.shared.delegate as! AppDelegate).session
        alertController = UIAlertController(title: nil, message: "Sending reply...\n\n", preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()
        
        alertController?.view.addSubview(spinnerIndicator)
        parent!.present(alertController!,animated: true, completion: nil)
        
        do {
            let name = toReplyTo is RMessage ? (toReplyTo as! RMessage).getId() : toReplyTo is RComment ? (toReplyTo as! RComment).getId() : (toReplyTo as! RSubmission).getId()
            try self.session?.postComment(body.text!, parentName:name, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        self.saveDraft(self)
                        self.alertController?.dismiss(animated: false, completion: {
                            let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your comment has not been sent (but has been saved as a draft), please try again", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self.parent!.present(alert, animated: true, completion: nil)
                        })
                        self.delegate!.replySent(comment: nil)
                    }
                case .success(let postedComment):
                    self.comment = postedComment
                    DispatchQueue.main.async {
                        self.alertController?.dismiss(animated: false, completion: {
                            self.parent!.dismiss(animated: true, completion: nil)
                        })
                        self.delegate!.replySent(comment: self.comment)
                    }
                }
            })
        } catch {
            DispatchQueue.main.async {
                self.saveDraft(self)
                self.alertController?.dismiss(animated: false, completion: {
                    let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your comment has not been sent (but has been saved as a draft), please try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.parent!.present(alert, animated: true, completion: nil)
                })
                self.delegate!.replySent(comment: nil)
            }

        }
    }
    
  func discard(_ sender: AnyObject){
        delegate!.discard()
    }
    
    var sideConstraint: [NSLayoutConstraint] = []
    
    override func updateConstraints() {
        super.updateConstraints()

        let metrics:[String:Int]=[:]
        let views=["body":body, "send":sendB, "discard":discardB] as [String : Any]
        
        sideConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[body]-|",
                                                        options: NSLayoutFormatOptions(rawValue: 0),
                                                        metrics: metrics,
                                                        views: views)
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[body(>=80)]-[send(40)]-|", options: NSLayoutFormatOptions(rawValue:0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[body(>=80)]-[discard(40)]-|", options: NSLayoutFormatOptions(rawValue:0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[send]-16-|", options: NSLayoutFormatOptions(rawValue:0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[discard]", options: NSLayoutFormatOptions(rawValue:0), metrics: metrics, views: views))

        self.contentView.addConstraints(sideConstraint)
    }

    func setContent(thing: Object, sub: String, editing: Bool, delegate: ReplyDelegate, parent: CommentViewController){
        body.text = ""
        comment = nil
        addToolbarToTextView()
        toReplyTo = thing
        edit = editing
        self.contentView.backgroundColor = ColorUtil.getColorForSub(sub: sub)
        self.delegate = delegate
        body.delegate = self
        self.parent = parent
        subreddit = sub
        body.isEditable = true
        body.textColor = .white
        body.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        body.layer.masksToBounds = false
        body.layer.cornerRadius = 10
        body.font = UIFont.systemFont(ofSize: 16)
        body.isScrollEnabled = false
        body.becomeFirstResponder()
        if(edit){
            body.text = (thing as! RComment).body
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        delegate!.updateHeight(textView: body)
    }
    
    func addToolbarToTextView(){
        let scrollView = TouchUIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: body.frame.size.width, height: 50))
        scrollView.contentSize = CGSize.init(width: 50 * 11, height: 50)
        scrollView.autoresizingMask = .flexibleWidth
        scrollView.backgroundColor = ColorUtil.backgroundColor
        var i = 0
        for button in ([
            generateButtons(image: "save", action: #selector(ReplyCellView.saveDraft(_:))),
            generateButtons(image: "folder", action: #selector(ReplyCellView.openDrafts(_:))),
            generateButtons(image: "image", action: #selector(ReplyCellView.uploadImage(_:))),
            generateButtons(image: "draw", action: #selector(ReplyCellView.drawD(_:))),
            generateButtons(image: "link", action: #selector(ReplyCellView.link(_:))),
            generateButtons(image: "bold", action: #selector(ReplyCellView.bold(_:))),
            generateButtons(image: "italic", action: #selector(ReplyCellView.italics(_:))),
            generateButtons(image: "list", action: #selector(ReplyCellView.list(_:))),
            generateButtons(image: "list_number", action: #selector(ReplyCellView.numberedList(_:))),
            generateButtons(image: "size", action: #selector(ReplyCellView.size(_:))),
            generateButtons(image: "strikethrough", action: #selector(ReplyCellView.strike(_:)))]) {
                button.0.frame = CGRect.init(x: i * 50, y: 0, width: 50, height: 50)
                button.0.isUserInteractionEnabled = true
                button.0.addTarget(self, action: button.1, for: UIControlEvents.touchUpInside)
                scrollView.addSubview(button.0)
                i += 1
        }
        scrollView.delaysContentTouches = false
        body.inputAccessoryView = scrollView
    }
    
    func generateButtons(image: String, action: Selector) -> (UIButton, Selector) {
        let more = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        more.setImage(UIImage.init(named: image)?.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        return (more, action)
    }
    
    func wrapIn(_ value: String){
        body.replace(body.selectedTextRange!, withText: value + body.text(in: body.selectedTextRange!)! + value)
    }
    
    func replaceIn(_ value: String, with: String){
        body.replace(body.selectedTextRange!, withText: with + body.text(in: body.selectedTextRange!)!.replacingOccurrences(of: value, with: with))
    }
    
    
    func saveDraft(_ sender: AnyObject){
        if let toSave = body.text {
            if(!toSave.isEmpty()){
                Drafts.addDraft(s: body.text)
                let message = MDCSnackbarMessage()
                message.text = "Draft saved"
                MDCSnackbarManager.show(message)
            }
        }
    }
    
    var picker: ActionSheetStringPicker?
    
    func openDrafts(_ sender: AnyObject){
        print("Opening drafts")
        if(Drafts.drafts.isEmpty){
            self.contentView.makeToast("No drafts found", duration: 4, position: .top)
        } else {
            picker = ActionSheetStringPicker(title: "Choose a draft", rows: Drafts.drafts, initialSelection: 0, doneBlock: { (picker, index, value) in
                self.body.insertText(Drafts.drafts[index] as String)
            }, cancel: { (picker) in
                return
            }, origin: body)
            
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
            
            self.parent!.present(controller, animated: true, completion: nil)
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
            controller.popoverPresentationController?.sourceView = self.contentView
            controller.popoverPresentationController?.sourceRect = CGRect(origin: self.contentView.center, size: CGSize())
        }
        
        parent!.present(controller, animated: true, completion: nil)
        
    }
    var progressBar = UIProgressView()
    var alertView: UIAlertController?
    
    func uploadAsync(_ assets: [PHAsset]){
        alertView = UIAlertController(title: "Uploading...", message: "Your images are uploading to Imgur", preferredStyle: .alert)
        alertView!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.parent!.present(alertView!, animated: true, completion: {
            //  Add your progressbar after alert is shown (and measured)
            let margin:CGFloat = 8.0
            let rect = CGRect.init(x: margin, y: 72.0, width: (self.alertView?.view.frame.width)! - margin * 2.0 , height: 2.0)
            self.progressBar = UIProgressView(frame: rect)
            self.progressBar.progress = 0
            self.progressBar.tintColor = ColorUtil.accentColorForSub(sub: self.subreddit)
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
                                            self.body.insertText("[\(textField.text!)](\(url))")
                                            
                                        }))
                                        
                                        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
                                        self.parent!.present(alert, animated: true, completion: nil)
                                    } else {
                                        let alert = UIAlertController(title: "Uploading failed", message: "Uh oh, something went wrong while uploading to Imgur. Please try again in a few minutes", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
                                        self.parent!.present(alert, animated: true, completion: nil)
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
                                self.body.insertText("[\(textField.text!)](\(link))")
                                
                            }))
                            
                            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
                            self.parent!.present(alert, animated: true, completion: nil)
                        } else {
                            let alert = UIAlertController(title: "Uploading failed", message: "Uh oh, something went wrong while uploading to Imgur. Please try again in a few minutes", preferredStyle: .alert)
                            alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
                            self.parent!.present(alert, animated: true, completion: nil)
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
                let mime = UTTypeCopyPreferredTagWithClass(uti! as CFString, kUTTagClassMIMEType)?.takeRetainedValue()
                
                Alamofire.upload(multipartFormData: { (multipartFormData) in
                    multipartFormData.append(data!, withName: "image", fileName: name, mimeType: mime! as String)
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
                                print(progress.fractionCompleted)
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
    
    
    func drawD(_ sender: UIButton!){
        
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
    
}
extension ReplyCellView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    }
}

extension ReplyCellView: ImagePickerSheetControllerDelegate {
    
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

