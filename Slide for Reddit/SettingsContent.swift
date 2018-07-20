//
//  SettingsContent.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/20/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SettingsContent: UITableViewController {
    
    var showNSFWContentCell: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "nsfwcontent")
    var showNSFWContent = UISwitch()
    
    var showNSFWPreviewsCell: UITableViewCell = UITableViewCell()
    var showNSFWPreviews = UISwitch()

    var hideCollectionViewsCell: UITableViewCell = UITableViewCell()
    var hideCollectionViews = UISwitch()
    
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
        if(changed == showNSFWContent) {
            SettingValues.nsfwEnabled = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_nsfwEnabled)
        }
        else if(changed == showNSFWPreviews) {
            SettingValues.nsfwPreviews = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_nsfwPreviews)
        }
        else if(changed == hideCollectionViews) {
            SettingValues.hideNSFWCollection = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_hideNSFWCollection)
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
        toReturn.backgroundColor = ColorUtil.backgroundColor
        
        switch(section) {
        case 0: label.text = ""
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
        self.title = "Reddit Content"
        self.tableView.separatorStyle = .none

        createCell(showNSFWContentCell, showNSFWContent, isOn: SettingValues.nsfwEnabled, text: "I am 18 years old or older, and am willing to see adult content")
        self.showNSFWContentCell.detailTextLabel?.text = "Tap to change this at reddit.com under 'Content Options'"
        self.showNSFWContentCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.showNSFWContentCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.showNSFWContentCell.detailTextLabel?.numberOfLines = 0
        showNSFWContent.isEnabled = false
        
        createCell(showNSFWPreviewsCell, showNSFWPreviews, isOn: SettingValues.nsfwPreviews, text: "Show NSFW image previews")
        createCell(hideCollectionViewsCell, hideCollectionViews, isOn: SettingValues.hideNSFWCollection, text: "Hide NSFW image previews in collections (such as r/all)")

        doDisables()
        self.tableView.tableFooterView = UIView()

    }
    
    func doDisables() {
        if(SettingValues.nsfwEnabled) {
            showNSFWPreviews.isEnabled = true
            hideCollectionViews.isEnabled = true
            if(!SettingValues.nsfwPreviews) {
                hideCollectionViews.isEnabled = false
            }
        }
        else {
            showNSFWPreviews.isEnabled = false
            hideCollectionViews.isEnabled = false
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row == 0) {
            let url = URL.init(string: "https://www.reddit.com/prefs")!
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? 80 : 60
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch(indexPath.section) {
        case 0:
            switch(indexPath.row) {
            case 0: return self.showNSFWContentCell
            case 1: return self.showNSFWPreviewsCell
            case 2: return self.hideCollectionViewsCell
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return 3   // section 0 has 2 rows
        default: fatalError("Unknown number of sections")
        }
    }
}
