//
//  SettingsAudio.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 2/14/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SettingsAudio: UITableViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight() && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }

    var muteInlineVideoCell = UITableViewCell().then {
        $0.selectionStyle = .none
    }
    var muteInlineVideoSwitch = UISwitch()

    var muteModalVideoCell = UITableViewCell().then {
        $0.selectionStyle = .none
    }
    var muteModalVideoSwitch = UISwitch()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
    }

    override func loadView() {
        super.loadView()
        self.tableView.tableFooterView = UIView()

        self.view.backgroundColor = ColorUtil.backgroundColor
        self.title = "Audio Settings"
        self.tableView.separatorStyle = .none

        muteInlineVideoSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.enlargeLinks
        }
        muteInlineVideoSwitch.addTarget(self, action: #selector(SettingsAudio.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        muteInlineVideoCell.textLabel?.text = "Mute inline video"
        muteInlineVideoCell.accessoryView = muteInlineVideoSwitch
        muteInlineVideoCell.textLabel?.numberOfLines = 0
        muteInlineVideoCell.selectionStyle = UITableViewCell.SelectionStyle.none

        muteModalVideoSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.enlargeLinks
        }
        muteModalVideoSwitch.addTarget(self, action: #selector(SettingsAudio.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        muteModalVideoCell.textLabel?.text = "Mute modal video"
        muteModalVideoCell.accessoryView = muteModalVideoSwitch
        muteModalVideoCell.textLabel?.numberOfLines = 0
        muteModalVideoCell.selectionStyle = UITableViewCell.SelectionStyle.none

        refresh()
    }

    func refresh() {
        muteInlineVideoSwitch.isOn = SettingValues.muteInlineVideos
        muteModalVideoSwitch.isOn = SettingValues.muteVideosInModal

        self.tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell

        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: cell = self.muteInlineVideoCell
            case 1: cell = self.muteModalVideoCell
            default: fatalError("Unknown row in section \(indexPath.section)")
            }
        default: fatalError("Unknown section")
        }

        cell.style()
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Each cell already has a tap handler in init
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2    // section 0 has 3 rows
        default: fatalError("Unknown number of sections")
        }
    }

}

// MARK: - Actions
private extension SettingsAudio {
    @objc func switchIsChanged(_ changed: UISwitch) {
        switch changed {
        case muteInlineVideoSwitch:
            SettingValues.muteInlineVideos = changed.isOn
        case muteModalVideoSwitch:
            SettingValues.muteVideosInModal = changed.isOn
        default:
            break
        }
        UserDefaults.standard.synchronize()
    }
}

private extension UITableViewCell {
    func style() {
        backgroundColor = ColorUtil.foregroundColor
        textLabel?.textColor = ColorUtil.fontColor
        detailTextLabel?.textColor = ColorUtil.fontColor.withAlphaComponent(0.7)
    }
}
