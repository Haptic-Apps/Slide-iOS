//
//  SettingsGeneral.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class SettingsGeneral: UITableViewController {

    var viewType: UITableViewCell = UITableViewCell()
    var hideFAB: UITableViewCell = UITableViewCell()
    var scrubUsername: UITableViewCell = UITableViewCell()
    var pinToolbar: UITableViewCell = UITableViewCell()

    var postSorting: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "post")
    var commentSorting: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "comment")
    var notifications: UITableViewCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "notif")
    var viewTypeSwitch = UISwitch()
    var hideFABSwitch = UISwitch()
    var scrubUsernameSwitch = UISwitch()
    var pinToolbarSwitch = UISwitch()

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
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
        navigationController?.navigationBar.tintColor = UIColor.white
    }

    func switchIsChanged(_ changed: UISwitch) {
        if (changed == viewTypeSwitch) {
            SubredditReorderViewController.changed = true
            SettingValues.viewType = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_viewType)
        } else if (changed == hideFABSwitch) {
            SettingValues.hiddenFAB = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_hiddenFAB)
            SubredditReorderViewController.changed = true
        } else if (changed == pinToolbarSwitch) {
            SettingValues.pinToolbar = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_pinToolbar)
            SubredditReorderViewController.changed = true
        } else if (changed == scrubUsernameSwitch) {
            if(!VCPresenter.proDialogShown(feature: false, self)){
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

        switch (section) {
        case 0: label.text = "Display"
            break
        case 1: label.text = "Notifications"
            break
        case 2: label.text = "Sorting"
            break

        default: label.text = ""
            break
        }
        return toReturn
    }

    override func loadView() {
        super.loadView()

        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "General"
        self.tableView.separatorStyle = .none

        viewTypeSwitch = UISwitch()
        viewTypeSwitch.isOn = SettingValues.viewType
        viewTypeSwitch.addTarget(self, action: #selector(SettingsGeneral.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.viewType.textLabel?.text = "Subreddit tabs mode"
        self.viewType.accessoryView = viewTypeSwitch
        self.viewType.backgroundColor = ColorUtil.foregroundColor
        self.viewType.textLabel?.textColor = ColorUtil.fontColor
        viewType.selectionStyle = UITableViewCellSelectionStyle.none

        hideFABSwitch = UISwitch()
        hideFABSwitch.isOn = !SettingValues.hiddenFAB
        hideFABSwitch.addTarget(self, action: #selector(SettingsGeneral.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.hideFAB.textLabel?.text = "Subreddit floating button"
        self.hideFAB.accessoryView = hideFABSwitch
        self.hideFAB.backgroundColor = ColorUtil.foregroundColor
        self.hideFAB.textLabel?.textColor = ColorUtil.fontColor
        hideFAB.selectionStyle = UITableViewCellSelectionStyle.none

        scrubUsernameSwitch = UISwitch()
        scrubUsernameSwitch.isOn = SettingValues.nameScrubbing
        scrubUsernameSwitch.addTarget(self, action: #selector(SettingsGeneral.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.scrubUsername.textLabel?.text = "Scrub your username (you will become \"you\")"
        self.scrubUsername.accessoryView = scrubUsernameSwitch
        self.scrubUsername.backgroundColor = ColorUtil.foregroundColor
        self.scrubUsername.textLabel?.textColor = ColorUtil.fontColor
        scrubUsername.selectionStyle = UITableViewCellSelectionStyle.none

        pinToolbarSwitch = UISwitch()
        pinToolbarSwitch.isOn = SettingValues.pinToolbar
        pinToolbarSwitch.addTarget(self, action: #selector(SettingsGeneral.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.pinToolbar.textLabel?.text = "Don't autohide toolbars"
        self.pinToolbar.accessoryView = pinToolbarSwitch
        self.pinToolbar.backgroundColor = ColorUtil.foregroundColor
        self.pinToolbar.textLabel?.textColor = ColorUtil.fontColor
        pinToolbar.selectionStyle = UITableViewCellSelectionStyle.none

        self.postSorting.textLabel?.text = "Default post sorting"
        self.postSorting.detailTextLabel?.text = SettingValues.defaultSorting.description
        self.postSorting.detailTextLabel?.textColor = ColorUtil.fontColor
        self.postSorting.backgroundColor = ColorUtil.foregroundColor
        self.postSorting.textLabel?.textColor = ColorUtil.fontColor

        self.notifications.textLabel?.text = "Notification check interval"
        self.notifications.detailTextLabel?.text = "Notification support coming soon!"
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
        return 3
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
            case 0: return self.viewType
            case 1: return self.hideFAB
            case 2: return self.pinToolbar
            case 3: return self.scrubUsername
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch (indexPath.row) {
            case 0: return self.notifications
            default: fatalError("Unknown row in section 1")
            }
        case 2:
            switch (indexPath.row) {
            case 0: return self.postSorting
            case 1: return self.commentSorting
            default: fatalError("Unknown row in section 2")
            }
        default: fatalError("Unknown section")
        }

    }

    func showMenuComments(_ selector: UIView?) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Comment sorting", message: "", preferredStyle: .actionSheet)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        let selected = UIImage.init(named: "selected")!.imageResize(sizeChange: CGSize.init(width: 20, height: 20)).withColor(tintColor: .blue)

        for link in CommentSort.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default) { action -> Void in
                SettingValues.defaultCommentSorting = link
                UserDefaults.standard.set(link.path, forKey: SettingValues.pref_defaultCommentSorting)
                UserDefaults.standard.synchronize()
                self.commentSorting.detailTextLabel?.text = SettingValues.defaultCommentSorting.description
            }
            if(SettingValues.defaultCommentSorting == link){
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

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        let selected = UIImage.init(named: "selected")!.imageResize(sizeChange: CGSize.init(width: 20, height: 20)).withColor(tintColor: .blue)

        for link in LinkSortType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default) { action -> Void in
                self.showTimeMenu(s: link, selector: selector)
            }
            if(SettingValues.defaultSorting == link){
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
        if (s == .hot || s == .new) {
            SettingValues.defaultSorting = s
            UserDefaults.standard.set(s.path, forKey: SettingValues.pref_defaultSorting)
            UserDefaults.standard.synchronize()
            self.postSorting.detailTextLabel?.text = SettingValues.defaultSorting.description
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Close", style: .cancel) { action -> Void in
            }
            actionSheetController.addAction(cancelActionButton)

            let selected = UIImage.init(named: "selected")!.imageResize(sizeChange: CGSize.init(width: 20, height: 20)).withColor(tintColor: .blue)

            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default) { action -> Void in
                    print("Sort is \(s) and time is \(t)")
                    SettingValues.defaultSorting = s
                    UserDefaults.standard.set(s.path, forKey: SettingValues.pref_defaultSorting)
                    SettingValues.defaultTimePeriod = t
                    UserDefaults.standard.set(t.param, forKey: SettingValues.pref_defaultTimePeriod)
                    UserDefaults.standard.synchronize()
                    self.postSorting.detailTextLabel?.text = SettingValues.defaultSorting.description
                }
                if(SettingValues.defaultTimePeriod == t){
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

        if (indexPath.section == 2 && indexPath.row == 0) {
            showMenu(tableView.cellForRow(at: indexPath))
        } else if (indexPath.section == 2 && indexPath.row == 1) {
            showMenuComments(tableView.cellForRow(at: indexPath))
        }

    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0: return 4
        case 1: return 1
        case 2: return 2
        default: fatalError("Unknown number of sections")
        }
    }


}
