//
//  SettingsComments.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/28/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class SettingsComments: UITableViewController {
    
    var disableNavigationBarCell: UITableViewCell = UITableViewCell()
    var disableNavigationBar = UISwitch()
    
    var disableColorCell: UITableViewCell = UITableViewCell()
    var disableColor = UISwitch()
    
    var collapseDefaultCell: UITableViewCell = UITableViewCell()
    var collapseDefault = UISwitch()
    
    var swapLongPressCell: UITableViewCell = UITableViewCell()
    var swapLongPress = UISwitch()
    
    var collapseFullyCell: UITableViewCell = UITableViewCell()
    var collapseFully = UISwitch()

    var highlightOpCell: UITableViewCell = UITableViewCell()
    var highlightOp = UISwitch()

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
        if(changed == disableNavigationBar){
            SettingValues.disableNavigationBar = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_disableNavigationBar)
        } else if(changed == disableColor){
            SettingValues.disableColor = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_disableColor)
        } else if(changed == collapseDefault){
            SettingValues.collapseDefault = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_collapseDefault)
        } else if(changed == swapLongPress){
            SettingValues.swapLongPress = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_swapLongPress)
        } else if(changed == collapseFully){
            SettingValues.collapseFully = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_collapseFully)
        } else if(changed == highlightOp){
            SettingValues.highlightOp = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_highlightOp)
        }
        UserDefaults.standard.synchronize()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label : UILabel = UILabel()
        label.textColor = ColorUtil.fontColor
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        
        switch(section) {
        case 0: label.text  = "Preview"
            break
        case 1: label.text  = "Display"
            break
        case 2: label.text = "Actionbar"
            break
        default: label.text  = ""
            break
        }
        return toReturn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Comments"
        
        disableNavigationBar = UISwitch()
        disableNavigationBar.isOn = SettingValues.disableNavigationBar
        disableNavigationBar.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        disableNavigationBarCell.textLabel?.text = "Disable comment navigation bar"
        disableNavigationBarCell.accessoryView = disableNavigationBar
        disableNavigationBarCell.backgroundColor = ColorUtil.foregroundColor
        disableNavigationBarCell.textLabel?.textColor = ColorUtil.fontColor
        disableNavigationBarCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        
        disableColor = UISwitch()
        disableColor.isOn = SettingValues.disableColor
        disableColor.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        disableColorCell.textLabel?.text = "Monochrome comment depth indicators"
        disableColorCell.accessoryView = disableColor
        disableColorCell.backgroundColor = ColorUtil.foregroundColor
        disableColorCell.textLabel?.textColor = ColorUtil.fontColor
        disableColorCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        collapseDefault = UISwitch()
        disableColor.isOn = SettingValues.collapseDefault
        collapseDefault.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        collapseDefaultCell.textLabel?.text = "Collapse all comments by default"
        collapseDefaultCell.accessoryView = collapseDefault
        collapseDefaultCell.backgroundColor = ColorUtil.foregroundColor
        collapseDefaultCell.textLabel?.textColor = ColorUtil.fontColor
        collapseDefaultCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        swapLongPress = UISwitch()
        swapLongPress.isOn = SettingValues.swapLongPress
        swapLongPress.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        swapLongPressCell.textLabel?.text = "Swap tap and long press actions"
        swapLongPressCell.accessoryView = swapLongPress
        swapLongPressCell.backgroundColor = ColorUtil.foregroundColor
        swapLongPressCell.textLabel?.textColor = ColorUtil.fontColor
        swapLongPressCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        collapseFully = UISwitch()
        collapseFully.isOn = SettingValues.collapseFully
        collapseFully.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        collapseFullyCell.textLabel?.text = "Collapse comments fully"
        collapseFullyCell.accessoryView = collapseFully
        collapseFullyCell.backgroundColor = ColorUtil.foregroundColor
        collapseFullyCell.textLabel?.textColor = ColorUtil.fontColor
        collapseFullyCell.selectionStyle = UITableViewCellSelectionStyle.none

        highlightOp = UISwitch()
        highlightOp.isOn = SettingValues.highlightOp
        highlightOp.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        highlightOpCell.textLabel?.text = "Highlight op replies of parent comments "
        highlightOpCell.accessoryView = highlightOp
        highlightOpCell.backgroundColor = ColorUtil.foregroundColor
        highlightOpCell.textLabel?.textColor = ColorUtil.fontColor
        highlightOpCell.selectionStyle = UITableViewCellSelectionStyle.none

        self.tableView.tableFooterView = UIView()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(section == 0){
            return 0
        }
        return 70
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
            case 0: return self.collapseDefaultCell
            case 1: return self.collapseFullyCell
            case 2: return self.disableColorCell
            case 3: return self.disableNavigationBarCell
            case 4: return self.swapLongPressCell
            case 5: return self.highlightOpCell
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return 6    // section 1 has 1 row
        default: fatalError("Unknown number of sections")
        }
    }
    
    
}
