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

class SettingsAudio: BubbleSettingTableViewController {

    var cells: [[UITableViewCell]] = []

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

    var muteInlineVideoCell = InsetCell().then {
        $0.selectionStyle = .none
    }
    var muteInlineVideoSwitch = UISwitch()

    var muteModalVideoCell = InsetCell().then {
        $0.selectionStyle = .none
    }
    var muteModalVideoSwitch = UISwitch()

    var muteYTCell = InsetCell().then {
        $0.selectionStyle = .none
    }
    var muteYTSwitch = UISwitch()

    var modalVideoFollowsMuteSwitchCell = InsetCell().then {
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

        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        self.title = "Audio settings"

        muteModalVideoSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.muteVideosInModal
        }
        muteModalVideoSwitch.addTarget(self, action: #selector(SettingsAudio.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        muteModalVideoCell.textLabel?.text = "Always start videos muted"
        muteModalVideoCell.accessoryView = muteModalVideoSwitch
        muteModalVideoCell.textLabel?.numberOfLines = 0
        muteModalVideoCell.selectionStyle = UITableViewCell.SelectionStyle.none

        modalVideoFollowsMuteSwitchSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.modalVideosRespectHardwareMuteSwitch
        }
        modalVideoFollowsMuteSwitchSwitch.addTarget(self, action: #selector(SettingsAudio.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        modalVideoFollowsMuteSwitchCell.textLabel?.text = "Start videos muted if your device is muted"
        modalVideoFollowsMuteSwitchCell.accessoryView = modalVideoFollowsMuteSwitchSwitch
        modalVideoFollowsMuteSwitchCell.textLabel?.numberOfLines = 0
        modalVideoFollowsMuteSwitchCell.selectionStyle = UITableViewCell.SelectionStyle.none

        muteYTSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.muteYouTube
        }
        muteYTSwitch.addTarget(self, action: #selector(SettingsAudio.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        muteYTCell.textLabel?.text = "Always start YouTube videos muted"
        muteYTCell.accessoryView = muteYTSwitch
        muteYTCell.textLabel?.numberOfLines = 0
        muteYTCell.selectionStyle = UITableViewCell.SelectionStyle.none

        headers.append("Popup Video Player")
        cells.append([
            muteModalVideoCell,
            modalVideoFollowsMuteSwitchCell,
            muteYTCell,
            ])

        #if DEBUG
        muteInlineVideoSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
            $0.isOn = SettingValues.muteInlineVideos
        }
        muteInlineVideoSwitch.addTarget(self, action: #selector(SettingsAudio.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        muteInlineVideoCell.textLabel?.text = "(Debug) Start inline videos muted"
        muteInlineVideoCell.accessoryView = muteInlineVideoSwitch
        muteInlineVideoCell.textLabel?.numberOfLines = 0
        muteInlineVideoCell.selectionStyle = UITableViewCell.SelectionStyle.none

        headers.append("Inline Video")
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = cells[indexPath.section][indexPath.row]
        cell.style()
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
        case muteYTSwitch:
            SettingValues.muteYouTube = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_muteYouTube)
        default:
            break
        }
        UserDefaults.standard.synchronize()
    }
}

private extension UITableViewCell {
    func style() {
        backgroundColor = ColorUtil.theme.foregroundColor
        textLabel?.textColor = ColorUtil.theme.fontColor
        detailTextLabel?.textColor = ColorUtil.theme.fontColor.withAlphaComponent(0.7)
    }
}
