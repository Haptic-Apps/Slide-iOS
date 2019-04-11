//
//  SettingsTheme.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/21/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import MKColorPicker
import RLBAlertsPickers
import UIKit
import SDCAlertView

class SettingsTheme: MediaTableViewController, ColorPickerViewDelegate {

    var tochange: SettingsViewController?
    var primary: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "primary")
    var accent: UITableViewCell = UITableViewCell()
    var base: UITableViewCell = UITableViewCell()
    var night: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "night")
    var tintingMode: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "tintingMode")
    var tintOutside: UITableViewCell = UITableViewCell()
    var tintOutsideSwitch: UISwitch = UISwitch()
    var custom: UITableViewCell = UITableViewCell()

    var shareButton = UIBarButtonItem.init()

    var reduceColorCell: UITableViewCell = UITableViewCell()
    var reduceColor: UISwitch = UISwitch()
    var nightEnabled: UISwitch = UISwitch()

    var isAccent = false
    
    var titleLabel = UILabel()

    var accentChosen: UIColor?
    var primaryChosen: UIColor?
    
    var customThemes: [String] = []

    public func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        if isAccent {
            accentChosen = colorPickerView.colors[indexPath.row]
            titleLabel.textColor = self.accentChosen
            self.accent.imageView?.image = UIImage.init(named: "circle")?.toolbarIcon().getCopy(withColor: accentChosen!)
            reduceColor.onTintColor = accentChosen!
            tableView.beginUpdates()
            tableView.endUpdates()
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
    static var needsRestart = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
        if doneOnce || SettingsTheme.needsRestart {
            SettingsTheme.needsRestart = false
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
        self.customThemes = UserDefaults.standard.dictionaryRepresentation().keys.filter({ $0.startsWith("Theme+") })
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
        
        nightEnabled = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        nightEnabled.isOn = SettingValues.nightModeEnabled
        nightEnabled.addTarget(self, action: #selector(SettingsViewController.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        self.night.textLabel?.text = "Night Mode"
        self.night.detailTextLabel?.text = "Tap to change night hours"
        self.night.detailTextLabel?.textColor = ColorUtil.fontColor
        self.night.accessoryType = .none
        self.night.backgroundColor = ColorUtil.foregroundColor
        self.night.textLabel?.textColor = ColorUtil.fontColor
        self.night.imageView?.image = UIImage.init(named: "night")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.night.imageView?.tintColor = ColorUtil.navIconColor
        night.accessoryView = nightEnabled

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
        
        navigationItem.leftBarButtonItem = barButton

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

    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == reduceColor {
            MainViewController.needsReTheme = true
            SettingValues.reduceColor = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_reduceColor)
        } else if changed == tintOutsideSwitch {
            SettingValues.onlyTintOutside = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_onlyTintOutside)
        } else if changed == reduceColor {
            MainViewController.needsReTheme = true
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
        } else if changed == nightEnabled {
            if !VCPresenter.proDialogShown(feature: false, self) {
                SettingValues.nightModeEnabled = changed.isOn
                UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_nightMode)
                _ = ColorUtil.doInit()
                SingleSubredditViewController.cellVersion += 1
                MainViewController.needsReTheme = true
                self.tochange!.doCells()
                self.tochange!.tableView.reloadData()
            } else {
                nightEnabled.isOn = false
            }
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
        return SettingValues.nightModeEnabled && ColorUtil.shouldBeNight() ? 2 : 4
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.primary
            case 1: return self.accent
            case 2: return self.reduceColorCell
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.night
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "theme") as! ThemeCellView
                cell.setTheme(theme: SettingValues.nightTheme)
                return cell
            }
        case 2:
            switch indexPath.row {
            case 0: return self.custom
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "theme") as! ThemeCellView
                cell.setTheme(string: customThemes[indexPath.row - 1])
                return cell
            }
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "theme") as! ThemeCellView
            cell.setTheme(theme: ColorUtil.Theme.cases[indexPath.row])
            return cell
        default: fatalError("Unknown section")
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 2 && indexPath.row != 0
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
            UserDefaults.standard.synchronize()
            self.customThemes = UserDefaults.standard.dictionaryRepresentation().keys.filter({ $0.startsWith("Theme+") })
            self.tableView.reloadData()
            b(true)
        }
        deleteAction.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [shareAction, deleteAction])
        return configuration
    }

    func selectTheme() {
        let chooseVC = SettingsThemeChooser()
        chooseVC.callback = { theme in
            SettingValues.nightTheme = theme
            UserDefaults.standard.set(theme.rawValue, forKey: SettingValues.pref_nightTheme)
            UserDefaults.standard.synchronize()
            _ = ColorUtil.doInit()
            SingleSubredditViewController.cellVersion += 1
            MainViewController.needsReTheme = true
            self.setupViews()
            self.tableView.reloadData()
            self.tochange!.doCells()
            self.tochange!.tableView.reloadData()
            self.setupBaseBarColors()
        }
        VCPresenter.presentModally(viewController: chooseVC, self)
    }
    
    var selectedTableView = UIView()

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTableView = tableView.cellForRow(at: indexPath)!.contentView
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 0 {
            pickTheme()
        } else if indexPath.section == 0 && indexPath.row == 1 {
            pickAccent()
        } else if indexPath.section == 1 && indexPath.row == 0 {
            if !VCPresenter.proDialogShown(feature: false, self) {
                self.selectTime()
            }
        } else if indexPath.section == 1 && indexPath.row == 1 {
            if !VCPresenter.proDialogShown(feature: false, self) {
                self.selectTheme()
            }
        } else if indexPath.section == 2 && indexPath.row == 0 {
            if !VCPresenter.proDialogShown(feature: false, self) {
                let theme = SettingsCustomTheme()
                VCPresenter.presentAlert(UINavigationController(rootViewController: theme), parentVC: self)
            }
        } else if indexPath.section == 2 {
            if !VCPresenter.proDialogShown(feature: true, self) {
                let row = indexPath.row - 1
                let theme = customThemes[row]
                let themeData = UserDefaults.standard.string(forKey: theme)!.removingPercentEncoding!
                let split = themeData.split("#")
                let alert = UIAlertController(title: "\(split[1].removingPercentEncoding!.replacingOccurrences(of: "<H>", with: "#"))", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Apply Theme", style: .default, handler: { (_) in
                    UserDefaults.standard.set("custom", forKey: "theme")
                    
                    UserDefaults.standard.setColor(color: UIColor(hex: split[2]), forKey: ColorUtil.CUSTOM_FOREGROUND)
                    UserDefaults.standard.setColor(color: UIColor(hex: split[3]), forKey: ColorUtil.CUSTOM_BACKGROUND)
                    UserDefaults.standard.setColor(color: UIColor(hex: split[4]), forKey: ColorUtil.CUSTOM_FONT)
                    UserDefaults.standard.setColor(color: UIColor(hex: split[5]), forKey: ColorUtil.CUSTOM_NAVICON)
                    
                    //UserDefaults.standard.setColor(color: UIColor(hex: split[6]), forKey: "baseColor")
                    //UserDefaults.standard.setColor(color: UIColor(hex: split[7]), forKey: "accentcolor")
                    
                    UserDefaults.standard.set(!Bool(split[8])!, forKey: ColorUtil.CUSTOM_STATUSBAR)
                    UserDefaults.standard.synchronize()
                    
                    _ = ColorUtil.doInit()
                    SingleSubredditViewController.cellVersion += 1
                    self.tableView.reloadData()
                    MainViewController.needsReTheme = true
                    self.setupViews()
                    self.tochange!.doCells()
                    self.tochange!.tableView.reloadData()
                    self.tableView.reloadData()
                    self.setupBaseBarColors()
                }))
                alert.addAction(UIAlertAction(title: "Edit Theme", style: .destructive, handler: { (_) in
                    let theme = SettingsCustomTheme()
                    theme.inputTheme = self.customThemes[row]
                    VCPresenter.presentAlert(UINavigationController(rootViewController: theme), parentVC: self)
                }))
                alert.addCancelButton()
                self.present(alert, animated: true)
            }
        } else if indexPath.section == 3 {
            let row = indexPath.row
            let theme = ColorUtil.Theme.cases[row]
            UserDefaults.standard.set(theme.rawValue, forKey: "theme")
            UserDefaults.standard.synchronize()
            _ = ColorUtil.doInit()
            SingleSubredditViewController.cellVersion += 1
            self.tableView.reloadData()
            MainViewController.needsReTheme = true
            self.setupViews()
            self.tochange!.doCells()
            self.tochange!.tableView.reloadData()
            self.tableView.reloadData()
            self.setupBaseBarColors()
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
        let alert = AlertController(title: "Select night hours", message: nil, preferredStyle: .alert)

        let cancelActionButton = AlertAction(title: "Save", style: .preferred) { _ -> Void in
            _ = ColorUtil.doInit()
            self.setupViews()
            SingleSubredditViewController.cellVersion += 1
            MainViewController.needsReTheme = true
            self.tableView.reloadData()
            self.tochange!.doCells()
            self.tochange!.tableView.reloadData()
            self.setupBaseBarColors()
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
        alert.setupTheme()
        
        alert.attributedTitle = NSAttributedString(string: "Select night hours", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.fontColor])
        
        let pickerView = PickerViewViewControllerColored(values: values, initialSelection: initialSelection, action: { _, _, index, _ in
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
        })
        
        alert.addChild(pickerView)

        let pv = pickerView.view!
        alert.contentView.addSubview(pv)
        
        pv.edgeAnchors == alert.contentView.edgeAnchors - 14
        pv.heightAnchor == CGFloat(216)
        pickerView.didMove(toParent: alert)
        
        alert.addCancelButton()
        alert.addBlurView()
        
        self.present(alert, animated: true, completion: nil)
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
                    self.setupViews()
                    self.tableView.reloadData()
                    self.tochange!.doCells()
                    self.tochange!.tableView.reloadData()
                    MainViewController.needsReTheme = true
                    self.setupBaseBarColors()
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
        case 0: titleLabel.text = "App Colors"
        case 1: titleLabel.text = "Night mode"
        case 2: titleLabel.text = "Custom themes"
        case 3: titleLabel.text = "Standard themes"
        default: titleLabel.text = ""
        }
        return toReturn
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return 2
        case 2: return customThemes.count + 1
        case 3: return ColorUtil.Theme.cases.count
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
final public class PickerViewViewControllerColored: UIViewController {
    
