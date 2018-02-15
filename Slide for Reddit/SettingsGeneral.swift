//
//  SettingsGeneral.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class SettingsGeneral: UITableViewController {
    
    var viewType: UITableViewCell = UITableViewCell()
    var hideFAB: UITableViewCell = UITableViewCell()
    var postSorting: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "post")
    var commentSorting: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "comment")
    var viewTypeSwitch = UISwitch()
    var hideFABSwitch = UISwitch()

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
        if(changed == viewTypeSwitch){
            SubredditReorderViewController.changed = true
            SettingValues.viewType = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_viewType)
        } else if(changed == hideFABSwitch){
            SettingValues.hiddenFAB = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_hiddenFAB)
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
        case 0: label.text  = "Display"
        break
        case 1: label.text  = "Sorting"
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
        self.title = "General"
        
        viewTypeSwitch = UISwitch()
        viewTypeSwitch.isOn = SettingValues.viewType
        viewTypeSwitch.addTarget(self, action: #selector(SettingsGeneral.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.viewType.textLabel?.text = "Subreddit tabs"
        self.viewType.accessoryView = viewTypeSwitch
        self.viewType.backgroundColor = ColorUtil.foregroundColor
        self.viewType.textLabel?.textColor = ColorUtil.fontColor
        viewType.selectionStyle = UITableViewCellSelectionStyle.none

        hideFABSwitch = UISwitch()
        hideFABSwitch.isOn = SettingValues.hiddenFAB
        hideFABSwitch.addTarget(self, action: #selector(SettingsGeneral.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.hideFAB.textLabel?.text = "Hide posts FAB"
        self.hideFAB.accessoryView = hideFABSwitch
        self.hideFAB.backgroundColor = ColorUtil.foregroundColor
        self.hideFAB.textLabel?.textColor = ColorUtil.fontColor
        hideFAB.selectionStyle = UITableViewCellSelectionStyle.none

        self.postSorting.textLabel?.text = "Default post sorting"
        self.postSorting.detailTextLabel?.text = SettingValues.defaultSorting.description
        self.postSorting.backgroundColor = ColorUtil.foregroundColor
        self.postSorting.textLabel?.textColor = ColorUtil.fontColor

        self.commentSorting.textLabel?.text = "Default comment sorting"
        self.commentSorting.detailTextLabel?.text = SettingValues.defaultCommentSorting.description
        self.commentSorting.backgroundColor = ColorUtil.foregroundColor
        self.commentSorting.textLabel?.textColor = ColorUtil.fontColor

        self.tableView.tableFooterView = UIView()
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
        switch(indexPath.section) {
        case 0:
            switch(indexPath.row) {
            case 0: return self.viewType
            case 1: return self.hideFAB
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch(indexPath.row) {
            case 0: return self.postSorting
            case 1: return self.commentSorting
            default: fatalError("Unknown row in section 1")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    func showTimeMenu(s: LinkSortType){
        if(s == .hot || s == .new){
            SettingValues.defaultSorting = s
            UserDefaults.standard.set(s.path, forKey: SettingValues.pref_defaultSorting)
            UserDefaults.standard.synchronize()
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Time Period", message: "", preferredStyle: .alert)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)
            
            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default)
                { action -> Void in
                    SettingValues.defaultSorting = s
                    UserDefaults.standard.set(s.path, forKey: SettingValues.pref_defaultSorting)
                    SettingValues.defaultTimePeriod = t
                    UserDefaults.standard.set(t.param, forKey: SettingValues.pref_defaultTimePeriod)
                    UserDefaults.standard.synchronize()
                }
                actionSheetController.addAction(saveActionButton)
            }
            
            self.present(actionSheetController, animated: true, completion: nil)
        }
    }
    
    var timeMenuView: UIView = UIView()

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.timeMenuView = self.tableView.cellForRow(at: indexPath)!.contentView

        if(indexPath.section == 1 && indexPath.row == 0){
            let actionSheetController: UIAlertController = UIAlertController(title: "Default post sorting", message: "", preferredStyle: .alert)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)
            for link in LinkSortType.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default)
                { action -> Void in
                    self.showTimeMenu(s: link)
                }
                actionSheetController.addAction(saveActionButton)
            }

            self.present(actionSheetController, animated: true, completion: nil)
        } else if(indexPath.section == 1 && indexPath.row == 1){
            let actionSheetController: UIAlertController = UIAlertController(title: "Default comment sorting", message: "", preferredStyle: .alert)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)
            
            for c in CommentSort.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: c.description, style: .default)
                { action -> Void in
                    SettingValues.defaultCommentSorting = c
                    UserDefaults.standard.set(c.type, forKey: SettingValues.pref_defaultCommentSorting)
                    UserDefaults.standard.synchronize()
                }
                actionSheetController.addAction(saveActionButton)
            }

            self.present(actionSheetController, animated: true, completion: nil)
        }

    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return 2    // section 0 has 2 rows
        case 1: return 2    // section 1 has 1 row
        default: fatalError("Unknown number of sections")
        }
    }
    
    
}
