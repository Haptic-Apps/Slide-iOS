//
//  SettingsGeneral.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/11/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class Filter: UITableViewController {

    var sub: String
    var enabled : [Bool]
    var oldEnabled: [Bool]
    var parentVC : SingleSubredditViewController
    
    var image: UITableViewCell = UITableViewCell()
    var imageSwitch = UISwitch()
    var album: UITableViewCell = UITableViewCell()
    var albumSwitch = UISwitch()
    var gif: UITableViewCell = UITableViewCell()
    var gifSwitch = UISwitch()
    var video: UITableViewCell = UITableViewCell()
    var videoSwitch = UISwitch()
    var link: UITableViewCell = UITableViewCell()
    var linkSwitch = UISwitch()
    var selftext: UITableViewCell = UITableViewCell()
    var selftextSwitch = UISwitch()
    var nsfw: UITableViewCell = UITableViewCell()
    var nsfwSwitch = UISwitch()
    
    
    public init(subreddit: String, parent: SingleSubredditViewController){
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
            if(enabled[i] != oldEnabled[i]){
                changed = true
                break
            }
        }
        if(changed){
            PostFilter.setEnabledArray(sub, enabled)
            parentVC.refresh()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize.init( width: 275, height: 350)
        self.tableView.frame = CGRect.init(x: 30, y: 8, width: 275, height: 420)
    }

    func switchIsChanged(_ changed: UISwitch) {
        if (changed == imageSwitch) {
            enabled[0] = changed.isOn
        } else if (changed == albumSwitch) {
            enabled[1] = changed.isOn
        } else if (changed == gifSwitch) {
            enabled[2] = changed.isOn
        } else if (changed == videoSwitch) {
            enabled[3] = changed.isOn
        } else if (changed == linkSwitch) {
            enabled[4] = changed.isOn
        } else if (changed == selftextSwitch) {
            enabled[5] = changed.isOn
        } else if (changed == nsfwSwitch) {
            enabled[6] = changed.isOn
        }
        UserDefaults.standard.synchronize()
    }

    override func loadView() {
        super.loadView()

        self.view.backgroundColor = .clear

        imageSwitch = UISwitch()
        imageSwitch.isOn = enabled[0]
        imageSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.image.textLabel?.text = "Images"
        self.image.accessoryView = imageSwitch
        self.image.backgroundColor = .clear
        self.image.selectionStyle = UITableViewCellSelectionStyle.none

        albumSwitch = UISwitch()
        albumSwitch.isOn = enabled[1]
        albumSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.album.textLabel?.text = "Albums"
        self.album.accessoryView = albumSwitch
        self.album.backgroundColor = .clear
        self.album.selectionStyle = UITableViewCellSelectionStyle.none

        gifSwitch = UISwitch()
        gifSwitch.isOn = enabled[2]
        gifSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.gif.textLabel?.text = "Gifs"
        self.gif.accessoryView = gifSwitch
        self.gif.backgroundColor = .clear
        self.gif.selectionStyle = UITableViewCellSelectionStyle.none

        videoSwitch = UISwitch()
        videoSwitch.isOn = enabled[3]
        videoSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.video.textLabel?.text = "Videos"
        self.video.accessoryView = videoSwitch
        self.video.backgroundColor = .clear
        self.video.selectionStyle = UITableViewCellSelectionStyle.none

        linkSwitch = UISwitch()
        linkSwitch.isOn = enabled[4]
        linkSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.link.textLabel?.text = "Links"
        self.link.accessoryView = linkSwitch
        self.link.backgroundColor = .clear
        self.link.selectionStyle = UITableViewCellSelectionStyle.none

        selftextSwitch = UISwitch()
        selftextSwitch.isOn = enabled[5]
        selftextSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.selftext.textLabel?.text = "Selftext"
        self.selftext.accessoryView = selftextSwitch
        self.selftext.backgroundColor = .clear
        self.selftext.selectionStyle = UITableViewCellSelectionStyle.none

        nsfwSwitch = UISwitch()
        nsfwSwitch.isOn = enabled[6]
        nsfwSwitch.addTarget(self, action: #selector(Filter.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        self.nsfw.textLabel?.text = "NSFW Content"
        self.nsfw.accessoryView = nsfwSwitch
        self.nsfw.backgroundColor = .clear
        self.nsfw.selectionStyle = UITableViewCellSelectionStyle.none

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
        switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
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
        switch (section) {
        case 0: return 7
        default: fatalError("Unknown number of sections")
        }
    }


}
