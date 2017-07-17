//
//  UZTextViewCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/6/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class NavigationHeaderView: UIView {
    var title = UILabel()
    var switchp: UIButton = UIButton()
    var more: UIButton = UIButton()
    var settings: UIButton = UIButton()
    var inbox: UILabel = UILabel()
    var search: UISearchBar = UISearchBar()
    
    func doColors(){
        switchp.setImage(UIImage(named: "down")?.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: .normal)
        more.setImage(UIImage(named: "ic_more_vert_white")?.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 20, height: 30)), for: .normal)
        settings.setImage(UIImage(named: "settings")?.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: .normal)

        title.textColor = ColorUtil.fontColor
        backgroundColor = ColorUtil.foregroundColor
    }
    

    override init(frame: CGRect) {
        super.init(frame:frame)
        self.search = UISearchBar(frame: CGRect(x: 0, y: 0, width: 3, height: 50))
        self.switchp = UIButton(frame: CGRect(x: 0, y: 0, width: 3, height: 50))
        self.more = UIButton(frame: CGRect(x: 0, y: 0, width: 3, height: 50))
        self.settings = UIButton(frame: CGRect(x: 0, y: 0, width: 3, height: 50))
        self.inbox = UILabel(frame: CGRect(x: 0, y: 0, width: 3, height: 50))
        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: 3, height: 50))

        
        
        search.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        switchp.translatesAutoresizingMaskIntoConstraints = false
        search.translatesAutoresizingMaskIntoConstraints = false
        more.translatesAutoresizingMaskIntoConstraints = false
        inbox.translatesAutoresizingMaskIntoConstraints = false
        settings.translatesAutoresizingMaskIntoConstraints = false

        switchp.contentHorizontalAlignment = .left
        switchp.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0)
        switchp.tintColor = ColorUtil.fontColor
        
        more.contentHorizontalAlignment = .left
        more.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0)
        more.tintColor = ColorUtil.fontColor
        
        settings.contentHorizontalAlignment = .left
        settings.tintColor = ColorUtil.fontColor

        
        inbox.textColor = .white
        inbox.font = UIFont.boldSystemFont(ofSize: 16)
        inbox.backgroundColor = GMColor.red300Color()
        inbox.layer.cornerRadius = 10
        inbox.layer.masksToBounds = true
        
        title.font = UIFont.boldSystemFont(ofSize: 26)
        
        let aTap = UITapGestureRecognizer(target: self, action: #selector(self.switchAccounts(_:)))
        switchp.addGestureRecognizer(aTap)
        switchp.isUserInteractionEnabled = true
        
        let sTap = UITapGestureRecognizer(target: self, action: #selector(self.showMore(_:)))
        more.addGestureRecognizer(sTap)
        more.isUserInteractionEnabled = true

        let setTap = UITapGestureRecognizer(target: self, action: #selector(self.settings(_:)))
        settings.addGestureRecognizer(setTap)
        settings.isUserInteractionEnabled = true

        if(AccountController.isLoggedIn){
            let yTap = UITapGestureRecognizer(target: self, action: #selector(self.you(_:)))
            title.addGestureRecognizer(yTap)
        } else {
            let yTap = UITapGestureRecognizer(target: self, action: #selector(self.switchAccounts(_:)))
            title.addGestureRecognizer(yTap)
        }
        title.isUserInteractionEnabled = true

        let iTap = UITapGestureRecognizer(target: self, action: #selector(self.inbox(_:)))
        inbox.addGestureRecognizer(iTap)
        inbox.isUserInteractionEnabled = true

        addSubview(switchp)
        addSubview(more)
        addSubview(settings)
        addSubview(search)
        addSubview(title)
        addSubview(inbox)
        
        self.clipsToBounds = true
        updateConstraints()
        doColors()
    }
    
    func you(_ sender: AnyObject){
        let profile = ProfileViewController.init(name: AccountController.currentName)
        self.parentController?.show(profile, sender: self.parentController)
    }
    
    func inbox(_ sender: AnyObject){
        let inbox = InboxViewController.init()
        self.parentController?.show(inbox, sender: self.parentController)
    }
    
    func showMore(_ sender: AnyObject){
        let optionMenu = UIAlertController(title: nil, message: "Navigate", preferredStyle: .actionSheet)
        
        let prof = UIAlertAction(title: "Go to a profile", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.showProfileDialog(self.switchp)
        })
        optionMenu.addAction(prof)
        
        let saved = UIAlertAction(title: "Your saved content", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            let profile = ProfileViewController.init(name: AccountController.currentName)
            self.parentController?.show(profile, sender: self.parentController)
        })
        optionMenu.addAction(saved)

        let inbox = UIAlertAction(title: "Inbox", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.inbox(self.switchp)
        })
        optionMenu.addAction(inbox)
        
        let settings = UIAlertAction(title: "Settings", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.settings(self.switchp)
        })
        optionMenu.addAction(settings)
        parentController?.present(optionMenu, animated: true, completion: nil)

    }
    

    
    func showProfileDialog(_ sender: AnyObject){
        let alert = UIAlertController(title: "Enter a username", message: "", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        alert.addAction(UIAlertAction(title: "Go to user", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            let profile = ProfileViewController.init(name: (textField?.text!)!)
            self.parentController?.show(profile, sender: self.parentController)
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        parentController?.present(alert, animated: true, completion: nil)
    }
    
    func settings(_ sender: AnyObject){
        self.parentController?.show(SettingsViewController.init(), sender: self.parentController!)
    }
    func switchAccounts(_ sender: AnyObject){
        let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
        
        for s in AccountController.names {
            let add = UIAlertAction(title: s, style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                AccountController.switchAccount(name: s)
                if !UserDefaults.standard.bool(forKey: "done" + s){
                    do{
                        try (self.parentController as! NavigationSidebarViewController).parentController?.addAccount(token: OAuth2TokenRepository.token(of: s))
                    } catch {
                        (self.parentController as! NavigationSidebarViewController).parentController?.addAccount()
                    }
                } else {
                    Subscriptions.sync(name: s, completion:{
                        (self.parentController as! NavigationSidebarViewController).parentController?.restartVC()
                    })
                }
            })
            optionMenu.addAction(add)
            
        }
        
        if(AccountController.isLoggedIn){
            let guest = UIAlertAction(title: "Guest", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                AccountController.switchAccount(name: "GUEST")
                Subscriptions.sync(name: "GUEST", completion: { 
                    (self.parentController as! NavigationSidebarViewController).parentController?.restartVC()
                })
            })
            optionMenu.addAction(guest)
            
            let deleteAction = UIAlertAction(title: "Log out", style: .destructive, handler: {
                (alert: UIAlertAction!) -> Void in
                AccountController.delete(name: AccountController.currentName)
            })
            optionMenu.addAction(deleteAction)
            
        }
        
        let add = UIAlertAction(title: "Add account", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            (self.parentController as! NavigationSidebarViewController).parentController?.addAccount()
        })
        optionMenu.addAction(add)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        optionMenu.addAction(cancelAction)
        
        parentController?.present(optionMenu, animated: true, completion: nil)
    }
    
    var parentController: UIViewController?
    func setSubreddit(subreddit: String, parent: UIViewController){
        self.subreddit = subreddit
        self.parentController = parent
        updateConstraints()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var subreddit = ""
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let metrics=["topMargin": 0]
        let views=["title": title, "switchp":switchp, "inbox": inbox, "settings":settings, "more":more, "search":search] as [String : Any]
        
        var constraint:[NSLayoutConstraint] = []
        
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[title]-2-[switchp(30)]-(>=8)-[inbox]-4-[settings(30)]-4-[more(20)]-4-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[search]-0-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-36-[inbox(30)]-4-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-36-[settings(30)]-4-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))

        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-36-[more(30)]-4-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-36-[title]-8-[search]-4-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-36-[switchp(30)]-4-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))

        
        if(AccountController.isLoggedIn){
            title.text = AccountController.currentName
            inbox.isHidden = false
        } else {
            inbox.isHidden = true
            switchp.isHidden = true
            title.text = "guest"
        }
        
        addConstraints(constraint)
    }
    
    func getEstHeight()-> CGFloat{
        return CGFloat((120))
    }
    
    func setMail(_ mailcount: Int){
        inbox.text = " \(mailcount) "
    }
}