    public typealias Values = [[String]]
    public typealias Index = (column: Int, row: Int)
    public typealias Action = (_ vc: UIViewController, _ picker: UIPickerView, _ index: Index, _ values: Values) -> ()
    
    fileprivate var action: Action?
    fileprivate var values: Values = [[]]
    fileprivate var initialSelection: [Index]?
    
    fileprivate lazy var pickerView: UIPickerView = {
        return $0
    }(UIPickerView())
    
    public init(values: Values, initialSelection: [Index]? = nil, action: Action?) {
        super.init(nibName: nil, bundle: nil)
        self.values = values
        self.initialSelection = initialSelection
        self.action = action
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Log("has deinitialized")
    }
    
    override public func loadView() {
        view = pickerView
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        pickerView.dataSource = self
        pickerView.delegate = self
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let initialSelection = initialSelection {
            for index in initialSelection {
                if values.count > index.column && values[index.column].count > index.row {
                    pickerView.selectRow(index.row, inComponent: index.column, animated: true)
                }
            }
        }
        
    }
}

extension PickerViewViewControllerColored: UIPickerViewDataSource, UIPickerViewDelegate {
    
    // returns the number of 'columns' to display.
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return values.count
    }
    
    
    // returns the # of rows in each component..
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values[component].count
    }
    
    // these methods return either a plain NSString, a NSAttributedString, or a view (e.g UILabel) to display the row for the component.
    // for the view versions, we cache any hidden and thus unused views and pass them back for reuse.
    // If you return back a different object, the old one will be released. the view will be centered in the row rect
    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: values[component][row], attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.fontColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 8)])
    }
    /*
     public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
     // attributed title is favored if both methods are implemented
     }
     
     
     public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
     
     }
     */
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        action?(self, pickerView, Index(column: component, row: row), values)
    }
}
