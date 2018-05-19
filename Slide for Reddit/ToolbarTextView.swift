//
// Created by Carlos Crane on 2/15/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

import UIKit
import YangMingShan
import ActionSheetPicker_3_0
import MaterialComponents.MaterialSnackbar
import Alamofire
import SwiftyJSON
import Photos
import MobileCoreServices

public class ToolbarTextView: NSObject {

    var delegate: YMSPhotoPickerViewControllerDelegate
    var text: UITextView?
    var parent: UIViewController

    init(textView: UITextView, delegate: YMSPhotoPickerViewControllerDelegate, parent: UIViewController){
        self.text = textView
        self.delegate = delegate
        self.parent = parent
        super.init()
        addToolbarToTextView()
    }

    func addToolbarToTextView() {
        let scrollView = TouchUIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: text!.frame.size.width, height: 50))
        scrollView.contentSize = CGSize.init(width: 50 * 11, height: 50)
        scrollView.autoresizingMask = .flexibleWidth
        scrollView.backgroundColor = ColorUtil.backgroundColor
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
            generateButtons(image: "strikethrough", action: #selector(ToolbarTextView.strike(_:)))]) {
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
        more.setImage(UIImage.init(named: image)?.menuIcon(), for: UIControlState.normal)
        return (more, action)
    }

    func wrapIn(_ value: String) {
        text!.replace(text!.selectedTextRange!, withText: value + text!.text(in: text!.selectedTextRange!)! + value)
    }

    func replaceIn(_ value: String, with: String) {
        text!.replace(text!.selectedTextRange!, withText: with + text!.text(in: text!.selectedTextRange!)!.replacingOccurrences(of: value, with: with))
    }


    func saveDraft(_ sender: AnyObject) {
        if let toSave = text!.text {
            if (!toSave.isEmpty()) {
                Drafts.addDraft(s: text!.text)
                let message = MDCSnackbarMessage()
                message.text = "Draft saved"
                MDCSnackbarManager.show(message)
            }
        }
    }

    var picker: ActionSheetStringPicker?

    func openDrafts(_ sender: AnyObject) {
        print("Opening drafts")
        if (Drafts.drafts.isEmpty) {
            parent.view.makeToast("No drafts found", duration: 4, position: .top)
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

    func doDelete(_ sender: AnyObject) {
        Drafts.deleteDraft(s: Drafts.drafts[(picker?.selectedIndex)!] as String)
        self.openDrafts(sender)
    }



    func uploadImage(_ sender: UIButton!) {
        let pickerViewController = YMSPhotoPickerViewController.init()
        pickerViewController.theme.titleLabelTextColor = ColorUtil.fontColor
        pickerViewController.theme.navigationBarBackgroundColor = ColorUtil.getColorForSub(sub: "")
        pickerViewController.theme.tintColor = UIColor.white
        pickerViewController.theme.cameraIconColor = ColorUtil.fontColor
        pickerViewController.shouldReturnImageForSingleSelection = false
        parent.yms_presentCustomAlbumPhotoView(pickerViewController, delegate: delegate)
    }

    var progressBar = UIProgressView()
    var alertView: UIAlertController?

    func uploadAsync(_ assets: [PHAsset]) {
        alertView = UIAlertController(title: "Uploading...", message: "Your images are uploading to Imgur", preferredStyle: .alert)
        alertView!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

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
                            switch (status) {
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
                                            if (self.parent is ReplyViewController && (self.parent as! ReplyViewController).type == .SUBMIT_IMAGE) {
                                                (self.parent as! ReplyViewController).linkCell.cellLabel.text = url
                                                (self.parent as! ReplyViewController).linkCell.cellLabel.isEditable = false
                                            } else {
                                                let alert = UIAlertController(title: "Link text", message: url, preferredStyle: .alert)

                                                alert.addTextField { (textField) in
                                                    textField.text = ""
                                                }
                                                alert.addAction(UIAlertAction(title: "Insert", style: .default, handler: { (action) in
                                                    let textField = alert.textFields![0] // Force unwrapping because we know it exists.
                                                    self.text!.insertText("[\(textField.text!)](\(url))")

                                                }))

                                                alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
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
                            if (self.parent is ReplyViewController && (self.parent as! ReplyViewController).type == .SUBMIT_IMAGE) {
                                (self.parent as! ReplyViewController).linkCell.cellLabel.text = link
                                (self.parent as! ReplyViewController).linkCell.cellLabel.isEditable = false
                            } else {
                                let alert = UIAlertController(title: "Link text", message: link, preferredStyle: .alert)

                                alert.addTextField { (textField) in
                                    textField.text = ""
                                }
                                alert.addAction(UIAlertAction(title: "Insert", style: .default, handler: { (action) in
                                    let textField = alert.textFields![0] // Force unwrapping because we know it exists.
                                    self.text!.insertText("[\(textField.text!)](\(link))")

                                }))

                                alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
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
                    if (!album.isEmpty) {
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
                            if (count == assets.count) {
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


    func draw(_ sender: UIButton!) {

    }

    func link(_ sender: UIButton!) {

    }

    func bold(_ sender: UIButton!) {
        wrapIn("*")
    }

    func italics(_ sender: UIButton!) {
        wrapIn("**")
    }

    func list(_ sender: UIButton!) {
        replaceIn("\n", with: "\n* ")
    }

    func numberedList(_ sender: UIButton!) {
        replaceIn("\n", with: "\n1. ")

    }

    func size(_ sender: UIButton!) {
        replaceIn("\n", with: "\n#")
    }

    func strike(_ sender: UIButton!) {
        wrapIn("~~")
    }
}
