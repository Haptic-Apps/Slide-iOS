//
//  SettingsPro.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/07/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import BiometricAuthentication
import LicensesViewController
import SDWebImage
import MaterialComponents.MaterialSnackbar
import RealmSwift
import RLBAlertsPickers

class SettingsProCustomization: UITableViewController {

    var night: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "night")
    var username: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "username")
    var custom: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "custom")
    var themes: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "themes")

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.setToolbarHidden(true, animated: false)
    }

    override func loadView() {
        super.loadView()
        doCells()
    }

    func doCells(_ reset: Bool = true) {
        self.view.backgroundColor = ColorUtil.backgroundColor
        self.title = "Pro Customization Pack"

        var three = UILabel(frame: CGRect.init(x:  (self.tableView.frame.size.width / 4) - 50, y: 140, width: 100, height: 45))
        three.text = "$2.99"
        three.backgroundColor = GMColor.lightGreen300Color()
        three.layer.cornerRadius = 22.5
        three.clipsToBounds = true
        three.textColor = .white
        three.font = UIFont.boldSystemFont(ofSize: 20)
        three.textAlignment = .center


        var six = UILabel(frame: CGRect.init(x:  (self.tableView.frame.size.width / 4) - 50, y: 140, width: 100, height: 45))
        six.text = "$4.99"
        six.backgroundColor = GMColor.lightBlue300Color()
        six.layer.cornerRadius = 22.5
        six.clipsToBounds = true
        six.textColor = .white
        six.font = UIFont.boldSystemFont(ofSize: 20)
        six.textAlignment = .center


        self.night.textLabel?.text = "Auto night mode"
        self.night.detailTextLabel?.text = "Select a custom night theme and night hours, Slide does the rest"
        self.night.backgroundColor = ColorUtil.foregroundColor
        self.night.textLabel?.textColor = ColorUtil.fontColor
        self.night.imageView?.image = UIImage.init(named: "night")?.toolbarIcon()
        self.night.imageView?.tintColor = ColorUtil.fontColor

        self.username.textLabel?.text = "Username scrubbing"
        self.username.detailTextLabel?.text = "Keep your account names a secret"
        self.username.backgroundColor = ColorUtil.foregroundColor
        self.username.textLabel?.textColor = ColorUtil.fontColor
        self.username.imageView?.image = UIImage.init(named: "hide")?.toolbarIcon()
        self.username.imageView?.tintColor = ColorUtil.fontColor

        self.custom.textLabel?.text = "Custom theme colors"
        self.custom.detailTextLabel?.text = "Choose a custom color for your themes"
        self.custom.backgroundColor = ColorUtil.foregroundColor
        self.custom.textLabel?.textColor = ColorUtil.fontColor
        self.custom.imageView?.image = UIImage.init(named: "accent")?.toolbarIcon()
        self.custom.imageView?.tintColor = ColorUtil.fontColor

        self.themes.textLabel?.text = "More base themes"
        self.themes.detailTextLabel?.text = "Unlocks AMOLED, Sepia, and Deep themes"
        self.themes.backgroundColor = .black
        self.themes.textLabel?.textColor = .white
        self.themes.imageView?.image = UIImage.init(named: "colors")?.toolbarIcon().withColor(tintColor: .white)
        self.themes.imageView?.tintColor = .white

        var purchasePro = UILabel(frame: CGRect.init(x:  0, y: -30, width: (self.view.frame.size.width / 2), height: 200))
        purchasePro.backgroundColor = ColorUtil.foregroundColor
        purchasePro.text = "Purchase\nPro Customization Pack"
        purchasePro.textAlignment = .center
        purchasePro.textColor = ColorUtil.fontColor
        purchasePro.font = UIFont.boldSystemFont(ofSize: 18)
        purchasePro.numberOfLines = 0
        purchasePro.addSubview(three)

        var purchaseBundle = UILabel(frame: CGRect.init(x:  (self.view.frame.size.width / 2), y: -30, width: (self.view.frame.size.width / 2), height: 200))
        purchaseBundle.backgroundColor = ColorUtil.foregroundColor
        purchaseBundle.text = "Purchase\nPro Bundle"
        purchaseBundle.textAlignment = .center
        purchaseBundle.textColor = ColorUtil.fontColor
        purchaseBundle.numberOfLines = 0
        purchaseBundle.font = UIFont.boldSystemFont(ofSize: 18)
        purchaseBundle.addSubview(six)


        var about = UIView(frame: CGRect.init(x:  0, y: 0, width: self.tableView.frame.size.width, height: 200))
        about.addSubview(purchasePro)
        about.addSubview(purchaseBundle)
        about.backgroundColor = ColorUtil.foregroundColor
        tableView.tableHeaderView = about

    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 70
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }


    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
            case 0: return self.night
            case 1: return self.themes
            case 2: return self.custom
            case 3: return self.username

            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor

        switch (section) {
        case 0: label.text = "General"
            break
        case 1: label.text = "Already a Slide supporter?"
            break
        default: label.text = ""
            break
        }
        return toReturn
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0: return 4
        default: fatalError("Unknown number of sections")
        }
    }

}
