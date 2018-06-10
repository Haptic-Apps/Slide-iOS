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

class SettingsProFeatures: UITableViewController {

    var shadowbox: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "shadow")
    var gallery: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "gallery")
    var biometric: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "bio")
    var multicolumn: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "multi")
    var autocache: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "auto")

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
        self.title = "Pro Features Pack"

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
        purchasePro.text = "Purchase\nPro Feature Pack"
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
            case 0: return self.multicolumn
            case 1: return self.shadowbox
            case 2: return self.gallery
            case 3: return self.biometric
            case 4: return self.autocache

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
        case 0: return 5
        default: fatalError("Unknown number of sections")
        }
    }

}
 class PaddingLabel: UILabel {

     var topInset: CGFloat = 220.0
     var bottomInset: CGFloat = 20.0
     var leftInset: CGFloat = 20.0
     var rightInset: CGFloat = 20.0

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
 }
