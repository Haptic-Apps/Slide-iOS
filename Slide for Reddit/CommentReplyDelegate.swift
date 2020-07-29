//
//  CommentReplyDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 7/28/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import RealmSwift

class CommentReplyDelegate: NSObject, ReplyDelegate {
    // MARK: - Properties / References
    private var commentController: CommentViewController!
    
    // MARK: - Initialization
    init(parentController: CommentViewController) {
        self.commentController = parentController
    }
    
    // MARK: - Methods
    /// Sends the users comment adding it to other comments in list.
    func replySent(comment: Comment?, cell: CommentDepthCell?) {
        if comment != nil && cell != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                let startDepth = (self.commentController.cDepth[cell!.comment!.getIdentifier()] ?? 0) + 1

                let queue: [Object] = [RealmDataWrapper.commentToRComment(comment: comment!, depth: startDepth)]
                self.commentController.cDepth[comment!.getId()] = startDepth

                var realPosition = 0
                for c in self.commentController.comments {
                    let id = c
                    if id == cell!.comment!.getIdentifier() {
                        break
                    }
                    realPosition += 1
                }

                var insertIndex = 0
                for c in self.commentController.dataArray {
                    let id = c
                    if id == cell!.comment!.getIdentifier() {
                        break
                    }
                    insertIndex += 1
                }

                var ids: [String] = []
                for item in queue {
                    let id = item.getIdentifier()
                    ids.append(id)
                    self.commentController.content[id] = item
                }

                self.commentController.dataArray.insert(contentsOf: ids, at: insertIndex + 1)
                self.commentController.comments.insert(contentsOf: ids, at: realPosition + 1)
                self.commentController.updateStringsSingle(queue)
                self.commentController.doArrays()
                self.commentController.isReply = false
                self.commentController.isEditing = false
                self.commentController.tableView.reloadData()

            })
        } else if comment != nil && cell == nil {
            DispatchQueue.main.async(execute: { () -> Void in
                let startDepth = 1

                let queue: [Object] = [RealmDataWrapper.commentToRComment(comment: comment!, depth: startDepth)]
                self.commentController.cDepth[comment!.getId()] = startDepth

                let realPosition = 0
                self.commentController.menuId = nil

                var ids: [String] = []
                for item in queue {
                    let id = item.getIdentifier()
                    ids.append(id)
                    self.commentController.content[id] = item
                }

                self.commentController.dataArray.insert(contentsOf: ids, at: 0)
                self.commentController.comments.insert(contentsOf: ids, at: realPosition == 0 ? 0 : realPosition + 1)
                self.commentController.updateStringsSingle(queue)
                self.commentController.doArrays()
                self.commentController.isReply = false
                self.commentController.isEditing = false
                self.commentController.tableView.reloadData()
            })
        }
    }
    
    /// Applies dynamic size to text being typed.
    func updateHeight(textView: UITextView) {
        UIView.setAnimationsEnabled(false)
        self.commentController.tableView.beginUpdates()
        self.commentController.tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }
    
    // Undefined
    func discard() {

    }
    
    /// Takes a the users modified comment and adds it back to comment section.
    func editSent(cr: Comment?, cell: CommentDepthCell) {
        if cr != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                var realPosition = 0

                var comment = cell.comment!
                for c in self.commentController.comments {
                    let id = c
                    if id == comment.getIdentifier() {
                        break
                    }
                    realPosition += 1
                }

                var insertIndex = 0
                for c in self.commentController.dataArray {
                    let id = c
                    if id == comment.getIdentifier() {
                        break
                    }
                    insertIndex += 1
                }

                comment = RealmDataWrapper.commentToRComment(comment: cr!, depth: self.commentController.cDepth[comment.getIdentifier()] ?? 1)
                self.commentController.dataArray.remove(at: insertIndex)
                self.commentController.dataArray.insert(comment.getIdentifier(), at: insertIndex)
                self.commentController.comments.remove(at: realPosition)
                self.commentController.comments.insert(comment.getIdentifier(), at: realPosition)
                self.commentController.content[comment.getIdentifier()] = comment
                self.commentController.updateStringsSingle([comment])
                self.commentController.doArrays()
                self.commentController.isEditing = false
                self.commentController.isReply = false
                self.commentController.tableView.reloadData()
                self.discard()
            })
        }
    }
    
}
