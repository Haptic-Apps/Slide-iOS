//
//  SettingsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/10/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import BiometricAuthentication
import LicensesViewController
import SDWebImage
import MaterialComponents.MaterialSnackbar
import RealmSwift
import RLBAlertsPickers

class SettingsViewController: UITableViewController {

    var general: UITableViewCell = UITableViewCell()
    var manageSubs: UITableViewCell = UITableViewCell()
    var mainTheme: UITableViewCell = UITableViewCell()
    var postLayout: UITableViewCell = UITableViewCell()
    var subThemes: UITableViewCell = UITableViewCell()
    var font: UITableViewCell = UITableViewCell()
    var comments: UITableViewCell = UITableViewCell()
    var linkHandling: UITableViewCell = UITableViewCell()
    var history: UITableViewCell = UITableViewCell()
    var dataSaving: UITableViewCell = UITableViewCell()
    var filters: UITableViewCell = UITableViewCell()
    var content: UITableViewCell = UITableViewCell()
    var lockCell: UITableViewCell = UITableViewCell()
    var subCell: UITableViewCell = UITableViewCell()
    var licenseCell: UITableViewCell = UITableViewCell()
    var aboutCell: UITableViewCell = UITableViewCell()
    var githubCell: UITableViewCell = UITableViewCell()
    var clearCell: UITableViewCell = UITableViewCell()
    var cacheCell: UITableViewCell = UITableViewCell()

    var multiColumnCell: UITableViewCell = UITableViewCell()
    var multiColumn = UISwitch()
    var lock = UISwitch()

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

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
        self.title = "Settings"

        self.general.textLabel?.text = "General"
        self.general.accessoryType = .disclosureIndicator
        self.general.backgroundColor = ColorUtil.foregroundColor
        self.general.textLabel?.textColor = ColorUtil.fontColor
        self.general.imageView?.image = UIImage.init(named: "settings")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.general.imageView?.tintColor = ColorUtil.fontColor

        self.manageSubs.textLabel?.text = "Manage your subreddits"
        self.manageSubs.accessoryType = .disclosureIndicator
        self.manageSubs.backgroundColor = ColorUtil.foregroundColor
        self.manageSubs.textLabel?.textColor = ColorUtil.fontColor
        self.manageSubs.imageView?.image = UIImage.init(named: "subs")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.manageSubs.imageView?.tintColor = ColorUtil.fontColor

        self.mainTheme.textLabel?.text = "Main theme"
        self.mainTheme.accessoryType = .disclosureIndicator
        self.mainTheme.backgroundColor = ColorUtil.foregroundColor
        self.mainTheme.textLabel?.textColor = ColorUtil.fontColor
        self.mainTheme.imageView?.image = UIImage.init(named: "colors")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.mainTheme.imageView?.tintColor = ColorUtil.fontColor

        self.clearCell.textLabel?.text = "Clear cache"
        self.clearCell.accessoryType = .disclosureIndicator
        self.clearCell.backgroundColor = ColorUtil.foregroundColor
        self.clearCell.textLabel?.textColor = ColorUtil.fontColor
        self.clearCell.imageView?.image = UIImage.init(named: "multis")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.clearCell.imageView?.tintColor = ColorUtil.fontColor

        self.cacheCell.textLabel?.text = "Offline caching"
        self.cacheCell.accessoryType = .disclosureIndicator
        self.cacheCell.backgroundColor = ColorUtil.foregroundColor
        self.cacheCell.textLabel?.textColor = ColorUtil.fontColor
        self.cacheCell.imageView?.image = UIImage.init(named: "save-1")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.cacheCell.imageView?.tintColor = ColorUtil.fontColor

        self.postLayout.textLabel?.text = "Post layout"
        self.postLayout.accessoryType = .disclosureIndicator
        self.postLayout.backgroundColor = ColorUtil.foregroundColor
        self.postLayout.textLabel?.textColor = ColorUtil.fontColor
        self.postLayout.imageView?.image = UIImage.init(named: "layout")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.postLayout.imageView?.tintColor = ColorUtil.fontColor

