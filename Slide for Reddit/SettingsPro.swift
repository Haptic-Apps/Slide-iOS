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

    var features: UITableViewCell = UITableViewCell()
    var customization: UITableViewCell = UITableViewCell()
    var bundle: UITableViewCell = UITableViewCell()
    var restore: UITableViewCell = UITableViewCell()

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

        var three = UILabel(frame: CGRect.init(x:  self.tableView.frame.size.width - 80, y: 20, width: 100, height: 30))
        three.text = "$2.99"
        three.backgroundColor = GMColor.lightGreen300Color()
        three.sizeToFit()
        three.layer.cornerRadius = 10
        three.clipsToBounds = true
        three.textColor = .white
        three.font = UIFont.boldSystemFont(ofSize: 12)
        three.textAlignment = .center

        self.features.textLabel?.text = "Pro Features Pack"
        self.features.accessoryType = .disclosureIndicator
        self.features.backgroundColor = ColorUtil.foregroundColor
        self.features.textLabel?.textColor = ColorUtil.fontColor
        self.features.imageView?.image = UIImage.init(named: "approve")?.toolbarIcon()
        self.features.imageView?.tintColor = ColorUtil.fontColor

        self.features.contentView.addSubview(three)

        var four = UILabel(frame: CGRect.init(x:  self.tableView.frame.size.width - 80, y: 20, width: 100, height: 30))
        four.text = "$2.99"
        four.backgroundColor = GMColor.lightGreen300Color()
        four.sizeToFit()
        four.layer.cornerRadius = 10
        four.clipsToBounds = true
        four.textColor = .white
        four.font = UIFont.boldSystemFont(ofSize: 12)
        four.textAlignment = .center

        self.customization.textLabel?.text = "Pro Customization Pack"
        self.customization.accessoryType = .disclosureIndicator
        self.customization.backgroundColor = ColorUtil.foregroundColor
        self.customization.textLabel?.textColor = ColorUtil.fontColor
        self.customization.imageView?.image = UIImage.init(named: "palette")?.toolbarIcon()
        self.customization.imageView?.tintColor = ColorUtil.fontColor

        self.customization.contentView.addSubview(four)

        var six = UILabel(frame: CGRect.init(x:  self.tableView.frame.size.width - 80, y: 20, width: 100, height: 30))
        six.text = "$4.99"
        six.backgroundColor = GMColor.lightBlue300Color()
        six.sizeToFit()
        six.layer.cornerRadius = 10
        six.clipsToBounds = true
        six.textColor = .white
        six.font = UIFont.boldSystemFont(ofSize: 12)
        six.textAlignment = .center

        self.bundle.textLabel?.text = "Pro packs bundle deal"
        self.bundle.accessoryType = .disclosureIndicator
        self.bundle.backgroundColor = ColorUtil.foregroundColor
        self.bundle.textLabel?.textColor = ColorUtil.fontColor
        self.bundle.imageView?.image = UIImage.init(named: "bundle")?.toolbarIcon()
        self.bundle.imageView?.tintColor = ColorUtil.fontColor

        self.bundle.contentView.addSubview(six)

        self.restore.textLabel?.text = "Restore pro purchases"
        self.restore.accessoryType = .disclosureIndicator
        self.restore.backgroundColor = ColorUtil.foregroundColor
        self.restore.textLabel?.textColor = ColorUtil.fontColor
        self.restore.imageView?.image = UIImage.init(named: "restore")?.toolbarIcon()
        self.restore.imageView?.tintColor = ColorUtil.fontColor

        var about = PaddingLabel(frame: CGRect.init(x:  0, y: 0, width: self.tableView.frame.size.width, height: 30))
        about.font = UIFont.systemFont(ofSize: 16)
        about.backgroundColor = ColorUtil.foregroundColor
        about.textColor = ColorUtil.fontColor
        about.text = "Upgrade to Slide Pro to enjoy awesome new features while supporting ad-free and open source software!\n\nI'm an indie software developer currently studying at university, and every donation helps keep Slide going :)\n\n\n\n"
        about.numberOfLines = 0
        about.textAlignment = .center
        about.lineBreakMode = .byClipping
        about.sizeToFit()
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
            case 0: return self.features
            case 1: return self.customization
            case 2: return self.bundle
            case 3: return self.restore

            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var ch: UIViewController?
        if (indexPath.section == 0 && indexPath.row == 0) {
            ch = SettingsProFeatures()
        } else if(indexPath.row == 1){
            ch = SettingsProCustomization()
        }
        if let n = ch {
            VCPresenter.showVC(viewController: n, popupIfPossible: false, parentNavigationController: navigationController, parentViewController: self)
        }
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
