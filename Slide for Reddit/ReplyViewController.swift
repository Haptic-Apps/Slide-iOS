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

class ReplyViewController: UIViewController, UITextViewDelegate {
    
    var toReplyTo: Thing
    var text: UITextView?
    var sub: String
    var scrollView: UIScrollView?
    
    init(thing: Thing, sub: String){
        self.toReplyTo = thing
        self.sub = sub
        super.init(nibName: nil, bundle: nil)
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
    
    
    func saveDraft(_ sender: UIButton!){
        if let toSave = text!.text {
            if(!toSave.isEmpty()){
                Drafts.addDraft(s: text!.text)
                self.view.makeToast("Draft saved", duration: 4, position: .top)
            }
        }
    }
    
    var picker: ActionSheetStringPicker?
    var doneButton: UIBarButtonItem?
    
    func openDrafts(_ sender: AnyObject){
        if(Drafts.drafts.isEmpty){
            self.view.makeToast("No drafts found", duration: 4, position: .top)
        } else {
            picker = ActionSheetStringPicker(title: "Choose a draft", rows: Drafts.drafts, initialSelection: 0, doneBlock: { (picker, index, value) in
                self.text!.insertText(Drafts.drafts[index] as String)
            }, cancel: { (picker) in
                return
            }, origin: sender)
            
            doneButton = UIBarButtonItem.init(title: "Insert", style: .done, target: nil, action: nil)
            picker?.setDoneButton(doneButton)
            picker?.addCustomButton(withTitle: "Delete", target: self, selector: #selector(ReplyViewController.doDelete))
            picker?.show()
            
        }
    }
    
    func doDelete(){
        Drafts.deleteDraft(s: Drafts.drafts[(picker?.selectedIndex)!] as String)
        self.openDrafts(self)
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
        let author = (toReplyTo is Comment) ? ((toReplyTo as! Comment).author) : ((toReplyTo as! Link).author)
        title = "Reply to \(author)"
        
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
    
    func send(_ sender: AnyObject){
        //todo this
        self.close(sender)
    }
    
    override func loadView() {
        self.view = UITextView(frame: CGRect.zero)
        text = self.view as? UITextView
        text?.isEditable = true
        text?.backgroundColor = ColorUtil.foregroundColor
        text?.textColor = ColorUtil.fontColor
        text?.delegate = self
        text?.font = UIFont.systemFont(ofSize: 18)
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
