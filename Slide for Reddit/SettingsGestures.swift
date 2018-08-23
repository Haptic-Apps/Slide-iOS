//
//  SettingsGestures.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/22/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import XLActionController

class SettingsGestures: UITableViewController {
    
    var doubleSwipeCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "double")
    var doubleSwipe = UISwitch()
    
    var swipeAnywhereCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "anywhere")
    var swipeAnywhere = UISwitch()

    var rightLeftActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "left")

    var rightRightActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "right")

    var leftLeftActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "left")
    
    var leftRightActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "right")

    var doubleTapActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "dtap")

    var doubleTapSubActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "dtaps")

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCells()
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
        navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    func switchIsChanged(_ changed: UISwitch) {
        if changed == doubleSwipe {
            SettingValues.commentTwoSwipe = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_commentTwoSwipe)
        } else if changed == swipeAnywhere {
            SettingValues.swipeAnywhereComments = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_swipeAnywhereComments)
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
        case 0: label.text  = "Comments"
        case 1: label.text  = "Submissions"
        default: label.text  = ""
        }
        return toReturn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 2 {
            showAction(cell: rightRightActionCell)
        } else if indexPath.row == 3 {
            showAction(cell: rightLeftActionCell)
        } else if indexPath.row == 4 {
            showAction(cell: leftLeftActionCell)
        } else if indexPath.row == 5 {
            showAction(cell: leftRightActionCell)
        } else if indexPath.row == 6 {
            showAction(cell: doubleTapActionCell)
        } else if indexPath.row == 0 && indexPath.section == 1 {
            showAction(cell: doubleTapSubActionCell)
        }
    }
    
    func showAction(cell: UITableViewCell) {
        let alertController: BottomSheetActionController = BottomSheetActionController()
        for action in SettingValues.CommentAction.cases {
            alertController.addAction(Action(ActionData(title: action.getTitle(), image: UIImage(named: action.getPhoto())!.menuIcon()), style: .default, handler: { _ in
                UserDefaults.standard.set(action.rawValue, forKey: cell == self.rightRightActionCell ? SettingValues.pref_commentActionRightRight : (cell == self.rightLeftActionCell ? SettingValues.pref_commentActionRightLeft : (cell == self.doubleTapSubActionCell ? SettingValues.pref_submissionActionDoubleTap :  SettingValues.pref_commentActionDoubleTap)))
                if cell == self.rightRightActionCell {
                    SettingValues.commentActionRightRight = action
                } else if cell == self.rightLeftActionCell {
                    SettingValues.commentActionRightLeft = action
                } else if cell == self.doubleTapActionCell {
                    SettingValues.commentActionDoubleTap = action
                } else if cell == self.leftLeftActionCell {
                        SettingValues.commentActionLeftLeft = action
                } else if cell == self.leftRightActionCell {
                        SettingValues.commentActionLeftRight = action
                } else {
                    SettingValues.submissionActionDoubleTap = action
                    SubredditReorderViewController.changed = true
                }
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
            s.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
            cell.accessoryView = s
        }
        cell.selectionStyle = UITableViewCellSelectionStyle.none
    }
    
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Gestures"
        self.tableView.separatorStyle = .none
        
        createCell(doubleSwipeCell, doubleSwipe, isOn: SettingValues.commentTwoSwipe, text: "Double finger swipe to go to next submission in comments view")
        self.doubleSwipeCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.doubleSwipeCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.doubleSwipeCell.detailTextLabel?.numberOfLines = 0
        self.doubleSwipeCell.detailTextLabel?.text = "Turning this off enables single finger swipe mode, which will disable comment slide gestures"
        
        createCell(swipeAnywhereCell, swipeAnywhere, isOn: SettingValues.swipeAnywhereComments, text: "Swipe anywhere to exit comments")
        self.swipeAnywhereCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.swipeAnywhereCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.swipeAnywhereCell.detailTextLabel?.numberOfLines = 0
        self.swipeAnywhereCell.detailTextLabel?.text = "Turning this off enables the left-side comment gestures"

        updateCells()
        self.tableView.tableFooterView = UIView()
    }
    
    func updateCells() {
        createCell(rightRightActionCell, nil, isOn: false, text: "First right slide button (also triggered by a long slide)")
        createCell(rightLeftActionCell, nil, isOn: false, text: "Second right slide button")
        createCell(leftLeftActionCell, nil, isOn: false, text: "First left slide button (also triggered by a long slide)")
        createCell(leftRightActionCell, nil, isOn: false, text: "Second left slide button")
        createCell(doubleTapActionCell, nil, isOn: false, text: "Double tap comment action")
        createCell(doubleTapSubActionCell, nil, isOn: false, text: "Double tap submission action")

        createLeftView(cell: doubleSwipeCell, image: "twofinger", color: ColorUtil.foregroundColor)
        createLeftView(cell: swipeAnywhereCell, image: "back", color: ColorUtil.foregroundColor)

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
        
        if !SettingValues.commentTwoSwipe {
            self.rightRightActionCell.isUserInteractionEnabled = false
            self.rightRightActionCell.contentView.alpha = 0.5
            self.rightLeftActionCell.isUserInteractionEnabled = false
            self.rightLeftActionCell.contentView.alpha = 0.5
        } else {
            self.rightRightActionCell.isUserInteractionEnabled = true
            self.rightRightActionCell.contentView.alpha = 1
            self.rightLeftActionCell.isUserInteractionEnabled = true
            self.rightLeftActionCell.contentView.alpha = 1
        }
        
        if SettingValues.swipeAnywhereComments {
            self.leftLeftActionCell.isUserInteractionEnabled = false
            self.leftLeftActionCell.contentView.alpha = 0.5
            self.leftRightActionCell.isUserInteractionEnabled = false
            self.leftRightActionCell.contentView.alpha = 0.5
        } else {
            self.leftLeftActionCell.isUserInteractionEnabled = true
            self.leftLeftActionCell.contentView.alpha = 1
            self.leftRightActionCell.isUserInteractionEnabled = true
            self.leftRightActionCell.contentView.alpha = 1
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
        if section == 0 {
            return 0
        }
        return 70
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath.row == 0 || indexPath.row == 1) && indexPath.section == 0 ? 150 : 70
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.doubleSwipeCell
            case 1: return self.swipeAnywhereCell
            case 2: return self.rightRightActionCell
            case 3: return self.rightLeftActionCell
            case 4: return self.leftLeftActionCell
            case 5: return self.leftRightActionCell
            case 6: return self.doubleTapActionCell
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.doubleTapSubActionCell
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 7
        case 1: return 1
        default: fatalError("Unknown number of sections")
        }
    }
    
}
