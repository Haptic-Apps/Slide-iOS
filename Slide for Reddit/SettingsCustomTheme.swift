//
//  SettingsCustomTheme.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import MKColorPicker
import RLBAlertsPickers
import UIKit

class SettingsCustomTheme: UITableViewController {
    
    var tochange: SettingsViewController?
    var foreground: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "foreground")
    var background: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "background")
    var font: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "font")
    var navicon: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "navicon")
    var statusbar: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "status")

    var applySwitch: UISwitch = UISwitch()
    var statusbarSwitch: UISwitch = UISwitch()

    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = ColorUtil.fontColor
        cell.backgroundColor = ColorUtil.foregroundColor
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if let s = switchV {
            s.isOn = isOn
            s.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
            cell.accessoryView = s
        }
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var doneOnce = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
        if doneOnce {
            self.loadView()
            self.tableView.reloadData(with: .automatic)
            self.tochange!.doCells()
            self.tochange!.tableView.reloadData()
        } else {
            doneOnce = true
        }
    }
    
    override func loadView() {
        super.loadView()
        setupBaseBarColors()
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Edit Custom Theme"
        self.tableView.separatorStyle = .none
        
        self.foreground.textLabel?.text = "Foreground color"
        self.foreground.accessoryType = .none
        self.foreground.backgroundColor = ColorUtil.Theme.CUSTOM.foregroundColor
        self.foreground.textLabel?.textColor = ColorUtil.Theme.CUSTOM.fontColor
        self.foreground.imageView?.image = UIImage.init(named: "dot")?.toolbarIcon().getCopy(withColor: ColorUtil.Theme.CUSTOM.navIconColor)
        
        self.background.textLabel?.text = "Background color"
        self.background.accessoryType = .none
        self.background.backgroundColor = ColorUtil.Theme.CUSTOM.foregroundColor
        self.background.textLabel?.textColor = ColorUtil.Theme.CUSTOM.fontColor
        self.background.imageView?.image = UIImage.init(named: "dot")?.toolbarIcon().getCopy(withColor: ColorUtil.Theme.CUSTOM.backgroundColor)

        self.font.textLabel?.text = "Font color"
        self.font.accessoryType = .none
        self.font.backgroundColor = ColorUtil.Theme.CUSTOM.foregroundColor
        self.font.textLabel?.textColor = ColorUtil.Theme.CUSTOM.fontColor
        self.font.imageView?.image = UIImage.init(named: "dot")?.toolbarIcon().getCopy(withColor: ColorUtil.Theme.CUSTOM.fontColor)

        self.navicon.textLabel?.text = "Icons color"
        self.navicon.accessoryType = .none
        self.navicon.backgroundColor = ColorUtil.Theme.CUSTOM.foregroundColor
        self.navicon.textLabel?.textColor = ColorUtil.Theme.CUSTOM.fontColor
        self.navicon.imageView?.image = UIImage.init(named: "dot")?.toolbarIcon().getCopy(withColor: ColorUtil.Theme.CUSTOM.navIconColor)

        self.statusbar.textLabel?.text = "Light statusbar"
        self.statusbar.accessoryType = .none
        self.statusbar.backgroundColor = ColorUtil.Theme.CUSTOM.foregroundColor
        self.statusbar.textLabel?.textColor = ColorUtil.Theme.CUSTOM.fontColor
        statusbarSwitch.addTarget(self, action: #selector(switchIsChanged(_:)), for: .valueChanged)
        self.statusbar.accessoryView = statusbarSwitch

        self.tableView.tableFooterView = UIView()
        
        if ColorUtil.theme != .CUSTOM {
            self.foreground.isUserInteractionEnabled = false
            self.background.isUserInteractionEnabled = false
            self.font.isUserInteractionEnabled = false
            self.navicon.isUserInteractionEnabled = false
            self.statusbar.isUserInteractionEnabled = false
            self.statusbarSwitch.isUserInteractionEnabled = false

            self.foreground.contentView.alpha = 0.5
            self.background.contentView.alpha = 0.5
            self.font.contentView.alpha = 0.5
            self.navicon.contentView.alpha = 0.5
            self.statusbar.contentView.alpha = 0.5
        } else {
            self.foreground.isUserInteractionEnabled = true
            self.background.isUserInteractionEnabled = true
            self.font.isUserInteractionEnabled = true
            self.navicon.isUserInteractionEnabled = true
            self.statusbar.isUserInteractionEnabled = true
            self.statusbarSwitch.isUserInteractionEnabled = true

            self.foreground.contentView.alpha = 1
            self.background.contentView.alpha = 1
            self.font.contentView.alpha = 1
            self.navicon.contentView.alpha = 1
            self.statusbar.contentView.alpha = 1
        }
        
        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.setImage(UIImage.init(named: "back")!.navIcon(), for: UIControl.State.normal)
        button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        
        let barButton = UIBarButtonItem.init(customView: button)
        
        navigationItem.leftBarButtonItem = barButton
        applySwitch.addTarget(self, action: #selector(switchIsChanged(_:)), for: .valueChanged)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: applySwitch)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight() && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }
    
    @objc public func handleBackButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == statusbarSwitch {
            UserDefaults.standard.set(changed.isOn, forKey: ColorUtil.CUSTOM_STATUSBAR)
        } else if changed == applySwitch {
            if ColorUtil.theme == .CUSTOM {
                UserDefaults.standard.set("light", forKey: "theme")
            } else {
                UserDefaults.standard.set("custom", forKey: "theme")
            }
            UserDefaults.standard.synchronize()
            _ = ColorUtil.doInit()
            SubredditReorderViewController.changed = true
            self.tableView.reloadData(with: .automatic)
            MainViewController.needsRestart = true
        }
        
        loadView()
        self.tableView.reloadData(with: .automatic)
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
    
    override func viewWillDisappear(_ animated: Bool) {
        SubredditReorderViewController.changed = true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.foreground
            case 1: return self.background
            case 2: return self.font
            case 3: return self.navicon
            case 4: return self.statusbar
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    func cleanup() {
        CachedTitle.titles.removeAll()
        LinkCellImageCache.initialize()
        SingleSubredditViewController.cellVersion += 1
        
        ColorUtil.foregroundColor = ColorUtil.theme.foregroundColor
        ColorUtil.backgroundColor = ColorUtil.theme.backgroundColor
        ColorUtil.fontColor = ColorUtil.theme.fontColor
        ColorUtil.navIconColor = ColorUtil.theme.navIconColor
        loadView()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            //foreground
            
            let alert = UIAlertController(style: .actionSheet)
            alert.addColorPicker(color: ColorUtil.Theme.CUSTOM.foregroundColor) { color in
                UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_FOREGROUND)
                UserDefaults.standard.synchronize()
                self.cleanup()
            }
            alert.addAction(title: "Set Foreground Color", style: .default)
            alert.addAction(title: "Cancel", style: .cancel)
            alert.show()
        } else if indexPath.row == 1 {
            //background
            
            let alert = UIAlertController(style: .actionSheet)
            alert.addColorPicker(color: ColorUtil.Theme.CUSTOM.backgroundColor) { color in
                UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_BACKGROUND)
                UserDefaults.standard.synchronize()
                self.cleanup()
            }
            alert.addAction(title: "Set Background Color", style: .default)
            alert.addAction(title: "Cancel", style: .cancel)
            alert.show()
        } else if indexPath.row == 2 {
            //font
            
            let alert = UIAlertController(style: .actionSheet)
            alert.addColorPicker(color: ColorUtil.Theme.CUSTOM.fontColor) { color in
                UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_FONT)
                UserDefaults.standard.synchronize()
                self.cleanup()
            }
            alert.addAction(title: "Set Font Color", style: .default)
            alert.addAction(title: "Cancel", style: .cancel)
            alert.show()
        } else if indexPath.row == 3 {
            //navicon
            
            let alert = UIAlertController(style: .actionSheet)
            alert.addColorPicker(color: ColorUtil.Theme.CUSTOM.navIconColor) { color in
                UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_NAVICON)
                UserDefaults.standard.synchronize()
                self.cleanup()
            }
            alert.addAction(title: "Set Icon Color", style: .default)
            alert.addAction(title: "Cancel", style: .cancel)
            alert.show()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 5
        default: fatalError("Unknown number of sections")
        }
    }

}
