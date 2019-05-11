//
//  SettingsHistory.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/17/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class SettingsHistory: UITableViewController {
    
    var saveHistoryCell: UITableViewCell = UITableViewCell()
    var saveHistory = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var saveNSFWHistoryCell: UITableViewCell = UITableViewCell()
    var saveNSFWHistory = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var readOnScrollCell: UITableViewCell = UITableViewCell()
    var readOnScroll = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var dotCell: UITableViewCell = UITableViewCell()
    var dot = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var clearHistory: UITableViewCell = UITableViewCell()

    var clearSubs: UITableViewCell = UITableViewCell()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }
    
    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == saveHistory {
            SettingValues.saveHistory = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_saveHistory)
        } else if changed == saveNSFWHistory {
            SettingValues.saveNSFWHistory = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_saveNSFWHistory)
        } else if changed == dot {
            SettingValues.newIndicator = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_newIndicator)
        } else if changed == readOnScroll {
            SettingValues.markReadOnScroll = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_markReadOnScroll)
        }
        UserDefaults.standard.synchronize()
        doDisables()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.theme.backgroundColor
        
        switch section {
        case 0: label.text  = "Settings"
        case 1: label.text = "Clear History"
        default: label.text  = ""
        }
        return toReturn
    }
    
    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = ColorUtil.theme.fontColor
        cell.backgroundColor = ColorUtil.theme.backgroundColor
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
        super.loadView()
        
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        // set the title
        self.title = "History"
        self.tableView.separatorStyle = .none

        createCell(saveHistoryCell, saveHistory, isOn: SettingValues.saveHistory, text: "Save submission and subreddit history")
        createCell(saveNSFWHistoryCell, saveNSFWHistory, isOn: SettingValues.saveNSFWHistory, text: "Save NSFW submission and subreddit history")
        createCell(readOnScrollCell, readOnScroll, isOn: SettingValues.markReadOnScroll, text: "Mark submissions as read when scrolled off screen")
        createCell(dotCell, dot, isOn: SettingValues.newIndicator, text: "Show new posts with a dot instead of graying post titles")

        clearHistory.textLabel?.text = "Clear submission history"
        clearHistory.backgroundColor = ColorUtil.theme.backgroundColor
        clearHistory.textLabel?.textColor = ColorUtil.theme.fontColor
        clearHistory.selectionStyle = UITableViewCell.SelectionStyle.none
        clearHistory.accessoryType = .disclosureIndicator

        clearSubs.textLabel?.text = "Clear subreddit history"
        clearSubs.backgroundColor = ColorUtil.theme.backgroundColor
        clearSubs.textLabel?.textColor = ColorUtil.theme.fontColor
        clearSubs.selectionStyle = UITableViewCell.SelectionStyle.none
        clearSubs.accessoryType = .disclosureIndicator

        doDisables()
        self.tableView.tableFooterView = UIView()

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                History.clearHistory()
                BannerUtil.makeBanner(text: "Submission history cleared!", color: GMColor.green500Color(), seconds: 5, context: self)
            } else {
                Subscriptions.clearSubHistory()
                BannerUtil.makeBanner(text: "Subreddit history cleared!", color: GMColor.green500Color(), seconds: 5, context: self)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func doDisables() {
        if SettingValues.saveHistory {
            saveNSFWHistory.isEnabled = true
            readOnScroll.isEnabled = true
        } else {
            saveNSFWHistory.isEnabled = false
            readOnScroll.isEnabled = false
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
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
            case 0: return self.saveHistoryCell
            case 1: return self.saveNSFWHistoryCell
            case 2: return self.readOnScrollCell
            case 3: return self.dotCell
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.clearHistory
            case 1: return self.clearSubs
            default: fatalError("Unknown row in section 0")
            }

        default: fatalError("Unknown section")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4   // section 0 has 2 rows
        case 1: return 2
        default: fatalError("Unknown number of sections")
        }
    }
}
