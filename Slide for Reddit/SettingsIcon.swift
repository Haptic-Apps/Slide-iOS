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

class SettingsIcon: BubbleSettingTableViewController {
    let iconSections: [(id: String, title: String, iconRows: [(id: String, title: String)])] = [
        ("premium", "Premium icons", [
            ("retroapple", "Retro"),
            ("tronteal", "Tron"),
            ("pink", "Pink"),
            ("black", "Black"),
        ]),
        ("community", "Community icons", [
            ("cottoncandy", "Cotton Candy"),
            ("outrun", "Outrun"),
            ("stars", "Starry night u/TyShark"),
            ("ghost", "Ghost"),
            ("mint", "Mint u/Baselt95"),
        ]),
        ("basic", "Basic icons", [
            ("red", "Red"),
            ("default", "Standard"),
            ("yellow", "Yellow"),
            ("green", "Green"),
            ("lightblue", "Light Blue"),
            ("blue", "Blue"),
            ("purple", "Purple"),
        ]),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(IconCell.classForCoder(), forCellReuseIdentifier: "icon")
    }
    
    override func loadView() {
        super.loadView()
        
        headers = iconSections.map({ $0.title })
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        self.title = "App icon"

        self.tableView.tableFooterView = UIView()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return iconSections.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "icon") as! IconCell
        let iconSection = iconSections[indexPath.section]
        let iconRow = iconSection.iconRows[indexPath.row]
        
        cell.title.text = iconRow.title
        cell.iconView.image = iconRow.id == "default"
            ? UIImage(named: "AppIcon")
            : UIImage(named: "ic_" + iconRow.id)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let iconSection = iconSections[indexPath.section]
        let iconRow = iconSection.iconRows[indexPath.row]
        
        if iconSection.id != "premium" || !VCPresenter.proDialogShown(feature: true, self) {
            if #available(iOS 10.3, *) {
                UIApplication.shared.setAlternateIconName(
                    iconRow.id == "default"
                        ? nil
                        : iconRow.id
                ) { (error) in
                    if let error = error {
                        print("err: \(error)")
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return iconSections[section].iconRows.count
    }
}

public class IconCell: InsetCell {
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
        title.textColor = ColorUtil.theme.fontColor
        
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
        
        iconView.heightAnchor == 40
        iconView.widthAnchor == 40
        iconView.layer.cornerRadius = 10
        iconView.clipsToBounds = true
        iconView.leftAnchor == self.contentView.leftAnchor + 10
        iconView.topAnchor == self.contentView.topAnchor + 10
        iconView.bottomAnchor == self.contentView.bottomAnchor - 10
    }
}
