//
//  CommentTableViewDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 7/28/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
import Foundation
import UIKit

class CommentTableViewDelegate: NSObject, UITableViewDelegate {
    // MARK: - Properties / References
    private var commentController: CommentViewController!
    
    // MARK: - Initialization
    init(parentController: CommentViewController) {
        self.commentController = parentController
    }
    
    // MARK: - Methods
    // TODO: - Complete Comment Table View Protocols
    
    //    @available(iOS 11.0, *)
    //    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    //        let cell = tableView.cellForRow(at: indexPath)
    //        if cell is CommentDepthCell && (cell as! CommentDepthCell).comment != nil && (SettingValues.commentActionRightLeft != .NONE || SettingValues.commentActionRightRight != .NONE) {
    //            HapticUtility.hapticActionWeak()
    //            var actions = [UIContextualAction]()
    //            if SettingValues.commentActionRightRight != .NONE {
    //                let action = UIContextualAction.init(style: .normal, title: "", handler: { (action, _, b) in
    //                    b(true)
    //                    self.doAction(cell: cell as! CommentDepthCell, action: SettingValues.commentActionRightRight, indexPath: indexPath)
    //                })
    //                action.backgroundColor = SettingValues.commentActionRightRight.getColor()
    //                action.image = UIImage(named: SettingValues.commentActionRightRight.getPhoto())?.navIcon()
    //
    //                actions.append(action)
    //            }
    //            if SettingValues.commentActionRightLeft != .NONE {
    //                let action = UIContextualAction.init(style: .normal, title: "", handler: { (action, _, b) in
    //                    b(true)
    //                    self.doAction(cell: cell as! CommentDepthCell, action: SettingValues.commentActionRightLeft, indexPath: indexPath)
    //                })
    //                action.backgroundColor = SettingValues.commentActionRightLeft.getColor()
    //                action.image = UIImage(named: SettingValues.commentActionRightLeft.getPhoto())?.navIcon()
    //
    //                actions.append(action)
    //            }
    //            let config = UISwipeActionsConfiguration.init(actions: actions)
    //
    //            return config
    //
    //        } else {
    //            return UISwipeActionsConfiguration.init()
    //        }
    //    }
    //
    //    @available(iOS 11.0, *)
    //    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    //        let cell = tableView.cellForRow(at: indexPath)
    //        if cell is CommentDepthCell && (cell as! CommentDepthCell).comment != nil && SettingValues.commentGesturesEnabled && (SettingValues.commentActionLeftLeft != .NONE || SettingValues.commentActionLeftRight != .NONE) {
    //            HapticUtility.hapticActionWeak()
    //            var actions = [UIContextualAction]()
    //            if SettingValues.commentActionLeftLeft != .NONE {
    //                let action = UIContextualAction.init(style: .normal, title: "", handler: { (action, _, b) in
    //                    b(true)
    //                    self.doAction(cell: cell as! CommentDepthCell, action: SettingValues.commentActionLeftLeft, indexPath: indexPath)
    //                })
    //                action.backgroundColor = SettingValues.commentActionLeftLeft.getColor()
    //                action.image = UIImage(named: SettingValues.commentActionLeftLeft.getPhoto())?.navIcon()
    //
    //                actions.append(action)
    //            }
    //            if SettingValues.commentActionLeftRight != .NONE {
    //                let action = UIContextualAction.init(style: .normal, title: "", handler: { (action, _, b) in
    //                    b(true)
    //                    self.doAction(cell: cell as! CommentDepthCell, action: SettingValues.commentActionLeftRight, indexPath: indexPath)
    //                })
    //                action.backgroundColor = SettingValues.commentActionLeftRight.getColor()
    //                action.image = UIImage(named: SettingValues.commentActionLeftRight.getPhoto())?.navIcon()
    //
    //                actions.append(action)
    //            }
    //            let config = UISwipeActionsConfiguration.init(actions: actions)
    //
    //            return config
    //
    //        } else {
    //            return UISwipeActionsConfiguration.init()
    //        }
    //    }
    
}
