//
//  SettingsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/10/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import BiometricAuthentication
import LicensesViewController
import MessageUI
import RealmSwift
import RLBAlertsPickers
import SDWebImage
import SloppySwiper
import UIKit

class SettingsViewController: MediaTableViewController, MFMailComposeViewControllerDelegate {
    var swiper: SloppySwiper?
    var goPro: UITableViewCell = UITableViewCell()

    var general: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "general")
    var manageSubs: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "managesubs")
    var mainTheme: UITableViewCell = UITableViewCell()
    var postLayout: UITableViewCell = UITableViewCell()
    var icon: UITableViewCell = UITableViewCell()
    var subThemes: UITableViewCell = UITableViewCell()
    var font: UITableViewCell = UITableViewCell()
    var comments: UITableViewCell = UITableViewCell()
    var linkHandling: UITableViewCell = UITableViewCell()
    var history: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "history")
    var dataSaving: UITableViewCell = UITableViewCell()
    var filters: UITableViewCell = UITableViewCell()
    var content: UITableViewCell = UITableViewCell()
    var lockCell: UITableViewCell = UITableViewCell()
    var subCell: UITableViewCell = UITableViewCell()
    var licenseCell: UITableViewCell = UITableViewCell()
    var contributorsCell: UITableViewCell = UITableViewCell()
    var aboutCell: UITableViewCell = UITableViewCell()
    var githubCell: UITableViewCell = UITableViewCell()
    var clearCell: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "cache")
    var cacheCell: UITableViewCell = UITableViewCell()
    var backupCell: UITableViewCell = UITableViewCell()
    var gestureCell: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "gestures")
    var autoPlayCell: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "autoplay")
    var tagsCell: UITableViewCell = UITableViewCell()
    var audioSettings = UITableViewCell()
    var postActionCell: UITableViewCell = UITableViewCell()
    var coffeeCell: UITableViewCell = UITableViewCell()

    var viewModeCell: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "viewmode")
    var lock = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lock.onTintColor = ColorUtil.baseAccent
        if SettingsPro.changed {
            self.tableView.reloadData()
            let menuB = UIBarButtonItem(image: UIImage.init(named: "support")?.toolbarIcon().getCopy(withColor: GMColor.red500Color()), style: .plain, target: self, action: #selector(SettingsViewController.didPro(_:)))
            navigationItem.rightBarButtonItem = menuB
        }
        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.setImage(UIImage.init(named: (self.navigationController?.viewControllers.count ?? 0) == 1 ? "close" : "back")!.navIcon(), for: UIControl.State.normal)
        button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        
        let barButton = UIBarButtonItem.init(customView: button)
        
        navigationItem.leftBarButtonItem = barButton
        
        if self.navigationController != nil {
            if !(self.navigationController?.delegate is SloppySwiper) {
                swiper = SloppySwiper.init(navigationController: self.navigationController!)
                self.navigationController!.delegate = swiper!
            }
        }
        
        if let interactiveGesture = self.navigationController?.interactivePopGestureRecognizer {
            self.tableView.panGestureRecognizer.require(toFail: interactiveGesture)
        }
    }
    
    @objc public func handleBackButton() {
        if self.navigationController?.viewControllers.count == 1 {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupBaseBarColors()
        self.history.detailTextLabel?.text = "\(History.seenTimes.allKeys.count) visited post" + (History.seenTimes.allKeys.count != 1 ? "s" : "")
        navigationController?.setToolbarHidden(true, animated: false)
        self.icon.imageView?.image = Bundle.main.icon?.getCopy(withSize: CGSize(width: 25, height: 25))
    }

    override func loadView() {
        super.loadView()
        if SettingValues.isPro {
            let menuB = UIBarButtonItem(image: UIImage.init(named: "support")?.toolbarIcon().getCopy(withColor: GMColor.red500Color()), style: .plain, target: self, action: #selector(SettingsViewController.didPro(_:)))
            navigationItem.rightBarButtonItem = menuB
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        doCells()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    @objc func didPro(_ sender: AnyObject) {
        let alert = UIAlertController.init(title: "Pro Supporter", message: "Thank you for supporting my work and going Pro 😊\n\nIf you need any assistance with pro features, feel free to send me a message!", preferredStyle: .alert)
        /*alert.addAction(UIAlertAction.init(title: "Tip jar", style: .default, handler: { (_) in
            VCPresenter.donateDialog(self)
        }))*/
        
        alert.addAction(UIAlertAction.init(title: "Email", style: .default, handler: { (_) in
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients(["hapticappsdev@gmail.com"])
                mail.setSubject("Slide Pro Purchase Support")
                self.present(mail, animated: true)
            }
        }))
        
        alert.addAction(UIAlertAction.init(title: "Private Message", style: .default, handler: { (_) in
            let base = TapBehindModalViewController(rootViewController: ReplyViewController.init(name: "ccrama", completion: { (_) in
                BannerUtil.makeBanner(text: "Message sent!", color: GMColor.green500Color(), seconds: 3, context: self, top: true, callback: nil)
            }))
            VCPresenter.presentAlert(base, parentVC: self)
        }))
            
        alert.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: nil))
            
        self.present(alert, animated: true)

    }

    func doCells(_ reset: Bool = true) {
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        // set the title
        self.title = "Settings"
        self.tableView.separatorStyle = .none

        self.general.textLabel?.text = "General"
        self.general.accessoryType = .disclosureIndicator
        self.general.backgroundColor = ColorUtil.theme.foregroundColor
        self.general.textLabel?.textColor = ColorUtil.theme.fontColor
        self.general.imageView?.image = UIImage.init(named: "settings")?.toolbarIcon()
        self.general.imageView?.tintColor = ColorUtil.theme.fontColor
        if false && !UserDefaults.standard.bool(forKey: "2notifs") { //Disabled now
            self.general.detailTextLabel?.textColor = ColorUtil.baseAccent
            self.general.detailTextLabel?.text = "New in 2.0: set up notifications here!"
        } else {
            self.general.detailTextLabel?.textColor = ColorUtil.theme.fontColor
            self.general.detailTextLabel?.text = "Display settings, haptic feedback and default sorting"
        }
        self.general.detailTextLabel?.numberOfLines = 0
        self.general.detailTextLabel?.lineBreakMode = .byWordWrapping

        self.manageSubs.textLabel?.text = "Subscriptions"
        self.manageSubs.accessoryType = .disclosureIndicator
        self.manageSubs.backgroundColor = ColorUtil.theme.foregroundColor
        self.manageSubs.textLabel?.textColor = ColorUtil.theme.fontColor
        self.manageSubs.imageView?.image = UIImage.init(named: "subs")?.toolbarIcon()
        self.manageSubs.imageView?.tintColor = ColorUtil.theme.fontColor
        self.manageSubs.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.manageSubs.detailTextLabel?.text = "Manage your subscriptions and rearrange your subreddits"
        self.manageSubs.detailTextLabel?.numberOfLines = 0

        self.postActionCell.textLabel?.text = "Reorder post actions"
        self.postActionCell.accessoryType = .disclosureIndicator
        self.postActionCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.postActionCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.postActionCell.imageView?.image = UIImage.init(named: "compact")?.toolbarIcon()
        self.postActionCell.imageView?.tintColor = ColorUtil.theme.fontColor

        self.mainTheme.textLabel?.text = "App theme"
        self.mainTheme.accessoryType = .disclosureIndicator
        self.mainTheme.backgroundColor = ColorUtil.theme.foregroundColor
        self.mainTheme.textLabel?.textColor = ColorUtil.theme.fontColor
        self.mainTheme.imageView?.image = UIImage.init(named: "palette")?.toolbarIcon()
        self.mainTheme.imageView?.tintColor = ColorUtil.theme.fontColor

        self.icon.textLabel?.text = "App icon"
        self.icon.accessoryType = .disclosureIndicator
        self.icon.backgroundColor = ColorUtil.theme.foregroundColor
        self.icon.textLabel?.textColor = ColorUtil.theme.fontColor
        self.icon.imageView?.image = Bundle.main.icon?.getCopy(withSize: CGSize(width: 25, height: 25))
        self.icon.imageView?.layer.cornerRadius = 5
        self.icon.imageView?.clipsToBounds = true

        self.tagsCell.textLabel?.text = "User Tags Management"
        self.tagsCell.accessoryType = .disclosureIndicator
        self.tagsCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.tagsCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.tagsCell.imageView?.image = UIImage.init(named: "user")?.toolbarIcon()
        self.tagsCell.imageView?.tintColor = ColorUtil.theme.fontColor

        self.goPro.textLabel?.text = "Support Slide, go Pro!"
        self.goPro.accessoryType = .disclosureIndicator
        self.goPro.backgroundColor = ColorUtil.theme.foregroundColor
        self.goPro.textLabel?.textColor = ColorUtil.theme.fontColor
        self.goPro.imageView?.image = UIImage.init(named: "support")?.toolbarIcon().getCopy(withColor: GMColor.red500Color())
        self.goPro.imageView?.tintColor = ColorUtil.theme.fontColor

        self.coffeeCell.textLabel?.text = "Tip Jar"
        self.coffeeCell.accessoryType = .disclosureIndicator
        self.coffeeCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.coffeeCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.coffeeCell.imageView?.image = UIImage.init(named: "support")?.toolbarIcon().getCopy(withColor: GMColor.lightGreen500Color())
        self.coffeeCell.imageView?.tintColor = ColorUtil.theme.fontColor

        self.clearCell.textLabel?.text = "Clear cache"
        self.clearCell.accessoryType = .none
        self.clearCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.clearCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.clearCell.imageView?.image = UIImage.init(named: "multis")?.toolbarIcon()
        self.clearCell.imageView?.tintColor = ColorUtil.theme.fontColor
        self.clearCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        let countBytes = ByteCountFormatter()
        countBytes.allowedUnits = [.useMB]
        countBytes.countStyle = .file
        let fileSize = countBytes.string(fromByteCount: Int64(SDImageCache.shared.totalDiskSize()))
        
        self.clearCell.detailTextLabel?.text = fileSize
        self.clearCell.detailTextLabel?.numberOfLines = 0

        self.backupCell.textLabel?.text = "Backup and Restore"
        self.backupCell.accessoryType = .disclosureIndicator
        self.backupCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.backupCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.backupCell.imageView?.image = UIImage.init(named: "restore")?.toolbarIcon()
        self.backupCell.imageView?.tintColor = ColorUtil.theme.fontColor

        self.gestureCell.textLabel?.text = "Gestures"
        self.gestureCell.accessoryType = .disclosureIndicator
        self.gestureCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.gestureCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.gestureCell.imageView?.image = UIImage.init(named: "gestures")?.toolbarIcon()
        self.gestureCell.imageView?.tintColor = ColorUtil.theme.fontColor
        self.gestureCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.gestureCell.detailTextLabel?.text = "Swipe and tap gestures for submissions and comments"
        self.gestureCell.detailTextLabel?.numberOfLines = 0

        self.cacheCell.textLabel?.text = "Offline caching"
        self.cacheCell.accessoryType = .disclosureIndicator
        self.cacheCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.cacheCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.cacheCell.imageView?.image = UIImage.init(named: "save-1")?.toolbarIcon()
        self.cacheCell.imageView?.tintColor = ColorUtil.theme.fontColor

        self.postLayout.textLabel?.text = "Submission layout"
        self.postLayout.accessoryType = .disclosureIndicator
        self.postLayout.backgroundColor = ColorUtil.theme.foregroundColor
        self.postLayout.textLabel?.textColor = ColorUtil.theme.fontColor
        self.postLayout.imageView?.image = UIImage.init(named: "layout")?.toolbarIcon()
        self.postLayout.imageView?.tintColor = ColorUtil.theme.fontColor

        self.subThemes.textLabel?.text = "Subreddit themes"
        self.subThemes.accessoryType = .disclosureIndicator
        self.subThemes.backgroundColor = ColorUtil.theme.foregroundColor
        self.subThemes.textLabel?.textColor = ColorUtil.theme.fontColor
        self.subThemes.imageView?.image = UIImage.init(named: "subs")?.toolbarIcon()
        self.subThemes.imageView?.tintColor = ColorUtil.theme.fontColor

        self.font.textLabel?.text = "Font and Links"
        self.font.accessoryType = .disclosureIndicator
        self.font.backgroundColor = ColorUtil.theme.foregroundColor
        self.font.textLabel?.textColor = ColorUtil.theme.fontColor
        self.font.imageView?.image = UIImage.init(named: "size")?.toolbarIcon()
        self.font.imageView?.tintColor = ColorUtil.theme.fontColor

        self.comments.textLabel?.text = "Comments"
        self.comments.accessoryType = .disclosureIndicator
        self.comments.backgroundColor = ColorUtil.theme.foregroundColor
        self.comments.textLabel?.textColor = ColorUtil.theme.fontColor
        self.comments.imageView?.image = UIImage.init(named: "comments")?.toolbarIcon()
        self.comments.imageView?.tintColor = ColorUtil.theme.fontColor

        self.linkHandling.textLabel?.text = "Link handling"
        self.linkHandling.accessoryType = .disclosureIndicator
        self.linkHandling.backgroundColor = ColorUtil.theme.foregroundColor
        self.linkHandling.textLabel?.textColor = ColorUtil.theme.fontColor
        self.linkHandling.imageView?.image = UIImage.init(named: "link")?.toolbarIcon()
        self.linkHandling.imageView?.tintColor = ColorUtil.theme.fontColor

        self.history.textLabel?.text = "History"
        self.history.accessoryType = .disclosureIndicator
        self.history.backgroundColor = ColorUtil.theme.foregroundColor
        self.history.textLabel?.textColor = ColorUtil.theme.fontColor
        self.history.imageView?.image = UIImage.init(named: "history")?.toolbarIcon()
        self.history.imageView?.tintColor = ColorUtil.theme.fontColor
        self.history.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.history.detailTextLabel?.text = "\(History.seenTimes.allKeys.count) visited posts"
        self.history.detailTextLabel?.numberOfLines = 0

        self.dataSaving.textLabel?.text = "Data saving"
        self.dataSaving.accessoryType = .disclosureIndicator
        self.dataSaving.backgroundColor = ColorUtil.theme.foregroundColor
        self.dataSaving.textLabel?.textColor = ColorUtil.theme.fontColor
        self.dataSaving.imageView?.image = UIImage.init(named: "data")?.toolbarIcon()
        self.dataSaving.imageView?.tintColor = ColorUtil.theme.fontColor

        self.content.textLabel?.text = "Content"
        self.content.accessoryType = .disclosureIndicator
        self.content.backgroundColor = ColorUtil.theme.foregroundColor
        self.content.textLabel?.textColor = ColorUtil.theme.fontColor
        self.content.imageView?.image = UIImage.init(named: "image")?.toolbarIcon()
        self.content.imageView?.tintColor = ColorUtil.theme.fontColor

        self.subCell.textLabel?.text = "Visit the Slide subreddit!"
        self.subCell.accessoryType = .disclosureIndicator
        self.subCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.subCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.subCell.imageView?.image = UIImage.init(named: "subs")?.toolbarIcon()
        self.subCell.imageView?.tintColor = ColorUtil.theme.fontColor

        self.filters.textLabel?.text = "Filters"
        self.filters.accessoryType = .disclosureIndicator
        self.filters.backgroundColor = ColorUtil.theme.foregroundColor
        self.filters.textLabel?.textColor = ColorUtil.theme.fontColor
        self.filters.imageView?.image = UIImage.init(named: "filter")?.toolbarIcon()
        self.filters.imageView?.tintColor = ColorUtil.theme.fontColor

        self.aboutCell.textLabel?.text = "Version: \(getVersion())"
        self.aboutCell.accessoryType = .disclosureIndicator
        self.aboutCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.aboutCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.aboutCell.imageView?.image = UIImage.init(named: "info")?.toolbarIcon()
            
        self.aboutCell.imageView?.tintColor = ColorUtil.theme.fontColor

        self.githubCell.textLabel?.text = "Github"
        self.githubCell.accessoryType = .disclosureIndicator
        self.githubCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.githubCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.githubCell.imageView?.image = UIImage.init(named: "github")?.toolbarIcon()
        self.githubCell.imageView?.tintColor = ColorUtil.theme.fontColor

        self.licenseCell.textLabel?.text = "Open source licenses"
        self.licenseCell.accessoryType = .disclosureIndicator
        self.licenseCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.licenseCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.licenseCell.imageView?.image = UIImage.init(named: "code")?.toolbarIcon()
        self.licenseCell.imageView?.tintColor = ColorUtil.theme.fontColor

        self.contributorsCell.textLabel?.text = "Slide project contributors"
        self.contributorsCell.accessoryType = .disclosureIndicator
        self.contributorsCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.contributorsCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.contributorsCell.imageView?.image = UIImage.init(named: "happy")?.toolbarIcon()
        self.contributorsCell.imageView?.tintColor = ColorUtil.theme.fontColor

        self.autoPlayCell.textLabel?.text = "Autoplay videos and gifs"
        self.autoPlayCell.accessoryType = .none
        self.autoPlayCell.backgroundColor = ColorUtil.theme.foregroundColor
        self.autoPlayCell.textLabel?.textColor = ColorUtil.theme.fontColor
        self.autoPlayCell.imageView?.image = UIImage.init(named: "play")?.toolbarIcon()
        self.autoPlayCell.imageView?.tintColor = ColorUtil.theme.fontColor
        self.autoPlayCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.autoPlayCell.detailTextLabel?.text = SettingValues.autoPlayMode.description() + "\nAutoplaying videos can lead to more data use"
        self.autoPlayCell.detailTextLabel?.numberOfLines = 0
        self.autoPlayCell.detailTextLabel?.lineBreakMode = .byWordWrapping

        viewModeCell.textLabel?.text = "App mode"
        viewModeCell.accessoryType = .disclosureIndicator
        viewModeCell.backgroundColor = ColorUtil.theme.foregroundColor
        viewModeCell.textLabel?.textColor = ColorUtil.theme.fontColor
        viewModeCell.selectionStyle = UITableViewCell.SelectionStyle.none
        self.viewModeCell.imageView?.image = UIImage.init(named: "multicolumn")?.toolbarIcon()
        self.viewModeCell.imageView?.tintColor = ColorUtil.theme.fontColor
        self.viewModeCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.viewModeCell.detailTextLabel?.text = "Multi-Column mode, Split UI, and subreddit bar settings"
        self.viewModeCell.detailTextLabel?.numberOfLines = 0

        lock = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        lock.isOn = SettingValues.biometrics
        lock.isEnabled = BioMetricAuthenticator.canAuthenticate()
        lock.addTarget(self, action: #selector(SettingsViewController.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        lockCell.textLabel?.text = "Biometric app lock"
        lockCell.accessoryView = lock
        lockCell.backgroundColor = ColorUtil.theme.foregroundColor
        lockCell.textLabel?.textColor = ColorUtil.theme.fontColor
        lockCell.selectionStyle = UITableViewCell.SelectionStyle.none
        self.lockCell.imageView?.image = UIImage.init(named: "lockapp")?.toolbarIcon()
        self.lockCell.imageView?.tintColor = ColorUtil.theme.fontColor

        audioSettings.textLabel?.text = "Audio"
        audioSettings.accessoryType = .disclosureIndicator
        audioSettings.backgroundColor = ColorUtil.theme.foregroundColor
        audioSettings.textLabel?.textColor = ColorUtil.theme.fontColor
        audioSettings.imageView?.image = UIImage.init(named: "audio")?.toolbarIcon()
        audioSettings.imageView?.tintColor = ColorUtil.theme.fontColor

        if reset {
            self.tableView.reloadData()
        }
    }

    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == lock {
            if !VCPresenter.proDialogShown(feature: true, self) {
                SettingValues.biometrics = changed.isOn
                UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_biometrics)
            } else {
                changed.isOn = false
            }
        }

        UserDefaults.standard.synchronize()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 30
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 74
        } else {
            // Hide content row if not logged in
            if indexPath == IndexPath(row: 3, section: 2) &&
                !AccountController.canShowNSFW {
                return 0
            }
            return 64
        }
    }

    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
        if SettingValues.isPro {
            switch indexPath.row {
            case 0: return self.general
            case 1: return self.manageSubs
            case 2: return self.viewModeCell
            case 3: return self.lockCell
            case 4: return self.gestureCell

            default: fatalError("Unknown row in section 0")
            }
        } else {
            switch indexPath.row {
            case 0: return self.general
            case 1: return self.manageSubs
            case 2: return self.goPro
            case 3: return self.viewModeCell
            case 4: return self.lockCell
            case 5: return self.gestureCell
                
            default: fatalError("Unknown row in section 0")
            }
        }
        case 1:
            switch indexPath.row {
            case 0: return self.mainTheme
            case 1: return self.icon
            case 2: return self.postLayout
            case 3: return self.autoPlayCell
            case 4: return self.audioSettings
            case 5: return self.subThemes
            case 6: return self.font
            case 7: return self.comments
            case 8: return self.postActionCell
            default: fatalError("Unknown row in section 1")
            }
        case 2:
            switch indexPath.row {
            case 0: return self.linkHandling
            case 1: return self.history
            case 2: return self.dataSaving
            case 3: return self.content
            case 4: return self.filters
            case 5: return self.cacheCell
            case 6: return self.clearCell
            case 7: return self.backupCell
            case 8: return self.tagsCell
            default: fatalError("Unknown row in section 2")
            }
        case 3:
            switch indexPath.row {
            case 0: return self.aboutCell
            case 1: return self.subCell
            case 2: return self.contributorsCell
            //case 4: return self.coffeeCell
            case 3: return self.githubCell
            case 4: return self.licenseCell
            default: fatalError("Unknown row in section 3")
            }
        default: fatalError("Unknown section")
        }

    }
    
