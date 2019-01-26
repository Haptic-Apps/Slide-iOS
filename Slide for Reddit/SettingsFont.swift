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

    var commentSize: UITableViewCell = UITableViewCell(style: .value1, reuseIdentifier: "commentSize")
    var submissionSize: UITableViewCell = UITableViewCell(style: .value1, reuseIdentifier: "submissionSize")

    var submissionFont = UITableViewCell(style: .value1, reuseIdentifier: "submissionFont")
    var commentFont = UITableViewCell(style: .value1, reuseIdentifier: "commentFont")

    var submissionWeight = UITableViewCell(style: .value1, reuseIdentifier: "submissionWeight")
    var commentWeight = UITableViewCell(style: .value1, reuseIdentifier: "commentWeight")

    var submissionPreview = UITableViewCell(style: .default, reuseIdentifier: "submissionPreview").then {
        $0.selectionStyle = .none
    }
    var commentPreview = UITableViewCell(style: .default, reuseIdentifier: "commentPreview").then {
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
        CachedTitle.titleFont = FontGenerator.fontOfSize(size: 18, submission: true)
        FontGenerator.initialize()
        refresh()
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "Font Settings"
        self.tableView.separatorStyle = .none

        enlarge = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.enlargeLinks
        }
        enlarge.addTarget(self, action: #selector(SettingsFont.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        enlargeCell.textLabel?.text = "Make links larger and easier to select"
        enlargeCell.accessoryView = enlarge
        enlargeCell.textLabel?.numberOfLines = 0
        enlargeCell.selectionStyle = UITableViewCell.SelectionStyle.none
        
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

        submissionWeight.textLabel?.text = "Font weight"
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

        commentWeight.textLabel?.text = "Font weight"
        commentWeight.addTapGestureRecognizer { [weak self] in
            self?.weightCellWasTapped(submission: false)
        }

        refresh()
        self.tableView.tableFooterView = UIView()

    }
    
    func refresh() {
        self.submissionPreview.textLabel?.font = FontGenerator.fontOfSize(size: 16, submission: true)
        self.commentPreview.textLabel?.font = FontGenerator.fontOfSize(size: 16, submission: false)

//        self.submissionFont.detailTextLabel?.font = FontGenerator.fontOfSize(size: 16, submission: true)
        self.submissionFont.detailTextLabel?.text = FontGenerator.fontOfSize(size: 16, submission: true).familyName
//        self.commentFont.detailTextLabel?.font = FontGenerator.fontOfSize(size: 16, submission: false)
        self.commentFont.detailTextLabel?.text = FontGenerator.fontOfSize(size: 16, submission: false).familyName

        self.submissionSize.detailTextLabel?.text = fontSizes[SettingValues.postFontOffset] ?? "Default"
        self.commentSize.detailTextLabel?.text = fontSizes[SettingValues.commentFontOffset] ?? "Default"

        self.submissionWeight.detailTextLabel?.text = SettingValues.submissionFontWeight ?? "Regular"
        self.commentWeight.detailTextLabel?.text = SettingValues.commentFontWeight ?? "Regular"

        self.tableView.reloadData()
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
        let cell: UITableViewCell
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: cell = self.submissionFont
            case 1: cell = self.submissionSize
            case 2: cell = self.submissionWeight
            case 3: cell = self.submissionPreview
            default: fatalError("Unknown row in section \(indexPath.section)")
            }
        case 1:
            switch indexPath.row {
            case 0: cell = self.commentFont
            case 1: cell = self.commentSize
            case 2: cell = self.commentWeight
            case 3: cell = self.commentPreview
            default: fatalError("Unknown row in section \(indexPath.section)")
            }
        case 2:
            switch indexPath.row {
            case 0: cell = self.enlargeCell
            case 1: cell = self.typeCell
            default: fatalError("Unknown row in section \(indexPath.section)")
            }
        default: fatalError("Unknown section")
        }

        cell.style()
        if indexPath == IndexPath(row: 3, section: 0) || indexPath == IndexPath(row: 3, section: 1) {
            cell.backgroundColor = ColorUtil.backgroundColor
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
        case 2: return 2
        default: fatalError("Unknown number of sections")
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel().then {
            $0.textColor = ColorUtil.baseAccent
            $0.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        }
        let toReturn = label.withPadding(padding: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor

        switch section {
        case 0: label.text = "Submissions"
        case 1: label.text = "Comments"
        case 2: label.text = "Options"
        default: label.text = ""
        }
        return toReturn
    }
    
}

