//
//  SettingsThemeChooser.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//
import Anchorage
import Then
import UIKit

class SettingsThemeChooser: UITableViewController {
    
    var callback: ((ColorUtil.Theme) -> Void)?
    var nightOnly: Bool = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }
    
    func doLayout() {
        setupBaseBarColors()
        
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        
        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.setImage(UIImage(sfString: SFSymbol.chevronLeft, overrideString: "back")!.navIcon(), for: UIControl.State.normal)
        button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        
        let barButton = UIBarButtonItem.init(customView: button)
        
        navigationItem.leftBarButtonItem = barButton
    }
    
    @objc public func handleBackButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func loadView() {
        super.loadView()
        
        self.themes = ColorUtil.themes.filter({ (theme) -> Bool in
            return !theme.isLight || !nightOnly
        })
        
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        self.title = "Choose a \(nightOnly ? "Night" : "") Theme"
        self.tableView.separatorStyle = .none
        self.tableView.tableFooterView = UIView()
        self.tableView.register(ThemeCellView.classForCoder(), forCellReuseIdentifier: "theme")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "theme") as! ThemeCellView
        let theme = themes[indexPath.row]
        cell.setTheme(theme: theme)
        return cell
    }
    
    var themes: [ColorUtil.Theme] = []
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true) {
            if self.nightOnly {
                self.callback?(self.themes[indexPath.row])
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return themes.count
    }
    
}
class ThemeCellView: UITableViewCell {
    
    var icon = UIImageView()
    var title: UILabel = UILabel()
    var body = UIView()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureViews()
        configureLayout()
    }
    
    func configureViews() {
        self.clipsToBounds = true
        
        self.body = UIView().then {
            $0.layer.cornerRadius = 22
            $0.clipsToBounds = true
        }
        
        self.title = UILabel().then {
            $0.numberOfLines = 0
            $0.font = UIFont.systemFont(ofSize: 16)
        }
        
        self.icon = UIImageView().then {
            $0.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
            $0.isHidden = false
            $0.contentMode = .center
        }
        self.contentView.addSubview(body)
        self.body.addSubviews(title, icon)
    }
    
    func configureLayout() {
        batch {
            body.leftAnchor /==/ contentView.leftAnchor + 8
            body.rightAnchor /==/ contentView.rightAnchor - 8
            body.topAnchor /==/ contentView.topAnchor + 8
            body.bottomAnchor /==/ contentView.bottomAnchor - 8
            
            icon.leftAnchor /==/ body.leftAnchor + 2
            icon.sizeAnchors /==/ CGSize.square(size: 60)
            icon.centerYAnchor /==/ body.centerYAnchor
            
            title.leftAnchor /==/ icon.rightAnchor
            title.centerYAnchor /==/ body.centerYAnchor
        }
    }
    
    func setTheme(string: String) {
        let colors = UserDefaults.standard.string(forKey: string)!.removingPercentEncoding!
        let split = colors.split("#")
        
        title.textColor = UIColor(hexString: split[4])
        title.text = (split[1].removingPercentEncoding ?? split[1]).replacingOccurrences(of: "<H>", with: "#")
        icon.image = UIImage(named: "colors")!.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor(hexString: split[5]))
        body.backgroundColor = UIColor(hexString: split[2])
        self.backgroundColor = ColorUtil.theme.backgroundColor
        self.tintColor = UIColor(hexString: split[5])
    }
    
    func setTheme(colors: String) {
        let split = colors.split("#")
        
        title.textColor = UIColor(hexString: split[4])
        title.text = (split[1].removingPercentEncoding ?? split[1]).replacingOccurrences(of: "<H>", with: "#")
        icon.image = UIImage(named: "colors")!.getCopy(withSize: CGSize.square(size: 20), withColor: UIColor(hexString: split[5]))
        body.backgroundColor = UIColor(hexString: split[2])
        self.backgroundColor = ColorUtil.theme.backgroundColor
        self.tintColor = UIColor(hexString: split[5])
    }
    
    func setTheme(theme: ColorUtil.Theme) {
        title.textColor = theme.fontColor
        title.text = theme.displayName
        icon.image = UIImage(named: "colors")!.getCopy(withSize: CGSize.square(size: 20), withColor: theme.navIconColor)
        body.backgroundColor = theme.foregroundColor
        self.backgroundColor = ColorUtil.theme.backgroundColor
        self.tintColor = theme.navIconColor
    }
}
