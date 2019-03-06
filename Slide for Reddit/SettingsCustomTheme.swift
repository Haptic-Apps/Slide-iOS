//
//  SettingsCustomTheme.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import MKColorPicker
import RLBAlertsPickers
import UIKit
import SDCAlertView

class SettingsCustomTheme: UITableViewController {
    
    var tochange: SettingsViewController?
    var foreground: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "foreground")
    var background: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "background")
    var font: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "font")
    var navicon: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "navicon")
    var statusbar: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "status")

    var applySwitch: UISwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var statusbarSwitch: UISwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

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
    
    var defaultButton: UIBarButtonItem?
    override func loadView() {
        super.loadView()
        setupBaseBarColors()
        
        self.view.backgroundColor = ColorUtil.Theme.CUSTOM.backgroundColor
        // set the title
        self.title = "Edit Custom Theme"
        self.tableView.separatorStyle = .none
        
        self.foreground.textLabel?.text = "Foreground color"
        self.foreground.accessoryType = .none
        self.foreground.backgroundColor = ColorUtil.Theme.CUSTOM.foregroundColor
        self.foreground.textLabel?.textColor = ColorUtil.Theme.CUSTOM.fontColor
        self.foreground.imageView?.image = UIImage.init(named: "circle")?.toolbarIcon().getCopy(withColor: ColorUtil.Theme.CUSTOM.foregroundColor)
        self.foreground.imageView?.layer.masksToBounds = true
        self.foreground.imageView?.layer.borderWidth = 1.5
        self.foreground.imageView?.layer.borderColor = UIColor.white.cgColor
        self.foreground.imageView?.layer.cornerRadius = self.foreground.imageView!.bounds.width / 2

        self.background.textLabel?.text = "Background color"
        self.background.accessoryType = .none
        self.background.backgroundColor = ColorUtil.Theme.CUSTOM.foregroundColor
        self.background.textLabel?.textColor = ColorUtil.Theme.CUSTOM.fontColor
        self.background.imageView?.image = UIImage.init(named: "circle")?.toolbarIcon().getCopy(withColor: ColorUtil.Theme.CUSTOM.backgroundColor)

        self.font.textLabel?.text = "Font color"
        self.font.accessoryType = .none
        self.font.backgroundColor = ColorUtil.Theme.CUSTOM.foregroundColor
        self.font.textLabel?.textColor = ColorUtil.Theme.CUSTOM.fontColor
        self.font.imageView?.image = UIImage.init(named: "circle")?.toolbarIcon().getCopy(withColor: ColorUtil.Theme.CUSTOM.fontColor)

        self.navicon.textLabel?.text = "Icons color"
        self.navicon.accessoryType = .none
        self.navicon.backgroundColor = ColorUtil.Theme.CUSTOM.foregroundColor
        self.navicon.textLabel?.textColor = ColorUtil.Theme.CUSTOM.fontColor
        self.navicon.imageView?.image = UIImage.init(named: "circle")?.toolbarIcon().getCopy(withColor: ColorUtil.Theme.CUSTOM.navIconColor)

        self.statusbar.textLabel?.text = "Light statusbar"
        self.statusbar.accessoryType = .none
        self.statusbar.backgroundColor = ColorUtil.Theme.CUSTOM.foregroundColor
        self.statusbar.textLabel?.textColor = ColorUtil.Theme.CUSTOM.fontColor
        statusbarSwitch.addTarget(self, action: #selector(switchIsChanged(_:)), for: .valueChanged)
        statusbarSwitch.isOn = UserDefaults.standard.bool(forKey: ColorUtil.CUSTOM_STATUSBAR)
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
        
        let defaultb = UIButtonWithContext.init(type: .custom)
        defaultb.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        defaultb.setImage(UIImage.init(named: "sync")!.navIcon(), for: UIControl.State.normal)
        defaultb.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        defaultb.addTarget(self, action: #selector(reset), for: .touchUpInside)
        
        defaultButton = UIBarButtonItem.init(customView: defaultb)

        navigationItem.leftBarButtonItem = barButton
        applySwitch.isOn = ColorUtil.theme == .CUSTOM
        applySwitch.addTarget(self, action: #selector(switchIsChanged(_:)), for: .valueChanged)
        applySwitch.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)

        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: applySwitch), defaultButton!]
    }
    
    @objc func reset() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Select a base theme", message: "Will overwrite your current custom settings", preferredStyle: .actionSheet)
        
        actionSheetController.addCancelButton()
        
        for theme in ColorUtil.Theme.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: theme.displayName, style: .default) { _ -> Void in
                UserDefaults.standard.setColor(color: theme.foregroundColor, forKey: ColorUtil.CUSTOM_FOREGROUND)
                UserDefaults.standard.setColor(color: theme.backgroundColor, forKey: ColorUtil.CUSTOM_BACKGROUND)
                UserDefaults.standard.setColor(color: theme.fontColor, forKey: ColorUtil.CUSTOM_FONT)
                UserDefaults.standard.setColor(color: theme.navIconColor, forKey: ColorUtil.CUSTOM_NAVICON)
                UserDefaults.standard.set(!theme.isLight(), forKey: ColorUtil.CUSTOM_STATUSBAR)
                self.cleanup()
            }
            actionSheetController.addAction(saveActionButton)
        }
        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = defaultButton!.customView!
            presenter.sourceRect = defaultButton!.customView!.bounds
        }
        
        self.present(actionSheetController, animated: true, completion: nil)

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
        
        cleanup()
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
    
    var tagText: String?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 4 {
            return
        }
        let alert = AlertController(title: "", message: "", preferredStyle: .alert)
        var color: UIColor
        switch indexPath.row {
        case 0:
            color = ColorUtil.Theme.CUSTOM.foregroundColor
            alert.attributedMessage = NSAttributedString(string:  "Foreground color", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: ColorUtil.fontColor])
        case 1:
            color = ColorUtil.Theme.CUSTOM.backgroundColor
            alert.attributedMessage = NSAttributedString(string:  "Background color", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: ColorUtil.fontColor])
        case 2:
            color = ColorUtil.Theme.CUSTOM.fontColor
            alert.attributedMessage = NSAttributedString(string:  "Font color", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: ColorUtil.fontColor])
        default:
            color = ColorUtil.Theme.CUSTOM.navIconColor
            alert.attributedMessage = NSAttributedString(string:  "Icons color", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: ColorUtil.fontColor])
        }

        let selection: ColorPickerViewController.Selection? = { color in
            switch indexPath.row {
            case 0:
                UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_FOREGROUND)
            case 1:
                UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_BACKGROUND)
            case 2:
                UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_FONT)
            default:
                UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_NAVICON)
            }
            UserDefaults.standard.synchronize()
            self.cleanup()
        }
        
        let buttonSelection = AlertAction(title: "Save", style: .normal) { _ in
            selection?(color)
        }
        
        buttonSelection.isEnabled = true
        alert.addAction(buttonSelection)
        
        let hexSelection = AlertAction(title: "Enter HEX code", style: .normal) { _ in
            alert.dismiss()
            let alert = AlertController(title: "", message: nil, preferredStyle: .alert)
            let confirmAction = AlertAction(title: "Set", style: .preferred) { (_) in
                if let text = self.tagText {
                    let color = UIColor(hexString: text)
                    switch indexPath.row {
                    case 0:
                        UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_FOREGROUND)
                    case 1:
                        UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_BACKGROUND)
                    case 2:
                        UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_FONT)
                    default:
                        UserDefaults.standard.setColor(color: color, forKey: ColorUtil.CUSTOM_NAVICON)
                    }
                    UserDefaults.standard.synchronize()
                    self.cleanup()
                } else {
                }
            }
            
            let config: TextField.Config = { textField in
                textField.becomeFirstResponder()
                textField.textColor = ColorUtil.fontColor
                textField.attributedPlaceholder = NSAttributedString(string: "HEX String", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.fontColor.withAlphaComponent(0.3)])
                textField.left(image: UIImage.init(named: "pallete"), color: ColorUtil.fontColor)
                textField.layer.borderColor = ColorUtil.fontColor.withAlphaComponent(0.3) .cgColor
                textField.backgroundColor = ColorUtil.foregroundColor
                textField.leftViewPadding = 12
                textField.layer.borderWidth = 1
                textField.layer.cornerRadius = 8
                textField.keyboardAppearance = .default
                textField.keyboardType = .default
                textField.returnKeyType = .done
                textField.text = color.hexString()
                textField.action { textField in
                    self.tagText = textField.text
                }
            }
            
            let textField = OneTextFieldViewController(vInset: 12, configuration: config).view!
            
            alert.setupTheme()
            
            alert.attributedTitle = NSAttributedString(string: "Enter HEX color code", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.fontColor])
            
            alert.contentView.addSubview(textField)
            
            textField.edgeAnchors == alert.contentView.edgeAnchors
            textField.heightAnchor == CGFloat(44 + 12)
            
            alert.addAction(confirmAction)
            alert.addCancelButton()
            
            alert.addBlurView()
            self.present(alert, animated: true, completion: nil)
        }
        
        alert.addAction(hexSelection)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ColorPicker") as? ColorPickerViewController else { return }
        
        alert.addChild(vc)
        let vcv = vc.view!
        
        let view = UIView()
        alert.contentView.addSubview(view)
        view.edgeAnchors == alert.contentView.edgeAnchors
        view.heightAnchor == 400

        vcv.isUserInteractionEnabled = true
        vcv.backgroundColor = UIColor.clear
        
        alert.setupTheme()
        
        alert.attributedTitle = NSAttributedString(string:  color.hexString(), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.fontColor])
        
        vc.set(color: color) { new in
            color = new
            alert.attributedTitle = NSAttributedString(string:  color.hexString(), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.fontColor])
        }
        
        alert.addCancelButton()
        
        alert.addBlurView()
        
        self.present(alert, animated: true) {
        }
        alert.view!.addSubview(vcv)
        vc.didMove(toParent: alert)
        vcv.horizontalAnchors == alert.contentView.superview!.horizontalAnchors
        vcv.topAnchor == alert.contentView.superview!.topAnchor + 70
        vcv.bottomAnchor == alert.contentView.superview!.bottomAnchor
        vcv.heightAnchor == 400
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 5
        default: fatalError("Unknown number of sections")
        }
    }

}
