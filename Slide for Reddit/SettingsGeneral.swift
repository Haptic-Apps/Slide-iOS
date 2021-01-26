//
//  SettingsGeneral.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import RLBAlertsPickers
import SDCAlertView
import UIKit
import UserNotifications

class SettingsGeneral: BubbleSettingTableViewController {

    var hideFAB: InsetCell = InsetCell(style: .subtitle, reuseIdentifier: "hidefab")
    var scrubUsername: InsetCell = InsetCell.init(style: .subtitle, reuseIdentifier: "scrub")
    var pinToolbar: InsetCell = InsetCell()
    var hapticFeedback: InsetCell = InsetCell()
    var autoKeyboard: InsetCell = InsetCell()
    var matchSilence: InsetCell = InsetCell.init(style: .subtitle, reuseIdentifier: "mute")
    var showPages: InsetCell = InsetCell()
    var totallyCollapse: InsetCell = InsetCell()
    var buttonType: InsetCell = InsetCell(style: .subtitle, reuseIdentifier: "button")
    var fullyHideNavbar: InsetCell = InsetCell()
    var alwaysShowHeader: InsetCell = InsetCell.init(style: .subtitle, reuseIdentifier: "head")
    var commentLimit: InsetCell = InsetCell.init(style: .subtitle, reuseIdentifier: "cl")
    var postLimit: InsetCell = InsetCell.init(style: .subtitle, reuseIdentifier: "pl")
    var scrollSidebar: InsetCell = InsetCell.init(style: .subtitle, reuseIdentifier: "scroll")

