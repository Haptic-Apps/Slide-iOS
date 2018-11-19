//
//  SettingsViewMode.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 10/31/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SettingsViewMode: UITableViewController {
    
    var singleMode: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "single")
    var splitMode: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "split")
    var multicolumnMode: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "multi")
    var multicolumnCount: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "multicount")

    var numberColumns: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "number")
    
    var subredditBar = UITableViewCell()
    var subredditBarSwitch = UISwitch()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }
    
    func switchIsChanged(_ changed: UISwitch) {
        if changed == subredditBarSwitch {
            MainViewController.needsRestart = true
            SettingValues.subredditBar = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_subBar)
        }
        UserDefaults.standard.synchronize()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        
        switch section {
        case 0: label.text = "Subreddit display mode"
        case 1: label.text = "Other settings"
        default: label.text = ""
        }
        return toReturn
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
        self.title = "App Mode"
        self.tableView.separatorStyle = .none
        
        createCell(subredditBar, subredditBarSwitch, isOn: SettingValues.subredditBar, text: "Swipable subreddit bar")
        createCell(singleMode, isOn: false, text: "Single-column posts")
        createCell(multicolumnMode, isOn: false, text: "Multi-column posts")
        createCell(splitMode, isOn: false, text: "Split-content")
        createCell(multicolumnCount, isOn: false, text: "Multi-column count")

        self.singleMode.detailTextLabel?.text = SettingValues.AppMode.SINGLE.getDescription()
        self.singleMode.detailTextLabel?.textColor = ColorUtil.fontColor
        self.singleMode.backgroundColor = ColorUtil.foregroundColor
        self.singleMode.textLabel?.textColor = ColorUtil.fontColor
        self.singleMode.detailTextLabel?.numberOfLines = 0
        
        self.splitMode.detailTextLabel?.text = SettingValues.AppMode.SPLIT.getDescription()
        self.splitMode.detailTextLabel?.textColor = ColorUtil.fontColor
        self.splitMode.backgroundColor = ColorUtil.foregroundColor
        self.splitMode.textLabel?.textColor = ColorUtil.fontColor
        self.splitMode.detailTextLabel?.numberOfLines = 0

        self.multicolumnMode.detailTextLabel?.text = SettingValues.AppMode.MULTI_COLUMN.getDescription()
        self.multicolumnMode.detailTextLabel?.textColor = ColorUtil.fontColor
        self.multicolumnMode.backgroundColor = ColorUtil.foregroundColor
        self.multicolumnMode.textLabel?.textColor = ColorUtil.fontColor
        self.multicolumnMode.detailTextLabel?.numberOfLines = 0

        self.multicolumnCount.detailTextLabel?.text = SettingValues.AppMode.SINGLE.getDescription()
        self.multicolumnCount.detailTextLabel?.textColor = ColorUtil.fontColor
        self.multicolumnCount.backgroundColor = ColorUtil.foregroundColor
        self.multicolumnCount.textLabel?.textColor = ColorUtil.fontColor
        self.multicolumnCount.detailTextLabel?.numberOfLines = 0

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
        
        if !SettingValues.isPro {
            multicolumnMode.isUserInteractionEnabled = false
            multicolumnMode.textLabel!.isEnabled = false
            multicolumnMode.detailTextLabel!.isEnabled = false
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
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 70
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
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
            case 1: return self.subredditBar
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
        }
        
        SubredditReorderViewController.changed = true
        UserDefaults.standard.synchronize()
        setSelected()
    }
    
    func showMultiColumn() {
        let pad = UIScreen.main.traitCollection.userInterfaceIdiom == .pad
        let actionSheetController: UIAlertController = UIAlertController(title: "Column count", message: "", preferredStyle: .actionSheet)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { _ -> Void in
        }
        actionSheetController.addAction(cancelActionButton)

        let values = pad ? [["1", "2", "3", "4", "5"]] : [["1", "2", "3"]]
        actionSheetController.addPickerView(values: values, initialSelection: [(0, SettingValues.multiColumnCount - 1)]) { (_, _, chosen, _) in
            SettingValues.multiColumnCount = chosen.row + 1
            UserDefaults.standard.set(chosen.row + 1, forKey: SettingValues.pref_multiColumnCount)
            UserDefaults.standard.synchronize()
            SubredditReorderViewController.changed = true
            self.setSelected()
        }

        actionSheetController.modalPresentationStyle = .popover

        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = self.multicolumnCount.contentView
            presenter.sourceRect = self.multicolumnCount.contentView.bounds
        }

        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return 2
        default: fatalError("Unknown number of sections")
        }
    }
    
}
