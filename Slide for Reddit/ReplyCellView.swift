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
import MobileCoreServices
import SwiftyJSON
import ActionSheetPicker_3_0
import RealmSwift

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
    var parent: CommentViewController?
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

    func edit(_ sender: AnyObject) {
        alertController = UIAlertController(title: nil, message: "Editing comment...\n\n", preferredStyle: .alert)

        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()

        alertController?.view.addSubview(spinnerIndicator)
        parent!.present(alertController!, animated: true, completion: nil)

        session = (UIApplication.shared.delegate as! AppDelegate).session

        //todo better system for tfhis
        do {
            let name = toReplyTo is RMessage ? (toReplyTo as! RMessage).getId() : toReplyTo is RComment ? (toReplyTo as! RComment).getId() : (toReplyTo as! RSubmission).getId()
            try self.session?.editCommentOrLink(name, newBody: body.text!, completion: { (result) in
                self.getCommentEdited(name)
            })
        } catch {
            print((error as NSError).description)
        }
    }

    func getCommentEdited(_ name: String) {
        do {
            try self.session?.getInfo([name], completion: { (res) in
                switch res {
                case .failure:
                    DispatchQueue.main.async {
                        self.toolbar?.saveDraft(self)
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
                self.toolbar?.saveDraft(self)
                self.alertController?.dismiss(animated: false, completion: {
                    let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your message has not been edited (but has been saved as a draft), please try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.parent!.present(alert, animated: true, completion: nil)
                })
                self.delegate!.editSent(cr: nil)
            }
        }

    }


    func send(_ sender: AnyObject) {
        self.body.endEditing(true)

        if (edit) {
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
        parent!.present(alertController!, animated: true, completion: nil)

        do {
            let name = toReplyTo is RMessage ? (toReplyTo as! RMessage).getId() : toReplyTo is RComment ? (toReplyTo as! RComment).getId() : (toReplyTo as! RSubmission).getId()
            try self.session?.postComment(body.text!, parentName: name, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        self.toolbar?.saveDraft(self)
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
                self.toolbar?.saveDraft(self)
                self.alertController?.dismiss(animated: false, completion: {
                    let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your comment has not been sent (but has been saved as a draft), please try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.parent!.present(alert, animated: true, completion: nil)
                })
                self.delegate!.replySent(comment: nil)
            }

        }
    }

    func discard(_ sender: AnyObject) {
        delegate!.discard()
    }

    var sideConstraint: [NSLayoutConstraint] = []

    override func updateConstraints() {
        super.updateConstraints()

        let metrics: [String: Int] = [:]
        let views = ["body": body, "send": sendB, "discard": discardB] as [String: Any]

        sideConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[body]-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views)
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[body(>=60)]-[send(40)]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[body(>=60)]-[discard(40)]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[send]-16-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[discard]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))

        self.contentView.addConstraints(sideConstraint)
    }

    func setContent(thing: Object, sub: String, editing: Bool, delegate: ReplyDelegate, parent: CommentViewController) {
        body.text = ""
        comment = nil
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
        body.layoutIfNeeded()
        if (edit) {
            body.text = (thing as! RComment).body
        }
        toolbar = ToolbarTextView.init(textView: body, parent: parent)
        body.becomeFirstResponder()
    }

    func textViewDidChange(_ textView: UITextView) {
        delegate!.updateHeight(textView: body)
    }

    var toolbar: ToolbarTextView?

}
