//
//  CacheSettings.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 5/22/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import SDCAlertView
import UIKit

class CacheSettings: BubbleSettingTableViewController {

    var subs: [String] = []
    var autoCache: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "auto")
    var cacheContent: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "cache")
    var depth: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "depth")
    var posts: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "posts")

    var autoCacheSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    var cacheContentSwitch = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    public func createCell(_ cell: UITableViewCell, _ switchV: UISwitch? = nil, isOn: Bool, text: String) {
        cell.textLabel?.text = text
        cell.textLabel?.textColor = ColorUtil.theme.fontColor
        cell.backgroundColor = ColorUtil.theme.foregroundColor
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if let s = switchV {
            s.isOn = isOn
            s.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControl.Event.valueChanged)
            cell.accessoryView = s
        }
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selected.append(contentsOf: Subscriptions.offline)
        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        subs.append(contentsOf: Subscriptions.subreddits)
        self.subs = self.subs.sorted() {
            $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
        }
        tableView.reloadData()
        self.headers = ["Caching options", "Subreddits to Auto-Cache"]

        createCell(autoCache, autoCacheSwitch, isOn: SettingValues.autoCache, text: "Cache subreddits automatically")
        self.autoCache.detailTextLabel?.text = "Will run the first time Slide opens each day"
        self.autoCache.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.autoCache.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.autoCache.detailTextLabel?.numberOfLines = 0

        createCell(cacheContent, cacheContentSwitch, isOn: false, text: "Cache subreddits automatically")
        self.cacheContent.detailTextLabel?.text = "Coming soon!"
        self.cacheContent.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.cacheContent.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.cacheContent.detailTextLabel?.numberOfLines = 0

        self.tableView.tableFooterView = UIView()
        
        createCell(depth, nil, isOn: false, text: "Depth of comments to cache")
        self.depth.detailTextLabel?.text = "\(SettingValues.commentDepth) levels"
        self.depth.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.depth.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.depth.detailTextLabel?.numberOfLines = 0

        createCell(posts, nil, isOn: false, text: "Number of posts to cache in each subreddit")
        self.posts.detailTextLabel?.text = "\(SettingValues.cachedPostsCount) posts"
        self.posts.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        self.posts.detailTextLabel?.lineBreakMode = .byWordWrapping
        self.posts.detailTextLabel?.numberOfLines = 0
    }

    var delete = UIButton()

    public static var changed = false

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 80 : 60
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        save(nil)
    }

    func save(_ selector: AnyObject?) {
        /* todo this
        SubredditReorderViewController.changed = true
        Subscriptions.set(name: AccountController.currentName, subs: subs, completion: {
            self.dismiss(animated: true, completion: nil)
        })*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: – Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 3 : subs.count
    }

    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == autoCacheSwitch {
            if !VCPresenter.proDialogShown(feature: true, self) {
                SettingValues.autoCache = changed.isOn
                UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_autoCache)
            } else {
                changed.isOn = false
            }
        } else if changed == cacheContentSwitch {
            //todo this setting
        } else if !changed.isOn {
            selected.remove(at: selected.index(of: changed.accessibilityIdentifier!)!)
            Subscriptions.setOffline(subs: selected) {
            }
        } else {
            selected.append(changed.accessibilityIdentifier!)
            Subscriptions.setOffline(subs: selected) {
            }
        }
    }
    
    var selected = [String]()
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                let actionSheetController = AlertController(title: "Posts to cache", message: nil, preferredStyle: .alert)
                
                actionSheetController.addCloseButton()
                
                let values = [["10", "15", "20", "25", "30", "35", "40", "45", "50", "55", "60", "65", "70", "75", "80", "85", "90", "95", "100"]]
                let pickerView = PickerViewViewControllerColored(values: values, initialSelection: [(0, (SettingValues.cachedPostsCount - 10) / 5)], action: { (_, _, chosen, _) in
                    SettingValues.cachedPostsCount = (chosen.row * 5) + 10
                    UserDefaults.standard.set((chosen.row * 5) + 10, forKey: SettingValues.pref_postsToCache)
                    UserDefaults.standard.synchronize()
                    self.posts.detailTextLabel?.text = "\((chosen.row * 5) + 10) posts"
                })
                
                actionSheetController.setupTheme()
                
                actionSheetController.attributedTitle = NSAttributedString(string: "Posts to cache", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
                actionSheetController.attributedMessage = NSAttributedString(string: "How many posts will cache in each subreddit", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])

                actionSheetController.addChild(pickerView)
                
                let pv = pickerView.view!
                actionSheetController.contentView.addSubview(pv)
                
                pv.edgeAnchors == actionSheetController.contentView.edgeAnchors - 14
                pv.heightAnchor == CGFloat(216)
                pickerView.didMove(toParent: actionSheetController)
                
                actionSheetController.addBlurView()
                
                self.present(actionSheetController, animated: true, completion: nil)
            } else if indexPath.row == 2 {
                let actionSheetController = AlertController(title: "Comment cache depth", message: nil, preferredStyle: .alert)
                
                actionSheetController.addCloseButton()
                
                let values = [["4", "5", "6", "7", "8", "9", "10"]]
                let pickerView = PickerViewViewControllerColored(values: values, initialSelection: [(0, SettingValues.commentDepth - 4)], action: { (_, _, chosen, _) in
                    SettingValues.commentDepth = chosen.row + 4
                    UserDefaults.standard.set(chosen.row + 4, forKey: SettingValues.pref_commentDepth)
                    UserDefaults.standard.synchronize()
                    self.depth.detailTextLabel?.text = "\(chosen.row + 4) levels"
                })
                
                actionSheetController.setupTheme()
                
                actionSheetController.attributedTitle = NSAttributedString(string: "Comment cache depth", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
                actionSheetController.attributedMessage = NSAttributedString(string: "How deep comment chains will load to", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])

                actionSheetController.addChild(pickerView)
                
                let pv = pickerView.view!
                actionSheetController.contentView.addSubview(pv)
                
                pv.edgeAnchors == actionSheetController.contentView.edgeAnchors - 14
                pv.heightAnchor == CGFloat(216)
                pickerView.didMove(toParent: actionSheetController)
                
                actionSheetController.addBlurView()
                
                self.present(actionSheetController, animated: true, completion: nil)
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return autoCache
            } else if indexPath.row == 1 {
                return posts
            } else {
                return depth
            }
        } else {
            let thing = subs[indexPath.row]
            var cell: SubredditCellView?
            let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
            c.setSubreddit(subreddit: thing, nav: nil)
            cell = c
            cell?.backgroundColor = ColorUtil.theme.foregroundColor
            let aSwitch = UISwitch().then {
                $0.onTintColor = ColorUtil.accentColorForSub(sub: thing)
            }
            if selected.contains(thing) {
                aSwitch.isOn = true
            }
            aSwitch.accessibilityIdentifier = thing
            aSwitch.addTarget(self, action: #selector(switchIsChanged(_:)), for: UIControl.Event.valueChanged)
            c.accessoryView = aSwitch
            return cell!
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBaseBarColors()
        self.title = "Manage offline caching"
    }

}
