//
//  SettingsAudio.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 2/14/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import reddift
import Then
import UIKit

class SettingsAudio: UITableViewController {

    var cells: [[UITableViewCell]] = []
    var sectionTitles: [String] = []

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

    var modalVideoFollowsMuteSwitchCell = UITableViewCell().then {
        $0.selectionStyle = .none
    }
    var modalVideoFollowsMuteSwitchSwitch = UISwitch()

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

        muteModalVideoSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.enlargeLinks
        }
        muteModalVideoSwitch.addTarget(self, action: #selector(SettingsAudio.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        muteModalVideoCell.textLabel?.text = "Start muted"
        muteModalVideoCell.accessoryView = muteModalVideoSwitch
        muteModalVideoCell.textLabel?.numberOfLines = 0
        muteModalVideoCell.selectionStyle = UITableViewCell.SelectionStyle.none

        modalVideoFollowsMuteSwitchSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.enlargeLinks
        }
        modalVideoFollowsMuteSwitchSwitch.addTarget(self, action: #selector(SettingsAudio.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        modalVideoFollowsMuteSwitchCell.textLabel?.text = "Respect mute switch"
        modalVideoFollowsMuteSwitchCell.accessoryView = modalVideoFollowsMuteSwitchSwitch
        modalVideoFollowsMuteSwitchCell.textLabel?.numberOfLines = 0
        modalVideoFollowsMuteSwitchCell.selectionStyle = UITableViewCell.SelectionStyle.none

        sectionTitles.append("Popup Video Player")
        cells.append([
            muteModalVideoCell,
            modalVideoFollowsMuteSwitchCell,
            ])

        #if DEBUG
        muteInlineVideoSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.enlargeLinks
        }
        muteInlineVideoSwitch.addTarget(self, action: #selector(SettingsAudio.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        muteInlineVideoCell.textLabel?.text = "(Debug) Start inline videos muted"
        muteInlineVideoCell.accessoryView = muteInlineVideoSwitch
        muteInlineVideoCell.textLabel?.numberOfLines = 0
        muteInlineVideoCell.selectionStyle = UITableViewCell.SelectionStyle.none

        sectionTitles.append("Inline Video")
        cells.append([muteInlineVideoCell])
        #endif

        refresh()
    }

    func refresh() {
        muteInlineVideoSwitch.isOn = SettingValues.muteInlineVideos
        muteModalVideoSwitch.isOn = SettingValues.muteVideosInModal
        modalVideoFollowsMuteSwitchSwitch.isOn = SettingValues.modalVideosRespectHardwareMuteSwitch

        self.tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return cells.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells[section].count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = cells[indexPath.section][indexPath.row]
        cell.style()
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label: UILabel = UILabel().then {
            $0.textColor = ColorUtil.baseAccent
            $0.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        }
        let toReturn = label.withPadding(padding: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        label.text = sectionTitles[section]

        return toReturn
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
        case modalVideoFollowsMuteSwitchSwitch:
            SettingValues.modalVideosRespectHardwareMuteSwitch = changed.isOn
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
