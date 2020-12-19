//
//  SettingsHistory.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/17/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class SettingsHistory: BubbleSettingTableViewController {
    
    var saveHistoryCell: UITableViewCell = InsetCell()
    var saveHistory = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var saveNSFWHistoryCell: UITableViewCell = InsetCell()
    var saveNSFWHistory = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var hideSeenCell: UITableViewCell = InsetCell()
    var hideSeen = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var readOnScrollCell: UITableViewCell = InsetCell()
    var readOnScroll = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var dotCell: UITableViewCell = InsetCell()
    var dot = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var exportCollectionsCell: UITableViewCell = InsetCell()

    var clearHistory: UITableViewCell = InsetCell()

    var clearSubs: UITableViewCell = InsetCell()

    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == saveHistory {
            SettingValues.saveHistory = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_saveHistory)
        } else if changed == saveNSFWHistory {
            SettingValues.saveNSFWHistory = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_saveNSFWHistory)
        } else if changed == hideSeen {
            SettingValues.hideSeen = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_hideSeen)
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
    
    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = UIColor.fontColor
        cell.backgroundColor = UIColor.foregroundColor
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
        
        self.view.backgroundColor = UIColor.backgroundColor
        // set the title
        self.title = "History"
        self.headers = ["Settings", "Clear history", "Export data"]

        createCell(saveHistoryCell, saveHistory, isOn: SettingValues.saveHistory, text: "Save submission and subreddit history")
        createCell(saveNSFWHistoryCell, saveNSFWHistory, isOn: !SettingValues.saveNSFWHistory, text: "Hide NSFW submission and subreddit history")
        createCell(readOnScrollCell, readOnScroll, isOn: SettingValues.markReadOnScroll, text: "Mark submissions as read when scrolled off screen")
        createCell(dotCell, dot, isOn: SettingValues.newIndicator, text: "New submissions indicator")
        createCell(exportCollectionsCell, nil, isOn: false, text: "Export your Slide collections as .csv")
        exportCollectionsCell.accessoryType = .disclosureIndicator

        dotCell.detailTextLabel?.numberOfLines = 0
        dotCell.detailTextLabel?.textColor = UIColor.fontColor
        dotCell.detailTextLabel?.text = "Enabling this will disable the 'grayed out' effect of read submissions"
        
        createCell(hideSeenCell, hideSeen, isOn: SettingValues.hideSeen, text: "Hide read posts automatically")
        hideSeenCell.detailTextLabel?.numberOfLines = 0
        hideSeenCell.detailTextLabel?.textColor = UIColor.fontColor
        hideSeenCell.detailTextLabel?.text = "Enabling this may lead to no posts loading in a subreddit"

        clearHistory.textLabel?.text = "Clear submission history"
        clearHistory.backgroundColor = UIColor.foregroundColor
        clearHistory.textLabel?.textColor = UIColor.fontColor
        clearHistory.selectionStyle = UITableViewCell.SelectionStyle.none
        clearHistory.accessoryType = .disclosureIndicator

        clearSubs.textLabel?.text = "Clear subreddit history"
        clearSubs.backgroundColor = UIColor.foregroundColor
        clearSubs.textLabel?.textColor = UIColor.fontColor
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
        if indexPath.section == 2 {
           exportCollectionsCSV(from: Collections.collectionIDs)
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
    func exportCollectionsCSV(from: NSDictionary) {
        var csvString = "\("Collection Name"),\("Reddit permalink")\n\n"
        for key in from.allKeys {
            csvString += "\(from[key] ?? "") , https://redd.it/\((key as! String).replacingOccurrences(of: "t3_", with: ""))\n"
        }

        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("Slide-Collections\(Date().dateString().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: ",", with: "-")).csv")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            var filesToShare = [Any]()

            filesToShare.append(fileURL)

            let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
        } catch {
            print("error creating file")
        }

    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.saveHistoryCell
            case 1: return self.saveNSFWHistoryCell
            case 2: return self.readOnScrollCell
            case 3: return self.dotCell
            case 4: return self.hideSeenCell
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.clearHistory
            case 1: return self.clearSubs
            default: fatalError("Unknown row in section 0")
            }
        case 2:
            return exportCollectionsCell

        default: fatalError("Unknown section")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 5   // section 0 has 2 rows
        case 1: return 2
        case 2: return 1
        default: fatalError("Unknown number of sections")
        }
    }
}
