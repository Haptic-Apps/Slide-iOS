//
//  SettingsGeneral.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/17/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import UIKit

class SettingsLayout: BubbleSettingTableViewController {
    
    var imageCell: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "image")
    
    var cardModeCell: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "mode")
    
    var actionBarCell: UITableViewCell = InsetCell.init(style: .subtitle, reuseIdentifier: "actionbar")

    var flatModeCell: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: "flat")
    var flatMode = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var hideImageSelftextCell: UITableViewCell = InsetCell(style: .subtitle, reuseIdentifier: "hide")
    var hideImageSelftext = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var largerThumbnailCell: UITableViewCell = InsetCell()
    var largerThumbnail = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var thumbLinkCell: UITableViewCell = InsetCell()
    var thumbLink = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var scoreTitleCell: UITableViewCell = InsetCell()
    var scoreTitle = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var commentTitleCell: UITableViewCell = InsetCell()
    var commentTitle = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var typeTitleCell: UITableViewCell = InsetCell()
    var typeTitle = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var infoBelowTitleCell: UITableViewCell = InsetCell()
    var infoBelowTitle = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var abbreviateScoreCell: UITableViewCell = InsetCell()
    var abbreviateScore = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var domainInfoCell: UITableViewCell = InsetCell()
    var domainInfo = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var leftThumbCell: UITableViewCell = InsetCell()
    var leftThumb = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var thumbInfoCell: UITableViewCell = InsetCell()
    var thumbInfo = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var hideCell: UITableViewCell = InsetCell()
    var hide = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var moreCell: UITableViewCell = InsetCell()
    var more = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var shareCell: UITableViewCell = InsetCell()
    var share = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var saveCell: UITableViewCell = InsetCell()
    var save = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }

    var readLaterCell: UITableViewCell = InsetCell()
    var readLater = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var selftextCell: UITableViewCell = InsetCell()
    var selftext = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var smalltagCell: UITableViewCell = InsetCell()
    var smalltag = UISwitch().then {
        $0.onTintColor = ColorUtil.baseAccent
    }
    
    var linkCell = UITableViewCell().then {
        $0.tintColor = ColorUtil.baseAccent
    }
    
    var link = LinkCellView().then {
        $0.tintColor = ColorUtil.baseAccent
    }
    
    @objc func switchIsChanged(_ changed: UISwitch) {
        if changed == smalltag {
            SettingValues.smallerTag = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_smallTag)
        } else if changed == selftext {
            SettingValues.showFirstParagraph = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_showFirstParagraph)
        } else if changed == thumbInfo {
            SettingValues.thumbTag = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_thumbTag)
        } else if changed == largerThumbnail {
            SettingValues.largerThumbnail = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_largerThumbnail)
        } else if changed == more {
            SettingValues.menuButton = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_moreButton)
        } else if changed == infoBelowTitle {
            SettingValues.infoBelowTitle = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_infoBelowTitle)
            CachedTitle.titles.removeAll()
        } else if changed == abbreviateScore {
            SettingValues.abbreviateScores = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_abbreviateScores)
        } else if changed == scoreTitle {
            SettingValues.scoreInTitle = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_scoreInTitle)
        } else if changed == commentTitle {
            SettingValues.commentsInTitle = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_commentsInTitle)
        } else if changed == typeTitle {
            SettingValues.typeInTitle = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_typeInTitle)
        } else if changed == thumbLink {
            SettingValues.linkAlwaysThumbnail = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_linkAlwaysThumbnail)
        } else if changed == hideImageSelftext {
            SettingValues.hideImageSelftext = !changed.isOn
            UserDefaults.standard.set(!changed.isOn, forKey: SettingValues.pref_hideImageSelftext)
        } else if changed == domainInfo {
            SettingValues.domainInInfo = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_domainInInfo)
        } else if changed == leftThumb {
            SettingValues.leftThumbnail = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_leftThumbnail)
        } else if changed == hide {
            SettingValues.hideButton = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_hideButton)
        } else if changed == share {
            SettingValues.shareButton = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_shareButton)
        } else if changed == save {
            SettingValues.saveButton = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_saveButton)
        } else if changed == readLater {
            SettingValues.readLaterButton = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_readLaterButton)
        } else if changed == flatMode {
            SettingValues.flatMode = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_flatMode)
        }
        SingleSubredditViewController.cellVersion += 1
        MainViewController.needsReTheme = true
        UserDefaults.standard.synchronize()
        doDisables()
        doLink()
        tableView.reloadData()
    }
    
    func doLink() {
        
        let fakesub = RSubmission()
        let calendar: NSCalendar! = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
        let now: NSDate! = NSDate()
        
        let date0 = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now as Date, options: NSCalendar.Options.matchFirst)!
        
        fakesub.id = "234"
        fakesub.name = "234"
        fakesub.author = "ccrama"
        fakesub.created = date0 as NSDate
        fakesub.edited = NSDate(timeIntervalSince1970: 1)
        fakesub.gilded = false
        fakesub.htmlBody = ""
        fakesub.body = "This is where the selftext preview goes in a normal submission."
        fakesub.title = "Chameleons are cool!"
        fakesub.subreddit = "all"
        fakesub.archived = false
        fakesub.locked = false
        fakesub.urlString = "http://i.imgur.com/mAs9Lk3.png"
        fakesub.distinguished = ""
        fakesub.isEdited = false
        fakesub.commentCount = 42
        fakesub.saved = false
        fakesub.stickied = false
        fakesub.visited = false
        fakesub.isSelf = false
        fakesub.permalink = ""
        fakesub.bannerUrl = "http://i.imgur.com/mAs9Lk3.png"
        fakesub.thumbnailUrl = "http://i.imgur.com/mAs9Lk3s.png"
        fakesub.lqUrl = "http://i.imgur.com/mAs9Lk3m.png"
        fakesub.lQ = false
        fakesub.thumbnail = true
        fakesub.banner = true
        fakesub.score = 52314
        fakesub.flair = "Cool!"
        fakesub.domain = "imgur.com"
        fakesub.voted = false
        fakesub.height = 288
        fakesub.width = 636
        fakesub.vote = false

        link.contentView.removeFromSuperview()
        if SettingValues.postImageMode == .THUMBNAIL {
            link = ThumbnailLinkCellView(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 500))
        } else {
            link = BannerLinkCellView(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: 500))
        }
        
        link.aspectWidth = self.tableView.frame.size.width
        self.link.configure(submission: fakesub, parent: MediaViewController(), nav: nil, baseSub: "all", test: true, np: false)
        self.link.isUserInteractionEnabled = false
        self.linkCell.isUserInteractionEnabled = false
        linkCell.contentView.backgroundColor = ColorUtil.theme.backgroundColor
        link.contentView.frame = CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: link.estimateHeight(false, true, np: false))
        linkCell.contentView.addSubview(link.contentView)
        linkCell.frame = CGRect.init(x: 0, y: 0, width: self.tableView.frame.size.width, height: link.estimateHeight(false, true, np: false))
        
        switch SettingValues.postViewMode {
        case .CARD:
            cardModeCell.imageView?.image = UIImage(named: "card")?.toolbarIcon()
        case .CENTER:
            cardModeCell.imageView?.image = UIImage(named: "centeredimage")?.toolbarIcon()
        case .COMPACT:
            cardModeCell.imageView?.image = UIImage(named: "compact")?.toolbarIcon()
        case .LIST:
            cardModeCell.imageView?.image = UIImage(named: "list")?.toolbarIcon()
        }
        
        switch SettingValues.postImageMode {
        case .CROPPED_IMAGE:
            imageCell.imageView?.image = UIImage(named: "crop")?.toolbarIcon()
        case .FULL_IMAGE:
            imageCell.imageView?.image = UIImage(named: "full")?.toolbarIcon()
        case .THUMBNAIL:
            imageCell.imageView?.image = UIImage(named: "thumb")?.toolbarIcon()
        }
        
        switch SettingValues.actionBarMode {
        case .FULL:
            actionBarCell.imageView?.image = UIImage(sfString: SFSymbol.chevronLeftSlashChevronRight, overrideString: "code")?.toolbarIcon()
        case .FULL_LEFT:
            actionBarCell.imageView?.image = UIImage(sfString: SFSymbol.chevronLeftSlashChevronRight, overrideString: "code")?.toolbarIcon()
        case .NONE:
            actionBarCell.imageView?.image = UIImage(sfString: SFSymbol.xmark, overrideString: "hide")?.toolbarIcon()
        case .SIDE:
            actionBarCell.imageView?.image = UIImage(sfString: SFSymbol.chevronUp, overrideString: "up")?.toolbarIcon()
        case .SIDE_RIGHT:
            actionBarCell.imageView?.image = UIImage(sfString: SFSymbol.chevronDown, overrideString: "down")?.toolbarIcon()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 && indexPath.row == 0 {
            let alertController = DragDownAlertMenu(title: "Card type", subtitle: "Select a card type that will be used throughout Slide", icon: nil)
            
            alertController.addAction(title: "List view", icon: UIImage(named: "list")!.menuIcon()) {
                UserDefaults.standard.set("list", forKey: SettingValues.pref_postViewMode)
                SettingValues.postViewMode = .LIST
                UserDefaults.standard.synchronize()
                SingleSubredditViewController.cellVersion += 1
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.cardModeCell.detailTextLabel?.text = SettingValues.postViewMode.rawValue.capitalize()
                MainViewController.needsReTheme = true
            }

            alertController.addAction(title: "Large card view", icon: UIImage(named: "card")!.menuIcon()) {
                UserDefaults.standard.set("card", forKey: SettingValues.pref_postViewMode)
                SettingValues.postViewMode = .CARD
                UserDefaults.standard.synchronize()
                SingleSubredditViewController.cellVersion += 1
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.cardModeCell.detailTextLabel?.text = SettingValues.postViewMode.rawValue.capitalize()
                MainViewController.needsReTheme = true
            }
            
            alertController.addAction(title: "Centered large card view", icon: UIImage(named: "centeredimage")!.menuIcon()) {
                UserDefaults.standard.set("center", forKey: SettingValues.pref_postViewMode)
                SettingValues.postViewMode = .CENTER
                UserDefaults.standard.synchronize()
                SingleSubredditViewController.cellVersion += 1
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.cardModeCell.detailTextLabel?.text = SettingValues.postViewMode.rawValue.capitalize()
                MainViewController.needsReTheme = true
            }

            alertController.addAction(title: "Compact list view", icon: UIImage(named: "compact")!.menuIcon()) {
                UserDefaults.standard.set("compact", forKey: SettingValues.pref_postViewMode)
                SettingValues.postViewMode = .COMPACT
                UserDefaults.standard.synchronize()
                SingleSubredditViewController.cellVersion += 1
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.cardModeCell.detailTextLabel?.text = SettingValues.postViewMode.rawValue.capitalize()
                MainViewController.needsReTheme = true
            }
            
            alertController.show(self)
        } else if indexPath.section == 1 && indexPath.row == 1 {
            let alertController = DragDownAlertMenu(title: "Submission image mode", subtitle: "Select a size for images throughout Slide", icon: nil)

            alertController.addAction(title: "Full-sized image", icon: UIImage(named: "full")!.menuIcon()) {
                UserDefaults.standard.set("full", forKey: SettingValues.pref_postImageMode)
                SettingValues.postImageMode = .FULL_IMAGE
                UserDefaults.standard.synchronize()
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.imageCell.detailTextLabel?.text = SettingValues.postImageMode.rawValue.capitalize()
                MainViewController.needsReTheme = true
            }

            alertController.addAction(title: "Cropped image", icon: UIImage(named: "crop")!.menuIcon()) {
                UserDefaults.standard.set("cropped", forKey: SettingValues.pref_postImageMode)
                SettingValues.postImageMode = .CROPPED_IMAGE
                UserDefaults.standard.synchronize()
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.imageCell.detailTextLabel?.text = SettingValues.postImageMode.rawValue.capitalize()
                MainViewController.needsReTheme = true
            }

            alertController.addAction(title: "No image (thumbnail only)", icon: UIImage(named: "thumb")!.menuIcon()) {
                UserDefaults.standard.set("thumbnail", forKey: SettingValues.pref_postImageMode)
                SettingValues.postImageMode = .THUMBNAIL
                UserDefaults.standard.synchronize()
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.imageCell.detailTextLabel?.text = SettingValues.postImageMode.rawValue.capitalize()
                MainViewController.needsReTheme = true
            }
            
            alertController.show(self)
        } else if indexPath.section == 1 && indexPath.row == 2 {
            let alertController = DragDownAlertMenu(title: "Button bar mode", subtitle: "Sets the layout for the submission buttons", icon: nil)
            
            alertController.addAction(title: "Full-sized button bar", icon: UIImage(sfString: SFSymbol.chevronLeftSlashChevronRight, overrideString: "code")!.menuIcon()) {
                UserDefaults.standard.set("full", forKey: SettingValues.pref_actionbarMode)
                SettingValues.actionBarMode = .FULL
                UserDefaults.standard.synchronize()
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.actionBarCell.detailTextLabel?.text = SettingValues.actionBarMode.rawValue.capitalize()
                SingleSubredditViewController.cellVersion += 1
                MainViewController.needsReTheme = true
            }

            alertController.addAction(title: "Left-aligned full-sized button bar", icon: UIImage(sfString: SFSymbol.chevronLeftSlashChevronRight, overrideString: "code")!.menuIcon()) {
                UserDefaults.standard.set("left", forKey: SettingValues.pref_actionbarMode)
                SettingValues.actionBarMode = .FULL_LEFT
                UserDefaults.standard.synchronize()
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.actionBarCell.detailTextLabel?.text = SettingValues.actionBarMode.rawValue.capitalize()
                SingleSubredditViewController.cellVersion += 1
                MainViewController.needsReTheme = true
            }

            alertController.addAction(title: "Left-side vote buttons", icon: UIImage(sfString: SFSymbol.chevronUp, overrideString: "up")!.menuIcon()) {
                UserDefaults.standard.set("side", forKey: SettingValues.pref_actionbarMode)
                SettingValues.actionBarMode = .SIDE
                UserDefaults.standard.synchronize()
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.actionBarCell.detailTextLabel?.text = SettingValues.actionBarMode.rawValue.capitalize()
                SingleSubredditViewController.cellVersion += 1
                MainViewController.needsReTheme = true
            }

            alertController.addAction(title: "Right-side vote buttons", icon: UIImage(sfString: SFSymbol.chevronDown, overrideString: "down")!.menuIcon()) {
                UserDefaults.standard.set("right", forKey: SettingValues.pref_actionbarMode)
                SettingValues.actionBarMode = .SIDE_RIGHT
                UserDefaults.standard.synchronize()
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.actionBarCell.detailTextLabel?.text = SettingValues.actionBarMode.rawValue.capitalize()
                SingleSubredditViewController.cellVersion += 1
                MainViewController.needsReTheme = true

            }

            alertController.addAction(title: "Hide button bar", icon: UIImage(sfString: SFSymbol.xmark, overrideString: "hide")!.menuIcon()) {
                UserDefaults.standard.set("none", forKey: SettingValues.pref_actionbarMode)
                SettingValues.actionBarMode = .NONE
                UserDefaults.standard.synchronize()
                self.doDisables()
                self.doLink()
                tableView.reloadData()
                self.actionBarCell.detailTextLabel?.text = SettingValues.actionBarMode.rawValue.capitalize()
                SingleSubredditViewController.cellVersion += 1
                MainViewController.needsReTheme = true
            }

            alertController.show(self)
        }
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
    
    override func loadView() {
        super.loadView()
        doLink()
        
        headers = ["Preview", "Display", "Information line", "Thumbnails", "Advanced"]
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        // set the title
        self.title = "Submission layout"
        
        createCell(selftextCell, selftext, isOn: SettingValues.showFirstParagraph, text: "Show selftext preview")
        createCell(thumbInfoCell, thumbInfo, isOn: SettingValues.thumbTag, text: "Show link type on thumbnail")

        createCell(cardModeCell, isOn: false, text: "Card type")
        cardModeCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        cardModeCell.detailTextLabel?.text = SettingValues.postViewMode.rawValue.capitalize()
        cardModeCell.detailTextLabel?.numberOfLines = 0
        cardModeCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        
        createCell(imageCell, isOn: false, text: "Image mode")
        imageCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        imageCell.detailTextLabel?.text = SettingValues.postImageMode.rawValue.capitalize()
        imageCell.detailTextLabel?.numberOfLines = 0
        imageCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        
        createCell(actionBarCell, isOn: false, text: "Button bar mode")
        actionBarCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        actionBarCell.detailTextLabel?.text = SettingValues.actionBarMode.rawValue.capitalize()
        actionBarCell.detailTextLabel?.numberOfLines = 0
        actionBarCell.detailTextLabel?.lineBreakMode = .byWordWrapping
        
        createCell(hideImageSelftextCell, hideImageSelftext, isOn: !SettingValues.hideImageSelftext, text: "Text-post images")
        hideImageSelftextCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        hideImageSelftextCell.detailTextLabel?.text = "Enabling this will show image previews on text-only posts"
        hideImageSelftextCell.detailTextLabel?.numberOfLines = 0
        hideImageSelftextCell.detailTextLabel?.lineBreakMode = .byWordWrapping

        createCell(typeTitleCell, typeTitle, isOn: SettingValues.typeInTitle, text: "Content type in title")
        createCell(smalltagCell, smalltag, isOn: SettingValues.smallerTag, text: "Smaller content tag")
        createCell(largerThumbnailCell, largerThumbnail, isOn: SettingValues.largerThumbnail, text: "Larger thumbnail")
        createCell(commentTitleCell, commentTitle, isOn: SettingValues.commentsInTitle, text: "Comment count in title")
        createCell(scoreTitleCell, scoreTitle, isOn: SettingValues.scoreInTitle, text: "Post score in title")
        createCell(abbreviateScoreCell, abbreviateScore, isOn: SettingValues.abbreviateScores, text: "Abbreviate post scores (ex: 10k)")
        createCell(infoBelowTitleCell, infoBelowTitle, isOn: SettingValues.infoBelowTitle, text: "Title above submission information")
        createCell(domainInfoCell, domainInfo, isOn: SettingValues.domainInInfo, text: "Domain in title")
        createCell(leftThumbCell, leftThumb, isOn: SettingValues.leftThumbnail, text: "Left-side thumbnail")
        createCell(hideCell, hide, isOn: SettingValues.hideButton, text: "Hide post button")
        createCell(saveCell, save, isOn: SettingValues.saveButton, text: "Save post button")
        createCell(shareCell, share, isOn: SettingValues.shareButton, text: "Share content button")
        createCell(readLaterCell, readLater, isOn: SettingValues.readLaterButton, text: "Read Later button")
        createCell(thumbLinkCell, thumbLink, isOn: SettingValues.linkAlwaysThumbnail, text: "Hide banner image on link submissions")
        createCell(flatModeCell, flatMode, isOn: SettingValues.flatMode, text: "Flat Mode")
        createCell(moreCell, more, isOn: SettingValues.menuButton, text: "Menu button")
        flatModeCell.detailTextLabel?.textColor = ColorUtil.theme.fontColor
        flatModeCell.detailTextLabel?.text = "Disables rounded corners and shadows throughout Slide"
        flatModeCell.detailTextLabel?.numberOfLines = 0

        doDisables()
        self.tableView.tableFooterView = UIView()
    }
    
    func doDisables() {
        if !SettingValues.actionBarMode.isFull() {
            hide.isEnabled = false
            save.isEnabled = false
            readLater.isEnabled = false
        } else {
            hide.isEnabled = true
            save.isEnabled = true
            readLater.isEnabled = true
        }
        if SettingValues.postImageMode == .THUMBNAIL {
            thumbLink.isEnabled = false
        } else {
            thumbLink.isEnabled = true
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return link.estimateHeight(false, np: false)
        }
        return 60
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return linkCell
        case 1:
            switch indexPath.row {
            case 0: return self.cardModeCell
            case 1: return self.imageCell
            case 2: return self.actionBarCell
            case 3: return self.flatModeCell
                
            default: fatalError("Unknown row in section 1")
            }
        case 2:
            switch indexPath.row {
            case 0: return self.infoBelowTitleCell
            case 1: return self.typeTitleCell
            case 2: return self.commentTitleCell
            case 3: return self.scoreTitleCell
            case 4: return self.abbreviateScoreCell
            case 5: return self.domainInfoCell
            case 6: return self.hideImageSelftextCell
            default: fatalError("Unknown row in section 2")
            }
        case 3:
            switch indexPath.row {
            case 0: return self.largerThumbnailCell
            case 1: return self.leftThumbCell
            case 2: return self.thumbLinkCell
            case 3: return self.thumbInfoCell
                
            default: fatalError("Unknown row in section 3")
            }
        case 4:
            switch indexPath.row {
            case 0: return self.selftextCell
            case 1: return self.smalltagCell
            case 2: return self.hideCell
            case 3: return self.saveCell
            case 4: return self.moreCell
            case 5: return self.shareCell
            case 6: return self.readLaterCell
                
            default: fatalError("Unknown row in section 4")
            }
        default: fatalError("Unknown section")
        }
        
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 4
        case 2: return 7
        case 3: return 4
        case 4: return 7
        default: fatalError("Unknown number of sections")
        }
    }
}