        self.subThemes.textLabel?.text = "Subreddit themes"
        self.subThemes.accessoryType = .disclosureIndicator
        self.subThemes.backgroundColor = ColorUtil.foregroundColor
        self.subThemes.textLabel?.textColor = ColorUtil.fontColor
        self.subThemes.imageView?.image = UIImage.init(named: "subs")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.subThemes.imageView?.tintColor = ColorUtil.fontColor

        self.font.textLabel?.text = "Font"
        self.font.accessoryType = .disclosureIndicator
        self.font.backgroundColor = ColorUtil.foregroundColor
        self.font.textLabel?.textColor = ColorUtil.fontColor
        self.font.imageView?.image = UIImage.init(named: "size")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.font.imageView?.tintColor = ColorUtil.fontColor

        self.comments.textLabel?.text = "Comments"
        self.comments.accessoryType = .disclosureIndicator
        self.comments.backgroundColor = ColorUtil.foregroundColor
        self.comments.textLabel?.textColor = ColorUtil.fontColor
        self.comments.imageView?.image = UIImage.init(named: "comments")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.comments.imageView?.tintColor = ColorUtil.fontColor

        self.linkHandling.textLabel?.text = "Link handling"
        self.linkHandling.accessoryType = .disclosureIndicator
        self.linkHandling.backgroundColor = ColorUtil.foregroundColor
        self.linkHandling.textLabel?.textColor = ColorUtil.fontColor
        self.linkHandling.imageView?.image = UIImage.init(named: "link")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.linkHandling.imageView?.tintColor = ColorUtil.fontColor

        self.history.textLabel?.text = "History"
        self.history.accessoryType = .disclosureIndicator
        self.history.backgroundColor = ColorUtil.foregroundColor
        self.history.textLabel?.textColor = ColorUtil.fontColor
        self.history.imageView?.image = UIImage.init(named: "history")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.history.imageView?.tintColor = ColorUtil.fontColor

        self.dataSaving.textLabel?.text = "Data saving"
        self.dataSaving.accessoryType = .disclosureIndicator
        self.dataSaving.backgroundColor = ColorUtil.foregroundColor
        self.dataSaving.textLabel?.textColor = ColorUtil.fontColor
        self.dataSaving.imageView?.image = UIImage.init(named: "data")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.dataSaving.imageView?.tintColor = ColorUtil.fontColor

        self.content.textLabel?.text = "Content"
        self.content.accessoryType = .disclosureIndicator
        self.content.backgroundColor = ColorUtil.foregroundColor
        self.content.textLabel?.textColor = ColorUtil.fontColor
        self.content.imageView?.image = UIImage.init(named: "image")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.content.imageView?.tintColor = ColorUtil.fontColor

        self.subCell.textLabel?.text = "Visit the Slide subreddit!"
        self.subCell.accessoryType = .disclosureIndicator
        self.subCell.backgroundColor = ColorUtil.foregroundColor
        self.subCell.textLabel?.textColor = ColorUtil.fontColor
        self.subCell.imageView?.image = UIImage.init(named: "subs")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.subCell.imageView?.tintColor = ColorUtil.fontColor

        self.filters.textLabel?.text = "Filters"
        self.filters.accessoryType = .disclosureIndicator
        self.filters.backgroundColor = ColorUtil.foregroundColor
        self.filters.textLabel?.textColor = ColorUtil.fontColor
        self.filters.imageView?.image = UIImage.init(named: "filter")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.filters.imageView?.tintColor = ColorUtil.fontColor

        self.aboutCell.textLabel?.text = "Slide \(getVersion())"
        self.aboutCell.accessoryType = .disclosureIndicator
        self.aboutCell.backgroundColor = ColorUtil.foregroundColor
        self.aboutCell.textLabel?.textColor = ColorUtil.fontColor
        self.aboutCell.imageView?.image = UIImage.init(named: "info")?.toolbarIcon()
            .withRenderingMode(.alwaysTemplate)
        self.aboutCell.imageView?.tintColor = ColorUtil.fontColor

