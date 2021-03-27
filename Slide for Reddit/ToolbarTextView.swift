//
// Created by Carlos Crane on 2/15/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

import Alamofire
import Anchorage
import MobileCoreServices
import OpalImagePicker
import Photos
import PhotosUI
import RLBAlertsPickers
import SDCAlertView
import SwiftyJSON
import UIKit

public class ToolbarTextView: NSObject {

    var text: UITextView?
    weak var parent: UIViewController?
    var picker: NSObject?
    var replyText: String?

    init(textView: UITextView, parent: UIViewController, replyText: String?) {
        self.text = textView
        self.parent = parent
        self.replyText = replyText
        super.init()
        addToolbarToTextView()
    }

    func addToolbarToTextView() {
        let scrollView = TouchUIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: text!.frame.size.width, height: 50))
        scrollView.contentSize = CGSize.init(width: 50 * 11, height: 50)
        scrollView.autoresizingMask = .flexibleWidth
        scrollView.backgroundColor = UIColor.backgroundColor
        var i = 0
        var buttons = [
            generateButtons(image: "save", sfString: SFSymbol.starFill, action: #selector(ToolbarTextView.saveDraft(_:))),
            generateButtons(image: "folder", sfString: SFSymbol.folderFill, action: #selector(ToolbarTextView.openDrafts(_:))),
            generateButtons(image: "image", sfString: SFSymbol.photoFill, action: #selector(ToolbarTextView.uploadImage(_:))),
            generateButtons(image: "link", sfString: SFSymbol.link, action: #selector(ToolbarTextView.link(_:))),
            generateButtons(image: "bold", sfString: SFSymbol.bold, action: #selector(ToolbarTextView.bold(_:))),
            generateButtons(image: "italic", sfString: SFSymbol.italic, action: #selector(ToolbarTextView.italics(_:))),
            generateButtons(image: "list", sfString: SFSymbol.listBullet, action: #selector(ToolbarTextView.list(_:))),
            generateButtons(image: "list_number", sfString: SFSymbol.listNumber, action: #selector(ToolbarTextView.numberedList(_:))),
            generateButtons(image: "size", sfString: SFSymbol.textformatSize, action: #selector(ToolbarTextView.size(_:))),
            generateButtons(image: "strikethrough", sfString: SFSymbol.strikethrough, action: #selector(ToolbarTextView.strike(_:))), ]
        
        if replyText != nil {
            buttons.insert(generateButtons(image: "comments", sfString: SFSymbol.quoteBubbleFill, action: #selector(ToolbarTextView.quote(_:))), at: 3)
        }
        
        for button in (buttons) {
            button.0.frame = CGRect.init(x: i * 50, y: 0, width: 50, height: 50)
            button.0.isUserInteractionEnabled = true
            button.0.addTarget(self, action: button.1, for: UIControl.Event.touchUpInside)
            scrollView.addSubview(button.0)
            i += 1
        }
        scrollView.delaysContentTouches = false
        text!.inputAccessoryView = scrollView
        if !(parent is ReplyViewController) {
            text!.tintColor = .white
        } else {
            text!.tintColor = UIColor.fontColor
        }
        if !UIColor.isLightTheme {
            text!.keyboardAppearance = .dark
        }
    }

    func generateButtons(image: String, sfString: SFSymbol?, action: Selector) -> (UIButton, Selector) {
        let more = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        if let strongSFString = sfString {
            more.setImage(UIImage(sfString: strongSFString, overrideString: image)?.menuIcon(), for: UIControl.State.normal)
        } else {
            more.setImage(UIImage(named: image)?.menuIcon(), for: UIControl.State.normal)
        }
        return (more, action)
    }

    func wrapIn(_ value: String) {
        if let selectedRange = text?.selectedTextRange, let textValue = text?.text(in: selectedRange) {
            let wrapped = value + textValue + value
            text?.replace(selectedRange, withText: wrapped)
            
            if wrapped.length == value.length * 2 {
                if let newPosition = text?.position(from: selectedRange.end, offset: (value.length)) {
                    text?.selectedTextRange = text?.textRange(from: newPosition, to: newPosition)
                }
            }
        }
        
    }

    func replaceIn(_ value: String, with: String) {
        if let selectedRange = text?.selectedTextRange, let textValue = text?.text(in: selectedRange) {
            text?.replace(selectedRange, withText: with + textValue.replacingOccurrences(of: value, with: with))
        }
    }

    @objc func saveDraft(_ sender: AnyObject?) {
        if let toSave = text!.text {
            if !toSave.isEmpty() {
                Drafts.addDraft(s: text!.text)
                BannerUtil.makeBanner(text: "Draft saved!", seconds: 3, context: parent, top: true)
            }
        }
    }

    @objc func openDrafts(_ sender: AnyObject) {
        print("Opening drafts")
        parent?.view.endEditing(true)
        let alert = AlertController(title: "Drafts", message: "", preferredStyle: .alert)
        
        alert.setupTheme()
        
        alert.attributedTitle = NSAttributedString(string: "Drafts", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
        
        let inner = DraftFindReturnViewController { (_) in
        }
        let innerView = inner.view!
        
        alert.contentView.addSubview(innerView)
        
        innerView.edgeAnchors /==/ alert.contentView.edgeAnchors - 8
        innerView.heightAnchor /==/ CGFloat(200)
        
        alert.addAction(AlertAction(title: "Insert", style: .preferred, handler: { (_) in
            let selectedData = inner.tableView.indexPathsForSelectedRows?.map { inner.baseDrafts[$0.row] }
            if selectedData != nil {
                for draft in selectedData! {
                    self.text?.insertText(draft)
                    self.text?.insertText(" ")
                }
                self.text?.becomeFirstResponder()
            }
        }))
        alert.addAction(AlertAction(title: "Delete", style: .normal, handler: { (_) in
            let selectedData = inner.tableView.indexPathsForSelectedRows?.map { inner.baseDrafts[$0.row] }
            if selectedData != nil {
                for draft in selectedData! {
                    Drafts.deleteDraft(s: draft)
                }
                BannerUtil.makeBanner(text: "\(selectedData!.count) drafts deleted", color: GMColor.red500Color(), seconds: 2, context: self.parent, top: true, callback: nil)
                self.text?.becomeFirstResponder()
            }
        }))
        let cancelAction = AlertAction(title: "Close", style: .preferred, handler: { (_) in
            self.text?.becomeFirstResponder()
        })
        alert.addAction(cancelAction)

        alert.addBlurView()
        
        parent?.present(alert, animated: true, completion: nil)
        /*
        if Drafts.drafts.isEmpty {
            parent.view.makeToast("No drafts found", duration: 4, position: .top)
        } else {
            var drafts = [NSString]()
            
            for arrayIndex in stride(from: Drafts.drafts.count - 1, through: 0, by: -1) {
                drafts.append(Drafts.drafts[arrayIndex])
            }

            picker = ActionSheetStringPicker(title: "Choose a draft", rows: drafts, initialSelection: 0, doneBlock: { (_, index, _) in
                self.text!.insertText(drafts[index] as String)
            }, cancel: { (_) in
                return
            }, origin: text!)

            let doneButton = UIBarButtonItem.init(title: "Insert", style: .done, target: nil, action: nil)
            picker?.setDoneButton(doneButton)
            picker?.addCustomButton(withTitle: "Delete Draft", actionBlock: {
                if let p = self.picker?.pickerView as? UIPickerView
                {
                    var current = drafts[p.selectedRow(inComponent: 0)]
                    Drafts.deleteDraft(s: current as String)
                    
                    self.openDrafts(sender)
                }
            })
            picker?.show()

        }*/
    }
    
    @objc func uploadImage(_ sender: UIButton!) {
        if #available(iOS 14.0, *) {
            
            var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())

            config.filter = .images
            config.selectionLimit = 0
            
            let localPicker = PHPickerViewController(configuration: config)
            localPicker.delegate = self
            self.picker = localPicker
            
            parent?.present(localPicker, animated: true)
             
            /*let library = PHPhotoLibrary.shared() //Choose new photos to grant access to
            if let parent = parent {
                library.presentLimitedLibraryPicker(from: parent)
            }*/
        } else {
            let imagePicker = OpalImagePickerController()
            imagePicker.allowedMediaTypes = [PHAssetMediaType.image]
            self.parent?.presentOpalImagePickerController(imagePicker, animated: true,
                                             select: { (assets) in
                                                imagePicker.dismiss(animated: true, completion: {
                                                    if !assets.isEmpty {
                                                        let alert = UIAlertController.init(title: "Confirm upload", message: "Would you like to upload \(assets.count) image\(assets.count > 1 ? "s" : "") anonymously to Imgur.com? This cannot be undone", preferredStyle: .alert)
                                                        alert.addAction(UIAlertAction.init(title: "No", style: .destructive, handler: nil))
                                                        alert.addAction(UIAlertAction.init(title: "Yes", style: .default) { _ in
                                                            self.uploadAsync(assets)
                                                        })
                                                        self.parent?.present(alert, animated: true, completion: nil)
                                                    }

                                                })
            }, cancel: {
                imagePicker.dismiss(animated: true)
            })
        }
    }

    var progressBar = UIProgressView()
    var alertView: UIAlertController?

    var insertText: String?

    // Legacy for iOS <= iOS 13
    func uploadAsync(_ assets: [PHAsset]) {
        alertView = UIAlertController(title: "Uploading...", message: "Your images are uploading to Imgur", preferredStyle: .alert)
        alertView!.addCancelButton()

        parent?.present(alertView!, animated: true, completion: {
            //  Add your progressbar after alert is shown (and measured)
            let margin: CGFloat = 8.0
            let rect = CGRect.init(x: margin, y: 72.0, width: (self.alertView?.view.frame.width)! - margin * 2.0, height: 2.0)
            self.progressBar = UIProgressView(frame: rect)
            self.progressBar.progress = 0
            self.progressBar.tintColor = ColorUtil.accentColorForSub(sub: "")
            self.alertView?.view.addSubview(self.progressBar)
        })

        if assets.count > 1 {
            AF.request("https://api.imgur.com/3/album", method: .post, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization": "Client-ID bef87913eb202e9"])
                    .responseJSON { response in
                        print(response)
                        if let status = response.response?.statusCode {
                            switch status {
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
                                            if self.parent is ReplyViewController && (self.parent as! ReplyViewController).type == .SUBMIT_IMAGE {
                                                (self.parent as! ReplyViewController).text!.last!.text = url
                                            } else {
                                                let alert = AlertController(title: "Link text", message: url, preferredStyle: .alert)

                                                let config: TextField.Config = { textField in
                                                    textField.becomeFirstResponder()
                                                    textField.textColor = UIColor.fontColor
                                                    textField.attributedPlaceholder = NSAttributedString(string: "Caption (optional)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor.withAlphaComponent(0.3)])
                                                    textField.left(image: UIImage(sfString: SFSymbol.link, overrideString: "link")?.menuIcon(), color: UIColor.fontColor)
                                                    textField.layer.borderColor = UIColor.fontColor.withAlphaComponent(0.3) .cgColor
                                                    textField.backgroundColor = UIColor.foregroundColor
                                                    textField.leftViewPadding = 12
                                                    textField.layer.borderWidth = 1
                                                    textField.layer.cornerRadius = 8
                                                    textField.keyboardAppearance = .default
                                                    textField.keyboardType = .default
                                                    textField.returnKeyType = .done
                                                    textField.action { textField in
                                                        self.insertText = textField.text
                                                    }
                                                }

                                                let textField = OneTextFieldViewController(vInset: 12, configuration: config).view!
                                                
                                                alert.setupTheme()
                                                
                                                alert.attributedTitle = NSAttributedString(string: "Link Text", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
                                                
                                                alert.contentView.addSubview(textField)
                                                
                                                textField.edgeAnchors /==/ alert.contentView.edgeAnchors
                                                textField.heightAnchor /==/ CGFloat(44 + 12)

                                                alert.addAction(AlertAction(title: "Insert", style: .preferred, handler: { (_) in
                                                    let text = self.insertText ?? ""
                                                    if text.isEmpty() {
                                                        self.text!.insertText("\(url)")
                                                    } else {
                                                        self.text!.insertText("[\(text)](\(url))")
                                                    }
                                                }))

                                                alert.addCancelButton()
                                                alert.addBlurView()

                                                self.parent?.present(alert, animated: true, completion: nil)
                                            }
                                        } else {
                                            let alert = UIAlertController(title: "Uploading failed", message: "Uh oh, something went wrong while uploading to Imgur. Please try again in a few minutes", preferredStyle: .alert)
                                            alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
                                            self.parent?.present(alert, animated: true, completion: nil)
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
                            if self.parent is ReplyViewController && (self.parent as! ReplyViewController).type == .SUBMIT_IMAGE {
                                (self.parent as! ReplyViewController).text!.last!.text = link
                            } else {
                                let alert = AlertController(title: "Link text", message: link, preferredStyle: .alert)

                                let config: TextField.Config = { textField in
                                    textField.becomeFirstResponder()
                                    textField.textColor = UIColor.fontColor
                                    textField.attributedPlaceholder = NSAttributedString(string: "Caption", attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor.withAlphaComponent(0.3)])
                                    textField.left(image: UIImage(sfString: SFSymbol.link, overrideString: "link")?.menuIcon(), color: UIColor.fontColor)
                                    textField.layer.borderColor = UIColor.fontColor.withAlphaComponent(0.3) .cgColor
                                    textField.backgroundColor = UIColor.foregroundColor
                                    textField.leftViewPadding = 12
                                    textField.layer.borderWidth = 1
                                    textField.layer.cornerRadius = 8
                                    textField.keyboardAppearance = .default
                                    textField.keyboardType = .default
                                    textField.returnKeyType = .done
                                    textField.action { textField in
                                        self.insertText = textField.text
                                    }
                                }

                                let textField = OneTextFieldViewController(vInset: 12, configuration: config).view!
                                
                                alert.setupTheme()
                                
                                alert.attributedTitle = NSAttributedString(string: "Link Text", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
                                
                                alert.contentView.addSubview(textField)
                                
                                textField.edgeAnchors /==/ alert.contentView.edgeAnchors
                                textField.heightAnchor /==/ CGFloat(44 + 12)
                                
                                alert.addAction(AlertAction(title: "Insert", style: .preferred, handler: { (_) in
                                    let text = self.insertText ?? ""
                                    if text.isEmpty() {
                                        self.text!.insertText("\(link)")
                                    } else {
                                        self.text!.insertText("[\(text)](\(link))")
                                    }
                                }))

                                alert.addCancelButton()
                                alert.addBlurView()

                                self.parent?.present(alert, animated: true, completion: nil)
                            }
                        } else {
                            let alert = UIAlertController(title: "Uploading failed", message: "Uh oh, something went wrong while uploading to Imgur. Please try again in a few minutes", preferredStyle: .alert)
                            alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
                            self.parent?.present(alert, animated: true, completion: nil)
                        }

                    })
                }
            })
        }
    }

    func uploadImages(_ assets: [PHAsset], album: String, completion: @escaping (String) -> Void) {
        var count = 0
        for image in assets {
            count += 1
            let parameters = [:] as [String: String] // TODO: - albums
            var name = UUID.init().uuidString
            PHImageManager.default().requestImageData(for: image, options: nil, resultHandler: { (data_in, uti, _, info) in
                var data = data_in
                if let fileName = (info?["PHImageFileURLKey"] as? NSURL)?.lastPathComponent {
                    name = fileName
                }
                let mime = UTTypeCopyPreferredTagWithClass(uti! as CFString, kUTTagClassMIMEType)?.takeRetainedValue()
                
                if mime as String? ?? "" == "image/heic" || mime as String? ?? "" == "image/heif" {
                    // Convert heic to jpg
                    if let dataStrong = data_in, let ciImage = CIImage(data: dataStrong) {
                        if #available(iOS 10.0, *) {
                            data = CIContext().jpegRepresentation(of: ciImage, colorSpace: CGColorSpaceCreateDeviceRGB())!
                        }
                    }
                }
                

                AF.upload(multipartFormData: { (multipartFormData) in
                    multipartFormData.append(data!, withName: "image", fileName: name, mimeType: mime! as String)
                    for (key, value) in parameters {
                        multipartFormData.append((value.data(using: .utf8))!, withName: key)
                    }
                    if !album.isEmpty {
                        multipartFormData.append(album.data(using: .utf8)!, withName: "album")
                    }
                }, to: "https://api.imgur.com/3/image", method: .post, headers: ["Authorization": "Client-ID bef87913eb202e9"])
                .uploadProgress(closure: { (progress) in
                    DispatchQueue.main.async {
                        print(progress.fractionCompleted)
                        self.progressBar.setProgress(Float(progress.fractionCompleted), animated: true)
                    }
                })
                .responseJSON { (response) in
                    switch response.result {
                    case .success(let result):
                        debugPrint(result)
                        if let json = result as? NSDictionary, let link = (json["data"] as? NSDictionary)?["link"] as? String {
                            print("Link is \(link)")
                            if count == assets.count {
                                completion(link)
                            }
                        } else {
                            completion("Failure")
                        }
                    case .failure:
                        completion("Failure")
                    }
                }
            })
        }
    }

    
    // iOS 14 impelentation
    @available(iOS 14, *)
    func uploadAsync(_ results: [PHPickerResult]) {
        alertView = UIAlertController(title: "Uploading...", message: "Your images are uploading to Imgur", preferredStyle: .alert)
        alertView!.addCancelButton()

        parent?.present(alertView!, animated: true, completion: {
            //  Add your progressbar after alert is shown (and measured)
            let margin: CGFloat = 8.0
            let rect = CGRect.init(x: margin, y: 72.0, width: (self.alertView?.view.frame.width)! - margin * 2.0, height: 2.0)
            self.progressBar = UIProgressView(frame: rect)
            self.progressBar.progress = 0
            self.progressBar.tintColor = ColorUtil.accentColorForSub(sub: "")
            self.alertView?.view.addSubview(self.progressBar)
        })

        if results.count > 1 {
            AF.request("https://api.imgur.com/3/album", method: .post, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization": "Client-ID bef87913eb202e9"])
                    .responseJSON { response in
                        print(response)
                        if let status = response.response?.statusCode {
                            switch status {
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
                            self.uploadImages(results, album: album, completion: { (last, success) in
                                DispatchQueue.main.async {
                                    self.alertView!.dismiss(animated: true, completion: {
                                        if success {
                                            if self.parent is ReplyViewController && (self.parent as! ReplyViewController).type == .SUBMIT_IMAGE {
                                                (self.parent as! ReplyViewController).text!.last!.text = url
                                            } else {
                                                let alert = AlertController(title: "Link text", message: url, preferredStyle: .alert)

                                                let config: TextField.Config = { textField in
                                                    textField.becomeFirstResponder()
                                                    textField.textColor = UIColor.fontColor
                                                    textField.attributedPlaceholder = NSAttributedString(string: "Caption (optional)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor.withAlphaComponent(0.3)])
                                                    textField.left(image: UIImage(sfString: SFSymbol.link, overrideString: "link")?.menuIcon(), color: UIColor.fontColor)
                                                    textField.layer.borderColor = UIColor.fontColor.withAlphaComponent(0.3) .cgColor
                                                    textField.backgroundColor = UIColor.foregroundColor
                                                    textField.leftViewPadding = 12
                                                    textField.layer.borderWidth = 1
                                                    textField.layer.cornerRadius = 8
                                                    textField.keyboardAppearance = .default
                                                    textField.keyboardType = .default
                                                    textField.returnKeyType = .done
                                                    textField.action { textField in
                                                        self.insertText = textField.text
                                                    }
                                                }

                                                let textField = OneTextFieldViewController(vInset: 12, configuration: config).view!
                                                
                                                alert.setupTheme()
                                                
                                                alert.attributedTitle = NSAttributedString(string: "Link Text", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
                                                
                                                alert.contentView.addSubview(textField)
                                                
                                                textField.edgeAnchors /==/ alert.contentView.edgeAnchors
                                                textField.heightAnchor /==/ CGFloat(44 + 12)

                                                alert.addAction(AlertAction(title: "Insert", style: .preferred, handler: { (_) in
                                                    let text = self.insertText ?? ""
                                                    if text.isEmpty() {
                                                        self.text!.insertText("\(url)")
                                                    } else {
                                                        self.text!.insertText("[\(text)](\(url))")
                                                    }
                                                }))

                                                alert.addCancelButton()
                                                alert.addBlurView()

                                                self.parent?.present(alert, animated: true, completion: nil)
                                            }
                                        } else {
                                            let alert = UIAlertController(title: "Uploading failed", message: "Uh oh, something went wrong while uploading to Imgur. Please try again in a few minutes", preferredStyle: .alert)
                                            alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
                                            self.parent?.present(alert, animated: true, completion: nil)
                                        }
                                    })
                                }
                            })
                        }

                    }

        } else {
            uploadImages(results, album: "", completion: { (link, success) in
                DispatchQueue.main.async {
                    self.alertView!.dismiss(animated: true, completion: {
                        if success {
                            if self.parent is ReplyViewController && (self.parent as! ReplyViewController).type == .SUBMIT_IMAGE {
                                (self.parent as! ReplyViewController).text!.last!.text = link
                            } else {
                                let alert = AlertController(title: "Link text", message: link, preferredStyle: .alert)

                                let config: TextField.Config = { textField in
                                    textField.becomeFirstResponder()
                                    textField.textColor = UIColor.fontColor
                                    textField.attributedPlaceholder = NSAttributedString(string: "Caption", attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor.withAlphaComponent(0.3)])
                                    textField.left(image: UIImage(sfString: SFSymbol.link, overrideString: "link")?.menuIcon(), color: UIColor.fontColor)
                                    textField.layer.borderColor = UIColor.fontColor.withAlphaComponent(0.3) .cgColor
                                    textField.backgroundColor = UIColor.foregroundColor
                                    textField.leftViewPadding = 12
                                    textField.layer.borderWidth = 1
                                    textField.layer.cornerRadius = 8
                                    textField.keyboardAppearance = .default
                                    textField.keyboardType = .default
                                    textField.returnKeyType = .done
                                    textField.action { textField in
                                        self.insertText = textField.text
                                    }
                                }

                                let textField = OneTextFieldViewController(vInset: 12, configuration: config).view!
                                
                                alert.setupTheme()
                                
                                alert.attributedTitle = NSAttributedString(string: "Link Text", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
                                
                                alert.contentView.addSubview(textField)
                                
                                textField.edgeAnchors /==/ alert.contentView.edgeAnchors
                                textField.heightAnchor /==/ CGFloat(44 + 12)
                                
                                alert.addAction(AlertAction(title: "Insert", style: .preferred, handler: { (_) in
                                    let text = self.insertText ?? ""
                                    if text.isEmpty() {
                                        self.text!.insertText("\(link)")
                                    } else {
                                        self.text!.insertText("[\(text)](\(link))")
                                    }
                                }))

                                alert.addCancelButton()
                                alert.addBlurView()

                                self.parent?.present(alert, animated: true, completion: nil)
                            }
                        } else {
                            let alert = UIAlertController(title: "Uploading failed", message: "Uh oh, something went wrong while uploading to Imgur. Please try again in a few minutes", preferredStyle: .alert)
                            alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
                            self.parent?.present(alert, animated: true, completion: nil)
                        }

                    })
                }
            })
        }
    }

    @available(iOS 14, *)
    func uploadImages(_ results: [PHPickerResult], album: String, completion: @escaping (String, Bool) -> Void) {
        var count = 0
        for result in results {
            
            count += 1
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if error != nil {
                    completion("", false)
                    return
                }
                guard let image = object as? UIImage else { return }
                
                func tryUploadWithSize(size: Float) {
                    if size <= 0 {
                        completion("", false)
                    }
                    guard let data = image.jpegData(compressionQuality: 1) else {
                        tryUploadWithSize(size: size - 0.1)
                        return
                    }
                    
                    AF.upload(multipartFormData: { (multipartFormData) in
                        multipartFormData.append(data, withName: "image", fileName: UUID().uuidString + ".jpeg", mimeType: "image/jpg")

                        if !album.isEmpty {
                            multipartFormData.append(album.data(using: .utf8)!, withName: "album")
                        }
                    }, to: "https://api.imgur.com/3/image", method: .post, headers: ["Authorization": "Client-ID bef87913eb202e9"])
                    .uploadProgress(closure: { (progress) in
                        DispatchQueue.main.async {
                            print(progress.fractionCompleted)
                            self.progressBar.setProgress(Float(progress.fractionCompleted), animated: true)
                        }
                    })
                    .responseJSON { (response) in
                        switch response.result {
                        case .success(let result):
                            if let val = response.value {
                                let json = JSON(val)
                                debugPrint(response)
                                let link = json["data"]["link"].stringValue
                                if link.isEmpty {
                                    if json["data"]["error"].stringValue != "" {
                                        tryUploadWithSize(size: size - 0.1)
                                        return
                                    }
                                }
                                print("Link is \(link)")
                                if count == results.count {
                                    completion(link, true)
                                }
                            }
                        case .failure:
                            completion("Failure", false)
                        }
                    }
                }
                
                tryUploadWithSize(size: 1)
            }
        }
    }

    @objc func quote(_ sender: UIButton!) {
        if let replyText = replyText {
            text?.resignFirstResponder()
            let alert = AlertController.init(title: "Quote text", message: nil, preferredStyle: .alert)
            
            alert.setupTheme()
            
            alert.attributedTitle = NSAttributedString(string: "Quote text", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
            
            let textView = UITextView().then {
                $0.font = FontGenerator.fontOfSize(size: 14, submission: false)
                $0.textColor = UIColor.fontColor
                $0.backgroundColor = .clear
                $0.isEditable = false
                $0.isSelectable = true
                $0.text = replyText
            }
            
            alert.contentView.addSubview(textView)
            textView.edgeAnchors /==/ alert.contentView.edgeAnchors
            
            let height = textView.sizeThatFits(CGSize(width: 238, height: CGFloat.greatestFiniteMagnitude)).height
            textView.heightAnchor /==/ height
            
            alert.addCloseButton()
            alert.addAction(AlertAction(title: "Quote all", style: AlertAction.Style.normal, handler: { (_) in
                self.replaceIn("\n", with: "\n> \(replyText)")
                self.text?.becomeFirstResponder()
            }))
            alert.addAction(AlertAction(title: "Quote selected", style: AlertAction.Style.normal, handler: { (_) in
                if let textRange = textView.selectedTextRange {
                    let selectedText = textView.text(in: textRange)
                    
                    self.replaceIn("\n", with: "\n> \(selectedText ?? "")")
                    if let textView = self.text {
                        textView.becomeFirstResponder()
                        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
                    }
                }
            }))

            alert.addBlurView()
            
            parent?.present(alert, animated: true)
        }
    }

    var insertLink: String?

    @objc func link(_ sender: UIButton!) {
        let alert = AlertController(title: "Insert Link", message: "", preferredStyle: .alert)

        let configU: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = UIColor.fontColor
            textField.placeholder = "URL"
            textField.left(image: UIImage(sfString: SFSymbol.link, overrideString: "link")?.menuIcon(), color: UIColor.fontColor)
            textField.leftViewPadding = 12
            textField.layer.borderWidth = 1
            textField.layer.cornerRadius = 8
            textField.layer.borderColor = UIColor.fontColor.withAlphaComponent(0.3) .cgColor
            textField.backgroundColor = UIColor.foregroundColor
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.action { textField in
                self.insertLink = textField.text
            }
        }

        let configT: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = UIColor.fontColor
            textField.placeholder = "Caption (optional)"
            textField.left(image: UIImage(sfString: SFSymbol.textbox, overrideString: "size")?.menuIcon(), color: UIColor.fontColor)
            textField.leftViewPadding = 12
            textField.layer.borderWidth = 1
            textField.layer.cornerRadius = 8
            textField.layer.borderColor = UIColor.fontColor.withAlphaComponent(0.3) .cgColor
            textField.backgroundColor = UIColor.foregroundColor
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.action { textField in
                self.insertText = textField.text
            }
        }

        let textField = TwoTextFieldsViewController(height: 58, hInset: 0, vInset: 0, textFieldOne: configU, textFieldTwo: configT).view!
        
        alert.setupTheme()
        
        alert.attributedTitle = NSAttributedString(string: "Insert link", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
        
        alert.contentView.addSubview(textField)
        
        textField.edgeAnchors /==/ alert.contentView.edgeAnchors
        textField.heightAnchor /==/ CGFloat(58 * 2)
        
        alert.addAction(AlertAction(title: "Insert", style: .preferred, handler: { (_) in
            let text = self.insertText ?? ""
            let link = self.insertLink ?? ""
            if text.isEmpty() {
                self.text!.insertText("\(link)")
            } else {
                self.text!.insertText("[\(text)](\(link))")
            }
        }))

        alert.addCancelButton()
        alert.addBlurView()
        
        self.parent?.present(alert, animated: true, completion: nil)

    }

    @objc func bold(_ sender: UIButton!) {
        wrapIn("**")
    }

    @objc func italics(_ sender: UIButton!) {
        wrapIn("*")
    }

    @objc func list(_ sender: UIButton!) {
        replaceIn("\n", with: "\n* ")
    }

    @objc func numberedList(_ sender: UIButton!) {
        replaceIn("\n", with: "\n1. ")

    }

    @objc func size(_ sender: UIButton!) {
        replaceIn("\n", with: "\n#")
    }

    @objc func strike(_ sender: UIButton!) {
        wrapIn("~~")
    }
}
class TouchUIScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}

@available(iOS 14, *)
extension ToolbarTextView: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else { return }
        
        (self.picker as? PHPickerViewController)?.dismiss(animated: true, completion: {
            let alert = UIAlertController.init(title: "Confirm upload", message: "Would you like to upload \(results.count) image\(results.count > 1 ? "s" : "") anonymously to Imgur.com? This cannot be undone", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "No", style: .destructive, handler: nil))
            alert.addAction(UIAlertAction.init(title: "Yes", style: .default) { _ in
                self.uploadAsync(results)
            })
            self.parent?.present(alert, animated: true, completion: nil)

        })
    }
}
