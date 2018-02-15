//
//  SettingsTheme.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/21/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import MKColorPicker

class SettingsTheme: UITableViewController, ColorPickerViewDelegate {

    var tochange: SettingsViewController?
    var primary: UITableViewCell = UITableViewCell()
    var accent: UITableViewCell = UITableViewCell()
    var base: UITableViewCell = UITableViewCell()
    var night: UITableViewCell = UITableViewCell()
    var tintingMode: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "tintingMode")
    var tintOutside: UITableViewCell = UITableViewCell()
    var tintOutsideSwitch: UISwitch = UISwitch()
    var isAccent = false
    
    var accentChosen: UIColor?

    public func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        if(isAccent){
            accentChosen = colorPickerView.colors[indexPath.row]
        } else {
            self.navigationController?.navigationBar.barTintColor = colorPickerView.colors[indexPath.row]
        }
    }

    func pickTheme(){
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        isAccent = false
        let margin:CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColor()
        MKColorPicker.selectionStyle = .check
        MKColorPicker.scrollDirection = .vertical
        var index = 0
        let firstColor = ColorUtil.baseColor
        for i in 0...MKColorPicker.colors.count - 1 {
            if(MKColorPicker.colors[i].cgColor.__equalTo(firstColor.cgColor)){
                MKColorPicker.preselectedIndex = i
                break
            }
        }

        MKColorPicker.style = .circle

        alertController.view.addSubview(MKColorPicker)
        
        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: {(alert: UIAlertAction!) in
            UserDefaults.standard.setColor(color: (self.navigationController?.navigationBar.barTintColor)!, forKey: "basecolor")
            UserDefaults.standard.synchronize()
            ColorUtil.doInit()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction!) in
            self.navigationController?.navigationBar.barTintColor = ColorUtil.baseColor
        })
        
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)
        
        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = selectedTableView
            presenter.sourceRect = selectedTableView.bounds
        }

        present(alertController, animated: true, completion: nil)
    }
    
    func pickAccent(){
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin:CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColorAccent()
        MKColorPicker.selectionStyle = .check

        self.isAccent = true
        MKColorPicker.scrollDirection = .vertical
        var index = 0
        let firstColor = ColorUtil.baseColor
        for i in 0...MKColorPicker.colors.count - 1 {
            if(MKColorPicker.colors[i].cgColor.__equalTo(firstColor.cgColor)){
                MKColorPicker.preselectedIndex = i
                break
            }
        }

        MKColorPicker.style = .circle

        alertController.view.addSubview(MKColorPicker)
        
        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: {(alert: UIAlertAction!) in
            if(self.accentChosen != nil){
            UserDefaults.standard.setColor(color: self.accentChosen!, forKey: "accentcolor")
            UserDefaults.standard.synchronize()
            ColorUtil.doInit()
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction!) in
            self.accentChosen = nil
        })
        
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)
        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = selectedTableView
            presenter.sourceRect = selectedTableView.bounds
        }

        present(alertController, animated: true, completion: nil)
    }

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
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Edit theme"
        
        self.primary.textLabel?.text = "Primary color"
        self.primary.accessoryType = .none
        self.primary.backgroundColor = ColorUtil.foregroundColor
        self.primary.textLabel?.textColor = ColorUtil.fontColor
        self.primary.imageView?.image = UIImage.init(named: "palette")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.primary.imageView?.tintColor = ColorUtil.fontColor
        
        self.accent.textLabel?.text = "Accent color"
        self.accent.accessoryType = .none
        self.accent.backgroundColor = ColorUtil.foregroundColor
        self.accent.textLabel?.textColor = ColorUtil.fontColor
        self.accent.imageView?.image = UIImage.init(named: "accent")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.accent.imageView?.tintColor = ColorUtil.fontColor
        
        self.base.textLabel?.text = "Base theme"
        self.base.accessoryType = .none
        self.base.backgroundColor = ColorUtil.foregroundColor
        self.base.textLabel?.textColor = ColorUtil.fontColor
        self.base.imageView?.image = UIImage.init(named: "colors")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.base.imageView?.tintColor = ColorUtil.fontColor
        
        self.night.textLabel?.text = "Night theme"
        self.night.accessoryType = .none
        self.night.backgroundColor = ColorUtil.foregroundColor
        self.night.textLabel?.textColor = ColorUtil.fontColor
        self.night.imageView?.image = UIImage.init(named: "night")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.night.imageView?.tintColor = ColorUtil.fontColor
        
        
        tintOutsideSwitch = UISwitch()
        tintOutsideSwitch.isOn = SettingValues.onlyTintOutside
        tintOutsideSwitch.addTarget(self, action: #selector(SettingsTheme.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.tintOutside.textLabel?.text = "Only tint outside of subreddit"
        self.tintOutside.accessoryView = tintOutsideSwitch
        self.tintOutside.backgroundColor = ColorUtil.foregroundColor
        self.tintOutside.textLabel?.textColor = ColorUtil.fontColor
        tintOutside.selectionStyle = UITableViewCellSelectionStyle.none

        self.tintingMode.textLabel?.text = "Subreddit tinting mode"
        self.tintingMode.detailTextLabel?.text = SettingValues.tintingMode
        self.tintingMode.backgroundColor = ColorUtil.foregroundColor
        self.tintingMode.textLabel?.textColor = ColorUtil.fontColor
        self.tintingMode.detailTextLabel?.textColor = ColorUtil.fontColor

        self.tableView.tableFooterView = UIView()
    }
    
    func switchIsChanged(_ changed: UISwitch) {
        if(changed == tintOutsideSwitch){
            SettingValues.onlyTintOutside = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_onlyTintOutside)
        }
        UserDefaults.standard.synchronize()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        SubredditReorderViewController.changed = true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch(indexPath.section) {
        case 0:
            switch(indexPath.row) {
            case 0: return self.primary
            case 1: return self.accent
            case 2: return self.base
            case 3: return self.night
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch(indexPath.row) {
            case 0: return self.tintingMode
            case 1: return self.tintOutside
            default: fatalError("Unknown row in section 1")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    var selectedTableView = UIView()
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTableView = tableView.cellForRow(at: indexPath)!.contentView
        tableView.deselectRow(at: indexPath, animated: true)
    if(indexPath.section == 0 && indexPath.row == 0){
            pickTheme()
        } else  if(indexPath.section == 0 && indexPath.row == 1){
            pickAccent()
        } else if(indexPath.section == 0 && indexPath.row == 2){
            showBaseTheme()
        } else if(indexPath.section == 1 && indexPath.row == 0){
            //tintmode
        }
    }
    
    func showBaseTheme(){
        let actionSheetController: UIAlertController = UIAlertController(title: "Select a base theme", message: "", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        for theme in ColorUtil.Theme.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: theme.rawValue , style: .default)
            { action -> Void in
                UserDefaults.standard.set(theme.rawValue, forKey: "theme")
                UserDefaults.standard.synchronize()
                ColorUtil.doInit()
                self.loadView()
                self.tableView.reloadData(with: .automatic)
                self.tochange!.doCells()
                self.tochange!.tableView.reloadData()
            }
            actionSheetController.addAction(saveActionButton)
        }
        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = selectedTableView
            presenter.sourceRect = selectedTableView.bounds
        }

        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label : UILabel = UILabel()
        label.textColor = ColorUtil.fontColor
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        
        switch(section) {
        case 0: label.text = "App theme"
            break
        case 1: label.text =  "Tinting"
            break
        default: label.text  = ""
            break
        }
        return toReturn
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return 4    // section 0 has 2 rows
        case 1: return 2    // section 1 has 1 row
        default: fatalError("Unknown number of sections")
        }
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