    var postSorting: InsetCell = InsetCell.init(style: .subtitle, reuseIdentifier: "post")
    var commentSorting: InsetCell = InsetCell.init(style: .subtitle, reuseIdentifier: "comment")
    var searchSorting: InsetCell = InsetCell.init(style: .subtitle, reuseIdentifier: "search")
    var notifications: InsetCell = InsetCell.init(style: .subtitle, reuseIdentifier: "notif")
    var hideFABSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var totallyCollapseSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var fullyHideNavbarSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var scrubUsernameSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var pinToolbarSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var hapticFeedbackSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var autoKeyboardSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var matchSilenceSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var showPagesSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var alwaysShowHeaderSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var notificationsSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var scrollSidebarSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.set(true, forKey: "2notifs")
        UserDefaults.standard.synchronize()
    }

    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == showPagesSwitch {
            MainViewController.needsRestart = true
            SettingValues.showPages = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_showPages)
        } else if changed == autoKeyboardSwitch {
            SettingValues.autoKeyboard = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_autoKeyboard)
        } else if changed == totallyCollapseSwitch {
            SettingValues.hideBottomBar = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_totallyCollapse)
        } else if changed == fullyHideNavbarSwitch {
            SettingValues.hideStatusBar = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_fullyHideNavbar)
        } else if changed == alwaysShowHeaderSwitch {
            SettingValues.alwaysShowHeader = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_alwaysShowHeader)
        } else if changed == hapticFeedbackSwitch {
            SettingValues.hapticFeedback = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_hapticFeedback)
        } else if changed == hideFABSwitch {
            SettingValues.hiddenFAB = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_hiddenFAB)
            SubredditReorderViewController.changed = true
            doDisables()
        } else if changed == hapticFeedback {
            SettingValues.hapticFeedback = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_hapticFeedback)
        } else if changed == scrollSidebarSwitch {
            SettingValues.scrollSidebar = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_scrollSidebar)
        } else if changed == notificationsSwitch {
            SettingValues.notifications = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_notifications)
            if changed.isOn, #available(iOS 10.0, *) {
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
                                UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
                                print("Application background refresh minimum set to never")
                            }
                        }
                    }
                }
            }
        } else if changed == pinToolbarSwitch {
            SettingValues.dontHideTopBar = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_pinToolbar)
            SubredditReorderViewController.changed = true
            if SettingValues.dontHideTopBar {
                self.totallyCollapse.contentView.alpha = 0.5
                self.totallyCollapse.isUserInteractionEnabled = false
                self.fullyHideNavbar.contentView.alpha = 0.5
                self.fullyHideNavbar.isUserInteractionEnabled = false
            } else {
                self.totallyCollapse.contentView.alpha = 1
                self.totallyCollapse.isUserInteractionEnabled = true
                self.fullyHideNavbar.contentView.alpha = 1
                self.fullyHideNavbar.isUserInteractionEnabled = true
            }
        } else if changed == matchSilenceSwitch {
            // SettingValues.matchSilence = changed.isOn
           // UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_matchSilence)
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
    
    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = UIColor.fontColor
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.detailTextLabel?.numberOfLines = 0
        if let s = switchV {
            s.isOn = isOn
            s.addTarget(self, action: #selector(SettingsGeneral.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
            cell.accessoryView = s
        }
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
    }
    
    override func loadView() {
        super.loadView()
        headers = ["Subreddits", "Auto-Hide", "Interaction", "Notifications", "Sorting", "Loading limits"]

        // set the title
        self.title = "General"
        
        createCell(hapticFeedback, hapticFeedbackSwitch, isOn: SettingValues.hapticFeedback, text: "Haptic feedback throughout app")
        createCell(hideFAB, hideFABSwitch, isOn: !SettingValues.hiddenFAB, text: "Subreddit quick action button")
        createCell(buttonType, nil, isOn: false, text: "Action")
        buttonType.accessoryView = UIImageView(image: SettingValues.fabType.getPhoto()?.navIcon())
        
        createCell(scrubUsername, scrubUsernameSwitch, isOn: SettingValues.nameScrubbing, text: "Username Scrubbing")
        createCell(pinToolbar, pinToolbarSwitch, isOn: !SettingValues.dontHideTopBar, text: "Hide top bars on scroll")
       // createCell(matchSilence, matchSilenceSwitch, isOn: SettingValues.matchSilence, text: "Let iOS handle audio focus")
        createCell(autoKeyboard, autoKeyboardSwitch, isOn: SettingValues.autoKeyboard, text: "Open keyboard with bottom drawer")
        createCell(showPages, showPagesSwitch, isOn: SettingValues.showPages, text: "Show page separators when loading more submissions")
        createCell(totallyCollapse, totallyCollapseSwitch, isOn: SettingValues.hideBottomBar, text: "Hide bottom bars on scroll")
        createCell(fullyHideNavbar, fullyHideNavbarSwitch, isOn: SettingValues.hideStatusBar, text: "Hide status bar on scroll")
        createCell(alwaysShowHeader, alwaysShowHeaderSwitch, isOn: SettingValues.alwaysShowHeader, text: "Show subreddit header")
        createCell(scrollSidebar, scrollSidebarSwitch, isOn: SettingValues.scrollSidebar, text: "Reset sidebar automatically")

        self.alwaysShowHeader.detailTextLabel?.text = "When off, scrolling up past the first post will display the header"
        self.alwaysShowHeader.detailTextLabel?.textColor = UIColor.fontColor
        self.alwaysShowHeader.detailTextLabel?.numberOfLines = 0
        
        self.hideFAB.detailTextLabel?.text = "Pro tip: long on the button to quickly change the action"
        self.hideFAB.detailTextLabel?.textColor = UIColor.fontColor
        self.hideFAB.backgroundColor = UIColor.foregroundColor
        self.hideFAB.textLabel?.textColor = UIColor.fontColor
        self.hideFAB.detailTextLabel?.numberOfLines = 0

        self.scrubUsername.detailTextLabel?.text = "Hide your username everywhere"
        self.scrubUsername.detailTextLabel?.textColor = UIColor.fontColor
        self.scrubUsername.backgroundColor = UIColor.foregroundColor
        self.scrubUsername.textLabel?.textColor = UIColor.fontColor

        self.buttonType.detailTextLabel?.text = SettingValues.fabType.getTitle()
        self.buttonType.detailTextLabel?.textColor = UIColor.fontColor
        self.buttonType.backgroundColor = UIColor.foregroundColor
        self.buttonType.textLabel?.textColor = UIColor.fontColor

        self.postSorting.textLabel?.text = "Default subreddit sorting"
        self.postSorting.detailTextLabel?.text = SettingValues.defaultSorting.description
        self.postSorting.detailTextLabel?.textColor = UIColor.fontColor
        self.postSorting.backgroundColor = UIColor.foregroundColor
        self.postSorting.textLabel?.textColor = UIColor.fontColor

        self.searchSorting.textLabel?.text = "Default search sorting"
        self.searchSorting.detailTextLabel?.text = "Sort by \(SettingValues.defaultSearchSorting.path.capitalize())"
        self.searchSorting.detailTextLabel?.textColor = UIColor.fontColor
        self.searchSorting.backgroundColor = UIColor.foregroundColor
        self.searchSorting.textLabel?.textColor = UIColor.fontColor
       
        self.scrollSidebar.textLabel?.text = "Reset Sidebar automatically"
        self.scrollSidebar.detailTextLabel?.text = "Reset search and scroll to the top of the subreddit menu automatically"
        self.scrollSidebar.detailTextLabel?.textColor = UIColor.fontColor
        self.scrollSidebar.backgroundColor = UIColor.foregroundColor
        self.scrollSidebar.textLabel?.textColor = UIColor.fontColor

        self.commentLimit.textLabel?.text = "Number of comments to load"
        self.commentLimit.detailTextLabel?.text = "\(SettingValues.commentLimit) comments"
        self.commentLimit.detailTextLabel?.textColor = UIColor.fontColor
        self.commentLimit.backgroundColor = UIColor.foregroundColor
        self.commentLimit.textLabel?.textColor = UIColor.fontColor
        self.commentLimit.contentView.addTapGestureRecognizer { (_) in
            self.showCountMenu(false)
        }

        self.postLimit.textLabel?.text = "Number of posts to load"
        self.postLimit.detailTextLabel?.text = "\(SettingValues.submissionLimit) posts"
        self.postLimit.detailTextLabel?.textColor = UIColor.fontColor
        self.postLimit.backgroundColor = UIColor.foregroundColor
        self.postLimit.textLabel?.textColor = UIColor.fontColor
        self.postLimit.contentView.addTapGestureRecognizer { (_) in
            self.showCountMenu(true)
        }

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
                DispatchQueue.main.async {
                    self.createCell(self.notifications, self.notificationsSwitch, isOn: SettingValues.notifications && settings.authorizationStatus == .authorized, text: "New message notifications")
                }
            })
        } else {
            self.notifications.textLabel?.text = "New message notifications"
            self.notifications.detailTextLabel?.text = "Requires iOS 10 or newer"
            self.notifications.detailTextLabel?.textColor = UIColor.fontColor
            self.notifications.backgroundColor = UIColor.foregroundColor
            self.notifications.textLabel?.textColor = UIColor.fontColor
        }
        
        if SettingValues.dontHideTopBar {
            self.totallyCollapse.contentView.alpha = 0.5
            self.totallyCollapse.isUserInteractionEnabled = false
            self.fullyHideNavbar.contentView.alpha = 0.5
            self.fullyHideNavbar.isUserInteractionEnabled = false
        } else {
            self.totallyCollapse.contentView.alpha = 1
            self.totallyCollapse.isUserInteractionEnabled = true
            self.fullyHideNavbar.contentView.alpha = 1
            self.fullyHideNavbar.isUserInteractionEnabled = true
        }
        
        self.notifications.textLabel?.text = "New message notifications"
        self.notifications.detailTextLabel?.text = "Check for new mail when iOS allows Slide to wake from background"
        self.notifications.detailTextLabel?.textColor = UIColor.fontColor
        self.notifications.backgroundColor = UIColor.foregroundColor
        self.notifications.textLabel?.textColor = UIColor.fontColor

        self.matchSilence.detailTextLabel?.text = "Follows mute switch and silent mode"
        self.matchSilence.detailTextLabel?.textColor = UIColor.fontColor
        self.matchSilence.backgroundColor = UIColor.foregroundColor
        self.matchSilence.textLabel?.textColor = UIColor.fontColor

        self.commentSorting.textLabel?.text = "Default comment sorting"
        self.commentSorting.detailTextLabel?.text = SettingValues.defaultCommentSorting.description
        self.commentSorting.backgroundColor = UIColor.foregroundColor
        self.commentSorting.detailTextLabel?.textColor = UIColor.fontColor
        self.commentSorting.textLabel?.textColor = UIColor.fontColor

        self.tableView.tableFooterView = UIView()
        
        doDisables()
    }

    func showCountMenu(_ submissions: Bool) {
        var min = 5
        var max = 100
        var step = 1
        if !submissions {
            min = 20
            max = 2000
            step = 20
        }
        
        let alert = AlertController(title: "Select \(submissions ? "submission" : "comment") depth limit", message: nil, preferredStyle: .alert)

        let cancelActionButton = AlertAction(title: "Close", style: .preferred) { _ -> Void in
        }
        alert.addAction(cancelActionButton)

        var values: [[String]] = [[]]
        for i in stride(from: min, to: max, by: step) {
            values[0].append("\(i)")
        }

        var initialSelection: [PickerViewViewController.Index] = []
        initialSelection.append((0, (submissions ? SettingValues.submissionLimit - min : SettingValues.commentLimit - min) / step))
        alert.setupTheme()
        
        alert.attributedTitle = NSAttributedString(string: "Select \(submissions ? "submission" : "comment") limit", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
        
        let pickerView = PickerViewViewControllerColored(values: values, initialSelection: initialSelection, action: { _, _, index, _ in
            switch index.column {
            case 0:
                if submissions {
                    SettingValues.submissionLimit = (index.row * step) + min
                    UserDefaults.standard.set(SettingValues.submissionLimit, forKey: SettingValues.pref_submissionLimit)
                    UserDefaults.standard.synchronize()
                } else {
                    SettingValues.commentLimit = (index.row * step) + min
                    UserDefaults.standard.set(SettingValues.submissionLimit, forKey: SettingValues.pref_submissionLimit)
                }
                self.commentLimit.detailTextLabel?.text = "\(SettingValues.commentLimit) comments"

                self.postLimit.detailTextLabel?.text = "\(SettingValues.submissionLimit) posts"
            default: break
            }
        })
        
        alert.addChild(pickerView)

        let pv = pickerView.view!
        alert.contentView.addSubview(pv)
        
        pv.edgeAnchors /==/ alert.contentView.edgeAnchors - 14
        pv.heightAnchor /==/ CGFloat(216)
        pickerView.didMove(toParent: alert)
        
        alert.addBlurView()
        
        self.present(alert, animated: true, completion: nil)

    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func doDisables() {
        if SettingValues.hiddenFAB {
            buttonType.textLabel?.isEnabled = false
            buttonType.detailTextLabel?.isEnabled = false
            buttonType.isUserInteractionEnabled = false
            (buttonType.accessoryView as? UIImageView)?.alpha = 0.5
            buttonType.accessoryView = UIImageView(image: UIImage(sfString: .xmark, overrideString: "close")?.menuIcon())
            self.buttonType.detailTextLabel?.text = "Disabled"
        } else {
            buttonType.textLabel?.isEnabled = true
            buttonType.detailTextLabel?.isEnabled = true
            buttonType.isUserInteractionEnabled = true
            (buttonType.accessoryView as? UIImageView)?.alpha = 1
            buttonType.accessoryView = UIImageView(image: SettingValues.fabType.getPhoto()?.navIcon())
            self.buttonType.detailTextLabel?.text = SettingValues.fabType.getTitle()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: InsetCell
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: cell = self.hideFAB
            case 1: cell = self.buttonType
            case 2: cell = self.showPages
            case 3: cell = self.scrubUsername
            case 4: cell = self.alwaysShowHeader
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: cell = self.pinToolbar
            case 1: cell = self.totallyCollapse
            case 2: cell = self.fullyHideNavbar
            default: fatalError("Unknown row in section 0")
            }
        case 2:
            switch indexPath.row {
            case 0: cell = self.hapticFeedback
            case 1: cell = self.scrollSidebar
            // case 1: return self.matchSilence
            default: fatalError("Unknown row in section 0")
            }
        case 3:
            switch indexPath.row {
            case 0: cell = self.notifications
            default: fatalError("Unknown row in section 1")
            }
        case 4:
            switch indexPath.row {
            case 0: cell = self.postSorting
            case 1: cell = self.commentSorting
            case 2: cell = self.searchSorting
            default: fatalError("Unknown row in section 2")
            }
        case 5:
            switch indexPath.row {
            case 0: cell = self.postLimit
            case 1: cell = self.commentLimit
            default: fatalError("Unknown row in section 2")
            }
        default: fatalError("Unknown section")
        }
        
        return cell
    }
    
    func showMenuComments(_ selector: UIView?) {
        let actionSheetController = DragDownAlertMenu(title: "Default comment sorting", subtitle: "Will be applied to threads", icon: nil, themeColor: nil, full: true)

        let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon()
        
        for link in CommentSort.cases {
            actionSheetController.addAction(title: link.description, icon: SettingValues.defaultCommentSorting == link ? selected : nil) {
                SettingValues.defaultCommentSorting = link
                UserDefaults.standard.set(link.path, forKey: SettingValues.pref_defaultCommentSorting)
                UserDefaults.standard.synchronize()
                self.commentSorting.detailTextLabel?.text = SettingValues.defaultCommentSorting.description
            }
        }
        
        actionSheetController.show(self)
    }

    func showMenuSearch(_ selector: UIView?) {
        let actionSheetController = DragDownAlertMenu(title: "Default search sorting", subtitle: "Will be applied to all searches", icon: nil, themeColor: nil, full: true)
        
        let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon()
        
        for link in SearchSortBy.cases {
            actionSheetController.addAction(title: "Sort by \(link.path.capitalize())", icon: SettingValues.defaultSearchSorting == link ? selected : nil) {
                SettingValues.defaultSearchSorting = link
                UserDefaults.standard.set(link.path, forKey: SettingValues.pref_defaultSearchSort)
                UserDefaults.standard.synchronize()
                self.searchSorting.detailTextLabel?.text = "Sort by \(SettingValues.defaultSearchSorting.path.capitalize())"
            }
        }
        
        actionSheetController.show(self)
    }

    func showMenu(_ selector: UIView?) {
        let actionSheetController = DragDownAlertMenu(title: "Default subreddit sorting", subtitle: "Will be applied to all subreddits", icon: nil, themeColor: nil, full: true)

        let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon()

        for link in LinkSortType.cases {
            actionSheetController.addAction(title: link.description, icon: SettingValues.defaultSorting == link ? selected : nil) {
                self.showTimeMenu(s: link, selector: selector)
            }
        }

        actionSheetController.show(self)
    }
    
    func changeFab() {
        let actionSheetController = DragDownAlertMenu(title: "Change action", subtitle: "", icon: nil, themeColor: ColorUtil.baseAccent, full: true)

        for t in SettingValues.FabType.cases {
            actionSheetController.addAction(title: t.getTitle(), icon: t.getPhoto()?.menuIcon(), action: {
                UserDefaults.standard.set(t.rawValue, forKey: SettingValues.pref_fabType)
                SettingValues.fabType = t
                self.doDisables()
            })
        }

        actionSheetController.show(self)
    }

    func showTimeMenu(s: LinkSortType, selector: UIView?) {
        if s == .hot || s == .new || s == .rising || s == .best {
            SettingValues.defaultSorting = s
            UserDefaults.standard.set(s.path, forKey: SettingValues.pref_defaultSorting)
            UserDefaults.standard.synchronize()
            self.postSorting.detailTextLabel?.text = SettingValues.defaultSorting.description
            return
        } else {
            let actionSheetController = DragDownAlertMenu(title: "Select a time period", subtitle: "", icon: nil, themeColor: nil, full: true)

            let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon()

            for t in TimeFilterWithin.cases {
                actionSheetController.addAction(title: t.param, icon: SettingValues.defaultTimePeriod == t ? selected : nil) {
                    SettingValues.defaultSorting = s
                    UserDefaults.standard.set(s.path, forKey: SettingValues.pref_defaultSorting)
                    SettingValues.defaultTimePeriod = t
                    UserDefaults.standard.set(t.param, forKey: SettingValues.pref_defaultTimePeriod)
                    UserDefaults.standard.synchronize()
                    self.postSorting.detailTextLabel?.text = SettingValues.defaultSorting.description
                }
            }
            
            actionSheetController.show(self)
        }
    }

    var timeMenuView: UIView = UIView()

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.timeMenuView = self.tableView.cellForRow(at: indexPath)!.contentView
        if indexPath.section == 0 && indexPath.row == 1 {
            changeFab()
        } else if indexPath.section == 4 && indexPath.row == 0 {
            showMenu(tableView.cellForRow(at: indexPath))
        } else if indexPath.section == 4 && indexPath.row == 1 {
            showMenuComments(tableView.cellForRow(at: indexPath))
        } else if indexPath.section == 4 && indexPath.row == 2 {
            showMenuSearch(tableView.cellForRow(at: indexPath))
        }

    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let pad = UIDevice.current.userInterfaceIdiom == .pad
        switch section {
        case 0: return 4 + (!pad ? 1 : 0)
        case 1: return 3
        case 2: return 2
        case 3: return 1
        case 4: return 3
        case 5: return 2
        default: fatalError("Unknown number of sections")
        }
    }

}

