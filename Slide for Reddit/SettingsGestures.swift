//
//  SettingsGestures.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/22/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit
import XLActionController

class SettingsGestures: UITableViewController {
    
    var submissionGesturesCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "subs")
    var submissionGestures = UISwitch()
    
    var disableBannerCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "banner")
    var disableBanner = UISwitch()

    var forceTouchSubmissionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "3dsubmission")

    var commentGesturesCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "comments")

    var rightLeftActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "left")

    var rightRightActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "right")

    var leftLeftActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "left")
    
    var leftRightActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "right")

    var doubleTapActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "dtap")

    var doubleTapSubActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "dtaps")

    var leftSubActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "leftsub")

    var rightSubActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "rightsub")
    
    var forceTouchActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "3dcomment")
    
    var canForceTouch = false

    var commentCell = UITableViewCell()
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCells()
        setupBaseBarColors()
    }
    
    func switchIsChanged(_ changed: UISwitch) {
        if changed == submissionGestures {
            SettingValues.submissionGesturesEnabled = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_submissionGesturesEnabled)
        } else if changed == disableBanner {
            SettingValues.disableBanner = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_disableBanner)
            SubredditReorderViewController.changed = true
        }

        UserDefaults.standard.synchronize()
        updateCells()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        
        switch section {
        case 0: label.text  = "Submissions"
        case 1: label.text  = "Comments"
        default: label.text  = ""
        }
        return toReturn
    }
    
    func showCommentGesturesMenu() {
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Select a comment gesture"
        for item in SettingValues.CommentGesturesMode.cases {
            alertController.addAction(Action(ActionData(title: item.description()), style: .default, handler: { _ in
                UserDefaults.standard.set(item.rawValue, forKey: SettingValues.pref_commentGesturesMode)
                SettingValues.commentGesturesMode = item
                UserDefaults.standard.synchronize()
                self.commentGesturesCell.detailTextLabel?.text = SettingValues.commentGesturesMode.description()
                self.updateCells()
            }))
        }
        VCPresenter.presentAlert(alertController, parentVC: self)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 && indexPath.section == 1 {
            showCommentGesturesMenu()
            return
        }
        
        if indexPath.row == 2 && indexPath.section == 0 {
            showActionSub(cell: doubleTapSubActionCell)
            return
        } else if indexPath.row == 3 && indexPath.section == 0 {
            showActionSub(cell: leftSubActionCell)
            return
        } else if indexPath.row == 4 && indexPath.section == 0 {
            showActionSub(cell: rightSubActionCell)
            return
        } else if indexPath.row == 5 && indexPath.section == 0 {
            showActionSub(cell: forceTouchSubmissionCell)
            return
        }
        
        if indexPath.section != 1 {
            return
        }
        if indexPath.row == 1 {
            showAction(cell: rightRightActionCell)
        } else if indexPath.row == 2 {
            showAction(cell: rightLeftActionCell)
        } else if indexPath.row == 3 {
            showAction(cell: leftLeftActionCell)
        } else if indexPath.row == 4 {
            showAction(cell: leftRightActionCell)
        } else if indexPath.row == 5 {
            showAction(cell: doubleTapActionCell)
        } else if indexPath.row == 6 {
            showAction(cell: forceTouchActionCell)
        }
    }
    
    func showAction(cell: UITableViewCell) {
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Select a comment gesture"
        for action in SettingValues.CommentAction.cases {
            alertController.addAction(Action(ActionData(title: action.getTitle(), image: UIImage(named: action.getPhoto())!.menuIcon()), style: .default, handler: { _ in
                if cell == self.leftRightActionCell {
                    SettingValues.commentActionLeftRight = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionLeftRight)
                } else if cell == self.rightRightActionCell {
                    SettingValues.commentActionRightRight = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionRightRight)
                } else if cell == self.leftLeftActionCell {
                    SettingValues.commentActionLeftLeft = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionLeftLeft)
                } else if cell == self.rightLeftActionCell {
                    SettingValues.commentActionRightLeft = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionRightLeft)
                } else if cell == self.forceTouchActionCell {
                    SettingValues.commentActionForceTouch = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionForceTouch)
                } else {
                    SettingValues.commentActionDoubleTap = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_commentActionDoubleTap)
                }
                
                UserDefaults.standard.synchronize()
                self.updateCells()
            }))
        }
        VCPresenter.presentAlert(alertController, parentVC: self)
    }
    
    func showActionSub(cell: UITableViewCell) {
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Select a submission gesture"
        for action in SettingValues.SubmissionAction.cases {
            alertController.addAction(Action(ActionData(title: action == .NONE ? "Peek content" : action.getTitle(), image: action == .NONE ? UIImage(named: "fullscreen")!.menuIcon() : UIImage(named: action.getPhoto())!.menuIcon() ), style: .default, handler: { _ in
                if cell == self.doubleTapSubActionCell {
                    SettingValues.submissionActionDoubleTap = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_submissionActionDoubleTap)
                } else if cell == self.rightSubActionCell {
                    SettingValues.submissionActionRight = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_submissionActionRight)
                } else if cell == self.leftSubActionCell {
                    SettingValues.submissionActionLeft = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_submissionActionLeft)
                } else if cell == self.forceTouchSubmissionCell {
                    SettingValues.submissionActionForceTouch = action
                    UserDefaults.standard.set(action.rawValue, forKey: SettingValues.pref_submissionActionForceTouch)
                }

                SubredditReorderViewController.changed = true
                UserDefaults.standard.synchronize()
                self.updateCells()
            }))
        }
        VCPresenter.presentAlert(alertController, parentVC: self)
    }

    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = ColorUtil.fontColor
        cell.backgroundColor = ColorUtil.foregroundColor
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if let s = switchV {
            s.isOn = isOn
            s.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
            cell.accessoryView = s
        }
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
    }
    
    override func loadView() {
        canForceTouch = (UIApplication.shared.keyWindow?.rootViewController?.traitCollection.forceTouchCapability ?? .unknown) == .available
        super.loadView()
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Gestures"
        self.tableView.separatorStyle = .none
        
        createCell(submissionGesturesCell, submissionGestures, isOn: SettingValues.submissionGesturesEnabled, text: "Enable submission gestures")
        self.submissionGesturesCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.submissionGesturesCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.submissionGesturesCell.detailTextLabel?.numberOfLines = 0
        self.submissionGesturesCell.detailTextLabel?.text = "Enabling submission gestures will require two fingers to swipe between subreddits in the main view"
        self.submissionGesturesCell.contentView.backgroundColor = ColorUtil.foregroundColor
        
        createCell(disableBannerCell, disableBanner, isOn: SettingValues.disableBanner, text: "Open comments from banner image")
        self.disableBannerCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.disableBannerCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.disableBannerCell.detailTextLabel?.numberOfLines = 0
        self.disableBannerCell.detailTextLabel?.text = "Enabling this will open comments when clicking on the submission banner image"
        self.disableBannerCell.contentView.backgroundColor = ColorUtil.foregroundColor

        createCell(commentGesturesCell, nil, isOn: false, text: "Comment gestures mode")
        self.commentGesturesCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.commentGesturesCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.commentGesturesCell.detailTextLabel?.numberOfLines = 0
        self.commentGesturesCell.detailTextLabel?.text = SettingValues.commentGesturesMode.description()
        self.commentGesturesCell.contentView.backgroundColor = ColorUtil.foregroundColor

        updateCells()
        self.tableView.tableFooterView = UIView()
        
        commentCell.contentView.backgroundColor = ColorUtil.foregroundColor
        let label = UILabel()
        for view in commentCell.contentView.subviews {
            view.removeFromSuperview()
        }
        commentCell.contentView.addSubview(label)
        label.edgeAnchors == commentCell.edgeAnchors + 8
        label.attributedText = getText()
        label.numberOfLines = 0
        label.sizeToFit()
        label.setBorder(border: .left, weight: 4, color: GMColor.red500Color())
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func getText() -> NSAttributedString {
        let color = ColorUtil.fontColor
        
        let boldFont = FontGenerator.boldFontOfSize(size: 12, submission: false)
        
        let scoreString = NSMutableAttributedString(string: "[score hidden]", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): color]))
        
        let endString = NSMutableAttributedString(string: "  •  3d", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor]))
        
        let authorStringNoFlair = NSMutableAttributedString(string: "u/ccrama\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor]))
        
        let infoString = NSMutableAttributedString(string: "")
            infoString.append(authorStringNoFlair)
        
        infoString.append(NSAttributedString(string: "  •  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): boldFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor])))
        infoString.append(scoreString)
        infoString.append(endString)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.5
        infoString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: infoString.length))
        
        let newTitle = NSMutableAttributedString(attributedString: infoString)
            newTitle.append(NSAttributedString.init(string: "\n\n", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 5)])))
        newTitle.append(TextDisplayStackView.createAttributedChunk(baseHTML: "<p>Swipe here to test the gestures out!</p>", fontSize: 16, submission: false, accentColor: ColorUtil.baseAccent))

        return newTitle
    }
    
