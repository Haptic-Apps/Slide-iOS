//
//  SettingsData.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/19/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SettingsData: BubbleSettingTableViewController {
    
    var enableDataSavingCell: UITableViewCell = InsetCell()
    var enableDataSaving = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var disableOnWifiCell: UITableViewCell = InsetCell()
    var disableOnWifi = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    //load hq always
    //LOwer quality mode
    //Dont show images
    var loadHQViewerCell: UITableViewCell = InsetCell()
    var loadHQViewer = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var lowerQualityModeCell: UITableViewCell = InsetCell()
    var lowerQualityMode = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var dontLoadImagePreviewsCell: UITableViewCell = InsetCell()
    var dontLoadImagePreviews = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var streamVideosCell: UITableViewCell = InsetCell()
    var streamVideos = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == enableDataSaving {
            SettingValues.dataSavingEnabled = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_dataSavingEnabled)
        } else if changed == disableOnWifi {
            SettingValues.dataSavingDisableWiFi = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_dataSavingDisableWifi)
        } else if changed == loadHQViewer {
            SettingValues.loadContentHQ = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_loadContentHQ)
        } else if changed == streamVideos {
            SettingValues.streamVideos = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_streamVideos)
        } else if changed == lowerQualityMode {
            SettingValues.lqLow = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_lqLow)
        } else if changed == dontLoadImagePreviews {
            SettingValues.noImages = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_noImg)
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
        case 0: label.text  = ""
        default: label.text  = ""
        }
        return toReturn
    }
    
    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = ColorUtil.theme.fontColor
        cell.backgroundColor = ColorUtil.theme.foregroundColor
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
        self.title = "Data settings"
        headers =  ["Data Saving"]

        createCell(enableDataSavingCell, enableDataSaving, isOn: SettingValues.dataSavingEnabled, text: "Enable Data Saving mode")
        createCell(disableOnWifiCell, disableOnWifi, isOn: !SettingValues.dataSavingDisableWiFi, text: "Data Saving mode on WiFi")
        createCell(loadHQViewerCell, loadHQViewer, isOn: SettingValues.loadContentHQ, text: "Load full-size images when opened")
        createCell(lowerQualityModeCell, lowerQualityMode, isOn: SettingValues.lqLow, text: "Load lowest image quality")
        createCell(dontLoadImagePreviewsCell, dontLoadImagePreviews, isOn: SettingValues.noImages, text: "Don't load banner images")
        self.dontLoadImagePreviewsCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.dontLoadImagePreviewsCell.detailTextLabel?.text = "While Data Saving mode is enabled"
        self.dontLoadImagePreviewsCell.detailTextLabel?.numberOfLines = 0
        createCell(streamVideosCell, streamVideos, isOn: SettingValues.streamVideos, text: "Stream videos")
        self.streamVideosCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.streamVideosCell.detailTextLabel?.text = "Disabling streaming will download videos before displaying them"
        self.streamVideosCell.detailTextLabel?.numberOfLines = 0

        doDisables()
        self.tableView.tableFooterView = UIView()
    }
    
    func doDisables() {
        if SettingValues.dataSavingEnabled {
            disableOnWifi.isEnabled = true
            loadHQViewer.isEnabled = true
            lowerQualityMode.isEnabled = true
            dontLoadImagePreviews.isEnabled = true
        } else {
            loadHQViewer.isEnabled = false
            disableOnWifi.isEnabled = false
            loadHQViewer.isEnabled = false
            lowerQualityMode.isEnabled = false
            dontLoadImagePreviews.isEnabled = false
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 2: return self.dontLoadImagePreviewsCell
            case 0: return self.enableDataSavingCell
            case 1: return self.disableOnWifiCell
            case 3: return self.loadHQViewerCell
            case 4: return self.lowerQualityModeCell
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4    // disable the last cell
        default: fatalError("Unknown number of sections")
        }
    }
    
}
