//
// Created by Carlos Crane on 2/15/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import ActionSheetPicker_3_0
import Alamofire
import MobileCoreServices
import OpalImagePicker
import Photos
import RLBAlertsPickers
import SwiftyJSON
import SDCAlertView
import UIKit

public class ToolbarTextView: NSObject {

    var text: UITextView?
    var parent: UIViewController

    init(textView: UITextView, parent: UIViewController) {
        self.text = textView
        self.parent = parent
        super.init()
        addToolbarToTextView()
    }

    func addToolbarToTextView() {
        let scrollView = TouchUIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: text!.frame.size.width, height: 50))
        scrollView.contentSize = CGSize.init(width: 50 * 11, height: 50)
        scrollView.autoresizingMask = .flexibleWidth
        scrollView.backgroundColor = ColorUtil.theme.backgroundColor
        var i = 0
        for button in ([
            generateButtons(image: "save", action: #selector(ToolbarTextView.saveDraft(_:))),
            generateButtons(image: "folder", action: #selector(ToolbarTextView.openDrafts(_:))),
            generateButtons(image: "image", action: #selector(ToolbarTextView.uploadImage(_:))),
            generateButtons(image: "draw", action: #selector(ToolbarTextView.draw(_:))),
            generateButtons(image: "link", action: #selector(ToolbarTextView.link(_:))),
            generateButtons(image: "bold", action: #selector(ToolbarTextView.bold(_:))),
            generateButtons(image: "italic", action: #selector(ToolbarTextView.italics(_:))),
            generateButtons(image: "list", action: #selector(ToolbarTextView.list(_:))),
            generateButtons(image: "list_number", action: #selector(ToolbarTextView.numberedList(_:))),
            generateButtons(image: "size", action: #selector(ToolbarTextView.size(_:))),
            generateButtons(image: "strikethrough", action: #selector(ToolbarTextView.strike(_:))), ]) {
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
            text!.tintColor = ColorUtil.theme.fontColor
        }
        if !ColorUtil.theme.isLight {
            text!.keyboardAppearance = .dark
        }
    }

    func generateButtons(image: String, action: Selector) -> (UIButton, Selector) {
        let more = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        more.setImage(UIImage.init(named: image)?.menuIcon(), for: UIControl.State.normal)
        return (more, action)
    }

    func wrapIn(_ value: String) {
        let wrapped = value + text!.text(in: text!.selectedTextRange!)! + value
        text!.replace(text!.selectedTextRange!, withText: wrapped)
        
        if wrapped.length == value.length * 2 {
            let newPosition = text!.position(from: text!.selectedTextRange!.end, offset: -(value.length)) ?? text!.selectedTextRange!.end
            text!.selectedTextRange = text!.textRange(from: newPosition, to: newPosition)
        }
    }

    func replaceIn(_ value: String, with: String) {
        text!.replace(text!.selectedTextRange!, withText: with + text!.text(in: text!.selectedTextRange!)!.replacingOccurrences(of: value, with: with))
    }

    @objc func saveDraft(_ sender: AnyObject?) {
        if let toSave = text!.text {
            if !toSave.isEmpty() {
                Drafts.addDraft(s: text!.text)
                BannerUtil.makeBanner(text: "Draft saved!", seconds: 3, context: parent, top: true)
            }
        }
    }

    var picker: ActionSheetStringPicker?

    @objc func openDrafts(_ sender: AnyObject) {
        print("Opening drafts")
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
            //todo  picker?.addCustomButton(withTitle: "Delete", target: self, selector: #selector(ReplyViewController.doDelete(_:)))
            picker?.show()

        }
    }

    func doDelete(_ sender: AnyObject) {
        Drafts.deleteDraft(s: Drafts.drafts[(picker?.selectedIndex)!] as String)
        self.openDrafts(sender)
    }

    @objc func uploadImage(_ sender: UIButton!) {
        let imagePicker = OpalImagePickerController()
        imagePicker.allowedMediaTypes = [PHAssetMediaType.image]
        self.parent.presentOpalImagePickerController(imagePicker, animated: true,
                                         select: { (assets) in
                                            imagePicker.dismiss(animated: true, completion: {
                                                if !assets.isEmpty {
                                                    let alert = UIAlertController.init(title: "Confirm upload", message: "Would you like to upload \(assets.count) image\(assets.count > 1 ? "s" : "") anonymously to Imgur.com? This cannot be undone", preferredStyle: .alert)
                                                    alert.addAction(UIAlertAction.init(title: "No", style: .destructive, handler: nil))
                                                    alert.addAction(UIAlertAction.init(title: "Yes", style: .default) { _ in
                                                        self.uploadAsync(assets)
                                                    })
                                                    self.parent.present(alert, animated: true, completion: nil)
                                                }

                                            })
        }, cancel: {
            imagePicker.dismiss(animated: true)
        })
    }

    var progressBar = UIProgressView()
    var alertView: UIAlertController?

    var insertText: String?

    func uploadAsync(_ assets: [PHAsset]) {
        alertView = UIAlertController(title: "Uploading...", message: "Your images are uploading to Imgur", preferredStyle: .alert)
        alertView!.addCancelButton()

        parent.present(alertView!, animated: true, completion: {
            //  Add your progressbar after alert is shown (and measured)
            let margin: CGFloat = 8.0
            let rect = CGRect.init(x: margin, y: 72.0, width: (self.alertView?.view.frame.width)! - margin * 2.0, height: 2.0)
            self.progressBar = UIProgressView(frame: rect)
            self.progressBar.progress = 0
            self.progressBar.tintColor = ColorUtil.accentColorForSub(sub: "")
            self.alertView?.view.addSubview(self.progressBar)
        })

        if assets.count > 1 {
            Alamofire.request("https://api.imgur.com/3/album", method: .post, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization": "Client-ID bef87913eb202e9"])
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
                                                    textField.textColor = ColorUtil.theme.fontColor
                                                    textField.attributedPlaceholder = NSAttributedString(string: "Caption (optional)", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor.withAlphaComponent(0.3)])
                                                    textField.left(image: UIImage.init(named: "link"), color: ColorUtil.theme.fontColor)
                                                    textField.layer.borderColor = ColorUtil.theme.fontColor.withAlphaComponent(0.3) .cgColor
                                                    textField.backgroundColor = ColorUtil.theme.backgroundColor
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
                                                
                                                alert.attributedTitle = NSAttributedString(string: "Link Text", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
                                                
                                                alert.contentView.addSubview(textField)
                                                
                                                textField.edgeAnchors == alert.contentView.edgeAnchors
                                                textField.heightAnchor == CGFloat(44 + 12)

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

                                                self.parent.present(alert, animated: true, completion: nil)
                                            }
                                        } else {
                                            let alert = UIAlertController(title: "Uploading failed", message: "Uh oh, something went wrong while uploading to Imgur. Please try again in a few minutes", preferredStyle: .alert)
                                            alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
                                            self.parent.present(alert, animated: true, completion: nil)
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
                                    textField.textColor = ColorUtil.theme.fontColor
                                    textField.attributedPlaceholder = NSAttributedString(string: "Caption", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor.withAlphaComponent(0.3)])
                                    textField.left(image: UIImage.init(named: "link"), color: ColorUtil.theme.fontColor)
                                    textField.layer.borderColor = ColorUtil.theme.fontColor.withAlphaComponent(0.3) .cgColor
                                    textField.backgroundColor = ColorUtil.theme.backgroundColor
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
                                
                                alert.attributedTitle = NSAttributedString(string: "Link Text", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
                                
                                alert.contentView.addSubview(textField)
                                
                                textField.edgeAnchors == alert.contentView.edgeAnchors
                                textField.heightAnchor == CGFloat(44 + 12)
                                
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

                                self.parent.present(alert, animated: true, completion: nil)
                            }
                        } else {
                            let alert = UIAlertController(title: "Uploading failed", message: "Uh oh, something went wrong while uploading to Imgur. Please try again in a few minutes", preferredStyle: .alert)
                            alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
                            self.parent.present(alert, animated: true, completion: nil)
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
                    if !album.isEmpty {
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
                            if count == assets.count {
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

    @objc func draw(_ sender: UIButton!) {

    }

    var insertLink: String?

    @objc func link(_ sender: UIButton!) {
        let alert = AlertController(title: "Insert Link", message: "", preferredStyle: .alert)

        let configU: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = ColorUtil.theme.fontColor
            textField.placeholder = "URL"
            textField.left(image: UIImage.init(named: "link"), color: ColorUtil.theme.fontColor)
            textField.leftViewPadding = 12
            textField.layer.borderWidth = 1
            textField.layer.cornerRadius = 8
            textField.layer.borderColor = ColorUtil.theme.fontColor.withAlphaComponent(0.3) .cgColor
            textField.backgroundColor = ColorUtil.theme.backgroundColor
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.action { textField in
                self.insertLink = textField.text
            }
        }

        let configT: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = ColorUtil.theme.fontColor
            textField.placeholder = "Caption (optional)"
            textField.left(image: UIImage.init(named: "size"), color: ColorUtil.theme.fontColor)
            textField.leftViewPadding = 12
            textField.layer.borderWidth = 1
            textField.layer.cornerRadius = 8
            textField.layer.borderColor = ColorUtil.theme.fontColor.withAlphaComponent(0.3) .cgColor
            textField.backgroundColor = ColorUtil.theme.backgroundColor
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.action { textField in
                self.insertText = textField.text
            }
        }

        let textField = TwoTextFieldsViewController(height: 58, hInset: 0, vInset: 0, textFieldOne: configU, textFieldTwo: configT).view!
        
        alert.setupTheme()
        
        alert.attributedTitle = NSAttributedString(string: "Insert link", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        alert.contentView.addSubview(textField)
        
        textField.edgeAnchors == alert.contentView.edgeAnchors
        textField.heightAnchor == CGFloat(58 * 2)
        
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
        
        self.parent.present(alert, animated: true, completion: nil)

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