//    @available(iOS 11.0, *)
//    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        if indexPath.row != 0 || indexPath.section != 1 {
//            return nil
//        }
//
//        if SettingValues.commentGesturesEnabled && (SettingValues.commentActionRightLeft != .NONE || SettingValues.commentActionRightRight != .NONE) {
//            HapticUtility.hapticActionWeak()
//            var actions = [UIContextualAction]()
//            if SettingValues.commentActionRightRight != .NONE {
//                let action = UIContextualAction.init(style: .normal, title: "", handler: { (_, _, b) in
//                    b(true)
//                })
//                action.backgroundColor = SettingValues.commentActionRightRight.getColor()
//                action.image = UIImage.init(named: SettingValues.commentActionRightRight.getPhoto())?.navIcon()
//
//                actions.append(action)
//            }
//            if SettingValues.commentActionRightLeft != .NONE {
//                let action = UIContextualAction.init(style: .normal, title: "", handler: { (_, _, b) in
//                    b(true)
//                })
//                action.backgroundColor = SettingValues.commentActionRightLeft.getColor()
//                action.image = UIImage.init(named: SettingValues.commentActionRightLeft.getPhoto())?.navIcon()
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
//        if indexPath.row != 0 || indexPath.section != 1 {
//            return nil
//        }
//
//        if SettingValues.commentGesturesEnabled && (SettingValues.commentActionLeftLeft != .NONE || SettingValues.commentActionLeftRight != .NONE) {
//            HapticUtility.hapticActionWeak()
//            var actions = [UIContextualAction]()
//            if SettingValues.commentActionLeftLeft != .NONE {
//                let action = UIContextualAction.init(style: .normal, title: "", handler: { (_, _, b) in
//                    b(true)
//                })
//                action.backgroundColor = SettingValues.commentActionLeftLeft.getColor()
//                action.image = UIImage.init(named: SettingValues.commentActionLeftLeft.getPhoto())?.navIcon()
//
//                actions.append(action)
//            }
//            if SettingValues.commentActionLeftRight != .NONE {
//                let action = UIContextualAction.init(style: .normal, title: "", handler: { (_, _, b) in
//                    b(true)
//                })
//                action.backgroundColor = SettingValues.commentActionLeftRight.getColor()
//                action.image = UIImage.init(named: SettingValues.commentActionLeftRight.getPhoto())?.navIcon()
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

    func updateCells() {
        createCell(rightRightActionCell, nil, isOn: false, text: "First action swiping left to right")
        createCell(rightLeftActionCell, nil, isOn: false, text: "Second action swiping left to right")
        createCell(leftLeftActionCell, nil, isOn: false, text: "First action swiping right to left")
        createCell(leftRightActionCell, nil, isOn: false, text: "Second action swiping right to left")
        createCell(doubleTapActionCell, nil, isOn: false, text: "Double tap comment action")
        createCell(forceTouchActionCell, nil, isOn: false, text: "3D-Touch comment action")
        createCell(doubleTapSubActionCell, nil, isOn: false, text: "Double tap submission action")
        createCell(leftSubActionCell, nil, isOn: false, text: "Left submission swipe")
        createCell(rightSubActionCell, nil, isOn: false, text: "Right submission swipe")
        createCell(forceTouchSubmissionCell, nil, isOn: false, text: "3D-Touch submission action")

        createLeftView(cell: forceTouchSubmissionCell, image: SettingValues.submissionActionForceTouch == .NONE ? "fullscreen" : SettingValues.submissionActionForceTouch.getPhoto(), color: SettingValues.submissionActionForceTouch == .NONE ? GMColor.lightGreen500Color() :SettingValues.submissionActionForceTouch.getColor())
        self.forceTouchSubmissionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.forceTouchSubmissionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.forceTouchSubmissionCell.detailTextLabel?.numberOfLines = 0
        self.forceTouchSubmissionCell.detailTextLabel?.text = SettingValues.submissionActionForceTouch == .NONE ? "Peek content" : SettingValues.submissionActionForceTouch.getTitle()
        self.forceTouchSubmissionCell.imageView?.layer.cornerRadius = 5

        createLeftView(cell: rightRightActionCell, image: SettingValues.commentActionRightRight.getPhoto(), color: SettingValues.commentActionRightRight.getColor())
        self.rightRightActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.rightRightActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.rightRightActionCell.detailTextLabel?.numberOfLines = 0
        self.rightRightActionCell.detailTextLabel?.text = SettingValues.commentActionRightRight.getTitle()
        self.rightRightActionCell.imageView?.layer.cornerRadius = 5

        createLeftView(cell: rightLeftActionCell, image: SettingValues.commentActionRightLeft.getPhoto(), color: SettingValues.commentActionRightLeft.getColor())
        self.rightLeftActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.rightLeftActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.rightLeftActionCell.detailTextLabel?.numberOfLines = 0
        self.rightLeftActionCell.detailTextLabel?.text = SettingValues.commentActionRightLeft.getTitle()
        self.rightLeftActionCell.imageView?.layer.cornerRadius = 5

        createLeftView(cell: leftRightActionCell, image: SettingValues.commentActionLeftRight.getPhoto(), color: SettingValues.commentActionLeftRight.getColor())
        self.leftRightActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.leftRightActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.leftRightActionCell.detailTextLabel?.numberOfLines = 0
        self.leftRightActionCell.detailTextLabel?.text = SettingValues.commentActionLeftRight.getTitle()
        self.leftRightActionCell.imageView?.layer.cornerRadius = 5

        createLeftView(cell: leftLeftActionCell, image: SettingValues.commentActionLeftLeft.getPhoto(), color: SettingValues.commentActionLeftLeft.getColor())
        self.leftLeftActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.leftLeftActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.leftLeftActionCell.detailTextLabel?.numberOfLines = 0
        self.leftLeftActionCell.detailTextLabel?.text = SettingValues.commentActionLeftLeft.getTitle()
        self.leftLeftActionCell.imageView?.layer.cornerRadius = 5

        createLeftView(cell: doubleTapActionCell, image: SettingValues.commentActionDoubleTap.getPhoto(), color: SettingValues.commentActionDoubleTap.getColor())
        self.doubleTapActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.doubleTapActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.doubleTapActionCell.detailTextLabel?.numberOfLines = 0
        self.doubleTapActionCell.detailTextLabel?.text = SettingValues.commentActionDoubleTap.getTitle()
        self.doubleTapActionCell.imageView?.layer.cornerRadius = 5
        
        createLeftView(cell: forceTouchActionCell, image: SettingValues.commentActionForceTouch.getPhoto(), color: SettingValues.commentActionForceTouch.getColor())
        self.forceTouchActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.forceTouchActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.forceTouchActionCell.detailTextLabel?.numberOfLines = 0
        self.forceTouchActionCell.detailTextLabel?.text = SettingValues.commentActionForceTouch.getTitle()
        self.forceTouchActionCell.imageView?.layer.cornerRadius = 5

        createLeftView(cell: leftSubActionCell, image: SettingValues.submissionActionLeft.getPhoto(), color: SettingValues.submissionActionLeft.getColor())
        self.leftSubActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.leftSubActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.leftSubActionCell.detailTextLabel?.numberOfLines = 0
        self.leftSubActionCell.detailTextLabel?.text = SettingValues.submissionActionLeft.getTitle()
        self.leftSubActionCell.imageView?.layer.cornerRadius = 5

        createLeftView(cell: rightSubActionCell, image: SettingValues.submissionActionRight.getPhoto(), color: SettingValues.submissionActionRight.getColor())
        self.rightSubActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.rightSubActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.rightSubActionCell.detailTextLabel?.numberOfLines = 0
        self.rightSubActionCell.detailTextLabel?.text = SettingValues.submissionActionRight.getTitle()
        self.rightSubActionCell.imageView?.layer.cornerRadius = 5

        if SettingValues.commentGesturesMode == .NONE || SettingValues.commentGesturesMode == .SWIPE_ANYWHERE {
            self.rightRightActionCell.isUserInteractionEnabled = false
            self.rightRightActionCell.contentView.alpha = 0.5
            self.rightLeftActionCell.isUserInteractionEnabled = false
            self.rightLeftActionCell.contentView.alpha = 0.5
            self.leftRightActionCell.isUserInteractionEnabled = false
            self.leftRightActionCell.contentView.alpha = 0.5
            self.leftLeftActionCell.isUserInteractionEnabled = false
            self.leftLeftActionCell.contentView.alpha = 0.5
        } else {
            self.rightRightActionCell.isUserInteractionEnabled = true
            self.rightRightActionCell.contentView.alpha = 1
            self.rightLeftActionCell.isUserInteractionEnabled = true
            self.rightLeftActionCell.contentView.alpha = 1
            self.leftRightActionCell.isUserInteractionEnabled = true
            self.leftRightActionCell.contentView.alpha = 1
            self.leftLeftActionCell.isUserInteractionEnabled = true
            self.leftLeftActionCell.contentView.alpha = 1
        }
        
        if !SettingValues.submissionGesturesEnabled {
            self.leftSubActionCell.isUserInteractionEnabled = false
            self.leftSubActionCell.contentView.alpha = 0.5
            self.rightSubActionCell.isUserInteractionEnabled = false
            self.rightSubActionCell.contentView.alpha = 0.5
        } else {
            self.leftSubActionCell.isUserInteractionEnabled = true
            self.leftSubActionCell.contentView.alpha = 1
            self.rightSubActionCell.isUserInteractionEnabled = true
            self.rightSubActionCell.contentView.alpha = 1
        }
        
        createLeftView(cell: doubleTapSubActionCell, image: SettingValues.submissionActionDoubleTap.getPhoto(), color: SettingValues.submissionActionDoubleTap.getColor())
        self.doubleTapSubActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.doubleTapSubActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.doubleTapSubActionCell.detailTextLabel?.numberOfLines = 0
        self.doubleTapSubActionCell.detailTextLabel?.text = SettingValues.submissionActionDoubleTap.getTitle()
        self.doubleTapSubActionCell.imageView?.layer.cornerRadius = 5
    }
    
    func createLeftView(cell: UITableViewCell, image: String, color: UIColor) {
        cell.imageView?.image = UIImage.init(named: image)?.navIcon().getCopy(withColor: ColorUtil.fontColor)
        cell.imageView?.backgroundColor = color
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? 100 : 70
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0: return self.commentGesturesCell
            //case 1: return self.commentCell
            case 1: return self.rightRightActionCell
            case 2: return self.rightLeftActionCell
            case 3: return self.leftLeftActionCell
            case 4: return self.leftRightActionCell
            case 5: return self.doubleTapActionCell
            case 6: return self.forceTouchActionCell
            default: fatalError("Unknown row in section 0")
            }
        case 0:
            switch indexPath.row {
            case 0: return self.submissionGesturesCell
            case 1: return self.disableBannerCell
            case 2: return self.doubleTapSubActionCell
            case 3: return self.leftSubActionCell
            case 4: return self.rightSubActionCell
            case 5: return self.forceTouchSubmissionCell
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 5 + (canForceTouch ? 1 : 0)
        case 1: return 6 + (canForceTouch ? 1 : 0)
        default: fatalError("Unknown number of sections")
        }
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
