//
//  CommentTTTAttributedCellDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 7/28/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit
import RealmSwift
import reddift

class CommentTTTAttributedCellDelegate: NSObject, TTTAttributedCellDelegate {
    // MARK: - Properties / References
    private var commentController: CommentViewController!
    
    // MARK: - Initialization
    init(parentController: CommentViewController) {
        self.commentController = parentController
    }

    // MARK: - Methods
    /// Scrolls to Comment upon tapping.
    func pushedSingleTap(_ cell: CommentDepthCell) {
        if !commentController.isReply {
            if commentController.isSearching {
                commentController.hideSearchBar()
                commentController.context = (cell.content as! RComment).getIdentifier()
                var index = 0
                if !self.commentController.context.isEmpty() {
                    for c in self.commentController.dataArray {
                        let comment = commentController.content[c]
                        if comment is RComment && (comment as! RComment).getIdentifier().contains(self.commentController.context) {
                            self.commentController.menuId = comment!.getIdentifier()
                            self.commentController.tableView.reloadData()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.commentController.goToCell(i: index)
                            }
                            break
                        } else {
                            index += 1
                        }
                    }
                }

            } else {
                if let comment = cell.content as? RComment {
                    let row = commentController.tableView.indexPath(for: cell)?.row
                    let id = comment.getIdentifier()
                    let childNumber = commentController.getChildNumber(n: comment.getIdentifier())
                    if childNumber == 0 {
                        if !SettingValues.collapseFully {
                            cell.showMenu(nil)
                        } else if cell.isCollapsed {
                            if commentController.hiddenPersons.contains((id)) {
                                commentController.hiddenPersons.remove(at: commentController.hiddenPersons.firstIndex(of: id)!)
                            }
                            if let oldHeight = commentController.oldHeights[id] {
                                // TODO: Add either a parameter or delegates of some sort to make this happen inside a UIViewController
                                
//                                commentController.UIView.animate(withDuration: 0.25, delay: 0, options: commentController.UIView.AnimationOptions.curveEaseInOut, animations: {
//                                    cell.contentView.frame = CGRect(x: 0, y: 0, width: cell.contentView.frame.size.width, height: oldHeight)
//                                }, completion: { (_) in
                                    cell.expandSingle()
                                    self.commentController.oldHeights.removeValue(forKey: id)
//                                })
                                
                                commentController.tableView.beginUpdates()
                                commentController.tableView.endUpdates()
                            } else {
                                cell.expandSingle()
                                commentController.tableView.beginUpdates()
                                commentController.tableView.endUpdates()
                            }
                        } else {
                            commentController.oldHeights[id] = cell.contentView.frame.size.height
                            if !commentController.hiddenPersons.contains(id) {
                                commentController.hiddenPersons.insert(id)
                            }
                            
                            self.commentController.tableView.beginUpdates()
                            cell.collapse(childNumber: 0)
                            self.commentController.tableView.endUpdates()
                            /* disable for now
                            if SettingValues.collapseFully, let path = tableView.indexPath(for: cell) {
                                self.tableView.scrollToRow(at: path,
                                                           at: UITableView.ScrollPosition.none, animated: true)
                            }*/
                        }
                    } else {
                        if commentController.hiddenPersons.contains((id)) && childNumber > 0 {
                            commentController.hiddenPersons.remove(at: commentController.hiddenPersons.firstIndex(of: id)!)
                            if let oldHeight = commentController.oldHeights[id] {
                                // TODO: Add either a parameter or delegates of some sort to make this happen inside a UIViewController
                                
//                                commentController.UIView.animate(withDuration: 0.25, delay: 0, options: commentController.UIView.AnimationOptions.curveEaseInOut, animations: {
//                                    cell.contentView.frame = CGRect(x: 0, y: 0, width: cell.contentView.frame.size.width, height: oldHeight)
//                                }, completion: { (_) in
                                    cell.expand()
                                    self.commentController.oldHeights.removeValue(forKey: id)
//                                })
                                
                            } else {
                                cell.expand()
                                commentController.tableView.beginUpdates()
                                commentController.tableView.endUpdates()
                            }
                            commentController.unhideAll(comment: comment.getId(), i: row!)
                           // TODO: hide child number
                        } else {
                            if childNumber > 0 {
                                if childNumber > 0 {
                                    commentController.oldHeights[id] = cell.contentView.frame.size.height
                                    cell.collapse(childNumber: childNumber)
                                    /* disable for now
                                    if SettingValues.collapseFully, let path = tableView.indexPath(for: cell) {
                                        self.tableView.scrollToRow(at: path,
                                                                   at: UITableView.ScrollPosition.none, animated: false)
                                    }*/
                                }
                                if row != nil {
                                    commentController.hideAll(comment: comment.getIdentifier(), i: row! + 1)
                                }
                                if !commentController.hiddenPersons.contains(id) {
                                    commentController.hiddenPersons.insert(id)
                                }
                            }
                        }
                    }
                } else {
                    let datasetPosition = commentController.tableView.indexPath(for: cell)?.row ?? -1
                    if datasetPosition == -1 {
                        return
                    }
                    if let more = commentController.content[commentController.dataArray[datasetPosition]] as? RMore, let link = self.commentController.submission {
                        if more.children.isEmpty {
                            VCPresenter.openRedditLink("https://www.reddit.com" + commentController.submission!.permalink + more.parentId.substring(3, length: more.parentId.length - 3), self.commentController.navigationController, commentController)
                        } else {
                            do {
                                var strings: [String] = []
                                for c in more.children {
                                    strings.append(c.value)
                                }
                                cell.animateMore()
                                try commentController.session?.getMoreChildren(strings, name: link.id, sort: .top, id: more.id, completion: { (result) -> Void in
                                    switch result {
                                    case .failure(let error):
                                        print(error)
                                    case .success(let list):
                                        DispatchQueue.main.async(execute: { () -> Void in
                                            let startDepth = self.commentController.cDepth[more.getIdentifier()] ?? 0

                                            var queue: [Object] = []
                                            for i in self.commentController.extendForMore(parentId: more.parentId, comments: list, current: startDepth) {
                                                let item = i.0 is Comment ? RealmDataWrapper.commentToRComment(comment: i.0 as! Comment, depth: i.1) : RealmDataWrapper.moreToRMore(more: i.0 as! More)
                                                queue.append(item)
                                                self.commentController.cDepth[item.getIdentifier()] = i.1
                                                self.commentController.updateStrings([i])
                                            }

                                            var realPosition = 0
                                            for comment in self.commentController.comments {
                                                if comment == more.getIdentifier() {
                                                    break
                                                }
                                                realPosition += 1
                                            }

                                            if self.commentController.comments.count > realPosition && self.commentController.comments[realPosition] != nil {
                                                self.commentController.comments.remove(at: realPosition)
                                            } else {
                                                return
                                            }
                                            self.commentController.dataArray.remove(at: datasetPosition)
                                            
                                            let currentParent = self.commentController.parents[more.getIdentifier()]

                                            var ids: [String] = []
                                            for item in queue {
                                                let id = item.getIdentifier()
                                                self.commentController.parents[id] = currentParent
                                                ids.append(id)
                                                self.commentController.content[id] = item
                                            }

                                            if queue.count != 0 {
                                                self.commentController.tableView.beginUpdates()
                                                self.commentController.tableView.deleteRows(at: [IndexPath.init(row: datasetPosition, section: 0)], with: .fade)
                                                self.commentController.dataArray.insert(contentsOf: ids, at: datasetPosition)
                                                self.commentController.comments.insert(contentsOf: ids, at: realPosition)
                                                self.commentController.doArrays()
                                                var paths: [IndexPath] = []
                                                for i in stride(from: datasetPosition, to: datasetPosition + queue.count, by: 1) {
                                                    paths.append(IndexPath.init(row: i, section: 0))
                                                }
                                                self.commentController.tableView.insertRows(at: paths, with: .left)
                                                self.commentController.tableView.endUpdates()

                                            } else {
                                                self.commentController.doArrays()
                                                self.commentController.tableView.reloadData()
                                            }
                                        })

                                    }

                                })

                            } catch {
                                print(error)
                            }
                        }
                    }
                }
            }
        }

    }
    
    /// Returns a bool based upon if Menu is shown.
    func isMenuShown() -> Bool {
        return commentController.menuCell != nil
    }
    
    /// Returns the comment from selected cell.
    func getMenuShown() -> String? {
        return commentController.menuId
    }
}
