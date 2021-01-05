//
//  CommentViewController+ReplyDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/3/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import RealmSwift

extension CommentViewController: ReplyDelegate {
    // MARK: - Methods
    /// Sends the users comment adding it to other comments in list.
    func replySent(comment: Comment?, cell: CommentDepthCell?) {
        if comment != nil && cell != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                let startDepth = (self.cDepth[cell!.comment!.getIdentifier()] ?? 0) + 1

                let queue: [Object] = [RealmDataWrapper.commentToRComment(comment: comment!, depth: startDepth)]
                self.cDepth[comment!.getId()] = startDepth

                var realPosition = 0
                for c in self.comments {
                    let id = c
                    if id == cell!.comment!.getIdentifier() {
                        break
                    }
                    realPosition += 1
                }

                var insertIndex = 0
                for c in self.dataArray {
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
                    self.content[id] = item
                }

                self.dataArray.insert(contentsOf: ids, at: insertIndex + 1)
                self.comments.insert(contentsOf: ids, at: realPosition + 1)
                self.updateStringsSingle(queue)
                self.doArrays()
                self.isReply = false
                self.isEditing = false
                self.tableView.reloadData()

            })
        } else if comment != nil && cell == nil {
            DispatchQueue.main.async(execute: { () -> Void in
                let startDepth = 1

                let queue: [Object] = [RealmDataWrapper.commentToRComment(comment: comment!, depth: startDepth)]
                self.cDepth[comment!.getId()] = startDepth

                let realPosition = 0
                self.menuId = nil

                var ids: [String] = []
                for item in queue {
                    let id = item.getIdentifier()
                    ids.append(id)
                    self.content[id] = item
                }

                self.dataArray.insert(contentsOf: ids, at: 0)
                self.comments.insert(contentsOf: ids, at: realPosition == 0 ? 0 : realPosition + 1)
                self.updateStringsSingle(queue)
                self.doArrays()
                self.isReply = false
                self.isEditing = false
                self.tableView.reloadData()
            })
        }
    }
    
    /// Applies dynamic size to text being typed.
    func updateHeight(textView: UITextView) {
        UIView.setAnimationsEnabled(false)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
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
                for c in self.comments {
                    let id = c
                    if id == comment.getIdentifier() {
                        break
                    }
                    realPosition += 1
                }

                var insertIndex = 0
                for c in self.dataArray {
                    let id = c
                    if id == comment.getIdentifier() {
                        break
                    }
                    insertIndex += 1
                }

                comment = RealmDataWrapper.commentToRComment(comment: cr!, depth: self.cDepth[comment.getIdentifier()] ?? 1)
                self.dataArray.remove(at: insertIndex)
                self.dataArray.insert(comment.getIdentifier(), at: insertIndex)
                self.comments.remove(at: realPosition)
                self.comments.insert(comment.getIdentifier(), at: realPosition)
                self.content[comment.getIdentifier()] = comment
                self.updateStringsSingle([comment])
                self.doArrays()
                self.isEditing = false
                self.isReply = false
                self.tableView.reloadData()
                self.discard()
            })
        }
    }
    
}