//    func showMultiColumn() {
//        if !VCPresenter.proDialogShown(feature: true, self) {
//            let actionSheetController: UIAlertController = UIAlertController(title: "Multi Column Mode", message: "", preferredStyle: .actionSheet)
//            
//            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { _ -> Void in
//            }
//            actionSheetController.addAction(cancelActionButton)
//            
//            multiColumn = UISwitch.init(frame: CGRect.init(x: 20, y: 20, width: 75, height: 50))
//            multiColumn.isOn = SettingValues.multiColumn
//            multiColumn.addTarget(self, action: #selector(SettingsViewController.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
//            actionSheetController.view.addSubview(multiColumn)
//            
//            let values = [["1", "2", "3", "4", "5"]]
//            actionSheetController.addPickerView(values: values, initialSelection: [(0, SettingValues.multiColumnCount - 1)]) { (_, _, chosen, _) in
//                SettingValues.multiColumnCount = chosen.row + 1
//                UserDefaults.standard.set(chosen.row + 1, forKey: SettingValues.pref_multiColumnCount)
//                UserDefaults.standard.synchronize()
//                SubredditReorderViewController.changed = true
//            }
//            
//            actionSheetController.modalPresentationStyle = .popover
//            
//            if let presenter = actionSheetController.popoverPresentationController {
//                presenter.sourceView = multiColumnCell
//                presenter.sourceRect = multiColumnCell.bounds
//            }
//            
//            self.present(actionSheetController, animated: true, completion: nil)
//        }
//    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var ch: UIViewController?
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                ch = SettingsGeneral()
            case 1:
                ch = SubredditReorderViewController()
            case 2:
                if !SettingValues.isPro {
                    ch = SettingsPro()
                } else {
                    ch = SettingsViewMode()
                }
            case 3:
                if !SettingValues.isPro {
                    ch = SettingsViewMode()
                }
            case 4:
                if SettingValues.isPro {
                    ch = SettingsGestures()
                }
            case 5:
                if !SettingValues.isPro {
                    ch = SettingsGestures()
                }
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                ch = SettingsTheme()
                (ch as! SettingsTheme).tochange = self
            case 1:
                if #available(iOS 10.3, *) {
                    ch = SettingsIcon()
                } else {
                    let alert = UIAlertController(title: "Can't access alternate icons", message: "Alternate icons require iOS 10.3 or above", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                    VCPresenter.presentAlert(alert, parentVC: self)
                }
            case 2:
                ch = SettingsLayout()
            case 3:
                let alertController = DragDownAlertMenu(title: "AutoPlay Settings", subtitle: "AutoPlay can lead to higher data use", icon: nil)
                for item in SettingValues.AutoPlay.cases {
                    alertController.addAction(title: item.description(), icon: UIImage()) {
                        UserDefaults.standard.set(item.rawValue, forKey: SettingValues.pref_autoPlayMode)
                        SettingValues.autoPlayMode = item
                        UserDefaults.standard.synchronize()
                        self.autoPlayCell.detailTextLabel?.text = SettingValues.autoPlayMode.description() + "\nAutoPlaying videos can lead to more data use"
                        SingleSubredditViewController.cellVersion += 1
                        SubredditReorderViewController.changed = true
                    }
                }
                alertController.show(self)
            case 4:
                ch = SettingsAudio()
            case 5:
                ch = SubredditThemeViewController()
            case 6:
                ch = SettingsFont()
            case 7:
                ch = SettingsComments()
            case 8:
                ch = SettingsPostMenu()
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                ch = SettingsLinkHandling()
            case 1:
                ch = SettingsHistory()
            case 2:
                ch = SettingsData()
            case 3:
                ch = SettingsContent()
            case 4:
                ch = FiltersViewController()
            case 5:
                ch = CacheSettings()
            case 6:
                let realm = try! Realm()
                try! realm.write {
                    realm.deleteAll()
                }
                
                SDImageCache.shared.clearMemory()
                SDImageCache.shared.clearDisk()
                
                do {
                    var cache_path = SDImageCache.shared.diskCachePath
                    cache_path += cache_path.endsWith("/") ? "" : "/"
                    let files = try FileManager.default.contentsOfDirectory(atPath: cache_path)
                    for file in files {
                        if file.endsWith(".mp4") {
                            try FileManager.default.removeItem(atPath: cache_path + file)
                        }
                    }
                } catch {
                    print(error)
                }
                let countBytes = ByteCountFormatter()
                countBytes.allowedUnits = [.useMB]
                countBytes.countStyle = .file
                let fileSize = countBytes.string(fromByteCount: Int64(SDImageCache.shared.totalDiskSize()))
                
                self.clearCell.detailTextLabel?.text = fileSize

                BannerUtil.makeBanner(text: "All caches cleared!", color: GMColor.green500Color(), seconds: 3, context: self)
            case 7:
                if !SettingValues.isPro {
                    ch = SettingsPro()
                } else {
                    ch = SettingsBackup()
                }
            case 8:
                ch = SettingsUserTags()
            default:
                break
            }
        case 3:
            switch indexPath.row {
            case 0:
                let url = UserDefaults.standard.string(forKey: "vlink")!
                VCPresenter.openRedditLink(url, self.navigationController, self)
            case 1:
                ch = SingleSubredditViewController.init(subName: "slide_ios", single: true)
            case 2:
                let url = URL.init(string: "https://github.com/ccrama/Slide-ios/graphs/contributors")!
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                } else {
                    UIApplication.shared.opnURL(url)
                }
            case 3:
                let url = URL.init(string: "https://github.com/ccrama/Slide-ios")!
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            case 4:
                ch = LicensesViewController()
                let file = Bundle.main.path(forResource: "Credits", ofType: "plist")!
                (ch as! LicensesViewController).loadPlist(NSDictionary(contentsOfFile: file)!)
            default:
                break
            }
        default:
            break

        }

        if let n = ch {
            VCPresenter.showVC(viewController: n, popupIfPossible: false, parentNavigationController: navigationController, parentViewController: self)
        }
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 14, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 24, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.theme.backgroundColor
        
        switch section {
        case 0: label.text = "General"
        case 1: label.text = "Appearance"
        case 2: label.text = "Content"
        case 3: label.text = "About"
        default: label.text = ""
        }
        return toReturn
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return (SettingValues.isPro) ? 5 : 6
        case 1: return 9
        case 2: return 9
        case 3: return 5
        default: fatalError("Unknown number of sections")
        }
    }

    func getVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "\(version) build \(build)"
    }

}
extension Bundle {
    public var icon: UIImage? {
        if #available(iOS 10.3, *) {
            if let alt = UIApplication.shared.alternateIconName {
                return UIImage(named: "ic_" + alt)
            }
        }
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}
