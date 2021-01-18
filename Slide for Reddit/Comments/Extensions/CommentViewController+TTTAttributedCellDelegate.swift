//
//  CommentViewController+TTTAttributedCellDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/3/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit
import RealmSwift
import reddift

extension CommentViewController: TTTAttributedCellDelegate {
    // MARK: - Methods
    /// Scrolls to Comment upon tapping.
    func pushedSingleTap(_ cell: CommentDepthCell) {
        if !isReply {
            if isSearching {
                hideSearchBar()
                context = (cell.content as! RComment).getIdentifier()
                var index = 0
                if !self.context.isEmpty() {
                    for c in self.dataArray {
                        let comment = content[c]
                        if comment is RComment && (comment as! RComment).getIdentifier().contains(self.context) {
                            self.menuId = comment!.getIdentifier()
                            self.tableView.reloadData()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.goToCell(i: index)
                            }
                            break
                        } else {
                            index += 1
                        }
                    }
                }

            } else {
                if let comment = cell.content as? RComment {
                    let row = tableView.indexPath(for: cell)?.row
                    let id = comment.getIdentifier()
                    let childNumber = getChildNumber(n: comment.getIdentifier())
                    if childNumber == 0 {
                        if !SettingValues.collapseFully {
                            cell.showMenu(nil)
                        } else if cell.isCollapsed {
                            if hiddenPersons.contains((id)) {
                                hiddenPersons.remove(at: hiddenPersons.firstIndex(of: id)!)
                            }
                            if let oldHeight = oldHeights[id] {
                                UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                                    cell.contentView.frame = CGRect(x: 0, y: 0, width: cell.contentView.frame.size.width, height: oldHeight)
                                }, completion: { (_) in
                                    cell.expandSingle()
                                    self.oldHeights.removeValue(forKey: id)
                                })
                                tableView.beginUpdates()
                                tableView.endUpdates()
                            } else {
                                cell.expandSingle()
                                tableView.beginUpdates()
                                tableView.endUpdates()
                            }
                        } else {
                            oldHeights[id] = cell.contentView.frame.size.height
                            if !hiddenPersons.contains(id) {
                                hiddenPersons.insert(id)
                            }
                            
                            self.tableView.beginUpdates()
                            cell.collapse(childNumber: 0)
                            self.tableView.endUpdates()
                            /* disable for now
                            if SettingValues.collapseFully, let path = tableView.indexPath(for: cell) {
                                self.tableView.scrollToRow(at: path,
                                                           at: UITableView.ScrollPosition.none, animated: true)
                            }*/
                        }
                    } else {
                        if hiddenPersons.contains((id)) && childNumber > 0 {
                            hiddenPersons.remove(at: hiddenPersons.firstIndex(of: id)!)
                            if let oldHeight = oldHeights[id] {
                                UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                                    cell.contentView.frame = CGRect(x: 0, y: 0, width: cell.contentView.frame.size.width, height: oldHeight)
                                }, completion: { (_) in
                                    cell.expand()
                                    self.oldHeights.removeValue(forKey: id)
                                })
                            } else {
                                cell.expand()
                                tableView.beginUpdates()
                                tableView.endUpdates()
                            }
                            unhideAll(comment: comment.getId(), i: row!)
                           // TODO: - hide child number
                        } else {
                            if childNumber > 0 {
                                if childNumber > 0 {
                                    oldHeights[id] = cell.contentView.frame.size.height
                                    cell.collapse(childNumber: childNumber)
                                    /* disable for now
                                    if SettingValues.collapseFully, let path = tableView.indexPath(for: cell) {
                                        self.tableView.scrollToRow(at: path,
                                                                   at: UITableView.ScrollPosition.none, animated: false)
                                    }*/
                                }
                                if row != nil {
                                    hideAll(comment: comment.getIdentifier(), i: row! + 1)
                                }
                                if !hiddenPersons.contains(id) {
                                    hiddenPersons.insert(id)
                                }
                            }
                        }
                    }
                } else {
                    let datasetPosition = tableView.indexPath(for: cell)?.row ?? -1
                    if datasetPosition == -1 {
                        return
                    }
                    if let more = content[dataArray[datasetPosition]] as? RMore, let link = self.submission {
                        if more.children.isEmpty {
                            VCPresenter.openRedditLink("https://www.reddit.com" + submission!.permalink + more.parentId.substring(3, length: more.parentId.length - 3), self.navigationController, self)
                        } else {
                            do {
                                var strings: [String] = []
                                for c in more.children {
                                    strings.append(c.value)
                                }
                                cell.animateMore()
                                try session?.getMoreChildren(strings, name: link.id, sort: .top, id: more.id, completion: { (result) -> Void in
                                    switch result {
                                    case .failure(let error):
                                        print(error)
                                    case .success(let list):
                                        DispatchQueue.main.async(execute: { () -> Void in
                                            let startDepth = self.cDepth[more.getIdentifier()] ?? 0

                                            var queue: [Object] = []
                                            for i in self.extendForMore(parentId: more.parentId, comments: list, current: startDepth) {
                                                let item = i.0 is Comment ? RealmDataWrapper.commentToRComment(comment: i.0 as! Comment, depth: i.1) : RealmDataWrapper.moreToRMore(more: i.0 as! More)
                                                queue.append(item)
                                                self.cDepth[item.getIdentifier()] = i.1
                                                self.updateStrings([i])
                                            }

                                            var realPosition = 0
                                            for comment in self.comments {
                                                if comment == more.getIdentifier() {
                                                    break
                                                }
                                                realPosition += 1
                                            }

                                            if self.comments.count > realPosition && self.comments[realPosition] != nil {
                                                self.comments.remove(at: realPosition)
                                            } else {
                                                return
                                            }
                                            self.dataArray.remove(at: datasetPosition)
                                            
                                            let currentParent = self.parents[more.getIdentifier()]

                                            var ids: [String] = []
                                            for item in queue {
                                                let id = item.getIdentifier()
                                                self.parents[id] = currentParent
                                                ids.append(id)
                                                self.content[id] = item
                                            }

                                            if queue.count != 0 {
                                                self.tableView.beginUpdates()
                                                self.tableView.deleteRows(at: [IndexPath.init(row: datasetPosition, section: 0)], with: .fade)
                                                self.dataArray.insert(contentsOf: ids, at: datasetPosition)
                                                self.comments.insert(contentsOf: ids, at: realPosition)
                                                self.doArrays()
                                                var paths: [IndexPath] = []
                                                for i in stride(from: datasetPosition, to: datasetPosition + queue.count, by: 1) {
                                                    paths.append(IndexPath.init(row: i, section: 0))
                                                }
                                                self.tableView.insertRows(at: paths, with: .left)
                                                self.tableView.endUpdates()

                                            } else {
                                                self.doArrays()
                                                self.tableView.reloadData()
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
        return menuCell != nil
    }
    
    /// Returns the comment from selected cell.
    func getMenuShown() -> String? {
        return menuId
    }
    
}
