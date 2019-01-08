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
        setupBaseBarColors()
    }
    
    func switchIsChanged(_ changed: UISwitch) {
        if changed == showNSFWPreviews {
            SettingValues.nsfwPreviews = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_nsfwPreviews + AccountController.currentName)
        } else if changed == hideCollectionViews {
            SettingValues.hideNSFWCollection = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_hideNSFWCollection + AccountController.currentName)
        }
        UserDefaults.standard.synchronize()
        doDisables()
        tableView.reloadData()
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
        
        createCell(showNSFWPreviewsCell, showNSFWPreviews, isOn: SettingValues.nsfwPreviews, text: "Show NSFW image previews")
        createCell(hideCollectionViewsCell, hideCollectionViews, isOn: SettingValues.hideNSFWCollection, text: "Hide NSFW image previews in collections (such as r/all)")

        doDisables()
        self.tableView.tableFooterView = UIView()

    }
    
    func doDisables() {
        if SettingValues.nsfwEnabled {
            showNSFWPreviews.isEnabled = true
            hideCollectionViews.isEnabled = true
            if !SettingValues.nsfwPreviews {
                hideCollectionViews.isEnabled = false
            }
        } else {
            showNSFWPreviews.isEnabled = false
            hideCollectionViews.isEnabled = false
        }
    }

}

extension SettingsContent {
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
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.showNSFWPreviewsCell
            case 1: return self.hideCollectionViewsCell
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2   // section 0 has 2 rows
        default: fatalError("Unknown number of sections")
        }
    }
}
