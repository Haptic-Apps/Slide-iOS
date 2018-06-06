//
//  SettingsData.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/19/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class SettingsData: UITableViewController {
    
    var enableDataSavingCell: UITableViewCell = UITableViewCell()
    var enableDataSaving = UISwitch()
    
    var disableOnWifiCell: UITableViewCell = UITableViewCell()
    var disableOnWifi = UISwitch()
    //load hq always
    //LOwer quality mode
    //Dont show images
    var loadHQViewerCell: UITableViewCell = UITableViewCell()
    var loadHQViewer = UISwitch()
    
    var lowerQualityModeCell: UITableViewCell = UITableViewCell()
    var lowerQualityMode = UISwitch()
    
    var dontLoadImagePreviewsCell: UITableViewCell = UITableViewCell()
    var dontLoadImagePreviews = UISwitch()
    
    
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
        if(changed == enableDataSaving){
            SettingValues.dataSavingEnabled = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_dataSavingEnabled)
        } else if(changed == disableOnWifi){
            SettingValues.dataSavingDisableWiFi = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_dataSavingDisableWifi)
        } else if(changed == loadHQViewer){
            SettingValues.loadContentHQ = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_loadContentHQ)
        } else if(changed == lowerQualityMode){
            SettingValues.lqLow = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_lqLow)
        } else if(changed == dontLoadImagePreviews){
            SettingValues.noImages = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_noImg)
        }
        UserDefaults.standard.synchronize()
        doDisables()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label : UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        
        switch(section) {
        case 0: label.text  = ""
            break
        default: label.text  = ""
            break
        }
        return toReturn
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Data Saving"
        
        enableDataSaving = UISwitch()
        enableDataSaving.isOn = SettingValues.dataSavingEnabled
        enableDataSaving.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        enableDataSavingCell.textLabel?.text = "Data saving enabled"
        enableDataSavingCell.accessoryView = enableDataSaving
        enableDataSavingCell.backgroundColor = ColorUtil.foregroundColor
        enableDataSavingCell.textLabel?.textColor = ColorUtil.fontColor
        enableDataSavingCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        disableOnWifi = UISwitch()
        disableOnWifi.isOn = SettingValues.dataSavingDisableWiFi
        disableOnWifi.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        disableOnWifiCell.textLabel?.text = "Disable data saving on WiFi"
        disableOnWifiCell.accessoryView = disableOnWifi
        disableOnWifiCell.backgroundColor = ColorUtil.foregroundColor
        disableOnWifiCell.textLabel?.textColor = ColorUtil.fontColor
        disableOnWifiCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        loadHQViewer = UISwitch()
        loadHQViewer.isOn = SettingValues.loadContentHQ
        loadHQViewer.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        loadHQViewerCell.textLabel?.text = "Load HQ image when clicked"
        loadHQViewerCell.accessoryView = loadHQViewer
        loadHQViewerCell.backgroundColor = ColorUtil.foregroundColor
        loadHQViewerCell.textLabel?.textColor = ColorUtil.fontColor
        loadHQViewerCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        lowerQualityMode = UISwitch()
        lowerQualityMode.isOn = SettingValues.lqLow
        lowerQualityMode.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        lowerQualityModeCell.textLabel?.text = "Lowest quality images"
        lowerQualityModeCell.accessoryView = lowerQualityMode
        lowerQualityModeCell.backgroundColor = ColorUtil.foregroundColor
        lowerQualityModeCell.textLabel?.textColor = ColorUtil.fontColor
        lowerQualityModeCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        dontLoadImagePreviews = UISwitch()
        dontLoadImagePreviews.isOn = SettingValues.noImages
        dontLoadImagePreviews.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        dontLoadImagePreviewsCell.textLabel?.text = "Don't load images"
        dontLoadImagePreviewsCell.accessoryView = dontLoadImagePreviews
        dontLoadImagePreviewsCell.backgroundColor = ColorUtil.foregroundColor
        dontLoadImagePreviewsCell.textLabel?.textColor = ColorUtil.fontColor
        dontLoadImagePreviewsCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        doDisables()
        self.tableView.tableFooterView = UIView()
    }
    
    func doDisables(){
        if(SettingValues.dataSavingEnabled){
            disableOnWifi.isEnabled = true
            loadHQViewer.isEnabled = true
            lowerQualityMode.isEnabled = true
            dontLoadImagePreviews.isEnabled = false
        } else {
            loadHQViewer.isEnabled = false
            disableOnWifi.isEnabled = false
            loadHQViewer.isEnabled = false
            lowerQualityMode.isEnabled = false
            dontLoadImagePreviews.isEnabled = true
        }
        if(SettingValues.noImages){
            enableDataSaving.isEnabled = false
            dontLoadImagePreviews.isEnabled = true
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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
            case 0: return self.dontLoadImagePreviewsCell
            case 1: return self.enableDataSavingCell
            case 2: return self.disableOnWifiCell
            case 3: return self.loadHQViewerCell
            case 4: return self.lowerQualityModeCell
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return 5    // section 0 has 2 rows
        default: fatalError("Unknown number of sections")
        }
    }
    
    
}
