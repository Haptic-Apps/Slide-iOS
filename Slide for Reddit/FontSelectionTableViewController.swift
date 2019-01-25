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

//class FontSelectionCell: UITableViewCell {
//    var title = UILabel()
//    var subtitle = UILabel()
//
//    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//        setupView()
//    }
//    required public init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func setupView() {
//        self.contentView.backgroundColor = ColorUtil.foregroundColor
//
//        self.contentView.addSubviews(title, subtitle)
//
//        title.text = "Font Name"
//        title.numberOfLines = 1
//        title.textAlignment = .left
//        title.textColor = ColorUtil.fontColor
//
//        subtitle.text = "The quick brown fox jumps over the lazy dog"
//        subtitle.numberOfLines = 1
//        subtitle.textAlignment = .left
//        subtitle.textColor = ColorUtil.fontColor
//
//        title.horizontalAnchors == self.contentView.horizontalAnchors + 8
//        subtitle.leftAnchor == self.contentView.leftAnchor + 16
//        subtitle.rightAnchor == self.contentView.rightAnchor - 8
//        title.topAnchor == self.contentView.topAnchor + 12
//        subtitle.topAnchor == title.bottomAnchor + 4
//        subtitle.bottomAnchor == self.contentView.bottomAnchor + 12
//    }
//
//    func configure(withFontName fontName: String) {
//        title.text = fontName
//        subtitle.font = UIFont(name: fontName, size: 16)
//        setNeedsLayout()
//    }
//}

protocol FontSelectionTableViewControllerDelegate: AnyObject {
    func fontSelectionTableViewController(_ controller: FontSelectionTableViewController, didChooseFontWithName fontName: String)
}

class FontSelectionTableViewController: UITableViewController {

    enum Item {
        case system
        case boldSystem
        case named(string: String)

        func font(forSize size: CGFloat) -> UIFont? {
            switch self {
            case .system:
                return UIFont.systemFont(ofSize: size)
            case .boldSystem:
                return UIFont.boldSystemFont(ofSize: size)
            case .named(let name):
                return UIFont(name: name, size: size)
            }
        }
    }

    weak var delegate: FontSelectionTableViewControllerDelegate?
    var key: String = ""

    private var currentFont: String? {
        return UserDefaults.standard.string(forKey: key)
    }

    private lazy var allFonts: [Item] = [.system, .boldSystem] +
        UIFont.familyNames
            .flatMap(UIFont.fontNames(forFamilyName:))
            .sorted()
            .map(Item.named(string:))

    override func viewDidLoad() {
        super.viewDidLoad()
        //tableView.register(FontSelectionCell.self, forCellReuseIdentifier: "fontCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "fontCell")
        tableView.backgroundColor = ColorUtil.backgroundColor
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
        let fontName = allFonts[indexPath.row].font(forSize: 16)?.fontName ?? "system"
        cell.textLabel?.font = UIFont(name: fontName, size: 16)
        cell.textLabel?.text = fontName
        cell.backgroundColor = ColorUtil.foregroundColor
        cell.textLabel?.textColor = ColorUtil.fontColor
        if fontName == currentFont {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFontName = allFonts[indexPath.row].font(forSize: 16)?.fontName ?? "system"

        // Store the font to the given key
        UserDefaults.standard.set(selectedFontName, forKey: key)

        delegate?.fontSelectionTableViewController(self, didChooseFontWithName: selectedFontName)

        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.popViewController(animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

}
