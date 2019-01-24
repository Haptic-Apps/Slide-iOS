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
    var commentSize: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "commentSize")
    var submissionSize: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "submissionSize")

    var submissionFont = UITableViewCell(style: .subtitle, reuseIdentifier: "submissionFont")
    var commentFont = UITableViewCell(style: .subtitle, reuseIdentifier: "commentFont")

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
    
    @objc func switchIsChanged(_ changed: UISwitch) {
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
        case 0: label.text  = "Font size"
        case 1: label.text  = "Submission font"
        case 2: label.text = "Comment font"
        default: label.text  = ""
        }
        return toReturn
    }
    
    func setSizeComment(size: Int) {
        SettingValues.commentFontOffset = size
        UserDefaults.standard.set(size, forKey: SettingValues.pref_commentFontSize)
        UserDefaults.standard.synchronize()
        FontGenerator.initialize()
        doFontSizes()
    }
    
    func setSizeSubmission(size: Int) {
        SettingValues.postFontOffset = size
        UserDefaults.standard.set(size, forKey: SettingValues.pref_postFontSize)
        UserDefaults.standard.synchronize()
        SubredditReorderViewController.changed = true
        CachedTitle.titleFont = FontGenerator.fontOfSize(size: 18, submission: true)
        FontGenerator.initialize()
        doFontSizes()
    }
    
    @objc func doCommentSize() {
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
        if currentCommentSize == -6 {
            cancelActionButton.setValue(selected, forKey: "image")
        }
        actionSheetController.addAction(cancelActionButton)

        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = commentSize.contentView
            presenter.sourceRect = commentSize.contentView.bounds
        }
        self.present(actionSheetController, animated: true, completion: nil)
    
    }
    
    @objc func doSubmissionSize() {
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
        enlarge.addTarget(self, action: #selector(SettingsFont.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        self.enlargeCell.textLabel?.text = "Make links larger and easier to select"
        self.enlargeCell.accessoryView = enlarge
        self.enlargeCell.textLabel?.numberOfLines = 0
        self.enlargeCell.backgroundColor = ColorUtil.foregroundColor
        self.enlargeCell.textLabel?.textColor = ColorUtil.fontColor
        enlargeCell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        type = UISwitch()
        type.isOn = SettingValues.showLinkContentType
        type.addTarget(self, action: #selector(SettingsFont.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        self.typeCell.textLabel?.text = "Show content type preview next to links"
        self.typeCell.textLabel?.numberOfLines = 0
        self.typeCell.textLabel?.lineBreakMode = .byWordWrapping
        self.typeCell.accessoryView = type
        self.typeCell.backgroundColor = ColorUtil.foregroundColor
        self.typeCell.textLabel?.textColor = ColorUtil.fontColor
        typeCell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        self.commentSize.backgroundColor = ColorUtil.foregroundColor
        self.commentSize.textLabel?.textColor = ColorUtil.fontColor
        self.commentSize.detailTextLabel?.textColor = ColorUtil.fontColor
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(self.doCommentSize))
        self.commentSize.contentView.addGestureRecognizer(tap)

        self.submissionSize.backgroundColor = ColorUtil.foregroundColor
        self.submissionSize.textLabel?.textColor = ColorUtil.fontColor
        self.submissionSize.detailTextLabel?.textColor = ColorUtil.fontColor
        let tap2 = UITapGestureRecognizer.init(target: self, action: #selector(self.doSubmissionSize))
        self.submissionSize.contentView.addGestureRecognizer(tap2)

        submissionFont.textLabel?.text = "Submission Font"
        submissionFont.backgroundColor = ColorUtil.foregroundColor
        submissionFont.textLabel?.textColor = ColorUtil.fontColor
        submissionFont.detailTextLabel?.textColor = ColorUtil.fontColor

        commentFont.textLabel?.text = "Comment Font"
        commentFont.backgroundColor = ColorUtil.foregroundColor
        commentFont.textLabel?.textColor = ColorUtil.fontColor
        commentFont.detailTextLabel?.textColor = ColorUtil.fontColor

        doFontSizes()
        self.tableView.tableFooterView = UIView()

    }
    
    func doFontSizes() {
        self.submissionSize.textLabel?.font = FontGenerator.fontOfSize(size: 16, submission: true)
        self.commentSize.textLabel?.font = FontGenerator.fontOfSize(size: 16, submission: false)

        self.submissionFont.detailTextLabel?.font = FontGenerator.fontOfSize(size: 16, submission: true)
        self.submissionFont.detailTextLabel?.text = UserDefaults.standard.string(forKey: "postfont") ?? "Unknown"
        self.commentFont.detailTextLabel?.font = FontGenerator.fontOfSize(size: 16, submission: false)
        self.commentFont.detailTextLabel?.text = UserDefaults.standard.string(forKey: "commentfont") ?? "Unknown"
        
        var commentText = ""
        switch SettingValues.commentFontOffset {
        case 10:
            commentText = "Largest"
        case 8:
            commentText = "Extra Large"
        case 4:
            commentText = "Very Large"
        case 2:
            commentText = "Large"
        case 0:
            commentText = "Normal"
        case -2:
            commentText = "Small"
        case -4:
            commentText = "Very Small"
        case -6:
            commentText = "Smallest"
        default:
            commentText = "Default"
        }
        
        var submissionText = ""
        switch SettingValues.postFontOffset {
        case 10:
            submissionText = "Largest"
        case 8:
            submissionText = "Extra Large"
        case 4:
            submissionText = "Very Large"
        case 2:
            submissionText = "Large"
        case 0:
            submissionText = "Normal"
        case -2:
            submissionText = "Small"
        case -4:
            submissionText = "Very Small"
        case -6:
            submissionText = "Smallest"
        default:
            submissionText = "Default"
        }
        
        self.commentSize.textLabel?.text = "Comment font size"
        self.submissionSize.textLabel?.text = "Submission title size"
        
        self.submissionSize.detailTextLabel?.text = submissionText
        self.commentSize.detailTextLabel?.text = commentText

        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
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
            case 0: return self.submissionSize
            case 1: return self.commentSize
            case 2: return self.enlargeCell
            case 3: return self.typeCell
            default: fatalError("Unknown row in section 0")
            }
        case 1:
            switch indexPath.row {
            case 0: return self.submissionFont
            case 1: return self.commentFont
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
                let vc = FontSelectionTableViewController()
                vc.key = "postfont"
                vc.delegate = self
                navigationController?.pushViewController(vc, animated: true)
            case 1:
                let vc = FontSelectionTableViewController()
                vc.key = "commentfont"
                vc.delegate = self
                navigationController?.pushViewController(vc, animated: true)
            default: fatalError("Unknown row in section 1")
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4    // section 0 has 2 rows
        case 1: return 2    // section 1 has 2 rows
        default: fatalError("Unknown number of sections")
        }
    }
    
}

extension SettingsFont: FontSelectionTableViewControllerDelegate {

    func fontSelectionTableViewController(_ controller: FontSelectionTableViewController, didChooseFontWithName fontName: String) {

        // Update the VC
        UserDefaults.standard.synchronize()
        FontGenerator.initialize()
        CachedTitle.titleFont = FontGenerator.fontOfSize(size: 18, submission: true)
        CachedTitle.titles.removeAll()
        doFontSizes()
    }
}
