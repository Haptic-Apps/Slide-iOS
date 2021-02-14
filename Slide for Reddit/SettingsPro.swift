//
//  SettingsPro.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/07/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import BiometricAuthentication
import LicensesViewController
import MessageUI

import RLBAlertsPickers
import SDWebImage
import UIKit

class SettingsPro: UITableViewController, MFMailComposeViewControllerDelegate {
    
    static var changed = false

    var restore: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "restore")
    var shadowbox: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "shadow")
    var gallery: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "gallery")
    var biometric: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "bio")
    var multicolumn: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "multi")
    var autocache: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "auto")
    var night: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "night")
    var username: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "username")
    var icons: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "icons")
    var custom: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "custom")
    var themes: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "themes")
    var backup: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "backup")

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView?.reloadData()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
        navigationController?.setToolbarHidden(true, animated: false)
    }

    override func loadView() {
        super.loadView()
    }
    
    var cellsDone = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !cellsDone {
            cellsDone = true
            doCells()
            tableView?.reloadData()
        }
    }
    
    var three = UILabel()
    var six = UILabel()

    func doCells(_ reset: Bool = true) {
        self.view.backgroundColor = UIColor.backgroundColor
        // set the title
        self.title = "Support Slide!"
        self.tableView.separatorStyle = .none

        self.night.textLabel?.text = "Auto night mode"
        self.night.detailTextLabel?.text = "Select a custom night theme and night hours, Slide does the rest"
        self.night.detailTextLabel?.numberOfLines = 0
        self.night.backgroundColor = UIColor.foregroundColor
        self.night.textLabel?.textColor = UIColor.fontColor
        self.night.imageView?.image = UIImage(sfString: SFSymbol.moonStarsFill, overrideString: "night")?.toolbarIcon()
        self.night.imageView?.tintColor = UIColor.fontColor
        self.night.detailTextLabel?.textColor = UIColor.fontColor
        
        self.username.textLabel?.text = "Username scrubbing"
        self.username.detailTextLabel?.text = "Keep your account names a secret"
        self.username.detailTextLabel?.numberOfLines = 0
        self.username.backgroundColor = UIColor.foregroundColor
        self.username.textLabel?.textColor = UIColor.fontColor
        self.username.imageView?.image = UIImage(sfString: SFSymbol.xmark, overrideString: "hide")?.toolbarIcon()
        self.username.imageView?.tintColor = UIColor.fontColor
        self.username.detailTextLabel?.textColor = UIColor.fontColor

        self.icons.textLabel?.text = "Premium Icons"
        self.icons.detailTextLabel?.text = "Freshen up your homescreen with a new icon"
        self.icons.detailTextLabel?.numberOfLines = 0
        self.icons.backgroundColor = UIColor.foregroundColor
        self.icons.textLabel?.textColor = UIColor.fontColor
        self.icons.imageView?.image = UIImage(named: "ic_retroapple")?.getCopy(withSize: CGSize(width: 25, height: 25))
        self.icons.imageView?.layer.cornerRadius = 10
        self.icons.imageView?.clipsToBounds = true
        self.icons.detailTextLabel?.textColor = UIColor.fontColor

        self.backup.textLabel?.text = "Backup and Restore"
        self.backup.detailTextLabel?.text = "Sync your Slide settings between devices"
        self.backup.detailTextLabel?.numberOfLines = 0
        self.backup.backgroundColor = UIColor.foregroundColor
        self.backup.textLabel?.textColor = UIColor.fontColor
        self.backup.imageView?.image = UIImage.init(sfString: SFSymbol.squareAndArrowDownFill, overrideString: "download")?.toolbarIcon()
        self.backup.imageView?.tintColor = UIColor.fontColor
        self.backup.detailTextLabel?.textColor = UIColor.fontColor

        self.custom.textLabel?.text = "Custom theme colors"
        self.custom.detailTextLabel?.text = "Choose a custom color for your themes"
        self.custom.detailTextLabel?.numberOfLines = 0
        self.custom.backgroundColor = UIColor.foregroundColor
        self.custom.detailTextLabel?.textColor = UIColor.fontColor
        self.custom.textLabel?.textColor = UIColor.fontColor
        self.custom.imageView?.image = UIImage(sfString: SFSymbol.eyedropperFull, overrideString: "accent")?.toolbarIcon()
        self.custom.imageView?.tintColor = UIColor.fontColor
        
        self.themes.textLabel?.text = "Custom app themes"
        self.themes.detailTextLabel?.text = "Unlocks powerful theme customization options"
        self.themes.backgroundColor = UIColor(hexString: "#16161C")
        self.themes.detailTextLabel?.numberOfLines = 0
        self.themes.detailTextLabel?.textColor = .white
        self.themes.textLabel?.textColor = .white
        self.themes.imageView?.image = UIImage(named: "palette")?.toolbarIcon().getCopy(withColor: .white)
        self.themes.imageView?.tintColor = .white
        
        self.restore.textLabel?.text = "Already a supporter?"
        self.restore.accessoryType = .disclosureIndicator
        self.restore.backgroundColor = UIColor.foregroundColor
        self.restore.textLabel?.textColor = GMColor.lightGreen300Color()
        self.restore.imageView?.image = UIImage(sfString: SFSymbol.arrowClockwise, overrideString: "restore")?.toolbarIcon().getCopy(withColor: GMColor.lightGreen300Color())
        self.restore.imageView?.tintColor = GMColor.lightGreen300Color()
        self.restore.detailTextLabel?.textColor = GMColor.lightGreen300Color()
        self.restore.detailTextLabel?.text = "Restore your purchase!"
        
        let aboutArea = UIView()
        let about = UILabel(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 30))
        about.font = UIFont.systemFont(ofSize: 15)
        aboutArea.backgroundColor = UIColor.foregroundColor
        about.textColor = UIColor.fontColor
        about.text = "Go Pro to enjoy some awesome new features while supporting open source software!\n\nThis project wouldn't be possible without your support, as being ad and tracker free is core to Slide's mission.\n-Carlos"
        about.numberOfLines = 0
        about.textAlignment = .left
        about.lineBreakMode = .byClipping
        about.sizeToFit()
        
        three = UILabel(frame: CGRect.init(x: 0, y: 0, width: 100, height: 45))
        three.text = "Go pro for $4.99"
        three.backgroundColor = GMColor.lightGreen300Color()
        three.layer.cornerRadius = 22.5
        three.clipsToBounds = true
        three.numberOfLines = 0
        three.lineBreakMode = .byWordWrapping
        three.textColor = .white
        three.font = UIFont.boldSystemFont(ofSize: 16)
        three.textAlignment = .center
        
        six = UILabel(frame: CGRect.init(x: 0, y: 0, width: 100, height: 45))
        six.text = "Go pro and donate for $7.99"
        six.backgroundColor = GMColor.lightBlue300Color()
        six.layer.cornerRadius = 22.5
        six.clipsToBounds = true
        six.textColor = .white
        six.numberOfLines = 0
        six.lineBreakMode = .byWordWrapping
        six.font = UIFont.boldSystemFont(ofSize: 16)
        six.textAlignment = .center
        
        self.shadowbox.textLabel?.text = "Shadowbox mode"
        self.shadowbox.detailTextLabel?.text = "View your favorite content in a full-screen distraction free shadowbox"
        self.shadowbox.detailTextLabel?.numberOfLines = 0
        self.shadowbox.backgroundColor = UIColor.foregroundColor
        self.shadowbox.textLabel?.textColor = UIColor.fontColor
        self.shadowbox.imageView?.image = UIImage(named: "shadowbox")?.toolbarIcon()
        self.shadowbox.imageView?.tintColor = UIColor.fontColor
        self.shadowbox.detailTextLabel?.textColor = UIColor.fontColor
        
        self.gallery.textLabel?.text = "Gallery mode"
        self.gallery.detailTextLabel?.text = "r/pics never looked better"
        self.gallery.detailTextLabel?.numberOfLines = 0
        self.gallery.backgroundColor = UIColor.foregroundColor
        self.gallery.textLabel?.textColor = UIColor.fontColor
        self.gallery.imageView?.image = UIImage(sfString: SFSymbol.photoFillOnRectangleFill, overrideString: "image")?.toolbarIcon()
        self.gallery.imageView?.tintColor = UIColor.fontColor
        self.gallery.detailTextLabel?.textColor = UIColor.fontColor
        
        self.biometric.textLabel?.text = "Biometric lock"
        self.biometric.detailTextLabel?.text = "Keep Slide safe from prying eyes"
        self.biometric.detailTextLabel?.numberOfLines = 0
        self.biometric.backgroundColor = UIColor.foregroundColor
        self.biometric.textLabel?.textColor = UIColor.fontColor
        self.biometric.imageView?.image = UIImage(sfString: SFSymbol.lockFill, overrideString: "lockapp")?.toolbarIcon()
        self.biometric.imageView?.tintColor = UIColor.fontColor
        self.biometric.detailTextLabel?.textColor = UIColor.fontColor
        
        self.multicolumn.textLabel?.text = "Custom column count"
        self.multicolumn.detailTextLabel?.text = "A must-have for iPads! This option allows you to customize Multi Column and Gallery modes with a configurable number of columns"
        self.multicolumn.detailTextLabel?.numberOfLines = 0
        self.multicolumn.backgroundColor = UIColor.foregroundColor
        self.multicolumn.textLabel?.textColor = UIColor.fontColor
        self.multicolumn.imageView?.image = UIImage(named: "multicolumn")?.toolbarIcon()
        self.multicolumn.imageView?.tintColor = UIColor.fontColor
        self.multicolumn.detailTextLabel?.textColor = UIColor.fontColor
        
        self.autocache.textLabel?.text = "Autocache subreddits"
        self.autocache.detailTextLabel?.text = "Cache your favorite subreddits and comments for offline viewing"
        self.autocache.detailTextLabel?.numberOfLines = 0
        self.autocache.backgroundColor = UIColor.foregroundColor
        self.autocache.textLabel?.textColor = UIColor.fontColor
        self.autocache.imageView?.image = UIImage.init(sfString: SFSymbol.squareAndArrowDownFill, overrideString: "download")?.toolbarIcon()
        self.autocache.imageView?.tintColor = UIColor.fontColor
        self.autocache.detailTextLabel?.textColor = UIColor.fontColor
        
        three.addTapGestureRecognizer { (_) in
            IAPHandler.shared.purchaseMyProduct(index: 0)
            self.alertController = UIAlertController(title: "Upgrading you to Pro!\n\n\n", message: nil, preferredStyle: .alert)

            let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.fontColor
            spinnerIndicator.startAnimating()
            
            self.alertController?.view.addSubview(spinnerIndicator)
            self.present(self.alertController!, animated: true, completion: nil)
        }
        
        six.addTapGestureRecognizer { (_) in
            IAPHandler.shared.purchaseMyProduct(index: 1)
            self.alertController = UIAlertController(title: "Upgrading you to Pro!\n\n\n", message: nil, preferredStyle: .alert)

            let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.black
            spinnerIndicator.startAnimating()
            
            self.alertController?.view.addSubview(spinnerIndicator)
            self.present(self.alertController!, animated: true, completion: nil)
        }

        aboutArea.addSubview(three)
        aboutArea.addSubview(six)
        aboutArea.addSubview(about)
        three.horizontalAnchors /==/ aboutArea.horizontalAnchors + 8
        six.horizontalAnchors /==/ aboutArea.horizontalAnchors + 8
        
        three.topAnchor /==/ aboutArea.topAnchor + 16
        six.topAnchor /==/ three.bottomAnchor + 12
        three.heightAnchor /==/ 45
        six.heightAnchor /==/ 45
        
        about.horizontalAnchors /==/ aboutArea.horizontalAnchors + 12
        about.topAnchor /==/ six.bottomAnchor + 12
        about.bottomAnchor /==/ aboutArea.bottomAnchor - 16
        
        let rect = about.textRect(forBounds: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width - 24, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines: 0)

        aboutArea.heightAnchor /==/ 45 + 45 + 16 + 12 + 18 + 12 + rect.size.height
        aboutArea.widthAnchor /==/ self.tableView.frame.width
        
        self.tableView.tableHeaderView = UIView(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.width, height: 0.01))
        
        let frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: 45 + 45 + 16 + 12 + 16 + 12 + rect.size.height)
        aboutArea.frame = frame
        aboutArea.layoutIfNeeded()
        let view = UIView(frame: aboutArea.frame)
        view.addSubview(aboutArea)
        self.tableView.tableHeaderView = view

        tableView.tableHeaderView?.isUserInteractionEnabled = true
    }
    
    var alertController: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 200
        self.tableView.rowHeight = UITableView.automaticDimension
        IAPHandler.shared.fetchAvailableProducts()
        IAPHandler.shared.getItemsBlock = {(items) in
            
            if items.isEmpty || items.count != 2 {
                DispatchQueue.main.async {
                    let alertView = UIAlertController(title: "Slide could not connect to Apple's servers", message: "Something went wrong connecting to Apple, please try again soon! Sorry for any inconvenience this may have caused", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Close", style: .cancel, handler: { (_) in
                    })
                    alertView.addAction(action)
                    self.present(alertView, animated: true, completion: nil)
                }

            } else {
                DispatchQueue.main.async {
                    let numberFormatter = NumberFormatter()
                    numberFormatter.formatterBehavior = .behavior10_4
                    numberFormatter.numberStyle = .currency
                    numberFormatter.locale = items[0].priceLocale
                    let price1Str = "Go pro for \(numberFormatter.string(from: items[0].price) ?? "$4.99")"
                    let price2Str = "Go pro and donate for \(numberFormatter.string(from: items[1].price) ?? "$7.99")"
                
                    self.three.text = price1Str
                    self.six.text = price2Str
                }
            }
        }
        IAPHandler.shared.purchaseStatusBlock = {[weak self] (type) in
            guard let strongSelf = self else { return }
            if type == .purchased {
                DispatchQueue.main.async {
                    strongSelf.alertController?.dismiss(animated: true, completion: nil)
                    let alertView = UIAlertController(title: "", message: type.message(), preferredStyle: .alert)
                    let action = UIAlertAction(title: "Close", style: .cancel, handler: { (_) in
                        self?.dismiss(animated: true, completion: nil)
                    })
                    alertView.addAction(action)
                    strongSelf.present(alertView, animated: true, completion: nil)
                    SettingValues.isPro = true
                    UserDefaults.standard.set(true, forKey: SettingValues.pref_pro)
                    UserDefaults.standard.synchronize()
                    (strongSelf.presentingViewController as? SettingsViewController)?.doPro()
                    SettingsPro.changed = true
                }
            } else if type == .restored {
                DispatchQueue.main.async {
                    strongSelf.alertController?.dismiss(animated: true, completion: nil)
                    let alertView = UIAlertController(title: "", message: type.message(), preferredStyle: .alert)
                    let action = UIAlertAction(title: "Close", style: .cancel, handler: { (_) in
                        self?.dismiss(animated: true, completion: nil)
                    })
                    alertView.addAction(action)
                    strongSelf.present(alertView, animated: true, completion: nil)
                    SettingValues.isPro = true
                    UserDefaults.standard.set(true, forKey: SettingValues.pref_pro)
                    UserDefaults.standard.synchronize()
                    (strongSelf.presentingViewController as? SettingsViewController)?.doPro()
                    SettingsPro.changed = true
                }
            }
        }
        
        IAPHandler.shared.errorBlock = {[weak self] (error) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {

                strongSelf.alertController?.dismiss(animated: true, completion: nil)
                if error != nil {
                    let alertView = UIAlertController(title: "Something went wrong!", message: "Slide Pro was not purchased and your account has not been charged.\nError: \(error!)\n\nPlease send me an email if this issue persists!", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Close", style: .cancel, handler: { (_) in
                    })
                    alertView.addAction(action)
                    alertView.addAction(UIAlertAction.init(title: "Email me", style: .default, handler: { (_) in
                        if MFMailComposeViewController.canSendMail() {
                            let mail = MFMailComposeViewController()
                            mail.mailComposeDelegate = strongSelf
                            mail.setToRecipients(["hapticappsdev@gmail.com"])
                            mail.setSubject("Slide Pro Purchase")
                            mail.setMessageBody("<p>Apple ID: \nError:" + (error ?? "" ) + "\n\n</p>", isHTML: true)
                            
                            strongSelf.present(mail, animated: true)
                        }
                    }))
                    strongSelf.present(alertView, animated: true, completion: nil)
                } else {
                    let alertView = UIAlertController(title: "Something went wrong!", message: "Slide Pro was not purchased and your account has not been charged! \n\nPlease send me an email if this issue persists!", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Close", style: .cancel, handler: { (_) in
                    })
                    alertView.addAction(action)
                    alertView.addAction(UIAlertAction.init(title: "Email me", style: .default, handler: { (_) in
                        if MFMailComposeViewController.canSendMail() {
                            let mail = MFMailComposeViewController()
                            mail.mailComposeDelegate = strongSelf
                            mail.setToRecipients(["hapticappsdev@gmail.com"])
                            mail.setSubject("Slide Pro Purchase")
                            mail.setMessageBody("<p>Apple ID: \nName:\n\n</p>", isHTML: true)
                            
                            strongSelf.present(mail, animated: true)
                        }
                    }))
                    strongSelf.present(alertView, animated: true, completion: nil)
                }
            }
        }
        
        IAPHandler.shared.restoreBlock = {[weak self] (restored) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.alertController?.dismiss(animated: true, completion: nil)
                if restored {
                    SettingValues.isPro = true
                    UserDefaults.standard.set(true, forKey: SettingValues.pref_pro)
                    UserDefaults.standard.synchronize()
                    SettingsPro.changed = true
                    let alertView = UIAlertController(title: "", message: "Slide has been successfully restored on your device! Thank you for supporting Slide 🍻", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Close", style: .cancel, handler: { (_) in
                        self?.dismiss(animated: true, completion: nil)
                    })
                    alertView.addAction(action)
                    strongSelf.present(alertView, animated: true, completion: nil)
                } else {
                    let alertView = UIAlertController(title: "Something went wrong!", message: "Slide Pro could not be restored! Make sure you purchased Slide on the same Apple ID as you purchased Slide Pro on. Please send me an email if this issue persists!", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Close", style: .cancel, handler: { (_) in
                    })
                    alertView.addAction(action)
                    alertView.addAction(UIAlertAction.init(title: "Email me", style: .default, handler: { (_) in
                        if MFMailComposeViewController.canSendMail() {
                            let mail = MFMailComposeViewController()
                            mail.mailComposeDelegate = strongSelf
                            mail.setToRecipients(["hapticappsdev@gmail.com"])
                            mail.setSubject("Slide Pro Restsore")
                            mail.setMessageBody("<p>Apple ID: \nName:\n\n</p>", isHTML: true)
                            
                            strongSelf.present(mail, animated: true)
                        }
                    }))
                    strongSelf.present(alertView, animated: true, completion: nil)
                }
            }
        }

    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 40
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.restore
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.multicolumn
            case 1: return self.shadowbox
            case 2: return self.backup
            case 3: return self.icons
            // case 3: return self.night
            case 4: return self.biometric
            case 5: return self.themes
            //            case 7: return self.gallery
            case 6: return self.autocache
            case 7: return self.username
                
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 && indexPath.section == 0 {
            IAPHandler.shared.restorePurchase()
        }
    }
   
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 16, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = UIColor.foregroundColor

        switch section {
        case 0: label.text = "Already a Slide supporter?"
        case 1: label.text = "Pro features"
        default: label.text = ""
        }
        return toReturn
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 8
        default: fatalError("Unknown number of sections")
        }
    }

}
