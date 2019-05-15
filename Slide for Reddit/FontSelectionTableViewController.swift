//
//  FontSelectionTableViewController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 1/23/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import Then
import UIKit

protocol FontSelectionTableViewControllerDelegate: AnyObject {
    func fontSelectionTableViewController(_ controller: FontSelectionTableViewController, didChooseFontWithName fontName: String, forKey key: FontSelectionTableViewController.Key)
}

class FontSelectionTableViewController: UITableViewController {

    enum Key: String {
        case postFont = "postfont"
        case commentFont = "commentfont"
    }

    enum Item {
        case system
        case named(string: String)

        func font(ofSize size: CGFloat) -> UIFont? {
            switch self {
            case .system:
                return UIFont.systemFont(ofSize: size)
            case .named(let name):
                let descriptor = UIFontDescriptor().withFamily(name)
//                descriptor = descriptor.addingAttributes([.traits : [UIFontDescriptor.TraitKey.weight : UIFont.Weight.black]])
                return UIFont(descriptor: descriptor, size: size)
            }
        }
    }

    weak var delegate: FontSelectionTableViewControllerDelegate?
    var key: Key = .postFont

    private var currentFont: String? {
        return UserDefaults.standard.string(forKey: key.rawValue)
    }

    private lazy var allFonts: [Item] =
        [.system] + UIFont.familyNames
            .sorted()
            .map(Item.named(string:))

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "fontCell")
        tableView.backgroundColor = ColorUtil.theme.backgroundColor
        tableView.separatorStyle = .none
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight() && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }

}

// MARK: - Table view data source
extension FontSelectionTableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allFonts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fontCell", for: indexPath)
        let fontName = allFonts[indexPath.row].font(ofSize: 16)?.fontName ?? "system"
        cell.textLabel?.font = UIFont(name: fontName, size: 16)
        switch allFonts[indexPath.row] {
        case .system:
            cell.textLabel?.text = "System Default"
        case .named(let name):
            cell.textLabel?.text = name
        }
        cell.backgroundColor = ColorUtil.theme.foregroundColor
        cell.textLabel?.textColor = ColorUtil.theme.fontColor
        if fontName == currentFont {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFontName = allFonts[indexPath.row].font(ofSize: 16)?.fontName ?? "system"

        // Store the font to the given key
        UserDefaults.standard.set(selectedFontName, forKey: key.rawValue)

        delegate?.fontSelectionTableViewController(self, didChooseFontWithName: selectedFontName, forKey: key)

        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.popViewController(animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

}
