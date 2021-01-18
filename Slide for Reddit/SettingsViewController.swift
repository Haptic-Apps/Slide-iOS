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

import RLBAlertsPickers
import SDWebImage
import UIKit

class SettingsViewController: MediaTableViewController, MFMailComposeViewControllerDelegate {
    var goPro: UITableViewCell = InsetCell()

    var general: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: "general")
    var manageSubs: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: "managesubs")
    var mainTheme: UITableViewCell = InsetCell()
    var postLayout: UITableViewCell = InsetCell()
    var icon: UITableViewCell = InsetCell()
    var subThemes: UITableViewCell = InsetCell()
    var font: UITableViewCell = InsetCell()
    var comments: UITableViewCell = InsetCell()
    var linkHandling: UITableViewCell = InsetCell()
    var history: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: "history")
    var dataSaving: UITableViewCell = InsetCell()
    var filters: UITableViewCell = InsetCell()
    var content: UITableViewCell = InsetCell()
    var lockCell: UITableViewCell = InsetCell()
    var subIconsCell: UITableViewCell = InsetCell()
    var subCell: UITableViewCell = InsetCell()
    var licenseCell: UITableViewCell = InsetCell()
    var contributorsCell: UITableViewCell = InsetCell()
    var aboutCell: UITableViewCell = InsetCell()
    var githubCell: UITableViewCell = InsetCell()
    var clearCell: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: "cache")
    var cacheCell: UITableViewCell = InsetCell()
    var backupCell: UITableViewCell = InsetCell()
    var gestureCell: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: "gestures")
    var widgetsCell: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: "widgets")
    var autoPlayCell: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: "autoplay")
    var tagsCell: UITableViewCell = InsetCell()
    var audioSettings = InsetCell()
    var postActionCell: UITableViewCell = InsetCell()
    var shortcutCell: UITableViewCell = InsetCell()
    var coffeeCell: UITableViewCell = InsetCell()

    var viewModeCell: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: "viewmode")
    var lock = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var subIcons = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if UIColor.isLightTheme && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lock.onTintColor = ColorUtil.baseAccent
        if SettingsPro.changed {
            doPro()
        }
        let button = UIButtonWithContext(buttonImage: UIImage(sfString: SFSymbol.xmark, overrideString: "close"))
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        
        let barButton = UIBarButtonItem.init(customView: button)
        
        navigationItem.leftBarButtonItem = barButton
    }
    
    func doPro() {
        self.tableView.reloadData()
        let menuB = UIBarButtonItem(image: UIImage(sfString: SFSymbol.heartCircleFill, overrideString: "support")?.toolbarIcon().getCopy(withColor: GMColor.red500Color()), style: .plain, target: self, action: #selector(SettingsViewController.didPro(_:)))
        navigationItem.rightBarButtonItem = menuB
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
        
        if (oldAppMode == .MULTI_COLUMN || oldAppMode == .SINGLE) && SettingValues.appMode == .SPLIT {
            let alert = UIAlertController(title: "Switching to Split Content mode requires an app restart", message: "Would you like to close Slide now, or have changes applied next time you open Slide?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close Slide now", style: UIAlertAction.Style.destructive, handler: { (_) in
                UserDefaults.standard.synchronize()
                exit(0)
            }))
            alert.addAction(UIAlertAction(title: "Apply later", style: UIAlertAction.Style.cancel, handler: { (_) in
                self.oldAppMode = SettingValues.appMode
            }))
            self.present(alert, animated: true, completion: nil)
        } else   if (SettingValues.appMode == .MULTI_COLUMN || SettingValues.appMode == .SINGLE) && oldAppMode == .SPLIT {
            let alert = UIAlertController(title: "Switching to Columned mode requires an app restart", message: "Would you like to close Slide now, or have changes applied next time you open Slide?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close Slide now", style: UIAlertAction.Style.destructive, handler: { (_) in
                UserDefaults.standard.synchronize()
                exit(0)
            }))
            alert.addAction(UIAlertAction(title: "Apply later", style: UIAlertAction.Style.cancel, handler: { (_) in
                self.oldAppMode = SettingValues.appMode
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    var oldAppMode = SettingValues.appMode
    
    override func loadView() {
        super.loadView()
        if SettingValues.isPro {
            let menuB = UIBarButtonItem(image: UIImage(sfString: SFSymbol.heartCircleFill, overrideString: "support")?.toolbarIcon().getCopy(withColor: GMColor.red500Color()), style: .plain, target: self, action: #selector(SettingsViewController.didPro(_:)))
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
        self.view.backgroundColor = UIColor.backgroundColor
        // set the title
        self.title = "Settings"
        self.tableView.separatorStyle = .none
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200

        self.general.textLabel?.text = "General"
        self.general.accessoryType = .disclosureIndicator
        self.general.backgroundColor = UIColor.foregroundColor
        self.general.textLabel?.textColor = UIColor.fontColor
        self.general.imageView?.image = UIImage(sfString: SFSymbol.gear, overrideString: "settings")?.toolbarIcon()
        self.general.imageView?.tintColor = UIColor.fontColor
        self.general.detailTextLabel?.textColor = UIColor.fontColor
        self.general.detailTextLabel?.text = "Display settings, haptic feedback and default sorting"
        
        self.general.detailTextLabel?.numberOfLines = 0
        self.general.detailTextLabel?.lineBreakMode = .byWordWrapping

        self.manageSubs.textLabel?.text = "Subscriptions"
        self.manageSubs.accessoryType = .disclosureIndicator
        self.manageSubs.backgroundColor = UIColor.foregroundColor
        self.manageSubs.textLabel?.textColor = UIColor.fontColor
        self.manageSubs.imageView?.image = UIImage(sfString: .rCircleFill, overrideString: "subs")?.toolbarIcon()
        self.manageSubs.imageView?.tintColor = UIColor.fontColor
        self.manageSubs.detailTextLabel?.textColor = UIColor.fontColor
        self.manageSubs.detailTextLabel?.text = "Manage your subscriptions and rearrange the sidebar"
        self.manageSubs.detailTextLabel?.numberOfLines = 0

        self.postActionCell.textLabel?.text = "Reorder post actions"
        self.postActionCell.accessoryType = .disclosureIndicator
        self.postActionCell.backgroundColor = UIColor.foregroundColor
        self.postActionCell.textLabel?.textColor = UIColor.fontColor
        self.postActionCell.imageView?.image = UIImage(sfString: SFSymbol.arrowUpArrowDownCircleFill, overrideString: "compact")?.toolbarIcon()
        self.postActionCell.imageView?.tintColor = UIColor.fontColor

        self.shortcutCell.textLabel?.text = "Reorder homepage shortcuts"
        self.shortcutCell.accessoryType = .disclosureIndicator
        self.shortcutCell.backgroundColor = UIColor.foregroundColor
        self.shortcutCell.textLabel?.textColor = UIColor.fontColor
        self.shortcutCell.imageView?.image = UIImage(sfString: SFSymbol.boltFill, overrideString: "compact")?.toolbarIcon()
        self.shortcutCell.imageView?.tintColor = UIColor.fontColor

        self.mainTheme.textLabel?.text = "App theme"
        self.mainTheme.accessoryType = .disclosureIndicator
        self.mainTheme.backgroundColor = UIColor.foregroundColor
        self.mainTheme.textLabel?.textColor = UIColor.fontColor
        self.mainTheme.imageView?.image = UIImage(named: "palette")?.toolbarIcon()
        self.mainTheme.imageView?.tintColor = UIColor.fontColor

        self.icon.textLabel?.text = "App icon"
        self.icon.accessoryType = .disclosureIndicator
        self.icon.backgroundColor = UIColor.foregroundColor
        self.icon.textLabel?.textColor = UIColor.fontColor
        self.icon.imageView?.image = Bundle.main.icon?.getCopy(withSize: CGSize(width: 25, height: 25))
        self.icon.imageView?.layer.cornerRadius = 5
        self.icon.imageView?.clipsToBounds = true

        self.tagsCell.textLabel?.text = "User Tags Management"
        self.tagsCell.accessoryType = .disclosureIndicator
        self.tagsCell.backgroundColor = UIColor.foregroundColor
        self.tagsCell.textLabel?.textColor = UIColor.fontColor
        self.tagsCell.imageView?.image = UIImage(sfString: SFSymbol.tagFill, overrideString: "user")?.toolbarIcon()
        self.tagsCell.imageView?.tintColor = UIColor.fontColor

        self.goPro.textLabel?.text = "Support Slide, go Pro!"
        self.goPro.accessoryType = .disclosureIndicator
        self.goPro.backgroundColor = UIColor.foregroundColor
        self.goPro.textLabel?.textColor = UIColor.fontColor
        self.goPro.imageView?.image = UIImage(sfString: SFSymbol.heartCircleFill, overrideString: "support")?.toolbarIcon().getCopy(withColor: GMColor.red500Color())
        self.goPro.imageView?.tintColor = UIColor.fontColor

        self.coffeeCell.textLabel?.text = "Tip Jar"
        self.coffeeCell.accessoryType = .disclosureIndicator
        self.coffeeCell.backgroundColor = UIColor.foregroundColor
        self.coffeeCell.textLabel?.textColor = UIColor.fontColor
        self.coffeeCell.imageView?.image = UIImage(sfString: SFSymbol.heartCircleFill, overrideString: "support")?.toolbarIcon().getCopy(withColor: GMColor.lightGreen500Color())
        self.coffeeCell.imageView?.tintColor = UIColor.fontColor

        self.clearCell.textLabel?.text = "Clear cache"
        self.clearCell.accessoryType = .none
        self.clearCell.backgroundColor = UIColor.foregroundColor
        self.clearCell.textLabel?.textColor = UIColor.fontColor
        self.clearCell.imageView?.image = UIImage(sfString: SFSymbol.trashFill, overrideString: "multis")?.toolbarIcon()
        self.clearCell.imageView?.tintColor = UIColor.fontColor
        self.clearCell.detailTextLabel?.textColor = UIColor.fontColor
        let countBytes = ByteCountFormatter()
        countBytes.allowedUnits = [.useMB]
        countBytes.countStyle = .file
        let fileSize = countBytes.string(fromByteCount: Int64(SDImageCache.shared.totalDiskSize() + UInt(checkRealmFileSize())))

        self.clearCell.detailTextLabel?.text = fileSize
        self.clearCell.detailTextLabel?.numberOfLines = 0

        self.backupCell.textLabel?.text = "Backup and Restore"
        self.backupCell.accessoryType = .disclosureIndicator
        self.backupCell.backgroundColor = UIColor.foregroundColor
        self.backupCell.textLabel?.textColor = UIColor.fontColor
        self.backupCell.imageView?.image = UIImage(sfString: SFSymbol.arrowCounterclockwise, overrideString: "restore")?.toolbarIcon()
        self.backupCell.imageView?.tintColor = UIColor.fontColor

        self.gestureCell.textLabel?.text = "Gestures"
        self.gestureCell.accessoryType = .disclosureIndicator
        self.gestureCell.backgroundColor = UIColor.foregroundColor
        self.gestureCell.textLabel?.textColor = UIColor.fontColor
        self.gestureCell.imageView?.image = UIImage(sfString: .scribble, overrideString: "gestures")?.toolbarIcon()
        self.gestureCell.imageView?.tintColor = UIColor.fontColor
        self.gestureCell.detailTextLabel?.textColor = UIColor.fontColor
        self.gestureCell.detailTextLabel?.text = "Swipe and tap gestures for submissions and comments"
        self.gestureCell.detailTextLabel?.numberOfLines = 0

        self.widgetsCell.textLabel?.text = "Widgets"
        self.widgetsCell.accessoryType = .disclosureIndicator
        self.widgetsCell.backgroundColor = UIColor.foregroundColor
        self.widgetsCell.textLabel?.textColor = UIColor.fontColor
        self.widgetsCell.imageView?.image = UIImage(sfString: .squareGrid2x2, overrideString: "gestures")?.toolbarIcon()
        self.widgetsCell.imageView?.tintColor = UIColor.fontColor
        self.widgetsCell.detailTextLabel?.textColor = UIColor.fontColor
        self.widgetsCell.detailTextLabel?.text = "Create subreddit lists for Slide widgets"
        self.widgetsCell.detailTextLabel?.numberOfLines = 0

        self.cacheCell.textLabel?.text = "Offline caching"
        self.cacheCell.accessoryType = .disclosureIndicator
        self.cacheCell.backgroundColor = UIColor.foregroundColor
        self.cacheCell.textLabel?.textColor = UIColor.fontColor
        self.cacheCell.imageView?.image = UIImage(sfString: SFSymbol.arrow2Circlepath, overrideString: "save-1")?.toolbarIcon()
        self.cacheCell.imageView?.tintColor = UIColor.fontColor

        self.postLayout.textLabel?.text = "Card layout"
        self.postLayout.accessoryType = .disclosureIndicator
        self.postLayout.backgroundColor = UIColor.foregroundColor
        self.postLayout.textLabel?.textColor = UIColor.fontColor
        self.postLayout.imageView?.image = UIImage(sfString: SFSymbol.squareStack3dUpFill, overrideString: "layout")?.toolbarIcon()
        self.postLayout.imageView?.tintColor = UIColor.fontColor

        self.subThemes.textLabel?.text = "Subreddit themes"
        self.subThemes.accessoryType = .disclosureIndicator
        self.subThemes.backgroundColor = UIColor.foregroundColor
        self.subThemes.textLabel?.textColor = UIColor.fontColor
        self.subThemes.imageView?.image = UIImage(sfString: .eyedropperHalffull, overrideString: "subs")?.toolbarIcon()
        self.subThemes.imageView?.tintColor = UIColor.fontColor

        self.font.textLabel?.text = "Font and Links"
        self.font.accessoryType = .disclosureIndicator
        self.font.backgroundColor = UIColor.foregroundColor
        self.font.textLabel?.textColor = UIColor.fontColor
        self.font.imageView?.image = UIImage(sfString: SFSymbol.textformat, overrideString: "size")?.toolbarIcon()
        self.font.imageView?.tintColor = UIColor.fontColor

        self.comments.textLabel?.text = "Comments"
        self.comments.accessoryType = .disclosureIndicator
        self.comments.backgroundColor = UIColor.foregroundColor
        self.comments.textLabel?.textColor = UIColor.fontColor
        self.comments.imageView?.image = UIImage(sfString: SFSymbol.bubbleLeftAndBubbleRightFill, overrideString: "comments")?.toolbarIcon()
        self.comments.imageView?.tintColor = UIColor.fontColor

        self.linkHandling.textLabel?.text = "Link handling"
        self.linkHandling.accessoryType = .disclosureIndicator
        self.linkHandling.backgroundColor = UIColor.foregroundColor
        self.linkHandling.textLabel?.textColor = UIColor.fontColor
        self.linkHandling.imageView?.image = UIImage(sfString: SFSymbol.link, overrideString: "link")?.toolbarIcon()
        self.linkHandling.imageView?.tintColor = UIColor.fontColor

        self.history.textLabel?.text = "History"
        self.history.accessoryType = .disclosureIndicator
        self.history.backgroundColor = UIColor.foregroundColor
        self.history.textLabel?.textColor = UIColor.fontColor
        self.history.imageView?.image = UIImage(sfString: SFSymbol.clockFill, overrideString: "history")?.toolbarIcon()
        self.history.imageView?.tintColor = UIColor.fontColor
        self.history.detailTextLabel?.textColor = UIColor.fontColor
        self.history.detailTextLabel?.text = "\(History.seenTimes.allKeys.count) visited posts"
        self.history.detailTextLabel?.numberOfLines = 0

        self.dataSaving.textLabel?.text = "Data saving"
        self.dataSaving.accessoryType = .disclosureIndicator
        self.dataSaving.backgroundColor = UIColor.foregroundColor
        self.dataSaving.textLabel?.textColor = UIColor.fontColor
        self.dataSaving.imageView?.image = UIImage(sfString: SFSymbol.wifiExclamationmark, overrideString: "data")?.toolbarIcon()
        self.dataSaving.imageView?.tintColor = UIColor.fontColor

        self.content.textLabel?.text = "NSFW Content"
        self.content.accessoryType = .disclosureIndicator
        self.content.backgroundColor = UIColor.foregroundColor
        self.content.textLabel?.textColor = UIColor.fontColor
        self.content.imageView?.image = UIImage(sfString: SFSymbol.eyeSlashFill, overrideString: "image")?.toolbarIcon()
        self.content.imageView?.tintColor = UIColor.fontColor

        self.subCell.textLabel?.text = "Visit the Slide subreddit!"
        self.subCell.accessoryType = .disclosureIndicator
        self.subCell.backgroundColor = UIColor.foregroundColor
        self.subCell.textLabel?.textColor = UIColor.fontColor
        self.subCell.imageView?.image = UIImage(sfString: .rCircleFill, overrideString: "subs")?.toolbarIcon()
        self.subCell.imageView?.tintColor = UIColor.fontColor

        self.filters.textLabel?.text = "Filters"
        self.filters.accessoryType = .disclosureIndicator
        self.filters.backgroundColor = UIColor.foregroundColor
        self.filters.textLabel?.textColor = UIColor.fontColor
        self.filters.imageView?.image = UIImage(named: "filter")?.toolbarIcon()
        self.filters.imageView?.tintColor = UIColor.fontColor

        self.aboutCell.textLabel?.text = "Version: \(getVersion())"
        self.aboutCell.accessoryType = .disclosureIndicator
        self.aboutCell.backgroundColor = UIColor.foregroundColor
        self.aboutCell.textLabel?.textColor = UIColor.fontColor
        self.aboutCell.imageView?.image = UIImage(sfString: SFSymbol.infoCircleFill, overrideString: "info")?.toolbarIcon()
            
        self.aboutCell.imageView?.tintColor = UIColor.fontColor

        self.githubCell.textLabel?.text = "Github"
        self.githubCell.accessoryType = .disclosureIndicator
        self.githubCell.backgroundColor = UIColor.foregroundColor
        self.githubCell.textLabel?.textColor = UIColor.fontColor
        self.githubCell.imageView?.image = UIImage(named: "github")?.toolbarIcon()
        self.githubCell.imageView?.tintColor = UIColor.fontColor

        self.licenseCell.textLabel?.text = "Open source licenses"
        self.licenseCell.accessoryType = .disclosureIndicator
        self.licenseCell.backgroundColor = UIColor.foregroundColor
        self.licenseCell.textLabel?.textColor = UIColor.fontColor
        self.licenseCell.imageView?.image = UIImage(sfString: SFSymbol.chevronLeftSlashChevronRight, overrideString: "code")?.toolbarIcon()
        self.licenseCell.imageView?.tintColor = UIColor.fontColor

        self.contributorsCell.textLabel?.text = "Slide project contributors"
        self.contributorsCell.accessoryType = .disclosureIndicator
        self.contributorsCell.backgroundColor = UIColor.foregroundColor
        self.contributorsCell.textLabel?.textColor = UIColor.fontColor
        self.contributorsCell.imageView?.image = UIImage(sfString: SFSymbol.smileyFill, overrideString: "happy")?.toolbarIcon()
        self.contributorsCell.imageView?.tintColor = UIColor.fontColor

        self.autoPlayCell.textLabel?.text = "Autoplay videos and gifs"
        self.autoPlayCell.accessoryType = .none
        self.autoPlayCell.backgroundColor = UIColor.foregroundColor
        self.autoPlayCell.textLabel?.textColor = UIColor.fontColor
        self.autoPlayCell.imageView?.image = UIImage(sfString: SFSymbol.playFill, overrideString: "play")?.toolbarIcon()
        self.autoPlayCell.imageView?.tintColor = UIColor.fontColor
        self.autoPlayCell.detailTextLabel?.textColor = UIColor.fontColor
        self.autoPlayCell.detailTextLabel?.text = SettingValues.autoPlayMode.description() + "\nAutoplaying videos can lead to more data use"
        self.autoPlayCell.detailTextLabel?.numberOfLines = 0
        self.autoPlayCell.detailTextLabel?.lineBreakMode = .byWordWrapping

        viewModeCell.textLabel?.text = "Multi-Column and app behavior"
        viewModeCell.accessoryType = .disclosureIndicator
        viewModeCell.backgroundColor = UIColor.foregroundColor
        viewModeCell.textLabel?.textColor = UIColor.fontColor
        viewModeCell.selectionStyle = UITableViewCell.SelectionStyle.none
        self.viewModeCell.imageView?.image = UIImage(sfString: SFSymbol.sidebarLeft, overrideString: "multicolumn")?.toolbarIcon()
        self.viewModeCell.imageView?.tintColor = UIColor.fontColor
        self.viewModeCell.detailTextLabel?.textColor = UIColor.fontColor
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
        lockCell.backgroundColor = UIColor.foregroundColor
        lockCell.textLabel?.textColor = UIColor.fontColor
        lockCell.selectionStyle = UITableViewCell.SelectionStyle.none
        self.lockCell.imageView?.image = UIImage(sfString: SFSymbol.lockFill, overrideString: "lockapp")?.toolbarIcon()
        self.lockCell.imageView?.tintColor = UIColor.fontColor

        subIcons = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        subIcons.isOn = SettingValues.subredditIcons
        subIcons.addTarget(self, action: #selector(SettingsViewController.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        subIconsCell.textLabel?.text = "Subreddit Icons on posts"
        subIconsCell.accessoryView = subIcons
        subIconsCell.backgroundColor = UIColor.foregroundColor
        subIconsCell.textLabel?.textColor = UIColor.fontColor
        subIconsCell.selectionStyle = UITableViewCell.SelectionStyle.none
        self.subIconsCell.imageView?.image = UIImage(named: "icon")?.getCopy(withSize: CGSize(width: 25, height: 25))
        self.subIconsCell.imageView?.layer.cornerRadius = 12.5
        self.subIconsCell.imageView?.clipsToBounds = true

        audioSettings.textLabel?.text = "Audio"
        audioSettings.accessoryType = .disclosureIndicator
        audioSettings.backgroundColor = UIColor.foregroundColor
        audioSettings.textLabel?.textColor = UIColor.fontColor
        audioSettings.imageView?.image = UIImage(sfString: SFSymbol.speaker3Fill, overrideString: "audio")?.toolbarIcon()
        audioSettings.imageView?.tintColor = UIColor.fontColor

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
        } else if changed == subIcons {
            SingleSubredditViewController.cellVersion += 1
            MainViewController.needsReTheme = true

            SettingValues.subredditIcons = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_subredditIcons)
        }

        UserDefaults.standard.synchronize()
    }
    
    func checkRealmFileSize() -> Double {
        if let realmPath = SlideCoreData.getCoreDataDBPath() {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: realmPath.absoluteString)
                if let fileSize = attributes[FileAttributeKey.size] as? Double {

                    return fileSize
                }
            } catch let error {
                print(error)
            }
        }
        return 0
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
        return UITableView.automaticDimension
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        switch indexPath.section {
        case 0:
        if SettingValues.isPro {
            switch indexPath.row {
            case 0: cell = self.general
            case 1: cell = self.manageSubs
            case 2: cell = self.viewModeCell
            case 3: cell = self.lockCell
            case 4: cell = self.subIconsCell
            case 5: cell = self.gestureCell
            case 6: cell = self.widgetsCell

            default: fatalError("Unknown row in section 0")
            }
        } else {
            switch indexPath.row {
            case 0: cell = self.general
            case 1: cell = self.manageSubs
            case 2: cell = self.goPro
            case 3: cell = self.viewModeCell
            case 4: cell = self.lockCell
            case 5: cell = self.subIconsCell
            case 6: cell = self.gestureCell
            case 7: cell = self.widgetsCell

            default: fatalError("Unknown row in section 0")
            }
        }
        case 1:
            switch indexPath.row {
            case 0: cell = self.mainTheme
            case 1: cell = self.icon
            case 2: cell = self.postLayout
            case 3: cell = self.autoPlayCell
            case 4: cell = self.audioSettings
            case 5: cell = self.subThemes
            case 6: cell = self.font
            case 7: cell = self.comments
            case 8: cell = self.postActionCell
            case 9: cell = self.shortcutCell
            default: fatalError("Unknown row in section 1")
            }
        case 2:
            switch indexPath.row {
            case 0: cell = self.linkHandling
            case 1: cell = self.history
            case 2: cell = self.dataSaving
            case 3: cell = self.content
            case 4: cell = self.filters
            case 5: cell = self.cacheCell
            case 6: cell = self.clearCell
            case 7: cell = self.backupCell
            case 8: cell = self.tagsCell
            default: fatalError("Unknown row in section 2")
            }
        case 3:
            switch indexPath.row {
            case 0: cell = self.aboutCell
            case 1: cell = self.subCell
            case 2: cell = self.contributorsCell
            //case 4: return self.coffeeCell
            case 3: cell = self.githubCell
            case 4: cell = self.licenseCell
            default: fatalError("Unknown row in section 3")
            }
        default: fatalError("Unknown section")
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? InsetCell {
            if indexPath.row == 0 {
                cell.top = true
            } else {
                cell.top = false
            }
            if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
                cell.bottom = true
            } else {
                cell.bottom = false
            }
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
                    _ = VCPresenter.proDialogShown(feature: true, self)
                } else {
                    ch = SettingsViewMode()
                }
            case 3:
                if !SettingValues.isPro {
                    ch = SettingsViewMode()
                }
            case 5:
                if SettingValues.isPro {
                    ch = SettingsGestures()
                }
            case 6:
                if !SettingValues.isPro {
                    ch = SettingsGestures()
                } else {
                    ch = SettingsWidget()
                }
            case 7:
                ch = SettingsWidget()
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
            case 9:
                ch = SettingsShortcutMenu()
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
                ch = SettingsContentFilters()
            case 5:
                ch = CacheSettings()
            case 6:
                let activity = UIActivityIndicatorView()
                activity.color = UIColor.navIconColor
                activity.hidesWhenStopped = true
                activity.backgroundColor = UIColor.foregroundColor

                clearCell.addSubview(activity)
                activity.startAnimating()
                
                activity.rightAnchor /==/ clearCell.rightAnchor - 16
                activity.centerYAnchor /==/ clearCell.centerYAnchor

                DispatchQueue.global(qos: .background).async { [weak self] in
                    guard let self = self else { return }
                    
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
                    
                    do {
                        let fileManager = FileManager.default

                        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                        let directoryContents = try fileManager.contentsOfDirectory(atPath: dirPath)

                        for path in directoryContents {
                            if path.contains("realm") {
                                let writePath = URL(fileURLWithPath: dirPath).appendingPathComponent(path)
                                try fileManager.removeItem(at: writePath)
                            }
                        }
                    } catch {
                        
                    }

                    let countBytes = ByteCountFormatter()
                    countBytes.allowedUnits = [.useMB]
                    countBytes.countStyle = .file
                    let fileSize = countBytes.string(fromByteCount: Int64(SDImageCache.shared.totalDiskSize() + UInt(self.checkRealmFileSize())))
                    
                    DispatchQueue.main.async {
                        self.clearCell.accessoryType = .disclosureIndicator
                        BannerUtil.makeBanner(text: "All caches cleared!", color: GMColor.green500Color(), seconds: 3, context: self)
                        self.clearCell.detailTextLabel?.text = fileSize
                        activity.stopAnimating()
                    }
                }

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
                var url = UserDefaults.standard.string(forKey: "vlink") ?? ""
                if url.isEmpty {
                    url = "https://www.reddit.com/r/slide_ios"
                } else {
                    VCPresenter.openRedditLink(url, self.navigationController, self)
                }
            case 1:
                ch = SingleSubredditViewController.init(subName: "slide_ios", single: true)
            case 2:
                let url = URL.init(string: "https://github.com/ccrama/Slide-ios/graphs/contributors")!
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            case 3:
                let url = URL.init(string: "https://github.com/ccrama/Slide-ios")!
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
        toReturn.backgroundColor = UIColor.backgroundColor
        
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
        var iOS14 = false
        if #available(iOS 14.0, *) {
            iOS14 = true
        }
        switch section {
        case 0: return ((SettingValues.isPro) ? 6 : 7) + (iOS14 ? 1 : 0)
        case 1: return 10
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