public class InsetCell: UITableViewCell {
    override public var frame: CGRect {
        get {
            return super.frame
        }
        set (newFrame) {
            var frame = newFrame
            frame.origin.x += 10
            frame.size.width -= 2 * 10
            super.frame = frame
        }
    }
    var top = false
    var bottom = false

    /// Minimum height of the cell. Only effective when the table view's
    /// row height is set to `UITableView.automaticDimension`.
    var minHeight: CGFloat? = 60
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = UIColor.foregroundColor

        if !top && !bottom {
            let shape = CAShapeLayer()
            let rect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.size.height)
            let corners: UIRectCorner = []
            
            shape.path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: 10, height: 10)).cgPath
            layer.mask = shape
            layer.masksToBounds = true
            return
        }
        
        if top && bottom {
            let shape = CAShapeLayer()
            let rect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.size.height)
            let corners: UIRectCorner = [.topLeft, .topRight, .bottomRight, .bottomLeft]
            
            shape.path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: 10, height: 10)).cgPath
            layer.mask = shape
            layer.masksToBounds = true
            return
        }
        
        let shape = CAShapeLayer()
        let rect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.size.height)
        let corners: UIRectCorner = self.top ? [.topLeft, .topRight] : [.bottomRight, .bottomLeft]
        
        shape.path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: 10, height: 10)).cgPath
        layer.mask = shape
        layer.masksToBounds = true
    }
}

extension InsetCell { // Support minHeight variable. See https://stackoverflow.com/a/48853081/7138792
    public override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        let size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
        guard let minHeight = minHeight else { return size }
        return CGSize(width: size.width, height: max(size.height, minHeight))
    }

    public override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        let size = super.systemLayoutSizeFitting(targetSize)
        guard let minHeight = minHeight else { return size }
        return CGSize(width: size.width, height: max(size.height, minHeight))
    }
}

class BubbleSettingTableViewController: UITableViewController {
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

    override func loadView() {
        super.loadView()
        self.tableView.backgroundColor = UIColor.backgroundColor
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel()
        label.textColor = ColorUtil.baseAccent
        label.font = FontGenerator.boldFontOfSize(size: 14, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 24, bottom: 0, right: 0))
        toReturn.backgroundColor = UIColor.backgroundColor
        
        if headers.isEmpty {
            return UIView()
        }
        label.text = headers[section]
        return toReturn
    }

    var headers = [String]()
    
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
        tableView.separatorColor = UIColor.foregroundColorOverlaidWithFont(0.15)
    }
}
