//
//  SettingsGestures.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/22/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import XLActionController

class SettingsGestures: UITableViewController {
    
    var doubleSwipeCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "double")
    var doubleSwipe = UISwitch()
    
    var leftActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "left")

    var rightActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "right")

    var doubleTapActionCell: UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "dtap")

    override func viewDidLoad() {
        super.viewDidLoad()
        updateCells()
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
        if(changed == doubleSwipe){
            SettingValues.commentTwoSwipe = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_commentTwoSwipe)
        }
        UserDefaults.standard.synchronize()
        updateCells()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label : UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        
        switch(section) {
        case 0: label.text  = "Comments"
            break
        case 1: label.text  = "Submissions"
            break
        default: label.text  = ""
            break
        }
        return toReturn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if(indexPath.row == 1){
            showAction(cell: rightActionCell)
        } else if(indexPath.row == 2){
            showAction(cell: leftActionCell)
        } else if(indexPath.row == 3){
            showAction(cell: doubleTapActionCell)
        }
    }
    
    func showAction(cell: UITableViewCell){
        let alertController: BottomSheetActionController = BottomSheetActionController()
        for action in SettingValues.CommentAction.cases{
            alertController.addAction(Action(ActionData(title: action.getTitle(), image: UIImage(named: action.getPhoto())!.menuIcon()), style: .default, handler: { action2 in
                UserDefaults.standard.set(action.rawValue, forKey: cell == self.rightActionCell ? SettingValues.pref_commentActionRight : (cell == self.leftActionCell ? SettingValues.pref_commentActionLeft : SettingValues.pref_commentActionDoubleTap))
                if(cell == self.rightActionCell){
                    SettingValues.commentActionRight = action
                } else if(cell == self.leftActionCell){
                    SettingValues.commentActionLeft = action
                } else {
                    SettingValues.commentActionDoubleTap = action
                }
                UserDefaults.standard.synchronize()
                self.updateCells()
            }))
        }
        VCPresenter.presentAlert(alertController, parentVC: self)
    }
    
    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String){
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
        self.title = "Gestures"
        self.tableView.separatorStyle = .none
        
        createCell(doubleSwipeCell, doubleSwipe, isOn: SettingValues.commentTwoSwipe, text: "Double finger swipe to go through comments")
        self.doubleSwipeCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.doubleSwipeCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.doubleSwipeCell.detailTextLabel?.numberOfLines = 0
        self.doubleSwipeCell.detailTextLabel?.text = "Turning this off enables single finger swipe mode, which will disable comment swipe gestures"
        updateCells()
        self.tableView.tableFooterView = UIView()
    }
    
    func updateCells(){
        createCell(rightActionCell, nil, isOn: false, text: "First right swipe button")
        createCell(leftActionCell, nil, isOn: false, text: "Second right swipe button (also triggered by a long swipe)")
        createCell(doubleTapActionCell, nil, isOn: false, text: "Double tap comment action")

        createLeftView(cell: doubleSwipeCell, image: "twofinger", color: ColorUtil.foregroundColor)
        
        createLeftView(cell: rightActionCell, image: SettingValues.commentActionRight.getPhoto(), color: SettingValues.commentActionRight.getColor())
        self.rightActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.rightActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.rightActionCell.detailTextLabel?.numberOfLines = 0
        self.rightActionCell.detailTextLabel?.text = SettingValues.commentActionRight.getTitle()
        self.rightActionCell.imageView?.cornerRadius = 5

        createLeftView(cell: leftActionCell, image: SettingValues.commentActionLeft.getPhoto(), color: SettingValues.commentActionLeft.getColor())
        self.leftActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.leftActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.leftActionCell.detailTextLabel?.numberOfLines = 0
        self.leftActionCell.detailTextLabel?.text = SettingValues.commentActionLeft.getTitle()
        self.leftActionCell.imageView?.cornerRadius = 5

        createLeftView(cell: doubleTapActionCell, image: SettingValues.commentActionDoubleTap.getPhoto(), color: SettingValues.commentActionDoubleTap.getColor())
        self.doubleTapActionCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.doubleTapActionCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.doubleTapActionCell.detailTextLabel?.numberOfLines = 0
        self.doubleTapActionCell.detailTextLabel?.text = SettingValues.commentActionDoubleTap.getTitle()
        self.doubleTapActionCell.imageView?.cornerRadius = 5

        if(!SettingValues.commentTwoSwipe){
            self.rightActionCell.isUserInteractionEnabled = false
            self.rightActionCell.alpha = 0.5
            self.leftActionCell.isUserInteractionEnabled = false
            self.leftActionCell.alpha = 0.5
        } else {
            self.rightActionCell.isUserInteractionEnabled = true
            self.rightActionCell.alpha = 1
            self.leftActionCell.isUserInteractionEnabled = true
            self.leftActionCell.alpha = 1
        }

    }
    
    func createLeftView(cell: UITableViewCell, image: String, color: UIColor) {
        cell.imageView?.image = UIImage.init(named: image)?.navIcon()
        cell.imageView?.backgroundColor = color
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(section == 0){
            return 0
        }
        return 70
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch(indexPath.section) {
        case 0:
            switch(indexPath.row) {
            case 0: return self.doubleSwipeCell
            case 1: return self.rightActionCell
            case 2: return self.leftActionCell
            case 3: return self.doubleTapActionCell
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return 4
        default: fatalError("Unknown number of sections")
        }
    }
    
    
}
