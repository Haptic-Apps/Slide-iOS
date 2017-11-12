//
//  SettingsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/10/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    var general: UITableViewCell = UITableViewCell()
    var manageSubs: UITableViewCell = UITableViewCell()
    var mainTheme: UITableViewCell = UITableViewCell()
    var postLayout: UITableViewCell = UITableViewCell()
    var subThemes: UITableViewCell = UITableViewCell()
    var font: UITableViewCell = UITableViewCell()
    var comments: UITableViewCell = UITableViewCell()
    var linkHandling: UITableViewCell = UITableViewCell()
    var history: UITableViewCell = UITableViewCell()
    var dataSaving: UITableViewCell = UITableViewCell()
    var filters: UITableViewCell = UITableViewCell()
    var content: UITableViewCell = UITableViewCell()
    
    var multiColumnCell: UITableViewCell = UITableViewCell()
    var multiColumn = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(navigationController != nil){
            let close = UIButton.init(type: .custom)
            close.setImage(UIImage.init(named: "close")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
            close.addTarget(self, action: #selector(self.close(_:)), for: UIControlEvents.touchUpInside)
            close.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            let closeB = UIBarButtonItem.init(customView: close)
            self.navigationItem.rightBarButtonItem = closeB
        }

        // Do any additional setup after loading the view.
    }
    
    func close(_ sender: AnyObject){
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.splitViewController?.maximumPrimaryColumnWidth = 375
        self.splitViewController?.preferredPrimaryColumnWidthFraction = 0.5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
        navigationController?.navigationBar.tintColor = UIColor.white
        doCells()
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    override func loadView() {
        super.loadView()
    }
    
    func doCells(){
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Settings"
        
        self.general.textLabel?.text = "General"
        self.general.accessoryType = .disclosureIndicator
        self.general.backgroundColor = ColorUtil.foregroundColor
        self.general.textLabel?.textColor = ColorUtil.fontColor
        self.general.imageView?.image = UIImage.init(named: "settings")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.general.imageView?.tintColor = ColorUtil.fontColor
        
        self.manageSubs.textLabel?.text = "Manage your subreddits"
        self.manageSubs.accessoryType = .disclosureIndicator
        self.manageSubs.backgroundColor = ColorUtil.foregroundColor
        self.manageSubs.textLabel?.textColor = ColorUtil.fontColor
        self.manageSubs.imageView?.image = UIImage.init(named: "subs")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.manageSubs.imageView?.tintColor = ColorUtil.fontColor
        
        self.mainTheme.textLabel?.text = "Main theme"
        self.mainTheme.accessoryType = .disclosureIndicator
        self.mainTheme.backgroundColor = ColorUtil.foregroundColor
        self.mainTheme.textLabel?.textColor = ColorUtil.fontColor
        self.mainTheme.imageView?.image = UIImage.init(named: "colors")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.mainTheme.imageView?.tintColor = ColorUtil.fontColor
        
        self.postLayout.textLabel?.text = "Post layout"
        self.postLayout.accessoryType = .disclosureIndicator
        self.postLayout.backgroundColor = ColorUtil.foregroundColor
        self.postLayout.textLabel?.textColor = ColorUtil.fontColor
        self.postLayout.imageView?.image = UIImage.init(named: "layout")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.postLayout.imageView?.tintColor = ColorUtil.fontColor
        
        self.subThemes.textLabel?.text = "Subreddit themes"
        self.subThemes.accessoryType = .disclosureIndicator
        self.subThemes.backgroundColor = ColorUtil.foregroundColor
        self.subThemes.textLabel?.textColor = ColorUtil.fontColor
        self.subThemes.imageView?.image = UIImage.init(named: "subs")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.subThemes.imageView?.tintColor = ColorUtil.fontColor
        
        self.font.textLabel?.text = "Font"
        self.font.accessoryType = .disclosureIndicator
        self.font.backgroundColor = ColorUtil.foregroundColor
        self.font.textLabel?.textColor = ColorUtil.fontColor
        self.font.imageView?.image = UIImage.init(named: "size")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.font.imageView?.tintColor = ColorUtil.fontColor
        
        self.comments.textLabel?.text = "Comments"
        self.comments.accessoryType = .disclosureIndicator
        self.comments.backgroundColor = ColorUtil.foregroundColor
        self.comments.textLabel?.textColor = ColorUtil.fontColor
        self.comments.imageView?.image = UIImage.init(named: "comments")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.comments.imageView?.tintColor = ColorUtil.fontColor
        
        self.linkHandling.textLabel?.text = "Link handling"
        self.linkHandling.accessoryType = .disclosureIndicator
        self.linkHandling.backgroundColor = ColorUtil.foregroundColor
        self.linkHandling.textLabel?.textColor = ColorUtil.fontColor
        self.linkHandling.imageView?.image = UIImage.init(named: "link")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.linkHandling.imageView?.tintColor = ColorUtil.fontColor
        
        self.history.textLabel?.text = "History"
        self.history.accessoryType = .disclosureIndicator
        self.history.backgroundColor = ColorUtil.foregroundColor
        self.history.textLabel?.textColor = ColorUtil.fontColor
        self.history.imageView?.image = UIImage.init(named: "history")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.history.imageView?.tintColor = ColorUtil.fontColor
        
        self.dataSaving.textLabel?.text = "Data saving"
        self.dataSaving.accessoryType = .disclosureIndicator
        self.dataSaving.backgroundColor = ColorUtil.foregroundColor
        self.dataSaving.textLabel?.textColor = ColorUtil.fontColor
        self.dataSaving.imageView?.image = UIImage.init(named: "data")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.dataSaving.imageView?.tintColor = ColorUtil.fontColor
        
        self.content.textLabel?.text = "Content"
        self.content.accessoryType = .disclosureIndicator
        self.content.backgroundColor = ColorUtil.foregroundColor
        self.content.textLabel?.textColor = ColorUtil.fontColor
        self.content.imageView?.image = UIImage.init(named: "image")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.content.imageView?.tintColor = ColorUtil.fontColor

        self.filters.textLabel?.text = "Filters"
        self.filters.accessoryType = .disclosureIndicator
        self.filters.backgroundColor = ColorUtil.foregroundColor
        self.filters.textLabel?.textColor = ColorUtil.fontColor
        self.filters.imageView?.image = UIImage.init(named: "filter")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)
        self.filters.imageView?.tintColor = ColorUtil.fontColor
        
        multiColumn = UISwitch()
        multiColumn.isOn = SettingValues.multiColumn
        multiColumn.addTarget(self, action: #selector(SettingsViewController.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        multiColumnCell.textLabel?.text = "Multi Column mode"
        multiColumnCell.accessoryView = multiColumn
        multiColumnCell.backgroundColor = ColorUtil.foregroundColor
        multiColumnCell.textLabel?.textColor = ColorUtil.fontColor
        multiColumnCell.selectionStyle = UITableViewCellSelectionStyle.none
        self.multiColumnCell.imageView?.image = UIImage.init(named: "multi")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withRenderingMode(.alwaysTemplate)

        
        self.tableView.reloadData(with: .none)
        if(self.view.frame.size.width > 1000 && UIScreen.main.traitCollection.userInterfaceIdiom == .pad){
        self.tableView(tableView, didSelectRowAt: IndexPath.init(row: 0, section: 0))
        }
    }
    
    func switchIsChanged(_ changed: UISwitch) {
        if(changed == multiColumn){
            SettingValues.multiColumn = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_multiColumn)
        }
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
        switch(indexPath.section) {
        case 0:
            switch(indexPath.row) {
            case 0: return self.general
            case 1: return self.manageSubs
            case 2: return self.multiColumnCell
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch(indexPath.row) {
            case 0: return self.mainTheme
            case 1: return self.postLayout
            case 2: return self.subThemes
            case 3: return self.font
            case 4: return self.comments
            default: fatalError("Unknown row in section 1")
            }
        case 2:
            switch(indexPath.row){
            case 0: return self.linkHandling
            case 1: return self.history
            case 2: return self.dataSaving
            case 3: return self.content
            case 4: return self.filters
            default: fatalError("Unknown row in section 2")
            }
        default: fatalError("Unknown section")
        }

    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var ch : UIViewController?
        if(indexPath.section == 0 && indexPath.row == 1){
ch = SubredditReorderViewController()
        } else  if(indexPath.section == 0 && indexPath.row == 0){
ch = SettingsGeneral()
        } else if(indexPath.section == 2 && indexPath.row == 4){
ch = FiltersViewController()
        } else if(indexPath.section == 1 && indexPath.row == 2){
ch = SubredditThemeViewController()
        }  else if(indexPath.section == 1 && indexPath.row == 0){
ch = SettingsTheme()
        }  else if(indexPath.section == 1 && indexPath.row == 3){
ch = SettingsFont()
        }  else if(indexPath.section == 1 && indexPath.row == 1){
ch = SettingsLayout()
        }  else if(indexPath.section == 2 && indexPath.row == 2){
ch = SettingsData()
        }  else if(indexPath.section == 2 && indexPath.row == 3){
ch = SettingsContent()
        }  else if(indexPath.section == 1 && indexPath.row == 4){
            ch = SettingsComments()
        }  else if(indexPath.section == 2 && indexPath.row == 0){
            ch = SettingsLinkHandling()
        }  else if(indexPath.section == 2 && indexPath.row == 1){
            ch = SettingsHistory()
        }
        if let n = ch {
            if(self.navigationController != nil){
             self.navigationController?.pushViewController(n, animated: true)
            } else {
                splitViewController?.showDetailViewController(n, sender: self)
            }
        }
    }
    /* maybe future
 override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cornerRadius : CGFloat = 12.0
        cell.backgroundColor = UIColor.clear
        var layer: CAShapeLayer = CAShapeLayer()
        var pathRef:CGMutablePath = CGMutablePath()
        var bounds: CGRect = cell.bounds.insetBy(dx: 25, dy: 0)
        var addLine: Bool = false
        
        if (indexPath.row == 0 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1) {
            pathRef.__addRoundedRect(transform: nil, rect: bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        } else if (indexPath.row == 0) {
            pathRef.move(to: CGPoint.init(x: bounds.minX, y: bounds.maxY))
            pathRef.addArc(center: CGPoint.init(x: bounds.minX, y: bounds.maxY), radius: bounds.midX, startAngle: bounds.minY, endAngle: cornerRadius, clockwise: false)
            pathRef.addArc(center: CGPoint.init(x: bounds.maxX, y: bounds.minY), radius: bounds.maxX, startAngle: bounds.midY, endAngle: cornerRadius, clockwise: false)
            pathRef.addLine(to: CGPoint.init(x: bounds.maxX, y: bounds.maxY))
            addLine = true
        } else if (indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1) {
            pathRef.move(to: CGPoint.init(x: bounds.minX, y: bounds.maxY))
            pathRef.addArc(center: CGPoint.init(x: bounds.minX, y: bounds.maxY), radius: bounds.midX, startAngle: bounds.maxY, endAngle: cornerRadius, clockwise: false)
            pathRef.addArc(center: CGPoint.init(x: bounds.maxX, y: bounds.maxY), radius: bounds.maxX, startAngle: bounds.midY, endAngle: cornerRadius, clockwise: false)
            pathRef.addLine(to: CGPoint.init(x: bounds.maxX, y: bounds.minY))
        } else {
            pathRef.addRect(bounds)
            addLine = true
        }
        
        layer.path = pathRef
        layer.fillColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 0.8).cgColor
        
        if (addLine == true) {
            var lineLayer: CALayer = CALayer()
            var lineHeight: CGFloat = (1.0 / UIScreen.main.scale)
            lineLayer.frame = CGRect.init(x: bounds.minX+10, y:  bounds.size.height-lineHeight, width: bounds.size.width-10, height: lineHeight)
            lineLayer.backgroundColor = tableView.separatorColor?.cgColor
            layer.addSublayer(lineLayer)
        }
        var testView: UIView = UIView(frame: bounds)
        testView.layer.insertSublayer(layer, at: 0)
        testView.backgroundColor = UIColor.clear
        cell.backgroundView = testView

    }*/
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label : UILabel = UILabel()
        label.textColor = ColorUtil.fontColor
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor

        switch(section) {
        case 0: label.text = "General"
            break
        case 1: label.text =  "Appearance"
            break
        case 2: label.text = "Content"
            break
        default: label.text  = ""
            break
        }
        return toReturn
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return 3    // section 0 has 2 rows
        case 1: return 5    // section 1 has 1 row
        case 2: return 5
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
