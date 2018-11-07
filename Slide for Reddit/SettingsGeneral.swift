//
//  SettingsGeneral.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit
import UserNotifications

class SettingsGeneral: UITableViewController {

    var hideFAB: UITableViewCell = UITableViewCell()
    var scrubUsername: UITableViewCell = UITableViewCell()
    var pinToolbar: UITableViewCell = UITableViewCell()
    var hapticFeedback: UITableViewCell = UITableViewCell()
    var autoKeyboard: UITableViewCell = UITableViewCell()
    var matchSilence: UITableViewCell = UITableViewCell()
    var showPages: UITableViewCell = UITableViewCell()

    var postSorting: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "post")
    var commentSorting: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "comment")
    var notifications: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "notif")
    var hideFABSwitch = UISwitch()
    var scrubUsernameSwitch = UISwitch()
    var pinToolbarSwitch = UISwitch()
    var hapticFeedbackSwitch = UISwitch()
    var autoKeyboardSwitch = UISwitch()
    var matchSilenceSwitch = UISwitch()
    var showPagesSwitch = UISwitch()
    var notificationsSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }

    func switchIsChanged(_ changed: UISwitch) {
        if changed == showPagesSwitch {
            MainViewController.needsRestart = true
            SettingValues.showPages = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_showPages)
        } else if changed == autoKeyboardSwitch {
            SettingValues.autoKeyboard = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_autoKeyboard)
        } else if changed == hapticFeedbackSwitch {
            SettingValues.hapticFeedback = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_hapticFeedback)
        } else if changed == hideFABSwitch {
            SettingValues.hiddenFAB = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_hiddenFAB)
            SubredditReorderViewController.changed = true
        } else if changed == hapticFeedback {
            SettingValues.hapticFeedback = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_hapticFeedback)
        } else if changed == notificationsSwitch {
            SettingValues.notifications = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_notifications)
            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        DispatchQueue.main.async {
                            self.notificationsSwitch.isOn = granted
                            SettingValues.notifications = granted
                            UserDefaults.standard.set(granted, forKey: SettingValues.pref_notifications)
                            
                            if SettingValues.notifications {
                                UIApplication.shared.setMinimumBackgroundFetchInterval(60 * 10) // 10 minute interval
                                print("Application background refresh minimum interval: \(60 * 10) seconds")
                                print("Application background refresh status: \(UIApplication.shared.backgroundRefreshStatus.rawValue)")
                            } else {
                                UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
                                print("Application background refresh minimum set to never")
                            }
                        }
                    }
                }
            }
        } else if changed == pinToolbarSwitch {
            SettingValues.pinToolbar = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_pinToolbar)
            SubredditReorderViewController.changed = true
        } else if changed == matchSilenceSwitch {
            SettingValues.matchSilence = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_matchSilence)
        } else if changed == scrubUsernameSwitch {
            if !VCPresenter.proDialogShown(feature: false, self) {
                SettingValues.nameScrubbing = changed.isOn
                UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_nameScrubbing)
            } else {
                changed.isOn = false
            }
        }
        UserDefaults.standard.synchronize()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor

        switch section {
        case 0: label.text = "Display"
        case 1: label.text = "Interaction"
        case 2: label.text = "Notifications"
        case 3: label.text = "Sorting"
        default: label.text = ""
        }
        return toReturn
    }
    
    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = ColorUtil.fontColor
        cell.backgroundColor = ColorUtil.foregroundColor
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if let s = switchV {
            s.isOn = isOn
            s.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
            cell.accessoryView = s
        }
        cell.selectionStyle = UITableViewCellSelectionStyle.none
    }

    override func loadView() {
        super.loadView()

        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "General"
        self.tableView.separatorStyle = .none
        
        createCell(hapticFeedback, hapticFeedbackSwitch, isOn: SettingValues.hapticFeedback, text: "Haptic feedback throughout app")
        createCell(hideFAB, hideFABSwitch, isOn: !SettingValues.hiddenFAB, text: "Show subreddit floating action button")
        createCell(scrubUsername, scrubUsernameSwitch, isOn: SettingValues.nameScrubbing, text: "Scrub your username (you will show as \"you\")")
        createCell(pinToolbar, pinToolbarSwitch, isOn: !SettingValues.pinToolbar, text: "Autohide navigation bars")
        createCell(matchSilence, matchSilenceSwitch, isOn: SettingValues.matchSilence, text: "Mute videos if silent mode is on (will also pause background audio)")
        createCell(autoKeyboard, autoKeyboardSwitch, isOn: SettingValues.autoKeyboard, text: "Open keyboard automatically in bottom drawer")
        createCell(showPages, showPagesSwitch, isOn: SettingValues.showPages, text: "Show page separators when loading more content")

        self.postSorting.textLabel?.text = "Default post sorting"
        self.postSorting.detailTextLabel?.text = SettingValues.defaultSorting.description
        self.postSorting.detailTextLabel?.textColor = ColorUtil.fontColor
        self.postSorting.backgroundColor = ColorUtil.foregroundColor
        self.postSorting.textLabel?.textColor = ColorUtil.fontColor

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
                DispatchQueue.main.async {
                    self.createCell(self.notifications, self.notificationsSwitch, isOn: SettingValues.notifications && settings.authorizationStatus == .authorized, text: "New message notifications")
                }
            })
        } else {
            self.notifications.textLabel?.text = "New message notifications"
            self.notifications.detailTextLabel?.text = "Requires iOS 10 or newer"
            self.notifications.detailTextLabel?.textColor = ColorUtil.fontColor
            self.notifications.backgroundColor = ColorUtil.foregroundColor
            self.notifications.textLabel?.textColor = ColorUtil.fontColor
        }
        self.notifications.textLabel?.text = "New message notifications"
        self.notifications.detailTextLabel?.text = "Check for new mail every 15 minutes"
        self.notifications.detailTextLabel?.textColor = ColorUtil.fontColor
        self.notifications.backgroundColor = ColorUtil.foregroundColor
        self.notifications.textLabel?.textColor = ColorUtil.fontColor

        self.commentSorting.textLabel?.text = "Default comment sorting"
        self.commentSorting.detailTextLabel?.text = SettingValues.defaultCommentSorting.description
        self.commentSorting.backgroundColor = ColorUtil.foregroundColor
        self.commentSorting.detailTextLabel?.textColor = ColorUtil.fontColor
        self.commentSorting.textLabel?.textColor = ColorUtil.fontColor

        self.tableView.tableFooterView = UIView()
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
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.hideFAB
            case 1: return self.showPages
            case 2: return self.autoKeyboard
            case 3: return self.pinToolbar
            case 4: return self.scrubUsername
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.hapticFeedback
            case 1: return self.matchSilence
            default: fatalError("Unknown row in section 0")
            }
        case 2:
            switch indexPath.row {
            case 0: return self.notifications
            default: fatalError("Unknown row in section 1")
            }
        case 3:
            switch indexPath.row {
            case 0: return self.postSorting
            case 1: return self.commentSorting
            default: fatalError("Unknown row in section 2")
            }
        default: fatalError("Unknown section")
        }

    }

    func showMenuComments(_ selector: UIView?) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Comment sorting", message: "", preferredStyle: .actionSheet)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        let selected = UIImage(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

        for link in CommentSort.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default) { _ -> Void in
                SettingValues.defaultCommentSorting = link
                UserDefaults.standard.set(link.path, forKey: SettingValues.pref_defaultCommentSorting)
                UserDefaults.standard.synchronize()
                self.commentSorting.detailTextLabel?.text = SettingValues.defaultCommentSorting.description
            }
            if SettingValues.defaultCommentSorting == link {
                saveActionButton.setValue(selected, forKey: "image")
            }
            actionSheetController.addAction(saveActionButton)
        }

        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = selector!
            presenter.sourceRect = selector!.bounds
        }

        self.present(actionSheetController, animated: true, completion: nil)

    }

    func showMenu(_ selector: UIView?) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

        for link in LinkSortType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default) { _ -> Void in
                self.showTimeMenu(s: link, selector: selector)
            }
            if SettingValues.defaultSorting == link {
                saveActionButton.setValue(selected, forKey: "image")
            }
            actionSheetController.addAction(saveActionButton)
        }

        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = selector!
            presenter.sourceRect = selector!.bounds
        }

        self.present(actionSheetController, animated: true, completion: nil)

    }

    func showTimeMenu(s: LinkSortType, selector: UIView?) {
        if s == .hot || s == .new || s == .rising || s == .best {
            SettingValues.defaultSorting = s
            UserDefaults.standard.set(s.path, forKey: SettingValues.pref_defaultSorting)
            UserDefaults.standard.synchronize()
            self.postSorting.detailTextLabel?.text = SettingValues.defaultSorting.description
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { _ -> Void in
            }
            actionSheetController.addAction(cancelActionButton)

            let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default) { _ -> Void in
                    print("Sort is \(s) and time is \(t)")
                    SettingValues.defaultSorting = s
                    UserDefaults.standard.set(s.path, forKey: SettingValues.pref_defaultSorting)
                    SettingValues.defaultTimePeriod = t
                    UserDefaults.standard.set(t.param, forKey: SettingValues.pref_defaultTimePeriod)
                    UserDefaults.standard.synchronize()
                    self.postSorting.detailTextLabel?.text = SettingValues.defaultSorting.description
                }
                if SettingValues.defaultTimePeriod == t {
                    saveActionButton.setValue(selected, forKey: "image")
                }

                actionSheetController.addAction(saveActionButton)
            }

            if let presenter = actionSheetController.popoverPresentationController {
                presenter.sourceView = selector!
                presenter.sourceRect = selector!.bounds
            }

            self.present(actionSheetController, animated: true, completion: nil)
        }
    }

    var timeMenuView: UIView = UIView()

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.timeMenuView = self.tableView.cellForRow(at: indexPath)!.contentView

        if indexPath.section == 3 && indexPath.row == 0 {
            showMenu(tableView.cellForRow(at: indexPath))
        } else if indexPath.section == 3 && indexPath.row == 1 {
            showMenuComments(tableView.cellForRow(at: indexPath))
        }

    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 5
        case 1: return 2
        case 2: return 1
        case 3: return 2
        default: fatalError("Unknown number of sections")
        }
    }

}
