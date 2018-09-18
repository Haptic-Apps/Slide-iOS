//
//  SettingsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/10/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import BiometricAuthentication
import LicensesViewController
import MessageUI
import RealmSwift
import RLBAlertsPickers
import SDWebImage
import UIKit
import XLActionController

class SettingsViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    var goPro: UITableViewCell = UITableViewCell()

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
    var contributorsCell: UITableViewCell = UITableViewCell()
    var aboutCell: UITableViewCell = UITableViewCell()
    var githubCell: UITableViewCell = UITableViewCell()
    var clearCell: UITableViewCell = UITableViewCell()
    var cacheCell: UITableViewCell = UITableViewCell()
    var backupCell: UITableViewCell = UITableViewCell()
    var gestureCell: UITableViewCell = UITableViewCell()
    var autoPlayCell: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "autoplay")

    var multiColumnCell: UITableViewCell = UITableViewCell()
    var multiColumn = UISwitch()
    var lock = UISwitch()
    
    var reduceColorCell: UITableViewCell = UITableViewCell()
    var reduceColor = UISwitch()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if SettingsPro.changed {
            self.tableView.reloadData()
            let menuB = UIBarButtonItem(image: UIImage.init(named: "support")?.toolbarIcon().getCopy(withColor: GMColor.red500Color()), style: .plain, target: self, action: #selector(SettingsViewController.didPro(_:)))
            navigationItem.rightBarButtonItem = menuB
        }
        let button = UIButtonWithContext.init(type: .custom)
        button.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        button.setImage(UIImage.init(named: "back")!.navIcon(), for: UIControlState.normal)
        button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        
        let barButton = UIBarButtonItem.init(customView: button)
        
        navigationItem.leftBarButtonItem = barButton
    }
    
    @objc public func handleBackButton() {
        self.navigationController?.popViewController(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
        navigationController?.setToolbarHidden(true, animated: false)
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
        doCells()
    }
    
    func didPro(_ sender: AnyObject) {
        let alert = UIAlertController.init(title: "Pro Supporter", message: "Thank you for supporting my work and going Pro :)\n\nIf you need any assistance with pro features, feel free to send me a message!", preferredStyle: .alert)
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
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Settings"
        self.tableView.separatorStyle = .none

        self.general.textLabel?.text = "General"
        self.general.accessoryType = .disclosureIndicator
        self.general.backgroundColor = ColorUtil.foregroundColor
        self.general.textLabel?.textColor = ColorUtil.fontColor
        self.general.imageView?.image = UIImage.init(named: "settings")?.toolbarIcon()
        self.general.imageView?.tintColor = ColorUtil.fontColor

        self.manageSubs.textLabel?.text = "Manage your subreddits"
        self.manageSubs.accessoryType = .disclosureIndicator
        self.manageSubs.backgroundColor = ColorUtil.foregroundColor
        self.manageSubs.textLabel?.textColor = ColorUtil.fontColor
        self.manageSubs.imageView?.image = UIImage.init(named: "subs")?.toolbarIcon()
        self.manageSubs.imageView?.tintColor = ColorUtil.fontColor

        self.mainTheme.textLabel?.text = "Main theme"
        self.mainTheme.accessoryType = .disclosureIndicator
        self.mainTheme.backgroundColor = ColorUtil.foregroundColor
        self.mainTheme.textLabel?.textColor = ColorUtil.fontColor
        self.mainTheme.imageView?.image = UIImage.init(named: "palette")?.toolbarIcon()
        self.mainTheme.imageView?.tintColor = ColorUtil.fontColor

        self.goPro.textLabel?.text = "Support Slide, Go Pro!"
        self.goPro.accessoryType = .disclosureIndicator
        self.goPro.backgroundColor = ColorUtil.foregroundColor
        self.goPro.textLabel?.textColor = ColorUtil.fontColor
        self.goPro.imageView?.image = UIImage.init(named: "support")?.toolbarIcon().getCopy(withColor: GMColor.red500Color())
        self.goPro.imageView?.tintColor = ColorUtil.fontColor

        self.clearCell.textLabel?.text = "Clear cache"
        self.clearCell.accessoryType = .none
        self.clearCell.backgroundColor = ColorUtil.foregroundColor
        self.clearCell.textLabel?.textColor = ColorUtil.fontColor
        self.clearCell.imageView?.image = UIImage.init(named: "multis")?.toolbarIcon()
        self.clearCell.imageView?.tintColor = ColorUtil.fontColor

        self.backupCell.textLabel?.text = "Backup and Restore"
        self.backupCell.accessoryType = .disclosureIndicator
        self.backupCell.backgroundColor = ColorUtil.foregroundColor
        self.backupCell.textLabel?.textColor = ColorUtil.fontColor
        self.backupCell.imageView?.image = UIImage.init(named: "restore")?.toolbarIcon()
        self.backupCell.imageView?.tintColor = ColorUtil.fontColor

        self.gestureCell.textLabel?.text = "Gestures"
        self.gestureCell.accessoryType = .disclosureIndicator
        self.gestureCell.backgroundColor = ColorUtil.foregroundColor
        self.gestureCell.textLabel?.textColor = ColorUtil.fontColor
        self.gestureCell.imageView?.image = UIImage.init(named: "gestures")?.toolbarIcon()
        self.gestureCell.imageView?.tintColor = ColorUtil.fontColor

        self.cacheCell.textLabel?.text = "Offline caching"
        self.cacheCell.accessoryType = .disclosureIndicator
        self.cacheCell.backgroundColor = ColorUtil.foregroundColor
        self.cacheCell.textLabel?.textColor = ColorUtil.fontColor
        self.cacheCell.imageView?.image = UIImage.init(named: "save-1")?.toolbarIcon()
        self.cacheCell.imageView?.tintColor = ColorUtil.fontColor

        self.postLayout.textLabel?.text = "Submission layout"
        self.postLayout.accessoryType = .disclosureIndicator
        self.postLayout.backgroundColor = ColorUtil.foregroundColor
        self.postLayout.textLabel?.textColor = ColorUtil.fontColor
        self.postLayout.imageView?.image = UIImage.init(named: "layout")?.toolbarIcon()
        self.postLayout.imageView?.tintColor = ColorUtil.fontColor

        self.subThemes.textLabel?.text = "Subreddit themes"
        self.subThemes.accessoryType = .disclosureIndicator
        self.subThemes.backgroundColor = ColorUtil.foregroundColor
        self.subThemes.textLabel?.textColor = ColorUtil.fontColor
        self.subThemes.imageView?.image = UIImage.init(named: "subs")?.toolbarIcon()
        self.subThemes.imageView?.tintColor = ColorUtil.fontColor

        self.font.textLabel?.text = "Font"
        self.font.accessoryType = .disclosureIndicator
        self.font.backgroundColor = ColorUtil.foregroundColor
        self.font.textLabel?.textColor = ColorUtil.fontColor
        self.font.imageView?.image = UIImage.init(named: "size")?.toolbarIcon()
        self.font.imageView?.tintColor = ColorUtil.fontColor

        self.comments.textLabel?.text = "Comments"
        self.comments.accessoryType = .disclosureIndicator
        self.comments.backgroundColor = ColorUtil.foregroundColor
        self.comments.textLabel?.textColor = ColorUtil.fontColor
        self.comments.imageView?.image = UIImage.init(named: "comments")?.toolbarIcon()
        self.comments.imageView?.tintColor = ColorUtil.fontColor

        self.linkHandling.textLabel?.text = "Link handling"
        self.linkHandling.accessoryType = .disclosureIndicator
        self.linkHandling.backgroundColor = ColorUtil.foregroundColor
        self.linkHandling.textLabel?.textColor = ColorUtil.fontColor
        self.linkHandling.imageView?.image = UIImage.init(named: "link")?.toolbarIcon()
        self.linkHandling.imageView?.tintColor = ColorUtil.fontColor

        self.history.textLabel?.text = "History"
        self.history.accessoryType = .disclosureIndicator
        self.history.backgroundColor = ColorUtil.foregroundColor
        self.history.textLabel?.textColor = ColorUtil.fontColor
        self.history.imageView?.image = UIImage.init(named: "history")?.toolbarIcon()
        self.history.imageView?.tintColor = ColorUtil.fontColor

        self.dataSaving.textLabel?.text = "Data saving"
        self.dataSaving.accessoryType = .disclosureIndicator
        self.dataSaving.backgroundColor = ColorUtil.foregroundColor
        self.dataSaving.textLabel?.textColor = ColorUtil.fontColor
        self.dataSaving.imageView?.image = UIImage.init(named: "data")?.toolbarIcon()
        self.dataSaving.imageView?.tintColor = ColorUtil.fontColor

        self.content.textLabel?.text = "Content"
        self.content.accessoryType = .disclosureIndicator
        self.content.backgroundColor = ColorUtil.foregroundColor
        self.content.textLabel?.textColor = ColorUtil.fontColor
        self.content.imageView?.image = UIImage.init(named: "image")?.toolbarIcon()
        self.content.imageView?.tintColor = ColorUtil.fontColor

        self.subCell.textLabel?.text = "Visit the Slide subreddit!"
        self.subCell.accessoryType = .disclosureIndicator
        self.subCell.backgroundColor = ColorUtil.foregroundColor
        self.subCell.textLabel?.textColor = ColorUtil.fontColor
        self.subCell.imageView?.image = UIImage.init(named: "subs")?.toolbarIcon()
        self.subCell.imageView?.tintColor = ColorUtil.fontColor

        self.filters.textLabel?.text = "Filters"
        self.filters.accessoryType = .disclosureIndicator
        self.filters.backgroundColor = ColorUtil.foregroundColor
        self.filters.textLabel?.textColor = ColorUtil.fontColor
        self.filters.imageView?.image = UIImage.init(named: "filter")?.toolbarIcon()
        self.filters.imageView?.tintColor = ColorUtil.fontColor

        self.aboutCell.textLabel?.text = "Version: \(getVersion())"
        self.aboutCell.accessoryType = .disclosureIndicator
        self.aboutCell.backgroundColor = ColorUtil.foregroundColor
        self.aboutCell.textLabel?.textColor = ColorUtil.fontColor
        self.aboutCell.imageView?.image = UIImage.init(named: "info")?.toolbarIcon()
            
        self.aboutCell.imageView?.tintColor = ColorUtil.fontColor

        self.githubCell.textLabel?.text = "Github"
        self.githubCell.accessoryType = .disclosureIndicator
        self.githubCell.backgroundColor = ColorUtil.foregroundColor
        self.githubCell.textLabel?.textColor = ColorUtil.fontColor
        self.githubCell.imageView?.image = UIImage.init(named: "github")?.toolbarIcon()
        self.githubCell.imageView?.tintColor = ColorUtil.fontColor

        self.licenseCell.textLabel?.text = "Open source licenses"
        self.licenseCell.accessoryType = .disclosureIndicator
        self.licenseCell.backgroundColor = ColorUtil.foregroundColor
        self.licenseCell.textLabel?.textColor = ColorUtil.fontColor
        self.licenseCell.imageView?.image = UIImage.init(named: "code")?.toolbarIcon()
        self.licenseCell.imageView?.tintColor = ColorUtil.fontColor

        self.contributorsCell.textLabel?.text = "Slide project contributors"
        self.contributorsCell.accessoryType = .disclosureIndicator
        self.contributorsCell.backgroundColor = ColorUtil.foregroundColor
        self.contributorsCell.textLabel?.textColor = ColorUtil.fontColor
        self.contributorsCell.imageView?.image = UIImage.init(named: "happy")?.toolbarIcon()
        self.contributorsCell.imageView?.tintColor = ColorUtil.fontColor

        self.autoPlayCell.textLabel?.text = "Autoplay videos and gifs"
        self.autoPlayCell.accessoryType = .none
        self.autoPlayCell.backgroundColor = ColorUtil.foregroundColor
        self.autoPlayCell.textLabel?.textColor = ColorUtil.fontColor
        self.autoPlayCell.imageView?.image = UIImage.init(named: "play")?.toolbarIcon()
        self.autoPlayCell.imageView?.tintColor = ColorUtil.fontColor
        self.autoPlayCell.detailTextLabel?.textColor = ColorUtil.fontColor
        self.autoPlayCell.detailTextLabel?.text = SettingValues.autoPlayMode.description()
        self.autoPlayCell.detailTextLabel?.numberOfLines = 0
        self.autoPlayCell.detailTextLabel?.lineBreakMode = .byWordWrapping

        multiColumnCell.textLabel?.text = "Multi-Column mode settings"
        multiColumnCell.backgroundColor = ColorUtil.foregroundColor
        multiColumnCell.textLabel?.textColor = ColorUtil.fontColor
        multiColumnCell.selectionStyle = UITableViewCellSelectionStyle.none
        self.multiColumnCell.imageView?.image = UIImage.init(named: "multicolumn")?.toolbarIcon()
        self.multiColumnCell.imageView?.tintColor = ColorUtil.fontColor

        lock = UISwitch()
        lock.isOn = SettingValues.biometrics
        lock.isEnabled = BioMetricAuthenticator.canAuthenticate()
        lock.addTarget(self, action: #selector(SettingsViewController.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        lockCell.textLabel?.text = "Biometric app lock"
        lockCell.accessoryView = lock
        lockCell.backgroundColor = ColorUtil.foregroundColor
        lockCell.textLabel?.textColor = ColorUtil.fontColor
        lockCell.selectionStyle = UITableViewCellSelectionStyle.none
        self.lockCell.imageView?.image = UIImage.init(named: "lockapp")?.toolbarIcon()
        self.lockCell.imageView?.tintColor = ColorUtil.fontColor

        reduceColor = UISwitch()
        reduceColor.isOn = SettingValues.reduceColor
        reduceColor.addTarget(self, action: #selector(SettingsViewController.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        reduceColorCell.textLabel?.text = "Reduce app colors (experimental)"
        reduceColorCell.textLabel?.numberOfLines = 0
        reduceColorCell.accessoryView = reduceColor
        reduceColorCell.backgroundColor = ColorUtil.foregroundColor
        reduceColorCell.textLabel?.textColor = ColorUtil.fontColor
        reduceColorCell.selectionStyle = UITableViewCellSelectionStyle.none
        self.reduceColorCell.imageView?.image = UIImage.init(named: "colors")?.toolbarIcon()
        self.reduceColorCell.imageView?.tintColor = ColorUtil.fontColor

        if reset {
            self.tableView.reloadData()
        }
    }

    func switchIsChanged(_ changed: UISwitch) {
        if changed == reduceColor {
            MainViewController.needsRestart = true
            SettingValues.reduceColor = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_reduceColor)
            setupBaseBarColors()
            let button = UIButtonWithContext.init(type: .custom)
            button.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            button.setImage(UIImage.init(named: "back")!.navIcon(), for: UIControlState.normal)
            button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
            
            let barButton = UIBarButtonItem.init(customView: button)
            
            navigationItem.leftBarButtonItem = barButton
        } else if changed == multiColumn {
            SettingValues.multiColumn = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_multiColumn)
        } else if changed == lock {
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
        return 70
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
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
            case 2: return self.multiColumnCell
            case 3: return self.lockCell
            case 4: return self.gestureCell

            default: fatalError("Unknown row in section 0")
            }
        } else {
            switch indexPath.row {
            case 0: return self.general
            case 1: return self.manageSubs
            case 2: return self.goPro
            case 3: return self.multiColumnCell
            case 4: return self.lockCell
            case 5: return self.gestureCell
                
            default: fatalError("Unknown row in section 0")
            }
        }
        case 1:
            switch indexPath.row {
            case 0: return self.mainTheme
            case 1: return self.reduceColorCell
            case 2: return self.postLayout
            case 3: return self.autoPlayCell
            case 4: return self.subThemes
            case 5: return self.font
            case 6: return self.comments
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
            default: fatalError("Unknown row in section 2")
            }
        case 3:
            switch indexPath.row {
            case 0: return self.aboutCell
            case 1: return self.subCell
            case 2: return self.contributorsCell
            case 3: return self.githubCell
            case 4: return self.licenseCell
            default: fatalError("Unknown row in section 3")
            }
        default: fatalError("Unknown section")
        }

    }
    
    func showMultiColumn() {
        if !VCPresenter.proDialogShown(feature: true, self) {
            let actionSheetController: UIAlertController = UIAlertController(title: "Multi Column Mode", message: "", preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { _ -> Void in
            }
            actionSheetController.addAction(cancelActionButton)
            
            multiColumn = UISwitch.init(frame: CGRect.init(x: 20, y: 20, width: 75, height: 50))
            multiColumn.isOn = SettingValues.multiColumn
            multiColumn.addTarget(self, action: #selector(SettingsViewController.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
            actionSheetController.view.addSubview(multiColumn)
            
            let values = [["1", "2", "3", "4", "5"]]
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
    }

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
                    showMultiColumn()
                }
            case 3:
                if !SettingValues.isPro {
                    showMultiColumn()
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
            case 2:
                ch = SettingsLayout()
            case 4:
                ch = SubredditThemeViewController()
            case 3:
                let alertController: BottomSheetActionController = BottomSheetActionController()
                for item in SettingValues.AutoPlay.cases {
                    alertController.addAction(Action(ActionData(title: item.description()), style: .default, handler: { _ in
                        UserDefaults.standard.set(item.rawValue, forKey: SettingValues.pref_autoPlayMode)
                        SettingValues.autoPlayMode = item
                        UserDefaults.standard.synchronize()
                        self.autoPlayCell.detailTextLabel?.text = SettingValues.autoPlayMode.description()
                        SingleSubredditViewController.cellVersion += 1
                        SubredditReorderViewController.changed = true
                    }))
                }
                VCPresenter.presentAlert(alertController, parentVC: self)
            case 5:
                ch = SettingsFont()
            case 6:
                ch = SettingsComments()
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
                
                SDImageCache.shared().clearMemory()
                SDImageCache.shared().clearDisk()
                SDWebImageManager.shared().imageCache?.clearMemory()
                SDWebImageManager.shared().imageCache?.clearDisk()
                
                BannerUtil.makeBanner(text: "All caches cleared!", color: GMColor.green500Color(), seconds: 3, context: self)
            case 7:
                if !SettingValues.isPro {
                    ch = SettingsPro()
                } else {
                    ch = SettingsBackup()
                }
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
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor

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
        case 1: return 7
        case 2: return 8
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
