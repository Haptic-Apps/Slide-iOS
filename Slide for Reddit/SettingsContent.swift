//
//  SettingsContent.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/20/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class SettingsContent: UITableViewController {
    
    var showNSFWContentCell: UITableViewCell = UITableViewCell()
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
        if(changed == showNSFWContent){
            SettingValues.nsfwEnabled = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_nsfwEnabled)
        } else if(changed == showNSFWPreviews){
            SettingValues.nsfwPreviews = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_nsfwPreviews)
        } else if(changed == hideCollectionViews){
            SettingValues.hideNSFWCollection = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_hideNSFWCollection)
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
        self.tableView.separatorStyle = .none

        showNSFWContent = UISwitch()
        showNSFWContent.isOn = SettingValues.nsfwEnabled
        showNSFWContent.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        showNSFWContentCell.textLabel?.text = "I am 18 or older and willing to see adult content"
        showNSFWContentCell.accessoryView = showNSFWContent
        showNSFWContentCell.backgroundColor = ColorUtil.foregroundColor
        showNSFWContentCell.textLabel?.textColor = ColorUtil.fontColor
        showNSFWContentCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        showNSFWPreviews = UISwitch()
        showNSFWPreviews.isOn = SettingValues.nsfwPreviews
        showNSFWPreviews.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        showNSFWPreviewsCell.textLabel?.text = "Show NSFW image previews"
        showNSFWPreviewsCell.accessoryView = showNSFWPreviews
        showNSFWPreviewsCell.backgroundColor = ColorUtil.foregroundColor
        showNSFWPreviewsCell.textLabel?.textColor = ColorUtil.fontColor
        showNSFWPreviewsCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        hideCollectionViews = UISwitch()
        hideCollectionViews.isOn = SettingValues.hideNSFWCollection
        hideCollectionViews.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        hideCollectionViewsCell.textLabel?.text = "Hide NSFW image previews in collections (such as r/all)"
        hideCollectionViewsCell.accessoryView = hideCollectionViews
        hideCollectionViewsCell.backgroundColor = ColorUtil.foregroundColor
        hideCollectionViewsCell.textLabel?.textColor = ColorUtil.fontColor
        hideCollectionViewsCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        /*dontLoadImagePreviews = UISwitch()
        dontLoadImagePreviews.isOn = SettingValues.noImages
        dontLoadImagePreviews.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        dontLoadImagePreviewsCell.textLabel?.text = "Don't load images"
        dontLoadImagePreviewsCell.accessoryView = dontLoadImagePreviews
        dontLoadImagePreviewsCell.backgroundColor = ColorUtil.foregroundColor
        dontLoadImagePreviewsCell.textLabel?.textColor = ColorUtil.fontColor
        dontLoadImagePreviewsCell.selectionStyle = UITableViewCellSelectionStyle.none*/
        
        doDisables()
        self.tableView.tableFooterView = UIView()

    }
    
    func doDisables(){
        if(SettingValues.nsfwEnabled){
            showNSFWPreviews.isEnabled = true
            hideCollectionViews.isEnabled = true
            if(!SettingValues.nsfwPreviews){
                hideCollectionViews.isEnabled = false
            }
        } else {
            showNSFWPreviews.isEnabled = false
            hideCollectionViews.isEnabled = false
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
