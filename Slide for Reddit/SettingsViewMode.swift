//
//  SettingsViewMode.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 10/31/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import SDCAlertView
import UIKit

class SettingsViewMode: BubbleSettingTableViewController {
    
    var singleMode: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "single")
    var splitMode: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "split")
    var multicolumnMode: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "multi")
    var multicolumnCount: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "multicount")
    var galleryCount: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "gallerycount")

    var numberColumns: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "number")
    
    var subredditBar = InsetCell()
    var subredditBarSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var thireenPopup = InsetCell()
    var thireenPopupSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == subredditBarSwitch {
            MainViewController.needsRestart = true
            SettingValues.subredditBar = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_subBar)
        } else if changed == thireenPopupSwitch {
            SettingValues.disable13Popup = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_disable13Popup)
        }
        UserDefaults.standard.synchronize()
    }

    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = ColorUtil.theme.fontColor
        cell.backgroundColor = ColorUtil.theme.foregroundColor
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if let s = switchV {
            s.isOn = isOn
            s.addTarget(self, action: #selector(switchIsChanged(_:)), for: UIControl.Event.valueChanged)
            cell.accessoryView = s
        }
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
    }
    
    override func loadView() {
        super.loadView()
        
        headers = ["Subreddit display mode", "Other settings"]
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        // set the title
        self.title = "App Mode"
        
        createCell(subredditBar, subredditBarSwitch, isOn: SettingValues.subredditBar, text: "Swipable subreddit bar")
        createCell(thireenPopup, thireenPopupSwitch, isOn: SettingValues.disable13Popup, text: "Disable iOS 13 popup behavior")
        createCell(singleMode, isOn: false, text: "Single-column posts")
        createCell(multicolumnMode, isOn: false, text: "Multi-column posts")
        createCell(splitMode, isOn: false, text: "Split-content")
        createCell(multicolumnCount, isOn: false, text: "Multi-column count (customize with Pro)")
        createCell(galleryCount, isOn: false, text: "Gallery-mode column count (Pro)")

        self.singleMode.detailTextLabel?.text = SettingValues.AppMode.SINGLE.getDescription()
        self.singleMode.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.singleMode.backgroundColor = ColorUtil.theme.foregroundColor
        self.singleMode.textLabel?.textColor = ColorUtil.theme.fontColor
        self.singleMode.detailTextLabel?.numberOfLines = 0
        
        self.splitMode.detailTextLabel?.text = SettingValues.AppMode.SPLIT.getDescription()
        self.splitMode.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.splitMode.backgroundColor = ColorUtil.theme.foregroundColor
        self.splitMode.textLabel?.textColor = ColorUtil.theme.fontColor
        self.splitMode.detailTextLabel?.numberOfLines = 0

        self.multicolumnMode.detailTextLabel?.text = SettingValues.AppMode.MULTI_COLUMN.getDescription()
        self.multicolumnMode.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.multicolumnMode.backgroundColor = ColorUtil.theme.foregroundColor
        self.multicolumnMode.textLabel?.textColor = ColorUtil.theme.fontColor
        self.multicolumnMode.detailTextLabel?.numberOfLines = 0

        self.multicolumnCount.detailTextLabel?.text = SettingValues.AppMode.SINGLE.getDescription()
        self.multicolumnCount.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.multicolumnCount.backgroundColor = ColorUtil.theme.foregroundColor
        self.multicolumnCount.textLabel?.textColor = ColorUtil.theme.fontColor
        self.multicolumnCount.detailTextLabel?.numberOfLines = 0

        self.galleryCount.detailTextLabel?.text = SettingValues.AppMode.SINGLE.getDescription()
        self.galleryCount.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.galleryCount.backgroundColor = ColorUtil.theme.foregroundColor
        self.galleryCount.textLabel?.textColor = ColorUtil.theme.fontColor
        self.galleryCount.detailTextLabel?.numberOfLines = 0

        self.setSelected()

        self.tableView.tableFooterView = UIView()
    }
    
    func setSelected() {
        self.singleMode.accessoryType = .none
        self.splitMode.accessoryType = .none
        self.multicolumnMode.accessoryType = .none
        
        switch SettingValues.appMode {
        case .SINGLE:
            self.singleMode.accessoryType = .checkmark
        case .SPLIT:
            self.splitMode.accessoryType = .checkmark
        case .MULTI_COLUMN:
            self.multicolumnMode.accessoryType = .checkmark
        }
            
        self.galleryCount.isUserInteractionEnabled = true
        self.galleryCount.textLabel!.isEnabled = true
        self.galleryCount.detailTextLabel!.isEnabled = true

        if !SettingValues.isPro {
            multicolumnCount.isUserInteractionEnabled = false
            multicolumnCount.textLabel!.isEnabled = false
            multicolumnCount.detailTextLabel!.isEnabled = false
            multicolumnCount.contentView.alpha = 0.8
            galleryCount.isUserInteractionEnabled = false
            galleryCount.textLabel!.isEnabled = false
            galleryCount.detailTextLabel!.isEnabled = false
            galleryCount.contentView.alpha = 0.8
        }

        if UIDevice.current.userInterfaceIdiom != .pad {
            self.splitMode.isUserInteractionEnabled = false
            self.splitMode.textLabel!.isEnabled = false
            self.splitMode.detailTextLabel!.isEnabled = false
        }
        
        if SettingValues.appMode != .MULTI_COLUMN {
            self.multicolumnCount.isUserInteractionEnabled = false
            self.multicolumnCount.textLabel!.isEnabled = false
            self.multicolumnCount.detailTextLabel!.isEnabled = false
        } else {
            self.multicolumnCount.isUserInteractionEnabled = true
            self.multicolumnCount.textLabel!.isEnabled = true
            self.multicolumnCount.detailTextLabel!.isEnabled = true
        }
        
        
        var portraitCount = SettingValues.multiColumnCount / 2
        if portraitCount == 0 {
            portraitCount = 1
        }
        
        let pad = UIScreen.main.traitCollection.userInterfaceIdiom == .pad
        if portraitCount == 1 && pad {
            portraitCount = 2
        }

        self.multicolumnCount.detailTextLabel?.text = "\(SettingValues.multiColumnCount) landscape, \(portraitCount) portrait"
        self.galleryCount.detailTextLabel?.text = "\(SettingValues.galleryCount) across"
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.singleMode
            case 1: return self.splitMode
            case 2: return self.multicolumnMode
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.multicolumnCount
            case 1: return self.galleryCount
            case 2: return self.subredditBar
            case 3: return self.thireenPopup
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                SettingValues.appMode = .SINGLE
                UserDefaults.standard.set(SettingValues.AppMode.SINGLE.rawValue, forKey: SettingValues.pref_appMode)
            case 1:
                SettingValues.appMode = .SPLIT
                UserDefaults.standard.set(SettingValues.AppMode.SPLIT.rawValue, forKey: SettingValues.pref_appMode)
            case 2:
                SettingValues.appMode = .MULTI_COLUMN
                UserDefaults.standard.set(SettingValues.AppMode.MULTI_COLUMN.rawValue, forKey: SettingValues.pref_appMode)
            default:
                break
            }
        } else if indexPath.section == 1 && indexPath.row == 0 {
            showMultiColumn()
        } else if indexPath.section == 1 && indexPath.row == 1 {
            showGalleryColumn()
        }
        
        SubredditReorderViewController.changed = true
        UserDefaults.standard.synchronize()
        setSelected()
    }
    
    func showMultiColumn() {
        let pad = UIScreen.main.traitCollection.userInterfaceIdiom == .pad
        let actionSheetController = AlertController(title: "Column count", message: nil, preferredStyle: .alert)

        actionSheetController.addCloseButton()

        let values = pad ? [["1", "2", "3", "4", "5"]] : [["1", "2", "3"]]
        let pickerView = PickerViewViewControllerColored(values: values, initialSelection: [(0, SettingValues.multiColumnCount - 1)], action: { (_, _, chosen, _) in
            SettingValues.multiColumnCount = chosen.row + 1
            UserDefaults.standard.set(chosen.row + 1, forKey: SettingValues.pref_multiColumnCount)
            UserDefaults.standard.synchronize()
            SubredditReorderViewController.changed = true
            self.setSelected()
        })

        actionSheetController.setupTheme()
        
        actionSheetController.attributedTitle = NSAttributedString(string: "Landscape column count", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        actionSheetController.addChild(pickerView)
        
        let pv = pickerView.view!
        actionSheetController.contentView.addSubview(pv)
        
        pv.edgeAnchors == actionSheetController.contentView.edgeAnchors - 14
        pv.heightAnchor == CGFloat(216)
        pickerView.didMove(toParent: actionSheetController)
        
        actionSheetController.addBlurView()

        self.present(actionSheetController, animated: true, completion: nil)
    }

    func showGalleryColumn() {
        let pad = UIScreen.main.traitCollection.userInterfaceIdiom == .pad
        let actionSheetController = AlertController(title: "Gallery column count", message: nil, preferredStyle: .alert)

        actionSheetController.addCloseButton()

        let values = pad ? [["1", "2", "3", "4", "5"]] : [["1", "2", "3"]]
        let pickerView = PickerViewViewControllerColored(values: values, initialSelection: [(0, SettingValues.galleryCount - 1)], action: { (_, _, chosen, _) in
            SettingValues.galleryCount = chosen.row + 1
            UserDefaults.standard.set(chosen.row + 1, forKey: SettingValues.pref_galleryCount)
            UserDefaults.standard.synchronize()
            SubredditReorderViewController.changed = true
            self.setSelected()
        })

        actionSheetController.setupTheme()
        
        actionSheetController.attributedTitle = NSAttributedString(string: "Gallery column count", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        actionSheetController.addChild(pickerView)
        
        let pv = pickerView.view!
        actionSheetController.contentView.addSubview(pv)
        
        pv.edgeAnchors == actionSheetController.contentView.edgeAnchors - 14
        pv.heightAnchor == CGFloat(216)
        pickerView.didMove(toParent: actionSheetController)
        
        actionSheetController.addBlurView()

        self.present(actionSheetController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var thirteenOffset = 0
        if #available(iOS 13, *) {
            thirteenOffset = 1
        }
        switch section {
        case 0: return 3
        case 1: return 3 + thirteenOffset
        default: fatalError("Unknown number of sections")
        }
    }
    
}
