//
//  SettingsFont.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/28/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SettingsFont: BubbleSettingTableViewController {

    var enlargeCell: UITableViewCell = InsetCell()
    var typeCell: UITableViewCell = InsetCell()
    var enlarge = UISwitch()
    var type = UISwitch()

    var previewCell: UITableViewCell = InsetCell()
    var preview = UISwitch()

    var commentSize: UITableViewCell = InsetCell(style: .value1, reuseIdentifier: "commentSize")
    var submissionSize: UITableViewCell = InsetCell(style: .value1, reuseIdentifier: "submissionSize")

    var submissionFont = InsetCell(style: .value1, reuseIdentifier: "submissionFont")
    var commentFont = InsetCell(style: .value1, reuseIdentifier: "commentFont")

    var submissionWeight = InsetCell(style: .value1, reuseIdentifier: "submissionWeight")
    var commentWeight = InsetCell(style: .value1, reuseIdentifier: "commentWeight")

    var submissionPreview = InsetCell(style: .default, reuseIdentifier: "submissionPreview").then {
        $0.selectionStyle = .none
    }
    var commentPreview = InsetCell(style: .default, reuseIdentifier: "commentPreview").then {
        $0.selectionStyle = .none
    }

    let fontSizes: [Int: String] = [
        10: "Largest",
        8: "Extra Large",
        4: "Very Large",
        2: "Large",
        0: "Normal",
        -2: "Small",
        -4: "Very Small",
        -6: "Smallest",
        ]

    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == enlarge {
            SettingValues.enlargeLinks = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_enlargeLinks)
        } else if changed == type {
            SettingValues.showLinkContentType = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_showLinkContentType)
        } else if changed == preview {
            SettingValues.disablePreviews = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_disablePreviews)
        }
        UserDefaults.standard.synchronize()
    }
    
    func setSizeComment(size: Int) {
        SettingValues.commentFontOffset = size
        UserDefaults.standard.set(size, forKey: SettingValues.pref_commentFontSize)
        UserDefaults.standard.synchronize()
        FontGenerator.initialize()
        refresh()
    }
    
    func setSizeSubmission(size: Int) {
        SettingValues.postFontOffset = size
        UserDefaults.standard.set(size, forKey: SettingValues.pref_postFontSize)
        UserDefaults.standard.synchronize()
        SubredditReorderViewController.changed = true
        CachedTitle.titleFont = FontGenerator.fontOfSize(size: CachedTitle.baseFontSize, submission: true)
        FontGenerator.initialize()
        refresh()
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        // set the title
        self.title = "Font settings"
        headers = ["Submissions", "Comments", "Link options"]

        enlarge = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.enlargeLinks
        }
        enlarge.addTarget(self, action: #selector(SettingsFont.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        enlargeCell.textLabel?.text = "Make links larger and easier to select"
        enlargeCell.accessoryView = enlarge
        enlargeCell.textLabel?.numberOfLines = 0
        enlargeCell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        preview = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.disablePreviews
        }
        preview.addTarget(self, action: #selector(SettingsFont.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        previewCell.textLabel?.text = "Disable link preview bubbles"
        previewCell.accessoryView = preview
        previewCell.textLabel?.numberOfLines = 0
        previewCell.selectionStyle = UITableViewCell.SelectionStyle.none

        type = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.showLinkContentType
        }
        type.addTarget(self, action: #selector(SettingsFont.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        typeCell.textLabel?.text = "Show content type preview next to links"
        typeCell.textLabel?.numberOfLines = 0
        typeCell.textLabel?.lineBreakMode = .byWordWrapping
        typeCell.accessoryView = type
        typeCell.selectionStyle = UITableViewCell.SelectionStyle.none

        submissionPreview.textLabel?.text = "I'm a text preview!"

        submissionSize.textLabel?.text = "Font size"
        submissionSize.addTapGestureRecognizer { [weak self] in
            self?.submissionSizeCellWasTapped()
        }

        submissionWeight.textLabel?.text = "Font variant"
        submissionWeight.addTapGestureRecognizer { [weak self] in
            self?.weightCellWasTapped(submission: true)
        }

        submissionFont.textLabel?.text = "Font"
        submissionFont.addTapGestureRecognizer { [weak self] in
            self?.submissionFontCellWasTapped()
        }

        commentPreview.textLabel?.text = "I'm a text preview!"

        commentSize.textLabel?.text = "Font size"
        commentSize.addTapGestureRecognizer { [weak self] in
            self?.commentSizeCellWasTapped()
        }

        commentFont.textLabel?.text = "Font"
        commentFont.addTapGestureRecognizer { [weak self] in
            self?.commentFontCellWasTapped()
        }

        commentWeight.textLabel?.text = "Font variant"
        commentWeight.addTapGestureRecognizer { [weak self] in
            self?.weightCellWasTapped(submission: false)
        }

        refresh()
        self.tableView.tableFooterView = UIView()

    }
    
    func refresh() {
        let submissionFont = FontGenerator.fontOfSize(size: 16, submission: true)
        let commentFont = FontGenerator.fontOfSize(size: 16, submission: false)

        self.submissionPreview.textLabel?.font = submissionFont
        self.commentPreview.textLabel?.font = commentFont

        let subFontKey = UserDefaults.standard.string(forKey: "postfont") ?? ""
        let subFontDisplayName = FontMapping.fromStoredName(name: subFontKey).displayedName
        self.submissionFont.detailTextLabel?.text = subFontDisplayName

        let commentFontKey = UserDefaults.standard.string(forKey: "commentfont") ?? ""
        let commentFontDisplayName = FontMapping.fromStoredName(name: commentFontKey).displayedName
        self.commentFont.detailTextLabel?.text = commentFontDisplayName

        self.submissionSize.detailTextLabel?.text = fontSizes[SettingValues.postFontOffset] ?? "Default"
        self.commentSize.detailTextLabel?.text = fontSizes[SettingValues.commentFontOffset] ?? "Default"

        self.submissionWeight.detailTextLabel?.text = FontGenerator.fontOfSize(size: 12, submission: true).fontName
        self.commentWeight.detailTextLabel?.text = FontGenerator.fontOfSize(size: 12, submission: false).fontName

        // Enable/disable if we have font variants to choose from for submission font
        if UIFont.fontNames(forFamilyName: submissionFont.familyName).count > 1 {
            self.submissionWeight.contentView.alpha = 1
            self.submissionWeight.isUserInteractionEnabled = true
        } else {
            self.submissionWeight.detailTextLabel?.text = "Default"
            self.submissionWeight.contentView.alpha = 0.7
            self.submissionWeight.isUserInteractionEnabled = false
        }

        // Enable/disable if we have font variants to choose from for comment font
        if UIFont.fontNames(forFamilyName: commentFont.familyName).count > 1 {
            self.commentWeight.contentView.alpha = 1
            self.commentWeight.isUserInteractionEnabled = true
        } else {
            self.commentWeight.detailTextLabel?.text = "Default"
            self.commentWeight.contentView.alpha = 0.7
            self.commentWeight.isUserInteractionEnabled = false
        }

        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: cell = self.submissionFont
            case 1: cell = self.submissionWeight
            case 2: cell = self.submissionSize
            case 3: cell = self.submissionPreview
            default: fatalError("Unknown row in section \(indexPath.section)")
            }
        case 1:
            switch indexPath.row {
            case 0: cell = self.commentFont
            case 1: cell = self.commentWeight
            case 2: cell = self.commentSize
            case 3: cell = self.commentPreview
            default: fatalError("Unknown row in section \(indexPath.section)")
            }
        case 2:
            switch indexPath.row {
            case 0: cell = self.previewCell
            case 1: cell = self.enlargeCell
            case 2: cell = self.typeCell
            default: fatalError("Unknown row in section \(indexPath.section)")
            }
        default: fatalError("Unknown section")
        }

        cell.style()
        if indexPath == IndexPath(row: 3, section: 0) || indexPath == IndexPath(row: 3, section: 1) {
            cell.backgroundColor = ColorUtil.theme.backgroundColor
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Each cell already has a tap handler in init
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4    // section 0 has 2 rows
        case 1: return 4    // section 1 has 2 rows
        case 2: return 3
        default: fatalError("Unknown number of sections")
        }
    }
}

