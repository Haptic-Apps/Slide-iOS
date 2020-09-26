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
            ("blackwhite", "Black and White u/Baselt95"),
            ("pride", "Trans Pride u/Username-blank"),
            ("space", "Space u/hilabius"),
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
    
    var howToCell: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(IconCell.classForCoder(), forCellReuseIdentifier: "icon")
        
        self.howToCell.textLabel?.text = "Want to see your icon design in Slide?"
        self.howToCell.detailTextLabel?.text = "Click here for more info"
        self.howToCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.howToCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.howToCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.howToCell.imageView?.image = UIImage.init(sfString: SFSymbol.infoCircle, overrideString: "download")?.toolbarIcon().getCopy(withColor: ColorUtil.theme.fontColor)
        self.howToCell.imageView?.tintColor = ColorUtil.theme.fontColor
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
        if indexPath.row == iconSections[indexPath.section].iconRows.count && indexPath.section == 1 {
            return howToCell
        }
        
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
        if indexPath.section == 1 && indexPath.row == iconSections[indexPath.section].iconRows.count {
            VCPresenter.openRedditLink("https://www.reddit.com/r/slide_ios/comments/a6kcp0/alt_icons_share_your_creativity/", self.navigationController, self)
            return
        }
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
        return iconSections[section].iconRows.count + (section == 1 ? 1 : 0)
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
