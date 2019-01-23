//
//  SettingsMainTheme.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import Then
import UIKit

class SettingsMainTheme: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        UserDefaults.standard.set(true, forKey: "2notifs")
        UserDefaults.standard.synchronize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight() && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }
    
    func doLayout() {
        setupBaseBarColors()
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        
        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.setImage(UIImage.init(named: "back")!.navIcon(), for: UIControl.State.normal)
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
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Main Theme"
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
        let theme = ColorUtil.Theme.cases[indexPath.row]
        cell.setTheme(theme: theme)
        if theme == ColorUtil.theme {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let theme = ColorUtil.Theme.cases[indexPath.row]
        UserDefaults.standard.set(theme.rawValue, forKey: "theme")
        UserDefaults.standard.synchronize()
        _ = ColorUtil.doInit()
        SubredditReorderViewController.changed = true
        self.tableView.reloadData(with: .automatic)
        MainViewController.needsRestart = true
        doLayout()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return ColorUtil.Theme.cases.count
    }
    
}
class ThemeCellView: UITableViewCell {
    
    var icon = UIImageView()
    var title: UILabel = UILabel()
    
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
        
        self.title = UILabel().then {
            $0.numberOfLines = 0
            $0.font = UIFont.systemFont(ofSize: 16)
        }
        
        self.icon = UIImageView().then {
            $0.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
            $0.isHidden = false
            $0.contentMode = .center
        }
        
        self.contentView.addSubviews(title, icon)
    }
    
    func configureLayout() {
        batch {
            icon.leftAnchor == contentView.leftAnchor + 2
            icon.sizeAnchors == CGSize.square(size: 60)
            icon.centerYAnchor == contentView.centerYAnchor
            
            title.leftAnchor == icon.rightAnchor
            title.centerYAnchor == contentView.centerYAnchor
        }
    }
    
    func setTheme(theme: ColorUtil.Theme) {
        title.textColor = theme.fontColor
        title.text = theme.displayName
        icon.image = UIImage(named: "colors")!.getCopy(withSize: CGSize.square(size: 20), withColor: theme.navIconColor)
        contentView.backgroundColor = theme.foregroundColor
        self.backgroundColor = theme.foregroundColor
        self.tintColor = theme.navIconColor
    }
}
