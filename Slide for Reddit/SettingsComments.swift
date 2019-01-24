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
import XLActionController

class SettingsComments: UITableViewController, ColorPickerViewDelegate {
    var disableNavigationBarCell: UITableViewCell = UITableViewCell()
    var disableNavigationBar = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var authorThemeCell: UITableViewCell = UITableViewCell()

    var themeColorCell: UITableViewCell = UITableViewCell()
    
    var wideIndicatorCell: UITableViewCell = UITableViewCell()
    var wideIndicator = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var collapseDefaultCell: UITableViewCell = UITableViewCell()
    var collapseDefault = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var swapLongPressCell: UITableViewCell = UITableViewCell()
    var swapLongPress = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var collapseFullyCell: UITableViewCell = UITableViewCell()
    var collapseFully = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var fullscreenImageCell: UITableViewCell = UITableViewCell()
    var fullscreenImage = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var highlightOpCell: UITableViewCell = UITableViewCell()
    var highlightOp = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var hideAutomodCell: UITableViewCell = UITableViewCell()
    var hideAutomod = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

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
        setupBaseBarColors()
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
        } else if indexPath.section == 1 && indexPath.row == 1 {
            showDepthChooser()
        }
    }
    
    func setDepthColors(_ colors: [UIColor]) {
        ColorUtil.setCommentDepthColors(colors)
        self.updateDepthsCell()
    }
    
    func showDepthChooser() {
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Comment depth colors"

        alertController.addAction(Action(ActionData(title: "Default", image: UIImage(named: "circle")!.menuIcon().getCopy(withColor: GMColor.red500Color())), style: .default, handler: { _ in
            //choose color
            var colorArray = [UIColor]()
            colorArray.append(GMColor.red500Color())
            colorArray.append(GMColor.orange500Color())
            colorArray.append(GMColor.yellow500Color())
            colorArray.append(GMColor.green500Color())
            colorArray.append(GMColor.blue500Color())
            self.setDepthColors(colorArray)
        }))
        
        alertController.addAction(Action(ActionData(title: "Monochrome", image: UIImage(named: "circle")!.menuIcon().getCopy(withColor: GMColor.grey500Color())), style: .default, handler: { _ in
            var colorArray = [UIColor]()
            colorArray.append(GMColor.grey700Color())
            colorArray.append(GMColor.grey600Color())
            colorArray.append(GMColor.grey500Color())
            colorArray.append(GMColor.grey400Color())
            colorArray.append(GMColor.grey300Color())
            self.setDepthColors(colorArray)
        }))
        
        alertController.addAction(Action(ActionData(title: "Main color", image: UIImage(named: "circle")!.menuIcon().getCopy(withColor: ColorUtil.baseColor)), style: .default, handler: { _ in
            let baseColor = ColorUtil.baseColor
            var colorArray = [UIColor]()
            colorArray.append(baseColor.add(overlay: UIColor.white.withAlphaComponent(0.3)))
            colorArray.append(baseColor.add(overlay: UIColor.white.withAlphaComponent(0.15)))
            colorArray.append(baseColor)
            colorArray.append(baseColor.add(overlay: UIColor.black.withAlphaComponent(0.15)))
            colorArray.append(baseColor.add(overlay: UIColor.black.withAlphaComponent(0.3)))
            self.setDepthColors(colorArray)
        }))
        
        alertController.addAction(Action(ActionData(title: "Invisible", image: UIImage(named: "circle")!.menuIcon().getCopy(withColor: ColorUtil.backgroundColor)), style: .default, handler: { _ in
            let baseColor = ColorUtil.backgroundColor
            var colorArray = [UIColor]()
            colorArray.append(baseColor)
            colorArray.append(baseColor)
            colorArray.append(baseColor)
            colorArray.append(baseColor)
            colorArray.append(baseColor)
            self.setDepthColors(colorArray)
        }))
        
        alertController.addAction(Action(ActionData(title: "Accent color", image: UIImage(named: "circle")!.menuIcon().getCopy(withColor: ColorUtil.baseAccent)), style: .default, handler: { _ in
            let baseColor = ColorUtil.baseAccent
            var colorArray = [UIColor]()
            colorArray.append(baseColor.add(overlay: UIColor.white.withAlphaComponent(0.3)))
            colorArray.append(baseColor.add(overlay: UIColor.white.withAlphaComponent(0.15)))
            colorArray.append(baseColor)
            colorArray.append(baseColor.add(overlay: UIColor.black.withAlphaComponent(0.15)))
            colorArray.append(baseColor.add(overlay: UIColor.black.withAlphaComponent(0.3)))
            self.setDepthColors(colorArray)
        }))
        
        alertController.addAction(Action(ActionData(title: "Space", image: UIImage(named: "circle")!.menuIcon().getCopy(withColor: UIColor(hex: "BF3436"))), style: .default, handler: { _ in
            //choose color
            var colorArray = [UIColor]()
            colorArray.append(UIColor(hex: "EF6040"))
            colorArray.append(UIColor(hex: "BF3436"))
            colorArray.append(UIColor(hex: "6C2032"))
            colorArray.append(UIColor(hex: "662132"))
            colorArray.append(UIColor(hex: "20151D"))
            self.setDepthColors(colorArray)
        }))
            
        alertController.addAction(Action(ActionData(title: "Candy", image: UIImage(named: "circle")!.menuIcon().getCopy(withColor: GMColor.blue500Color())), style: .default, handler: { _ in
            //choose color
            var colorArray = [UIColor]()
            colorArray.append(UIColor(hex: "E83F6F"))
            colorArray.append(UIColor(hex: "FF7B00"))
            colorArray.append(UIColor(hex: "FFBF00"))
            colorArray.append(UIColor(hex: "32936F"))
            colorArray.append(UIColor(hex: "2274A5"))
            self.setDepthColors(colorArray)
        }))

        alertController.addAction(Action(ActionData(title: "Spice", image: UIImage(named: "circle")!.menuIcon().getCopy(withColor: GMColor.blue500Color())), style: .default, handler: { _ in
            //choose color
            var colorArray = [UIColor]()
            colorArray.append(UIColor(hex: "4F000B"))
            colorArray.append(UIColor(hex: "720026"))
            colorArray.append(UIColor(hex: "CE4257"))
            colorArray.append(UIColor(hex: "CE4257"))
            colorArray.append(UIColor(hex: "FF9B54"))
            self.setDepthColors(colorArray)
        }))

        alertController.addAction(Action(ActionData(title: "Bright", image: UIImage(named: "circle")!.menuIcon().getCopy(withColor: GMColor.blue500Color())), style: .default, handler: { _ in
            //choose color
            var colorArray = [UIColor]()
            colorArray.append(UIColor(hex: "FFBE0B"))
            colorArray.append(UIColor(hex: "FB5607"))
            colorArray.append(UIColor(hex: "FF006E"))
            colorArray.append(UIColor(hex: "8338EC"))
            colorArray.append(UIColor(hex: "3A86FF"))
            self.setDepthColors(colorArray)
        }))

        present(alertController, animated: true, completion: nil)
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

    override func loadView() {
        super.loadView()
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Comments"
        self.tableView.separatorStyle = .none

        createCell(disableNavigationBarCell, disableNavigationBar, isOn: SettingValues.disableNavigationBar, text: "Disable comment navigation toolbar")
        createCell(fullscreenImageCell, fullscreenImage, isOn: !SettingValues.commentFullScreen, text: "Crop the submission image in commment view")
        createCell(collapseDefaultCell, collapseDefault, isOn: SettingValues.collapseDefault, text: "Collapse all comments automatically")
        createCell(swapLongPressCell, swapLongPress, isOn: SettingValues.swapLongPress, text: "Swap tap and long press actions")
        createCell(collapseFullyCell, collapseFully, isOn: SettingValues.collapseFully, text: "Collapse comments fully")
        createCell(highlightOpCell, highlightOp, isOn: SettingValues.highlightOp, text: "Highlight op replies of parent comments with a purple depth indicator")
        createCell(wideIndicatorCell, wideIndicator, isOn: SettingValues.wideIndicators, text: "Make comment depth indicator wider")
        createCell(hideAutomodCell, hideAutomod, isOn: SettingValues.hideAutomod, text: "Move top AutoModerator comment to a button (if it is not your submission)")

        updateThemeCell()
        updateDepthsCell()
        
        self.tableView.tableFooterView = UIView()
    }
    
    public func updateThemeCell() {
        authorThemeCell.textLabel?.text = "Author username color"
        authorThemeCell.textLabel?.textColor = ColorUtil.fontColor
        authorThemeCell.backgroundColor = ColorUtil.foregroundColor
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
        themeColorCell.textLabel?.textColor = ColorUtil.fontColor
        themeColorCell.backgroundColor = ColorUtil.foregroundColor
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
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
            default: fatalError("Unkown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.authorThemeCell
            case 1: return self.themeColorCell
            case 2: return self.wideIndicatorCell
            default: fatalError("Unknown row in section 1")
            }
        case 2:
            switch indexPath.row {
            case 0: return self.collapseDefaultCell
            case 1: return self.collapseFullyCell
            case 2: return self.swapLongPressCell
            case 3: return self.highlightOpCell
            default: fatalError("Unknown row in section 2")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 3
        case 2: return 4
        default: fatalError("Unknown number of sections")
        }
    }
    
}
