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
    
    var foreground: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "foreground")
    var background: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "background")
    var font: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "font")
    var navicon: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "navicon")
    var statusbar: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "status")
    
    var inputTheme = ""
    var isCurrentTheme = false
    var foregroundColor = UIColor.white
    var backgroundColor = UIColor.white
    var fontColor = UIColor.black.withAlphaComponent(0.85)
    var navIconColor = UIColor.black.withAlphaComponent(0.85)
    var statusbarEnabled = true

    var statusbarSwitch: UISwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = ColorUtil.theme.fontColor
        cell.backgroundColor = ColorUtil.theme.foregroundColor
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if let s = switchV {
            s.isOn = isOn
            s.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
            cell.accessoryView = s
        }
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
    }
    
    override func setupBaseBarColors(_ overrideColor: UIColor? = nil) {
        navigationController?.navigationBar.barTintColor = SettingValues.reduceColor ? backgroundColor : UserDefaults.standard.colorForKey(key: "color+") ?? ColorUtil.baseColor
        
        navigationController?.navigationBar.tintColor = SettingValues.reduceColor ? fontColor : UIColor.white
        let textAttributes = [NSAttributedString.Key.foregroundColor: SettingValues.reduceColor ? fontColor : .white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    override func viewDidLoad() {
        self.title = "Edit Custom Theme"
        if !inputTheme.isEmpty() {
            let colors = UserDefaults.standard.string(forKey: "Theme+" + inputTheme)?.removingPercentEncoding ?? UserDefaults.standard.string(forKey: "Theme+" + inputTheme) ?? ""
            if !colors.isEmpty {
                let split = colors.split("#")
                foregroundColor = UIColor(hex: split[2])
                backgroundColor = UIColor(hex: split[3])
                fontColor = UIColor(hex: split[4])
                navIconColor = UIColor(hex: split[5])
                statusbarEnabled = Bool(split[8])!
                isCurrentTheme = foregroundColor.hexString() == ColorUtil.theme.foregroundColor.hexString() && backgroundColor.hexString() == ColorUtil.theme.backgroundColor.hexString() && fontColor.hexString() == ColorUtil.theme.fontColor.hexString() && navIconColor.hexString() == ColorUtil.theme.navIconColor.hexString()
                self.title = split[1].removingPercentEncoding!.replacingOccurrences(of: "<H>", with: "#")
                self.setupViews()
                setupBaseBarColors()
            }
        }
        
        super.viewDidLoad()
    }
    
    var doneOnce = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }
    
    var themeText: String?
    
    @objc public func save() {
        if inputTheme.isEmpty {
            let alert = AlertController(title: "Save theme?", message: "", preferredStyle: .alert)
            
            let date = Date()
            let calender = Calendar.current
            let components = calender.dateComponents([.year, .month, .day], from: date)
            
            let year = components.year
            let month = components.month
            let day = components.day
            
            let today_string = String(year!) + "-" + String(month!) + "-" + String(day!)
            
            let config: TextField.Config = { textField in
                textField.becomeFirstResponder()
                textField.textColor = ColorUtil.theme.fontColor
                textField.attributedPlaceholder = NSAttributedString(string: "Theme name...", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor.withAlphaComponent(0.3)])
                textField.layer.borderColor = ColorUtil.theme.fontColor.withAlphaComponent(0.3) .cgColor
                textField.backgroundColor = ColorUtil.theme.foregroundColor
                textField.layer.borderWidth = 1
                textField.autocorrectionType = UITextAutocorrectionType.no
                textField.keyboardAppearance = .default
                textField.keyboardType = .default
                textField.returnKeyType = .done
                textField.text = today_string
                textField.action { textField in
                    self.themeText = textField.text
                }
            }
            
            let textField = OneTextFieldViewController(vInset: 12, configuration: config).view!
            
            alert.setupTheme()
            
            alert.attributedTitle = NSAttributedString(string: "Save theme?", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
            
            alert.contentView.addSubview(textField)
            
            textField.edgeAnchors == alert.contentView.edgeAnchors
            textField.heightAnchor == CGFloat(44 + 12)
            let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
            let blurView = UIVisualEffectView(frame: UIScreen.main.bounds)
            blurEffect.setValue(8, forKeyPath: "blurRadius")
            blurView.effect = blurEffect
            
            alert.addAction(AlertAction(title: "Save", style: .preferred, handler: { (_) in
                var colorString = "slide://colors"
                colorString += ("#" + (self.themeText?.replacingOccurrences(of: "#", with: "<H>") ?? today_string)).addPercentEncoding
                
                colorString += (self.foregroundColor.toHexString() + self.backgroundColor.toHexString() + self.fontColor.toHexString() + self.navIconColor.toHexString() + ColorUtil.baseColor.toHexString() + ColorUtil.baseAccent.toHexString() + "#" + String(self.statusbarEnabled)).addPercentEncoding
                UserDefaults.standard.set(colorString, forKey: "Theme+" + (self.themeText ?? today_string).replacingOccurrences(of: "#", with: "<H>").addPercentEncoding)
                UserDefaults.standard.synchronize()
                SettingsTheme.needsRestart = true
                self.dismiss(animated: true, completion: nil)
            }))
            
            alert.addAction(AlertAction(title: "Discard", style: .destructive, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
            
            alert.addCancelButton()
            alert.addBlurView()
            
            self.present(alert, animated: true, completion: nil)
        } else {
            var colorString = "slide://colors"
            colorString += ("#" + self.title!).addPercentEncoding
            
            colorString += (self.foregroundColor.toHexString() + self.backgroundColor.toHexString() + self.fontColor.toHexString() + self.navIconColor.toHexString() + ColorUtil.baseColor.toHexString() + ColorUtil.baseAccent.toHexString() + "#" + String(self.statusbarEnabled)).addPercentEncoding
            UserDefaults.standard.set(colorString, forKey: "Theme+" + inputTheme)
            UserDefaults.standard.synchronize()
            if isCurrentTheme {
                _ = ColorUtil.doInit()
                MainViewController.needsReTheme = true
            }
            SettingsTheme.needsRestart = true
            self.dismiss(animated: true, completion: nil)
        }
    }

    var defaultButton: UIBarButtonItem?
    override func loadView() {
        super.loadView()
        setupViews()
    }
    
    func setupViews() {
        setupBaseBarColors()
        
        self.view.backgroundColor = backgroundColor
        // set the title
        self.tableView.separatorStyle = .none
        
        self.foreground.textLabel?.text = "Foreground color"
        self.foreground.accessoryType = .none
        self.foreground.backgroundColor = foregroundColor
        self.foreground.textLabel?.textColor = fontColor
        self.foreground.imageView?.image = UIImage(named: "circle")?.toolbarIcon().getCopy(withColor: foregroundColor)
        self.foreground.imageView?.layer.masksToBounds = true
        self.foreground.imageView?.layer.borderWidth = 1.5
        self.foreground.imageView?.layer.borderColor = UIColor.white.cgColor
        self.foreground.imageView?.layer.cornerRadius = self.foreground.imageView!.bounds.width / 2
        
        self.background.textLabel?.text = "Background color"
        self.background.accessoryType = .none
        self.background.backgroundColor = foregroundColor
        self.background.textLabel?.textColor = fontColor
        self.background.imageView?.image = UIImage(named: "circle")?.toolbarIcon().getCopy(withColor: backgroundColor)
        
        self.font.textLabel?.text = "Font color"
        self.font.accessoryType = .none
        self.font.backgroundColor = foregroundColor
        self.font.textLabel?.textColor = fontColor
        self.font.imageView?.image = UIImage(named: "circle")?.toolbarIcon().getCopy(withColor: fontColor)
        
        self.navicon.textLabel?.text = "Icons color"
        self.navicon.accessoryType = .none
        self.navicon.backgroundColor = foregroundColor
        self.navicon.textLabel?.textColor = fontColor
        self.navicon.imageView?.image = UIImage(named: "circle")?.toolbarIcon().getCopy(withColor: navIconColor)
        
        self.statusbar.textLabel?.text = "Light statusbar"
        self.statusbar.accessoryType = .none
        self.statusbar.backgroundColor = foregroundColor
        self.statusbar.textLabel?.textColor = fontColor
        statusbarSwitch.addTarget(self, action: #selector(switchIsChanged(_:)), for: .valueChanged)
        statusbarSwitch.isOn = !statusbarEnabled
        self.statusbar.accessoryView = statusbarSwitch
        
        self.tableView.tableFooterView = UIView()
        
        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.setImage(UIImage(sfString: SFSymbol.xmark, overrideString: "close")!.navIcon(), for: UIControl.State.normal)
        button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        
        let barButton = UIBarButtonItem.init(customView: button)
        navigationItem.leftBarButtonItem = barButton

    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if statusbarEnabled && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }
    
    @objc public func handleBackButton() {
        save()
    }
    
    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == statusbarSwitch {
            statusbarEnabled = !changed.isOn
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
        loadView()
    }
    
    var tagText: String?
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ColorUtil.initializeThemes()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 4 {
            return
        }
        let alert = AlertController(title: "", message: "", preferredStyle: .alert)
        var color: UIColor
        switch indexPath.row {
        case 0:
            color = foregroundColor
            alert.attributedMessage = NSAttributedString(string:  "Foreground color", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        case 1:
            color = backgroundColor
            alert.attributedMessage = NSAttributedString(string:  "Background color", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        case 2:
            color = fontColor
            alert.attributedMessage = NSAttributedString(string:  "Font color", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        default:
            color = navIconColor
            alert.attributedMessage = NSAttributedString(string:  "Icons color", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        }

        let selection: ColorPickerViewController.Selection? = { color in
            switch indexPath.row {
            case 0:
                self.foregroundColor = color
            case 1:
                self.backgroundColor = color
            case 2:
                self.fontColor = color
            default:
                self.navIconColor = color
            }
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
                        self.foregroundColor = color
                    case 1:
                        self.backgroundColor = color
                    case 2:
                        self.fontColor = color
                    default:
                        self.navIconColor = color
                    }
                    self.cleanup()
                } else {
                }
            }
            
            let config: TextField.Config = { textField in
                textField.becomeFirstResponder()
                textField.textColor = ColorUtil.theme.fontColor
                textField.attributedPlaceholder = NSAttributedString(string: "HEX String", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor.withAlphaComponent(0.3)])
                textField.left(image: UIImage(named: "pallete"), color: ColorUtil.theme.fontColor)
                textField.layer.borderColor = ColorUtil.theme.fontColor.withAlphaComponent(0.3) .cgColor
                textField.backgroundColor = ColorUtil.theme.foregroundColor
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
            
            alert.attributedTitle = NSAttributedString(string: "Enter HEX color code", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
            
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
        
        alert.attributedTitle = NSAttributedString(string:  color.hexString(), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        vc.set(color: color) { new in
            color = new
            alert.attributedTitle = NSAttributedString(string:  color.hexString(), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
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
