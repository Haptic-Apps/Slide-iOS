//
//  SettingsShortcutMenu.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/26/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SettingsShortcutMenu: BubbleSettingTableViewController {
    
    var all: [SettingValues.NavigationHeaderActions] = []
    var enabled: [SettingValues.NavigationHeaderActions] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headers = ["Active shortcuts", "Disabled shortcuts"]
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        self.tableView.isEditing = true
        self.tableView.backgroundColor = ColorUtil.theme.backgroundColor
        
        enabled.append(contentsOf: SettingValues.NavigationHeaderActions.getMenuNone())
        all.append(contentsOf: SettingValues.NavigationHeaderActions.cases.filter({ !enabled.contains($0) }))
        
        tableView.reloadData()
        
        self.tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        var saveArray = [String]()
        for item in enabled {
            saveArray.append(item.rawValue)
        }
        UserDefaults.standard.set(saveArray, forKey: "headerMenu")
        UserDefaults.standard.synchronize()
        if #available(iOS 13, *) {
            self.isModalInPresentation = false
        }
    }
    
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = ColorUtil.theme.foregroundColor
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
        c.backgroundColor = ColorUtil.theme.foregroundColor
        c.textLabel?.textColor = ColorUtil.theme.fontColor
        c.imageView?.image = thing.getImage()
        c.showsReorderControl = true
        
        return c
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove: SettingValues.NavigationHeaderActions = sourceIndexPath.section == 0 ? enabled[sourceIndexPath.row] : all[sourceIndexPath.row]
        
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
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
        self.title = "Arrange Shortcuts menu"
        if #available(iOS 13, *) {
            self.isModalInPresentation = true
        }
    }
}
