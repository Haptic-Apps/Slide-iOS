//
//  SettingsHistory.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/17/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialSnackbar

class SettingsHistory: UITableViewController {
    
    var saveHistoryCell: UITableViewCell = UITableViewCell()
    var saveHistory = UISwitch()
    
    var saveNSFWHistoryCell: UITableViewCell = UITableViewCell()
    var saveNSFWHistory = UISwitch()

    var readOnScrollCell: UITableViewCell = UITableViewCell()
    var readOnScroll = UISwitch()

    var clearHistory: UITableViewCell = UITableViewCell()

    var clearSubs: UITableViewCell = UITableViewCell()

    //for future var dontLoadImagePreviewsCell: UITableViewCell = UITableViewCell()
    // var dontLoadImagePreviews = UISwitch()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
        navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    func switchIsChanged(_ changed: UISwitch) {
        if(changed == saveHistory){
            SettingValues.saveHistory = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_saveHistory)
        } else if(changed == saveNSFWHistory){
            SettingValues.saveNSFWHistory = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_saveNSFWHistory)
        } else if(changed == readOnScroll){
            SettingValues.markReadOnScroll = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_markReadOnScroll)
        }
        UserDefaults.standard.synchronize()
        doDisables()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label : UILabel = UILabel()
        label.textColor = ColorUtil.fontColor
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        
        switch(section) {
        case 0: label.text  = "Settings"
            break
        case 1: label.text = "Clear History"
        default: label.text  = ""
            break
        }
        return toReturn
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "History"
        
        saveHistory = UISwitch()
        saveHistory.isOn = SettingValues.saveHistory
        saveHistory.addTarget(self, action: #selector(SettingsHistory.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        saveHistoryCell.textLabel?.text = "Save submission history"
        saveHistoryCell.accessoryView = saveHistory
        saveHistoryCell.backgroundColor = ColorUtil.foregroundColor
        saveHistoryCell.textLabel?.textColor = ColorUtil.fontColor
        saveHistoryCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        saveNSFWHistory = UISwitch()
        saveNSFWHistory.isOn = SettingValues.saveNSFWHistory
        saveNSFWHistory.addTarget(self, action: #selector(SettingsHistory.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        saveNSFWHistoryCell.textLabel?.text = "Save NSFW history"
        saveNSFWHistoryCell.accessoryView = saveNSFWHistory
        saveNSFWHistoryCell.backgroundColor = ColorUtil.foregroundColor
        saveNSFWHistoryCell.textLabel?.textColor = ColorUtil.fontColor
        saveNSFWHistoryCell.selectionStyle = UITableViewCellSelectionStyle.none

        readOnScroll = UISwitch()
        readOnScroll.isOn = SettingValues.markReadOnScroll
        readOnScroll.addTarget(self, action: #selector(SettingsHistory.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        readOnScrollCell.textLabel?.text = "Mark as read on scroll"
        readOnScrollCell.accessoryView = readOnScroll
        readOnScrollCell.backgroundColor = ColorUtil.foregroundColor
        readOnScrollCell.textLabel?.textColor = ColorUtil.fontColor
        readOnScrollCell.selectionStyle = UITableViewCellSelectionStyle.none

        clearHistory.textLabel?.text = "Clear submission history"
        clearHistory.backgroundColor = ColorUtil.foregroundColor
        clearHistory.textLabel?.textColor = ColorUtil.fontColor
        clearHistory.selectionStyle = UITableViewCellSelectionStyle.none

        clearSubs.textLabel?.text = "Clear subreddit history"
        clearSubs.backgroundColor = ColorUtil.foregroundColor
        clearSubs.textLabel?.textColor = ColorUtil.fontColor
        clearSubs.selectionStyle = UITableViewCellSelectionStyle.none

        doDisables()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.section == 1){
            if(indexPath.row == 0){
                History.clearHistory()
                let message = MDCSnackbarMessage()
                message.text = "Submission history cleared"
                MDCSnackbarManager.show(message)
            } else {
                Subscriptions.clearSubHistory()
                let message = MDCSnackbarMessage()
                message.text = "Subreddit history cleared"
                MDCSnackbarManager.show(message)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func doDisables(){
        if(SettingValues.saveHistory){
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
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch(indexPath.section) {
        case 0:
            switch(indexPath.row) {
            case 0: return self.saveHistoryCell
            case 1: return self.saveNSFWHistoryCell
            case 2: return self.readOnScrollCell
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch(indexPath.row) {
            case 0: return self.clearHistory
            case 1: return self.clearSubs
            default: fatalError("Unknown row in section 0")
            }

        default: fatalError("Unknown section")
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return 3   // section 0 has 2 rows
        case 1: return 2
        default: fatalError("Unknown number of sections")
        }
    }
}
