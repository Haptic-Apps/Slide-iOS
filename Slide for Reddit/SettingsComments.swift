//
//  SettingsComments.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/28/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import MKColorPicker
import UIKit

class SettingsComments: BubbleSettingTableViewController, ColorPickerViewDelegate {
    var disableNavigationBarCell: UITableViewCell = InsetCell()
    var disableNavigationBar = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var authorThemeCell: UITableViewCell = InsetCell()

    var themeColorCell: UITableViewCell = InsetCell()
    
    var wideIndicatorCell: UITableViewCell = InsetCell()
    var wideIndicator = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var floatingJumpCell: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: "jump")

    var collapseDefaultCell: UITableViewCell = InsetCell()
    var collapseDefault = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var swapLongPressCell: UITableViewCell = InsetCell()
    var swapLongPress = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var collapseFullyCell: UITableViewCell = InsetCell()
    var collapseFully = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var fullscreenImageCell: UITableViewCell = InsetCell()
    var fullscreenImage = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var highlightOpCell: UITableViewCell = InsetCell()
    var highlightOp = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var hideAutomodCell: UITableViewCell = InsetCell()
    var hideAutomod = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == disableNavigationBar {
            SettingValues.disableNavigationBar = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_disableNavigationBar)
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
            SettingValues.commentFullScreen = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_commentFullScreen)
        } else if changed == highlightOp {
            SettingValues.highlightOp = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_highlightOp)
        }
        UserDefaults.standard.synchronize()
    }
    
    func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        ColorUtil.setCommentNameColor(color: colorPickerView.colors[indexPath.row])
        self.updateThemeCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 && indexPath.row == 0 {
            showAuthorChooser()
        } else if indexPath.section == 1 && indexPath.row == 1 {
            showDepthChooser()
        } else if indexPath.section == 0 && indexPath.row == 2 {
            showJumpChooser()
        }
    }
    
    func showJumpChooser() {
        let actionSheetController = DragDownAlertMenu(title: "Comment floating jump button", subtitle: "Can be long-pressed to jump up", icon: nil)
        
        let selected = UIImage.init(named: "selected")!.menuIcon()

        for t in SettingValues.CommentJumpMode.cases {
            actionSheetController.addAction(title: t.getTitle(), icon: SettingValues.commentJumpButton == t ? selected : nil) {
                SettingValues.commentJumpButton = t
                UserDefaults.standard.set(t.rawValue, forKey: SettingValues.pref_commentJumpMode)
                self.floatingJumpCell.detailTextLabel?.text = t.getTitle()
            }
        }
        
        actionSheetController.show(self)
    }
    
    func setDepthColors(_ colors: [UIColor]) {
        ColorUtil.setCommentDepthColors(colors)
        self.updateDepthsCell()
    }
    
    func showDepthChooser() {
        let alertController = DragDownAlertMenu(title: "Comment depth theme", subtitle: "Select a color theme for comment depth", icon: nil)

        alertController.addAction(title: "Default", icon: UIImage(named: "circle")!.menuIcon().getCopy(withColor: GMColor.red500Color())) {
            var colorArray = [UIColor]()
            colorArray.append(GMColor.red500Color())
            colorArray.append(GMColor.orange500Color())
            colorArray.append(GMColor.yellow500Color())
            colorArray.append(GMColor.green500Color())
            colorArray.append(GMColor.blue500Color())
            self.setDepthColors(colorArray)
        }

        alertController.addAction(title: "Monochrome", icon: UIImage(named: "circle")!.menuIcon().getCopy(withColor: GMColor.grey500Color())) {
            var colorArray = [UIColor]()
            colorArray.append(GMColor.grey700Color())
            colorArray.append(GMColor.grey600Color())
            colorArray.append(GMColor.grey500Color())
            colorArray.append(GMColor.grey400Color())
            colorArray.append(GMColor.grey300Color())
            self.setDepthColors(colorArray)
        }

        alertController.addAction(title: "Main color", icon: UIImage(named: "circle")!.menuIcon().getCopy(withColor: ColorUtil.baseColor)) {
            let baseColor = ColorUtil.baseColor
            var colorArray = [UIColor]()
            colorArray.append(baseColor.add(overlay: UIColor.white.withAlphaComponent(0.3)))
            colorArray.append(baseColor.add(overlay: UIColor.white.withAlphaComponent(0.15)))
            colorArray.append(baseColor)
            colorArray.append(baseColor.add(overlay: UIColor.black.withAlphaComponent(0.15)))
            colorArray.append(baseColor.add(overlay: UIColor.black.withAlphaComponent(0.3)))
            self.setDepthColors(colorArray)
        }

        alertController.addAction(title: "Invisible", icon: UIImage(named: "circle")!.menuIcon().getCopy(withColor: ColorUtil.theme.backgroundColor)) {
            let baseColor = ColorUtil.theme.backgroundColor
            var colorArray = [UIColor]()
            colorArray.append(baseColor)
            colorArray.append(baseColor)
            colorArray.append(baseColor)
            colorArray.append(baseColor)
            colorArray.append(baseColor)
            self.setDepthColors(colorArray)
        }

        alertController.addAction(title: "Accent color", icon: UIImage(named: "circle")!.menuIcon().getCopy(withColor: ColorUtil.baseAccent)) {
            let baseColor = ColorUtil.baseAccent
            var colorArray = [UIColor]()
            colorArray.append(baseColor.add(overlay: UIColor.white.withAlphaComponent(0.3)))
            colorArray.append(baseColor.add(overlay: UIColor.white.withAlphaComponent(0.15)))
            colorArray.append(baseColor)
            colorArray.append(baseColor.add(overlay: UIColor.black.withAlphaComponent(0.15)))
            colorArray.append(baseColor.add(overlay: UIColor.black.withAlphaComponent(0.3)))
            self.setDepthColors(colorArray)
        }

        alertController.addAction(title: "Space", icon: UIImage(named: "circle")!.menuIcon().getCopy(withColor: UIColor(hex: "BF3436"))) {
            var colorArray = [UIColor]()
            colorArray.append(UIColor(hex: "EF6040"))
            colorArray.append(UIColor(hex: "BF3436"))
            colorArray.append(UIColor(hex: "6C2032"))
            colorArray.append(UIColor(hex: "662132"))
            colorArray.append(UIColor(hex: "20151D"))
            self.setDepthColors(colorArray)
        }

        alertController.addAction(title: "Candy", icon: UIImage(named: "circle")!.menuIcon().getCopy(withColor: GMColor.blue500Color())) {
            var colorArray = [UIColor]()
            colorArray.append(UIColor(hex: "E83F6F"))
            colorArray.append(UIColor(hex: "FF7B00"))
            colorArray.append(UIColor(hex: "FFBF00"))
            colorArray.append(UIColor(hex: "32936F"))
            colorArray.append(UIColor(hex: "2274A5"))
            self.setDepthColors(colorArray)
        }

        alertController.addAction(title: "Spice", icon: UIImage(named: "circle")!.menuIcon().getCopy(withColor: GMColor.blue500Color())) {
            var colorArray = [UIColor]()
            colorArray.append(UIColor(hex: "4F000B"))
            colorArray.append(UIColor(hex: "720026"))
            colorArray.append(UIColor(hex: "CE4257"))
            colorArray.append(UIColor(hex: "CE4257"))
            colorArray.append(UIColor(hex: "FF9B54"))
            self.setDepthColors(colorArray)
        }

        alertController.addAction(title: "Bright", icon: UIImage(named: "circle")!.menuIcon().getCopy(withColor: GMColor.blue500Color())) {
            var colorArray = [UIColor]()
            colorArray.append(UIColor(hex: "FFBE0B"))
            colorArray.append(UIColor(hex: "FB5607"))
            colorArray.append(UIColor(hex: "FF006E"))
            colorArray.append(UIColor(hex: "8338EC"))
            colorArray.append(UIColor(hex: "3A86FF"))
            self.setDepthColors(colorArray)
        }

        alertController.show(self)
    }
    
    func showAuthorChooser() {
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
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

    override func loadView() {
        super.loadView()
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        // set the title
        self.title = "Comments settings"
        self.headers = ["Comments page", "Comment display", "Comment interaction"]

        createCell(disableNavigationBarCell, disableNavigationBar, isOn: SettingValues.disableNavigationBar, text: "Disable comment navigation toolbar")
        createCell(fullscreenImageCell, fullscreenImage, isOn: !SettingValues.commentFullScreen, text: "Crop the lead banner image")
        createCell(collapseDefaultCell, collapseDefault, isOn: SettingValues.collapseDefault, text: "Collapse all comments automatically")
        createCell(swapLongPressCell, swapLongPress, isOn: SettingValues.swapLongPress, text: "Swap tap and long press actions")
        createCell(collapseFullyCell, collapseFully, isOn: SettingValues.collapseFully, text: "Collapse comments fully")
        createCell(highlightOpCell, highlightOp, isOn: SettingValues.highlightOp, text: "Purple depth indicator for OP replies")
        createCell(wideIndicatorCell, wideIndicator, isOn: SettingValues.wideIndicators, text: "Make comment depth indicator wider")
        createCell(hideAutomodCell, hideAutomod, isOn: SettingValues.hideAutomod, text: "Hide pinned AutoModerator comments")
        createCell(floatingJumpCell, nil, isOn: false, text: "Floating jump button")
        floatingJumpCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        floatingJumpCell.detailTextLabel?.numberOfLines = 0
        floatingJumpCell.detailTextLabel?.text = SettingValues.commentJumpButton.getTitle()

        updateThemeCell()
        updateDepthsCell()
        
        self.tableView.tableFooterView = UIView()
    }
    
    public func updateThemeCell() {
        authorThemeCell.textLabel?.text = "Author username color"
        authorThemeCell.textLabel?.textColor = ColorUtil.theme.fontColor
        authorThemeCell.backgroundColor = ColorUtil.theme.foregroundColor
        authorThemeCell.textLabel?.numberOfLines = 0
        authorThemeCell.textLabel?.lineBreakMode = .byWordWrapping
        authorThemeCell.selectionStyle = UITableViewCell.SelectionStyle.none
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        circleView.layer.cornerRadius = 15
        circleView.backgroundColor = ColorUtil.getCommentNameColor("NONE")
        authorThemeCell.accessoryView = circleView
    }
    
    public func updateDepthsCell() {
        themeColorCell.textLabel?.text = "Depths colors"
        themeColorCell.textLabel?.textColor = ColorUtil.theme.fontColor
        themeColorCell.backgroundColor = ColorUtil.theme.foregroundColor
        themeColorCell.textLabel?.numberOfLines = 0
        themeColorCell.textLabel?.lineBreakMode = .byWordWrapping
        themeColorCell.selectionStyle = UITableViewCell.SelectionStyle.none
        let currentColors = ColorUtil.getCommentDepthColors().backwards()
        let stack = UIStackView(frame: CGRect(x: 0, y: 0, width: 68, height: 30)).then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 2
        }
        for i in 0...4 {
            let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
            circleView.layer.cornerRadius = 6
            circleView.backgroundColor = currentColors[i]
            circleView.heightAnchor == 12
            circleView.widthAnchor == 12
            stack.addArrangedSubview(circleView)
        }
        themeColorCell.accessoryView = stack
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        PagingCommentViewController.savedComment = nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.fullscreenImageCell
            case 1: return self.hideAutomodCell
            case 2: return self.floatingJumpCell
            default: fatalError("Unkown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.authorThemeCell
            case 1: return self.themeColorCell
            case 2: return self.wideIndicatorCell
            case 3: return self.highlightOpCell
            default: fatalError("Unknown row in section 1")
            }
        case 2:
            switch indexPath.row {
            case 0: return self.collapseDefaultCell
            case 1: return self.collapseFullyCell
            case 2: return self.swapLongPressCell
            default: fatalError("Unknown row in section 2")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return 4
        case 2: return 3
        default: fatalError("Unknown number of sections")
        }
    }
    
}
