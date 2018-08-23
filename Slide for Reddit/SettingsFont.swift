//
//  SettingsFont.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/28/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SettingsFont: UITableViewController {
    
    var enlargeCell: UITableViewCell = UITableViewCell()
    var typeCell: UITableViewCell = UITableViewCell()
    var enlarge = UISwitch()
    var type = UISwitch()
    var commentSize: UITableViewCell = UITableViewCell()
    var submissionSize: UITableViewCell = UITableViewCell()

    var commentHelvetica: UITableViewCell = UITableViewCell()
    var commentRCR: UITableViewCell = UITableViewCell()
    var commentRCB: UITableViewCell = UITableViewCell()
    var commentRL: UITableViewCell = UITableViewCell()
    var commentRB: UITableViewCell = UITableViewCell()
    var commentRM: UITableViewCell = UITableViewCell()
    var commentSystem: UITableViewCell = UITableViewCell()
    var commentPapyrus: UITableViewCell = UITableViewCell()
    var commentChalkboard: UITableViewCell = UITableViewCell()

    var submissionHelvetica: UITableViewCell = UITableViewCell()
    var submissionRCR: UITableViewCell = UITableViewCell()
    var submissionRCB: UITableViewCell = UITableViewCell()
    var submissionRL: UITableViewCell = UITableViewCell()
    var submissionRB: UITableViewCell = UITableViewCell()
    var submissionRM: UITableViewCell = UITableViewCell()
    var submissionSystem: UITableViewCell = UITableViewCell()
    var submissionPapyrus: UITableViewCell = UITableViewCell()
    var submissionChalkboard: UITableViewCell = UITableViewCell()

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
        if changed == enlarge {
            SettingValues.enlargeLinks = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_enlargeLinks)
        } else if changed == type {
            SettingValues.showLinkContentType = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_showLinkContentType)
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
        case 0: label.text  = "Links"
        case 1: label.text  = "Submissions"
        case 2: label.text = "Comments"
        default: label.text  = ""
        }
        return toReturn
    }
    
    func setSizeComment(size: Int) {
        SettingValues.commentFontOffset = size
        UserDefaults.standard.set(size, forKey: SettingValues.pref_commentFontSize)
        UserDefaults.standard.synchronize()
        FontGenerator.initialize()
    }
    
    func setSizeSubmission(size: Int) {
        SettingValues.postFontOffset = size
        UserDefaults.standard.set(size, forKey: SettingValues.pref_postFontSize)
        UserDefaults.standard.synchronize()
        SubredditReorderViewController.changed = true
        CachedTitle.titleFont = FontGenerator.fontOfSize(size: 18, submission: true)
        FontGenerator.initialize()
    }
    
    func doCommentSize() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Comment font size", message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        let currentCommentSize = SettingValues.commentFontOffset
        let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)
        
        cancelActionButton = UIAlertAction(title: "Largest", style: .default) { _ -> Void in
            self.setSizeComment(size: 10)
        }
        if currentCommentSize == 10 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Extra Large", style: .default) { _ -> Void in
            self.setSizeComment(size: 8)
        }
        if currentCommentSize == 8 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Very Large", style: .default) { _ -> Void in
            self.setSizeComment(size: 4)
        }
        if currentCommentSize == 4 {
            cancelActionButton.setValue(selected, forKey: "image")
        }

        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Large", style: .default) { _ -> Void in
            self.setSizeComment(size: 2)
        }
        if currentCommentSize == 2 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Normal", style: .default) { _ -> Void in
            self.setSizeComment(size: 0)
        }
        if currentCommentSize == 0 {
            cancelActionButton.setValue(selected, forKey: "image")
        }

        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Small", style: .default) { _ -> Void in
            self.setSizeComment(size: -2)
        }
        if currentCommentSize == -2 {
            cancelActionButton.setValue(selected, forKey: "image")
        }

        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Very Small", style: .default) { _ -> Void in
            self.setSizeComment(size: -4)
        }
        if currentCommentSize == -4 {
            cancelActionButton.setValue(selected, forKey: "image")
        }

        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Smallest", style: .default) { _ -> Void in
            self.setSizeComment(size: -6)
        }
        actionSheetController.addAction(cancelActionButton)

        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = commentSize.contentView
            presenter.sourceRect = commentSize.contentView.bounds
        }
        self.present(actionSheetController, animated: true, completion: nil)
    
    }
    
    func doSubmissionSize() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Submission font size", message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        let currentLinkSize = SettingValues.postFontOffset
        let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

        cancelActionButton = UIAlertAction(title: "Largest", style: .default) { _ -> Void in
            self.setSizeSubmission(size: 10)
        }
        if currentLinkSize == 10 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)

        cancelActionButton = UIAlertAction(title: "Extra Large", style: .default) { _ -> Void in
            self.setSizeSubmission(size: 8)
        }
        if currentLinkSize == 8 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Very Large", style: .default) { _ -> Void in
            self.setSizeSubmission(size: 4)
        }
        if currentLinkSize == 4 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Large", style: .default) { _ -> Void in
            self.setSizeSubmission(size: 2)
        }
        if currentLinkSize == 2 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Normal", style: .default) { _ -> Void in
            self.setSizeSubmission(size: 0)
        }
        if currentLinkSize == 0 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Small", style: .default) { _ -> Void in
            self.setSizeSubmission(size: -2)
        }
        if currentLinkSize == -2 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Very Small", style: .default) { _ -> Void in
            self.setSizeSubmission(size: -4)
        }
        if currentLinkSize == -4 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Smallest", style: .default) { _ -> Void in
            self.setSizeSubmission(size: -6)
        }
        if currentLinkSize == -6 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)
        
        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = submissionSize.contentView
            presenter.sourceRect = submissionSize.contentView.bounds
        }
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Font"
        self.tableView.separatorStyle = .none

        enlarge = UISwitch()
        enlarge.isOn = SettingValues.enlargeLinks
        enlarge.addTarget(self, action: #selector(SettingsFont.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.enlargeCell.textLabel?.text = "Enlarge links"
        self.enlargeCell.accessoryView = enlarge
        self.enlargeCell.backgroundColor = ColorUtil.foregroundColor
        self.enlargeCell.textLabel?.textColor = ColorUtil.fontColor
        enlargeCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        type = UISwitch()
        type.isOn = SettingValues.showLinkContentType
        type.addTarget(self, action: #selector(SettingsFont.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.typeCell.textLabel?.text = "Show content type next to links"
        self.typeCell.textLabel?.numberOfLines = 0
        self.typeCell.textLabel?.lineBreakMode = .byWordWrapping
        self.typeCell.accessoryView = type
        self.typeCell.backgroundColor = ColorUtil.foregroundColor
        self.typeCell.textLabel?.textColor = ColorUtil.fontColor
        typeCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        self.commentSize.textLabel?.text = "Comment font size"
        self.commentSize.detailTextLabel?.text = "Small"
        self.commentSize.backgroundColor = ColorUtil.foregroundColor
        self.commentSize.textLabel?.textColor = ColorUtil.fontColor
        self.commentSize.detailTextLabel?.textColor = ColorUtil.fontColor
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(self.doCommentSize))
        self.commentSize.contentView.addGestureRecognizer(tap)

        self.submissionSize.textLabel?.text = "Submission font size"
        self.submissionSize.detailTextLabel?.text = "Large"
        self.submissionSize.backgroundColor = ColorUtil.foregroundColor
        self.submissionSize.textLabel?.textColor = ColorUtil.fontColor
        self.submissionSize.detailTextLabel?.textColor = ColorUtil.fontColor
        let tap2 = UITapGestureRecognizer.init(target: self, action: #selector(self.doSubmissionSize))
        self.submissionSize.contentView.addGestureRecognizer(tap2)

        self.commentHelvetica.textLabel?.text = "Helvetica"
        self.commentHelvetica.textLabel?.font = FontGenerator.Font.HELVETICA.font
        self.commentHelvetica.backgroundColor = ColorUtil.foregroundColor
        self.commentHelvetica.textLabel?.textColor = ColorUtil.fontColor
        
        self.commentRCR.textLabel?.text = "Roboto Condensed"
        self.commentRCR.textLabel?.font = FontGenerator.Font.ROBOTOCONDENSED_REGULAR.font
        self.commentRCR.backgroundColor = ColorUtil.foregroundColor
        self.commentRCR.textLabel?.textColor = ColorUtil.fontColor
        
        self.commentRCB.textLabel?.text = "Roboto Condensed Bold"
        self.commentRCB.textLabel?.font = FontGenerator.Font.ROBOTOCONDENSED_BOLD.font
        self.commentRCB.backgroundColor = ColorUtil.foregroundColor
        self.commentRCB.textLabel?.textColor = ColorUtil.fontColor

        self.commentRL.textLabel?.text = "Roboto Light"
        self.commentRL.textLabel?.font = FontGenerator.Font.ROBOTO_LIGHT.font
        self.commentRL.backgroundColor = ColorUtil.foregroundColor
        self.commentRL.textLabel?.textColor = ColorUtil.fontColor

        self.commentRB.textLabel?.text = "Roboto Bold"
        self.commentRB.textLabel?.font = FontGenerator.Font.ROBOTO_BOLD.font
        self.commentRB.backgroundColor = ColorUtil.foregroundColor
        self.commentRB.textLabel?.textColor = ColorUtil.fontColor

        self.commentRM.textLabel?.text = "Roboto Medium"
        self.commentRM.textLabel?.font = FontGenerator.Font.ROBOTO_MEDIUM.font
        self.commentRM.backgroundColor = ColorUtil.foregroundColor
        self.commentRM.textLabel?.textColor = ColorUtil.fontColor

        self.commentSystem.textLabel?.text = "System"
        self.commentSystem.textLabel?.font = FontGenerator.Font.SYSTEM.font
        self.commentSystem.backgroundColor = ColorUtil.foregroundColor
        self.commentSystem.textLabel?.textColor = ColorUtil.fontColor
        
        self.submissionHelvetica.textLabel?.text = "Helvetica"
        self.submissionHelvetica.textLabel?.font = FontGenerator.Font.HELVETICA.font
        self.submissionHelvetica.backgroundColor = ColorUtil.foregroundColor
        self.submissionHelvetica.textLabel?.textColor = ColorUtil.fontColor
        
        self.submissionRCR.textLabel?.text = "Roboto Condensed"
        self.submissionRCR.textLabel?.font = FontGenerator.Font.ROBOTOCONDENSED_REGULAR.font
        self.submissionRCR.backgroundColor = ColorUtil.foregroundColor
        self.submissionRCR.textLabel?.textColor = ColorUtil.fontColor
        
        self.submissionRCB.textLabel?.text = "Roboto Condensed Bold"
        self.submissionRCB.textLabel?.font = FontGenerator.Font.ROBOTOCONDENSED_BOLD.font
        self.submissionRCB.backgroundColor = ColorUtil.foregroundColor
        self.submissionRCB.textLabel?.textColor = ColorUtil.fontColor
        
        self.submissionRL.textLabel?.text = "Roboto Light"
        self.submissionRL.textLabel?.font = FontGenerator.Font.ROBOTO_LIGHT.font
        self.submissionRL.backgroundColor = ColorUtil.foregroundColor
        self.submissionRL.textLabel?.textColor = ColorUtil.fontColor
        
        self.submissionRB.textLabel?.text = "Roboto Bold"
        self.submissionRB.textLabel?.font = FontGenerator.Font.ROBOTO_BOLD.font
        self.submissionRB.backgroundColor = ColorUtil.foregroundColor
        self.submissionRB.textLabel?.textColor = ColorUtil.fontColor
        
        self.submissionRM.textLabel?.text = "Roboto Medium"
        self.submissionRM.textLabel?.font = FontGenerator.Font.ROBOTO_MEDIUM.font
        self.submissionRM.backgroundColor = ColorUtil.foregroundColor
        self.submissionRM.textLabel?.textColor = ColorUtil.fontColor
        
        self.submissionSystem.textLabel?.text = "System"
        self.submissionSystem.textLabel?.font = FontGenerator.Font.SYSTEM.font
        self.submissionSystem.backgroundColor = ColorUtil.foregroundColor
        self.submissionSystem.textLabel?.textColor = ColorUtil.fontColor
        
        self.commentPapyrus.textLabel?.text = "Papyrus"
        self.commentPapyrus.textLabel?.font = FontGenerator.Font.PAPYRUS.font
        self.commentPapyrus.backgroundColor = ColorUtil.foregroundColor
        self.commentPapyrus.textLabel?.textColor = ColorUtil.fontColor
        
        self.submissionPapyrus.textLabel?.text = "Papyrus"
        self.submissionPapyrus.textLabel?.font = FontGenerator.Font.PAPYRUS.font
        self.submissionPapyrus.backgroundColor = ColorUtil.foregroundColor
        self.submissionPapyrus.textLabel?.textColor = ColorUtil.fontColor

        self.commentChalkboard.textLabel?.text = "Chalkboard"
        self.commentChalkboard.textLabel?.font = FontGenerator.Font.CHALKBOARD.font
        self.commentChalkboard.backgroundColor = ColorUtil.foregroundColor
        self.commentChalkboard.textLabel?.textColor = ColorUtil.fontColor

        self.submissionChalkboard.textLabel?.text = "Chalkboard"
        self.submissionChalkboard.textLabel?.font = FontGenerator.Font.CHALKBOARD.font
        self.submissionChalkboard.backgroundColor = ColorUtil.foregroundColor
        self.submissionChalkboard.textLabel?.textColor = ColorUtil.fontColor

        doChecks()
        self.tableView.tableFooterView = UIView()

    }
    
    func doChecks() {
        
        submissionHelvetica.accessoryType = .none
        submissionRCR.accessoryType = .none
        submissionRCB.accessoryType = .none
        submissionRL.accessoryType = .none
        submissionRB.accessoryType = .none
        submissionRM.accessoryType = .none
        submissionSystem.accessoryType = .none
        submissionPapyrus.accessoryType = .none
        submissionChalkboard.accessoryType = .none
        switch FontGenerator.postFont {
        case .HELVETICA:
            submissionHelvetica.accessoryType = .checkmark
        case .ROBOTOCONDENSED_REGULAR:
            submissionRCR.accessoryType = .checkmark
        case .ROBOTOCONDENSED_BOLD:
            submissionRCB.accessoryType = .checkmark
        case .ROBOTO_LIGHT:
            submissionRL.accessoryType = .checkmark
        case .ROBOTO_BOLD:
            submissionRB.accessoryType = .checkmark
        case .ROBOTO_MEDIUM:
            submissionRM.accessoryType = .checkmark
        case .PAPYRUS:
            submissionPapyrus.accessoryType = .checkmark
        case .CHALKBOARD:
            submissionChalkboard.accessoryType = .checkmark
        case .SYSTEM:
            submissionSystem.accessoryType = .checkmark
        }

        commentHelvetica.accessoryType = .none
        commentRCR.accessoryType = .none
        commentRCB.accessoryType = .none
        commentRL.accessoryType = .none
        commentRB.accessoryType = .none
        commentRM.accessoryType = .none
        commentSystem.accessoryType = .none
        commentPapyrus.accessoryType = .none
        commentChalkboard.accessoryType = .none
        switch FontGenerator.commentFont {
        case .HELVETICA:
            commentHelvetica.accessoryType = .checkmark
        case .ROBOTOCONDENSED_REGULAR:
            commentRCR.accessoryType = .checkmark
        case .ROBOTOCONDENSED_BOLD:
            commentRCB.accessoryType = .checkmark
        case .ROBOTO_LIGHT:
            commentRL.accessoryType = .checkmark
        case .ROBOTO_BOLD:
            commentRB.accessoryType = .checkmark
        case .ROBOTO_MEDIUM:
            commentRM.accessoryType = .checkmark
        case .PAPYRUS:
            commentPapyrus.accessoryType = .checkmark
        case .CHALKBOARD:
            commentChalkboard.accessoryType = .checkmark
        case .SYSTEM:
            commentSystem.accessoryType = .checkmark
        }

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
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.enlargeCell
            case 1: return self.typeCell
            case 2: return self.submissionSize
            case 3: return self.commentSize
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.submissionHelvetica
            case 1: return self.submissionRCR
            case 2: return self.submissionRCB
            case 3: return self.submissionRL
            case 4: return self.submissionRB
            case 5: return self.submissionRM
            case 6: return self.submissionSystem
            case 7: return self.submissionPapyrus
            case 8: return self.submissionChalkboard
            default: fatalError("Unknown row in section 1")
            }
        case 2:
            switch indexPath.row {
            case 0: return self.commentHelvetica
            case 1: return self.commentRCR
            case 2: return self.commentRCB
            case 3: return self.commentRL
            case 4: return self.commentRB
            case 5: return self.commentRM
            case 6: return self.commentSystem
            case 7: return self.commentPapyrus
            case 8: return self.commentChalkboard
            default: fatalError("Unknown row in section 1")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                UserDefaults.standard.set(FontGenerator.Font.HELVETICA.rawValue, forKey: "postfont")
            case 1:
                UserDefaults.standard.set(FontGenerator.Font.ROBOTOCONDENSED_REGULAR.rawValue, forKey: "postfont")
            case 2:
                UserDefaults.standard.set(FontGenerator.Font.ROBOTOCONDENSED_BOLD.rawValue, forKey: "postfont")
                UserDefaults.standard.synchronize()
            case 3:
                UserDefaults.standard.set(FontGenerator.Font.ROBOTO_LIGHT.rawValue, forKey: "postfont")
            case 4:
                UserDefaults.standard.set(FontGenerator.Font.ROBOTO_BOLD.rawValue, forKey: "postfont")
            case 5:
                UserDefaults.standard.set(FontGenerator.Font.ROBOTO_MEDIUM.rawValue, forKey: "postfont")
            case 6:
                UserDefaults.standard.set(FontGenerator.Font.SYSTEM.rawValue, forKey: "postfont")
            case 7:
                UserDefaults.standard.set(FontGenerator.Font.PAPYRUS.rawValue, forKey: "postfont")
            case 8:
                UserDefaults.standard.set(FontGenerator.Font.CHALKBOARD.rawValue, forKey: "postfont")
            default: fatalError("Unknown row in section 1")
            }
        } else if indexPath.section == 2 {
            switch indexPath.row {
            case 0:
                UserDefaults.standard.set(FontGenerator.Font.HELVETICA.rawValue, forKey: "commentfont")
            case 1:
                UserDefaults.standard.set(FontGenerator.Font.ROBOTOCONDENSED_REGULAR.rawValue, forKey: "commentfont")
            case 2:
                UserDefaults.standard.set(FontGenerator.Font.ROBOTOCONDENSED_BOLD.rawValue, forKey: "commentfont")
            case 3:
                UserDefaults.standard.set(FontGenerator.Font.ROBOTO_LIGHT.rawValue, forKey: "commentfont")
            case 4:
                UserDefaults.standard.set(FontGenerator.Font.ROBOTO_BOLD.rawValue, forKey: "commentfont")
            case 5:
                UserDefaults.standard.set(FontGenerator.Font.ROBOTO_MEDIUM.rawValue, forKey: "commentfont")
            case 6:
                UserDefaults.standard.set(FontGenerator.Font.SYSTEM.rawValue, forKey: "commentfont")
            case 7:
                UserDefaults.standard.set(FontGenerator.Font.PAPYRUS.rawValue, forKey: "commentfont")
            case 8:
                UserDefaults.standard.set(FontGenerator.Font.CHALKBOARD.rawValue, forKey: "commentfont")
            default: fatalError("Unknown row in section 1")
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
        UserDefaults.standard.synchronize()
        FontGenerator.initialize()
        doChecks()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4    // section 0 has 2 rows
        case 1: return 9    // section 1 has 1 row
        case 2: return 9    // section 1 has 1 row
        default: fatalError("Unknown number of sections")
        }
    }
    
}