        self.githubCell.textLabel?.text = "Github"
        self.githubCell.accessoryType = .disclosureIndicator
        self.githubCell.backgroundColor = ColorUtil.foregroundColor
        self.githubCell.textLabel?.textColor = ColorUtil.fontColor
        self.githubCell.imageView?.image = UIImage.init(named: "github")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.githubCell.imageView?.tintColor = ColorUtil.fontColor

        self.licenseCell.textLabel?.text = "Open source licenses"
        self.licenseCell.accessoryType = .disclosureIndicator
        self.licenseCell.backgroundColor = ColorUtil.foregroundColor
        self.licenseCell.textLabel?.textColor = ColorUtil.fontColor
        self.licenseCell.imageView?.image = UIImage.init(named: "code")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.licenseCell.imageView?.tintColor = ColorUtil.fontColor

        multiColumnCell.textLabel?.text = "Multi Column mode"
        multiColumnCell.backgroundColor = ColorUtil.foregroundColor
        multiColumnCell.textLabel?.textColor = ColorUtil.fontColor
        multiColumnCell.selectionStyle = UITableViewCellSelectionStyle.none
        self.multiColumnCell.imageView?.image = UIImage.init(named: "multicolumn")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.multiColumnCell.imageView?.tintColor = ColorUtil.fontColor

        lock = UISwitch()
        lock.isOn = SettingValues.biometrics
        lock.isEnabled = BioMetricAuthenticator.canAuthenticate()
        lock.addTarget(self, action: #selector(SettingsViewController.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        lockCell.textLabel?.text = "Require unlock on open"
        lockCell.accessoryView = lock
        lockCell.backgroundColor = ColorUtil.foregroundColor
        lockCell.textLabel?.textColor = ColorUtil.fontColor
        lockCell.selectionStyle = UITableViewCellSelectionStyle.none
        self.lockCell.imageView?.image = UIImage.init(named: "lockapp")?.toolbarIcon().withRenderingMode(.alwaysTemplate)
        self.lockCell.imageView?.tintColor = ColorUtil.fontColor

        if (reset) {
            self.tableView.reloadData(with: .fade)
        }
    }

