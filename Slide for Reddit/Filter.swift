//
//  SettingsGeneral.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class Filter: UITableViewController {

    var sub: String
    var enabled: [Bool]
    var oldEnabled: [Bool]
    var parentVC: SingleSubredditViewController
    
    var image: UITableViewCell = UITableViewCell()
    var imageSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var album: UITableViewCell = UITableViewCell()
    var albumSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var gif: UITableViewCell = UITableViewCell()
    var gifSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var video: UITableViewCell = UITableViewCell()
    var videoSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var link: UITableViewCell = UITableViewCell()
    var linkSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var selftext: UITableViewCell = UITableViewCell()
    var selftextSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var nsfw: UITableViewCell = UITableViewCell()
    var nsfwSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var numberOfSections: Int {
        return AccountController.canShowNSFW ? 7 : 6
    }
    
    public init(subreddit: String, parent: SingleSubredditViewController) {
        self.sub = subreddit
        enabled = PostFilter.enabledArray(sub)
        oldEnabled = enabled
        self.parentVC = parent
        super.init(style: .plain)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        var changed = false
        for i in 0...6 {
            if enabled[i] != oldEnabled[i] {
                changed = true
                break
            }
        }
        if changed {
            PostFilter.setEnabledArray(sub, enabled)
            parentVC.refresh()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize.init( width: 275, height: numberOfSections * 50)
        self.tableView.frame = CGRect.init(x: 30, y: 8, width: 275, height: 420)
    }

    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == imageSwitch {
            enabled[0] = changed.isOn
        } else if changed == albumSwitch {
            enabled[1] = changed.isOn
        } else if changed == gifSwitch {
            enabled[2] = changed.isOn
        } else if changed == videoSwitch {
            enabled[3] = changed.isOn
        } else if changed == linkSwitch {
            enabled[4] = changed.isOn
        } else if changed == selftextSwitch {
            enabled[5] = changed.isOn
        } else if changed == nsfwSwitch {
            enabled[6] = changed.isOn
        }
        UserDefaults.standard.synchronize()
    }

    override func loadView() {
        super.loadView()

        self.view.backgroundColor = .clear
        self.tableView.separatorStyle = .none

        imageSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        imageSwitch.isOn = enabled[0]
        imageSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        self.image.textLabel?.text = "Images"
        self.image.textLabel?.textColor = ColorUtil.fontColor
        self.image.accessoryView = imageSwitch
        self.image.backgroundColor = .clear
        self.image.selectionStyle = UITableViewCell.SelectionStyle.none

        albumSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        albumSwitch.isOn = enabled[1]
        albumSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        self.album.textLabel?.text = "Albums"
        self.album.textLabel?.textColor = ColorUtil.fontColor
        self.album.accessoryView = albumSwitch
        self.album.backgroundColor = .clear
        self.album.selectionStyle = UITableViewCell.SelectionStyle.none

        gifSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        gifSwitch.isOn = enabled[2]
        gifSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        self.gif.textLabel?.text = "Gifs"
        self.gif.textLabel?.textColor = ColorUtil.fontColor
        self.gif.accessoryView = gifSwitch
        self.gif.backgroundColor = .clear
        self.gif.selectionStyle = UITableViewCell.SelectionStyle.none

        videoSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        videoSwitch.isOn = enabled[3]
        videoSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        self.video.textLabel?.text = "Videos"
        self.video.textLabel?.textColor = ColorUtil.fontColor
        self.video.accessoryView = videoSwitch
        self.video.backgroundColor = .clear
        self.video.selectionStyle = UITableViewCell.SelectionStyle.none

        linkSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        linkSwitch.isOn = enabled[4]
        linkSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        self.link.textLabel?.text = "Links"
        self.link.textLabel?.textColor = ColorUtil.fontColor
        self.link.accessoryView = linkSwitch
        self.link.backgroundColor = .clear
        self.link.selectionStyle = UITableViewCell.SelectionStyle.none

        selftextSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        selftextSwitch.isOn = enabled[5]
        selftextSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        self.selftext.textLabel?.text = "Selftext"
        self.selftext.textLabel?.textColor = ColorUtil.fontColor
        self.selftext.accessoryView = selftextSwitch
        self.selftext.backgroundColor = .clear
        self.selftext.selectionStyle = UITableViewCell.SelectionStyle.none

        nsfwSwitch = UISwitch().then {
            $0.onTintColor = ColorUtil.baseAccent
        }
        nsfwSwitch.isOn = enabled[6]
        nsfwSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
        self.nsfw.textLabel?.text = "NSFW Content"
        self.nsfw.textLabel?.textColor = ColorUtil.fontColor
        self.nsfw.accessoryView = nsfwSwitch
        self.nsfw.backgroundColor = .clear
        self.nsfw.selectionStyle = UITableViewCell.SelectionStyle.none

    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: return self.image
            case 1: return self.album
            case 2: return self.gif
            case 3: return self.video
            case 4: return self.link
            case 5: return self.selftext
            case 6: return self.nsfw
            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }

    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return numberOfSections
        default: fatalError("Unknown number of sections")
        }
    }

}
