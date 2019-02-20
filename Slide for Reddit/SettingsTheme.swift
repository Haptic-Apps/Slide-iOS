//
//  SettingsTheme.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/21/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import MKColorPicker
import RLBAlertsPickers
import UIKit

class SettingsTheme: MediaTableViewController, ColorPickerViewDelegate {

    var tochange: SettingsViewController?
    var primary: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "primary")
    var accent: UITableViewCell = UITableViewCell()
    var base: UITableViewCell = UITableViewCell()
    var night: UITableViewCell = UITableViewCell()
    var tintingMode: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "tintingMode")
    var tintOutside: UITableViewCell = UITableViewCell()
    var tintOutsideSwitch: UISwitch = UISwitch()
    var custom: UITableViewCell = UITableViewCell()

    var shareButton = UIBarButtonItem.init()

    var reduceColorCell: UITableViewCell = UITableViewCell()
    var reduceColor: UISwitch = UISwitch()

    var isAccent = false
    
    var titleLabel = UILabel()

    var accentChosen: UIColor?
    var primaryChosen: UIColor?
    
    var customThemes: [String] {
        return UserDefaults.standard.dictionaryRepresentation().keys.filter({$0.startsWith("Theme+")})
    }

    public func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        if isAccent {
            accentChosen = colorPickerView.colors[indexPath.row]
            titleLabel.textColor = self.accentChosen
            self.accent.imageView?.image = UIImage.init(named: "circle")?.toolbarIcon().getCopy(withColor: accentChosen!)
            reduceColor.onTintColor = accentChosen!
        } else {
            primaryChosen = colorPickerView.colors[indexPath.row]
            setupBaseBarColors(primaryChosen)
            self.primary.imageView?.image = UIImage.init(named: "circle")?.toolbarIcon().getCopy(withColor: primaryChosen!)
        }
    }

    func pickTheme() {
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        isAccent = false
        let margin: CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 314 - margin * 4.0: alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColor()
        MKColorPicker.selectionStyle = .check
        MKColorPicker.scrollDirection = .vertical
        let firstColor = ColorUtil.baseColor
        for i in 0 ..< MKColorPicker.colors.count {
            if MKColorPicker.colors[i].cgColor.__equalTo(firstColor.cgColor) {
                MKColorPicker.preselectedIndex = i
                break
            }
        }

        MKColorPicker.style = .circle

        alertController.view.addSubview(MKColorPicker)

        /*todo maybe ? let custom = UIAlertAction(title: "Custom color", style: .default, handler: { (alert: UIAlertAction!) in
            if(!VCPresenter.proDialogShown(feature: false, self)){
                let alert = UIAlertController.init(title: "Choose a color", message: nil, preferredStyle: .actionSheet)
                alert.addColorPicker(color: (self.navigationController?.navigationBar.barTintColor)!, selection: { (color) in
                    UserDefaults.standard.setColor(color: (self.navigationController?.navigationBar.barTintColor)!, forKey: "basecolor")
                    UserDefaults.standard.synchronize()
                    ColorUtil.doInit()
                })
                alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
                    self.pickTheme()
                }))
                self.present(alert, animated: true)
            }
        })*/

        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: { (_: UIAlertAction!) in
            if self.primaryChosen != nil {
                UserDefaults.standard.setColor(color: self.primaryChosen!, forKey: "basecolor")
                UserDefaults.standard.synchronize()
            }

            UserDefaults.standard.setColor(color: (self.navigationController?.navigationBar.barTintColor)!, forKey: "basecolor")
            UserDefaults.standard.synchronize()
            _ = ColorUtil.doInit()
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_: UIAlertAction!) in
            self.setupBaseBarColors()
            self.primary.imageView?.image = UIImage.init(named: "circle")?.toolbarIcon().getCopy(withColor: ColorUtil.baseColor)
        })

        //alertController.addAction(custom)
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
        self.tableView.register(ThemeCellView.classForCoder(), forCellReuseIdentifier: "theme")
    }

    func pickAccent() {
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let margin: CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 314 - margin * 4.0: alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColorAccent()
        MKColorPicker.selectionStyle = .check

        self.isAccent = true
        MKColorPicker.scrollDirection = .vertical
        let firstColor = ColorUtil.baseColor
        for i in 0 ..< MKColorPicker.colors.count {
            if MKColorPicker.colors[i].cgColor.__equalTo(firstColor.cgColor) {
                MKColorPicker.preselectedIndex = i
                break
            }
        }

        MKColorPicker.style = .circle

        alertController.view.addSubview(MKColorPicker)

        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: { (_: UIAlertAction!) in
            if self.accentChosen != nil {
                UserDefaults.standard.setColor(color: self.accentChosen!, forKey: "accentcolor")
                UserDefaults.standard.synchronize()
                _ = ColorUtil.doInit()
                self.titleLabel.textColor = self.accentChosen!
                self.tochange!.tableView.reloadData()
                self.setupViews()
                self.tochange!.doCells()
                self.tochange!.tableView.reloadData()
                self.tableView.reloadData()
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_: UIAlertAction!) in
            self.accentChosen = nil
            self.reduceColor.onTintColor = ColorUtil.baseAccent
            self.titleLabel.textColor = ColorUtil.baseAccent
            self.accent.imageView?.image = UIImage.init(named: "circle")?.toolbarIcon().getCopy(withColor: ColorUtil.baseAccent)
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

    var doneOnce = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
        if doneOnce {
            self.setupViews()
            self.tochange!.doCells()
            self.tochange!.tableView.reloadData()
            self.tableView.reloadData()
        } else {
            doneOnce = true
        }
    }

    override func loadView() {
        super.loadView()
        setupViews()
    }
    
    func setupViews() {
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Edit theme"
        self.tableView.separatorStyle = .none
        
        self.primary.textLabel?.text = "Primary color"
        self.primary.accessoryType = .none
        self.primary.backgroundColor = ColorUtil.foregroundColor
        self.primary.textLabel?.textColor = ColorUtil.fontColor
        self.primary.imageView?.image = UIImage.init(named: "circle")?.toolbarIcon().getCopy(withColor: ColorUtil.baseColor)
        
        self.accent.textLabel?.text = "Accent color"
        self.accent.accessoryType = .none
        self.accent.backgroundColor = ColorUtil.foregroundColor
        self.accent.textLabel?.textColor = ColorUtil.fontColor
        self.accent.imageView?.image = UIImage.init(named: "circle")?.toolbarIcon().getCopy(withColor: ColorUtil.baseAccent)
        
        self.custom.textLabel?.text = "Custom base theme"
        self.custom.accessoryType = .disclosureIndicator
        self.custom.backgroundColor = ColorUtil.foregroundColor
        self.custom.textLabel?.textColor = ColorUtil.fontColor
        self.custom.imageView?.image = UIImage.init(named: "selectall")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.custom.imageView?.tintColor = ColorUtil.navIconColor
        
        self.base.textLabel?.text = "Base theme"
        self.base.accessoryType = .disclosureIndicator
        self.base.backgroundColor = ColorUtil.foregroundColor
        self.base.textLabel?.textColor = ColorUtil.fontColor
        self.base.imageView?.image = UIImage.init(named: "palette")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.base.imageView?.tintColor = ColorUtil.navIconColor
        
        self.night.textLabel?.text = "Automatic night theme"
        self.night.accessoryType = .none
        self.night.backgroundColor = ColorUtil.foregroundColor
        self.night.textLabel?.textColor = ColorUtil.fontColor
        self.night.imageView?.image = UIImage.init(named: "night")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.night.imageView?.tintColor = ColorUtil.navIconColor
        
        tintOutsideSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        
        tintOutsideSwitch.isOn = SettingValues.onlyTintOutside
        tintOutsideSwitch.addTarget(self, action: #selector(SettingsTheme.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        self.tintOutside.textLabel?.text = "Only tint outside of subreddit"
        self.tintOutside.accessoryView = tintOutsideSwitch
        self.tintOutside.backgroundColor = ColorUtil.foregroundColor
        self.tintOutside.textLabel?.textColor = ColorUtil.fontColor
        tintOutside.selectionStyle = UITableViewCell.SelectionStyle.none
        
        self.tintingMode.textLabel?.text = "Subreddit tinting mode"
        self.tintingMode.detailTextLabel?.text = SettingValues.tintingMode
        self.tintingMode.backgroundColor = ColorUtil.foregroundColor
        self.tintingMode.textLabel?.textColor = ColorUtil.fontColor
        self.tintingMode.detailTextLabel?.textColor = ColorUtil.fontColor
        
        reduceColor = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        
        reduceColor.isOn = SettingValues.reduceColor
        reduceColor.addTarget(self, action: #selector(SettingsViewController.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        reduceColorCell.textLabel?.text = "Reduce app colors (experimental)"
        reduceColorCell.textLabel?.numberOfLines = 0
        reduceColorCell.accessoryView = reduceColor
        reduceColorCell.backgroundColor = ColorUtil.foregroundColor
        reduceColorCell.textLabel?.textColor = ColorUtil.fontColor
        reduceColorCell.selectionStyle = UITableViewCell.SelectionStyle.none
        self.reduceColorCell.imageView?.image = UIImage.init(named: "nocolors")?.toolbarIcon()
        self.reduceColorCell.imageView?.tintColor = ColorUtil.fontColor
        
        if SettingValues.reduceColor {
            self.primary.isUserInteractionEnabled = false
            self.primary.textLabel?.isEnabled = false
            self.primary.detailTextLabel?.isEnabled = false
            
            self.primary.detailTextLabel?.textColor = ColorUtil.fontColor
            self.primary.detailTextLabel?.numberOfLines = 0
            self.primary.detailTextLabel?.text = "Requires 'Reduce app colors' to be disabled"
        }
        
        createCell(reduceColorCell, reduceColor, isOn: SettingValues.reduceColor, text: "Reduce color throughout app (affects all navigation bars)")
        
        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.setImage(UIImage.init(named: "back")!.navIcon(), for: UIControl.State.normal)
        button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        
        let barButton = UIBarButtonItem.init(customView: button)
        
        let save = UIButtonWithContext.init(type: .custom)
        save.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        save.setImage(UIImage.init(named: "save")!.navIcon(), for: UIControl.State.normal)
        save.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        save.addTarget(self, action: #selector(self.save), for: .touchUpInside)
        let saveButton = UIBarButtonItem.init(customView: save)

        navigationItem.leftBarButtonItem = barButton
        navigationItem.rightBarButtonItems = [saveButton]

        self.navigationController?.setNavigationBarHidden(false, animated: false)
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
    
    var themeText: String?
    @objc public func save() {
        let alert = UIAlertController(title: "Name this theme", message: "", preferredStyle: .alert)
        
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        
        let today_string = String(year!) + "-" + String(month!) + "-" + String(day!)
        
        let config: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = ColorUtil.fontColor
            textField.attributedPlaceholder = NSAttributedString(string: "Theme name...", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.fontColor.withAlphaComponent(0.3)])
            textField.layer.borderColor = ColorUtil.fontColor.withAlphaComponent(0.3) .cgColor
            textField.backgroundColor = ColorUtil.foregroundColor
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
        
        alert.addOneTextField(configuration: config)
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (_) in
            var colorString = "slide://colors"
            colorString += ("#" + (self.themeText?.replacingOccurrences(of: "#", with: "<H>") ?? today_string)).addPercentEncoding
            
            colorString += (ColorUtil.foregroundColor.toHexString() + ColorUtil.backgroundColor.toHexString() + ColorUtil.fontColor.toHexString() + ColorUtil.navIconColor.toHexString() + ColorUtil.baseColor.toHexString() + ColorUtil.baseAccent.toHexString() + "#" + String(ColorUtil.theme.isLight())).addPercentEncoding
            UserDefaults.standard.set(colorString, forKey: "Theme+" + (self.themeText ?? today_string).replacingOccurrences(of: "#", with: "<H>").addPercentEncoding)
            UserDefaults.standard.synchronize()
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == reduceColor {
            MainViewController.needsRestart = true
            SettingValues.reduceColor = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_reduceColor)
        } else if changed == tintOutsideSwitch {
            SettingValues.onlyTintOutside = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_onlyTintOutside)
        } else if changed == reduceColor {
            MainViewController.needsRestart = true
            SettingValues.reduceColor = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_reduceColor)
            setupBaseBarColors()
            let button = UIButtonWithContext.init(type: .custom)
            button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
            button.setImage(UIImage.init(named: (self.navigationController?.viewControllers.count ?? 0) == 1 ? "close" : "back")!.navIcon(), for: UIControl.State.normal)
            button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
            
            let barButton = UIBarButtonItem.init(customView: button)
            
            navigationItem.leftBarButtonItem = barButton
        } else {
            SettingValues.nightModeEnabled = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_nightMode)
            _ = ColorUtil.doInit()
            self.tochange!.doCells()
            self.tochange!.tableView.reloadData()
        }
        self.setupViews()
        if SettingValues.reduceColor {
            self.primary.isUserInteractionEnabled = false
            self.primary.textLabel?.isEnabled = false
            self.primary.detailTextLabel?.isEnabled = false
            
            self.primary.detailTextLabel?.textColor = ColorUtil.fontColor
            self.primary.detailTextLabel?.numberOfLines = 0
            self.primary.detailTextLabel?.text = "Requires 'Reduce app colors' to be disabled"
        } else {
            self.primary.isUserInteractionEnabled = true
            self.primary.textLabel?.isEnabled = true
            self.primary.detailTextLabel?.isEnabled = true
            
            self.primary.detailTextLabel?.textColor = ColorUtil.fontColor
            self.primary.detailTextLabel?.numberOfLines = 0
            self.primary.detailTextLabel?.text = ""
        }
        self.setupBaseBarColors()
        self.tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return customThemes.count == 0 ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SubredditReorderViewController.changed = true
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.base
            case 1: return self.custom
            case 2: return self.primary
            case 3: return self.accent
            case 4: return self.night
            case 5: return self.reduceColorCell
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "theme") as! ThemeCellView
            cell.setTheme(string: customThemes[indexPath.row])
            return cell
        default: fatalError("Unknown section")
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    @available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let shareAction = UIContextualAction(style: .normal, title: "Share") { (_, _, b) in
            b(true)
            let textShare = [UserDefaults.standard.string(forKey: self.customThemes[indexPath.row])]
            let activityViewController = UIActivityViewController(activityItems: textShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.shareButton.customView
            self.present(activityViewController, animated: true, completion: nil)
        }
        shareAction.backgroundColor = ColorUtil.baseAccent

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, b) in
            UserDefaults.standard.removeObject(forKey: self.customThemes[indexPath.row])
            self.tableView.reloadData()
            b(true)
        }
        deleteAction.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [shareAction, deleteAction])
        return configuration
    }

    func selectTheme() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Select a night theme", message: "", preferredStyle: .actionSheet)
        
        actionSheetController.addCancelButton()
        
        for theme in ColorUtil.Theme.cases {
            if theme != .LIGHT && theme != .MINT && theme != .CREAM {
                let saveActionButton: UIAlertAction = UIAlertAction(title: theme.displayName, style: .default) { _ -> Void in
                    SettingValues.nightTheme = theme
                    UserDefaults.standard.set(theme.rawValue, forKey: SettingValues.pref_nightTheme)
                    UserDefaults.standard.synchronize()
                    _ = ColorUtil.doInit()
                    self.setupViews()
                    self.tableView.reloadData(with: .automatic)
                    self.tochange!.doCells()
                    self.tochange!.tableView.reloadData()
                }
                actionSheetController.addAction(saveActionButton)
            }
        }
        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = selectedTableView
            presenter.sourceRect = selectedTableView.bounds
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    var selectedTableView = UIView()

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTableView = tableView.cellForRow(at: indexPath)!.contentView
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 2 {
            pickTheme()
        } else if indexPath.section == 0 && indexPath.row == 3 {
            pickAccent()
        } else if indexPath.section == 0 && indexPath.row == 0 {
            VCPresenter.showVC(viewController: SettingsMainTheme(), popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
        } else if indexPath.section == 0 && indexPath.row == 4 {
            if !VCPresenter.proDialogShown(feature: false, self) {
                showNightTheme()
            }
        } else if indexPath.section == 0 && indexPath.row == 1 {
            if !VCPresenter.proDialogShown(feature: false, self) {
                VCPresenter.showVC(viewController: SettingsCustomTheme(), popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
            }
        } else if indexPath.section == 1 {
            if !VCPresenter.proDialogShown(feature: true, self) {
                let theme = customThemes[indexPath.row]
                let themeData = UserDefaults.standard.string(forKey: theme)!.removingPercentEncoding!
                let split = themeData.split("#")
                let alert = UIAlertController(title: "Apply theme \"\(split[1].removingPercentEncoding!.replacingOccurrences(of: "<H>", with: "#"))\"", message: "This will overwrite all your theme preferences", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Apply", style: .destructive, handler: { (_) in
                    UserDefaults.standard.set("custom", forKey: "theme")
                    
                    UserDefaults.standard.setColor(color: UIColor(hex: split[2]), forKey: ColorUtil.CUSTOM_FOREGROUND)
                    UserDefaults.standard.setColor(color: UIColor(hex: split[3]), forKey: ColorUtil.CUSTOM_BACKGROUND)
                    UserDefaults.standard.setColor(color: UIColor(hex: split[4]), forKey: ColorUtil.CUSTOM_FONT)
                    UserDefaults.standard.setColor(color: UIColor(hex: split[5]), forKey: ColorUtil.CUSTOM_NAVICON)
                    
                    UserDefaults.standard.setColor(color: UIColor(hex: split[6]), forKey: "baseColor")
                    UserDefaults.standard.setColor(color: UIColor(hex: split[7]), forKey: "accentcolor")
                    
                    UserDefaults.standard.set(!Bool(split[8])!, forKey: ColorUtil.CUSTOM_STATUSBAR)
                    UserDefaults.standard.synchronize()
                    
                    _ = ColorUtil.doInit()
                    SingleSubredditViewController.cellVersion += 1
                    SubredditReorderViewController.changed = true
                    self.tableView.reloadData(with: .automatic)
                    MainViewController.needsRestart = true
                    self.setupViews()
                    self.tochange!.doCells()
                    self.tochange!.tableView.reloadData()
                    self.tableView.reloadData()
                    self.setupBaseBarColors()
                }))
                alert.addCancelButton()
                self.present(alert, animated: true)
            }
        }
    }

    func getHourOffset(base: Int) -> Int {
        if base == 0 {
            return 12
        }
        return base
    }

    func getMinuteString(base: Int) -> String {
        return String.init(format: "%02d", arguments: [base])
    }

    func selectTime() {
        let alert = UIAlertController(style: .actionSheet, title: "Select night hours", message: "Select a PM time and an AM time")

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { _ -> Void in
            _ = ColorUtil.doInit()
            self.setupViews()
            self.tableView.reloadData(with: .automatic)
            self.tochange!.doCells()
            self.tochange!.tableView.reloadData()
        }
        alert.addAction(cancelActionButton)

        var values: [[String]] = [[], [], [], [], [], []]
        for i in 0...11 {
            values[0].append("\(getHourOffset(base: i))")
            values[3].append("\(getHourOffset(base: i))")
        }
        for i in 0...59 {
            if i % 5 == 0 {
                values[1].append(getMinuteString(base: i))
                values[4].append(getMinuteString(base: i))
            }
        }
        values[2].append("PM")
        values[5].append("AM")

        var initialSelection: [PickerViewViewController.Index] = []
        initialSelection.append((0, SettingValues.nightStart))
        initialSelection.append((1, SettingValues.nightStartMin / 5))
        initialSelection.append((3, SettingValues.nightEnd))
        initialSelection.append((4, SettingValues.nightEndMin / 5))

        alert.addPickerView(values: values, initialSelection: initialSelection) { _, _, index, _ in
            switch index.column {
            case 0:
                SettingValues.nightStart = index.row
                UserDefaults.standard.set(SettingValues.nightStart, forKey: SettingValues.pref_nightStartH)
                UserDefaults.standard.synchronize()
            case 1:
                SettingValues.nightStartMin = index.row * 5
                UserDefaults.standard.set(SettingValues.nightStartMin, forKey: SettingValues.pref_nightStartM)
                UserDefaults.standard.synchronize()
            case 3:
                SettingValues.nightEnd = index.row
                UserDefaults.standard.set(SettingValues.nightEnd, forKey: SettingValues.pref_nightEndH)
                UserDefaults.standard.synchronize()
            case 4:
                SettingValues.nightEndMin = index.row * 5
                UserDefaults.standard.set(SettingValues.nightEndMin, forKey: SettingValues.pref_nightEndM)
                UserDefaults.standard.synchronize()
            default: break
            }
        }

        alert.modalPresentationStyle = .popover
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = selectedTableView
            presenter.sourceRect = selectedTableView.bounds
        }

        self.present(alert, animated: true, completion: nil)
    }

    func showNightTheme() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Night Mode", message: "", preferredStyle: .actionSheet)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { _ -> Void in
        }
        actionSheetController.addAction(cancelActionButton)

        let enabled = UISwitch.init(frame: CGRect.init(x: 20, y: 20, width: 75, height: 50))
        enabled.isOn = SettingValues.nightModeEnabled
        enabled.addTarget(self, action: #selector(SettingsTheme.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        actionSheetController.view.addSubview(enabled)

        var button: UIAlertAction = UIAlertAction(title: "Select night hours", style: .default) { _ -> Void in
            self.selectTime()
        }
        actionSheetController.addAction(button)

        button = UIAlertAction(title: "Select night theme", style: .default) { _ -> Void in
            self.selectTheme()
        }
        actionSheetController.addAction(button)

        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = selectedTableView
            presenter.sourceRect = selectedTableView.bounds
        }

        self.present(actionSheetController, animated: true, completion: nil)

    }

    func showBaseTheme() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Select a base theme", message: "", preferredStyle: .actionSheet)

        actionSheetController.addCancelButton()

        for theme in ColorUtil.Theme.cases {
            if !SettingValues.isPro && (theme == ColorUtil.Theme.SEPIA || theme == ColorUtil.Theme.DEEP) {
                actionSheetController.addAction(image: UIImage.init(named: "support")?.menuIcon().getCopy(withColor: GMColor.red500Color()), title: theme.rawValue + " (pro)", color: GMColor.red500Color(), style: .default, isEnabled: true) { (_) in
                    _ = VCPresenter.proDialogShown(feature: false, self)
                }
            } else {
                let saveActionButton: UIAlertAction = UIAlertAction(title: theme.displayName, style: .default) { _ -> Void in
                    UserDefaults.standard.set(theme.rawValue, forKey: "theme")
                    UserDefaults.standard.synchronize()
                    _ = ColorUtil.doInit()
                    SubredditReorderViewController.changed = true
                    self.setupViews()
                    self.tableView.reloadData(with: .automatic)
                    self.tochange!.doCells()
                    self.tochange!.tableView.reloadData()
                    MainViewController.needsRestart = true
                }
                actionSheetController.addAction(saveActionButton)
            }
        }
        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = selectedTableView
            presenter.sourceRect = selectedTableView.bounds
        }

        self.present(actionSheetController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        titleLabel = UILabel()
        titleLabel.textColor = ColorUtil.baseAccent
        titleLabel.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = titleLabel.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor

        switch section {
        case 0: titleLabel.text = "App theme"
        case 1: titleLabel.text = "Saved themes"
        default: titleLabel.text = ""
        }
        return toReturn
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 6
        case 1: return customThemes.count
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
