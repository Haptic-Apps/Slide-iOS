//
//  SettingsPostMenu.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 2/24/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SettingsPostMenu: UITableViewController {
    
    var all: [SettingValues.PostOverflowAction] = []
    var enabled: [SettingValues.PostOverflowAction] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight() && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        self.tableView.isEditing = true
        self.tableView.backgroundColor = ColorUtil.backgroundColor
        
        enabled.append(contentsOf: SettingValues.PostOverflowAction.getMenuNone())
        all.append(contentsOf: SettingValues.PostOverflowAction.cases.filter({ !enabled.contains($0) }))
        
        tableView.reloadData()
        
        self.tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        var saveArray = [String]()
        for item in enabled {
            saveArray.append(item.rawValue)
        }
        UserDefaults.standard.set(saveArray, forKey: "postMenu")
        UserDefaults.standard.synchronize()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = ColorUtil.foregroundColor
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? enabled.count : all.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thing = indexPath.section == 0 ? self.enabled[indexPath.row] : all[indexPath.row]
        
        let c = UITableViewCell(style: .default, reuseIdentifier: nil)
        c.textLabel?.text = thing.getTitle()
        c.backgroundColor = ColorUtil.foregroundColor
        c.textLabel?.textColor = ColorUtil.fontColor
        c.imageView?.image = thing.getImage()
        c.showsReorderControl = true
        
        return c
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove: SettingValues.PostOverflowAction = sourceIndexPath.section == 0 ? enabled[sourceIndexPath.row] : all[sourceIndexPath.row]
        
        if sourceIndexPath.section == 0 && destinationIndexPath.section == 0 {
            enabled.remove(at: sourceIndexPath.row)
            enabled.insert(itemToMove, at: destinationIndexPath.row)
        } else if sourceIndexPath.section == 0 && destinationIndexPath.section == 1 {
            enabled.remove(at: sourceIndexPath.row)
            all.insert(itemToMove, at: destinationIndexPath.row)
        } else if sourceIndexPath.section == 1 && destinationIndexPath.section == 0 {
            all.remove(at: sourceIndexPath.row)
            enabled.insert(itemToMove, at: destinationIndexPath.row)
        } else {
            all.remove(at: sourceIndexPath.row)
            all.insert(itemToMove, at: destinationIndexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        switch section {
        case 0: label.text = "Active actions"
        case 1: label.text =  "Disabled actions"
        default: label.text  = ""
        }
        return toReturn
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.separatorStyle = .none
        setupBaseBarColors()
        self.title = "Arrange post menu"
    }
}
