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

class SettingsPro: UITableViewController {

    var restore: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "restore")
    var shadowbox: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "shadow")
    var gallery: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "gallery")
    var biometric: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "bio")
    var multicolumn: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "multi")
    var autocache: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "auto")
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
        // set the title
        self.title = "Support Slide for Reddit!"

        self.night.textLabel?.text = "Auto night mode"
        self.night.detailTextLabel?.text = "Select a custom night theme and night hours, Slide does the rest"
        self.night.backgroundColor = ColorUtil.foregroundColor
        self.night.textLabel?.textColor = ColorUtil.fontColor
        self.night.imageView?.image = UIImage.init(named: "night")?.toolbarIcon()
        self.night.imageView?.tintColor = ColorUtil.fontColor
        self.night.detailTextLabel?.textColor = ColorUtil.fontColor
        
        self.username.textLabel?.text = "Username scrubbing"
        self.username.detailTextLabel?.text = "Keep your account names a secret"
        self.username.backgroundColor = ColorUtil.foregroundColor
        self.username.textLabel?.textColor = ColorUtil.fontColor
        self.username.imageView?.image = UIImage.init(named: "hide")?.toolbarIcon()
        self.username.imageView?.tintColor = ColorUtil.fontColor
        self.username.detailTextLabel?.textColor = ColorUtil.fontColor
        
        self.custom.textLabel?.text = "Custom theme colors"
        self.custom.detailTextLabel?.text = "Choose a custom color for your themes"
        self.custom.backgroundColor = ColorUtil.foregroundColor
        self.custom.detailTextLabel?.textColor = ColorUtil.fontColor
        self.custom.textLabel?.textColor = ColorUtil.fontColor
        self.custom.imageView?.image = UIImage.init(named: "accent")?.toolbarIcon()
        self.custom.imageView?.tintColor = ColorUtil.fontColor
        
        self.themes.textLabel?.text = "More base themes"
        self.themes.detailTextLabel?.text = "Unlocks AMOLED, Sepia, and Deep themes"
        self.themes.backgroundColor = .black
        self.themes.detailTextLabel?.textColor = .white
        self.themes.textLabel?.textColor = .white
        self.themes.imageView?.image = UIImage.init(named: "colors")?.toolbarIcon().withColor(tintColor: .white)
        self.themes.imageView?.tintColor = .white
        
        self.restore.textLabel?.text = "Already a supporter?"
        self.restore.accessoryType = .disclosureIndicator
        self.restore.backgroundColor = ColorUtil.foregroundColor
        self.restore.textLabel?.textColor = GMColor.lightGreen300Color()
        self.restore.imageView?.image = UIImage.init(named: "restore")?.toolbarIcon().withColor(tintColor: GMColor.lightGreen300Color())
        self.restore.imageView?.tintColor = GMColor.lightGreen300Color()
        self.restore.detailTextLabel?.textColor = GMColor.lightGreen300Color()
        self.restore.detailTextLabel?.text = "Restore your purchase!"

        
        var about = PaddingLabel(frame: CGRect.init(x:  0, y: 200, width: self.tableView.frame.size.width, height: 30))
        about.font = UIFont.systemFont(ofSize: 16)
        about.backgroundColor = ColorUtil.foregroundColor
        about.textColor = ColorUtil.fontColor
        about.text = "Upgrade to Slide Pro to enjoy awesome new features while supporting ad-free and open source software!\n\nI'm an indie software developer currently studying at university, and every donation helps keep Slide going :)\n\n\n\n"
        about.numberOfLines = 0
        about.textAlignment = .center
        about.lineBreakMode = .byClipping
        about.sizeToFit()
        var three = UILabel(frame: CGRect.init(x:  (self.tableView.frame.size.width / 4) - 50, y: 140, width: 100, height: 45))
        three.text = "$4.99"
        three.backgroundColor = GMColor.lightGreen300Color()
        three.layer.cornerRadius = 22.5
        three.clipsToBounds = true
        three.textColor = .white
        three.font = UIFont.boldSystemFont(ofSize: 20)
        three.textAlignment = .center
        
        
        var six = UILabel(frame: CGRect.init(x:  (self.tableView.frame.size.width / 4) - 50, y: 140, width: 100, height: 45))
        six.text = "$7.99"
        six.backgroundColor = GMColor.lightBlue300Color()
        six.layer.cornerRadius = 22.5
        six.clipsToBounds = true
        six.textColor = .white
        six.font = UIFont.boldSystemFont(ofSize: 20)
        six.textAlignment = .center
        
        
        self.shadowbox.textLabel?.text = "Shadowbox mode"
        self.shadowbox.detailTextLabel?.text = "View your favorite subreddits distraction free"
        self.shadowbox.backgroundColor = ColorUtil.foregroundColor
        self.shadowbox.textLabel?.textColor = ColorUtil.fontColor
        self.shadowbox.imageView?.image = UIImage.init(named: "shadowbox")?.toolbarIcon()
        self.shadowbox.imageView?.tintColor = ColorUtil.fontColor
        self.shadowbox.detailTextLabel?.textColor = ColorUtil.fontColor
        
        self.gallery.textLabel?.text = "Gallery mode"
        self.gallery.detailTextLabel?.text = "r/pics never looked better"
        self.gallery.backgroundColor = ColorUtil.foregroundColor
        self.gallery.textLabel?.textColor = ColorUtil.fontColor
        self.gallery.imageView?.image = UIImage.init(named: "image")?.toolbarIcon()
        self.gallery.imageView?.tintColor = ColorUtil.fontColor
        self.gallery.detailTextLabel?.textColor = ColorUtil.fontColor
        
        self.biometric.textLabel?.text = "Biometric lock"
        self.biometric.detailTextLabel?.text = "Keep your Reddit content safe"
        self.biometric.backgroundColor = ColorUtil.foregroundColor
        self.biometric.textLabel?.textColor = ColorUtil.fontColor
        self.biometric.imageView?.image = UIImage.init(named: "lockapp")?.toolbarIcon()
        self.biometric.imageView?.tintColor = ColorUtil.fontColor
        self.biometric.detailTextLabel?.textColor = ColorUtil.fontColor
        
        self.multicolumn.textLabel?.text = "Multicolumn mode"
        self.multicolumn.detailTextLabel?.text = "A must-have for iPads!"
        self.multicolumn.backgroundColor = ColorUtil.foregroundColor
        self.multicolumn.textLabel?.textColor = ColorUtil.fontColor
        self.multicolumn.imageView?.image = UIImage.init(named: "multicolumn")?.toolbarIcon()
        self.multicolumn.imageView?.tintColor = ColorUtil.fontColor
        self.multicolumn.detailTextLabel?.textColor = ColorUtil.fontColor
        
        self.autocache.textLabel?.text = "Autocache subreddits"
        self.autocache.detailTextLabel?.text = "Cache your favorite subs for your morning commute"
        self.autocache.backgroundColor = ColorUtil.foregroundColor
        self.autocache.textLabel?.textColor = ColorUtil.fontColor
        self.autocache.imageView?.image = UIImage.init(named: "download")?.toolbarIcon()
        self.autocache.imageView?.tintColor = ColorUtil.fontColor
        self.autocache.detailTextLabel?.textColor = ColorUtil.fontColor
        
        var purchasePro = UILabel(frame: CGRect.init(x:  0, y: -30, width: (self.view.frame.size.width / 2), height: 200))
        purchasePro.backgroundColor = ColorUtil.foregroundColor
        purchasePro.text = "Purchase\nPro"
        purchasePro.textAlignment = .center
        purchasePro.textColor = ColorUtil.fontColor
        purchasePro.font = UIFont.boldSystemFont(ofSize: 18)
        purchasePro.numberOfLines = 0
        purchasePro.addSubview(three)
        
        var purchaseBundle = UILabel(frame: CGRect.init(x:  (self.view.frame.size.width / 2), y: -30, width: (self.view.frame.size.width / 2), height: 200))
        purchaseBundle.backgroundColor = ColorUtil.foregroundColor
        purchaseBundle.text = "Purchase Pro\nWith $3 Donation"
        purchaseBundle.textAlignment = .center
        purchaseBundle.textColor = ColorUtil.fontColor
        purchaseBundle.numberOfLines = 0
        purchaseBundle.font = UIFont.boldSystemFont(ofSize: 18)
        purchaseBundle.addSubview(six)
        
        
        about.frame.size.height = about.frame.size.height + 200
        about.addSubview(purchasePro)
        about.addSubview(purchaseBundle)
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
            case 0: return self.restore
            case 1: return self.multicolumn
            case 2: return self.shadowbox
            case 3: return self.night
            case 4: return self.biometric
            case 5: return self.themes
            case 6: return self.gallery
            case 7: return self.autocache
            case 8: return self.username

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
        case 0: return 9
        default: fatalError("Unknown number of sections")
        }
    }

}
