//
//  SettingsIcon.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/8/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import UIKit

class SettingsIcon: UITableViewController {
    
    var premium = ["retroapple", "tronteal", "pink", "black"]
    var community = ["cottoncandy", "outrun", "default", "stars", "blue", "mint", "green", "lightblue", "purple", "red", "yellow"]
    
    var premiumNames = ["Retro", "Tron", "Pink", "Black"]
    var communityNames = ["Cotton Candy", "Outrun", "Standard", "Starry night u/TyShark", "Blue", "Mint u/Baselt95", "Green", "Light Blue", "Purple", "Red", "Yellow"]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(IconCell.classForCoder(), forCellReuseIdentifier: "icon")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        
        switch section {
        case 0: label.text  = "Premium icons"
        case 1: label.text  = "Community icons"
        default: label.text  = ""
        }
        return toReturn
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Icon"
        self.tableView.separatorStyle = .none
        
        doChecks()
        self.tableView.tableFooterView = UIView()
    }
    
    func doChecks() {
       
        //todo accessory view
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "icon") as! IconCell
        
        let title = indexPath.section == 0 ? premiumNames[indexPath.row] : communityNames[indexPath.row]
        cell.title.text = title
        
        let isDefault = indexPath.row == 2 && indexPath.section == 1
        
        cell.iconView.image = isDefault ? UIImage(named: "AppIcon") : UIImage(named: "ic_" + (indexPath.section == 0 ? premium[indexPath.row] : community[indexPath.row]))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let title = indexPath.section == 0 ? premium[indexPath.row] : community[indexPath.row]
        let isDefault = indexPath.row == 2 && indexPath.section == 1

        if indexPath.section == 1 || !VCPresenter.proDialogShown(feature: true, self) {
            if #available(iOS 10.3, *) {
                if isDefault {
                    UIApplication.shared.setAlternateIconName(nil) { (error) in
                        if let error = error {
                            print("err: \(error)")
                        }
                    }
                } else {
                    UIApplication.shared.setAlternateIconName(title) { (error) in
                        if let error = error {
                            print("err: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return premium.count    // section 0 has 2 rows
        case 1: return community.count    // section 1 has 1 row
        default: fatalError("Unknown number of sections")
        }
    }
    
}

public class IconCell: UITableViewCell {
    var title = UILabel()
    var iconView = UIImageView()
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        self.contentView.addSubviews(title, iconView)
        
        title.heightAnchor == 60
        title.rightAnchor == self.contentView.rightAnchor
        title.leftAnchor == self.iconView.rightAnchor + 8
        title.topAnchor == self.contentView.topAnchor + 10
        title.bottomAnchor == self.contentView.bottomAnchor - 10
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        title.textAlignment = .left
        title.textColor = ColorUtil.fontColor
        
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        
        iconView.heightAnchor == 40
        iconView.widthAnchor == 40
        iconView.layer.cornerRadius = 10
        iconView.clipsToBounds = true
        iconView.leftAnchor == self.contentView.leftAnchor + 10
        iconView.topAnchor == self.contentView.topAnchor + 10
        iconView.bottomAnchor == self.contentView.bottomAnchor - 10
    }
}
