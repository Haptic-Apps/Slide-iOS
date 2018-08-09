//
//  SettingsComments.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/28/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import MKColorPicker
import UIKit

class SettingsComments: UITableViewController, ColorPickerViewDelegate {
    var disableNavigationBarCell: UITableViewCell = UITableViewCell()
    var disableNavigationBar = UISwitch()
    
    var authorThemeCell: UITableViewCell = UITableViewCell()

    var disableColorCell: UITableViewCell = UITableViewCell()
    var disableColor = UISwitch()
    
    var lockBottomCell: UITableViewCell = UITableViewCell()
    var lockBottom = UISwitch()
    
    var wideIndicatorCell: UITableViewCell = UITableViewCell()
    var wideIndicator = UISwitch()
    
    var collapseDefaultCell: UITableViewCell = UITableViewCell()
    var collapseDefault = UISwitch()
    
    var swapLongPressCell: UITableViewCell = UITableViewCell()
    var swapLongPress = UISwitch()
    
    var collapseFullyCell: UITableViewCell = UITableViewCell()
    var collapseFully = UISwitch()

    var fullscreenImageCell: UITableViewCell = UITableViewCell()
    var fullscreenImage = UISwitch()

    var highlightOpCell: UITableViewCell = UITableViewCell()
    var highlightOp = UISwitch()
    
    var hideAutomodCell: UITableViewCell = UITableViewCell()
    var hideAutomod = UISwitch()

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
        if changed == disableNavigationBar {
            SettingValues.disableNavigationBar = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_disableNavigationBar)
        } else if changed == disableColor {
            SettingValues.disableColor = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_disableColor)
        } else if changed == lockBottom {
            SettingValues.lockCommentBars = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_lockCommentBottomBar)
        } else if changed == wideIndicator {
            SettingValues.wideIndicators = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_widerIndicators)
        } else if changed == hideAutomod {
            SettingValues.hideAutomod = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_hideAutomod)
        } else if changed == collapseDefault {
            SettingValues.collapseDefault = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_collapseDefault)
        } else if changed == swapLongPress {
            SettingValues.swapLongPress = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_swapLongPress)
        } else if changed == collapseFully {
            SettingValues.collapseFully = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_collapseFully)
        } else if changed == fullscreenImage {
            SettingValues.commentFullScreen = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_commentFullScreen)
        } else if changed == highlightOp {
            SettingValues.highlightOp = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_highlightOp)
        }
        UserDefaults.standard.synchronize()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        
        switch section {
        case 0: label.text  = "Submission"
        case 1: label.text  = "Display"
        case 2: label.text = "Interaction"
        default: label.text  = ""
        }
        return toReturn
    }
    
    func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        ColorUtil.setCommentNameColor(color: colorPickerView.colors[indexPath.row])
        self.updateThemeCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 && indexPath.row == 0 {
            showAuthorChooser()
        }
    }
    
    func showAuthorChooser() {
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin: CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 314 - margin * 4.0: alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColor()
        MKColorPicker.selectionStyle = .check
        MKColorPicker.scrollDirection = .vertical
        
        MKColorPicker.style = .circle
        
        alertController.view.addSubview(MKColorPicker)
        
        alertController.addAction(UIAlertAction(title: "Match theme font color", style: .default, handler: { (_) in
            ColorUtil.setCommentNameColor(color: nil)
            self.updateThemeCell()
        }))
        
        alertController.addAction(UIAlertAction(title: "Match subreddit accent color", style: .default, handler: { (_) in
            ColorUtil.setCommentNameColor(color: nil, accent: true)
            self.updateThemeCell()
        }))

        let cancelAction = UIAlertAction(title: "Save", style: .cancel, handler: { (_: UIAlertAction!) in
        })
        
        alertController.addAction(cancelAction)
        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = authorThemeCell.contentView
            presenter.sourceRect = authorThemeCell.contentView.bounds
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
            s.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
            cell.accessoryView = s
        }
        cell.selectionStyle = UITableViewCellSelectionStyle.none
    }

    override func loadView() {
        super.loadView()
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Comments"
        self.tableView.separatorStyle = .none

        createCell(disableNavigationBarCell, disableNavigationBar, isOn: SettingValues.disableNavigationBar, text: "Disable comment navigation toolbar")
        createCell(fullscreenImageCell, fullscreenImage, isOn: SettingValues.commentFullScreen, text: "Show full height submission image in commment view")
        createCell(disableColorCell, disableColor, isOn: SettingValues.disableColor, text: "Monochrome comment depth indicators")
        createCell(collapseDefaultCell, collapseDefault, isOn: SettingValues.collapseDefault, text: "Collapse all comments automatically")
        createCell(swapLongPressCell, swapLongPress, isOn: SettingValues.swapLongPress, text: "Swap tap and long press actions")
        createCell(collapseFullyCell, collapseFully, isOn: SettingValues.collapseFully, text: "Collapse comments fully")
        createCell(highlightOpCell, highlightOp, isOn: SettingValues.highlightOp, text: "Highlight op replies of parent comments")
        createCell(wideIndicatorCell, wideIndicator, isOn: SettingValues.wideIndicators, text: "Make comment depth indicator wider")
        createCell(lockBottomCell, lockBottom, isOn: SettingValues.lockCommentBars, text: "Don't autohide toolbars in comments")
        createCell(hideAutomodCell, hideAutomod, isOn: SettingValues.hideAutomod, text: "Move top AutoModerator comment to a button (if it is not your submission)")

        updateThemeCell()
        
        self.tableView.tableFooterView = UIView()
    }
    
    public func updateThemeCell() {
        authorThemeCell.textLabel?.text = "Author username color"
        authorThemeCell.textLabel?.textColor = ColorUtil.fontColor
        authorThemeCell.backgroundColor = ColorUtil.foregroundColor
        authorThemeCell.textLabel?.numberOfLines = 0
        authorThemeCell.textLabel?.lineBreakMode = .byWordWrapping
        authorThemeCell.selectionStyle = UITableViewCellSelectionStyle.none
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        circleView.layer.cornerRadius = 15
        circleView.backgroundColor = ColorUtil.getCommentNameColor("NONE")
        authorThemeCell.accessoryView = circleView
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
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
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.fullscreenImageCell
            case 1: return self.hideAutomodCell
            default: fatalError("Unkown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.authorThemeCell
            case 1: return self.disableColorCell
            case 2: return self.wideIndicatorCell
            default: fatalError("Unknown row in section 1")
            }
        case 2:
            switch indexPath.row {
            case 0: return self.collapseDefaultCell
            case 1: return self.collapseFullyCell
            case 2: return self.swapLongPressCell
            case 3: return self.highlightOpCell
            case 4: return self.lockBottomCell
            default: fatalError("Unknown row in section 2")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 3
        case 2: return 5
        default: fatalError("Unknown number of sections")
        }
    }
    
}