    func switchIsChanged(_ changed: UISwitch) {
        if (changed == multiColumn) {
            SettingValues.multiColumn = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_multiColumn)
        } else if (changed == lock) {
            SettingValues.biometrics = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_biometrics)
        }
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
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
            case 0: return self.general
            case 1: return self.manageSubs
            case 2: return self.multiColumnCell
            case 3: return self.lockCell

            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch (indexPath.row) {
            case 0: return self.mainTheme
            case 1: return self.postLayout
            case 2: return self.subThemes
            case 3: return self.font
            case 4: return self.comments
            default: fatalError("Unknown row in section 1")
            }
        case 2:
            switch (indexPath.row) {
            case 0: return self.linkHandling
            case 1: return self.history
            case 2: return self.dataSaving
            case 3: return self.content
            case 4: return self.filters
            case 5: return self.cacheCell
            case 6: return self.clearCell
            default: fatalError("Unknown row in section 2")
            }
        case 3:
            switch (indexPath.row) {
            case 0: return self.aboutCell
            case 1: return self.subCell
            case 2: return self.githubCell
            case 3: return self.licenseCell
            default: fatalError("Unknown row in section 3")
            }
        default: fatalError("Unknown section")
        }

    }
    
    func showMultiColumn(){
        let actionSheetController: UIAlertController = UIAlertController(title: "Multi Column Mode", message: "", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { action -> Void in
        }
        actionSheetController.addAction(cancelActionButton)
        
        multiColumn = UISwitch.init(frame: CGRect.init(x: 20, y: 20, width: 75, height: 50))
        multiColumn.isOn = SettingValues.multiColumn
        multiColumn.addTarget(self, action: #selector(SettingsViewController.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        actionSheetController.view.addSubview(multiColumn)
        
        let values = [["1","2","3","4","5"]]
        actionSheetController.addPickerView(values: values, initialSelection: [(0, SettingValues.multiColumnCount - 1)]) { (_, _, chosen, _) in
            SettingValues.multiColumnCount = chosen.row + 1
            UserDefaults.standard.set(chosen.row + 1, forKey: SettingValues.pref_multiColumnCount)
            UserDefaults.standard.synchronize()
            SubredditReorderViewController.changed = true
        }
        
        actionSheetController.modalPresentationStyle = .popover
        
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = multiColumnCell
            presenter.sourceRect = multiColumnCell.bounds
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var ch: UIViewController?
        if (indexPath.section == 0 && indexPath.row == 1) {
            ch = SubredditReorderViewController()
        } else if(indexPath.section == 0 && indexPath.row == 2){
            showMultiColumn()
        } else if (indexPath.section == 0 && indexPath.row == 0) {
            ch = SettingsGeneral()
        } else if (indexPath.section == 2 && indexPath.row == 4) {
            ch = FiltersViewController()
        } else if (indexPath.section == 1 && indexPath.row == 2) {
            ch = SubredditThemeViewController()
        } else if (indexPath.section == 1 && indexPath.row == 0) {
            ch = SettingsTheme()
            (ch as! SettingsTheme).tochange = self
        } else if (indexPath.section == 1 && indexPath.row == 3) {
            ch = SettingsFont()
        } else if (indexPath.section == 1 && indexPath.row == 1) {
            ch = SettingsLayout()
        } else if (indexPath.section == 2 && indexPath.row == 2) {
            ch = SettingsData()
        } else if (indexPath.section == 2 && indexPath.row == 3) {
            ch = SettingsContent()
        } else if (indexPath.section == 1 && indexPath.row == 4) {
            ch = SettingsComments()
        } else if (indexPath.section == 2 && indexPath.row == 0) {
            ch = SettingsLinkHandling()
        } else if (indexPath.section == 2 && indexPath.row == 1) {
            ch = SettingsHistory()
        } else if (indexPath.section == 2 && indexPath.row == 6) {
            let realm = try! Realm()
            try! realm.write {
                realm.deleteAll()
            }

            SDImageCache.shared().clearMemory()
            SDImageCache.shared().clearDisk()
            SDWebImageManager.shared().imageCache.clearMemory()
            SDWebImageManager.shared().imageCache.clearDisk()

            let message = MDCSnackbarMessage()
            message.text = "All caches cleared!"
            MDCSnackbarManager.show(message)

        } else if (indexPath.section == 3 && indexPath.row == 0) {
            //todo Show changlog?
        } else if (indexPath.section == 3 && indexPath.row == 1) {
            ch = SingleSubredditViewController.init(subName: "slide_ios", single: true)
        } else if (indexPath.section == 2 && indexPath.row == 5) {
            ch = CacheSettings()
        } else if (indexPath.section == 3 && indexPath.row == 2) {
            let url = URL.init(string: "https://github.com/ccrama/Slide-ios")!
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        } else if (indexPath.section == 3 && indexPath.row == 3) {
            ch = LicensesViewController()
            let file = Bundle.main.path(forResource:"Credits", ofType: "plist")!
            (ch as! LicensesViewController).loadPlist(NSDictionary(contentsOfFile: file)!)
        }
        if let n = ch {
            VCPresenter.showVC(viewController: n, popupIfPossible: false, parentNavigationController: navigationController, parentViewController: self)
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.fontColor
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor

        switch (section) {
        case 0: label.text = "General"
            break
        case 1: label.text = "Appearance"
            break
        case 2: label.text = "Content"
            break
        case 3: label.text = "About"
        default: label.text = ""
            break
        }
        return toReturn
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0: return 4    // section 0 has 2 rows
        case 1: return 5    // section 1 has 1 row
        case 2: return 7
        case 3: return 4
        default: fatalError("Unknown number of sections")
        }
    }

    func getVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "v\(version).\(build)"
    }

}