// MARK: - Actions
extension SettingsFont {
    func submissionFontCellWasTapped() {
        let vc = FontSelectionTableViewController()
        vc.title = "Submission Font"
        vc.key = FontSelectionTableViewController.Key.postFont
        vc.delegate = self
        VCPresenter.showVC(viewController: vc, popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
    }

    func commentFontCellWasTapped() {
        let vc = FontSelectionTableViewController()
        vc.title = "Comment Font"
        vc.key = FontSelectionTableViewController.Key.commentFont
        vc.delegate = self
        VCPresenter.showVC(viewController: vc, popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
    }

    func commentSizeCellWasTapped() {
        let actionSheetController = DragDownAlertMenu(title: "Comment font size", subtitle: "Applies to text displayed throughout Slide", icon: nil, themeColor: nil, full: true)

        let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon()

        for key in fontSizes.keys.sorted() {
            let description = fontSizes[key]!
            actionSheetController.addAction(title: description, icon: SettingValues.commentFontOffset == key ? selected : nil) {
                self.setSizeComment(size: key)
            }
        }

        actionSheetController.show(self)
    }

    func submissionSizeCellWasTapped() {
        let actionSheetController = DragDownAlertMenu(title: "Submission font size", subtitle: "Applies to submission titles and subtitles", icon: nil, themeColor: nil, full: true)

        let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon()

        for key in fontSizes.keys.sorted() {
            let description = fontSizes[key]!
            actionSheetController.addAction(title: description, icon: SettingValues.postFontOffset == key ? selected : nil) {
                self.setSizeSubmission(size: key)
            }
        }
        
        actionSheetController.show(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CachedTitle.titles.removeAll()
    }

    func weightCellWasTapped(submission: Bool) {

        let actionSheetController = DragDownAlertMenu(title: submission ? "Submission font variant" : "Comment font variant", subtitle: "", icon: nil, themeColor: nil, full: true)

        let currentFamily = FontGenerator.fontOfSize(size: 16, submission: submission).familyName
        let fontsInFamily = UIFont.fontNames(forFamilyName: currentFamily)

        let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon()

        // Prune out the weights that aren't available for the selected font
        for font in fontsInFamily {
            actionSheetController.addAction(title: font, icon: font == FontGenerator.fontOfSize(size: 16, submission: submission).fontName ? selected : nil) {
                // Update the stored font weight
                UserDefaults.standard.set(font, forKey: submission ? "postfont" : "commentfont")
                
                UserDefaults.standard.synchronize()
                FontGenerator.initialize()
                CachedTitle.titleFont = FontGenerator.fontOfSize(size: CachedTitle.baseFontSize, submission: true)
                CachedTitle.titles.removeAll()
                self.refresh()
            }
        }

        actionSheetController.show(self)
    }
}

extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        var attributes = fontDescriptor.fontAttributes
        var traits = (attributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]

        traits[.weight] = weight

        attributes[.name] = nil
        attributes[.traits] = traits
        attributes[.family] = familyName

        let descriptor = UIFontDescriptor(fontAttributes: attributes)

        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

extension SettingsFont: FontSelectionTableViewControllerDelegate {

    func fontSelectionTableViewController(_ controller: FontSelectionTableViewController,
                                          didChooseFontWithName fontName: String,
                                          forKey key: FontSelectionTableViewController.Key) {

        // Reset the font weight if the font was changed
        switch key {
        case .postFont:
            SettingValues.submissionFontWeight = "Regular"
        case .commentFont:
            SettingValues.commentFontWeight = "Regular"
        }

        // Update the VC
        UserDefaults.standard.synchronize()
        FontGenerator.initialize()
        CachedTitle.titleFont = FontGenerator.fontOfSize(size: CachedTitle.baseFontSize, submission: true)
        CachedTitle.titles.removeAll()
        refresh()
    }
}

private extension UITableViewCell {
    func style() {
        backgroundColor = ColorUtil.theme.foregroundColor
        textLabel?.textColor = ColorUtil.theme.fontColor
        detailTextLabel?.textColor = ColorUtil.theme.fontColor.withAlphaComponent(0.7)
    }
}