// MARK: - Actions
extension SettingsFont {
    func submissionFontCellWasTapped() {
        let vc = FontSelectionTableViewController()
        vc.key = FontSelectionTableViewController.Key.postFont
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }

    func commentFontCellWasTapped() {
        let vc = FontSelectionTableViewController()
        vc.key = FontSelectionTableViewController.Key.postFont
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }

    func commentSizeCellWasTapped() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Comment font size", message: "", preferredStyle: .actionSheet)

        actionSheetController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        for key in fontSizes.keys.sorted() {
            let description = fontSizes[key]!
            let action = UIAlertAction(title: description, style: .default) { _ in
                self.setSizeComment(size: key)
            }
            if SettingValues.commentFontOffset == key {
                let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)
                action.setValue(selected, forKey: "image")
            }
            actionSheetController.addAction(action)
        }

        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = commentSize.contentView
            presenter.sourceRect = commentSize.contentView.bounds
        }
        self.present(actionSheetController, animated: true, completion: nil)

    }

    func submissionSizeCellWasTapped() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Submission font size", message: "", preferredStyle: .actionSheet)

        actionSheetController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        for key in fontSizes.keys.sorted() {
            let description = fontSizes[key]!
            let action = UIAlertAction(title: description, style: .default) { _ in
                self.setSizeSubmission(size: key)
            }
            if SettingValues.postFontOffset == key {
                let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)
                action.setValue(selected, forKey: "image")
            }
            actionSheetController.addAction(action)
        }

        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = submissionSize.contentView
            presenter.sourceRect = submissionSize.contentView.bounds
        }
        self.present(actionSheetController, animated: true, completion: nil)
    }

    func weightCellWasTapped(submission: Bool) {

        let actionSheetController: UIAlertController = UIAlertController(title: submission ? "Submission font size" : "Comment font size", message: "", preferredStyle: .actionSheet)

        actionSheetController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        let currentFamily = FontGenerator.fontOfSize(size: 16, submission: submission).familyName
        let fontsInFamily = UIFont.fontNames(forFamilyName: currentFamily)
        // Prune out the weights that aren't available for the selected font
        let availableWeights = FontGenerator.FontWeight.allCases.filter { weight in
            if weight == .regular {
                return true // Always display regular
            }
            for font in fontsInFamily {
                if font.lowercased().contains(weight.rawValue.lowercased()) {
                    return true
                }
            }
            return false
        }

        for weight in availableWeights {
            let action = UIAlertAction(title: weight.rawValue, style: .default) { _ in
                // Update the stored font weight
                if submission {
                    SettingValues.submissionFontWeight = weight.rawValue
                } else {
                    SettingValues.commentFontWeight = weight.rawValue
                }

                UserDefaults.standard.synchronize()
                FontGenerator.initialize()
                CachedTitle.titleFont = FontGenerator.fontOfSize(size: 18, submission: true)
                CachedTitle.titles.removeAll()
                self.refresh()
            }
            actionSheetController.addAction(action)
        }

        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = submissionSize.contentView
            presenter.sourceRect = submissionSize.contentView.bounds
        }
        self.present(actionSheetController, animated: true, completion: nil)
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
        CachedTitle.titleFont = FontGenerator.fontOfSize(size: 18, submission: true)
        CachedTitle.titles.removeAll()
        refresh()
    }
}

private extension UITableViewCell {
    func style() {
        backgroundColor = ColorUtil.foregroundColor
        textLabel?.textColor = ColorUtil.fontColor
        detailTextLabel?.textColor = ColorUtil.fontColor.withAlphaComponent(0.7)
    }
}
