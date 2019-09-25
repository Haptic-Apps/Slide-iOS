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

enum FontMapping {
    case system
    case systemRounded
    case systemSerif
    case systemMonospaced
    case named(string: String)

    static func fromStoredName(name: String) -> FontMapping {
        switch name {
        case "Slide.System-Base":
            return .system
        case "Slide.System-Rounded":
            return .systemRounded
        case "Slide.System-Serif":
            return .systemSerif
        case "Slide.System-Monospaced":
            return .systemMonospaced
        default:
            return .named(string: name)
        }
    }

    func font(ofSize size: CGFloat) -> UIFont? {
        switch self {
        case .system:
            return UIFont.systemFont(ofSize: size)
        case .systemRounded:
            return UIFont.withDesignRounded(forSize: size)
        case .systemSerif:
            return UIFont.withDesignSerif(forSize: size)
        case .systemMonospaced:
            return UIFont.withDesignMonospaced(forSize: size)
        case .named(let name):
            return UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        }
    }

    var storedName: String {
        switch self {
        case .system:
            return "Slide.System-Base"
        case .systemRounded:
            return "Slide.System-Rounded"
        case .systemSerif:
            return "Slide.System-Serif"
        case .systemMonospaced:
            return "Slide.System-Monospaced"
        case .named:
            return self.font(ofSize: 16)?.fontName ?? "Unknown Font Name"
        }
    }

    var displayedName: String {
        switch self {
        case .system:
            return "San Francisco"
        case .systemRounded:
            return "SF Rounded"
        case .systemSerif:
            return "SF Serif"
        case .systemMonospaced:
            return "SF Monospaced"
        case .named(let name):
            return name
        }
    }

    static var sanFranciscoVariants: [FontMapping] {
        if #available(iOS 13.0, *) {
            return [
                .system,
                .systemRounded,
                .systemSerif,
                .systemMonospaced,
            ]
        } else {
            return [.system]
        }
    }

    static var allInstalledFonts: [FontMapping] {
        return UIFont.familyNames
            .sorted()
            .map(FontMapping.named(string:))
    }
}

class FontSelectionTableViewController: UITableViewController {

    enum Key: String {
        case postFont = "postfont"
        case commentFont = "commentfont"
    }

    weak var delegate: FontSelectionTableViewControllerDelegate?
    var key: Key = .postFont

    private var currentFont: String? {
        return UserDefaults.standard.string(forKey: key.rawValue)
    }

    private lazy var allFonts: [FontMapping] = FontMapping.sanFranciscoVariants + FontMapping.allInstalledFonts

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "fontCell")
        tableView.backgroundColor = ColorUtil.theme.backgroundColor
        tableView.separatorStyle = .none
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }

}

extension UIFont {

    class func withDesignRounded(forSize size: CGFloat) -> UIFont {
        let sfFont = UIFont.systemFont(ofSize: size)
        if #available(iOS 13.0, *) {
            let descriptor = UIFontDescriptor().withFamily(sfFont.familyName).withDesign(.rounded)
            if let descriptor = descriptor {
                return UIFont(descriptor: descriptor, size: size)
            } else {
                return sfFont
            }
        } else {
            return sfFont
        }
    }

    class func withDesignSerif(forSize size: CGFloat) -> UIFont {
        let sfFont = UIFont.systemFont(ofSize: size)
        if #available(iOS 13.0, *) {
            let descriptor = UIFontDescriptor().withFamily(sfFont.familyName).withDesign(.serif)
            if let descriptor = descriptor {
                return UIFont(descriptor: descriptor, size: size)
            } else {
                return sfFont
            }
        } else {
            return sfFont
        }
    }

    class func withDesignMonospaced(forSize size: CGFloat) -> UIFont {
        let sfFont = UIFont.systemFont(ofSize: size)
        if #available(iOS 13.0, *) {
            let descriptor = UIFontDescriptor().withFamily(sfFont.familyName).withDesign(.monospaced)
            if let descriptor = descriptor {
                return UIFont(descriptor: descriptor, size: size)
            } else {
                return sfFont
            }
        } else {
            return sfFont
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
        let fontItem = allFonts[indexPath.row]
        cell.textLabel?.font = fontItem.font(ofSize: 16)
        cell.textLabel?.text = fontItem.displayedName
        cell.backgroundColor = ColorUtil.theme.foregroundColor
        cell.textLabel?.textColor = ColorUtil.theme.fontColor
        if fontItem.storedName == currentFont {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFontName = allFonts[indexPath.row].storedName

        // Store the font name to the given key
        UserDefaults.standard.set(selectedFontName, forKey: key.rawValue)

        delegate?.fontSelectionTableViewController(self, didChooseFontWithName: selectedFontName, forKey: key)

        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.popViewController(animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

}
