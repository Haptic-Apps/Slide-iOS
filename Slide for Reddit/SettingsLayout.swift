//
//  SettingsGeneral.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/17/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class SettingsLayout: UITableViewController {
    
    var cropBigPicCell: UITableViewCell = UITableViewCell()
    var cropBigPic = UISwitch()
    
    var hideBannerImageCell: UITableViewCell = UITableViewCell()
    var hideBannerImage = UISwitch()
    
    var cardModeCell: UITableViewCell = UITableViewCell()
    var cardMode = UISwitch()
    
    var centerLeadImageCell: UITableViewCell = UITableViewCell()
    var centerLeadImage = UISwitch()
    
    var hideActionbarCell: UITableViewCell = UITableViewCell()
    var hideActionbar = UISwitch()

    var largerThumbnailCell: UITableViewCell = UITableViewCell()
    var largerThumbnail = UISwitch()
    
    var scoreTitleCell: UITableViewCell = UITableViewCell()
    var scoreTitle = UISwitch()

    var abbreviateScoreCell: UITableViewCell = UITableViewCell()
    var abbreviateScore = UISwitch()

    var domainInfoCell: UITableViewCell = UITableViewCell()
    var domainInfo = UISwitch()

    var link = LinkCellView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
        navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    func switchIsChanged(_ changed: UISwitch) {
        if(changed == cropBigPic){
            SettingValues.bigPicCropped = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_cropBigPic)
        } else if(changed == hideBannerImage){
            SettingValues.bannerHidden = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_bannerHidden)
        } else if(changed == cardMode){
            if(changed.isOn){
                SettingValues.postViewMode = .CARD
            } else {
                SettingValues.postViewMode = .LIST
            }
            UserDefaults.standard.set((changed.isOn ? "card" : "list"), forKey: SettingValues.pref_postViewMode)
        } else if(changed == centerLeadImage){
            SettingValues.centerLeadImage = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_centerLead)
        } else if(changed == hideActionbar){
            SettingValues.hideButtonActionbar = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_hideButtonActionbar)
        } else if(changed == largerThumbnail){
            SettingValues.largerThumbnail = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_largerThumbnail)
        } else if(changed == abbreviateScore){
            SettingValues.abbreviateScores = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_abbreviateScores)
        } else if(changed == scoreTitle){
            SettingValues.scoreInTitle = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_scoreInTitle)
        } else if(changed == domainInfo){
            SettingValues.domainInInfo = changed.isOn
            UserDefaults.standard.set(changed.isOn, forKey: SettingValues.pref_domainInInfo)
        }
        UserDefaults.standard.synchronize()
        doDisables()
        doLink()
        tableView.reloadData()
    }
    
    func doLink(){
        link = LinkCellView()
        let fakesub = RSubmission.init()
        let calendar: NSCalendar! = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
        let now: NSDate! = NSDate()
        
        let date0 = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now as Date, options: NSCalendar.Options.matchFirst)!
        
        fakesub.id = "234"
        fakesub.name = "234"
        fakesub.author = "ccrama"
        fakesub.created = date0 as NSDate
        fakesub.edited = NSDate(timeIntervalSince1970: 1)
        fakesub.gilded = 0
        fakesub.htmlBody = ""
        fakesub.body = ""
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
        
        
        self.link.setLinkForPreview(submission: fakesub)
        self.link.isUserInteractionEnabled = false
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label : UILabel = UILabel()
        label.textColor = ColorUtil.fontColor
        label.font = FontGenerator.boldFontOfSize(size: 20, submission: true)
        let toReturn = label.withPadding(padding: UIEdgeInsets.init(top: 0, left: 12, bottom: 0, right: 0))
        toReturn.backgroundColor = ColorUtil.backgroundColor
        
        switch(section) {
        case 0: label.text  = "Preview"
            break
        case 1: label.text  = "Display"
            break
        case 2: label.text = "Actionbar"
            break
        default: label.text  = ""
            break
        }
        return toReturn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func loadView() {
        super.loadView()
        doLink()
        self.view.backgroundColor = ColorUtil.backgroundColor
        // set the title
        self.title = "General"
        
        cropBigPic = UISwitch()
        cropBigPic.isOn = SettingValues.bigPicCropped
        cropBigPic.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        cropBigPicCell.textLabel?.text = "Crop big pic"
        cropBigPicCell.accessoryView = cropBigPic
        cropBigPicCell.backgroundColor = ColorUtil.foregroundColor
        cropBigPicCell.textLabel?.textColor = ColorUtil.fontColor
        cropBigPicCell.selectionStyle = UITableViewCellSelectionStyle.none
        
        
        hideBannerImage = UISwitch()
        hideBannerImage.isOn = SettingValues.bannerHidden
        hideBannerImage.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        hideBannerImageCell.textLabel?.text = "Hide banner image"
        hideBannerImageCell.accessoryView = hideBannerImage
        hideBannerImageCell.backgroundColor = ColorUtil.foregroundColor
        hideBannerImageCell.textLabel?.textColor = ColorUtil.fontColor
        hideBannerImageCell.selectionStyle = UITableViewCellSelectionStyle.none

        cardMode = UISwitch()
        cardMode.isOn = SettingValues.postViewMode == .CARD
        cardMode.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        cardModeCell.textLabel?.text = "Card mode"
        cardModeCell.accessoryView = cardMode
        cardModeCell.backgroundColor = ColorUtil.foregroundColor
        cardModeCell.textLabel?.textColor = ColorUtil.fontColor
        cardModeCell.selectionStyle = UITableViewCellSelectionStyle.none

        centerLeadImage = UISwitch()
        centerLeadImage.isOn = SettingValues.centerLeadImage
        centerLeadImage.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        centerLeadImageCell.textLabel?.text = "Center lead image"
        centerLeadImageCell.accessoryView = centerLeadImage
        centerLeadImageCell.backgroundColor = ColorUtil.foregroundColor
        centerLeadImageCell.textLabel?.textColor = ColorUtil.fontColor
        centerLeadImageCell.selectionStyle = UITableViewCellSelectionStyle.none

        hideActionbar = UISwitch()
        hideActionbar.isOn = SettingValues.hideButtonActionbar
        hideActionbar.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        hideActionbarCell.textLabel?.text = "Hide actionbar"
        hideActionbarCell.accessoryView = hideActionbar
        hideActionbarCell.backgroundColor = ColorUtil.foregroundColor
        hideActionbarCell.textLabel?.textColor = ColorUtil.fontColor
        hideActionbarCell.selectionStyle = UITableViewCellSelectionStyle.none

        largerThumbnail = UISwitch()
        largerThumbnail.isOn = SettingValues.largerThumbnail
        largerThumbnail.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        largerThumbnailCell.textLabel?.text = "Larger thumbnail"
        largerThumbnailCell.accessoryView = largerThumbnail
        largerThumbnailCell.backgroundColor = ColorUtil.foregroundColor
        largerThumbnailCell.textLabel?.textColor = ColorUtil.fontColor
        largerThumbnailCell.selectionStyle = UITableViewCellSelectionStyle.none

        scoreTitle = UISwitch()
        scoreTitle.isOn = SettingValues.scoreInTitle
        scoreTitle.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        scoreTitleCell.textLabel?.text = "Score and comments in title"
        scoreTitleCell.accessoryView = scoreTitle
        scoreTitleCell.backgroundColor = ColorUtil.foregroundColor
        scoreTitleCell.textLabel?.textColor = ColorUtil.fontColor
        scoreTitleCell.selectionStyle = UITableViewCellSelectionStyle.none

        abbreviateScore = UISwitch()
        abbreviateScore.isOn = SettingValues.abbreviateScores
        abbreviateScore.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        abbreviateScoreCell.textLabel?.text = "Abbreviate scores"
        abbreviateScoreCell.accessoryView = abbreviateScore
        abbreviateScoreCell.backgroundColor = ColorUtil.foregroundColor
        abbreviateScoreCell.textLabel?.textColor = ColorUtil.fontColor
        abbreviateScoreCell.selectionStyle = UITableViewCellSelectionStyle.none

        domainInfo = UISwitch()
        domainInfo.isOn = SettingValues.domainInInfo
        domainInfo.addTarget(self, action: #selector(SettingsLayout.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
        domainInfoCell.textLabel?.text = "Domain in info line"
        domainInfoCell.accessoryView = domainInfo
        domainInfoCell.backgroundColor = ColorUtil.foregroundColor
        domainInfoCell.textLabel?.textColor = ColorUtil.fontColor
        domainInfoCell.selectionStyle = UITableViewCellSelectionStyle.none

        doDisables()
    }
    
    func doDisables(){
        if(SettingValues.bannerHidden){
            centerLeadImage.isEnabled = false
            cropBigPic.isEnabled = false
        } else {
            centerLeadImage.isEnabled = true
            cropBigPic.isEnabled = true
        }
    
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(section == 0){
            return 0
        }
        return 70
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(indexPath.section == 0){
            return link.estimateHeight(false)
        }
        return 60
    }
    
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch(indexPath.section) {
        case 0:
            return link
        case 1:
            switch(indexPath.row) {
            case 0: return self.cardModeCell
            case 1: return self.hideBannerImageCell
            case 2: return self.cropBigPicCell
            case 3: return self.centerLeadImageCell
            case 4: return self.largerThumbnailCell
            default: fatalError("Unknown row in section 0")
            }
        case 2:
            switch(indexPath.row) {
            case 0: return self.hideActionbarCell
            case 1: return self.scoreTitleCell
            case 2: return self.abbreviateScoreCell
            case 3: return self.domainInfoCell

            default: fatalError("Unknown row in section 0")
            }
        default: fatalError("Unknown section")
        }
        
    }
    
    func showTimeMenu(s: LinkSortType){
        if(s == .hot || s == .new){
            SettingValues.defaultSorting = s
            UserDefaults.standard.set(s.path, forKey: SettingValues.pref_defaultSorting)
            UserDefaults.standard.synchronize()
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Time Period", message: "", preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)
            
            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default)
                { action -> Void in
                    SettingValues.defaultSorting = s
                    UserDefaults.standard.set(s.path, forKey: SettingValues.pref_defaultSorting)
                    SettingValues.defaultTimePeriod = t
                    UserDefaults.standard.set(t.param, forKey: SettingValues.pref_defaultTimePeriod)
                    UserDefaults.standard.synchronize()
                }
                actionSheetController.addAction(saveActionButton)
            }
            self.present(actionSheetController, animated: true, completion: nil)
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0: return 1    // section 0 has 2 rows
        case 1: return 5    // section 1 has 1 row
        case 2: return 4
        default: fatalError("Unknown number of sections")
        }
    }
    
    
}
