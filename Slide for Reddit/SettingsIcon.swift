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

private struct AlternateIcon {
    let id: String
    let title: String
    var contributor: String?
}

class SettingsIcon: BubbleSettingTableViewController {
    private let iconSections: [(id: String, title: String, iconRows: [AlternateIcon])] = [
        ("premium", "Premium icons", [
            AlternateIcon(id: "retroapple", title: "Retro"),
            AlternateIcon(id: "tronteal", title: "Tron"),
            AlternateIcon(id: "pink", title: "Pink"),
            AlternateIcon(id: "black", title: "Black"),
        ]),
        ("community", "Community icons", [
            AlternateIcon(id: "cottoncandy", title: "Cotton Candy"),
            AlternateIcon(id: "outrun", title: "Outrun"),
            AlternateIcon(id: "blackwhite", title: "Black and White", contributor: "Baselt95"),
            AlternateIcon(id: "pride", title: "Trans Pride", contributor: "Username-blank"),
            AlternateIcon(id: "space", title: "Space", contributor: "hilabius"),
            AlternateIcon(id: "stars", title: "Starry night", contributor: "TyShark"),
            AlternateIcon(id: "ghost", title: "Ghost"),
            AlternateIcon(id: "mint", title: "Mint", contributor: "Baselt95"),
            AlternateIcon(id: "garbage", title: "Garbage", contributor: "SandwichEconomist"),
        ]),
        ("basic", "Basic icons", [
            AlternateIcon(id: "default", title: "Standard"),
            AlternateIcon(id: "red", title: "Red"),
            AlternateIcon(id: "yellow", title: "Yellow"),
            AlternateIcon(id: "green", title: "Green"),
            AlternateIcon(id: "lightblue", title: "Light Blue"),
            AlternateIcon(id: "blue", title: "Blue"),
            AlternateIcon(id: "purple", title: "Purple"),
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
        view.backgroundColor = ColorUtil.theme.backgroundColor
        title = "App icon"

        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
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

        cell.configure(with: iconRow)
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

private class IconCell: InsetCell {
    private var titleLabel = UILabel()
    private var contributorLabel = UILabel()
    private var iconView = UIImageView()

    private var textStack = UIStackView().then {
        $0.axis = .vertical
    }
    
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        contentView.backgroundColor = ColorUtil.theme.foregroundColor

        contentView.addSubviews(iconView, textStack)

        iconView.sizeAnchors |==| CGSize(width: 40, height: 40)
        iconView.layer.cornerRadius = 10
        iconView.clipsToBounds = true
        iconView.leftAnchor |==| contentView.leftAnchor + 10
        iconView.centerYAnchor |==| contentView.centerYAnchor

        textStack.leftAnchor |==| iconView.rightAnchor + 8
        textStack.rightAnchor |==| contentView.rightAnchor - 10
        textStack.verticalAnchors |==| contentView.verticalAnchors + 10

        textStack.addArrangedSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .left
        titleLabel.font = FontGenerator.fontOfSize(size: 18, submission: false)
        titleLabel.textColor = ColorUtil.theme.fontColor
        titleLabel.setContentHuggingPriority(.defaultLow + 2, for: .vertical)

        textStack.addArrangedSubview(contributorLabel)
        contributorLabel.numberOfLines = 0
        contributorLabel.lineBreakMode = .byWordWrapping
        contributorLabel.textAlignment = .left
        contributorLabel.font = FontGenerator.fontOfSize(size: 14, submission: false)
        contributorLabel.textColor = ColorUtil.theme.fontColor
        contributorLabel.setContentHuggingPriority(.defaultLow + 1, for: .vertical)
    }

    func configure(with icon: AlternateIcon) {
        titleLabel.text = icon.title

        if let contributor = icon.contributor {
            contributorLabel.text = "by u/\(contributor)"
        }
        contributorLabel.isHidden = icon.contributor == nil

        iconView.image = icon.id == "default"
            ? UIImage(named: "AppIcon")
            : UIImage(named: "ic_" + icon.id)
    }
}
